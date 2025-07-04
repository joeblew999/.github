// lib/nats-reporter.js
import NATSConnection from './nats-connection.js';

class NATSReporter {
  constructor() {
    this.nats = null;
    this.testRunId = `test-run-${Date.now()}`;
    this.suiteStartTime = null;
  }

  async onBegin(config, suite) {
    console.log('🎭 NATS Reporter: Starting test suite...');
    this.suiteStartTime = Date.now();
    
    // Connect to NATS
    this.nats = new NATSConnection();
    try {
      await this.nats.connect([process.env.NATS_URL || 'nats://localhost:4222']);
    } catch (error) {
      console.warn('⚠️ NATS Reporter: Could not connect to NATS, continuing without reporting');
      return;
    }

    // Report suite start
    await this.nats.publish('playwright.suite.started', {
      testRunId: this.testRunId,
      totalTests: suite.allTests().length,
      projects: config.projects.map(p => ({
        name: p.name,
        testDir: p.testDir,
        use: p.use
      })),
      workers: config.workers,
      timeout: config.timeout
    });
  }

  async onTestBegin(test, result) {
    if (!this.nats?.isConnected) return;

    await this.nats.publish('playwright.test.begin', {
      testRunId: this.testRunId,
      testId: test.id,
      title: test.title,
      titlePath: test.titlePath(),
      file: test.location.file,
      line: test.location.line,
      column: test.location.column,
      project: test.parent.project()?.name,
      expectedStatus: test.expectedStatus,
      timeout: test.timeout,
      retries: test.retries,
      annotations: test.annotations,
      tags: test.tags
    });
  }

  async onTestEnd(test, result) {
    if (!this.nats?.isConnected) return;

    const testData = {
      testRunId: this.testRunId,
      testId: test.id,
      title: test.title,
      titlePath: test.titlePath(),
      file: test.location.file,
      project: test.parent.project()?.name,
      status: result.status,
      duration: result.duration,
      retry: result.retry,
      startTime: result.startTime,
      expectedStatus: test.expectedStatus,
      errors: result.errors.map(error => ({
        message: error.message,
        location: error.location,
        stack: error.stack
      })),
      attachments: result.attachments.map(att => ({
        name: att.name,
        contentType: att.contentType,
        path: att.path
      })),
      steps: this.extractSteps(result.steps)
    };

    await this.nats.publish('playwright.test.end', testData);

    // Also publish status-specific events
    if (result.status === 'failed') {
      await this.nats.publish('playwright.test.failed', testData);
    } else if (result.status === 'passed') {
      await this.nats.publish('playwright.test.passed', testData);
    } else if (result.status === 'skipped') {
      await this.nats.publish('playwright.test.skipped', testData);
    }
  }

  async onStepBegin(test, result, step) {
    if (!this.nats?.isConnected) return;

    await this.nats.publish('playwright.step.begin', {
      testRunId: this.testRunId,
      testId: test.id,
      stepId: step.titlePath().join('.'),
      title: step.title,
      category: step.category,
      startTime: step.startTime,
      parent: step.parent?.title
    });
  }

  async onStepEnd(test, result, step) {
    if (!this.nats?.isConnected) return;

    await this.nats.publish('playwright.step.end', {
      testRunId: this.testRunId,
      testId: test.id,
      stepId: step.titlePath().join('.'),
      title: step.title,
      category: step.category,
      duration: step.duration,
      error: step.error ? {
        message: step.error.message,
        stack: step.error.stack
      } : null
    });
  }

  async onEnd(result) {
    if (!this.nats?.isConnected) return;

    const suiteEndTime = Date.now();
    const totalDuration = suiteEndTime - this.suiteStartTime;

    await this.nats.publish('playwright.suite.end', {
      testRunId: this.testRunId,
      status: result.status,
      duration: totalDuration,
      startTime: this.suiteStartTime,
      endTime: suiteEndTime,
      stats: {
        total: result.stats.total,
        passed: result.stats.passed,
        failed: result.stats.failed,
        skipped: result.stats.skipped,
        flaky: result.stats.flaky,
        interrupted: result.stats.interrupted
      }
    });

    // Close NATS connection
    if (this.nats) {
      await this.nats.close();
    }

    console.log('🎭 NATS Reporter: Test suite completed');
  }

  extractSteps(steps) {
    return steps.map(step => ({
      title: step.title,
      category: step.category,
      duration: step.duration,
      error: step.error ? {
        message: step.error.message,
        stack: step.error.stack
      } : null,
      steps: step.steps ? this.extractSteps(step.steps) : []
    }));
  }
}

export default NATSReporter;
