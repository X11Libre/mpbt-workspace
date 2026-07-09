import type { Plugin } from "@opencode-ai/plugin"

let tuiReady = false
let seen: Set<string> = new Set()
let watchdog: ReturnType<typeof setTimeout> | null = null
let polling = false

export const MtxAgentBusWatcher: Plugin = async ({ client, $ }) => {
  const agentID = process.env.AGENT_ID || ''
  if (!agentID) return {}

  // seen beim Start füllen — keine alten Nachrichten
  try {
    const seed = await $`scripts/agent-bus inbox`.text()
    for (const raw of seed.split('\n')) {
      const line = raw.trim()
      if (!line || line.startsWith('ID') || line.startsWith('---') || line.startsWith('No unread') || line === 'AGENT') continue
      const id = line.split(/\s+/)[0]
      if (id) seen.add(id)
    }
  } catch {}

  const log = (msg: string) => {
    client.app.log({ body: { service: 'bus-monitor', level: 'info', message: msg } }).catch(() => {})
  }

  log(`Bus-Überwachung für ${agentID}`)

  const showToast = async (msg: string, variant: 'info' | 'error' | 'success' = 'info') => {
    if (!tuiReady) return
    try { await client.tui.showToast({ body: { message: msg, variant } }) } catch {}
  }

  const armWatchdog = () => {
    if (watchdog) clearTimeout(watchdog)
    watchdog = setTimeout(() => {
      showToast('⚠️ KI antwortet nicht — quota erschöpft / hängt?', 'error')
      $`scripts/agent-bus broadcast ⚠️ ${agentID} KI antwortet nicht`.catch(() => {})
    }, 120000)
  }

  const disarmWatchdog = () => {
    if (watchdog) { clearTimeout(watchdog); watchdog = null }
  }

  const submit = async (text: string) => {
    if (!tuiReady) return
    try {
      await client.tui.appendPrompt({ body: { text: `\n📨 ${text.slice(0, 140)}` } })
      await client.tui.submitPrompt()
      armWatchdog()
    } catch {}
  }

  const poll = async () => {
    if (!tuiReady || polling) return
    polling = true
    try {
      const result = await $`scripts/agent-bus inbox`.text()
      for (const raw of result.split('\n')) {
        const line = raw.trim()
        if (!line || line === 'AGENT' || line.startsWith('ID') || line.startsWith('---') || line.startsWith('No unread')) continue
        const id = line.split(/\s+/)[0]
        if (!id || id.startsWith('m')) {
          if (id && !seen.has(id)) {
            seen.add(id)
            log(`inbox: ${line}`)
            await submit(line)
          }
        }
      }
    } catch {}
    polling = false
  }

  // heartbeat alle 5 Minuten
  setInterval(() => {
    try { $`scripts/agent-bus touch`.catch(() => {}) } catch {}
  }, 300000)

  // TUI-aktiv-Fallback nach 3s
  setTimeout(() => {
    if (!tuiReady) {
      tuiReady = true
      showToast('Bus-Monitor aktiv', 'success')
    }
  }, 3000)

  // Polling alle 3s
  setInterval(poll, 3000)

  return {
    event: async ({ event }) => {
      const ev = event as any
      if (ev.type === 'session.created' && !tuiReady) {
        tuiReady = true
        showToast('Bus-Monitor aktiv', 'success')
      }
      if (ev.type === 'session.idle' || ev.type === 'session.updated') disarmWatchdog()
      if (ev.type === 'session.error') {
        const detail = ev.properties?.error?.message || ev.properties?.error?.code || 'unbekannter Fehler'
        await showToast(`❌ KI-Fehler: ${detail}`, 'error')
        $`scripts/agent-bus broadcast ⚠️ ${agentID} KI-Fehler: ${detail}`.catch(() => {})
        disarmWatchdog()
      }
    },
  }
}
