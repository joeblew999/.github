# ⚙️ Step 4: Configure Your .env File

## Edit Your .env File

Open the `.env` file in your logging directory and update it with your Synadia details.

## Configuration Template

```bash
# Logging Configuration
LOG_FORMAT=text              # text or json
LOG_LEVEL=info              # debug, info, warn, error

# Comment out local NATS
# NATS_URL=nats://localhost:4222

# Add your Synadia NATS details
NATS_URL=tls://connect.ngs.global:4222
NATS_CREDS=/path/to/your/downloaded.creds
```

## Real Example

Replace with your actual values:

```bash
# Your actual Synadia URL from step 3
NATS_URL=tls://connect.ngs.global:4222

# Full path to your downloaded .creds file
NATS_CREDS=/Users/apple/.config/nats/my-synadia-team.creds
```

## Alternative: Token Authentication

If you're using token authentication instead of .creds file:

```bash
# Token in URL format
NATS_URL=nats://your_token@connect.ngs.global:4222

# Or separate token
NATS_URL=tls://connect.ngs.global:4222
NATS_TOKEN=your_token_here
```

## Verify Your Configuration

Double-check:
- ✅ NATS_URL matches exactly what you copied from Synadia
- ✅ NATS_CREDS points to the correct file path
- ✅ File exists at that path: `ls -la /path/to/your/file.creds`

## Next Step

Ready to test your configuration:

```bash
task synadia-test
```
