const { defineConfig } = require('@playwright/test');
const fs = require('fs');

function connectOptions() {
  const endpointFile = process.env.HEALTHIE_QA_BROWSER_WS_FILE;
  if (!endpointFile) return undefined;

  const wsEndpoint = fs.readFileSync(endpointFile, 'utf8').trim();
  if (!wsEndpoint.startsWith('ws://127.0.0.1:')) {
    throw new Error('HEALTHIE_QA_BROWSER_WS_FILE must contain a loopback Playwright websocket endpoint');
  }

  return { wsEndpoint };
}

module.exports = defineConfig({
  testDir: './test/browser', workers: 1,
  reporter: [['list'], ['html', {open: 'never'}]],
  use: {
    browserName: 'chromium',
    headless: process.env.HEADED !== 'true',
    screenshot: 'on',
    trace: 'retain-on-failure',
    baseURL: 'http://127.0.0.1:3100',
    connectOptions: connectOptions()
  },
  webServer: { command: 'RAILS_ENV=test bin/rails server -b 127.0.0.1 -p 3100', url: 'http://127.0.0.1:3100/up', reuseExistingServer: false, timeout: 60000 }
});
