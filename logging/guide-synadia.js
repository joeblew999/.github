// guide-synadia.js - Interactive guidance for Synadia NATS credential setup
import { chromium } from 'playwright';

const TEAM_URL = 'https://cloud.synadia.com/teams/2XrIt5ApHyjVq8XkELhTaP4vfO3';
const TIMEOUT_MS = 10000; // 10 seconds

// Enhanced visual guidance styles
const GUIDANCE_STYLES = `
  .guide-tooltip {
    position: fixed !important;
    top: 20px !important;
    right: 20px !important;
    background: linear-gradient(135deg, #2563eb, #1d4ed8) !important;
    color: white !important;
    padding: 20px !important;
    border-radius: 12px !important;
    z-index: 999999 !important;
    font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', sans-serif !important;
    font-size: 14px !important;
    line-height: 1.5 !important;
    box-shadow: 0 8px 32px rgba(0,0,0,0.3), 0 2px 8px rgba(0,0,0,0.1) !important;
    max-width: 320px !important;
    border: 1px solid rgba(255,255,255,0.2) !important;
    backdrop-filter: blur(10px) !important;
  }
  
  .guide-step {
    margin-bottom: 12px !important;
  }
  
  .guide-step:last-child {
    margin-bottom: 0 !important;
  }
  
  .guide-highlight {
    background: rgba(255,255,255,0.2) !important;
    padding: 2px 6px !important;
    border-radius: 4px !important;
    font-weight: 600 !important;
  }
  
  .guide-progress {
    background: rgba(255,255,255,0.1) !important;
    height: 4px !important;
    border-radius: 2px !important;
    margin-top: 16px !important;
    overflow: hidden !important;
  }
  
  .guide-progress-bar {
    background: white !important;
    height: 100% !important;
    width: 33% !important;
    border-radius: 2px !important;
    animation: pulse 2s infinite !important;
  }
  
  @keyframes pulse {
    0%, 100% { opacity: 1; }
    50% { opacity: 0.7; }
  }
`;

async function addGuidanceTooltip(page, step, content, progress = 33) {
  await page.evaluate(({ step, content, progress, styles }) => {
    // Remove existing tooltip
    const existing = document.querySelector('.guide-tooltip');
    if (existing) existing.remove();
    
    // Add styles if not already present
    if (!document.querySelector('#guide-styles')) {
      const styleEl = document.createElement('style');
      styleEl.id = 'guide-styles';
      styleEl.textContent = styles;
      document.head.appendChild(styleEl);
    }
    
    // Create new tooltip
    const tooltip = document.createElement('div');
    tooltip.className = 'guide-tooltip';
    tooltip.innerHTML = `
      <div class="guide-step">
        <strong>Step ${step}: ${content.title}</strong>
      </div>
      <div class="guide-step">
        ${content.description}
      </div>
      ${content.action ? `<div class="guide-step">
        👉 <span class="guide-highlight">${content.action}</span>
      </div>` : ''}
      <div class="guide-progress">
        <div class="guide-progress-bar" style="width: ${progress}%"></div>
      </div>
    `;
    document.body.appendChild(tooltip);
  }, { step, content, progress, styles: GUIDANCE_STYLES });
}

async function waitForUserInteraction(page, timeoutMs = 30000) {
  console.log('⏳ Waiting for user interaction or timeout...');
  try {
    await Promise.race([
      page.waitForTimeout(timeoutMs),
      page.waitForEvent('framenavigated'),
      page.waitForFunction(() => document.querySelector('[data-guide-next]') !== null)
    ]);
  } catch (e) {
    // Timeout or user interaction
  }
}

async function guideSynadiaSetup() {
  console.log('🎭 Starting comprehensive Synadia NATS guidance...');
  
  const browser = await chromium.launch({ 
    headless: false,
    args: ['--start-maximized']
  });
  
  const page = await browser.newPage();
  
  try {
    // Step 1: Navigate to Synadia console
    console.log('🌐 Opening Synadia console...');
    await page.goto(TEAM_URL, { waitUntil: 'networkidle' });
    
    await addGuidanceTooltip(page, 1, {
      title: 'Welcome to Synadia Console',
      description: 'This is your team\'s NATS management console. We\'ll help you find your connection credentials.',
      action: 'Look around and click on different sections'
    }, 20);
    
    await waitForUserInteraction(page, 15000);
    
    // Step 2: Look for credentials sections
    console.log('🔍 Guiding credential discovery...');
    await addGuidanceTooltip(page, 2, {
      title: 'Find Your Credentials',
      description: 'Look for these sections in the interface:',
      action: 'Try "Accounts", "Apps", "Connect", or "Settings" tabs'
    }, 50);
    
    await waitForUserInteraction(page, 20000);
    
    // Step 3: Download or copy credentials
    console.log('📋 Final guidance...');
    await addGuidanceTooltip(page, 3, {
      title: 'Get Your Credentials',
      description: 'Once you find the credentials section, you can usually download a .creds file or copy connection details.',
      action: 'Download .creds file or copy the connection string'
    }, 80);
    
    await waitForUserInteraction(page, 30000);
    
    // Step 4: Completion
    await addGuidanceTooltip(page, 4, {
      title: 'Almost Done! 🎉',
      description: 'Save your credentials securely and update your .env file with the connection details.',
      action: 'Press Ctrl+C when you\'re ready to close this guide'
    }, 100);
    
    console.log('✅ Guidance complete! Browse freely or press Ctrl+C to exit.');
    
    // Keep browser open until user closes it
    await page.waitForEvent('close', { timeout: 0 });
    
  } catch (error) {
    if (error.message.includes('Target page, context or browser has been closed')) {
      console.log('👋 Browser closed by user');
    } else {
      console.error('❌ Error during guidance:', error.message);
    }
  } finally {
    await browser.close();
    console.log('🏁 Synadia guidance session ended');
  }
}
// Start the guidance
guideSynadiaSetup().catch(console.error);
