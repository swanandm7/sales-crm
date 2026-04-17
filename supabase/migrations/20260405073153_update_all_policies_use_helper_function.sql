/*
  # Update All Policies to Use Helper Function

  1. Changes
    - Updates all policies that check role hierarchy to use the helper function
    - Prevents infinite recursion across all tables
*/

-- Update all policies that were checking role hierarchy
-- This prevents infinite recursion by avoiding self-referencing profiles table

-- Calls policies
DROP POLICY IF EXISTS "Super admins can view all calls" ON public.calls;
CREATE POLICY "Super admins can view all calls"
  ON public.calls FOR SELECT
  TO authenticated
  USING (public.get_my_role_hierarchy_level() = 1);

-- Notes policies
DROP POLICY IF EXISTS "Super admins can view all notes" ON public.notes;
CREATE POLICY "Super admins can view all notes"
  ON public.notes FOR SELECT
  TO authenticated
  USING (public.get_my_role_hierarchy_level() = 1);

-- Lead sources policies
DROP POLICY IF EXISTS "Admins can manage lead sources in their organization" ON public.lead_sources;
DROP POLICY IF EXISTS "Super admins can view all lead sources" ON public.lead_sources;

CREATE POLICY "Admins can manage lead sources in their organization"
  ON public.lead_sources FOR ALL
  TO authenticated
  USING (
    organization_id IN (
      SELECT organization_id
      FROM public.organization_members
      WHERE profile_id = (SELECT auth.uid())
    )
    AND public.get_my_role_hierarchy_level() <= 2
  );

CREATE POLICY "Super admins can view all lead sources"
  ON public.lead_sources FOR SELECT
  TO authenticated
  USING (public.get_my_role_hierarchy_level() = 1);

-- Lead statuses policies
DROP POLICY IF EXISTS "Admins can manage lead statuses in their organization" ON public.lead_statuses;
DROP POLICY IF EXISTS "Super admins can view all lead statuses" ON public.lead_statuses;

CREATE POLICY "Admins can manage lead statuses in their organization"
  ON public.lead_statuses FOR ALL
  TO authenticated
  USING (
    organization_id IN (
      SELECT organization_id
      FROM public.organization_members
      WHERE profile_id = (SELECT auth.uid())
    )
    AND public.get_my_role_hierarchy_level() <= 2
  );

CREATE POLICY "Super admins can view all lead statuses"
  ON public.lead_statuses FOR SELECT
  TO authenticated
  USING (public.get_my_role_hierarchy_level() = 1);

-- Bulk upload jobs policies
DROP POLICY IF EXISTS "Super admins can view all bulk upload jobs" ON public.bulk_upload_jobs;
CREATE POLICY "Super admins can view all bulk upload jobs"
  ON public.bulk_upload_jobs FOR SELECT
  TO authenticated
  USING (public.get_my_role_hierarchy_level() = 1);

-- Time tracking sessions policies
DROP POLICY IF EXISTS "Super admins can view all time tracking sessions" ON public.time_tracking_sessions;
CREATE POLICY "Super admins can view all time tracking sessions"
  ON public.time_tracking_sessions FOR SELECT
  TO authenticated
  USING (public.get_my_role_hierarchy_level() = 1);

-- Lead activity log policies
DROP POLICY IF EXISTS "Super admins can view all lead activity log" ON public.lead_activity_log;
CREATE POLICY "Super admins can view all lead activity log"
  ON public.lead_activity_log FOR SELECT
  TO authenticated
  USING (public.get_my_role_hierarchy_level() = 1);

-- Filter presets policies
DROP POLICY IF EXISTS "Super admins can view all filter presets" ON public.filter_presets;
CREATE POLICY "Super admins can view all filter presets"
  ON public.filter_presets FOR SELECT
  TO authenticated
  USING (public.get_my_role_hierarchy_level() = 1);

-- Bulk download history policies
DROP POLICY IF EXISTS "Admins can view all download history" ON public.bulk_download_history;
DROP POLICY IF EXISTS "Super admins can view all bulk download history" ON public.bulk_download_history;

CREATE POLICY "Admins can view all download history"
  ON public.bulk_download_history FOR SELECT
  TO authenticated
  USING (
    public.get_my_role_hierarchy_level() <= 2
    AND EXISTS (
      SELECT 1 FROM public.organization_members
      WHERE profile_id = (SELECT auth.uid())
      AND organization_id = bulk_download_history.organization_id
    )
  );

CREATE POLICY "Super admins can view all bulk download history"
  ON public.bulk_download_history FOR SELECT
  TO authenticated
  USING (public.get_my_role_hierarchy_level() = 1);

-- Assignment rules policies
DROP POLICY IF EXISTS "Admins can manage assignment rules in their organization" ON public.assignment_rules;
DROP POLICY IF EXISTS "Super admins can view all assignment rules" ON public.assignment_rules;

CREATE POLICY "Admins can manage assignment rules in their organization"
  ON public.assignment_rules FOR ALL
  TO authenticated
  USING (
    organization_id IN (
      SELECT organization_id
      FROM public.organization_members
      WHERE profile_id = (SELECT auth.uid())
    )
    AND public.get_my_role_hierarchy_level() <= 2
  );

CREATE POLICY "Super admins can view all assignment rules"
  ON public.assignment_rules FOR SELECT
  TO authenticated
  USING (public.get_my_role_hierarchy_level() = 1);

-- Assignment rule criteria policies
DROP POLICY IF EXISTS "Admins can manage rule criteria" ON public.assignment_rule_criteria;

CREATE POLICY "Admins can manage rule criteria"
  ON public.assignment_rule_criteria FOR ALL
  TO authenticated
  USING (
    public.get_my_role_hierarchy_level() <= 2
    AND EXISTS (
      SELECT 1 FROM public.assignment_rules ar
      JOIN public.organization_members om ON ar.organization_id = om.organization_id
      WHERE ar.id = assignment_rule_criteria.rule_id
      AND om.profile_id = (SELECT auth.uid())
    )
  );

-- Assignment rule counselors policies
DROP POLICY IF EXISTS "Admins can manage rule counselors" ON public.assignment_rule_counselors;

CREATE POLICY "Admins can manage rule counselors"
  ON public.assignment_rule_counselors FOR ALL
  TO authenticated
  USING (
    public.get_my_role_hierarchy_level() <= 2
    AND EXISTS (
      SELECT 1 FROM public.assignment_rules ar
      JOIN public.organization_members om ON ar.organization_id = om.organization_id
      WHERE ar.id = assignment_rule_counselors.rule_id
      AND om.profile_id = (SELECT auth.uid())
    )
  );

-- Message templates policies
DROP POLICY IF EXISTS "Admins can manage message templates in their organization" ON public.message_templates;
DROP POLICY IF EXISTS "Super admins can view all message templates" ON public.message_templates;

CREATE POLICY "Admins can manage message templates in their organization"
  ON public.message_templates FOR ALL
  TO authenticated
  USING (
    organization_id IN (
      SELECT organization_id
      FROM public.organization_members
      WHERE profile_id = (SELECT auth.uid())
    )
    AND public.get_my_role_hierarchy_level() <= 2
  );

CREATE POLICY "Super admins can view all message templates"
  ON public.message_templates FOR SELECT
  TO authenticated
  USING (public.get_my_role_hierarchy_level() = 1);

-- Message template users policies
DROP POLICY IF EXISTS "Admins can delete template users" ON public.message_template_users;
DROP POLICY IF EXISTS "Admins can insert template users" ON public.message_template_users;
DROP POLICY IF EXISTS "Admins can view all template users" ON public.message_template_users;

CREATE POLICY "Admins can delete template users"
  ON public.message_template_users FOR DELETE
  TO authenticated
  USING (public.get_my_role_hierarchy_level() <= 2);

CREATE POLICY "Admins can insert template users"
  ON public.message_template_users FOR INSERT
  TO authenticated
  WITH CHECK (public.get_my_role_hierarchy_level() <= 2);

CREATE POLICY "Admins can view all template users"
  ON public.message_template_users FOR SELECT
  TO authenticated
  USING (public.get_my_role_hierarchy_level() <= 2);

-- Message template usage log policies
DROP POLICY IF EXISTS "Admins can view all template usage" ON public.message_template_usage_log;

CREATE POLICY "Admins can view all template usage"
  ON public.message_template_usage_log FOR SELECT
  TO authenticated
  USING (public.get_my_role_hierarchy_level() <= 2);

-- Invitations policies
DROP POLICY IF EXISTS "Admins can create invitations" ON public.invitations;
DROP POLICY IF EXISTS "Admins can delete invitations" ON public.invitations;
DROP POLICY IF EXISTS "Admins can update invitations" ON public.invitations;
DROP POLICY IF EXISTS "Admins can view all invitations" ON public.invitations;
DROP POLICY IF EXISTS "Super admins can create invitations for any organization" ON public.invitations;
DROP POLICY IF EXISTS "Super admins can view all invitations" ON public.invitations;

CREATE POLICY "Admins can create invitations"
  ON public.invitations FOR INSERT
  TO authenticated
  WITH CHECK (
    organization_id IN (
      SELECT organization_id
      FROM public.organization_members
      WHERE profile_id = (SELECT auth.uid())
    )
    AND public.get_my_role_hierarchy_level() <= 2
  );

CREATE POLICY "Admins can delete invitations"
  ON public.invitations FOR DELETE
  TO authenticated
  USING (
    organization_id IN (
      SELECT organization_id
      FROM public.organization_members
      WHERE profile_id = (SELECT auth.uid())
    )
    AND public.get_my_role_hierarchy_level() <= 2
  );

CREATE POLICY "Admins can update invitations"
  ON public.invitations FOR UPDATE
  TO authenticated
  USING (
    organization_id IN (
      SELECT organization_id
      FROM public.organization_members
      WHERE profile_id = (SELECT auth.uid())
    )
    AND public.get_my_role_hierarchy_level() <= 2
  );

CREATE POLICY "Admins can view all invitations"
  ON public.invitations FOR SELECT
  TO authenticated
  USING (
    organization_id IN (
      SELECT organization_id
      FROM public.organization_members
      WHERE profile_id = (SELECT auth.uid())
    )
    AND public.get_my_role_hierarchy_level() <= 2
  );

CREATE POLICY "Super admins can create invitations for any organization"
  ON public.invitations FOR INSERT
  TO authenticated
  WITH CHECK (public.get_my_role_hierarchy_level() = 1);

CREATE POLICY "Super admins can view all invitations"
  ON public.invitations FOR SELECT
  TO authenticated
  USING (public.get_my_role_hierarchy_level() = 1);

-- Email templates policies
DROP POLICY IF EXISTS "Admins can manage email templates" ON public.email_templates;

CREATE POLICY "Admins can manage email templates"
  ON public.email_templates FOR ALL
  TO authenticated
  USING (
    organization_id IN (
      SELECT organization_id
      FROM public.organization_members
      WHERE profile_id = (SELECT auth.uid())
    )
    AND public.get_my_role_hierarchy_level() <= 2
  );

-- Roles policies
DROP POLICY IF EXISTS "Only admins can delete roles" ON public.roles;
DROP POLICY IF EXISTS "Only admins can insert roles" ON public.roles;
DROP POLICY IF EXISTS "Only admins can update roles" ON public.roles;

CREATE POLICY "Only admins can delete roles"
  ON public.roles FOR DELETE
  TO authenticated
  USING (public.get_my_role_hierarchy_level() <= 2);

CREATE POLICY "Only admins can insert roles"
  ON public.roles FOR INSERT
  TO authenticated
  WITH CHECK (public.get_my_role_hierarchy_level() <= 2);

CREATE POLICY "Only admins can update roles"
  ON public.roles FOR UPDATE
  TO authenticated
  USING (public.get_my_role_hierarchy_level() <= 2);

-- Permissions policies
DROP POLICY IF EXISTS "Only super admins can modify permissions" ON public.permissions;

CREATE POLICY "Only super admins can modify permissions"
  ON public.permissions FOR ALL
  TO authenticated
  USING (public.get_my_role_hierarchy_level() = 1);

-- Role permissions policies
DROP POLICY IF EXISTS "Only admins can modify role permissions" ON public.role_permissions;

CREATE POLICY "Only admins can modify role permissions"
  ON public.role_permissions FOR ALL
  TO authenticated
  USING (public.get_my_role_hierarchy_level() <= 2);

-- Teams policies
DROP POLICY IF EXISTS "Admins can manage teams in their organization" ON public.teams;
DROP POLICY IF EXISTS "Super admins can manage all teams" ON public.teams;
DROP POLICY IF EXISTS "Super admins can view all teams" ON public.teams;

CREATE POLICY "Admins can manage teams in their organization"
  ON public.teams FOR ALL
  TO authenticated
  USING (
    organization_id IN (
      SELECT organization_id
      FROM public.organization_members
      WHERE profile_id = (SELECT auth.uid())
    )
    AND public.get_my_role_hierarchy_level() <= 2
  );

CREATE POLICY "Super admins can manage all teams"
  ON public.teams FOR ALL
  TO authenticated
  USING (public.get_my_role_hierarchy_level() = 1);

CREATE POLICY "Super admins can view all teams"
  ON public.teams FOR SELECT
  TO authenticated
  USING (public.get_my_role_hierarchy_level() = 1);

-- Audit log policies
DROP POLICY IF EXISTS "Only admins can view audit log" ON public.audit_log;

CREATE POLICY "Only admins can view audit log"
  ON public.audit_log FOR SELECT
  TO authenticated
  USING (public.get_my_role_hierarchy_level() <= 2);

-- Webhook configurations policies
DROP POLICY IF EXISTS "Admins can delete webhook configs" ON public.webhook_configurations;
DROP POLICY IF EXISTS "Admins can insert webhook configs" ON public.webhook_configurations;
DROP POLICY IF EXISTS "Admins can update webhook configs" ON public.webhook_configurations;

CREATE POLICY "Admins can delete webhook configs"
  ON public.webhook_configurations FOR DELETE
  TO authenticated
  USING (
    organization_id IN (
      SELECT organization_id
      FROM public.organization_members
      WHERE profile_id = (SELECT auth.uid())
    )
    AND public.get_my_role_hierarchy_level() <= 2
  );

CREATE POLICY "Admins can insert webhook configs"
  ON public.webhook_configurations FOR INSERT
  TO authenticated
  WITH CHECK (
    organization_id IN (
      SELECT organization_id
      FROM public.organization_members
      WHERE profile_id = (SELECT auth.uid())
    )
    AND public.get_my_role_hierarchy_level() <= 2
  );

CREATE POLICY "Admins can update webhook configs"
  ON public.webhook_configurations FOR UPDATE
  TO authenticated
  USING (
    organization_id IN (
      SELECT organization_id
      FROM public.organization_members
      WHERE profile_id = (SELECT auth.uid())
    )
    AND public.get_my_role_hierarchy_level() <= 2
  );

-- Webhook sources policies
DROP POLICY IF EXISTS "Admins can manage webhook sources" ON public.webhook_sources;

CREATE POLICY "Admins can manage webhook sources"
  ON public.webhook_sources FOR ALL
  TO authenticated
  USING (
    organization_id IN (
      SELECT organization_id
      FROM public.organization_members
      WHERE profile_id = (SELECT auth.uid())
    )
    AND public.get_my_role_hierarchy_level() <= 2
  );

-- Integration endpoints policies
DROP POLICY IF EXISTS "Admins can manage integration endpoints" ON public.integration_endpoints;

CREATE POLICY "Admins can manage integration endpoints"
  ON public.integration_endpoints FOR ALL
  TO authenticated
  USING (
    organization_id IN (
      SELECT organization_id
      FROM public.organization_members
      WHERE profile_id = (SELECT auth.uid())
    )
    AND public.get_my_role_hierarchy_level() <= 2
  );

-- Webhook event subscriptions policies
DROP POLICY IF EXISTS "Admins can manage event subscriptions" ON public.webhook_event_subscriptions;

CREATE POLICY "Admins can manage event subscriptions"
  ON public.webhook_event_subscriptions FOR ALL
  TO authenticated
  USING (
    organization_id IN (
      SELECT organization_id
      FROM public.organization_members
      WHERE profile_id = (SELECT auth.uid())
    )
    AND public.get_my_role_hierarchy_level() <= 2
  );

-- API keys policies
DROP POLICY IF EXISTS "Admins can manage API keys" ON public.api_keys;

CREATE POLICY "Admins can manage API keys"
  ON public.api_keys FOR ALL
  TO authenticated
  USING (
    organization_id IN (
      SELECT organization_id
      FROM public.organization_members
      WHERE profile_id = (SELECT auth.uid())
    )
    AND public.get_my_role_hierarchy_level() <= 2
  );

-- Webhook request log policies
DROP POLICY IF EXISTS "Admins can view webhook request logs" ON public.webhook_request_log;

CREATE POLICY "Admins can view webhook request logs"
  ON public.webhook_request_log FOR SELECT
  TO authenticated
  USING (
    organization_id IN (
      SELECT organization_id
      FROM public.organization_members
      WHERE profile_id = (SELECT auth.uid())
    )
    AND public.get_my_role_hierarchy_level() <= 2
  );