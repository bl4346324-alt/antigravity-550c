import { readFileSync } from 'node:fs';
import { dirname, join } from 'node:path';
import { fileURLToPath, pathToFileURL } from 'node:url';
import { createServer } from 'node:http';
import { homedir } from 'node:os';

const HERE = dirname(fileURLToPath(import.meta.url));

async function loadSidecarSdk() {
  try {
    return await import('sidecar_sdk');
  } catch (err) {
    const defaultPath = join(homedir(), '.gemini', 'antigravity', 'lib', 'node_modules', 'sidecar_sdk', 'index.mjs');
    try {
      return await import(pathToFileURL(defaultPath).href);
    } catch (e) {
      return null;
    }
  }
}

const htmlContent = readFileSync(join(HERE, 'index.html'), 'utf8');

if (process.env.ANTIGRAVITY_SIDECAR_WEB_PORT) {
  const sdk = await loadSidecarSdk();
  if (sdk && sdk.SidecarApp) {
    const { SidecarApp, Response } = sdk;
    const app = new SidecarApp();
    app.page('/', () => new Response(htmlContent, {
      contentType: 'text/html; charset=utf-8',
      headers: { 'Cache-Control': 'no-store' }
    }));
    await app.run();
  } else {
    const port = parseInt(process.env.ANTIGRAVITY_SIDECAR_WEB_PORT, 10);
    const server = createServer((req, res) => {
      res.writeHead(200, {
        'Content-Type': 'text/html; charset=utf-8',
        'Cache-Control': 'no-store'
      });
      res.end(htmlContent);
    });
    server.listen(port, '127.0.0.1');
  }
} else {
  const port = 5500;
  const server = createServer((req, res) => {
    res.writeHead(200, {
      'Content-Type': 'text/html; charset=utf-8',
      'Cache-Control': 'no-store'
    });
    res.end(htmlContent);
  });
  server.listen(port, '127.0.0.1', () => {
    console.log(`[550c-terminal] listening on http://127.0.0.1:${port}`);
  });
}
