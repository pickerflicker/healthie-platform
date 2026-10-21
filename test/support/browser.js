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

async function signIn(page, login) {
  await page.goto('/users/sign_in');
  await page.getByLabel('Email').fill(`${login}@browser.example.test`);
  await page.getByLabel('Password', { exact: true }).fill('Focused-tests-2026');
  await page.getByRole('button', { name: 'Sign in', exact: true }).click();
}

async function signOut(page) {
  await page.getByRole('button', { name: 'Sign out', exact: true }).click();
  await expect(page).toHaveURL(/\/users\/sign_in$/);
}

module.exports = { test, expect, signIn, signOut };
