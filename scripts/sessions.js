#!/usr/bin/env node
// claude-sessions — list Claude sessions for a project (fzf picker in menu.sh).
// No external dependencies (built-in fs/path only). Local read + stdout only — no network.
//
// Modes:
//   claude-sessions <cwd>                 -> TSV rows: "<id>\t<title>  ·  <when>  ·  <size>"
//                                            (newest first; field 1 is id, rest is for display)
//   claude-sessions --preview <cwd> <id>  -> short session preview (for fzf --preview)
//
// Sessions live in ~/.claude/projects/<encoded cwd>/<session-id>.jsonl
// Encoding: each path segment has _ and . replaced with -, segments joined by -

const fs = require('fs');
const path = require('path');

// fzf may close the preview pipe early — don't crash on EPIPE
process.stdout.on('error', e => {
  if (e.code === 'EPIPE') process.exit(0);
  throw e;
});

const HOME = process.env.HOME || process.env.USERPROFILE || '';
// Same path encoding as Claude Code: /a/b_c.d → -a-b-c-d (slashes, _, . → -)
const encode = cwd =>
  cwd
    .split('/')
    .map(s => s.replace(/[_.]/g, '-'))
    .join('-');
const projDir = cwd => path.join(HOME, '.claude', 'projects', encode(cwd));

function relTime(ms) {
  const s = Math.max(0, Math.floor((Date.now() - ms) / 1000));
  const m = Math.floor(s / 60),
    h = Math.floor(m / 60),
    d = Math.floor(h / 24);
  if (s < 60) return 'just now';
  if (m < 60) return `${m}m ago`;
  if (h < 24) return `${h}h ago`;
  if (d < 7) return `${d}d ago`;
  const w = Math.floor(d / 7);
  if (d < 30) return `${w}w ago`;
  return new Date(ms).toISOString().slice(0, 10);
}

function fmtSize(bytes) {
  if (bytes < 1024) return `${bytes} B`;
  if (bytes < 1024 * 1024) return `${(bytes / 1024).toFixed(1)} KB`;
  return `${(bytes / 1024 / 1024).toFixed(1)} MB`;
}

// Text from a user message (content may be a string or an array of blocks).
function userText(entry) {
  const c = entry && entry.message && entry.message.content;
  let t = '';
  if (typeof c === 'string') t = c;
  else if (Array.isArray(c)) {
    const b = c.find(x => x && (x.type === 'text' || typeof x.text === 'string'));
    t = b ? b.text || '' : '';
  }
  t = String(t).replace(/\s+/g, ' ').trim();
  // skip system/command messages
  if (!t || t.startsWith('<') || t.startsWith('Caveat:') || t.startsWith('/')) return '';
  return t;
}

// Parse one .jsonl: title, last activity time, first meaningful user message.
function parseSession(file) {
  let aiTitle = '',
    firstUser = '',
    lastTs = 0;
  let data;
  try {
    data = fs.readFileSync(file, 'utf8');
  } catch {
    return null;
  }
  for (const line of data.split('\n')) {
    if (!line) continue;
    let e;
    try {
      e = JSON.parse(line);
    } catch {
      continue;
    }
    if (e.type === 'ai-title' && e.aiTitle) aiTitle = e.aiTitle;
    if (!firstUser && e.type === 'user') {
      const u = userText(e);
      if (u) firstUser = u;
    }
    if (e.timestamp) {
      const ms = Date.parse(e.timestamp);
      if (ms && ms > lastTs) lastTs = ms;
    }
  }
  let mtime = 0;
  let size = 0;
  try {
    const st = fs.statSync(file);
    mtime = st.mtimeMs;
    size = st.size;
  } catch {}
  return {
    id: path.basename(file, '.jsonl'),
    title: aiTitle || firstUser || '(untitled)',
    ts: lastTs || mtime,
    size,
  };
}

function listSessions(cwd) {
  const dir = projDir(cwd);
  let files;
  try {
    files = fs.readdirSync(dir).filter(f => f.endsWith('.jsonl'));
  } catch {
    return [];
  }
  return files
    .map(f => parseSession(path.join(dir, f)))
    .filter(Boolean)
    .sort((a, b) => b.ts - a.ts);
}

function clip(s, n) {
  return s.length > n ? s.slice(0, n - 1) + '…' : s;
}

// Session ids are opaque tokens from our own listing — reject path components.
function safeSessionId(id) {
  if (!id || !/^[a-zA-Z0-9._-]+$/.test(id)) return null;
  return id;
}

function sessionFile(cwd, id) {
  const safe = safeSessionId(id);
  if (!safe) return null;
  const file = path.resolve(projDir(cwd), `${safe}.jsonl`);
  const root = path.resolve(projDir(cwd)) + path.sep;
  if (!file.startsWith(root)) return null;
  return file;
}

// --- main ---
const args = process.argv.slice(2);

if (args[0] === '--preview') {
  const [, cwd, id] = args;
  const file = sessionFile(cwd, id);
  if (!file) process.exit(0);
  let data;
  try {
    data = fs.readFileSync(file, 'utf8');
  } catch {
    process.exit(0);
  }
  const msgs = [];
  for (const line of data.split('\n')) {
    if (!line) continue;
    let e;
    try {
      e = JSON.parse(line);
    } catch {
      continue;
    }
    if (e.type === 'user') {
      const u = userText(e);
      if (u) msgs.push('› ' + clip(u, 200));
    } else if (e.type === 'assistant') {
      const c = e.message && e.message.content;
      let t = '';
      if (Array.isArray(c)) {
        const b = c.find(x => x && x.type === 'text');
        t = b ? b.text : '';
      } else if (typeof c === 'string') t = c;
      t = String(t).replace(/\s+/g, ' ').trim();
      if (t) msgs.push('  ' + clip(t, 200));
    }
  }
  process.stdout.write(msgs.slice(-12).join('\n\n') + '\n');
  process.exit(0);
}

const cwd = args[0];
if (!cwd) {
  process.exit(0);
}
for (const s of listSessions(cwd)) {
  const label = `${clip(s.title, 60)}  ·  ${relTime(s.ts)}  ·  ${fmtSize(s.size)}`;
  process.stdout.write(`${s.id}\t${label}\n`);
}
