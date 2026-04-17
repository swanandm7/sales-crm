/*
  # Fix Function Search Path Security

  1. Changes
    - Sets explicit search_path on all functions to prevent search path attacks
    - Uses 'pg_catalog, public' for security
    - Maintains function behavior while improving security

  2. Security
    - Prevents malicious schema manipulation attacks
    - Ensures functions always reference correct schema objects
*/

-- Core validation functions
ALTER FUNCTION public.validate_mobile_number SET search_path = pg_catalog, public;
ALTER FUNCTION public.check_duplicate_mobile SET search_path = pg_catalog, public;
ALTER FUNCTION public.validate_sub_status SET search_path = pg_catalog, public;

-- Activity and stats functions
ALTER FUNCTION public.count_pinned_activities SET search_path = pg_catalog, public;
ALTER FUNCTION public.get_lead_activity_stats SET search_path = pg_catalog, public;
ALTER FUNCTION public.get_lead_status_display SET search_path = pg_catalog, public;

-- Lead management functions
ALTER FUNCTION public.merge_lead_data SET search_path = pg_catalog, public;
ALTER FUNCTION public.increment_call_count SET search_path = pg_catalog, public;
ALTER FUNCTION public.track_ownership_change SET search_path = pg_catalog, public;

-- Bulk operations
ALTER FUNCTION public.bulk_assign_leads SET search_path = pg_catalog, public;
ALTER FUNCTION public.bulk_change_lead_status SET search_path = pg_catalog, public;

-- Webhook functions
ALTER FUNCTION public.update_webhook_updated_at SET search_path = pg_catalog, public;
ALTER FUNCTION public.upsert_webhook_health_metric SET search_path = pg_catalog, public;
ALTER FUNCTION public.queue_webhook_delivery_for_lead SET search_path = pg_catalog, public;
ALTER FUNCTION public.queue_webhook_delivery_for_lead_update SET search_path = pg_catalog, public;

-- Assignment rule functions
ALTER FUNCTION public.match_assignment_rule_for_lead SET search_path = pg_catalog, public;
ALTER FUNCTION public.get_next_counselor_round_robin SET search_path = pg_catalog, public;
ALTER FUNCTION public.get_next_system_counselor SET search_path = pg_catalog, public;
ALTER FUNCTION public.evaluate_criteria_match SET search_path = pg_catalog, public;
ALTER FUNCTION public.seed_webhook_sources_for_org SET search_path = pg_catalog, public;
ALTER FUNCTION public.auto_assign_lead SET search_path = pg_catalog, public;
ALTER FUNCTION public.log_lead_assignment SET search_path = pg_catalog, public;
ALTER FUNCTION public.create_assignment_rule SET search_path = pg_catalog, public;
ALTER FUNCTION public.update_assignment_rule SET search_path = pg_catalog, public;
ALTER FUNCTION public.delete_assignment_rule SET search_path = pg_catalog, public;
ALTER FUNCTION public.toggle_assignment_rule_status SET search_path = pg_catalog, public;

-- Permission and access functions
ALTER FUNCTION public.get_user_hierarchy_level SET search_path = pg_catalog, public;
ALTER FUNCTION public.is_same_team SET search_path = pg_catalog, public;
ALTER FUNCTION public.is_team_lead_of SET search_path = pg_catalog, public;
ALTER FUNCTION public.user_has_permission SET search_path = pg_catalog, public;
ALTER FUNCTION public.is_super_admin SET search_path = pg_catalog, public;
ALTER FUNCTION public.can_access_organization SET search_path = pg_catalog, public;
ALTER FUNCTION public.get_user_organization_id SET search_path = pg_catalog, public;

-- Organization and capacity functions
ALTER FUNCTION public.calculate_max_users_from_tier SET search_path = pg_catalog, public;
ALTER FUNCTION public.check_user_status_on_login SET search_path = pg_catalog, public;
ALTER FUNCTION public.is_organization_at_limit SET search_path = pg_catalog, public;
ALTER FUNCTION public.check_organization_capacity_before_invite SET search_path = pg_catalog, public;

-- Invitation functions
ALTER FUNCTION public.expire_old_invitations SET search_path = pg_catalog, public;
ALTER FUNCTION public.validate_invitation_token SET search_path = pg_catalog, public;
ALTER FUNCTION public.resend_invitation SET search_path = pg_catalog, public;
ALTER FUNCTION public.check_invitation_expiry SET search_path = pg_catalog, public;

-- User management functions
ALTER FUNCTION public.update_full_name SET search_path = pg_catalog, public;
ALTER FUNCTION public.disable_user SET search_path = pg_catalog, public;
ALTER FUNCTION public.enable_user SET search_path = pg_catalog, public;
ALTER FUNCTION public.suspend_organization SET search_path = pg_catalog, public;
ALTER FUNCTION public.activate_organization SET search_path = pg_catalog, public;

-- Audit and logging
ALTER FUNCTION public.log_audit_event SET search_path = pg_catalog, public;
ALTER FUNCTION public.update_updated_at_column SET search_path = pg_catalog, public;