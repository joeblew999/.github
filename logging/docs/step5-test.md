# 🧪 Step 5: Test Your Connection

## What This Test Does

Runs your logging example with Synadia NATS to verify everything works.

## Expected Success Output

If everything is configured correctly, you should see:

```json
{"time":"2025-07-04T13:35:22.841275+10:00","level":"INFO","msg":"NATS logging enabled","url":"tls://connect.ngs.global:4222","subject":"logs.registry"}
{"time":"2025-07-04T13:35:22.841346+10:00","level":"INFO","msg":"application starting","handlers":2}
```

**Key indicators of success:**
- ✅ `"NATS logging enabled"` message appears
- ✅ `"handlers":2` (console + NATS)
- ✅ No connection errors

## Common Issues

### Connection Failed
```
ERROR: failed to connect to NATS: connection refused
```
**Solutions:**
- Check your NATS_URL is correct
- Verify you have internet connection
- Confirm the Synadia endpoint is reachable

### Authentication Failed
```
ERROR: failed to connect to NATS: authorization violation
```
**Solutions:**
- Verify your .creds file path is correct
- Check the .creds file exists: `ls -la /path/to/your/file.creds`
- Re-download credentials from Synadia console

### File Not Found
```
ERROR: no such file or directory
```
**Solutions:**
- Double-check the NATS_CREDS path in your .env
- Use absolute path: `/Users/yourname/.config/nats/file.creds`
- Verify file permissions

## Success! What's Next?

Once connected, you can:

```bash
# Run full Synadia demo
task synadia-demo

# Subscribe to logs in real-time (in another terminal)
task subscribe-synadia

# Reset back to local development
task synadia-reset
```

## Celebration Time! 🎉

Your logging system now streams to Synadia NATS Cloud for production-ready observability!
