/*
  # Optimize Templates and Invitations RLS

  1. Changes
    - Optimizes message templates, invitations, email system
    - Uses (SELECT auth.uid()) pattern for performance
*/

-- Message templates policies
DROP POLICY IF EXISTS "Admins can create templates" ON public.message_templates;
DROP POLICY IF EXISTS "Admins can delete templates" ON public.message_templates;
DROP POLICY IF EXISTS "Admins can manage message templates in their organization" ON public.message_templates;
DROP POLICY IF EXISTS "Admins can update all templates" ON public.message_templates;
DROP POLICY IF EXISTS "Admins can view all templates" ON public.message_templates;
DROP POLICY IF EXISTS "Super admins can view all message templates" ON public.message_templates;
DROP POLICY IF EXISTS "Users can create draft templates" ON public.message_templates;
DROP POLICY IF EXISTS "Users can update own draft templates" ON public.message_templates;
DROP POLICY IF EXISTS "Users can view assigned approved templates" ON public.message_templates;
DROP POLICY IF EXISTS "Users can view message templates in their organization" ON public.message_templates;

CREATE POLICY "Admins can manage message templates in their organization"
  ON public.message_templates FOR ALL
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

CREATE POLICY "Super admins can view all message templates"
  ON public.message_templates FOR SELECT
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM public.profiles p
      JOIN public.roles r ON p.role_id = r.id
      WHERE p.id = (SELECT auth.uid())
      AND r.hierarchy_level = 1
    )
  );

CREATE POLICY "Users can create draft templates"
  ON public.message_templates FOR INSERT
  TO authenticated
  WITH CHECK (
    created_by = (SELECT auth.uid())
    AND is_draft = true
  );

CREATE POLICY "Users can update own draft templates"
  ON public.message_templates FOR UPDATE
  TO authenticated
  USING (
    created_by = (SELECT auth.uid())
    AND is_draft = true
  );

CREATE POLICY "Users can view message templates in their organization"
  ON public.message_templates FOR SELECT
  TO authenticated
  USING (
    organization_id IN (
      SELECT organization_id
      FROM public.organization_members
      WHERE profile_id = (SELECT auth.uid())
    )
  );

-- Message template users policies
DROP POLICY IF EXISTS "Admins can delete template users" ON public.message_template_users;
DROP POLICY IF EXISTS "Admins can insert template users" ON public.message_template_users;
DROP POLICY IF EXISTS "Admins can view all template users" ON public.message_template_users;
DROP POLICY IF EXISTS "Users can view own template assignments" ON public.message_template_users;

CREATE POLICY "Admins can delete template users"
  ON public.message_template_users FOR DELETE
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM public.profiles p
      JOIN public.roles r ON p.role_id = r.id
      WHERE p.id = (SELECT auth.uid())
      AND r.hierarchy_level <= 2
    )
  );

CREATE POLICY "Admins can insert template users"
  ON public.message_template_users FOR INSERT
  TO authenticated
  WITH CHECK (
    EXISTS (
      SELECT 1 FROM public.profiles p
      JOIN public.roles r ON p.role_id = r.id
      WHERE p.id = (SELECT auth.uid())
      AND r.hierarchy_level <= 2
    )
  );

CREATE POLICY "Admins can view all template users"
  ON public.message_template_users FOR SELECT
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM public.profiles p
      JOIN public.roles r ON p.role_id = r.id
      WHERE p.id = (SELECT auth.uid())
      AND r.hierarchy_level <= 2
    )
  );

CREATE POLICY "Users can view own template assignments"
  ON public.message_template_users FOR SELECT
  TO authenticated
  USING (user_id = (SELECT auth.uid()));

-- Message template usage log policies
DROP POLICY IF EXISTS "Admins can view all template usage" ON public.message_template_usage_log;
DROP POLICY IF EXISTS "Users can log template usage" ON public.message_template_usage_log;
DROP POLICY IF EXISTS "Users can view own template usage" ON public.message_template_usage_log;

CREATE POLICY "Admins can view all template usage"
  ON public.message_template_usage_log FOR SELECT
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM public.profiles p
      JOIN public.roles r ON p.role_id = r.id
      WHERE p.id = (SELECT auth.uid())
      AND r.hierarchy_level <= 2
    )
  );

CREATE POLICY "Users can log template usage"
  ON public.message_template_usage_log FOR INSERT
  TO authenticated
  WITH CHECK (user_id = (SELECT auth.uid()));

CREATE POLICY "Users can view own template usage"
  ON public.message_template_usage_log FOR SELECT
  TO authenticated
  USING (user_id = (SELECT auth.uid()));

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
    AND EXISTS (
      SELECT 1 FROM public.profiles p
      JOIN public.roles r ON p.role_id = r.id
      WHERE p.id = (SELECT auth.uid())
      AND r.hierarchy_level <= 2
    )
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
    AND EXISTS (
      SELECT 1 FROM public.profiles p
      JOIN public.roles r ON p.role_id = r.id
      WHERE p.id = (SELECT auth.uid())
      AND r.hierarchy_level <= 2
    )
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
    AND EXISTS (
      SELECT 1 FROM public.profiles p
      JOIN public.roles r ON p.role_id = r.id
      WHERE p.id = (SELECT auth.uid())
      AND r.hierarchy_level <= 2
    )
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
    AND EXISTS (
      SELECT 1 FROM public.profiles p
      JOIN public.roles r ON p.role_id = r.id
      WHERE p.id = (SELECT auth.uid())
      AND r.hierarchy_level <= 2
    )
  );

CREATE POLICY "Super admins can create invitations for any organization"
  ON public.invitations FOR INSERT
  TO authenticated
  WITH CHECK (
    EXISTS (
      SELECT 1 FROM public.profiles p
      JOIN public.roles r ON p.role_id = r.id
      WHERE p.id = (SELECT auth.uid())
      AND r.hierarchy_level = 1
    )
  );

CREATE POLICY "Super admins can view all invitations"
  ON public.invitations FOR SELECT
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM public.profiles p
      JOIN public.roles r ON p.role_id = r.id
      WHERE p.id = (SELECT auth.uid())
      AND r.hierarchy_level = 1
    )
  );

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
    AND EXISTS (
      SELECT 1 FROM public.profiles p
      JOIN public.roles r ON p.role_id = r.id
      WHERE p.id = (SELECT auth.uid())
      AND r.hierarchy_level <= 2
    )
  );

-- Email queue policies
DROP POLICY IF EXISTS "Users can view their email queue" ON public.email_queue;

CREATE POLICY "Users can view their email queue"
  ON public.email_queue FOR SELECT
  TO authenticated
  USING (
    organization_id IN (
      SELECT organization_id
      FROM public.organization_members
      WHERE profile_id = (SELECT auth.uid())
    )
  );

-- Email logs policies
DROP POLICY IF EXISTS "Users can view their email logs" ON public.email_logs;

CREATE POLICY "Users can view their email logs"
  ON public.email_logs FOR SELECT
  TO authenticated
  USING (
    organization_id IN (
      SELECT organization_id
      FROM public.organization_members
      WHERE profile_id = (SELECT auth.uid())
    )
  );