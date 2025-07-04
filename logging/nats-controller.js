// nats-controller.js
import { spawn } from 'child_process';
import NATSConnection from './lib/nats-connection.js';

class PlaywrightNATSController {
  constructor() {
    this.nats = null;
    this.runningTests = new Map();
    this.testHistory = [];
  }

  async start() {
    console.log('🎮 Starting Playwright NATS Controller...');
    
    // Connect to NATS
    this.nats = new NATSConnection();
    await this.nats.connect([process.env.NATS_URL || 'nats://localhost:4222']);
    
    // Subscribe to control commands
    await this.setupControlSubscriptions();
    
    // Subscribe to test events for monitoring
    await this.setupMonitoringSubscriptions();
    
    console.log('✅ Playwright NATS Controller ready');
    console.log('📡 Listening for commands on: playwright.control.*');
    console.log('📊 Monitoring test events on: playwright.*');
  }

  async setupControlSubscriptions() {
    // Run tests command
    await this.nats.subscribe('playwright.control.run', async (data, msg) => {
      console.log('🚀 Received run command:', data);
      
      try {
        const result = await this.runTests(data);
        msg.respond(JSON.stringify({ success: true, result }));
      } catch (error) {
        msg.respond(JSON.stringify({ 
          success: false, 
          error: error.message 
        }));
      }
    });

    // Stop tests command
    await this.nats.subscribe('playwright.control.stop', async (data, msg) => {
      console.log('🛑 Received stop command:', data);
      
      try {
        const result = await this.stopTests(data.testRunId);
        msg.respond(JSON.stringify({ success: true, result }));
      } catch (error) {
        msg.respond(JSON.stringify({ 
          success: false, 
          error: error.message 
        }));
      }
    });

    // Get status command
    await this.nats.subscribe('playwright.control.status', async (data, msg) => {
      const status = {
        runningTests: Array.from(this.runningTests.entries()).map(([id, info]) => ({
          testRunId: id,
          startTime: info.startTime,
          command: info.command,
          pid: info.process?.pid
        })),
        recentHistory: this.testHistory.slice(-10)
      };
      
      msg.respond(JSON.stringify({ success: true, status }));
    });

    // Execute single test command
    await this.nats.subscribe('playwright.control.execute', async (data, msg) => {
      console.log('⚡ Received execute command:', data);
      
      try {
        const result = await this.executeTest(data);
        msg.respond(JSON.stringify({ success: true, result }));
      } catch (error) {
        msg.respond(JSON.stringify({ 
          success: false, 
          error: error.message 
        }));
      }
    });
  }

  async setupMonitoringSubscriptions() {
    // Monitor test lifecycle
    await this.nats.subscribe('playwright.test.started', (data) => {
      console.log(`🧪 Test started: ${data.title}`);
    });

    await this.nats.subscribe('playwright.test.completed', (data) => {
      console.log(`✅ Test completed: ${data.title} (${data.status})`);
    });

    await this.nats.subscribe('playwright.test.failed', (data) => {
      console.log(`❌ Test failed: ${data.title}`);
      console.log(`   Errors: ${data.errors.join(', ')}`);
    });

    // Monitor suite lifecycle
    await this.nats.subscribe('playwright.suite.started', (data) => {
      console.log(`🎭 Test suite started: ${data.totalTests} tests`);
    });

    await this.nats.subscribe('playwright.suite.end', (data) => {
      console.log(`🏁 Test suite completed: ${data.status}`);
      console.log(`   Stats: ${JSON.stringify(data.stats)}`);
      
      // Add to history
      this.testHistory.push({
        testRunId: data.testRunId,
        status: data.status,
        duration: data.duration,
        stats: data.stats,
        completedAt: new Date().toISOString()
      });
    });
  }

  async runTests(options = {}) {
    const testRunId = `run-${Date.now()}`;
    const {
      config = 'playwright-nats.config.js',
      grep,
      project,
      headed = false,
      debug = false
    } = options;

    let command = ['npx', 'playwright', 'test', `--config=${config}`];
    
    if (grep) command.push(`--grep=${grep}`);
    if (project) command.push(`--project=${project}`);
    if (headed) command.push('--headed');
    if (debug) command.push('--debug');

    // Set environment variables
    const env = {
      ...process.env,
      TEST_RUN_ID: testRunId,
      NATS_URL: process.env.NATS_URL || 'nats://localhost:4222'
    };

    return new Promise((resolve, reject) => {
      console.log(`🎬 Starting test run: ${testRunId}`);
      console.log(`   Command: ${command.join(' ')}`);

      const testProcess = spawn(command[0], command.slice(1), {
        env,
        stdio: ['pipe', 'pipe', 'pipe']
      });

      // Store running test info
      this.runningTests.set(testRunId, {
        process: testProcess,
        startTime: new Date().toISOString(),
        command: command.join(' ')
      });

      let stdout = '';
      let stderr = '';

      testProcess.stdout.on('data', (data) => {
        stdout += data;
        console.log(`📤 [${testRunId}] ${data}`);
      });

      testProcess.stderr.on('data', (data) => {
        stderr += data;
        console.error(`📥 [${testRunId}] ${data}`);
      });

      testProcess.on('close', (code) => {
        this.runningTests.delete(testRunId);
        
        const result = {
          testRunId,
          exitCode: code,
          stdout,
          stderr,
          success: code === 0
        };

        if (code === 0) {
          console.log(`✅ Test run completed: ${testRunId}`);
          resolve(result);
        } else {
          console.log(`❌ Test run failed: ${testRunId} (exit code: ${code})`);
          reject(new Error(`Test run failed with exit code: ${code}`));
        }
      });

      testProcess.on('error', (error) => {
        this.runningTests.delete(testRunId);
        console.error(`💥 Test run error: ${testRunId}`, error);
        reject(error);
      });
    });
  }

  async stopTests(testRunId) {
    if (!this.runningTests.has(testRunId)) {
      throw new Error(`Test run not found: ${testRunId}`);
    }

    const testInfo = this.runningTests.get(testRunId);
    
    if (testInfo.process) {
      testInfo.process.kill('SIGTERM');
      console.log(`🛑 Stopping test run: ${testRunId}`);
      
      // Wait a bit for graceful shutdown
      setTimeout(() => {
        if (!testInfo.process.killed) {
          testInfo.process.kill('SIGKILL');
          console.log(`💀 Force killed test run: ${testRunId}`);
        }
      }, 5000);
    }

    this.runningTests.delete(testRunId);
    return { stopped: true, testRunId };
  }

  async executeTest(options) {
    const { file, testName, project = 'chromium-nats' } = options;
    
    if (!file) {
      throw new Error('Test file is required');
    }

    const testRunId = `exec-${Date.now()}`;
    let command = ['npx', 'playwright', 'test', file, `--project=${project}`];
    
    if (testName) {
      command.push(`--grep=${testName}`);
    }

    const env = {
      ...process.env,
      TEST_RUN_ID: testRunId,
      NATS_URL: process.env.NATS_URL || 'nats://localhost:4222'
    };

    return new Promise((resolve, reject) => {
      const testProcess = spawn(command[0], command.slice(1), {
        env,
        stdio: 'pipe'
      });

      let stdout = '';
      let stderr = '';

      testProcess.stdout.on('data', (data) => {
        stdout += data;
      });

      testProcess.stderr.on('data', (data) => {
        stderr += data;
      });

      testProcess.on('close', (code) => {
        resolve({
          testRunId,
          exitCode: code,
          stdout,
          stderr,
          success: code === 0
        });
      });

      testProcess.on('error', reject);
    });
  }

  async stop() {
    console.log('🔄 Stopping Playwright NATS Controller...');
    
    // Stop all running tests
    for (const [testRunId, info] of this.runningTests) {
      if (info.process) {
        info.process.kill('SIGTERM');
      }
    }
    
    // Close NATS connection
    if (this.nats) {
      await this.nats.close();
    }
    
    console.log('✅ Playwright NATS Controller stopped');
  }
}

// Start the controller if run directly
if (import.meta.url === `file://${process.argv[1]}`) {
  const controller = new PlaywrightNATSController();
  
  // Graceful shutdown
  process.on('SIGINT', async () => {
    await controller.stop();
    process.exit(0);
  });
  
  process.on('SIGTERM', async () => {
    await controller.stop();
    process.exit(0);
  });
  
  controller.start().catch(console.error);
}

export default PlaywrightNATSController;
