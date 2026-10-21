const { test, expect } = require('@playwright/test');

async function signIn(page, login) {
  await page.goto('/users/sign_in');
  await page.getByLabel('Email').fill(`${login}@healthie.example`);
  await page.getByLabel('Password', { exact: true }).fill('Healthie-demo-2026');
  await page.getByRole('button', { name: 'Sign in', exact: true }).click();
}

async function signOut(page) {
  await page.getByRole('button', { name: 'Sign out', exact: true }).click();
  await expect(page).toHaveURL(/\/users\/sign_in$/);
}

test('seeded provider combined feed, shared client journal, plans and unrelated denials', async ({ page }, testInfo) => {
  await signIn(page, 'provider');
  await page.getByRole('link', { name: 'Combined journal feed', exact: true }).click();
  await expect(page.locator('article')).toHaveCount(4);
  for (const [index, text] of ['Tried a new breakfast', 'An evening stretch', 'Prepared lunch', 'Walked after breakfast'].entries()) {
    await expect(page.locator('article').nth(index)).toContainText(text);
  }
  await page.screenshot({ path: testInfo.outputPath('combined-feed.png'), fullPage: true });
  await page.getByRole('link', { name: 'My clients', exact: true }).click();
  await expect(page.locator('tbody tr').filter({ hasText: 'Alex Rivera' })).toContainText('Basic');
  await expect(page.locator('tbody tr').filter({ hasText: 'Sam Chen' })).toContainText('Premium');
  const samJournal = await page.getByRole('link', { name: 'Sam Chen', exact: true }).getAttribute('href');
  await page.getByRole('link', { name: 'Alex Rivera', exact: true }).click();
  await expect(page.getByRole('heading', { name: "Alex Rivera's journal", exact: true })).toBeVisible();
  await expect(page.locator('article')).toHaveCount(3);
  await expect(page.locator('article').nth(0)).toContainText('An evening stretch');
  await expect(page.locator('article').nth(1)).toContainText('Prepared lunch');
  await expect(page.locator('article').nth(2)).toContainText('Walked after breakfast');
  await expect(page.getByRole('link', { name: 'New journal entry' })).toHaveCount(0);
  await page.screenshot({ path: testInfo.outputPath('individual-journal.png'), fullPage: true });
  const entryURL = await page.locator('article h2 a').first().getAttribute('href');
  await page.goto(entryURL);
  await expect(page.getByRole('link', { name: 'Edit entry' })).toHaveCount(0);
  await expect(page.getByRole('button', { name: 'Delete entry' })).toHaveCount(0);
  expect((await page.request.get(`${entryURL}/edit`)).status()).toBe(403);
  expect((await page.request.patch(entryURL, { form: { 'journal_entry[text]': 'provider forged text' } })).status()).toBe(403);
  expect((await page.request.delete(entryURL)).status()).toBe(403);
  expect((await page.request.get('/journal_entries/new')).status()).toBe(403);
  expect((await page.request.post('/journal_entries', { form: { 'journal_entry[text]': 'provider forged text' } })).status()).toBe(403);
  await page.reload();
  await expect(page.locator('main')).toContainText('An evening stretch');
  await page.screenshot({ path: testInfo.outputPath('read-only-entry.png'), fullPage: true });
  await signOut(page);
  await signIn(page, 'second-provider');
  await page.getByRole('link', { name: 'My clients', exact: true }).click();
  await expect(page.locator('tbody tr')).toHaveCount(1);
  await expect(page.locator('tbody tr')).toContainText('Premium');
  await page.getByRole('link', { name: 'Combined journal feed', exact: true }).click();
  await expect(page.locator('article')).toHaveCount(3);
  await expect(page.locator('main')).not.toContainText('Tried a new breakfast');
  expect((await page.goto(samJournal)).status()).toBe(404);
  await expect(page.getByRole('heading', { name: 'Page not found', exact: true })).toBeVisible();
  await page.screenshot({ path: testInfo.outputPath('unrelated-denied.png'), fullPage: true });
  await page.getByRole('link', { name: 'Return home', exact: true }).click();
  await expect(page).toHaveURL(/\/provider$/);
  await expect(page.getByRole('heading', { name: 'Provider home', exact: true })).toBeVisible();
});

test('warm provider list refreshes on enrollment changes and journal access is granted then revoked', async ({ page }, testInfo) => {
  await signIn(page, 'empty-provider');
  await page.getByRole('link', { name: 'Combined journal feed', exact: true }).click();
  await expect(page.getByText('No journal entries yet.')).toBeVisible();
  await page.screenshot({ path: testInfo.outputPath('empty-feed.png'), fullPage: true });
  await signOut(page);

  await signIn(page, 'client');
  await page.getByRole('link', { name: 'My journal', exact: true }).click();
  const entryURL = await page.locator('article h2 a').last().getAttribute('href');
  await page.getByRole('link', { name: 'Client home', exact: true }).last().click();
  await page.getByRole('link', { name: 'My providers', exact: true }).click();
  await expect(page.locator('tbody tr')).toHaveCount(2);
  await page.reload(); // Exercise the existing cached list before adding a provider.
  await expect(page.locator('tbody tr')).toHaveCount(2);
  await expect(page.locator('tbody')).not.toContainText('Casey Park');
  await page.getByLabel('Provider', { exact: true }).selectOption({ label: 'Casey Park' });
  await page.getByRole('button', { name: 'Add provider', exact: true }).click();
  await expect(page.locator('tbody tr')).toHaveCount(3);
  await expect(page.locator('tbody tr').filter({ hasText: 'Casey Park' })).toContainText('Basic');
  await page.reload();
  await expect(page.locator('tbody tr')).toHaveCount(3);
  await expect(page.locator('tbody')).toContainText('Casey Park');
  await page.screenshot({ path: testInfo.outputPath('provider-added.png'), fullPage: true });
  await signOut(page);

  await signIn(page, 'empty-provider');
  await page.getByRole('link', { name: 'My clients', exact: true }).click();
  await page.getByRole('link', { name: 'Alex Rivera', exact: true }).click();
  await expect(page).toHaveURL(/\/clients\/\d+\/journal_entries$/);
  const clientJournalURL = page.url();
  await expect(page.locator('article')).toHaveCount(3);
  await expect(page.locator('article').last()).toContainText('Walked after breakfast');
  await page.screenshot({ path: testInfo.outputPath('historical-access-granted.png'), fullPage: true });
  await page.goto(entryURL);
  await expect(page.locator('main')).toContainText('Walked after breakfast');
  await signOut(page);

  await signIn(page, 'client');
  await page.getByRole('link', { name: 'My providers', exact: true }).click();
  await expect(page).toHaveURL(/\/enrollments$/);
  await expect(page.locator('tbody tr')).toHaveCount(3);
  await page.reload(); // Warm membership immediately before revocation.
  await expect(page.locator('tbody')).toContainText('Casey Park');
  await page.getByRole('button', { name: 'Remove Casey Park', exact: true }).click();
  await expect(page.locator('tbody tr')).toHaveCount(2);
  await expect(page.locator('tbody')).not.toContainText('Casey Park');
  await expect(page.getByLabel('Provider', { exact: true })).toContainText('Casey Park');
  await page.reload();
  await expect(page.locator('tbody tr')).toHaveCount(2);
  await expect(page.locator('tbody')).not.toContainText('Casey Park');
  await page.screenshot({ path: testInfo.outputPath('provider-removed.png'), fullPage: true });
  await page.goto(entryURL);
  await expect(page.locator('main')).toContainText('Walked after breakfast');
  await signOut(page);

  await signIn(page, 'empty-provider');
  await page.getByRole('link', { name: 'Combined journal feed', exact: true }).click();
  await expect(page.locator('article')).toHaveCount(0);
  await expect(page.getByText('No journal entries yet.')).toBeVisible();
  await page.screenshot({ path: testInfo.outputPath('feed-access-revoked.png'), fullPage: true });
  expect((await page.request.get(clientJournalURL)).status()).toBe(404);
  expect((await page.request.patch(entryURL, { form: { 'journal_entry[text]': 'removed provider' } })).status()).toBe(404);
  expect((await page.request.delete(entryURL)).status()).toBe(404);
  expect((await page.goto(entryURL)).status()).toBe(404);
  await expect(page.getByRole('heading', { name: 'Page not found', exact: true })).toBeVisible();
  await expect(page.locator('main')).not.toContainText('Walked after breakfast');
  await expect(page.locator('body')).not.toContainText('ActiveRecord::RecordNotFound');
  await page.screenshot({ path: testInfo.outputPath('direct-access-revoked.png'), fullPage: true });
  await page.getByRole('link', { name: 'Return home', exact: true }).click();
  await expect(page).toHaveURL(/\/provider$/);
  await expect(page.getByRole('heading', { name: 'Provider home', exact: true })).toBeVisible();
  expect((await page.goto(clientJournalURL)).status()).toBe(404);
  await expect(page.getByRole('heading', { name: 'Page not found', exact: true })).toBeVisible();
  await page.screenshot({ path: testInfo.outputPath('client-journal-access-revoked.png'), fullPage: true });
});
