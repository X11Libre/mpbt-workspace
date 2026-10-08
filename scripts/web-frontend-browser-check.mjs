#!/usr/bin/env node
//
// SPDX-License-Identifier: AGPL-3.0-or-later
// Copyright © 2026 Enrico Weigelt, metux IT consult
//
// End-to-end browser check for the starfleet web console.
//
// A plain HTTP 200 proves NOTHING about the frontend: the console is a single
// inline <script> block, and a syntax error there leaves the page fully
// rendered (HTML+CSS intact) with zero interactivity — no data, no click
// handlers. That failure mode is invisible to `curl -f`, so this check drives
// a real headless Chromium over the DevTools protocol and asserts what a user
// actually sees:
//
//   render  - ship cards exist after the board fetch completed
//   click   - clicking a ship opens the detail overlay (openShip)
//   back    - history.back() closes it again (popstate handler alive)
//   tab     - clicking a tab switches the visible page (show())
//   errors  - no uncaught JS exception during the whole run
//
// Usage: web-frontend-browser-check.mjs [url] [timeout-seconds]
// Exit:  0 = all checks passed, 1 = at least one failed.

import { spawn } from 'node:child_process';
import { mkdtempSync, mkdirSync, rmSync, existsSync } from 'node:fs';
import { tmpdir } from 'node:os';
import { join, dirname } from 'node:path';
import { fileURLToPath } from 'node:url';
import { createRequire } from 'node:module';

// Chromium profile must not leak into the source tree; keep it under
// _WORK_/tmp when running inside the mpbt workspace, else in the OS temp dir.
function profileBase() {
  if (process.env.SFWEB_TMPDIR) return process.env.SFWEB_TMPDIR;
  const wsTmp = join(dirname(fileURLToPath(import.meta.url)), '..', '_WORK_', 'tmp');
  if (existsSync(wsTmp)) return wsTmp;
  return tmpdir();
}

// Node 20 has no global WebSocket, and ESM does not see Debian's global module
// dir — so resolve the system 'ws' package through CJS resolution.
const require = createRequire(import.meta.url);
const { WebSocket } = require('ws');

const URL_ = process.argv[2] || 'http://127.0.0.1:8080/';
const TIMEOUT_S = Number(process.argv[3] || 30);
const CHROME = process.env.CHROME_BIN || 'chromium';

const results = [];
const pageErrors = [];

function record(name, ok, detail) {
  results.push({ name, ok, detail });
  console.log(`${ok ? 'PASS' : 'FAIL'}  ${name}${detail ? '  (' + detail + ')' : ''}`);
}

const sleep = (ms) => new Promise((r) => setTimeout(r, ms));

function findPageTarget(port) {
  return new Promise((resolve, reject) => {
    const deadline = Date.now() + 15000;
    const attempt = async () => {
      try {
        const res = await fetch(`http://127.0.0.1:${port}/json/list`);
        const list = await res.json();
        const page = list.find((t) => t.type === 'page' && t.webSocketDebuggerUrl);
        if (page) return resolve(page.webSocketDebuggerUrl);
      } catch { /* browser not up yet */ }
      if (Date.now() > deadline) return reject(new Error('no page target appeared'));
      setTimeout(attempt, 250);
    };
    attempt();
  });
}

class CDP {
  constructor(ws) {
    this.ws = ws;
    this.id = 0;
    this.pending = new Map();
    ws.addEventListener('message', (ev) => {
      const msg = JSON.parse(ev.data);
      if (msg.id && this.pending.has(msg.id)) {
        const { resolve, reject } = this.pending.get(msg.id);
        this.pending.delete(msg.id);
        if (msg.error) reject(new Error(msg.error.message));
        else resolve(msg.result);
      } else if (msg.method === 'Runtime.exceptionThrown') {
        const d = msg.params.exceptionDetails;
        pageErrors.push(d.exception?.description || d.text || 'unknown exception');
      }
    });
  }
  send(method, params = {}) {
    const id = ++this.id;
    this.ws.send(JSON.stringify({ id, method, params }));
    return new Promise((resolve, reject) => {
      this.pending.set(id, { resolve, reject });
      setTimeout(() => {
        if (this.pending.delete(id)) reject(new Error(`timeout: ${method}`));
      }, 15000);
    });
  }
  async eval(expression) {
    const r = await this.send('Runtime.evaluate', {
      expression, returnByValue: true, awaitPromise: true,
    });
    if (r.exceptionDetails) {
      throw new Error(r.exceptionDetails.exception?.description || r.exceptionDetails.text);
    }
    return r.result.value;
  }
}

const port = 9300 + Math.floor(Math.random() * 400);
const base = profileBase();
mkdirSync(base, { recursive: true });
const profile = mkdtempSync(join(base, 'sfweb-'));
let chrome;
let cdp;

try {
  chrome = spawn(CHROME, [
    '--headless', '--no-sandbox', '--disable-gpu', '--disable-dev-shm-usage',
    `--remote-debugging-port=${port}`, `--user-data-dir=${profile}`,
    '--no-first-run', '--no-default-browser-check', URL_,
  ], { stdio: ['ignore', 'ignore', 'pipe'] });
  chrome.stderr.on('data', () => {});

  const wsUrl = await findPageTarget(port);
  cdp = new CDP(new WebSocket(wsUrl));
  await new Promise((res, rej) => {
    cdp.ws.addEventListener('open', res, { once: true });
    cdp.ws.addEventListener('error', rej, { once: true });
  });
  await cdp.send('Runtime.enable');
  await cdp.send('Page.enable');

  // --- render: wait for the board fetch to produce ship cards -------------
  const t0 = Date.now();
  let cards = 0;
  while (Date.now() - t0 < TIMEOUT_S * 1000) {
    cards = await cdp.eval(`document.querySelectorAll('.card.ship').length`);
    if (cards > 0) break;
    await sleep(400);
  }
  record('render: Schiffe im Board sichtbar', cards > 0, `${cards} Karten`);

  const ids = await cdp.eval(
    `Array.from(document.querySelectorAll('.card.ship')).map(e=>e.textContent.trim().split(/\\s+/)[0])`
  );
  record('render: Schiffsnamen ausgelesen', ids.length > 0, ids.slice(0, 8).join(', '));

  // --- click: open the ship detail overlay --------------------------------
  if (cards > 0) {
    await cdp.eval(`document.querySelector('.card.ship').click()`);
    await sleep(1200);
    const overlay = await cdp.eval(
      `document.getElementById('ship_overlay')?.classList.contains('on')`
    );
    record('click: Schiff anklickbar -> Detail-Overlay offen', overlay === true,
      await cdp.eval(`document.getElementById('ship_name')?.textContent || '-'`));

    // --- back: popstate handler must close it again -----------------------
    await cdp.eval(`history.back()`);
    await sleep(800);
    const closed = await cdp.eval(
      `!document.getElementById('ship_overlay')?.classList.contains('on')`
    );
    record('back: Overlay schliesst sich wieder (popstate)', closed === true);
  } else {
    record('click: Schiff anklickbar -> Detail-Overlay offen', false, 'keine Karten');
    record('back: Overlay schliesst sich wieder (popstate)', false, 'keine Karten');
  }

  // --- tab: switching must switch the visible page ------------------------
  const tabSwitched = await cdp.eval(`(()=>{
    const tabs = Array.from(document.querySelectorAll('#tabs .tab'));
    const target = tabs.find(t=>t.dataset.p==='tasks') || tabs[3];
    if (!target) return false;
    target.click();
    return true;
  })()`);
  await sleep(900);
  const pageId = await cdp.eval(`document.querySelector('.page.on')?.id || '-'`);
  record('tab: Tab-Wechsel schaltet die Seite um', tabSwitched && pageId !== '-',
    `aktive Seite: ${pageId}`);

  // --- no uncaught JS exceptions -----------------------------------------
  record('errors: keine uncaught JS-Exceptions', pageErrors.length === 0,
    pageErrors.slice(0, 2).join(' | ').slice(0, 200));
} catch (e) {
  record('check durchgefuehrt', false, String(e.message || e).slice(0, 300));
} finally {
  try { cdp?.ws?.close(); } catch { /* ignore */ }
  if (chrome) { chrome.kill('SIGKILL'); }
  try { rmSync(profile, { recursive: true, force: true }); } catch { /* ignore */ }
}

const failed = results.filter((r) => !r.ok);
console.log(`\n${results.length - failed.length}/${results.length} checks ok`);
process.exit(failed.length ? 1 : 0);
