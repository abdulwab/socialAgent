# 🎯 General Rules

## Communication Rules

- Urdu/Roman Urdu mein baat karo agar user Urdu mein kare
- Technical terms English mein reh sakte hain
- Agar kuch unclear ho toh pehle poocho, assume mat karo

## File Rules

- Bina permission ke files delete mat karo
- `.env` aur secret files kabhi mat chhuao
- Git history preserve karo

## 🚀 Git & Memory Rules

- **Code update ke baad GitHub push karna zaroori hai** — har code change ke baad relevant repo (`fb_agent` ya `fb_dash`) mein commit karke `git push origin main` karo. Push kiye bina kaam complete nahi maana jayega.
- **GitHub push ke baad memory update karo** — agar push mein koi naya feature, bug fix, ya architecture change hai toh `.claude/memory/` ki relevant file update karo taake future sessions mein context accurate rahe.

## 🚫 Prohibited Actions (Bina Poocha Nahi Karna)

- Database schema change karna
- Dependencies add/remove karna
- Configuration files edit karna
- Kisi bhi file rename/move karna

---

## 💡 Example Workflow

**User:** "Login page mein remember me feature add karo"

**Response:**

```
## 📝 Plan

**Goal:** Login page mein "Remember Me" checkbox add karna

**Steps:**
1. LoginForm component mein checkbox add karna
2. State management update karna (useState)
3. localStorage/cookie mein token save karna
4. Token expiry logic likhna (7 days)
5. Logout par token clear karna

**Files Affected:** 
- src/components/LoginForm.jsx
- src/utils/auth.js

**Estimated Complexity:** Medium

Kya main yeh plan follow karoon? Ya koi change chahiye?
```
