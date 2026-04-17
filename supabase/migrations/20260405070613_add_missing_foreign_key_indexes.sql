/*
  # Add Missing Foreign Key Indexes for Performance

  1. Changes
    - Adds indexes on all foreign key columns that were missing covering indexes
    - Improves query performance for joins and foreign key lookups
    - Prevents performance degradation at scale

  2. Security
    - No RLS changes
    - Only adds performance indexes

  3. Tables Affected
    - api_keys, assignment_rule_counselors, assignment_rule_execution_log
    - email_logs, email_queue, email_templates
    - integration_endpoints, invitations, lead_interactions
    - lead_ownership_history, leads, message_template_usage_log
    - message_templates, notes, organization_members
    - organizations, profiles, system_round_robin_state
    - teams, webhook_configurations, webhook_delivery_log
    - webhook_delivery_queue
*/

-- API Keys
CREATE INDEX IF NOT EXISTS idx_api_keys_created_by ON public.api_keys(created_by);

-- Assignment Rules
CREATE INDEX IF NOT EXISTS idx_assignment_rule_counselors_counselor_id ON public.assignment_rule_counselors(counselor_id);
CREATE INDEX IF NOT EXISTS idx_assignment_rule_execution_log_assigned_counselor ON public.assignment_rule_execution_log(assigned_counselor_id);

-- Email System
CREATE INDEX IF NOT EXISTS idx_email_logs_organization_id ON public.email_logs(organization_id);
CREATE INDEX IF NOT EXISTS idx_email_logs_queue_id ON public.email_logs(queue_id);
CREATE INDEX IF NOT EXISTS idx_email_queue_organization_id ON public.email_queue(organization_id);
CREATE INDEX IF NOT EXISTS idx_email_queue_template_id ON public.email_queue(template_id);
CREATE INDEX IF NOT EXISTS idx_email_templates_organization_id ON public.email_templates(organization_id);

-- Integration
CREATE INDEX IF NOT EXISTS idx_integration_endpoints_created_by ON public.integration_endpoints(created_by);

-- Invitations
CREATE INDEX IF NOT EXISTS idx_invitations_cancelled_by ON public.invitations(cancelled_by);
CREATE INDEX IF NOT EXISTS idx_invitations_invited_by ON public.invitations(invited_by);
CREATE INDEX IF NOT EXISTS idx_invitations_role_id ON public.invitations(role_id);

-- Lead Interactions
CREATE INDEX IF NOT EXISTS idx_lead_interactions_user_id ON public.lead_interactions(user_id);

-- Lead Ownership History
CREATE INDEX IF NOT EXISTS idx_lead_ownership_history_changed_by ON public.lead_ownership_history(changed_by);
CREATE INDEX IF NOT EXISTS idx_lead_ownership_history_from_owner ON public.lead_ownership_history(from_owner_id);
CREATE INDEX IF NOT EXISTS idx_lead_ownership_history_to_owner ON public.lead_ownership_history(to_owner_id);

-- Leads
CREATE INDEX IF NOT EXISTS idx_leads_created_by ON public.leads(created_by);
CREATE INDEX IF NOT EXISTS idx_leads_previous_owner ON public.leads(previous_lead_owner);

-- Message Templates
CREATE INDEX IF NOT EXISTS idx_message_template_usage_log_lead_id ON public.message_template_usage_log(lead_id);
CREATE INDEX IF NOT EXISTS idx_message_templates_approved_by ON public.message_templates(approved_by);
CREATE INDEX IF NOT EXISTS idx_message_templates_created_by ON public.message_templates(created_by);

-- Notes
CREATE INDEX IF NOT EXISTS idx_notes_user_id ON public.notes(user_id);

-- Organization Members
CREATE INDEX IF NOT EXISTS idx_organization_members_invited_by ON public.organization_members(invited_by);

-- Organizations
CREATE INDEX IF NOT EXISTS idx_organizations_suspended_by ON public.organizations(suspended_by);

-- Profiles
CREATE INDEX IF NOT EXISTS idx_profiles_disabled_by ON public.profiles(disabled_by);
CREATE INDEX IF NOT EXISTS idx_profiles_manager_id ON public.profiles(manager_id);

-- Round Robin
CREATE INDEX IF NOT EXISTS idx_system_round_robin_state_last_assigned ON public.system_round_robin_state(last_assigned_counselor_id);

-- Teams
CREATE INDEX IF NOT EXISTS idx_teams_team_lead_id ON public.teams(team_lead_id);

-- Webhooks
CREATE INDEX IF NOT EXISTS idx_webhook_configurations_created_by ON public.webhook_configurations(created_by);
CREATE INDEX IF NOT EXISTS idx_webhook_delivery_log_queue_id ON public.webhook_delivery_log(queue_id);
CREATE INDEX IF NOT EXISTS idx_webhook_delivery_queue_endpoint_id ON public.webhook_delivery_queue(endpoint_id);