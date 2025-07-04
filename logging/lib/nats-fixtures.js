// lib/nats-fixtures.js
import { test as base } from '@playwright/test';
import NATSConnection from './nats-connection.js';

// Extend Playwright test with NATS capabilities
export const test = base.extend({
  // Test-scoped NATS monitoring fixture
  natsMonitoring: [async ({ page }, use, testInfo) => {
    const nats = global.natsConnection || new NATSConnection();
    if (!nats.isConnected) {
      await nats.connect([process.env.NATS_URL || 'nats://localhost:4222']);
    }

    const testId = `${testInfo.titlePath.join('.')}.${Date.now()}`;
    
    // Setup page monitoring
    const logs = [];
    const requests = [];
    const responses = [];
    
    // Monitor page events
    page.on('console', msg => {
      const logData = {
        type: msg.type(),
        text: msg.text(),
        location: msg.location()
      };
      logs.push(logData);
      
      // Send to NATS
      nats.publish('playwright.console', {
        testId,
        testTitle: testInfo.title,
        ...logData
      });
    });
    
    page.on('request', request => {
      const reqData = {
        url: request.url(),
        method: request.method(),
        headers: request.headers(),
        timestamp: Date.now()
      };
      requests.push(reqData);
      
      nats.publish('playwright.request', {
        testId,
        testTitle: testInfo.title,
        ...reqData
      });
    });
    
    page.on('response', response => {
      const respData = {
        url: response.url(),
        status: response.status(),
        headers: response.headers(),
        timestamp: Date.now()
      };
      responses.push(respData);
      
      nats.publish('playwright.response', {
        testId,
        testTitle: testInfo.title,
        ...respData
      });
    });
    
    page.on('pageerror', error => {
      const errorData = {
        message: error.message,
        stack: error.stack,
        timestamp: Date.now()
      };
      
      nats.publish('playwright.error', {
        testId,
        testTitle: testInfo.title,
        ...errorData
      });
    });

    // Announce test start
    await nats.publish('playwright.test.started', {
      testId,
      title: testInfo.title,
      file: testInfo.file,
      project: testInfo.project.name
    });

    // Use the monitoring
    await use({
      testId,
      logs,
      requests,
      responses,
      publish: (subject, data) => nats.publish(subject, { testId, ...data }),
      subscribe: (subject, callback) => nats.subscribe(subject, callback),
      request: (subject, data) => nats.request(subject, { testId, ...data })
    });

    // Test completion
    await nats.publish('playwright.test.completed', {
      testId,
      title: testInfo.title,
      status: testInfo.status,
      duration: testInfo.duration,
      errors: testInfo.errors.map(e => e.message),
      stats: {
        logsCount: logs.length,
        requestsCount: requests.length,
        responsesCount: responses.length
      }
    });

  }, { auto: true }],

  // Page fixture with NATS control capabilities
  natsPage: async ({ page, natsMonitoring }, use) => {
    // Add NATS control methods to page
    page.nats = {
      publish: natsMonitoring.publish,
      subscribe: natsMonitoring.subscribe,
      request: natsMonitoring.request,
      
      // Custom page actions with NATS reporting
      async gotoWithReport(url, options = {}) {
        await natsMonitoring.publish('playwright.action.goto', { url, options });
        const result = await page.goto(url, options);
        await natsMonitoring.publish('playwright.action.goto.completed', { url, success: !!result });
        return result;
      },
      
      async clickWithReport(selector, options = {}) {
        await natsMonitoring.publish('playwright.action.click', { selector, options });
        try {
          await page.click(selector, options);
          await natsMonitoring.publish('playwright.action.click.completed', { selector, success: true });
        } catch (error) {
          await natsMonitoring.publish('playwright.action.click.failed', { 
            selector, 
            error: error.message 
          });
          throw error;
        }
      },
      
      async fillWithReport(selector, value, options = {}) {
        await natsMonitoring.publish('playwright.action.fill', { selector, value, options });
        try {
          await page.fill(selector, value, options);
          await natsMonitoring.publish('playwright.action.fill.completed', { selector, success: true });
        } catch (error) {
          await natsMonitoring.publish('playwright.action.fill.failed', { 
            selector, 
            error: error.message 
          });
          throw error;
        }
      }
    };
    
    await use(page);
  }
});

export { expect } from '@playwright/test';
