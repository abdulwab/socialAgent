---
name: time-skill
description: Display current time in Pakistan Standard Time (PKT, UTC+5). Use when user asks for current time, Pakistan time, PKT, or when debugging timezone-related scheduling issues in SocialHub.
user-invocable: true
---

# Time Skill — Pakistan Standard Time

Current date/time Pakistan Standard Time (PKT) mein dikhao.

## Task

Pakistan Standard Time (UTC+5) mein current date aur time display karo.

## Instructions

1. **Get Current Time** — yeh command run karo:

   **Windows (PowerShell):**
   ```powershell
   [System.TimeZoneInfo]::ConvertTimeBySystemTimeZoneId([DateTime]::UtcNow, "Pakistan Standard Time").ToString("yyyy-MM-dd HH:mm:ss")
   ```

   **Linux/Mac (Bash):**
   ```bash
   TZ='Asia/Karachi' date '+%Y-%m-%d %H:%M:%S %Z'
   ```

2. **Display Result:**
   ```
   Current Time in Pakistan (PKT): YYYY-MM-DD HH:MM:SS PKT
   ```

## Requirements

- Hamesha `Asia/Karachi` timezone use karo (UTC+5)
- 24-hour format
- Date bhi saath dikhao
- Output concise rakho

## SocialHub Scheduling Context

SocialHub mein scheduled posts timezone-aware hain. Jab koi scheduling bug debug karo:

- `ScheduledPost.timezone` field mein user ka timezone store hota hai (e.g., `"Asia/Karachi"`)
- `ScheduledPost.scheduled_time` UTC mein store hoti hai ya local — backend code check karo
- APScheduler har 5 minute mein pending posts check karta hai
- Pakistan users ke liye: UTC+5, koi DST nahi

## Common Timezones for Reference

| Region | Timezone String | UTC Offset |
|---|---|---|
| Pakistan | `Asia/Karachi` | UTC+5 |
| India | `Asia/Kolkata` | UTC+5:30 |
| UAE | `Asia/Dubai` | UTC+4 |
| UK | `Europe/London` | UTC+0/+1 |
| US Eastern | `America/New_York` | UTC-5/-4 |
| US Pacific | `America/Los_Angeles` | UTC-8/-7 |
