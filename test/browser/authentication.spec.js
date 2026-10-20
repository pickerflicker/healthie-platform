const { test, expect } = require('@playwright/test');
const path = require('path');
const evidence = name => path.join(__dirname, '../../docs/qa/PIC-277', name);

test('seeded identities, denied access, tampering and logout', async ({ page }) => {
  for (const target of ['/', '/provider', '/client']) {
    await page.goto(target);
    await expect(page).toHaveURL(/\/users\/sign_in$/);
  }
  await page.screenshot({ path: evidence('sign-in.png'), fullPage: true });
  await page.getByLabel('Email').fill('client@healthie.example');
  await page.getByLabel('Password', { exact: true }).fill('incorrect-password');
  await page.getByRole('button', { name: 'Sign in', exact: true }).click();
  await expect(page.getByRole('alert')).toContainText('Invalid Email or password');
  await page.screenshot({ path: evidence('invalid-login.png'), fullPage: true });
  for (const [role, name] of [['provider', 'Morgan Patel'], ['client', 'Alex Rivera']]) {
    await page.goto('/users/sign_in');
    await page.getByLabel('Email').fill(`${role}@healthie.example`);
    await page.getByLabel('Password', { exact: true }).fill('Healthie-demo-2026');
    await page.locator('form').evaluate((form, forgedRole) => {
      const input = document.createElement('input');
      input.type = 'hidden'; input.name = 'user[role]'; input.value = forgedRole; form.append(input);
    }, role === 'provider' ? 'client' : 'provider');
    await page.getByRole('button', { name: 'Sign in', exact: true }).click();
    await expect(page).toHaveURL(new RegExp(`/${role}$`));
    await expect(page.getByRole('heading', { name: `${role[0].toUpperCase() + role.slice(1)} home` })).toBeVisible();
    await expect(page.locator('main')).toContainText(name);
    await expect(page.locator('main')).toContainText(`${role}@healthie.example`);
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
