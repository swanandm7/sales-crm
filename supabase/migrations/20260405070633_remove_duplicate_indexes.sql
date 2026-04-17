/*
  # Remove Duplicate Indexes

  1. Changes
    - Removes duplicate indexes that cover the same columns
    - Reduces storage overhead and maintenance cost
    - Improves write performance

  2. Duplicate Indexes Removed
    - audit_log: Keeps idx_audit_log_user_id, drops idx_audit_log_actor
    - audit_log: Keeps idx_audit_log_target_user_id, drops idx_audit_log_target_user
    - leads: Keeps idx_leads_current_owner, drops idx_leads_current_lead_owner
*/

-- Drop duplicate indexes
DROP INDEX IF EXISTS public.idx_audit_log_actor;
DROP INDEX IF EXISTS public.idx_audit_log_target_user;
DROP INDEX IF EXISTS public.idx_leads_current_lead_owner;