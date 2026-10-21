const { test: base, expect } = require('@playwright/test');
const { execFileSync } = require('node:child_process');

function loadScenario(data = {}) {
  execFileSync('bin/rails', ['runner', 'test/support/browser_scenario.rb'], {
    input: JSON.stringify(data),
    env: { ...process.env, RAILS_ENV: 'test' },
    stdio: ['pipe', 'pipe', 'pipe']
  });
}

// Test-scoped, including retries. Browser cases share one database and run serially.
const test = base.extend({
  scenario: async ({}, use) => {
    loadScenario();
    try {
      await use(loadScenario);
    } finally {
      loadScenario();
    }
  }
});

module.exports = { test, expect };
