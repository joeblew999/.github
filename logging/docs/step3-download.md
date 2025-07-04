# 💾 Step 3: Download Your Credentials

## Download the .creds File

1. **Click the "Download Credentials" button** in your Synadia console
2. **Save the file securely** - recommended locations:
   - `~/.config/nats/` (create directory if needed)
   - `~/.nats/` 
   - Or any secure location you prefer

3. **Note the full path** - you'll need this exact path for your `.env` file

## Copy the NATS URL

From the Synadia console, copy the exact NATS URL. Common formats:

```
tls://connect.ngs.global:4222
tls://connect.ngs.global:4443
tls://your-custom-endpoint:port
```

## Example Setup

If you saved your credentials to `~/.config/nats/my-team.creds` and your URL is `tls://connect.ngs.global:4222`, you'll use:

```bash
NATS_URL=tls://connect.ngs.global:4222
NATS_CREDS=/Users/yourname/.config/nats/my-team.creds
```

## Security Note

⚠️ **Keep your .creds file secure!**
- Don't commit it to git
- Don't share it publicly
- Treat it like a password

## Next Step

Once you have your credentials downloaded and URL copied:

```bash
task synadia-step4
```
