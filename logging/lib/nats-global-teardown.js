// lib/nats-global-teardown.js
async function globalTeardown(config) {
  console.log('🔄 Cleaning up NATS connections...');
  
  try {
    if (global.natsConnection) {
      // Announce test run completion
      await global.natsConnection.publish('playwright.testrun.completed', {
        testRunId: config.use?.testRunId || 'unknown',
        completedAt: new Date().toISOString()
      });
      
      // Close connection
      await global.natsConnection.close();
      global.natsConnection = null;
    }
    
    console.log('✅ NATS cleanup complete');
    
  } catch (error) {
    console.error('❌ NATS cleanup failed:', error);
  }
}

export default globalTeardown;
