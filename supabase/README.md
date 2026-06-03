# Soulive — ฐานข้อมูล Supabase (PostgreSQL)

ออกแบบครอบคลุมฟีเจอร์ในแอป Flutter ทั้ง 4 แท็บ: **หาเพื่อนใหม่**, **ฟีด**, **แชท**, **โปรไฟล์**

## แผนภาพตาราง (สรุป)

```
auth.users
    └── profiles (1:1)
            ├── profile_photos
            ├── profile_interests ── interests
            ├── discovery_preferences
            ├── profile_likes ──► (mutual) matches
            ├── profile_views
            ├── blocks / reports
            ├── posts
            │     ├── post_media
            │     ├── post_reactions (like/dislike)
            │     ├── post_comments
            │     └── post_bookmarks
            ├── conversations ── conversation_members
            │     └── messages
            └── notifications
```

## ไฟล์ Migration (รันตามลำดับ)

| ไฟล์ | เนื้อหา |
|------|---------|
| `001_extensions_and_types.sql` | PostGIS, ENUMs |
| `002_core_tables.sql` | profiles, photos, interests, discovery prefs |
| `003_social_interactions.sql` | likes, views, matches, blocks, reports |
| `004_feed.sql` | posts, media, reactions, comments, bookmarks |
| `005_chat.sql` | conversations, messages |
| `006_notifications.sql` | notifications |
| `007_functions_triggers.sql` | triggers, RPC `discover_nearby_users`, views |
| `008_rls_policies.sql` | Row Level Security |
| `009_storage.sql` | buckets: profile-photos, post-media, chat-media |
| `010_grants.sql` | สิทธิ์ anon / authenticated |

## วิธีติดตั้ง

### วิธีที่ 1 — Supabase Dashboard (SQL Editor)

1. สร้างโปรเจ็กต์ที่ [supabase.com](https://supabase.com)
2. เปิด **SQL Editor** → รันไฟล์ `001` ถึง `009` ตามลำดับ
3. (ถ้าต้องการ) รัน `seed.sql` สำหรับแท็กความสนใจ

### วิธีที่ 2 — Supabase CLI

```bash
cd D:\Weerawat\project-dating-one
supabase login
supabase link --project-ref YOUR_PROJECT_REF
supabase db push
```

## Storage buckets

| Bucket | ใช้กับ | Public |
|--------|--------|--------|
| `profile-photos` | รูปโปรไฟล์ | ใช่ |
| `post-media` | รูปในฟีด | ใช่ |
| `chat-media` | รูปในแชท | ไม่ (เฉพาะสมาชิกแชท) |

โครงสร้าง path แนะนำ: `{user_id}/{filename}`

## แมปกับหน้าแอป

| หน้าแอป | ตารางหลัก |
|---------|-----------|
| หาเพื่อนใหม่ | `profiles`, `profile_photos`, `profile_interests`, `discovery_preferences`, `profile_likes` |
| RPC ใกล้ฉัน | `discover_nearby_users()` + PostGIS |
| ฟีด | `posts`, `post_media`, `post_reactions`, `post_comments`, `post_bookmarks` |
| แชท | `conversations`, `conversation_members`, `messages` |
| โปรไฟล์ | `profiles`, `profile_views_count`, `likes_received_count` |
| โซเชียล | `line_id`, `instagram`, `x_handle`, `facebook` ใน `profiles` |
| ถูกใจคุณ | `profile_likes` WHERE `liked_id = me` |
| ตั้งค่า | UPDATE `profiles`, `profile_photos`, `profile_interests` |

## ฟังก์ชันสำคัญ

- **`discover_nearby_users(viewer_id, max_km, gender_filter, limit, offset)`** — รายการสมาชิกเรียงระยะทาง
- **`feed_posts_v`** — view ฟีดพร้อมรูปผู้เขียน
- **`my_conversations_v`** — รายการแชท + unread
- **`handle_new_user`** — สร้าง profile อัตโนมัติเมื่อสมัคร

## หมายเหตุด้านความปลอดภัย

- เปิด **RLS** ทุกตารางแล้ว (ไฟล์ `008`)
- ปรับ policy เพิ่มเติมก่อน production (เช่น จำกัดการอ่าน email จาก auth)
- `discover_nearby_users` ใช้ `SECURITY DEFINER` — ตรวจสอบสิทธิ์ในแอปก่อนเรียก

## ขั้นตอนถัดไป (Flutter)

1. เพิ่ม `supabase_flutter` ใน `pubspec.yaml`
2. แทนที่ `MockData` ด้วย Supabase client
3. อัปโหลดรูปผ่าน Storage API
