// lib/browser-launcher.js - Generic browser management abstraction
import { chromium, webkit } from 'playwright';
import os from 'os';

/**
 * Browser configuration from environment variables
 * 
 * Note: Safari support uses WebKit engine (same as real Safari) 
 * but cannot launch the actual Safari.app on macOS.
 */
export function getBrowserConfig() {
  return {
    browser: process.env.GUIDE_BROWSER || 'chromium',     // chromium, webkit, chrome
    useReal: process.env.GUIDE_REAL === 'true',           // Use real browser vs bundled
    headless: process.env.GUIDE_HEADLESS === 'true',      // Headless mode
    platform: os.platform(),                              // darwin, win32, linux
    slowMo: parseInt(process.env.GUIDE_SLOWMO || '0'),     // Slow motion delay
    debug: process.env.GUIDE_DEBUG === 'true',            // Debug logging
  };
}

/**
 * Launch options for different browser types
 */
function getBrowserOptions(config) {
  const baseOptions = {
    headless: config.headless,
    slowMo: config.slowMo,
  };

  // Platform-specific adjustments
  if (config.platform === 'darwin') {
    baseOptions.args = ['--start-maximized'];
  }

  return baseOptions;
}

/**
 * Attempt to launch a specific browser with fallback chain
 */
async function tryLaunchBrowser(browserType, options, config) {
  const { browser, useReal, debug } = config;
  
  if (debug) {
    console.log(`🔧 Attempting to launch ${browserType}${useReal ? ' (real)' : ' (bundled)'}...`);
  }

  try {
    let browserInstance;
    
    switch (browserType) {
      case 'chrome':
        if (useReal) {
          browserInstance = await chromium.launch({
            ...options,
            channel: 'chrome', // Use real Chrome
          });
          if (debug) console.log('✅ Launched real Google Chrome');
        } else {
          browserInstance = await chromium.launch(options);
          if (debug) console.log('✅ Launched bundled Chromium');
        }
        break;
        
      case 'webkit':
      case 'safari':
        browserInstance = await webkit.launch(options);
        if (debug) console.log('✅ Launched WebKit (Safari engine - closest to real Safari)');
        break;
        
      case 'chromium':
      default:
        browserInstance = await chromium.launch(options);
        if (debug) console.log('✅ Launched bundled Chromium');
        break;
    }
    
    return browserInstance;
    
  } catch (error) {
    if (debug) {
      console.log(`⚠️  Failed to launch ${browserType}: ${error.message}`);
    }
    throw error;
  }
}

/**
 * Smart browser launcher with fallback chain
 */
export async function launchBrowser(overrideConfig = {}) {
  const config = { ...getBrowserConfig(), ...overrideConfig };
  const options = getBrowserOptions(config);
  
  console.log(`🌐 Launching browser: ${config.browser}${config.useReal ? ' (real)' : ' (bundled)'}`);
  
  // Define fallback chain based on requested browser
  const fallbackChain = [];
  
  if (config.browser === 'chrome') {
    if (config.useReal) {
      fallbackChain.push('chrome');      // Real Chrome first
    }
    fallbackChain.push('chromium');      // Bundled Chromium fallback
  } else if (config.browser === 'webkit' || config.browser === 'safari') {
    fallbackChain.push('webkit');        // WebKit only (no fallback)
  } else {
    fallbackChain.push('chromium');      // Default to Chromium
  }
  
  // Try each browser in the fallback chain
  for (const browserType of fallbackChain) {
    try {
      const browser = await tryLaunchBrowser(browserType, options, config);
      return {
        browser,
        actualType: browserType,
        config: config
      };
    } catch (error) {
      // Continue to next fallback
      continue;
    }
  }
  
  // If all fallbacks failed
  throw new Error(`❌ Failed to launch any browser. Tried: ${fallbackChain.join(', ')}`);
}

/**
 * Get browser info for display/logging
 */
export function getBrowserInfo(launchResult) {
  const { actualType, config } = launchResult;
  
  let displayName = actualType.toUpperCase();
  if (actualType === 'chrome' && config.useReal) {
    displayName += ' (Real)';
  } else if (actualType === 'chromium') {
    displayName += ' (Bundled)';
  } else if (actualType === 'webkit') {
    displayName = 'Safari WebKit (Engine)';
  }
  
  return {
    displayName,
    type: actualType,
    isReal: config.useReal && actualType === 'chrome',
    platform: config.platform
  };
}

/**
 * Graceful browser cleanup
 */
export async function closeBrowser(launchResult, reason = 'Session ended') {
  const { browser } = launchResult;
  const info = getBrowserInfo(launchResult);
  
  try {
    await browser.close();
    console.log(`🏁 ${info.displayName} ${reason.toLowerCase()}`);
  } catch (error) {
    console.log(`⚠️  Error closing browser: ${error.message}`);
  }
}

/**
 * Platform-specific browser detection
 */
export async function detectAvailableBrowsers() {
  const available = [];
  const config = getBrowserConfig();
  
  // Always available (bundled)
  available.push('chromium', 'webkit');
  
  // Try to detect real Chrome
  try {
    const testBrowser = await chromium.launch({ 
      channel: 'chrome',
      headless: true 
    });
    await testBrowser.close();
    available.push('chrome');
  } catch (error) {
    // Chrome not available
  }
  
  return available;
}
