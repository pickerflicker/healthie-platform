const { test, expect, signIn, signOut } = require('../support/browser');

test('enrollment age orders both visible lists; re-enrollment refreshes warm cache', async ({ page, scenario }, testInfo) => {
  scenario({
    accounts: {
      "client": {"role": "client", "name": "Quinn Avery"},
      "provider": {"role": "provider", "name": "Robin Lane"},
      "second-provider": {"role": "provider", "name": "Drew Ellis"},
      "unrelated-client": {"role": "client", "name": "Rowan Hayes"},
    },
    enrollments: [
      {"client": "client", "provider": "provider", "plan": "basic", "created_at": "2026-10-17T09:00:00Z"},
      {"client": "client", "provider": "second-provider", "plan": "premium", "created_at": "2026-10-19T09:00:00Z"},
      {"client": "unrelated-client", "provider": "provider", "plan": "premium", "created_at": "2026-10-18T09:00:00Z"},
    ],
  });
  await signIn(page, 'provider');
  await page.getByRole('link', { name: 'My clients', exact: true }).click();
  await expect(page.locator('tbody tr td:first-child')).toHaveText(['Rowan Hayes', 'Quinn Avery']);
  await page.screenshot({ path: testInfo.outputPath('provider-enrollment-order.png'), fullPage: true });
  await signOut(page);
  await signIn(page, 'client');
  await page.getByRole('link', { name: 'My providers', exact: true }).click();
  await expect(page.locator('tbody tr td:first-child')).toHaveText(['Drew Ellis', 'Robin Lane']);
  await page.reload();
  await expect(page.locator('tbody tr td:first-child')).toHaveText(['Drew Ellis', 'Robin Lane']);
  await page.screenshot({ path: testInfo.outputPath('client-enrollment-order.png'), fullPage: true });
  await page.getByRole('button', { name: 'Remove Robin Lane', exact: true }).click();
  await expect(page.locator('tbody tr td:first-child')).toHaveText(['Drew Ellis']);
  await page.getByLabel('Provider', { exact: true }).selectOption({ label: 'Robin Lane' });
  await page.getByRole('button', { name: 'Add provider', exact: true }).click();
  await expect(page.locator('tbody tr td:first-child')).toHaveText(['Robin Lane', 'Drew Ellis']);
  await page.reload();
  await expect(page.locator('tbody tr td:first-child')).toHaveText(['Robin Lane', 'Drew Ellis']);
  await page.screenshot({ path: testInfo.outputPath('client-reenrollment-order.png'), fullPage: true });
});
