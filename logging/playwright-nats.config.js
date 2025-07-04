// playwright-nats.config.js
import { defineConfig } from '@playwright/test';
import './lib/nats-fixtures.js';

export default defineConfig({
  testDir: './tests',
  timeout: 60000, // Increased for NATS operations
  globalSetup: './lib/nats-global-setup.js',
  globalTeardown: './lib/nats-global-teardown.js',
  
  use: {
    headless: false,
    viewport: { width: 1280, height: 720 },
    screenshot: 'only-on-failure',
    video: 'retain-on-failure',
    trace: 'on-first-retry',
    
    // Custom NATS options
    natsServer: process.env.NATS_URL || 'nats://localhost:4222',
    testRunId: process.env.TEST_RUN_ID || `test-${Date.now()}`,
  },
  
  projects: [
    {
      name: 'chromium-nats',
      use: { 
        browserName: 'chromium',
        channel: 'chrome'
      },
    },
  ],
  
  reporter: [
    ['list'],
    ['./lib/nats-reporter.js'],
    ['html', { open: 'never' }],
    ['json', { outputFile: 'test-results/results.json' }]
  ],
  
  workers: process.env.CI ? 1 : 2, // Limit workers for NATS coordination
});
