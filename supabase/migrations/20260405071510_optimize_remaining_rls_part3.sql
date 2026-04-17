/*
  # Optimize Remaining RLS Policies - Part 3

  1. Changes
    - Optimizes lead_activity_log, filter_presets, bulk_download_history, assignment rules
    - Uses (SELECT auth.uid()) pattern for performance
*/

-- Lead activity log policies
DROP POLICY IF EXISTS "Super admins can view all lead activity log" ON public.lead_activity_log;
DROP POLICY IF EXISTS "Users can create activity logs" ON public.lead_activity_log;
DROP POLICY IF EXISTS "Users can insert lead activity log in their organization" ON public.lead_activity_log;
DROP POLICY IF EXISTS "Users can update pinned status on activities" ON public.lead_activity_log;
DROP POLICY IF EXISTS "Users can view activity logs for accessible leads" ON public.lead_activity_log;
DROP POLICY IF EXISTS "Users can view lead activity log in their organization" ON public.lead_activity_log;

CREATE POLICY "Super admins can view all lead activity log"
  ON public.lead_activity_log FOR SELECT
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM public.profiles p
      JOIN public.roles r ON p.role_id = r.id
      WHERE p.id = (SELECT auth.uid())
      AND r.hierarchy_level = 1
    )
  );

CREATE POLICY "Users can create activity logs"
  ON public.lead_activity_log FOR INSERT
  TO authenticated
  WITH CHECK (user_id = (SELECT auth.uid()));

CREATE POLICY "Users can insert lead activity log in their organization"
  ON public.lead_activity_log FOR INSERT
  TO authenticated
  WITH CHECK (
    organization_id IN (
      SELECT organization_id
      FROM public.organization_members
      WHERE profile_id = (SELECT auth.uid())
    )
  );

CREATE POLICY "Users can update pinned status on activities"
  ON public.lead_activity_log FOR UPDATE
  TO authenticated
  USING (
    lead_id IN (
      SELECT id FROM public.leads
      WHERE current_lead_owner = (SELECT auth.uid())
    )
  );

CREATE POLICY "Users can view activity logs for accessible leads"
  ON public.lead_activity_log FOR SELECT
  TO authenticated
  USING (
    lead_id IN (
      SELECT id FROM public.leads
      WHERE current_lead_owner = (SELECT auth.uid())
      OR organization_id IN (
        SELECT organization_id
        FROM public.organization_members
        WHERE profile_id = (SELECT auth.uid())
      )
    )
  );

CREATE POLICY "Users can view lead activity log in their organization"
  ON public.lead_activity_log FOR SELECT
  TO authenticated
  USING (
    organization_id IN (
      SELECT organization_id
      FROM public.organization_members
      WHERE profile_id = (SELECT auth.uid())
    )
  );

-- Filter presets policies
DROP POLICY IF EXISTS "Super admins can view all filter presets" ON public.filter_presets;
DROP POLICY IF EXISTS "Users can create own filter presets" ON public.filter_presets;
DROP POLICY IF EXISTS "Users can delete own filter presets" ON public.filter_presets;
DROP POLICY IF EXISTS "Users can manage their filter presets in their organization" ON public.filter_presets;
DROP POLICY IF EXISTS "Users can update own filter presets" ON public.filter_presets;
DROP POLICY IF EXISTS "Users can view filter presets in their organization" ON public.filter_presets;
DROP POLICY IF EXISTS "Users can view own filter presets" ON public.filter_presets;

CREATE POLICY "Super admins can view all filter presets"
  ON public.filter_presets FOR SELECT
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM public.profiles p
      JOIN public.roles r ON p.role_id = r.id
      WHERE p.id = (SELECT auth.uid())
      AND r.hierarchy_level = 1
    )
  );

CREATE POLICY "Users can create own filter presets"
  ON public.filter_presets FOR INSERT
  TO authenticated
  WITH CHECK (user_id = (SELECT auth.uid()));

CREATE POLICY "Users can delete own filter presets"
  ON public.filter_presets FOR DELETE
  TO authenticated
  USING (user_id = (SELECT auth.uid()));

CREATE POLICY "Users can manage their filter presets in their organization"
  ON public.filter_presets FOR ALL
  TO authenticated
  USING (
    user_id = (SELECT auth.uid())
    AND organization_id IN (
      SELECT organization_id
      FROM public.organization_members
      WHERE profile_id = (SELECT auth.uid())
    )
  );

CREATE POLICY "Users can update own filter presets"
  ON public.filter_presets FOR UPDATE
  TO authenticated
  USING (user_id = (SELECT auth.uid()));

CREATE POLICY "Users can view filter presets in their organization"
  ON public.filter_presets FOR SELECT
  TO authenticated
  USING (
    organization_id IN (
      SELECT organization_id
      FROM public.organization_members
      WHERE profile_id = (SELECT auth.uid())
    )
  );

CREATE POLICY "Users can view own filter presets"
  ON public.filter_presets FOR SELECT
  TO authenticated
  USING (user_id = (SELECT auth.uid()));

-- Bulk download history policies
DROP POLICY IF EXISTS "Admins can view all download history" ON public.bulk_download_history;
DROP POLICY IF EXISTS "Super admins can view all bulk download history" ON public.bulk_download_history;
DROP POLICY IF EXISTS "Users can create download records" ON public.bulk_download_history;
DROP POLICY IF EXISTS "Users can manage bulk download history in their organization" ON public.bulk_download_history;
DROP POLICY IF EXISTS "Users can view bulk download history in their organization" ON public.bulk_download_history;
DROP POLICY IF EXISTS "Users can view own download history" ON public.bulk_download_history;

CREATE POLICY "Admins can view all download history"
  ON public.bulk_download_history FOR SELECT
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM public.profiles p
      JOIN public.roles r ON p.role_id = r.id
      WHERE p.id = (SELECT auth.uid())
      AND r.hierarchy_level <= 2
      AND p.organization_id = bulk_download_history.organization_id
    )
  );

CREATE POLICY "Super admins can view all bulk download history"
  ON public.bulk_download_history FOR SELECT
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM public.profiles p
      JOIN public.roles r ON p.role_id = r.id
      WHERE p.id = (SELECT auth.uid())
      AND r.hierarchy_level = 1
    )
  );

CREATE POLICY "Users can create download records"
  ON public.bulk_download_history FOR INSERT
  TO authenticated
  WITH CHECK (user_id = (SELECT auth.uid()));

CREATE POLICY "Users can manage bulk download history in their organization"
  ON public.bulk_download_history FOR ALL
  TO authenticated
  USING (
    organization_id IN (
      SELECT organization_id
      FROM public.organization_members
      WHERE profile_id = (SELECT auth.uid())
    )
  );

CREATE POLICY "Users can view bulk download history in their organization"
  ON public.bulk_download_history FOR SELECT
  TO authenticated
  USING (
    organization_id IN (
      SELECT organization_id
      FROM public.organization_members
      WHERE profile_id = (SELECT auth.uid())
    )
  );

CREATE POLICY "Users can view own download history"
  ON public.bulk_download_history FOR SELECT
  TO authenticated
  USING (user_id = (SELECT auth.uid()));

-- Assignment rules policies
DROP POLICY IF EXISTS "Admins can manage assignment rules in their organization" ON public.assignment_rules;
DROP POLICY IF EXISTS "Super admins can view all assignment rules" ON public.assignment_rules;
DROP POLICY IF EXISTS "Users can view assignment rules in their organization" ON public.assignment_rules;

CREATE POLICY "Admins can manage assignment rules in their organization"
  ON public.assignment_rules FOR ALL
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

CREATE POLICY "Super admins can view all assignment rules"
  ON public.assignment_rules FOR SELECT
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM public.profiles p
      JOIN public.roles r ON p.role_id = r.id
      WHERE p.id = (SELECT auth.uid())
      AND r.hierarchy_level = 1
    )
  );

CREATE POLICY "Users can view assignment rules in their organization"
  ON public.assignment_rules FOR SELECT
  TO authenticated
  USING (
    organization_id IN (
      SELECT organization_id
      FROM public.organization_members
      WHERE profile_id = (SELECT auth.uid())
    )
  );

-- Assignment rule criteria policies
DROP POLICY IF EXISTS "Admins can manage rule criteria" ON public.assignment_rule_criteria;

CREATE POLICY "Admins can manage rule criteria"
  ON public.assignment_rule_criteria FOR ALL
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM public.assignment_rules ar
      JOIN public.organization_members om ON ar.organization_id = om.organization_id
      WHERE ar.id = assignment_rule_criteria.rule_id
      AND om.profile_id = (SELECT auth.uid())
      AND EXISTS (
        SELECT 1 FROM public.profiles p
        JOIN public.roles r ON p.role_id = r.id
        WHERE p.id = (SELECT auth.uid())
        AND r.hierarchy_level <= 2
      )
    )
  );

-- Assignment rule counselors policies
DROP POLICY IF EXISTS "Admins can manage rule counselors" ON public.assignment_rule_counselors;

CREATE POLICY "Admins can manage rule counselors"
  ON public.assignment_rule_counselors FOR ALL
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM public.assignment_rules ar
      JOIN public.organization_members om ON ar.organization_id = om.organization_id
      WHERE ar.id = assignment_rule_counselors.rule_id
      AND om.profile_id = (SELECT auth.uid())
      AND EXISTS (
        SELECT 1 FROM public.profiles p
        JOIN public.roles r ON p.role_id = r.id
        WHERE p.id = (SELECT auth.uid())
        AND r.hierarchy_level <= 2
      )
    )
  );