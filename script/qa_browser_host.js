const fs = require('fs');
const path = require('path');
const { chromium } = require('@playwright/test');

const endpointFile = process.argv[2];
if (!endpointFile) throw new Error('endpoint file path is required');

let browserServer;

async function close() {
  try { fs.unlinkSync(endpointFile); } catch (error) {
    if (error.code !== 'ENOENT') throw error;
  }
  if (browserServer) await browserServer.close();
}

async function main() {
  browserServer = await chromium.launchServer({ headless: false });
  fs.mkdirSync(path.dirname(endpointFile), { recursive: true });
  fs.writeFileSync(endpointFile, `${browserServer.wsEndpoint()}\n`, { mode: 0o600 });

  process.on('SIGINT', async () => { await close(); process.exit(0); });
  process.on('SIGTERM', async () => { await close(); process.exit(0); });
  await new Promise(() => {});
}

main().catch(async error => {
  await close();
  console.error(error.message);
  process.exit(1);
});
