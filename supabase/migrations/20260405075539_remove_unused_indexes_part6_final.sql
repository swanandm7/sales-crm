/*
  # Remove Unused Indexes - Part 6 (Final)
  
  Final batch of unused indexes
*/

-- Webhook event subscriptions and API keys
DROP INDEX IF EXISTS public.idx_event_subscriptions_endpoint;
DROP INDEX IF EXISTS public.idx_event_subscriptions_event;
DROP INDEX IF EXISTS public.idx_event_subscriptions_org;
DROP INDEX IF EXISTS public.idx_api_keys_org;
DROP INDEX IF EXISTS public.idx_api_keys_hash;
DROP INDEX IF EXISTS public.idx_api_keys_created_by;

-- Webhook request log and health metrics
DROP INDEX IF EXISTS public.idx_request_log_org;
DROP INDEX IF EXISTS public.idx_request_log_created;
DROP INDEX IF EXISTS public.idx_health_metrics_org_bucket;
DROP INDEX IF EXISTS public.idx_health_metrics_endpoint;

-- Assignment rules indexes
DROP INDEX IF EXISTS public.idx_assignment_rules_active;
DROP INDEX IF EXISTS public.idx_assignment_rules_organization_id;
DROP INDEX IF EXISTS public.idx_rule_criteria_rule_id;
DROP INDEX IF EXISTS public.idx_rule_counselors_rule_id;
DROP INDEX IF EXISTS public.idx_assignment_rule_counselors_counselor_id;
DROP INDEX IF EXISTS public.idx_execution_log_lead_id;
DROP INDEX IF EXISTS public.idx_execution_log_rule_id;
DROP INDEX IF EXISTS public.idx_assignment_rule_execution_log_assigned_counselor;

-- Teams and filter presets
DROP INDEX IF EXISTS public.idx_teams_organization_id;
DROP INDEX IF EXISTS public.idx_teams_team_lead_id;
DROP INDEX IF EXISTS public.idx_filter_presets_organization_id;
DROP INDEX IF EXISTS public.idx_system_round_robin_state_last_assigned;
