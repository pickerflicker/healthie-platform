const { test, expect } = require('@playwright/test');
const { execFileSync } = require('node:child_process');

test.beforeEach(() => {
  execFileSync('bin/rails', ['runner', `
    abort 'Test environment required' unless Rails.env.test? && ActiveRecord::Base.connection_db_config.database == 'healthie_test'
    provider = User.find_by!(email: 'provider@healthie.example').provider
    client = User.find_by!(email: 'client@healthie.example').client
    second = User.find_by!(email: 'second-provider@healthie.example').provider
    sam = User.find_by!(email: 'unrelated-client@healthie.example').client
    [[provider, client, Time.utc(2026,10,17)], [provider, sam, Time.utc(2026,10,18)], [second, client, Time.utc(2026,10,19)]].each do |p,c,time|
      Enrollment.find_by!(provider: p, client: c).update!(created_at: time)
    end
    Rails.cache.delete(Client.provider_list_cache_key(client.id))
  `], { env: { ...process.env, RAILS_ENV: 'test' }, stdio: 'pipe' });
});

async function signIn(page, login) {
  await page.goto('/users/sign_in');
  await page.getByLabel('Email').fill(`${login}@healthie.example`);
  await page.getByLabel('Password', { exact: true }).fill('Healthie-demo-2026');
  await page.getByRole('button', { name: 'Sign in', exact: true }).click();
}

// Normalize only these synthetic test relationships; earlier journeys may re-enroll them.
test('enrollment age orders both visible lists; re-enrollment refreshes warm cache', async ({ page }, testInfo) => {
  await signIn(page, 'provider');
  await page.getByRole('link', { name: 'My clients', exact: true }).click();
  await expect(page.locator('tbody tr td:first-child')).toHaveText(['Sam Chen', 'Alex Rivera']);
  await page.screenshot({ path: testInfo.outputPath('provider-enrollment-order.png'), fullPage: true });
  await page.getByRole('button', { name: 'Sign out', exact: true }).click();
  await expect(page).toHaveURL(/\/users\/sign_in$/);
  await signIn(page, 'client');
  await page.getByRole('link', { name: 'My providers', exact: true }).click();
  await expect(page.locator('tbody tr td:first-child')).toHaveText(['Taylor Reed', 'Morgan Patel']);
  await page.reload();
  await expect(page.locator('tbody tr td:first-child')).toHaveText(['Taylor Reed', 'Morgan Patel']);
  await page.screenshot({ path: testInfo.outputPath('client-enrollment-order.png'), fullPage: true });
  await page.getByRole('button', { name: 'Remove Morgan Patel', exact: true }).click();
  await expect(page.locator('tbody tr td:first-child')).toHaveText(['Taylor Reed']);
  await page.getByLabel('Provider', { exact: true }).selectOption({ label: 'Morgan Patel' });
  await page.getByRole('button', { name: 'Add provider', exact: true }).click();
  await expect(page.locator('tbody tr td:first-child')).toHaveText(['Morgan Patel', 'Taylor Reed']);
  await page.reload();
  await expect(page.locator('tbody tr td:first-child')).toHaveText(['Morgan Patel', 'Taylor Reed']);
  await page.screenshot({ path: testInfo.outputPath('client-reenrollment-order.png'), fullPage: true });
});
