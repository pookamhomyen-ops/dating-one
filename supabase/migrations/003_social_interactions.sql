-- =============================================================================
-- Migration 003 — Likes, views, matches, blocks, reports
-- =============================================================================

-- -----------------------------------------------------------------------------
-- profile_likes (กดใจบนการ์ดหาเพื่อน / ถูกใจคุณ)
-- -----------------------------------------------------------------------------
CREATE TABLE public.profile_likes (
  id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  liker_id        UUID NOT NULL REFERENCES public.profiles (id) ON DELETE CASCADE,
  liked_id        UUID NOT NULL REFERENCES public.profiles (id) ON DELETE CASCADE,
  created_at      TIMESTAMPTZ NOT NULL DEFAULT NOW(),

  CONSTRAINT profile_likes_no_self CHECK (liker_id <> liked_id),
  UNIQUE (liker_id, liked_id)
);

CREATE INDEX idx_profile_likes_liked ON public.profile_likes (liked_id, created_at DESC);
CREATE INDEX idx_profile_likes_liker ON public.profile_likes (liker_id, created_at DESC);

-- -----------------------------------------------------------------------------
-- profile_views (คนเข้ามาดูโปรไฟล์)
-- -----------------------------------------------------------------------------
CREATE TABLE public.profile_views (
  id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  viewer_id       UUID NOT NULL REFERENCES public.profiles (id) ON DELETE CASCADE,
  viewed_id       UUID NOT NULL REFERENCES public.profiles (id) ON DELETE CASCADE,
  viewed_at       TIMESTAMPTZ NOT NULL DEFAULT NOW(),

  CONSTRAINT profile_views_no_self CHECK (viewer_id <> viewed_id)
);

-- จำกัดการนับซ้ำภายใน 24 ชม. (optional — ใช้ unique partial index)
CREATE UNIQUE INDEX idx_profile_views_daily
  ON public.profile_views (viewer_id, viewed_id, (DATE_TRUNC('day', viewed_at AT TIME ZONE 'UTC')));

CREATE INDEX idx_profile_views_viewed ON public.profile_views (viewed_id, viewed_at DESC);

-- -----------------------------------------------------------------------------
-- matches (กดใจกันทั้งสองฝ่าย — mutual like)
-- -----------------------------------------------------------------------------
CREATE TABLE public.matches (
  id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_a_id       UUID NOT NULL REFERENCES public.profiles (id) ON DELETE CASCADE,
  user_b_id       UUID NOT NULL REFERENCES public.profiles (id) ON DELETE CASCADE,
  matched_at      TIMESTAMPTZ NOT NULL DEFAULT NOW(),

  CONSTRAINT matches_ordered CHECK (user_a_id < user_b_id),
  CONSTRAINT matches_no_self CHECK (user_a_id <> user_b_id),
  UNIQUE (user_a_id, user_b_id)
);

CREATE INDEX idx_matches_user_a ON public.matches (user_a_id, matched_at DESC);
CREATE INDEX idx_matches_user_b ON public.matches (user_b_id, matched_at DESC);

-- -----------------------------------------------------------------------------
-- blocks
-- -----------------------------------------------------------------------------
CREATE TABLE public.blocks (
  blocker_id      UUID NOT NULL REFERENCES public.profiles (id) ON DELETE CASCADE,
  blocked_id      UUID NOT NULL REFERENCES public.profiles (id) ON DELETE CASCADE,
  reason          TEXT,
  created_at      TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  PRIMARY KEY (blocker_id, blocked_id),
  CONSTRAINT blocks_no_self CHECK (blocker_id <> blocked_id)
);

-- -----------------------------------------------------------------------------
-- reports
-- -----------------------------------------------------------------------------
CREATE TABLE public.reports (
  id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  reporter_id     UUID NOT NULL REFERENCES public.profiles (id) ON DELETE CASCADE,
  reported_id     UUID NOT NULL REFERENCES public.profiles (id) ON DELETE CASCADE,
  reason          TEXT NOT NULL,
  details         TEXT,
  status          public.report_status NOT NULL DEFAULT 'pending',
  created_at      TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  resolved_at     TIMESTAMPTZ,

  CONSTRAINT reports_no_self CHECK (reporter_id <> reported_id)
);

CREATE INDEX idx_reports_status ON public.reports (status, created_at DESC);
