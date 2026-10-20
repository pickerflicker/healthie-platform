const { test, expect } = require('@playwright/test');

async function signIn(page, login) {
  await page.goto('/users/sign_in');
  await page.getByLabel('Email').fill(`${login}@healthie.example`);
  await page.getByLabel('Password', { exact: true }).fill('Healthie-demo-2026');
  await page.getByRole('button', { name: 'Sign in', exact: true }).click();
}

test('client Basic/Premium enrollment flow and provider read-only boundaries', async ({ page, browser }, testInfo) => {
  await signIn(page, 'empty-client');
  await page.getByRole('link', { name: 'My providers' }).click();
  await expect(page.getByText('No current relationships.')).toBeVisible();
  await expect(page.getByLabel('Plan', { exact: true })).toHaveValue('basic');
  await expect(page.getByLabel('Provider', { exact: true }).locator('option')).toHaveCount(3);
  await expect(page.locator('main')).toContainText('existing and future journal entries');
  await page.screenshot({ path: testInfo.outputPath('empty-relationships.png'), fullPage: true });
  const providerId = await page.getByLabel('Provider', { exact: true }).locator('option', { hasText: 'Morgan Patel' }).getAttribute('value');
  await page.getByLabel('Provider', { exact: true }).selectOption({ label: 'Morgan Patel' });
  await page.getByRole('button', { name: 'Add provider', exact: true }).click();
  await expect(page.locator('tbody tr')).toHaveCount(1);
  await expect(page.locator('tbody tr')).toContainText('Morgan Patel');
  await expect(page.locator('tbody tr')).toContainText('Basic');
  await expect(page.getByLabel('Provider', { exact: true }).locator('option')).toHaveCount(2);
  await expect(page.getByLabel('Provider', { exact: true })).not.toContainText('Morgan Patel');
  const enrollmentURL = await page.locator('tbody form').getAttribute('action');
  const duplicate = await page.request.post('/enrollments', { form: { 'enrollment[provider_id]': providerId, 'enrollment[plan]': 'premium' } });
  expect(duplicate.status()).toBe(422);
  expect(await duplicate.text()).toContain('already enrolled');
  await page.reload();
  await expect(page.locator('tbody tr')).toHaveCount(1);
  await expect(page.locator('tbody tr')).toContainText('Basic');
  await page.screenshot({ path: testInfo.outputPath('basic-added.png'), fullPage: true });
  await page.getByLabel('Provider', { exact: true }).selectOption({ label: 'Taylor Reed' });
  await page.getByLabel('Plan', { exact: true }).selectOption('premium');
  await page.getByRole('button', { name: 'Add provider', exact: true }).click();
  await expect(page.locator('tbody tr')).toHaveCount(2);
  await expect(page.locator('tbody tr').filter({ hasText: 'Taylor Reed' })).toContainText('Premium');
  await expect(page.getByLabel('Provider', { exact: true }).locator('option')).toHaveCount(1);
  await page.screenshot({ path: testInfo.outputPath('premium-added.png'), fullPage: true });

  const providerContext = await browser.newContext();
  const providerPage = await providerContext.newPage();
  await signIn(providerPage, 'provider');
  await providerPage.getByRole('link', { name: 'My clients' }).click();
  await expect(providerPage.locator('tbody tr')).toHaveCount(3);
  await expect(providerPage.locator('tbody tr').filter({ hasText: 'Jamie Brooks' })).toContainText('Basic');
  await expect(providerPage.getByRole('button', { name: /Remove|Add provider/ })).toHaveCount(0);
  expect((await providerPage.request.post('/enrollments', { form: { 'enrollment[provider_id]': providerId } })).status()).toBe(403);
  expect((await providerPage.request.delete(enrollmentURL)).status()).toBe(403);
  await providerPage.screenshot({ path: testInfo.outputPath('provider-read-only.png'), fullPage: true });

  const otherContext = await browser.newContext();
  const otherPage = await otherContext.newPage();
  await signIn(otherPage, 'client');
  expect((await otherPage.request.delete(enrollmentURL)).status()).toBe(404);
  await otherPage.getByRole('link', { name: 'My providers' }).click();
  await expect(otherPage.locator('tbody tr')).toHaveCount(2);
  await expect(otherPage.locator('tbody tr').filter({ hasText: 'Taylor Reed' })).toContainText('Premium');

  await page.getByRole('button', { name: 'Remove Morgan Patel', exact: true }).click();
  await expect(page.locator('tbody tr')).toHaveCount(1);
  await expect(page.getByLabel('Provider', { exact: true }).locator('option')).toHaveCount(2);
  await expect(page.getByLabel('Provider', { exact: true })).toContainText('Morgan Patel');
  await page.screenshot({ path: testInfo.outputPath('relationship-removed.png'), fullPage: true });
  await providerPage.reload();
  await expect(providerPage.locator('tbody tr')).toHaveCount(2);
  await expect(providerPage.locator('main')).not.toContainText('Jamie Brooks');
  await providerPage.screenshot({ path: testInfo.outputPath('provider-after-removal.png'), fullPage: true });
  await page.getByRole('button', { name: 'Remove Taylor Reed', exact: true }).click();
  await expect(page.getByText('No current relationships.')).toBeVisible();
  await otherContext.close();
  await providerContext.close();
});
