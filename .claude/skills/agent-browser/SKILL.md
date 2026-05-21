---
name: agent-browser
description: Browser automation for web app testing, form filling, and UI verification. Use when testing SocialHub frontend features, verifying OAuth flows, or checking UI behavior at fb.nexlabai.com or localhost:3000.
user-invocable: true
---

# Agent Browser — Web Automation Skill

Browser automation ka use karo SocialHub frontend test karne ke liye.

## Core Workflow

1. **Navigate** — URL par jao
2. **Snapshot** — interactive elements ka reference lo (`-i` flag)
3. **Interact** — elements ke saath interact karo (`@e1`, `@e2` references se)
4. **Re-snapshot** — DOM changes ke baad fresh references lo

## Key Commands

```bash
# Navigate
agent-browser open https://fb.nexlabai.com
agent-browser open http://localhost:3000

# Snapshot (interactive elements)
agent-browser snapshot -i

# Interact with elements
agent-browser click @e1
agent-browser fill @e2 "text value"
agent-browser select @e1 "option value"

# Get info
agent-browser get url
agent-browser get title
agent-browser get text

# Screenshot
agent-browser screenshot

# Wait
agent-browser wait @e1          # element appear hone tak
agent-browser wait network-idle # network quiet hone tak
```

## SocialHub Test Scenarios

### Login Test
```
1. open http://localhost:3000/login
2. snapshot -i
3. fill @email "test@example.com"
4. fill @password "password123"
5. click @login-button
6. re-snapshot — dashboard load hona chahiye
```

### Post Generation Test
```
1. Login karo (upar dekhein)
2. open http://localhost:3000/posts
3. snapshot -i
4. fill @topic-input "AI trends 2025"
5. select @platform "linkedin"
6. click @generate-button
7. wait network-idle
8. re-snapshot — generated content dikhna chahiye
```

### OAuth Connection Test
```
1. open http://localhost:3000/connect-apps
2. snapshot -i
3. click @facebook-connect
4. wait url "facebook.com"  (OAuth redirect)
```

## Important Rule

**Har navigation ke baad re-snapshot karo.** Element references (`@e1`, `@e2`) page change hone ke baad invalid ho jate hain.

## SocialHub Specific Notes

- **Local dev URL**: `http://localhost:3000` (fb_dash npm run dev)
- **Production URL**: `https://fb.nexlabai.com`
- **Auth required pages**: pehle login karo, token localStorage mein save hoga
- **API calls**: network-idle wait karo before asserting results
