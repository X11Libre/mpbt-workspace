import * as fs from 'fs'
import * as path from 'path'
import type { Plugin } from "@opencode-ai/plugin"

let tuiReady = false
let seen: Set<string> = new Set()

export const MtxAgentBusWatcher: Plugin = async ({ client, directory, $ }) => {
  const log = (msg: string) => {
    client.app.log({ body: { service: 'bus-monitor', level: 'info', message: msg } }).catch(() => {})
  }

  const busDir = path.resolve(directory, '_WORK_', 'agent-bus')
  const msgDir = path.join(busDir, 'msgs')
  const agentID = process.env.AGENT_ID || ''

  if (!agentID) {
    log('AGENT_ID nicht gesetzt — deaktiviere Bus-Überwachung')
    return {}
  }

  log(`Bus-Überwachung für ${agentID}`)

  const poll = async () => {
    if (!tuiReady) return

    let files: string[]
    try { files = fs.readdirSync(msgDir) } catch { return }

    for (const f of files) {
      if (!f.startsWith('m') || !f.endsWith('.tsv')) continue
      if (seen.has(f)) continue
      seen.add(f)

      try {
        const content = fs.readFileSync(path.join(msgDir, f), 'utf-8')
        const parts = content.split('\t')
        if (parts.length < 5) continue
        const to = parts[3]
        if (to !== 'all' && to !== agentID) continue
        const from = parts[2]
        const text = parts.slice(4).join('\t').trim()
        const id = f.replace('.tsv', '')

        const msg = `⛴️ [${id}] ${from} an ${to}: ${text}`
        log(`Neue Nachricht: ${msg}`)

        try {
          await client.tui.appendPrompt({ body: { text: `\n📨 ${msg.slice(0, 140)}` } })
          await client.tui.submitPrompt()
        } catch {}
      } catch {}
    }
  }

  setInterval(poll, 3000)

  return {
    event: async ({ event }) => {
      if (event.type === 'session.created' && !tuiReady) {
        tuiReady = true
        try {
          await client.tui.showToast({ body: { message: 'Bus-Monitor aktiv', variant: 'success' } })
          await client.tui.appendPrompt({ body: { text: '\n📨 Bus-Monitor bereit' } })
        } catch {}
      }
    },
  }
}
