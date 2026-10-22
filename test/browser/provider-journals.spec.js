const { test, expect, signIn, signOut } = require('../support/browser');

test('provider combined feed, provider-attributed client journal, plans and unrelated denials', async ({ page, scenario }, testInfo) => {
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
    entries: [
      {"client": "client", "provider": "provider", "text": "First older journal", "created_at": "2026-10-17T08:00:00Z"},
      {"client": "client", "provider": "provider", "text": "Second tied journal", "created_at": "2026-10-19T08:00:00Z"},
      {"client": "client", "provider": "provider", "text": "Third tied journal", "created_at": "2026-10-19T08:00:00Z"},
      {"client": "unrelated-client", "provider": "provider", "text": "Other client journal.", "created_at": "2026-10-20T08:00:00Z"},
      {"client": "client", "provider": "second-provider", "text": "Second-provider private journal"},
    ],
  });
  await signIn(page, 'provider');
  await page.getByRole('link', { name: 'Combined journal feed', exact: true }).click();
  await expect(page.locator('article')).toHaveCount(4);
  for (const [index, text] of ['Other client journal', 'Third tied journal', 'Second tied journal', 'First older journal'].entries()) {
    await expect(page.locator('article').nth(index)).toContainText(text);
  }
  await page.screenshot({ path: testInfo.outputPath('combined-feed.png'), fullPage: true });
  await page.getByRole('navigation', { name: 'Workspace', exact: true }).getByRole('link', { name: 'Clients', exact: true }).click();
  await expect(page.locator('tbody tr').filter({ hasText: 'Quinn Avery' })).toContainText('Basic');
  await expect(page.locator('tbody tr').filter({ hasText: 'Rowan Hayes' })).toContainText('Premium');
  const samJournal = await page.getByRole('link', { name: 'Rowan Hayes', exact: true }).getAttribute('href');
  await page.getByRole('link', { name: 'Quinn Avery', exact: true }).click();
  await expect(page.getByRole('heading', { name: "Quinn Avery's journal", exact: true })).toBeVisible();
  await expect(page.locator('article')).toHaveCount(3);
  await expect(page.locator('article').nth(0)).toContainText('Third tied journal');
  await expect(page.locator('article').nth(1)).toContainText('Second tied journal');
  await expect(page.locator('article').nth(2)).toContainText('First older journal');
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
  await expect(page.locator('main')).toContainText('Third tied journal');
  await page.screenshot({ path: testInfo.outputPath('read-only-entry.png'), fullPage: true });
  await signOut(page);
  await signIn(page, 'second-provider');
  await page.getByRole('navigation', { name: 'Workspace', exact: true }).getByRole('link', { name: 'Clients', exact: true }).click();
  await expect(page.locator('tbody tr')).toHaveCount(1);
  await expect(page.locator('tbody tr')).toContainText('Premium');
  await page.getByRole('link', { name: 'Combined journal feed', exact: true }).click();
  await expect(page.locator('article')).toHaveCount(1);
  await expect(page.locator('main')).toContainText('Second-provider private journal');
  await expect(page.locator('main')).not.toContainText('Third tied journal');
  expect((await page.request.get(entryURL)).status()).toBe(404);
  await expect(page.locator('main')).not.toContainText('Other client journal');
  expect((await page.goto(samJournal)).status()).toBe(404);
  await expect(page.getByRole('heading', { name: 'We couldn’t find that page.', exact: true })).toBeVisible();
  await page.screenshot({ path: testInfo.outputPath('unrelated-denied.png'), fullPage: true });
  await page.getByRole('link', { name: 'Return home', exact: true }).click();
  await expect(page).toHaveURL(/\/provider$/);
  await expect(page.getByRole('heading', { name: /Good to see you/ , exact: false })).toBeVisible();
});

test('warm provider list refreshes on enrollment changes and journal access is granted then revoked', async ({ page, scenario }, testInfo) => {
  scenario({
    accounts: {
      "client": {"role": "client", "name": "Quinn Avery"},
      "current-provider": {"role": "provider", "name": "Robin Lane"},
      "empty-provider": {"role": "provider", "name": "Avery Blake"},
    },
    enrollments: [
      {"client": "client", "provider": "current-provider", "plan": "basic"},
      {"client": "client", "provider": "empty-provider", "plan": "basic"},
    ],
    removed_enrollments: [{ client: "client", provider: "empty-provider" }],
    entries: [
      {"client": "client", "provider": "empty-provider", "text": "First older journal", "created_at": "2026-10-17T08:00:00Z"},
      {"client": "client", "provider": "empty-provider", "text": "Second tied journal", "created_at": "2026-10-19T08:00:00Z"},
      {"client": "client", "provider": "empty-provider", "text": "Third tied journal", "created_at": "2026-10-19T08:00:00Z"},
    ],
  });
  await signIn(page, 'empty-provider');
  await page.getByRole('link', { name: 'Combined journal feed', exact: true }).click();
  await expect(page.getByText('No journal entries yet.')).toBeVisible();
  await page.screenshot({ path: testInfo.outputPath('empty-feed.png'), fullPage: true });
  await signOut(page);

  await signIn(page, 'client');
  await page.getByRole('link', { name: 'My journal', exact: true }).click();
  const entryURL = await page.locator('article h2 a').last().getAttribute('href');
  await page.getByRole('link', { name: 'Client home', exact: true }).first().click();
  await page.getByRole('link', { name: 'My providers', exact: true }).click();
  await expect(page.locator('tbody tr')).toHaveCount(1);
  await page.reload(); // Exercise the existing cached list before adding a provider.
  await expect(page.locator('tbody tr')).toHaveCount(1);
  await expect(page.locator('tbody')).not.toContainText('Avery Blake');
  await expect(page.locator('tbody')).toContainText('Robin Lane');
  await page.getByLabel('Provider', { exact: true }).selectOption({ label: 'Avery Blake' });
  await page.getByRole('button', { name: 'Add provider', exact: true }).click();
  await expect(page.locator('tbody tr')).toHaveCount(2);
  await expect(page.locator('tbody tr').filter({ hasText: 'Avery Blake' })).toContainText('Basic');
  await page.reload();
  await expect(page.locator('tbody tr')).toHaveCount(2);
  await expect(page.locator('tbody')).toContainText('Avery Blake');
  await page.screenshot({ path: testInfo.outputPath('provider-added.png'), fullPage: true });
  await signOut(page);

  await signIn(page, 'empty-provider');
  await page.getByRole('navigation', { name: 'Workspace', exact: true }).getByRole('link', { name: 'Clients', exact: true }).click();
  await page.getByRole('link', { name: 'Quinn Avery', exact: true }).click();
  await expect(page).toHaveURL(/\/clients\/\d+\/journal_entries$/);
  const clientJournalURL = page.url();
  await expect(page.locator('article')).toHaveCount(3);
  await expect(page.locator('article').last()).toContainText('First older journal');
  await page.screenshot({ path: testInfo.outputPath('historical-access-granted.png'), fullPage: true });
  await page.goto(entryURL);
  await expect(page.locator('main')).toContainText('First older journal');
  await signOut(page);

  await signIn(page, 'client');
  await page.getByRole('link', { name: 'My providers', exact: true }).click();
  await expect(page).toHaveURL(/\/enrollments$/);
  await expect(page.locator('tbody tr')).toHaveCount(2);
  await page.reload(); // Warm membership immediately before revocation.
  await expect(page.locator('tbody')).toContainText('Avery Blake');
  await page.getByRole('button', { name: 'Remove Avery Blake', exact: true }).click();
  await page.getByRole('dialog').getByRole('button', { name: 'Remove provider', exact: true }).click();
  await expect(page.locator('tbody tr')).toHaveCount(1);
  await expect(page.locator('tbody')).not.toContainText('Avery Blake');
  await expect(page.locator('tbody')).toContainText('Robin Lane');
  await expect(page.getByLabel('Provider', { exact: true })).toContainText('Avery Blake');
  await page.reload();
  await expect(page.locator('tbody tr')).toHaveCount(1);
  await expect(page.locator('tbody')).not.toContainText('Avery Blake');
  await expect(page.locator('tbody')).toContainText('Robin Lane');
  await page.screenshot({ path: testInfo.outputPath('provider-removed.png'), fullPage: true });
  await page.goto(entryURL);
  await expect(page.locator('main')).toContainText('First older journal');
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
  await expect(page.getByRole('heading', { name: 'We couldn’t find that page.', exact: true })).toBeVisible();
  await expect(page.locator('main')).not.toContainText('First older journal');
  await expect(page.locator('body')).not.toContainText('ActiveRecord::RecordNotFound');
  await page.screenshot({ path: testInfo.outputPath('direct-access-revoked.png'), fullPage: true });
  await page.getByRole('link', { name: 'Return home', exact: true }).click();
  await expect(page).toHaveURL(/\/provider$/);
  await expect(page.getByRole('heading', { name: /Good to see you/ , exact: false })).toBeVisible();
  expect((await page.goto(clientJournalURL)).status()).toBe(404);
  await expect(page.getByRole('heading', { name: 'We couldn’t find that page.', exact: true })).toBeVisible();
  await page.screenshot({ path: testInfo.outputPath('client-journal-access-revoked.png'), fullPage: true });
});
