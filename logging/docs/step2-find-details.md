# 🔍 Step 2: Find Your Connection Details

## What to Look For

In your Synadia console, you need to find your NATS connection information.

## Common Locations

### Option 1: Accounts Tab
1. Click **"Accounts"** in the navigation
2. Select your account from the list
3. Look for **"Connection Info"** or **"Connect"** section

### Option 2: Apps Section
1. Click **"Apps"** in the navigation  
2. Create a new app OR select existing app
3. Look for **"Connection Details"** or **"Connect"** button

### Option 3: Connect Button
- Look for a prominent **"Connect"** button/section
- This often provides quick access to connection details

## Information You Need

### 📡 NATS URL
Usually looks like:
- `tls://connect.ngs.global:4222`
- `tls://connect.ngs.global:4443`
- Or similar Synadia endpoint

### 🔑 Credentials File
- Look for **"Download Credentials"** button
- File will be named something like `your-account.creds`
- This contains your authentication information

### 🎫 Alternative: JWT/Token
Some setups use:
- JWT tokens
- User/password combinations
- Token embedded in URL

## Next Step

Once you've located the connection information:

```bash
task synadia-step3
```
