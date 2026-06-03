-- =============================================================================
-- Fix handle_new_user trigger to be more robust
-- =============================================================================

CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, extensions
AS $$
BEGIN
  -- Insert into profiles with conflict handling
  INSERT INTO public.profiles (id, display_name)
  VALUES (
    NEW.id,
    COALESCE(
      NEW.raw_user_meta_data ->> 'display_name',
      NEW.raw_user_meta_data ->> 'full_name',
      split_part(NEW.email, '@', 1),
      'สมาชิกใหม่'
    )
  )
  ON CONFLICT (id) DO NOTHING;

  -- Insert into discovery_preferences with conflict handling
  INSERT INTO public.discovery_preferences (profile_id)
  VALUES (NEW.id)
  ON CONFLICT (profile_id) DO NOTHING;

  RETURN NEW;
EXCEPTION WHEN OTHERS THEN
  -- Log error or handle it silently to not block auth
  -- In Supabase, trigger failures block user creation
  RETURN NEW; 
END;
$$;
