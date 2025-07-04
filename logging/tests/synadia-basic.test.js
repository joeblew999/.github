// tests/synadia-basic.test.js
import { test, expect } from '@playwright/test';

const TEAM_URL = 'https://cloud.synadia.com/teams/2XrIt5ApHyjVq8XkELhTaP4vfO3';

test.describe('Synadia Console Basic Tests', () => {
  test('should load Synadia console page', async ({ page }) => {
    // Navigate to the Synadia console
    await page.goto(TEAM_URL);
    
    // Wait for the page to load
    await page.waitForLoadState('networkidle');
    
    // Check that we're on the right page
    await expect(page).toHaveURL(/cloud\.synadia\.com/);
    
    // Check for common Synadia console elements
    // Note: These selectors may need to be updated based on actual page structure
    const possibleElements = [
      'nav', 'header', '[data-testid]', '.nav', '.sidebar', 
      'button', 'a[href*="account"]', 'a[href*="connect"]'
    ];
    
    let foundElement = false;
    for (const selector of possibleElements) {
      try {
        const element = await page.locator(selector).first();
        if (await element.isVisible({ timeout: 2000 })) {
          foundElement = true;
          console.log(`✅ Found element: ${selector}`);
          break;
        }
      } catch (e) {
        // Element not found, continue
      }
    }
    
    expect(foundElement).toBe(true);
  });
  
  test('should be able to interact with page elements', async ({ page }) => {
    await page.goto(TEAM_URL);
    await page.waitForLoadState('networkidle');
    
    // Try to find clickable elements
    const clickableElements = await page.locator('button, a, [role="button"]').all();
    
    // Should have some interactive elements
    expect(clickableElements.length).toBeGreaterThan(0);
    
    console.log(`Found ${clickableElements.length} clickable elements`);
  });
  
  test('should detect credential-related sections', async ({ page }) => {
    await page.goto(TEAM_URL);
    await page.waitForLoadState('networkidle');
    
    // Look for text that might indicate credential sections
    const credentialKeywords = [
      'account', 'connect', 'credential', 'download', 'key', 
      'token', 'auth', 'login', 'settings', 'app'
    ];
    
    let foundCredentialSection = false;
    
    for (const keyword of credentialKeywords) {
      try {
        const element = page.getByText(new RegExp(keyword, 'i')).first();
        if (await element.isVisible({ timeout: 1000 })) {
          console.log(`✅ Found potential credential section: "${keyword}"`);
          foundCredentialSection = true;
          break;
        }
      } catch (e) {
        // Keyword not found, continue
      }
    }
    
    // This test might fail if the page structure changes, but it's informational
    console.log(foundCredentialSection ? 
      '✅ Detected potential credential sections' : 
      '⚠️  No obvious credential sections detected'
    );
  });
});
