-- Drop the old overloaded version of mobile_log_call_outcome
-- that had 6 parameters. PostgREST gets confused because the new one has 8
-- (with the last two defaulting to NULL), causing a PGRST203 error.

DROP FUNCTION IF EXISTS public.mobile_log_call_outcome(
  UUID,
  TEXT,
  INTEGER,
  TEXT,
  TIMESTAMPTZ,
  TIMESTAMPTZ
);
