const { test, expect } = require('@playwright/test');
test('Rails is healthy in the isolated browser test server', async ({ page }) => {
  const response = await page.goto('/up');
  expect(response.status()).toBe(200);
  await expect(page.locator('body')).toHaveCSS('background-color', 'rgb(0, 128, 0)');
});
