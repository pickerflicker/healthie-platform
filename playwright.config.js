const { defineConfig } = require('@playwright/test');
module.exports = defineConfig({
  testDir: './test/browser', workers: 1,
  reporter: [['list'], ['html', {open: 'never'}]],
  use: { browserName: 'chromium', headless: process.env.CI === 'true', screenshot: 'on', trace: 'retain-on-failure', baseURL: 'http://127.0.0.1:3100' },
  webServer: { command: 'RAILS_ENV=test bin/rails server -b 127.0.0.1 -p 3100', url: 'http://127.0.0.1:3100/up', reuseExistingServer: false, timeout: 60000 }
});
