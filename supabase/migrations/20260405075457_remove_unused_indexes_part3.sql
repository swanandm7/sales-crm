/*
  # Remove Unused Indexes - Part 3
  
  Continue removing unused indexes
*/

-- Lead interaction indexes
DROP INDEX IF EXISTS public.idx_lead_interactions_created_at;
DROP INDEX IF EXISTS public.idx_lead_interactions_user_id;

-- Ownership history indexes
DROP INDEX IF EXISTS public.idx_ownership_history_lead_id;
DROP INDEX IF EXISTS public.idx_ownership_history_changed_at;
DROP INDEX IF EXISTS public.idx_ownership_history_changed_by;
DROP INDEX IF EXISTS public.idx_ownership_history_from_owner;
DROP INDEX IF EXISTS public.idx_ownership_history_to_owner;

-- Followups indexes
DROP INDEX IF EXISTS public.idx_followups_user_id;
DROP INDEX IF EXISTS public.idx_followups_next_action_date;
DROP INDEX IF EXISTS public.idx_followups_status;
DROP INDEX IF EXISTS public.idx_followups_lead_id;
DROP INDEX IF EXISTS public.idx_followups_organization_id;
DROP INDEX IF EXISTS public.idx_followups_user_status_date;

-- Time tracking indexes
DROP INDEX IF EXISTS public.idx_time_tracking_user_id;
DROP INDEX IF EXISTS public.idx_time_tracking_is_active;

-- Lead activity log indexes
DROP INDEX IF EXISTS public.idx_lead_activity_log_user_id;
DROP INDEX IF EXISTS public.idx_lead_activity_log_is_pinned;
