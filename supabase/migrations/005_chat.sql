-- =============================================================================
-- Migration 005 — Chat: conversations & messages
-- =============================================================================

CREATE TABLE public.conversations (
  id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  -- เก็บคู่สนทนาแบบเรียง UUID เพื่อ uniqueness (user_low < user_high)
  user_low_id     UUID NOT NULL REFERENCES public.profiles (id) ON DELETE CASCADE,
  user_high_id    UUID NOT NULL REFERENCES public.profiles (id) ON DELETE CASCADE,
  last_message_at TIMESTAMPTZ,
  last_message_preview TEXT,
  created_at      TIMESTAMPTZ NOT NULL DEFAULT NOW(),

  CONSTRAINT conversations_ordered CHECK (user_low_id < user_high_id),
  CONSTRAINT conversations_distinct CHECK (user_low_id <> user_high_id),
  UNIQUE (user_low_id, user_high_id)
);

CREATE INDEX idx_conversations_last_msg ON public.conversations (last_message_at DESC NULLS LAST);

-- สมาชิกในแชท (สำหรับ unread count ต่อคน)
CREATE TABLE public.conversation_members (
  conversation_id UUID NOT NULL REFERENCES public.conversations (id) ON DELETE CASCADE,
  profile_id      UUID NOT NULL REFERENCES public.profiles (id) ON DELETE CASCADE,
  unread_count    INTEGER NOT NULL DEFAULT 0 CHECK (unread_count >= 0),
  last_read_at    TIMESTAMPTZ,
  joined_at       TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  PRIMARY KEY (conversation_id, profile_id)
);

CREATE INDEX idx_conversation_members_profile ON public.conversation_members (profile_id);

-- -----------------------------------------------------------------------------
CREATE TABLE public.messages (
  id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  conversation_id UUID NOT NULL REFERENCES public.conversations (id) ON DELETE CASCADE,
  sender_id       UUID NOT NULL REFERENCES public.profiles (id) ON DELETE CASCADE,
  message_type    public.message_type NOT NULL DEFAULT 'text',
  body            TEXT NOT NULL DEFAULT '',
  media_path      TEXT,                    -- bucket: chat-media (ถ้าเป็นรูป)
  created_at      TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  edited_at       TIMESTAMPTZ,
  deleted_at      TIMESTAMPTZ,

  CONSTRAINT messages_body_len CHECK (char_length(body) <= 4000)
);

CREATE INDEX idx_messages_conversation ON public.messages (conversation_id, created_at ASC);
CREATE INDEX idx_messages_sender ON public.messages (sender_id, created_at DESC);
