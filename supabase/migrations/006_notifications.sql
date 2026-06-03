-- =============================================================================
-- Migration 006 — Notifications
-- =============================================================================

CREATE TABLE public.notifications (
  id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  recipient_id    UUID NOT NULL REFERENCES public.profiles (id) ON DELETE CASCADE,
  actor_id        UUID REFERENCES public.profiles (id) ON DELETE SET NULL,
  type            public.notification_type NOT NULL,
  title           TEXT NOT NULL DEFAULT '',
  body            TEXT NOT NULL DEFAULT '',
  -- อ้างอิง entity ที่เกี่ยวข้อง (post, conversation, profile)
  entity_type     TEXT,
  entity_id       UUID,
  is_read         BOOLEAN NOT NULL DEFAULT FALSE,
  created_at      TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_notifications_recipient ON public.notifications (recipient_id, created_at DESC);
CREATE INDEX idx_notifications_unread ON public.notifications (recipient_id) WHERE is_read = FALSE;
