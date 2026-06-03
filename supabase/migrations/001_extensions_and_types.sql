-- =============================================================================
-- Soulive / Dating One — Supabase Migration 001
-- Extensions, ENUMs, helper types
-- =============================================================================

-- PostGIS สำหรับคำนวณระยะทาง "ใกล้ฉัน" (Supabase รองรับ)
CREATE EXTENSION IF NOT EXISTS postgis WITH SCHEMA extensions;

-- UUID
CREATE EXTENSION IF NOT EXISTS "uuid-ossp" WITH SCHEMA extensions;

-- -----------------------------------------------------------------------------
-- ENUMs
-- -----------------------------------------------------------------------------

CREATE TYPE public.gender_type AS ENUM ('female', 'male', 'other');

CREATE TYPE public.post_reaction_type AS ENUM ('like', 'dislike');

CREATE TYPE public.message_type AS ENUM ('text', 'image', 'system');

CREATE TYPE public.report_status AS ENUM ('pending', 'reviewed', 'resolved', 'dismissed');

CREATE TYPE public.notification_type AS ENUM (
  'profile_like',
  'profile_view',
  'new_match',
  'post_like',
  'post_comment',
  'new_message'
);
