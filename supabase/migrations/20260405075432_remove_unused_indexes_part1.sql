/*
  # Remove Unused Indexes - Part 1
  
  Removing unused indexes improves:
  - INSERT/UPDATE/DELETE performance (no index maintenance overhead)
  - Storage space
  - Vacuum/analyze performance
*/

-- Audit log indexes
DROP INDEX IF EXISTS public.idx_audit_log_created_at;
DROP INDEX IF EXISTS public.idx_audit_log_target_org;
DROP INDEX IF EXISTS public.idx_audit_log_action_type;
DROP INDEX IF EXISTS public.idx_audit_log_user_id;
DROP INDEX IF EXISTS public.idx_audit_log_target_user_id;

-- Profile indexes
DROP INDEX IF EXISTS public.idx_profiles_status;
DROP INDEX IF EXISTS public.idx_profiles_mobile_number;
DROP INDEX IF EXISTS public.idx_profiles_disabled_at;
DROP INDEX IF EXISTS public.idx_profiles_organization_id;
DROP INDEX IF EXISTS public.idx_profiles_role_id;
DROP INDEX IF EXISTS public.idx_profiles_team_id;
DROP INDEX IF EXISTS public.idx_profiles_disabled_by;
DROP INDEX IF EXISTS public.idx_profiles_manager_id;

-- Bulk operations indexes
DROP INDEX IF EXISTS public.idx_bulk_download_history_user_id;
DROP INDEX IF EXISTS public.idx_bulk_download_history_downloaded_at;
DROP INDEX IF EXISTS public.idx_bulk_download_history_organization_id;
DROP INDEX IF EXISTS public.idx_bulk_upload_jobs_status;
DROP INDEX IF EXISTS public.idx_bulk_upload_jobs_uploaded_at;
DROP INDEX IF EXISTS public.idx_bulk_upload_jobs_organization_id;

-- Roles indexes
DROP INDEX IF EXISTS public.idx_roles_is_global;
DROP INDEX IF EXISTS public.idx_role_permissions_role_id;
DROP INDEX IF EXISTS public.idx_role_permissions_permission_id;
