# Step 13 — Bulk Post Upload (CSV)

**Phase:** 3
**Effort:** Medium
**Estimated Time:** 3–4 hours
**Dependencies:** None (independent feature)

---

## Goal

User ek CSV file upload kare jisme multiple posts hoon, system sab ko parse kare aur schedule kar de.

---

## CSV Format

User ko yeh format use karna hoga:

```csv
platform,content,scheduled_at
facebook,"Check out our latest blog post about AI trends!",2026-05-25 09:00
linkedin,"Excited to share our Q2 results! We grew by 40%...",2026-05-25 12:00
instagram,"Summer vibes with our new product line 🌞 #summer",2026-05-26 10:00
x,"Quick tip: Use AI to schedule your posts automatically! #socialmedia",2026-05-26 15:00
```

---

## Backend

### `POST /posts/bulk-upload`

```python
@router.post("/posts/bulk-upload")
async def bulk_upload_posts(
    file: UploadFile = File(...),
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db)
):
    import csv, io
    
    content = await file.read()
    text = content.decode("utf-8")
    reader = csv.DictReader(io.StringIO(text))
    
    created = []
    errors = []
    
    for i, row in enumerate(reader, start=2):
        try:
            platform = row.get("platform", "").strip().lower()
            post_content = row.get("content", "").strip()
            scheduled_at_str = row.get("scheduled_at", "").strip()
            
            if not all([platform, post_content, scheduled_at_str]):
                errors.append(f"Row {i}: Missing required fields")
                continue
            
            scheduled_at = datetime.fromisoformat(scheduled_at_str)
            
            post = ScheduledPost(
                user_id=current_user.id,
                platform=platform,
                content=post_content,
                scheduled_at=scheduled_at,
                status="scheduled",
                source="bulk_upload"
            )
            db.add(post)
            created.append(i)
        except Exception as e:
            errors.append(f"Row {i}: {str(e)}")
    
    await db.commit()
    
    return {
        "created": len(created),
        "errors": errors,
        "message": f"{len(created)} posts scheduled successfully"
    }
```

---

## Frontend

### File: `fb_dash/app/posts/page.tsx` ya naya `fb_dash/app/bulk-upload/page.tsx`

Option 1: `/posts` page mein ek "Bulk Upload" tab add karo
Option 2: Alag page banao `/bulk-upload`

**Recommended:** `/posts` mein tab, kyunki yeh related hai.

```tsx
// Bulk upload section
<div className="border-2 border-dashed border-border rounded-xl p-8 text-center">
  <Upload className="w-8 h-8 text-gray-400 mx-auto mb-3" />
  <p className="text-gray-400 mb-2">Upload CSV file</p>
  <p className="text-xs text-gray-500 mb-4">Format: platform, content, scheduled_at</p>
  
  <input
    type="file"
    accept=".csv"
    onChange={handleFileUpload}
    className="hidden"
    id="csv-upload"
  />
  <label htmlFor="csv-upload" className="px-4 py-2 bg-card border border-border rounded-lg text-sm cursor-pointer hover:bg-card/80">
    Choose CSV File
  </label>
</div>

{/* Template download */}
<button onClick={downloadTemplate} className="text-sm text-primary underline">
  Download CSV template
</button>

{/* Upload result */}
{uploadResult && (
  <div className={`p-4 rounded-lg ${uploadResult.errors.length > 0 ? "bg-yellow-500/10 text-yellow-400" : "bg-green-500/10 text-green-400"}`}>
    <p className="font-medium">{uploadResult.message}</p>
    {uploadResult.errors.map((e, i) => <p key={i} className="text-xs mt-1">{e}</p>)}
  </div>
)}
```

**Handler:**
```tsx
const handleFileUpload = async (e: React.ChangeEvent<HTMLInputElement>) => {
  const file = e.target.files?.[0];
  if (!file) return;
  
  const formData = new FormData();
  formData.append("file", file);
  
  const result = await apiManager.bulkUploadPosts(token, formData);
  setUploadResult(result);
};

const downloadTemplate = () => {
  const csv = "platform,content,scheduled_at\nfacebook,Your post content here,2026-05-25 09:00\n";
  const blob = new Blob([csv], { type: "text/csv" });
  const url = URL.createObjectURL(blob);
  const a = document.createElement("a");
  a.href = url;
  a.download = "socialhub-bulk-template.csv";
  a.click();
};
```

---

## Implementation Process

1. Backend endpoint add karo (`/posts/bulk-upload`)
2. Test with Postman (multipart/form-data)
3. `apiManager.ts` mein `bulkUploadPosts(token, formData)` add karo
4. Frontend mein upload section add karo
5. Template download button add karo
6. Test: CSV file banao, upload karo, Post Queue mein posts dikhni chahiye

---

**Next Step:** [Step 14 — Mobile Sidebar](step-14-mobile-sidebar.md)
