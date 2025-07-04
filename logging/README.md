# Logging Example

Structured logging with Go's `slog` and optional NATS streaming. Supports local Docker NATS and Synadia NATS Cloud.

## Quick Start

```bash
# Basic logging
task demo              # Show text/JSON formats
task run-debug         # Debug level

# Local NATS
task nats-demo         # Full local demo

# Synadia NATS Cloud  
task setup-env         # Create .env (configure with your Synadia details)
task synadia-demo      # Use Synadia NATS
```

## Configuration

**Environment Variables:**
- `LOG_FORMAT=json` - JSON output (default: text)
- `LOG_LEVEL=debug` - Debug level (default: info)  
- `NATS_URL` - Enable NATS streaming
- `NATS_CREDS` - Synadia credentials file
- `NATS_TOKEN` - Token authentication

**Synadia Setup:**
1. Run `task synadia-help` for step-by-step guide
2. Follow tasks `synadia-step1` through `synadia-test`
3. Or use visual guidance: `task guide`

## Visual Guidance

```bash
# Fresh machine setup (one-time)
task -t Taskfile.playwright.yml setup    # Install Bun dependencies + browsers

# Interactive browser guidance for Synadia credentials
task guide                                # Delegates to Playwright taskfile
# OR directly:
task -t Taskfile.playwright.yml guide    # Auto-detects best browser
task -t Taskfile.playwright.yml guide-chrome    # Force Chrome
task -t Taskfile.playwright.yml guide-safari    # Force Safari/WebKit
```

## Benefits

- **Structured**: Consistent, searchable logs
- **Flexible**: Text (dev) or JSON (prod) output  
- **Observable**: Real-time NATS streaming
- **Resilient**: Works with/without NATS
- **Simple**: Environment-controlled configuration


## Command and Control via NATS

Uses [nats.js](https://github.com/nats-io/nats.js) for JavaScript NATS integration.

**Architecture Overview:**

NATS acts as the central nervous system for Playwright test orchestration and monitoring.

**Control Flow:**
- NATS Controller receives commands (run, stop, status) 
- Controller spawns Playwright processes using Task files
- Playwright publishes real-time events back to NATS
- External systems can monitor and control tests via NATS subjects

**Event Streams:**
- Test lifecycle events (start, pass, fail, complete)
- Browser interactions (page loads, requests, errors)
- System status and health checks

**Benefits:**
- Remote test execution and monitoring
- Real-time visibility into test progress
- Centralized control across multiple environments
- Event-driven integration with CI/CD pipelines

**Usage:**

```bash
# Start everything (manual terminals)
task -t Taskfile.nats.yml dev

# Start everything (parallel)  
task -t Taskfile.nats.yml dev-parallel

# Quick test
task -t Taskfile.nats.yml validate
```

**NATS Subjects:**
- Send commands: `playwright.control.*`
- Monitor events: `playwright.test.*`
- Health status: `playwright.status.*` 


