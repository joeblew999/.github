// lib/nats-global-setup.js
import NATSConnection from './nats-connection.js';

async function globalSetup(config) {
  console.log('🚀 Setting up NATS for Playwright tests...');
  
  // Create global NATS connection
  const nats = new NATSConnection();
  
  try {
    // Use default NATS server if not specified in config
    const natsServer = config.use?.natsServer || 'nats://localhost:4222';
    await nats.connect([natsServer]);
    
    // Announce test run start
    await nats.publish('playwright.testrun.started', {
      testRunId: config.use.testRunId,
      config: {
        testDir: config.testDir,
        timeout: config.timeout,
        projects: config.projects.map(p => p.name)
      }
    });
    
    // Store connection globally for other components
    global.natsConnection = nats;
    
    console.log(`✅ NATS setup complete for test run: ${config.use.testRunId}`);
    
  } catch (error) {
    console.error('❌ NATS setup failed:', error);
    throw error;
  }
}

export default globalSetup;
