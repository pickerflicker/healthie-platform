const { test, expect, signIn, signOut } = require('../support/browser');

test('real role pages reflow with populated lists and long text at desktop, 390px and 320px', async ({ page, scenario }, testInfo) => {
  test.setTimeout(90000);
  const accounts = { writer: { role: 'client', name: 'Riley A-Very-Long-Family-Name Montgomery' }, empty: { role: 'client', name: 'Empty Journal' } };
  for (let n = 0; n < 12; n++) accounts[`provider${n}`] = { role: 'provider', name: `Morgan ${'LongFamilyName'.repeat(4)} ${n}` };
  const enrollments = Array.from({ length: 11 }, (_, n) => ({ client: 'writer', provider: `provider${n}`, plan: n % 2 ? 'premium' : 'basic' }));
  const entries = Array.from({ length: 15 }, (_, n) => ({ client: 'writer', text: `Reflection ${n}.\n${'A-long-unbroken-word'.repeat(30)}\nA quiet moment.` }));
  scenario({ accounts, enrollments, entries });
  await signIn(page, 'writer');
  await expect(page).toHaveURL(/\/client$/);
  await page.goto('/journal_entries');
  const entry = await page.locator('article h2 a').first().getAttribute('href');
  const check = async (path, name, width) => {
    await page.setViewportSize({ width, height: 900 });
    await page.goto(path);
    await expect(page.locator('h1')).toBeVisible();
    expect(await page.evaluate(() => document.documentElement.scrollWidth <= innerWidth), `${name} at ${width}`).toBe(true);
    if (width === 1280) await expect(page.getByRole('navigation', { name: 'Workspace', exact: true })).toBeVisible();
    else await expect(page.getByRole('navigation', { name: 'Mobile workspace', exact: true })).toBeVisible();
    await page.screenshot({ path: testInfo.outputPath(`${name}-${width}.png`), fullPage: true });
  };
  for (const width of [1280, 390, 320]) {
    for (const [path, name] of [['/client','client-home'], ['/journal_entries','journal'], ['/journal_entries/new','new'], [entry,'entry'], [`${entry}/edit`,'edit'], ['/enrollments','providers']]) await check(path, name, width);
  }
  await page.setViewportSize({ width: 1280, height: 900 });
  await signOut(page);
  await signIn(page, 'provider0');
  await expect(page).toHaveURL(/\/provider$/);
  await page.goto('/enrollments');
  const clientJournal = await page.locator('tbody a').first().getAttribute('href');
  for (const width of [1280, 390, 320]) {
    for (const [path, name] of [['/provider','provider-home'], ['/provider/edit','credentials'], ['/enrollments','clients'], ['/journal_entries','feed'], [clientJournal,'client-journal'], [entry,'read-only'], ['/client','role-denied'], ['/journal_entries/999999999','not-found']]) await check(path, name, width);
  }
});

test('relationship plan badges stay aligned and contain their labels at desktop resolutions', async ({ page, scenario }, testInfo) => {
  scenario({
    accounts: {
      client: { role: 'client', name: 'Riley Montgomery' },
      other: { role: 'client', name: 'Avery Long-Family-Name Montgomery' },
      provider: { role: 'provider', name: 'Morgan Long-Family-Name Rivera' },
      second: { role: 'provider', name: 'Taylor Reed' }
    },
    provider_credentials: { provider: ['RDN', 'LD', 'PhD'] },
    enrollments: [
      { client: 'client', provider: 'provider', plan: 'premium' },
      { client: 'client', provider: 'second', plan: 'basic' },
      { client: 'other', provider: 'provider', plan: 'basic' }
    ]
  });
  for (const login of ['client', 'provider']) {
    await signIn(page, login);
    await expect(page).toHaveURL(new RegExp(`/${login}$`));
    for (const width of [1024, 1280, 1440, 1920]) {
      await page.setViewportSize({ width, height: 1080 });
      await page.goto('/enrollments');
      await page.evaluate(() => document.fonts.ready);
      const badges = page.locator('.plan-cell .badge');
      await expect(badges).toHaveCount(2);
      const bounds = await badges.evaluateAll(elements => elements.map(element => {
        const box = element.getBoundingClientRect();
        const range = document.createRange();
        range.selectNodeContents(element);
        const text = range.getBoundingClientRect();
        return { x: box.x, width: box.width, height: box.height,
          contained: text.left >= box.left && text.right <= box.right && text.top >= box.top && text.bottom <= box.bottom };
      }));
      for (const badge of bounds) {
        expect(badge.contained, `${login} badge text at ${width}px`).toBe(true);
        expect(badge.x).toBeCloseTo(bounds[0].x, 0);
        expect(badge.width).toBeCloseTo(bounds[0].width, 0);
        expect(badge.height).toBeCloseTo(bounds[0].height, 0);
      }
      expect(await page.evaluate(() => document.documentElement.scrollWidth <= innerWidth)).toBe(true);
      await page.screenshot({ path: testInfo.outputPath(`${login}-relationships-${width}.png`), fullPage: true });
    }
    await signOut(page);
  }
});
