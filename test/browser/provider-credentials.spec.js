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
  await expect(group.getByRole('checkbox')).toHaveCount(50);
  const choices = [
    'DO — Doctor of Osteopathic Medicine',
    'OD — Doctor of Optometry',
    'PA-C — Physician Assistant-Certified',
    'PhD — Doctor of Philosophy',
    'PharmD — Doctor of Pharmacy',
    'CCC-SLP — Certificate of Clinical Competence in Speech-Language Pathology',
    'LAc — Licensed Acupuncturist',
    'NBC-HWC — National Board Certified Health & Wellness Coach'
  ];
  await expect(group.getByRole('group')).toHaveCount(9);
  for (const label of choices) await group.getByLabel(label, { exact: true }).check();
  await page.screenshot({ path: testInfo.outputPath('credential-checkboxes.png'), fullPage: true });
  await page.getByRole('button', { name: 'Save credentials', exact: true }).click();
  await expect(page.getByRole('status')).toHaveText('Credentials saved.');
  await expect(page.locator('main')).toContainText('Welcome Jordan Brooks, DO, OD, PA-C, PhD, PharmD, CCC-SLP, LAc, NBC-HWC.');
  await page.reload();
  await expect(page.locator('main')).toContainText('Welcome Jordan Brooks, DO, OD, PA-C, PhD, PharmD, CCC-SLP, LAc, NBC-HWC.');
  await page.screenshot({ path: testInfo.outputPath('provider-credentials-saved.png'), fullPage: true });
  await clientPage.reload();
  await expect(clientPage.locator('tbody td').first()).toHaveText('Jordan Brooks, DO, OD, PA-C, PhD, PharmD, CCC-SLP, LAc, NBC-HWC');
  await expect(clientPage.locator('tbody tr')).toContainText('Premium');
  await clientPage.screenshot({ path: testInfo.outputPath('client-credential-labels.png'), fullPage: true });

  await page.getByRole('link', { name: 'Edit credentials', exact: true }).click();
  for (const label of choices) await expect(group.getByLabel(label, { exact: true })).toBeChecked();
  // Forged values reach the server through a real browser form and show feedback.
  await page.locator('input[name="provider[credentials][]"][type=hidden]').evaluate(input => { input.value = 'FAKE'; });
  await page.getByRole('button', { name: 'Save credentials', exact: true }).click();
  await expect(page.getByRole('alert')).toContainText('Credentials must contain only supported selections');
  await page.screenshot({ path: testInfo.outputPath('credential-validation.png'), fullPage: true });
  await page.reload();
  for (const label of choices) await group.getByLabel(label, { exact: true }).uncheck();
  await page.getByRole('button', { name: 'Save credentials', exact: true }).click();
  await expect(page.locator('main')).toContainText('Welcome Jordan Brooks.');
  await clientPage.reload();
  await expect(clientPage.locator('tbody td').first()).toHaveText('Jordan Brooks');

  await page.screenshot({ path: testInfo.outputPath('credentials-cleared.png'), fullPage: true });

  // Credentialed providers are also correctly labeled before enrollment.
  await page.getByRole('link', { name: 'Edit credentials', exact: true }).click();
  await group.getByLabel('AuD — Doctor of Audiology', { exact: true }).check();
  await page.getByRole('button', { name: 'Save credentials', exact: true }).click();
  await clientPage.getByRole('button', { name: 'Remove Jordan Brooks', exact: true }).click();
  await clientPage.getByRole('dialog').getByRole('button', { name: 'Remove provider', exact: true }).click();
  await expect(clientPage.getByLabel('Provider', { exact: true }).locator('option')).toHaveText(['Jordan Brooks, AuD', 'Avery Quinn']);
  await clientPage.screenshot({ path: testInfo.outputPath('selector-credentials.png'), fullPage: true });
  await clientContext.close();
});
