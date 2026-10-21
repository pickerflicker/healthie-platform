const { test, expect } = require('../support/browser');

test('test-owned identities, denied access, tampering and logout', async ({ page, scenario }, testInfo) => {
  scenario({
    accounts: {
      "client": {"role": "client", "name": "Quinn Avery"},
      "provider": {"role": "provider", "name": "Robin Lane"},
    },
  });
  const evidence = name => testInfo.outputPath(name);
  for (const target of ['/', '/provider', '/client']) {
    await page.goto(target);
    await expect(page).toHaveURL(/\/users\/sign_in$/);
  }
  await page.screenshot({ path: evidence('sign-in.png'), fullPage: true });
  await page.getByLabel('Email').fill('client@browser.example.test');
  await page.getByLabel('Password', { exact: true }).fill('incorrect-password');
  await page.getByRole('button', { name: 'Sign in', exact: true }).click();
  await expect(page.getByRole('alert')).toHaveText(/^Invalid email or password\.$/i);
  await page.screenshot({ path: evidence('invalid-login.png'), fullPage: true });
  for (const [role, name] of [['provider', 'Robin Lane'], ['client', 'Quinn Avery']]) {
    await page.goto('/users/sign_in');
    await page.getByLabel('Email').fill(`${role}@browser.example.test`);
    await page.getByLabel('Password', { exact: true }).fill('Focused-tests-2026');
    await page.locator('form').evaluate((form, forgedRole) => {
      const input = document.createElement('input');
      input.type = 'hidden'; input.name = 'user[role]'; input.value = forgedRole; form.append(input);
    }, role === 'provider' ? 'client' : 'provider');
    await page.getByRole('button', { name: 'Sign in', exact: true }).click();
    await expect(page).toHaveURL(new RegExp(`/${role}$`));
    await expect(page.getByRole('heading', { name: `${role[0].toUpperCase() + role.slice(1)} home` })).toBeVisible();
    await expect(page.locator('main')).toContainText(name);
    await expect(page.locator('main')).toContainText(`${role}@browser.example.test`);
    await page.getByRole('link', { name: `${role[0].toUpperCase() + role.slice(1)} home` }).click();
    await page.screenshot({ path: evidence(`${role}-home.png`), fullPage: true });
    const response = await page.goto(role === 'provider' ? '/client?role=client' : '/provider?role=provider');
    expect(response.status()).toBe(403);
    await expect(page.locator('body')).toContainText('Access denied');
    await page.screenshot({ path: evidence(`${role}-denied.png`), fullPage: true });
    await page.goto(`/${role}`);
    await page.getByRole('button', { name: 'Sign out' }).click();
    await expect(page).toHaveURL(/\/users\/sign_in$/);
    await page.goto(`/${role}`);
    await expect(page).toHaveURL(/\/users\/sign_in$/);
  }
  for (const target of ['/users/sign_up', '/users/password/new', '/users/edit', '/admin']) {
    const response = await page.request.get(target);
    expect(response.status()).toBe(404);
  }
});
