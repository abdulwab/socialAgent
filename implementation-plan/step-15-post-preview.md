# Step 15 — Post Preview (Platform Mockup)

**Phase:** 3
**Effort:** High
**Estimated Time:** 3–5 hours
**Dependencies:** None (pure frontend — mockup UI)

---

## Goal

Post create karte waqt user dekh sake ki post us platform pe kaisi dikhegi — realistic UI mockup.

---

## Where It Shows

`/posts` (New Post) page pe — content likhne ke baad, ek "Preview" tab ya side panel dikhao.

---

## Platform-Specific Mockups

### LinkedIn Preview
```
┌─────────────────────────────────────────┐
│ [Avatar] Abdul Baig                     │
│          Digital Marketing Expert       │
│          1st • Just now                 │
│                                         │
│  Excited to share our latest blog       │
│  post about AI trends! AI is going to   │
│  transform how we work in 2026...       │
│                                         │
│  #AITrends #DigitalMarketing            │
│                                         │
│  [image if attached]                    │
│                                         │
│  👍 Like  💬 Comment  🔁 Repost  ➤ Send │
└─────────────────────────────────────────┘
```

### Facebook Preview
```
┌─────────────────────────────────────────┐
│ [Avatar] Abdul Baig        🌐 · Just now│
│                                         │
│  Check out our latest blog post!        │
│  AI is transforming everything...       │
│                                         │
│  [image preview]                        │
│                                         │
│ 👍 Like  💬 Comment  ↗ Share            │
└─────────────────────────────────────────┘
```

### X (Twitter) Preview
```
┌─────────────────────────────────────────┐
│ [Avatar] Abdul Baig @abdulbaig          │
│                                         │
│  Quick tip: Use AI to schedule your     │
│  posts automatically! 🚀               │
│  #socialmedia #ai                       │
│                                         │
│  [image]                                │
│                                         │
│  🗨 0  🔁 0  ❤️ 0  📊                  │
└─────────────────────────────────────────┘
```

### Instagram Preview
```
┌─────────────────────────────────────────┐
│ [Avatar] abdulbaig23        •••         │
│                                         │
│  [LARGE IMAGE — full width]             │
│                                         │
│ ❤️ 🗨 ➤          🔖                     │
│                                         │
│ abdulbaig23 Summer vibes with our      │
│ new product line 🌞 #summer             │
└─────────────────────────────────────────┘
```

---

## Implementation

### File: `fb_dash/app/components/PostPreview.tsx` (NEW)

```tsx
"use client";
import { User } from "lucide-react";

interface Props {
  platform: string;
  content: string;
  imageUrl?: string;
  authorName?: string;
}

export default function PostPreview({ platform, content, imageUrl, authorName = "You" }: Props) {
  if (!platform) return (
    <div className="flex items-center justify-center h-40 text-gray-500 text-sm">
      Select a platform to see preview
    </div>
  );

  return (
    <div className="max-w-sm mx-auto">
      {platform === "linkedin" && <LinkedInMockup content={content} imageUrl={imageUrl} author={authorName} />}
      {platform === "facebook" && <FacebookMockup content={content} imageUrl={imageUrl} author={authorName} />}
      {platform === "x" && <XMockup content={content} imageUrl={imageUrl} author={authorName} />}
      {platform === "instagram" && <InstagramMockup content={content} imageUrl={imageUrl} author={authorName} />}
    </div>
  );
}

function LinkedInMockup({ content, imageUrl, author }: any) {
  return (
    <div className="bg-white text-gray-900 rounded-xl p-4 shadow-lg text-sm">
      <div className="flex items-center gap-3 mb-3">
        <div className="w-10 h-10 bg-blue-600 rounded-full flex items-center justify-center">
          <User className="w-5 h-5 text-white" />
        </div>
        <div>
          <p className="font-semibold text-sm">{author}</p>
          <p className="text-xs text-gray-500">1st • Just now</p>
        </div>
        <button className="ml-auto text-blue-600 text-xs font-semibold border border-blue-600 px-3 py-1 rounded-full">Follow</button>
      </div>
      <p className="text-sm leading-relaxed whitespace-pre-wrap mb-3">{content}</p>
      {imageUrl && <img src={imageUrl} className="w-full rounded-lg mb-3" alt="post" />}
      <div className="border-t pt-2 flex gap-4 text-gray-500 text-xs">
        <button>👍 Like</button>
        <button>💬 Comment</button>
        <button>🔁 Repost</button>
        <button>➤ Send</button>
      </div>
    </div>
  );
}

function FacebookMockup({ content, imageUrl, author }: any) {
  return (
    <div className="bg-white text-gray-900 rounded-xl p-4 shadow-lg text-sm">
      <div className="flex items-center gap-3 mb-3">
        <div className="w-10 h-10 bg-blue-500 rounded-full flex items-center justify-center">
          <User className="w-5 h-5 text-white" />
        </div>
        <div>
          <p className="font-semibold">{author}</p>
          <p className="text-xs text-gray-500">🌐 Just now</p>
        </div>
      </div>
      <p className="text-sm leading-relaxed whitespace-pre-wrap mb-3">{content}</p>
      {imageUrl && <img src={imageUrl} className="w-full mb-3" alt="post" />}
      <div className="border-t pt-2 flex gap-4 text-gray-500 text-xs">
        <button>👍 Like</button>
        <button>💬 Comment</button>
        <button>↗ Share</button>
      </div>
    </div>
  );
}

function XMockup({ content, imageUrl, author }: any) {
  return (
    <div className="bg-black text-white rounded-xl p-4 shadow-lg border border-gray-700">
      <div className="flex gap-3">
        <div className="w-10 h-10 bg-gray-600 rounded-full flex items-center justify-center shrink-0">
          <User className="w-5 h-5 text-white" />
        </div>
        <div className="flex-1">
          <div className="flex gap-2 items-center">
            <span className="font-bold text-sm">{author}</span>
            <span className="text-gray-500 text-xs">@{author.toLowerCase().replace(" ", "")} · now</span>
          </div>
          <p className="text-sm mt-1 leading-relaxed whitespace-pre-wrap">{content}</p>
          {imageUrl && <img src={imageUrl} className="w-full rounded-xl mt-2" alt="post" />}
          <div className="flex gap-6 mt-3 text-gray-500 text-xs">
            <span>🗨 0</span><span>🔁 0</span><span>❤️ 0</span><span>📊</span>
          </div>
        </div>
      </div>
    </div>
  );
}

function InstagramMockup({ content, imageUrl, author }: any) {
  return (
    <div className="bg-white text-gray-900 rounded-xl shadow-lg overflow-hidden text-sm">
      <div className="flex items-center gap-3 p-3">
        <div className="w-8 h-8 bg-gradient-to-tr from-yellow-400 to-pink-600 rounded-full flex items-center justify-center">
          <User className="w-4 h-4 text-white" />
        </div>
        <span className="font-semibold text-sm">{author.toLowerCase().replace(" ", "")}</span>
        <span className="ml-auto text-gray-400">•••</span>
      </div>
      {imageUrl ? (
        <img src={imageUrl} className="w-full" alt="post" />
      ) : (
        <div className="h-48 bg-gray-100 flex items-center justify-center text-gray-400 text-xs">
          No image
        </div>
      )}
      <div className="p-3">
        <div className="flex gap-4 text-lg mb-2">❤️ 🗨 ➤ <span className="ml-auto">🔖</span></div>
        <p><span className="font-semibold">{author.toLowerCase().replace(" ", "")}</span> {content}</p>
      </div>
    </div>
  );
}
```

---

### File: `fb_dash/app/posts/page.tsx`

Preview tab add karo:

```tsx
// Tabs: "Write" | "Preview"
const [tab, setTab] = useState<"write" | "preview">("write");

// Tab buttons
<div className="flex gap-2 border-b border-border mb-4">
  <button onClick={() => setTab("write")} className={tab === "write" ? "text-white border-b-2 border-primary" : "text-gray-400"}>Write</button>
  <button onClick={() => setTab("preview")} className={tab === "preview" ? "text-white border-b-2 border-primary" : "text-gray-400"}>Preview</button>
</div>

{tab === "write" && <PostForm />}
{tab === "preview" && (
  <PostPreview
    platform={selectedPlatform}
    content={postContent}
    imageUrl={imageUrl}
    authorName={userName}
  />
)}
```

---

## Implementation Process

1. `PostPreview.tsx` component create karo
2. `posts/page.tsx` mein tab UI add karo
3. Preview tab pe `PostPreview` render karo
4. Test: LinkedIn, Facebook, X, Instagram — saare preview check karo
5. Long content test karo
6. Image ke saath aur bina image ke test karo

---

**Phase 3 Complete! Congratulations.**

Baaki Phase 4 features (Team Collaboration, Unified Inbox, More Platforms) future planning mein hain.
