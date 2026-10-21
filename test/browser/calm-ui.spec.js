const { test, expect, signIn } = require('../support/browser');

const accounts = {
  writer: { role: 'client', name: 'Riley Long-Name Montgomery', },
  first: { role: 'provider', name: 'Morgan Long-Name Rivera' },
  second: { role: 'provider', name: 'Taylor Reed' }
};

test('confirmations cancel, dismiss, restore focus and mutate only the selected records', async ({ page, scenario }) => {
  scenario({ accounts, enrollments: [
    { client: 'writer', provider: 'first', plan: 'premium' },
    { client: 'writer', provider: 'second', plan: 'basic' }
  ], entries: [{ client: 'writer', text: 'Keep this reflection.' }, { client: 'writer', text: 'Selected reflection.' }] });
  await signIn(page, 'writer');
  await expect(page).toHaveURL(/\/client$/);
  await page.goto('/enrollments');
  const remove = page.getByRole('button', { name: 'Remove Morgan Long-Name Rivera', exact: true });
  await remove.click();
  const dialog = page.getByRole('dialog');
  await expect(dialog).toContainText('Morgan Long-Name Rivera will lose access');
  await expect(dialog).toContainText('other current providers will keep their access');
  await expect(dialog.getByRole('button', { name: 'Keep provider' })).toBeFocused();
  await page.keyboard.press('Tab');
  await expect(dialog.getByRole('button', { name: 'Remove provider', exact: true })).toBeFocused();
  await page.keyboard.press('Shift+Tab');
  await expect(dialog.getByRole('button', { name: 'Keep provider' })).toBeFocused();
  await page.keyboard.press('Escape');
  await expect(dialog).not.toBeVisible();
  await expect(remove).toBeFocused();
  await expect(page.locator('tbody tr')).toHaveCount(2);
  await remove.click();
  await dialog.getByRole('button', { name: 'Keep provider' }).click();
  await expect(remove).toBeFocused();
  await remove.click();
  await dialog.getByRole('button', { name: 'Remove provider', exact: true }).click();
  await expect(page.locator('tbody tr')).toHaveCount(1);
  await page.reload();
  await expect(page.locator('tbody td').first()).toHaveText('Taylor Reed');
  await page.goto('/journal_entries');
  await expect(page.locator('article')).toHaveCount(2);
  await page.locator('article').filter({ hasText: 'Selected reflection.' }).getByRole('link').click();
  await expect(page).toHaveURL(/\/journal_entries\/\d+$/);
  const selectedURL = page.url();
  const destroy = page.locator('button[aria-haspopup=dialog]').filter({ hasText: 'Delete entry' });
  await destroy.click();
  await page.getByRole('dialog').getByRole('button', { name: 'Keep entry' }).click();
  await expect(destroy).toBeFocused();
  await expect(page.locator('main')).toContainText('Selected reflection.');
  await destroy.click();
  await page.keyboard.press('Escape');
  await expect(destroy).toBeFocused();
  await destroy.click();
  await page.getByRole('dialog').getByRole('button', { name: 'Delete entry', exact: true }).click();
  await expect(page).toHaveURL(/\/journal_entries$/);
  await page.reload();
  await expect(page.locator('article')).toHaveCount(1);
  await expect(page.locator('article')).toContainText('Keep this reflection.');
  expect((await page.request.get(selectedURL)).status()).toBe(404);
});

test('server validation recovers and pending feedback prevents repeated entry submissions', async ({ page, scenario }) => {
  scenario({ accounts });
  await signIn(page, 'writer');
  await expect(page).toHaveURL(/\/client$/);
  await page.goto('/journal_entries/new');
  await page.getByLabel('Entry text').fill('   '); // Passes required, reaches real server validation.
  await page.getByRole('button', { name: 'Save entry' }).click();
  await expect(page.getByRole('alert')).toContainText("Text can't be blank");
  await expect(page.getByLabel('Entry text')).toHaveAttribute('aria-invalid', 'true');
  await expect(page.getByRole('button', { name: 'Save entry' })).toBeEnabled();
  await page.getByLabel('Entry text').fill('Recovered reflection.\nA second line.');
  let posts = 0;
  let release;
  const gate = new Promise(resolve => { release = resolve; });
  await page.route('**/journal_entries', async route => {
    if (route.request().method() === 'POST') { posts++; await gate; }
    await route.continue();
  });
  await page.getByRole('button', { name: 'Save entry' }).click();
  await expect(page.getByRole('button', { name: 'Saving…', exact: true })).toBeDisabled();
  await expect(page.getByRole('status')).toHaveText('Saving your entry…');
  await page.getByRole('button', { name: 'Saving…', exact: true }).evaluate(button => button.click());
  release();
  await expect(page).toHaveURL(/\/journal_entries\/\d+$/);
  expect(posts).toBe(1);
  await page.reload();
  await expect(page.locator('main')).toContainText('Recovered reflection.');
  await page.goto('/journal_entries');
  await expect(page.locator('article')).toHaveCount(1);
});

test('public fallbacks need no JavaScript, fonts or app assets; old browsers get usable recovery', async ({ browser, scenario }) => {
  scenario();
  const context = await browser.newContext({ javaScriptEnabled: false, viewport: { width: 320, height: 800 } });
  const page = await context.newPage();
  await page.route('**/assets/**', route => route.abort());
  for (const code of ['400', '404', '406-unsupported-browser', '422', '500']) {
    await page.goto(`http://127.0.0.1:3100/${code}.html`);
    await expect(page.locator('h1')).toBeVisible();
    expect(await page.evaluate(() => document.documentElement.scrollWidth <= innerWidth)).toBe(true);
    expect(await page.locator('body').evaluate(el => getComputedStyle(el).backgroundColor)).toBe('rgb(250, 251, 248)');
    if (code.startsWith('406')) {
      await expect(page.getByRole('link')).toHaveAttribute('href', 'https://www.google.com/chrome/');
      await expect(page.locator('a[href="/users/sign_in"]')).toHaveCount(0);
    } else await expect(page.getByRole('link', { name: 'Return to sign in' })).toHaveAttribute('href', '/users/sign_in');
  }
  await context.close();
  const old = await browser.newContext({ userAgent: 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/15.0 Safari/605.1.15', javaScriptEnabled: false });
  const oldPage = await old.newPage();
  expect((await oldPage.goto('http://127.0.0.1:3100/users/sign_in')).status()).toBe(406);
  await expect(oldPage.getByRole('heading')).toHaveText('Your browser needs an update.');
  await expect(oldPage.getByRole('link')).toHaveAttribute('href', 'https://www.google.com/chrome/');
  await old.close();
});

test('provider server validation recovers and the complete directory reaches its empty-selector state', async ({ page, scenario }) => {
  scenario({ accounts });
  await signIn(page, 'writer');
  await expect(page).toHaveURL(/\/client$/);
  await page.goto('/enrollments');
  await page.getByLabel('Plan', { exact: true }).locator('option[value="basic"]').evaluate(option => { option.value = 'invalid'; });
  await page.getByRole('button', { name: 'Add provider', exact: true }).click();
  await expect(page.getByRole('alert')).toContainText('Plan is not included in the list');
  await page.getByLabel('Plan', { exact: true }).selectOption('basic');
  await page.getByRole('button', { name: 'Add provider', exact: true }).click();
  await expect(page.getByRole('status')).toHaveText('Provider added.');
  await expect(page.locator('tbody tr')).toHaveCount(1);
  await page.getByRole('button', { name: 'Add provider', exact: true }).click();
  await expect(page.getByText('All available providers are already added.')).toBeVisible();
  await expect(page.getByLabel('Provider', { exact: true })).toHaveCount(0);
  await page.reload();
  await expect(page.locator('tbody tr')).toHaveCount(2);
});
