---
name: social-platforms
description: Facebook, Instagram, LinkedIn, X OAuth flows, platform-specific constraints, aur service files
metadata:
  type: project
---

# Social Platform Integrations

## Overview

| Platform | OAuth Type | Service File | Auth Route |
|---|---|---|---|
| Facebook | OAuth 2.0 (Meta) | facebook_service.py | `/auth/login-url`, `/auth/callback` |
| Instagram | OAuth 2.0 (Meta) | instagram_service.py | `/auth/instagram-login-url`, `/auth/instagram-callback` |
| LinkedIn | OAuth 2.0 | linkedin_service.py | `/auth/linkedin-login-url`, `/auth/linkedin-callback` |
| X/Twitter | OAuth 2.0 (PKCE) | x_service.py | `/auth/x-login-url`, `/auth/x-callback` |

---

## Facebook

**Service:** [fb_agent/app/services/facebook_service.py](../../../fb_agent/app/services/facebook_service.py)

**Env Vars:**
```
FACEBOOK_APP_ID
FACEBOOK_APP_SECRET
FACEBOOK_REDIRECT_URI   # Must match Meta Developer Console
```

**Flow:**
1. User `/auth/login-url` se Facebook login URL le
2. Facebook redirect karta hai `/auth/callback?code=X`
3. Code exchange → user access token
4. User ka access token se pages fetch (`/me/accounts`)
5. Page tokens `PageToken` table mein save

**Posting:** Page access token use karke Graph API se post

**Instagram via Facebook:**
- Instagram Business account Facebook page se linked hoti hai
- `instagram_business_account_id` `PageToken` mein save hota hai
- Posting: Instagram Graph API via Facebook

---

## Instagram Direct Login

**Service:** [fb_agent/app/services/instagram_service.py](../../../fb_agent/app/services/instagram_service.py)

**Env Vars:**
```
INSTAGRAM_APP_ID
INSTAGRAM_APP_SECRET
INSTAGRAM_REDIRECT_URI
```

Instagram Basic Display API ya Instagram Business API — direct login option.

---

## LinkedIn

**Service:** [fb_agent/app/services/linkedin_service.py](../../../fb_agent/app/services/linkedin_service.py)

**Env Vars:**
```
LINKEDIN_CLIENT_ID
LINKEDIN_CLIENT_SECRET
LINKEDIN_REDIRECT_URI   # Must match LinkedIn Developer App
```

**Key Detail:** LinkedIn posting ke liye **URN** zaroori hai (e.g., `urn:li:person:ABC123`)
- URN `LinkedInAccount.urn` field mein store hota hai
- Posting: LinkedIn Share API v2

**Token Expiry:** LinkedIn tokens expire hote hain — `expires_at` field check karo

---

## X / Twitter

**Service:** [fb_agent/app/services/x_service.py](../../../fb_agent/app/services/x_service.py)

**Env Vars:**
```
X_CLIENT_ID
X_CLIENT_SECRET
```

**Flow:** OAuth 2.0 with PKCE
- `x-callback/page.tsx` frontend par OAuth callback handle karta hai
- Tokens `XAccount` table mein store hote hain (access_token + refresh_token)
- Token refresh logic: `expires_at` check karo, expired hone par refresh karo

**Posting:** X API v2, `POST /2/tweets`

---

## Critical Constraints

### Redirect URIs
OAuth redirect URIs **social platform developer consoles** mein registered hain:
- Facebook: Meta Developer → App → OAuth Settings
- LinkedIn: LinkedIn Developer → App → Auth → Redirect URLs
- X: Twitter Developer Portal → App → Authentication Settings

**Redirect URI change karna = OAuth toot jaana**. Bina developer console update kiye backend mein change mat karo.

### CORS & Frontend URL
Backend `main.py` mein CORS sirf `https://fb.nexlabai.com` allow karta hai.
Local development mein CORS origins mein `http://localhost:3000` add karna padta hai.

### Token Storage Security
- Saare access tokens database mein plaintext store hote hain (production mein encryption recommended)
- `.env` ya database credentials share mat karo

---

## Platform Value Mappings

`ScheduledPost.platform` field values:

| Value | Meaning |
|---|---|
| `"facebook"` | Sirf Facebook |
| `"instagram"` | Sirf Instagram |
| `"linkedin"` | Sirf LinkedIn |
| `"x"` | Sirf X/Twitter |
| `"both"` | Facebook + Instagram |
| `"all"` | Saare platforms |

**Why:** OAuth flows aur platform constraints ka knowledge zaroori hai taaki integration changes carefully ki jayein.
**How to apply:** OAuth redirect URIs kabhi bhi user confirm kiye baghair change mat karo. Naya platform add karne se pehle env vars, DB model, aur service file — teeno ki zaroorat hoti hai.
