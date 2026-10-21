const { test, expect, signIn } = require('../support/browser');

test('client journal persisted CRUD journey', async ({ page, scenario }, testInfo) => {
  scenario({
    accounts: {
      "client": {"role": "client", "name": "Quinn Avery"},
    },
    entries: [
      {"client": "client", "text": "First older journal", "created_at": "2026-10-17T08:00:00Z"},
      {"client": "client", "text": "Second tied journal", "created_at": "2026-10-19T08:00:00Z"},
      {"client": "client", "text": "Third tied journal", "created_at": "2026-10-19T08:00:00Z"},
    ],
  });
  await signIn(page, 'client');
  await page.getByRole('link', { name: 'My journal', exact: true }).click();
  await expect(page.locator('article')).toHaveCount(3);
  await expect(page.locator('article').nth(0)).toContainText('Third tied journal');
  await expect(page.locator('article').nth(1)).toContainText('Second tied journal');
  await expect(page.locator('article').nth(2)).toContainText('First older journal');
  await page.screenshot({ path: testInfo.outputPath('journal-list.png'), fullPage: true });
  await page.getByRole('link', { name: 'New journal entry' }).click();
  await page.getByLabel('Entry text').fill('QA journal: a walk outside.\nFeeling refreshed.');
  await page.getByRole('button', { name: 'Save entry' }).click();
  await expect(page).toHaveURL(/\/journal_entries\/\d+$/);
  await expect(page.getByRole('heading', { name: 'Journal entry', exact: true })).toBeVisible();
  await expect(page.locator('main')).toContainText('QA journal: a walk outside.');
  const entryURL = page.url();
  await page.reload();
  await expect(page.locator('main')).toContainText('Feeling refreshed.');
  await page.screenshot({ path: testInfo.outputPath('journal-created.png'), fullPage: true });
  await page.getByRole('link', { name: 'Edit entry' }).click();
  await page.getByLabel('Entry text').fill('QA journal: updated after lunch.');
  await page.getByRole('button', { name: 'Save entry' }).click();
  await expect(page).toHaveURL(entryURL);
  await expect(page.getByRole('heading', { name: 'Journal entry', exact: true })).toBeVisible();
  await page.reload();
  await expect(page.locator('main')).toContainText('QA journal: updated after lunch.');
  await page.screenshot({ path: testInfo.outputPath('journal-edited.png'), fullPage: true });
  await page.getByRole('link', { name: 'My journal', exact: true }).click();
  await expect(page.locator('article')).toHaveCount(4);
  await expect(page.locator('article').first()).toContainText('QA journal: updated after lunch.');
  await page.goto(entryURL);
  await page.getByRole('button', { name: 'Delete entry' }).click();
  await expect(page).toHaveURL(/\/journal_entries$/);
  await page.reload();
  await expect(page.locator('article')).toHaveCount(3);
  await expect(page.locator('main')).not.toContainText('QA journal:');
  await page.screenshot({ path: testInfo.outputPath('journal-deleted.png'), fullPage: true });
  expect((await page.request.get(entryURL)).status()).toBe(404);
});
