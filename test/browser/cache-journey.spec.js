const { test, expect } = require('@playwright/test');

async function signIn(page, login) {
  await page.goto('/users/sign_in');
  await page.getByLabel('Email').fill(`${login}@healthie.example`);
  await page.getByLabel('Password', { exact: true }).fill('Healthie-demo-2026');
  await page.getByRole('button', { name: 'Sign in', exact: true }).click();
  await expect(page).toHaveURL(login === 'provider' ? /\/provider$/ : /\/client$/);
}

async function signOut(page) {
  await page.getByRole('button', { name: 'Sign out', exact: true }).click();
  await expect(page).toHaveURL(/\/users\/sign_in$/);
}

async function openSection(page, role, name) {
  await page.getByRole('navigation', { name: 'Account' }).getByRole('link', { name: `${role} home`, exact: true }).click();
  await expect(page).toHaveURL(role === 'Provider' ? /\/provider$/ : /\/client$/);
  await page.getByRole('link', { name, exact: true }).click();
  await expect(page).toHaveURL(name === 'My providers' || name === 'My clients' ? /\/enrollments$/ : /\/journal_entries$/);
}

test('final seeded journey: warm providers, journal CRUD, removal privacy and fresh re-enrollment', async ({ page }, testInfo) => {
  await signIn(page, 'client');
  await openSection(page, 'Client', 'My providers');
  await expect(page.locator('tbody tr')).toHaveCount(2);
  await expect(page.locator('tbody tr').filter({ hasText: 'Morgan Patel' })).toContainText('Basic');
  await page.reload();
  await expect(page.locator('tbody tr')).toHaveCount(2);
  await page.screenshot({ path: testInfo.outputPath('warm-provider-list.png'), fullPage: true });
  await openSection(page, 'Client', 'My journal');
  await page.getByRole('link', { name: 'New journal entry', exact: true }).click();
  await page.getByLabel('Entry text').fill('Cache journey private journal');
  await page.getByRole('button', { name: 'Save entry', exact: true }).click();
  await expect(page).toHaveURL(/\/journal_entries\/\d+$/);
  const entryURL = page.url();
  await page.getByRole('link', { name: 'Edit entry', exact: true }).click();
  await page.getByLabel('Entry text').fill('Cache journey private journal edited');
  await page.getByRole('button', { name: 'Save entry', exact: true }).click();
  await expect(page).toHaveURL(entryURL);
  await page.reload();
  await expect(page.locator('main')).toContainText('Cache journey private journal edited');
  await signOut(page);

  await signIn(page, 'provider');
  await openSection(page, 'Provider', 'Combined journal feed');
  await expect(page.locator('article')).toHaveCount(5);
  await expect(page.locator('article').first()).toContainText('Cache journey private journal edited');
  await openSection(page, 'Provider', 'My clients');
  await page.getByRole('link', { name: 'Alex Rivera', exact: true }).click();
  await expect(page).toHaveURL(/\/clients\/\d+\/journal_entries$/);
  const clientJournalURL = page.url();
  await expect(page.locator('article')).toHaveCount(4);
  await page.goto(entryURL);
  await expect(page.getByRole('link', { name: 'Edit entry', exact: true })).toHaveCount(0);
  expect((await page.request.patch(entryURL, { form: { 'journal_entry[text]': 'forbidden' } })).status()).toBe(403);
  await signOut(page);

  await signIn(page, 'client');
  await openSection(page, 'Client', 'My providers');
  await page.reload(); // Warm membership immediately before revocation.
  await page.getByRole('button', { name: 'Remove Morgan Patel', exact: true }).click();
  await expect(page.locator('tbody tr')).toHaveCount(1);
  await expect(page.locator('tbody')).not.toContainText('Morgan Patel');
  await expect(page.getByLabel('Provider', { exact: true })).toContainText('Morgan Patel');
  await page.screenshot({ path: testInfo.outputPath('fresh-after-removal.png'), fullPage: true });
  await signOut(page);

  await signIn(page, 'provider');
  await openSection(page, 'Provider', 'Combined journal feed');
  await expect(page.locator('article')).toHaveCount(1);
  await expect(page.locator('main')).toContainText('Tried a new breakfast recipe.');
  await expect(page.locator('main')).not.toContainText('Cache journey private journal');
  await page.screenshot({ path: testInfo.outputPath('revoked-from-feed.png'), fullPage: true });
  expect((await page.request.get(clientJournalURL)).status()).toBe(404);
  expect((await page.request.get(entryURL)).status()).toBe(404);
  expect((await page.goto(entryURL)).status()).toBe(404);
  await expect(page.getByRole('heading', { name: 'Page not found', exact: true })).toBeVisible();
  await expect(page.locator('main')).not.toContainText('Cache journey private journal');
  await page.screenshot({ path: testInfo.outputPath('revoked-direct-journal.png'), fullPage: true });
  await signOut(page);

  await signIn(page, 'client');
  await page.goto(entryURL);
  await expect(page.locator('main')).toContainText('Cache journey private journal edited');
  await openSection(page, 'Client', 'My providers');
  await page.getByLabel('Provider', { exact: true }).selectOption({ label: 'Morgan Patel' });
  await page.getByLabel('Plan', { exact: true }).selectOption('premium');
  await page.getByRole('button', { name: 'Add provider', exact: true }).click();
  await expect(page.locator('tbody tr')).toHaveCount(2);
  await expect(page.locator('tbody tr').filter({ hasText: 'Morgan Patel' })).toContainText('Premium');
  await page.screenshot({ path: testInfo.outputPath('fresh-after-add.png'), fullPage: true });
  await signOut(page);

  await signIn(page, 'provider');
  await page.goto(entryURL);
  await expect(page.locator('main')).toContainText('Cache journey private journal edited');
  await page.screenshot({ path: testInfo.outputPath('re-enrolled-journal-access.png'), fullPage: true });
  await signOut(page);
  await signIn(page, 'client');
  await page.goto(entryURL);
  await page.getByRole('button', { name: 'Delete entry', exact: true }).click();
  await expect(page.locator('article')).toHaveCount(3);
  expect((await page.request.get(entryURL)).status()).toBe(404);
  // Restore the original Basic relationship so this journey leaves the seed baseline coherent.
  await openSection(page, 'Client', 'My providers');
  await page.getByRole('button', { name: 'Remove Morgan Patel', exact: true }).click();
  await page.getByLabel('Provider', { exact: true }).selectOption({ label: 'Morgan Patel' });
  await page.getByRole('button', { name: 'Add provider', exact: true }).click();
  await expect(page.locator('tbody tr').filter({ hasText: 'Morgan Patel' })).toContainText('Basic');
});
