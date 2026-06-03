-- =============================================================================
-- Migration 002 — Core tables: profiles, photos, interests, location
-- =============================================================================

-- -----------------------------------------------------------------------------
-- profiles (ผูกกับ auth.users ของ Supabase Auth)
-- -----------------------------------------------------------------------------
CREATE TABLE public.profiles (
  id              UUID PRIMARY KEY REFERENCES auth.users (id) ON DELETE CASCADE,
  display_name    TEXT NOT NULL DEFAULT '',
  gender          public.gender_type,
  birth_date      DATE,                    -- คำนวณอายุจาก birth_date
  bio             TEXT NOT NULL DEFAULT '',

  -- ที่อยู่ (แสดงในหน้า Discover / Profile)
  province        TEXT NOT NULL DEFAULT '',
  district        TEXT NOT NULL DEFAULT '',

  -- รายละเอียดเพิ่ม (การ์ดหาเพื่อน)
  university      TEXT NOT NULL DEFAULT '',
  occupation      TEXT NOT NULL DEFAULT '',

  -- โซเชียลมีเดีย
  line_id         TEXT NOT NULL DEFAULT '',
  instagram       TEXT NOT NULL DEFAULT '',
  x_handle        TEXT NOT NULL DEFAULT '',
  facebook        TEXT NOT NULL DEFAULT '',

  -- สถานะ & สถิติ (denormalized เพื่อความเร็ว — sync ด้วย trigger)
  is_verified     BOOLEAN NOT NULL DEFAULT FALSE,
  is_online       BOOLEAN NOT NULL DEFAULT FALSE,
  last_seen_at    TIMESTAMPTZ,
  profile_views_count   INTEGER NOT NULL DEFAULT 0 CHECK (profile_views_count >= 0),
  likes_received_count  INTEGER NOT NULL DEFAULT 0 CHECK (likes_received_count >= 0),

  -- ตำแหน่ง GPS (ใช้กับ "ใกล้ฉัน")
  latitude        DOUBLE PRECISION,
  longitude       DOUBLE PRECISION,
  location        extensions.geography(POINT, 4326),

  created_at      TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at      TIMESTAMPTZ NOT NULL DEFAULT NOW(),

  CONSTRAINT profiles_display_name_len CHECK (char_length(display_name) <= 100),
  CONSTRAINT profiles_bio_len CHECK (char_length(bio) <= 2000)
);

COMMENT ON TABLE public.profiles IS 'โปรไฟล์สมาชิก — 1:1 กับ auth.users';

CREATE INDEX idx_profiles_gender ON public.profiles (gender);
CREATE INDEX idx_profiles_province_district ON public.profiles (province, district);
CREATE INDEX idx_profiles_last_seen ON public.profiles (last_seen_at DESC NULLS LAST);
CREATE INDEX idx_profiles_location ON public.profiles USING GIST (location);

-- -----------------------------------------------------------------------------
-- profile_photos (รูปโปรไฟล์หลายรูป — เรียงลำดับ)
-- -----------------------------------------------------------------------------
CREATE TABLE public.profile_photos (
  id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  profile_id      UUID NOT NULL REFERENCES public.profiles (id) ON DELETE CASCADE,
  storage_path    TEXT NOT NULL,           -- bucket: profile-photos
  public_url      TEXT,                    -- URL สำเร็จรูป (optional cache)
  sort_order      SMALLINT NOT NULL DEFAULT 0,
  is_primary      BOOLEAN NOT NULL DEFAULT FALSE,
  created_at      TIMESTAMPTZ NOT NULL DEFAULT NOW(),

  UNIQUE (profile_id, sort_order)
);

CREATE INDEX idx_profile_photos_profile ON public.profile_photos (profile_id, sort_order);

-- -----------------------------------------------------------------------------
-- interests (แท็กความสนใจ — master list)
-- -----------------------------------------------------------------------------
CREATE TABLE public.interests (
  id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  name            TEXT NOT NULL UNIQUE,
  name_normalized TEXT NOT NULL UNIQUE,    -- lowercase สำหรับค้นหา
  created_at      TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- -----------------------------------------------------------------------------
-- profile_interests (ความสนใจของแต่ละคน)
-- -----------------------------------------------------------------------------
CREATE TABLE public.profile_interests (
  profile_id      UUID NOT NULL REFERENCES public.profiles (id) ON DELETE CASCADE,
  interest_id     UUID NOT NULL REFERENCES public.interests (id) ON DELETE CASCADE,
  created_at      TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  PRIMARY KEY (profile_id, interest_id)
);

CREATE INDEX idx_profile_interests_interest ON public.profile_interests (interest_id);

-- -----------------------------------------------------------------------------
-- discovery_preferences (ตัวกรองหน้าหาเพื่อน: ใกล้ฉัน, เพศ)
-- -----------------------------------------------------------------------------
CREATE TABLE public.discovery_preferences (
  profile_id          UUID PRIMARY KEY REFERENCES public.profiles (id) ON DELETE CASCADE,
  near_me_enabled     BOOLEAN NOT NULL DEFAULT TRUE,
  max_distance_km     NUMERIC(6, 2) NOT NULL DEFAULT 50.00 CHECK (max_distance_km > 0),
  gender_filter       public.gender_type[],  -- NULL = ทุกเพศ
  min_age             SMALLINT NOT NULL DEFAULT 18 CHECK (min_age >= 18),
  max_age             SMALLINT NOT NULL DEFAULT 60 CHECK (max_age <= 99),
  updated_at          TIMESTAMPTZ NOT NULL DEFAULT NOW()
);
