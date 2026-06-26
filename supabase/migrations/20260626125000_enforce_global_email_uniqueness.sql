-- Enforce global email uniqueness across the platform
-- "if a user exists then it cant be invited or added again in any organisation with same gmail"

-- 1. Ensure profiles have unique emails
CREATE UNIQUE INDEX IF NOT EXISTS profiles_email_key ON public.profiles(email);

-- 2. Create a function to check global uniqueness before invitation
CREATE OR REPLACE FUNCTION public.check_global_email_uniqueness()
RETURNS trigger AS $$
BEGIN
  -- Convert email to lowercase for consistent checking
  NEW.email := LOWER(TRIM(NEW.email));

  -- 1. Check if email already exists in profiles
  IF EXISTS (SELECT 1 FROM public.profiles WHERE LOWER(TRIM(email)) = NEW.email) THEN
    -- Postgres unique_violation code is 23505.
    -- The frontend explicitly checks for code 23505 to show a user-friendly error.
    RAISE EXCEPTION USING ERRCODE = '23505', MESSAGE = 'A user with this email already exists on the platform.';
  END IF;

  -- 2. Check if there is already an active/pending invitation for this email
  IF EXISTS (SELECT 1 FROM public.invitations WHERE LOWER(TRIM(email)) = NEW.email AND status = 'pending' AND id != NEW.id) THEN
    RAISE EXCEPTION USING ERRCODE = '23505', MESSAGE = 'An invitation for this email is already pending.';
  END IF;

  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- 3. Attach the trigger to the invitations table
DROP TRIGGER IF EXISTS enforce_global_email_unique ON public.invitations;
CREATE TRIGGER enforce_global_email_unique
  BEFORE INSERT OR UPDATE OF email ON public.invitations
  FOR EACH ROW
  EXECUTE FUNCTION public.check_global_email_uniqueness();
