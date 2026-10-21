const { test, expect, signIn } = require('../support/browser');

test('provider edits multiple credentials and clears them; client labels refresh', async ({ page, browser, scenario }, testInfo) => {
  scenario({
    accounts: {
      practitioner: { role: 'provider', name: 'Jordan Brooks' },
      uncredentialed: { role: 'provider', name: 'Avery Quinn' },
      reader: { role: 'client', name: 'Riley Lane' }
    },
    enrollments: [{ client: 'reader', provider: 'practitioner', plan: 'premium' }]
  });
  const clientContext = await browser.newContext();
  const clientPage = await clientContext.newPage();
  await signIn(clientPage, 'reader');
  await clientPage.getByRole('link', { name: 'My providers', exact: true }).click();
  await expect(clientPage.locator('tbody td').first()).toHaveText('Jordan Brooks');
  await expect(clientPage.getByLabel('Provider', { exact: true }).locator('option')).toHaveText(['Avery Quinn']);

  await signIn(page, 'practitioner');
  await page.getByRole('link', { name: 'Edit credentials', exact: true }).click();
  const group = page.getByRole('group', { name: 'Credentials', exact: true });
  await expect(group.getByRole('checkbox')).toHaveCount(6);
  await group.getByLabel('LD — Licensed Dietitian', { exact: true }).check();
  await group.getByLabel('RDN — Registered Dietitian Nutritionist', { exact: true }).check();
  await page.screenshot({ path: testInfo.outputPath('credential-checkboxes.png'), fullPage: true });
  await page.getByRole('button', { name: 'Save credentials', exact: true }).click();
  await expect(page.getByRole('status')).toHaveText('Credentials saved.');
  await expect(page.locator('main')).toContainText('Welcome, Jordan Brooks, RDN, LD.');
  await page.reload();
  await expect(page.locator('main')).toContainText('Welcome, Jordan Brooks, RDN, LD.');
  await page.screenshot({ path: testInfo.outputPath('provider-credentials-saved.png'), fullPage: true });
  await clientPage.reload();
  await expect(clientPage.locator('tbody td').first()).toHaveText('Jordan Brooks, RDN, LD');
  await expect(clientPage.locator('tbody tr')).toContainText('Premium');
  await clientPage.screenshot({ path: testInfo.outputPath('client-credential-labels.png'), fullPage: true });

  await page.getByRole('link', { name: 'Edit credentials', exact: true }).click();
  await expect(group.getByLabel('RDN — Registered Dietitian Nutritionist', { exact: true })).toBeChecked();
  await expect(group.getByLabel('LD — Licensed Dietitian', { exact: true })).toBeChecked();
  // Forged values reach the server through a real browser form and show feedback.
  await page.locator('input[name="provider[credentials][]"][type=hidden]').evaluate(input => { input.value = 'FAKE'; });
  await page.getByRole('button', { name: 'Save credentials', exact: true }).click();
  await expect(page.getByRole('alert')).toContainText('Credentials must contain only supported selections');
  await page.screenshot({ path: testInfo.outputPath('credential-validation.png'), fullPage: true });
  await page.reload();
  await group.getByLabel('RDN — Registered Dietitian Nutritionist', { exact: true }).uncheck();
  await group.getByLabel('LD — Licensed Dietitian', { exact: true }).uncheck();
  await page.getByRole('button', { name: 'Save credentials', exact: true }).click();
  await expect(page.locator('main')).toContainText('Welcome, Jordan Brooks.');
  await clientPage.reload();
  await expect(clientPage.locator('tbody td').first()).toHaveText('Jordan Brooks');

  // Credentialed providers are also correctly labeled before enrollment.
  await page.getByRole('link', { name: 'Edit credentials', exact: true }).click();
  await group.getByLabel('MD — Doctor of Medicine', { exact: true }).check();
  await page.getByRole('button', { name: 'Save credentials', exact: true }).click();
  await clientPage.getByRole('button', { name: 'Remove Jordan Brooks', exact: true }).click();
  await expect(clientPage.getByLabel('Provider', { exact: true }).locator('option')).toHaveText(['Jordan Brooks, MD', 'Avery Quinn']);
  await clientPage.screenshot({ path: testInfo.outputPath('selector-credentials.png'), fullPage: true });
  await clientContext.close();
});
