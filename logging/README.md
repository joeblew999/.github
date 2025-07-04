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
3. Or manually: Get connection details from https://cloud.synadia.com/teams/2XrIt5ApHyjVq8XkELhTaP4vfO3

## Benefits

- **Structured**: Consistent, searchable logs
- **Flexible**: Text (dev) or JSON (prod) output  
- **Observable**: Real-time NATS streaming
- **Resilient**: Works with/without NATS
- **Simple**: Environment-controlled configuration
