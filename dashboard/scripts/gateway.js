'use strict';

// HTTP gateway for the read-only Claude Code dashboard. Serves the static frontend
// and a small REST API backed by shell scripts (sessions/search/names) plus the
// watcher's snapshot file.

const http = require('http');
const fs = require('fs');
const path = require('path');
const { execFile } = require('child_process');
const crypto = require('crypto');
const { URL } = require('url');

const USERNAME = process.env.DASHBOARD_USERNAME || 'admin';
const PASSWORD = process.env.DASHBOARD_PASSWORD || '';
const INTERFACE = process.env.DASHBOARD_INTERFACE || '127.0.0.1';
const PORT = parseInt(process.env.DASHBOARD_PORT || '7900', 10);

const FRONTEND_PATH = '/opt/dashboard/dashboard.html';
const METRICS_PATH = '/home/node/.claude/dashboard-stats.json';

const EMPTY_METRICS = JSON.stringify({
  timestamp: 0,
  host: { cpuPercent: 0, cpuCores: 1, memUsedMb: 0, memTotalMb: 0, diskUsedPercent: 0 },
  containers: {},
  companions: {},
});

if (!PASSWORD) {
  console.error('ERROR: DASHBOARD_PASSWORD is not set. Refusing to start without authentication.');
  process.exit(1);
}

function timingSafeEqual(a, b) {
  const bufA = Buffer.from(a);
  const bufB = Buffer.from(b);
  if (bufA.length !== bufB.length) return false;
  return crypto.timingSafeEqual(bufA, bufB);
}

function checkAuth(req) {
  const header = req.headers['authorization'] || '';
  if (!header.startsWith('Basic ')) return false;
  let decoded;
  try {
    decoded = Buffer.from(header.slice(6), 'base64').toString('utf8');
  } catch {
    return false;
  }
  const sep = decoded.indexOf(':');
  if (sep === -1) return false;
  const user = decoded.slice(0, sep);
  const pass = decoded.slice(sep + 1);
  return timingSafeEqual(user, USERNAME) && timingSafeEqual(pass, PASSWORD);
}

function sendJson(res, status, obj) {
  const body = JSON.stringify(obj);
  res.writeHead(status, { 'Content-Type': 'application/json', 'Content-Length': Buffer.byteLength(body) });
  res.end(body);
}

function sendRaw(res, status, contentType, body) {
  res.writeHead(status, { 'Content-Type': contentType, 'Content-Length': Buffer.byteLength(body) });
  res.end(body);
}

function runScript(bin, args, res, onSuccess) {
  execFile(bin, args, { maxBuffer: 64 * 1024 * 1024 }, (err, stdout, stderr) => {
    if (err) {
      console.error(`${bin} ${args.join(' ')} failed: ${stderr || err.message}`);
      sendJson(res, 500, { ok: false });
      return;
    }
    onSuccess(stdout);
  });
}

function handleApi(req, res, parsedUrl) {
  const { pathname, searchParams } = parsedUrl;

  if (pathname === '/api/sessions' && req.method === 'GET') {
    runScript('claude-dashboard-sessions', ['list'], res, stdout => {
      sendRaw(res, 200, 'application/json', stdout);
    });
    return;
  }

  if (pathname === '/api/preview' && req.method === 'GET') {
    const slug = searchParams.get('slug') || '';
    const session = searchParams.get('session') || '';
    runScript('claude-dashboard-sessions', ['preview', slug, session], res, stdout => {
      sendRaw(res, 200, 'application/json', stdout);
    });
    return;
  }

  if (pathname === '/api/search' && req.method === 'GET') {
    const q = searchParams.get('q') || '';
    const scope = searchParams.get('scope') || 'all';
    const slug = searchParams.get('slug');
    const args = ['--query', q, '--scope', scope];
    if (slug) args.push('--slug', slug);
    runScript('claude-dashboard-search', args, res, stdout => {
      sendRaw(res, 200, 'application/json', stdout);
    });
    return;
  }

  if (pathname === '/api/metrics' && req.method === 'GET') {
    fs.readFile(METRICS_PATH, (err, data) => {
      if (err) {
        sendRaw(res, 200, 'application/json', EMPTY_METRICS);
        return;
      }
      sendRaw(res, 200, 'application/json', data);
    });
    return;
  }

  if (pathname === '/api/delete' && req.method === 'POST') {
    const slug = searchParams.get('slug') || '';
    const session = searchParams.get('session') || '';
    runScript('claude-dashboard-sessions', ['delete', slug, session], res, () => {
      sendJson(res, 200, { ok: true });
    });
    return;
  }

  if (pathname === '/api/rename' && req.method === 'POST') {
    const slug = searchParams.get('slug') || '';
    const session = searchParams.get('session') || '';
    const name = searchParams.get('name') || '';
    runScript('claude-dashboard-names', ['set', slug, session, name], res, () => {
      sendJson(res, 200, { ok: true });
    });
    return;
  }

  sendJson(res, 404, { error: 'not found' });
}

function handleRequest(req, res) {
  res.setHeader('WWW-Authenticate', 'Basic realm="claude-dashboard"');
  if (!checkAuth(req)) {
    sendJson(res, 401, { error: 'unauthorized' });
    return;
  }

  const parsedUrl = new URL(req.url, 'http://localhost');

  if (parsedUrl.pathname === '/' && req.method === 'GET') {
    fs.readFile(FRONTEND_PATH, (err, data) => {
      if (err) {
        sendJson(res, 500, { error: 'frontend not found' });
        return;
      }
      sendRaw(res, 200, 'text/html', data);
    });
    return;
  }

  if (parsedUrl.pathname.startsWith('/api/')) {
    handleApi(req, res, parsedUrl);
    return;
  }

  sendJson(res, 404, { error: 'not found' });
}

process.on('uncaughtException', err => {
  console.error('uncaught exception:', err);
});
process.on('unhandledRejection', err => {
  console.error('unhandled rejection:', err);
});

const httpServer = http.createServer(handleRequest);
httpServer.listen(PORT, INTERFACE, () => {
  console.log(`claude-dashboard-gateway listening on http://${INTERFACE}:${PORT}`);
});
