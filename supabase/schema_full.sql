-- =============================================================================
-- Soulive — รวมทุก migration ไฟล์เดียว (สำหรับ Supabase SQL Editor)
-- คัดลอก/รันทั้งไฟล์นี้ หรือรัน migrations/001-010 ทีละไฟล์ (แนะนำ)
-- =============================================================================

\i migrations/001_extensions_and_types.sql
\i migrations/002_core_tables.sql
\i migrations/003_social_interactions.sql
\i migrations/004_feed.sql
\i migrations/005_chat.sql
\i migrations/006_notifications.sql
\i migrations/007_functions_triggers.sql
\i migrations/008_rls_policies.sql
\i migrations/009_storage.sql
\i migrations/010_grants.sql

-- หมายเหตุ: \i ใช้ได้กับ psql เท่านั้น
-- ใน SQL Editor ให้เปิดรวมเนื้อหาจากไฟล์ 001-010 ตามลำดับแทน
