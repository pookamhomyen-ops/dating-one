-- =============================================================================
-- Migration 008 — Row Level Security (RLS)
-- =============================================================================

ALTER TABLE public.profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.profile_photos ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.interests ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.profile_interests ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.discovery_preferences ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.profile_likes ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.profile_views ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.matches ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.blocks ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.reports ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.posts ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.post_media ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.post_reactions ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.post_comments ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.post_bookmarks ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.conversations ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.conversation_members ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.messages ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.notifications ENABLE ROW LEVEL SECURITY;

-- -----------------------------------------------------------------------------
-- profiles
-- -----------------------------------------------------------------------------
CREATE POLICY "profiles_select_authenticated"
  ON public.profiles FOR SELECT
  TO authenticated
  USING (TRUE);

CREATE POLICY "profiles_update_own"
  ON public.profiles FOR UPDATE
  TO authenticated
  USING (auth.uid() = id)
  WITH CHECK (auth.uid() = id);

-- -----------------------------------------------------------------------------
-- profile_photos
-- -----------------------------------------------------------------------------
CREATE POLICY "profile_photos_select"
  ON public.profile_photos FOR SELECT TO authenticated USING (TRUE);

CREATE POLICY "profile_photos_insert_own"
  ON public.profile_photos FOR INSERT TO authenticated
  WITH CHECK (auth.uid() = profile_id);

CREATE POLICY "profile_photos_update_own"
  ON public.profile_photos FOR UPDATE TO authenticated
  USING (auth.uid() = profile_id);

CREATE POLICY "profile_photos_delete_own"
  ON public.profile_photos FOR DELETE TO authenticated
  USING (auth.uid() = profile_id);

-- -----------------------------------------------------------------------------
-- interests (อ่านได้ทุกคน, เพิ่มได้เมื่อ authenticated)
-- -----------------------------------------------------------------------------
CREATE POLICY "interests_select"
  ON public.interests FOR SELECT TO authenticated USING (TRUE);

CREATE POLICY "interests_insert"
  ON public.interests FOR INSERT TO authenticated WITH CHECK (TRUE);

-- -----------------------------------------------------------------------------
-- profile_interests
-- -----------------------------------------------------------------------------
CREATE POLICY "profile_interests_select"
  ON public.profile_interests FOR SELECT TO authenticated USING (TRUE);

CREATE POLICY "profile_interests_manage_own"
  ON public.profile_interests FOR ALL TO authenticated
  USING (auth.uid() = profile_id)
  WITH CHECK (auth.uid() = profile_id);

-- -----------------------------------------------------------------------------
-- discovery_preferences
-- -----------------------------------------------------------------------------
CREATE POLICY "discovery_prefs_select_own"
  ON public.discovery_preferences FOR SELECT TO authenticated
  USING (auth.uid() = profile_id);

CREATE POLICY "discovery_prefs_update_own"
  ON public.discovery_preferences FOR UPDATE TO authenticated
  USING (auth.uid() = profile_id)
  WITH CHECK (auth.uid() = profile_id);

-- -----------------------------------------------------------------------------
-- profile_likes
-- -----------------------------------------------------------------------------
CREATE POLICY "profile_likes_select"
  ON public.profile_likes FOR SELECT TO authenticated USING (TRUE);

CREATE POLICY "profile_likes_insert_own"
  ON public.profile_likes FOR INSERT TO authenticated
  WITH CHECK (auth.uid() = liker_id);

CREATE POLICY "profile_likes_delete_own"
  ON public.profile_likes FOR DELETE TO authenticated
  USING (auth.uid() = liker_id);

-- -----------------------------------------------------------------------------
-- profile_views
-- -----------------------------------------------------------------------------
CREATE POLICY "profile_views_insert_own"
  ON public.profile_views FOR INSERT TO authenticated
  WITH CHECK (auth.uid() = viewer_id);

CREATE POLICY "profile_views_select_received"
  ON public.profile_views FOR SELECT TO authenticated
  USING (auth.uid() = viewed_id OR auth.uid() = viewer_id);

-- -----------------------------------------------------------------------------
-- matches
-- -----------------------------------------------------------------------------
CREATE POLICY "matches_select_participant"
  ON public.matches FOR SELECT TO authenticated
  USING (auth.uid() = user_a_id OR auth.uid() = user_b_id);

-- -----------------------------------------------------------------------------
-- blocks
-- -----------------------------------------------------------------------------
CREATE POLICY "blocks_manage_own"
  ON public.blocks FOR ALL TO authenticated
  USING (auth.uid() = blocker_id)
  WITH CHECK (auth.uid() = blocker_id);

-- -----------------------------------------------------------------------------
-- reports
-- -----------------------------------------------------------------------------
CREATE POLICY "reports_insert_own"
  ON public.reports FOR INSERT TO authenticated
  WITH CHECK (auth.uid() = reporter_id);

CREATE POLICY "reports_select_own"
  ON public.reports FOR SELECT TO authenticated
  USING (auth.uid() = reporter_id);

-- -----------------------------------------------------------------------------
-- posts
-- -----------------------------------------------------------------------------
CREATE POLICY "posts_select_published"
  ON public.posts FOR SELECT TO authenticated
  USING (is_published = TRUE);

CREATE POLICY "posts_insert_own"
  ON public.posts FOR INSERT TO authenticated
  WITH CHECK (auth.uid() = author_id);

CREATE POLICY "posts_update_own"
  ON public.posts FOR UPDATE TO authenticated
  USING (auth.uid() = author_id);

CREATE POLICY "posts_delete_own"
  ON public.posts FOR DELETE TO authenticated
  USING (auth.uid() = author_id);

-- -----------------------------------------------------------------------------
-- post_media, reactions, comments, bookmarks
-- -----------------------------------------------------------------------------
CREATE POLICY "post_media_select"
  ON public.post_media FOR SELECT TO authenticated USING (TRUE);

CREATE POLICY "post_media_manage_author"
  ON public.post_media FOR ALL TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM public.posts p
      WHERE p.id = post_id AND p.author_id = auth.uid()
    )
  );

CREATE POLICY "post_reactions_select"
  ON public.post_reactions FOR SELECT TO authenticated USING (TRUE);

CREATE POLICY "post_reactions_manage_own"
  ON public.post_reactions FOR ALL TO authenticated
  USING (auth.uid() = profile_id)
  WITH CHECK (auth.uid() = profile_id);

CREATE POLICY "post_comments_select"
  ON public.post_comments FOR SELECT TO authenticated USING (TRUE);

CREATE POLICY "post_comments_insert_own"
  ON public.post_comments FOR INSERT TO authenticated
  WITH CHECK (auth.uid() = author_id);

CREATE POLICY "post_comments_update_own"
  ON public.post_comments FOR UPDATE TO authenticated
  USING (auth.uid() = author_id);

CREATE POLICY "post_comments_delete_own"
  ON public.post_comments FOR DELETE TO authenticated
  USING (auth.uid() = author_id);

CREATE POLICY "post_bookmarks_manage_own"
  ON public.post_bookmarks FOR ALL TO authenticated
  USING (auth.uid() = profile_id)
  WITH CHECK (auth.uid() = profile_id);

-- -----------------------------------------------------------------------------
-- chat
-- -----------------------------------------------------------------------------
CREATE POLICY "conversations_select_member"
  ON public.conversations FOR SELECT TO authenticated
  USING (
    auth.uid() = user_low_id OR auth.uid() = user_high_id
  );

CREATE POLICY "conversation_members_select_own"
  ON public.conversation_members FOR SELECT TO authenticated
  USING (auth.uid() = profile_id);

CREATE POLICY "conversation_members_update_own"
  ON public.conversation_members FOR UPDATE TO authenticated
  USING (auth.uid() = profile_id);

CREATE POLICY "messages_select_member"
  ON public.messages FOR SELECT TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM public.conversation_members cm
      WHERE cm.conversation_id = messages.conversation_id
        AND cm.profile_id = auth.uid()
    )
  );

CREATE POLICY "messages_insert_member"
  ON public.messages FOR INSERT TO authenticated
  WITH CHECK (
    auth.uid() = sender_id
    AND EXISTS (
      SELECT 1 FROM public.conversation_members cm
      WHERE cm.conversation_id = messages.conversation_id
        AND cm.profile_id = auth.uid()
    )
  );

-- -----------------------------------------------------------------------------
-- notifications
-- -----------------------------------------------------------------------------
CREATE POLICY "notifications_select_own"
  ON public.notifications FOR SELECT TO authenticated
  USING (auth.uid() = recipient_id);

CREATE POLICY "notifications_update_own"
  ON public.notifications FOR UPDATE TO authenticated
  USING (auth.uid() = recipient_id);
