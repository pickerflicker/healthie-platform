const { test, expect, signIn } = require('../support/browser');

test('client Basic/Premium enrollment flow and provider read-only boundaries', async ({ page, browser, scenario }, testInfo) => {
  scenario({
    accounts: {
      "client": {"role": "client", "name": "Quinn Avery"},
      "provider": {"role": "provider", "name": "Robin Lane"},
      "second-provider": {"role": "provider", "name": "Drew Ellis"},
      "empty-provider": {"role": "provider", "name": "Avery Blake"},
      "unrelated-client": {"role": "client", "name": "Rowan Hayes"},
      "empty-client": {"role": "client", "name": "Emery Hale"},
    },
    enrollments: [
      {"client": "client", "provider": "provider", "plan": "basic", "created_at": "2026-10-17T09:00:00Z"},
      {"client": "client", "provider": "second-provider", "plan": "premium", "created_at": "2026-10-19T09:00:00Z"},
      {"client": "unrelated-client", "provider": "provider", "plan": "premium", "created_at": "2026-10-18T09:00:00Z"},
    ],
  });
  await signIn(page, 'empty-client');
  await expect(page).toHaveURL(/\/client$/);
  await page.getByRole('link', { name: 'My providers' }).click();
  await expect(page.getByText('No current relationships.')).toBeVisible();
  await expect(page.getByLabel('Plan', { exact: true })).toHaveValue('basic');
  await expect(page.getByLabel('Provider', { exact: true }).locator('option')).toHaveCount(3);
  await expect(page.locator('main')).toContainText('existing and future journal entries');
  await page.screenshot({ path: testInfo.outputPath('empty-relationships.png'), fullPage: true });
  const providerId = await page.getByLabel('Provider', { exact: true }).locator('option', { hasText: 'Robin Lane' }).getAttribute('value');
  await page.getByLabel('Provider', { exact: true }).selectOption({ label: 'Robin Lane' });
  await page.getByRole('button', { name: 'Add provider', exact: true }).click();
  await expect(page.locator('tbody tr')).toHaveCount(1);
  await expect(page.locator('tbody tr')).toContainText('Robin Lane');
  await expect(page.locator('tbody tr')).toContainText('Basic');
  await expect(page.getByLabel('Provider', { exact: true }).locator('option')).toHaveCount(2);
  await expect(page.getByLabel('Provider', { exact: true })).not.toContainText('Robin Lane');
  const enrollmentURL = await page.locator('tbody form').getAttribute('action');
  const duplicate = await page.request.post('/enrollments', { form: { 'enrollment[provider_id]': providerId, 'enrollment[plan]': 'premium' } });
  expect(duplicate.status()).toBe(422);
  expect(await duplicate.text()).toContain('already enrolled');
  await page.reload();
  await expect(page.locator('tbody tr')).toHaveCount(1);
  await expect(page.locator('tbody tr')).toContainText('Basic');
  await page.screenshot({ path: testInfo.outputPath('basic-added.png'), fullPage: true });
  await page.getByLabel('Provider', { exact: true }).selectOption({ label: 'Drew Ellis' });
  await page.getByLabel('Plan', { exact: true }).selectOption('premium');
  await page.getByRole('button', { name: 'Add provider', exact: true }).click();
  await expect(page.locator('tbody tr')).toHaveCount(2);
  await expect(page.locator('tbody tr').filter({ hasText: 'Drew Ellis' })).toContainText('Premium');
  await expect(page.getByLabel('Provider', { exact: true }).locator('option')).toHaveCount(1);
  await page.screenshot({ path: testInfo.outputPath('premium-added.png'), fullPage: true });

  const providerContext = await browser.newContext();
  const providerPage = await providerContext.newPage();
  await signIn(providerPage, 'provider');
  await expect(providerPage).toHaveURL(/\/provider$/);
  await providerPage.getByRole('link', { name: 'My clients' }).click();
  await expect(providerPage.locator('tbody tr')).toHaveCount(3);
  await expect(providerPage.locator('tbody tr').filter({ hasText: 'Emery Hale' })).toContainText('Basic');
  await expect(providerPage.getByRole('button', { name: /Remove|Add provider/ })).toHaveCount(0);
  expect((await providerPage.request.post('/enrollments', { form: { 'enrollment[provider_id]': providerId } })).status()).toBe(403);
  expect((await providerPage.request.delete(enrollmentURL)).status()).toBe(403);
  await providerPage.screenshot({ path: testInfo.outputPath('provider-read-only.png'), fullPage: true });

  const otherContext = await browser.newContext();
  const otherPage = await otherContext.newPage();
  await signIn(otherPage, 'client');
  await expect(otherPage).toHaveURL(/\/client$/);
  expect((await otherPage.request.delete(enrollmentURL)).status()).toBe(404);
  await otherPage.getByRole('link', { name: 'My providers' }).click();
  await expect(otherPage.locator('tbody tr')).toHaveCount(2);
  await expect(otherPage.locator('tbody tr').filter({ hasText: 'Drew Ellis' })).toContainText('Premium');

  await page.getByRole('button', { name: 'Remove Robin Lane', exact: true }).click();
  await page.getByRole('dialog').getByRole('button', { name: 'Remove provider', exact: true }).click();
  await expect(page.locator('tbody tr')).toHaveCount(1);
  await expect(page.getByLabel('Provider', { exact: true }).locator('option')).toHaveCount(2);
  await expect(page.getByLabel('Provider', { exact: true })).toContainText('Robin Lane');
  await page.screenshot({ path: testInfo.outputPath('relationship-removed.png'), fullPage: true });
  await providerPage.reload();
  await expect(providerPage.locator('tbody tr')).toHaveCount(2);
  await expect(providerPage.locator('main')).not.toContainText('Emery Hale');
  await providerPage.screenshot({ path: testInfo.outputPath('provider-after-removal.png'), fullPage: true });
  await page.getByRole('button', { name: 'Remove Drew Ellis', exact: true }).click();
  await page.getByRole('dialog').getByRole('button', { name: 'Remove provider', exact: true }).click();
  await expect(page.getByText('No current relationships.')).toBeVisible();
  await otherContext.close();
  await providerContext.close();
});
