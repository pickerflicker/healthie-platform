const { test, expect } = require('@playwright/test');

async function signIn(page, login) {
  await page.goto('/users/sign_in');
  await page.getByLabel('Email').fill(`${login}@healthie.example`);
  await page.getByLabel('Password', { exact: true }).fill('Healthie-demo-2026');
  await page.getByRole('button', { name: 'Sign in', exact: true }).click();
}

// Runs against the isolated, freshly seeded test database, never development.
test('enrollment age and ID ties order both visible lists; re-enrollment refreshes warm cache', async ({ page }, testInfo) => {
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
