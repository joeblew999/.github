# Playwright Guidance Concept

## What It Is

Visual guidance system to help users navigate Synadia's console to get their NATS credentials.

https://github.com/CoreyCole/datastarui as some good  example  stuff

## How It Works

- Opens browser to Synadia console
- Highlights where to click (visual cues only)
- User remains in control - they click, we just guide
- No data scraping or automation

## Key Points

- **Guidance not automation** - we show, user does
- **Visual help only** - highlights and tooltips
- **No security issues** - not reading or capturing data
- **Uses Bun** - simpler than Node.js ecosystem

## When To Use

Later when Synadia setup becomes a real blocker for users. For now, the markdown guides work fine.
