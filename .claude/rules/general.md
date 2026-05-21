# 🎯 General Rules

## Communication Rules

- Urdu/Roman Urdu mein baat karo agar user Urdu mein kare
- Technical terms English mein reh sakte hain
- Agar kuch unclear ho toh pehle poocho, assume mat karo

## File Rules

- Bina permission ke files delete mat karo
- `.env` aur secret files kabhi mat chhuao
- Git history preserve karo

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
