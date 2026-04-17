/*
  # Optimize Roles, Teams, Audit, and Webhooks RLS

  1. Changes
    - Optimizes roles, permissions, teams, audit_log, webhooks
    - Uses (SELECT auth.uid()) pattern for performance
*/

-- Roles policies
DROP POLICY IF EXISTS "Only admins can delete roles" ON public.roles;
DROP POLICY IF EXISTS "Only admins can insert roles" ON public.roles;
DROP POLICY IF EXISTS "Only admins can update roles" ON public.roles;

CREATE POLICY "Only admins can delete roles"
  ON public.roles FOR DELETE
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM public.profiles p
      JOIN public.roles r ON p.role_id = r.id
      WHERE p.id = (SELECT auth.uid())
      AND r.hierarchy_level <= 2
    )
  );

CREATE POLICY "Only admins can insert roles"
  ON public.roles FOR INSERT
  TO authenticated
  WITH CHECK (
    EXISTS (
      SELECT 1 FROM public.profiles p
      JOIN public.roles r ON p.role_id = r.id
      WHERE p.id = (SELECT auth.uid())
      AND r.hierarchy_level <= 2
    )
  );

CREATE POLICY "Only admins can update roles"
  ON public.roles FOR UPDATE
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM public.profiles p
      JOIN public.roles r ON p.role_id = r.id
      WHERE p.id = (SELECT auth.uid())
      AND r.hierarchy_level <= 2
    )
  );

-- Permissions policies
DROP POLICY IF EXISTS "Only super admins can modify permissions" ON public.permissions;

CREATE POLICY "Only super admins can modify permissions"
  ON public.permissions FOR ALL
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM public.profiles p
      JOIN public.roles r ON p.role_id = r.id
      WHERE p.id = (SELECT auth.uid())
      AND r.hierarchy_level = 1
    )
  );

-- Role permissions policies
DROP POLICY IF EXISTS "Only admins can modify role permissions" ON public.role_permissions;

CREATE POLICY "Only admins can modify role permissions"
  ON public.role_permissions FOR ALL
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM public.profiles p
      JOIN public.roles r ON p.role_id = r.id
      WHERE p.id = (SELECT auth.uid())
      AND r.hierarchy_level <= 2
    )
  );

-- Teams policies
DROP POLICY IF EXISTS "Admins can manage teams in their organization" ON public.teams;
DROP POLICY IF EXISTS "Only admins can modify teams" ON public.teams;
DROP POLICY IF EXISTS "Super admins can manage all teams" ON public.teams;
DROP POLICY IF EXISTS "Super admins can view all teams" ON public.teams;
DROP POLICY IF EXISTS "Users can view teams in their organization" ON public.teams;

CREATE POLICY "Admins can manage teams in their organization"
  ON public.teams FOR ALL
  TO authenticated
  USING (
    organization_id IN (
      SELECT organization_id
      FROM public.organization_members
      WHERE profile_id = (SELECT auth.uid())
    )
    AND EXISTS (
      SELECT 1 FROM public.profiles p
      JOIN public.roles r ON p.role_id = r.id
      WHERE p.id = (SELECT auth.uid())
      AND r.hierarchy_level <= 2
    )
  );

CREATE POLICY "Super admins can manage all teams"
  ON public.teams FOR ALL
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM public.profiles p
      JOIN public.roles r ON p.role_id = r.id
      WHERE p.id = (SELECT auth.uid())
      AND r.hierarchy_level = 1
    )
  );

CREATE POLICY "Super admins can view all teams"
  ON public.teams FOR SELECT
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM public.profiles p
      JOIN public.roles r ON p.role_id = r.id
      WHERE p.id = (SELECT auth.uid())
      AND r.hierarchy_level = 1
    )
  );

CREATE POLICY "Users can view teams in their organization"
  ON public.teams FOR SELECT
  TO authenticated
  USING (
    organization_id IN (
      SELECT organization_id
      FROM public.organization_members
      WHERE profile_id = (SELECT auth.uid())
    )
  );

-- Audit log policies
DROP POLICY IF EXISTS "Authenticated users can create audit log entries" ON public.audit_log;
DROP POLICY IF EXISTS "Only admins can view audit log" ON public.audit_log;

CREATE POLICY "Authenticated users can create audit log entries"
  ON public.audit_log FOR INSERT
  TO authenticated
  WITH CHECK (actor_user_id = (SELECT auth.uid()));

CREATE POLICY "Only admins can view audit log"
  ON public.audit_log FOR SELECT
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM public.profiles p
      JOIN public.roles r ON p.role_id = r.id
      WHERE p.id = (SELECT auth.uid())
      AND r.hierarchy_level <= 2
    )
  );

-- Webhook configurations policies
DROP POLICY IF EXISTS "Admins can delete webhook configs" ON public.webhook_configurations;
DROP POLICY IF EXISTS "Admins can insert webhook configs" ON public.webhook_configurations;
DROP POLICY IF EXISTS "Admins can update webhook configs" ON public.webhook_configurations;
DROP POLICY IF EXISTS "Users can view own organization webhook configs" ON public.webhook_configurations;

CREATE POLICY "Admins can delete webhook configs"
  ON public.webhook_configurations FOR DELETE
  TO authenticated
  USING (
    organization_id IN (
      SELECT organization_id
      FROM public.organization_members
      WHERE profile_id = (SELECT auth.uid())
    )
    AND EXISTS (
      SELECT 1 FROM public.profiles p
      JOIN public.roles r ON p.role_id = r.id
      WHERE p.id = (SELECT auth.uid())
      AND r.hierarchy_level <= 2
    )
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
    AND EXISTS (
      SELECT 1 FROM public.profiles p
      JOIN public.roles r ON p.role_id = r.id
      WHERE p.id = (SELECT auth.uid())
      AND r.hierarchy_level <= 2
    )
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
    AND EXISTS (
      SELECT 1 FROM public.profiles p
      JOIN public.roles r ON p.role_id = r.id
      WHERE p.id = (SELECT auth.uid())
      AND r.hierarchy_level <= 2
    )
  );

CREATE POLICY "Users can view own organization webhook configs"
  ON public.webhook_configurations FOR SELECT
  TO authenticated
  USING (
    organization_id IN (
      SELECT organization_id
      FROM public.organization_members
      WHERE profile_id = (SELECT auth.uid())
    )
  );

-- Webhook sources policies
DROP POLICY IF EXISTS "Admins can manage webhook sources" ON public.webhook_sources;
DROP POLICY IF EXISTS "Users can view own organization webhook sources" ON public.webhook_sources;

CREATE POLICY "Admins can manage webhook sources"
  ON public.webhook_sources FOR ALL
  TO authenticated
  USING (
    organization_id IN (
      SELECT organization_id
      FROM public.organization_members
      WHERE profile_id = (SELECT auth.uid())
    )
    AND EXISTS (
      SELECT 1 FROM public.profiles p
      JOIN public.roles r ON p.role_id = r.id
      WHERE p.id = (SELECT auth.uid())
      AND r.hierarchy_level <= 2
    )
  );

CREATE POLICY "Users can view own organization webhook sources"
  ON public.webhook_sources FOR SELECT
  TO authenticated
  USING (
    organization_id IN (
      SELECT organization_id
      FROM public.organization_members
      WHERE profile_id = (SELECT auth.uid())
    )
  );

-- Integration endpoints policies
DROP POLICY IF EXISTS "Admins can manage integration endpoints" ON public.integration_endpoints;
DROP POLICY IF EXISTS "Users can view own organization endpoints" ON public.integration_endpoints;

CREATE POLICY "Admins can manage integration endpoints"
  ON public.integration_endpoints FOR ALL
  TO authenticated
  USING (
    organization_id IN (
      SELECT organization_id
      FROM public.organization_members
      WHERE profile_id = (SELECT auth.uid())
    )
    AND EXISTS (
      SELECT 1 FROM public.profiles p
      JOIN public.roles r ON p.role_id = r.id
      WHERE p.id = (SELECT auth.uid())
      AND r.hierarchy_level <= 2
    )
  );

CREATE POLICY "Users can view own organization endpoints"
  ON public.integration_endpoints FOR SELECT
  TO authenticated
  USING (
    organization_id IN (
      SELECT organization_id
      FROM public.organization_members
      WHERE profile_id = (SELECT auth.uid())
    )
  );

-- Webhook delivery queue policies
DROP POLICY IF EXISTS "Users can view own organization delivery queue" ON public.webhook_delivery_queue;

CREATE POLICY "Users can view own organization delivery queue"
  ON public.webhook_delivery_queue FOR SELECT
  TO authenticated
  USING (
    organization_id IN (
      SELECT organization_id
      FROM public.organization_members
      WHERE profile_id = (SELECT auth.uid())
    )
  );

-- Webhook delivery log policies
DROP POLICY IF EXISTS "Users can view own organization delivery logs" ON public.webhook_delivery_log;

CREATE POLICY "Users can view own organization delivery logs"
  ON public.webhook_delivery_log FOR SELECT
  TO authenticated
  USING (
    organization_id IN (
      SELECT organization_id
      FROM public.organization_members
      WHERE profile_id = (SELECT auth.uid())
    )
  );

-- Webhook event subscriptions policies
DROP POLICY IF EXISTS "Admins can manage event subscriptions" ON public.webhook_event_subscriptions;
DROP POLICY IF EXISTS "Users can view own organization event subscriptions" ON public.webhook_event_subscriptions;

CREATE POLICY "Admins can manage event subscriptions"
  ON public.webhook_event_subscriptions FOR ALL
  TO authenticated
  USING (
    organization_id IN (
      SELECT organization_id
      FROM public.organization_members
      WHERE profile_id = (SELECT auth.uid())
    )
    AND EXISTS (
      SELECT 1 FROM public.profiles p
      JOIN public.roles r ON p.role_id = r.id
      WHERE p.id = (SELECT auth.uid())
      AND r.hierarchy_level <= 2
    )
  );

CREATE POLICY "Users can view own organization event subscriptions"
  ON public.webhook_event_subscriptions FOR SELECT
  TO authenticated
  USING (
    organization_id IN (
      SELECT organization_id
      FROM public.organization_members
      WHERE profile_id = (SELECT auth.uid())
    )
  );

-- API keys policies
DROP POLICY IF EXISTS "Admins can manage API keys" ON public.api_keys;
DROP POLICY IF EXISTS "Users can view own organization API keys" ON public.api_keys;

CREATE POLICY "Admins can manage API keys"
  ON public.api_keys FOR ALL
  TO authenticated
  USING (
    organization_id IN (
      SELECT organization_id
      FROM public.organization_members
      WHERE profile_id = (SELECT auth.uid())
    )
    AND EXISTS (
      SELECT 1 FROM public.profiles p
      JOIN public.roles r ON p.role_id = r.id
      WHERE p.id = (SELECT auth.uid())
      AND r.hierarchy_level <= 2
    )
  );

CREATE POLICY "Users can view own organization API keys"
  ON public.api_keys FOR SELECT
  TO authenticated
  USING (
    organization_id IN (
      SELECT organization_id
      FROM public.organization_members
      WHERE profile_id = (SELECT auth.uid())
    )
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
    AND EXISTS (
      SELECT 1 FROM public.profiles p
      JOIN public.roles r ON p.role_id = r.id
      WHERE p.id = (SELECT auth.uid())
      AND r.hierarchy_level <= 2
    )
  );

-- Webhook health metrics policies
DROP POLICY IF EXISTS "Users can view own organization health metrics" ON public.webhook_health_metrics;

CREATE POLICY "Users can view own organization health metrics"
  ON public.webhook_health_metrics FOR SELECT
  TO authenticated
  USING (
    organization_id IN (
      SELECT organization_id
      FROM public.organization_members
      WHERE profile_id = (SELECT auth.uid())
    )
  );