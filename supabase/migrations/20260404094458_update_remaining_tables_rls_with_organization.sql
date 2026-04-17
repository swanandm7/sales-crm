/*
  # Update RLS Policies for Remaining Tables with Organization Filtering

  1. Tables Updated
    - teams
    - followups
    - calls
    - notes
    - lead_sources
    - lead_statuses
    - message_templates
    - assignment_rules
    - bulk_upload_jobs
    - bulk_download_history
    - time_tracking_sessions
    - lead_activity_log
    - filter_presets

  2. Security
    - All tables now enforce organization-based isolation
    - Super admins can access all data across organizations
    - Regular users limited to their organization's data
*/

-- ========== TEAMS TABLE ==========
DROP POLICY IF EXISTS "Users can view teams" ON teams;
DROP POLICY IF EXISTS "Admins can manage teams" ON teams;
DROP POLICY IF EXISTS "Super admins can manage all teams" ON teams;

CREATE POLICY "Super admins can view all teams"
  ON teams FOR SELECT TO authenticated
  USING (is_super_admin(auth.uid()));

CREATE POLICY "Users can view teams in their organization"
  ON teams FOR SELECT TO authenticated
  USING (organization_id = get_user_organization_id(auth.uid()));

CREATE POLICY "Super admins can manage all teams"
  ON teams FOR ALL TO authenticated
  USING (is_super_admin(auth.uid()));

CREATE POLICY "Admins can manage teams in their organization"
  ON teams FOR ALL TO authenticated
  USING (
    organization_id = get_user_organization_id(auth.uid())
    AND get_user_hierarchy_level(auth.uid()) <= 2
  );

-- ========== FOLLOWUPS TABLE ==========
DROP POLICY IF EXISTS "Users can view followups" ON followups;
DROP POLICY IF EXISTS "Users can manage followups" ON followups;
DROP POLICY IF EXISTS "Admins can manage all followups" ON followups;

CREATE POLICY "Super admins can view all followups"
  ON followups FOR SELECT TO authenticated
  USING (is_super_admin(auth.uid()));

CREATE POLICY "Users can view followups in their organization"
  ON followups FOR SELECT TO authenticated
  USING (
    organization_id = get_user_organization_id(auth.uid())
    AND (
      user_id = auth.uid()
      OR get_user_hierarchy_level(auth.uid()) <= 2
    )
  );

CREATE POLICY "Users can manage their followups in their organization"
  ON followups FOR ALL TO authenticated
  USING (
    organization_id = get_user_organization_id(auth.uid())
    AND (
      user_id = auth.uid()
      OR get_user_hierarchy_level(auth.uid()) <= 2
      OR is_super_admin(auth.uid())
    )
  );

-- ========== CALLS TABLE ==========
DROP POLICY IF EXISTS "Users can view calls" ON calls;
DROP POLICY IF EXISTS "Users can manage calls" ON calls;

CREATE POLICY "Super admins can view all calls"
  ON calls FOR SELECT TO authenticated
  USING (is_super_admin(auth.uid()));

CREATE POLICY "Users can view calls in their organization"
  ON calls FOR SELECT TO authenticated
  USING (organization_id = get_user_organization_id(auth.uid()));

CREATE POLICY "Users can manage calls in their organization"
  ON calls FOR ALL TO authenticated
  USING (
    organization_id = get_user_organization_id(auth.uid())
    OR is_super_admin(auth.uid())
  );

-- ========== NOTES TABLE ==========
DROP POLICY IF EXISTS "Users can view notes" ON notes;
DROP POLICY IF EXISTS "Users can manage notes" ON notes;

CREATE POLICY "Super admins can view all notes"
  ON notes FOR SELECT TO authenticated
  USING (is_super_admin(auth.uid()));

CREATE POLICY "Users can view notes in their organization"
  ON notes FOR SELECT TO authenticated
  USING (organization_id = get_user_organization_id(auth.uid()));

CREATE POLICY "Users can manage notes in their organization"
  ON notes FOR ALL TO authenticated
  USING (
    organization_id = get_user_organization_id(auth.uid())
    OR is_super_admin(auth.uid())
  );

-- ========== LEAD_SOURCES TABLE ==========
DROP POLICY IF EXISTS "Users can view lead sources" ON lead_sources;
DROP POLICY IF EXISTS "Admins can manage lead sources" ON lead_sources;

CREATE POLICY "Super admins can view all lead sources"
  ON lead_sources FOR SELECT TO authenticated
  USING (is_super_admin(auth.uid()));

CREATE POLICY "Users can view lead sources in their organization"
  ON lead_sources FOR SELECT TO authenticated
  USING (organization_id = get_user_organization_id(auth.uid()));

CREATE POLICY "Admins can manage lead sources in their organization"
  ON lead_sources FOR ALL TO authenticated
  USING (
    organization_id = get_user_organization_id(auth.uid())
    AND get_user_hierarchy_level(auth.uid()) <= 2
    OR is_super_admin(auth.uid())
  );

-- ========== LEAD_STATUSES TABLE ==========
DROP POLICY IF EXISTS "Users can view lead statuses" ON lead_statuses;
DROP POLICY IF EXISTS "Admins can manage lead statuses" ON lead_statuses;

CREATE POLICY "Super admins can view all lead statuses"
  ON lead_statuses FOR SELECT TO authenticated
  USING (is_super_admin(auth.uid()));

CREATE POLICY "Users can view lead statuses in their organization"
  ON lead_statuses FOR SELECT TO authenticated
  USING (organization_id = get_user_organization_id(auth.uid()));

CREATE POLICY "Admins can manage lead statuses in their organization"
  ON lead_statuses FOR ALL TO authenticated
  USING (
    organization_id = get_user_organization_id(auth.uid())
    AND get_user_hierarchy_level(auth.uid()) <= 2
    OR is_super_admin(auth.uid())
  );

-- ========== MESSAGE_TEMPLATES TABLE ==========
DROP POLICY IF EXISTS "Users can view message templates" ON message_templates;
DROP POLICY IF EXISTS "Admins can manage message templates" ON message_templates;

CREATE POLICY "Super admins can view all message templates"
  ON message_templates FOR SELECT TO authenticated
  USING (is_super_admin(auth.uid()));

CREATE POLICY "Users can view message templates in their organization"
  ON message_templates FOR SELECT TO authenticated
  USING (organization_id = get_user_organization_id(auth.uid()));

CREATE POLICY "Admins can manage message templates in their organization"
  ON message_templates FOR ALL TO authenticated
  USING (
    organization_id = get_user_organization_id(auth.uid())
    AND get_user_hierarchy_level(auth.uid()) <= 2
    OR is_super_admin(auth.uid())
  );

-- ========== ASSIGNMENT_RULES TABLE ==========
DROP POLICY IF EXISTS "Users can view assignment rules" ON assignment_rules;
DROP POLICY IF EXISTS "Admins can manage assignment rules" ON assignment_rules;

CREATE POLICY "Super admins can view all assignment rules"
  ON assignment_rules FOR SELECT TO authenticated
  USING (is_super_admin(auth.uid()));

CREATE POLICY "Users can view assignment rules in their organization"
  ON assignment_rules FOR SELECT TO authenticated
  USING (organization_id = get_user_organization_id(auth.uid()));

CREATE POLICY "Admins can manage assignment rules in their organization"
  ON assignment_rules FOR ALL TO authenticated
  USING (
    organization_id = get_user_organization_id(auth.uid())
    AND get_user_hierarchy_level(auth.uid()) <= 2
    OR is_super_admin(auth.uid())
  );

-- ========== BULK_UPLOAD_JOBS TABLE ==========
DROP POLICY IF EXISTS "Users can view bulk upload jobs" ON bulk_upload_jobs;

CREATE POLICY "Super admins can view all bulk upload jobs"
  ON bulk_upload_jobs FOR SELECT TO authenticated
  USING (is_super_admin(auth.uid()));

CREATE POLICY "Users can view bulk upload jobs in their organization"
  ON bulk_upload_jobs FOR SELECT TO authenticated
  USING (organization_id = get_user_organization_id(auth.uid()));

CREATE POLICY "Users can manage bulk upload jobs in their organization"
  ON bulk_upload_jobs FOR ALL TO authenticated
  USING (
    organization_id = get_user_organization_id(auth.uid())
    OR is_super_admin(auth.uid())
  );

-- ========== BULK_DOWNLOAD_HISTORY TABLE ==========
DROP POLICY IF EXISTS "Users can view bulk download history" ON bulk_download_history;

CREATE POLICY "Super admins can view all bulk download history"
  ON bulk_download_history FOR SELECT TO authenticated
  USING (is_super_admin(auth.uid()));

CREATE POLICY "Users can view bulk download history in their organization"
  ON bulk_download_history FOR SELECT TO authenticated
  USING (organization_id = get_user_organization_id(auth.uid()));

CREATE POLICY "Users can manage bulk download history in their organization"
  ON bulk_download_history FOR ALL TO authenticated
  USING (
    organization_id = get_user_organization_id(auth.uid())
    OR is_super_admin(auth.uid())
  );

-- ========== TIME_TRACKING_SESSIONS TABLE ==========
DROP POLICY IF EXISTS "Users can view time tracking sessions" ON time_tracking_sessions;

CREATE POLICY "Super admins can view all time tracking sessions"
  ON time_tracking_sessions FOR SELECT TO authenticated
  USING (is_super_admin(auth.uid()));

CREATE POLICY "Users can view time tracking sessions in their organization"
  ON time_tracking_sessions FOR SELECT TO authenticated
  USING (organization_id = get_user_organization_id(auth.uid()));

CREATE POLICY "Users can manage their time tracking sessions"
  ON time_tracking_sessions FOR ALL TO authenticated
  USING (
    (organization_id = get_user_organization_id(auth.uid()) AND user_id = auth.uid())
    OR get_user_hierarchy_level(auth.uid()) <= 2
    OR is_super_admin(auth.uid())
  );

-- ========== LEAD_ACTIVITY_LOG TABLE ==========
DROP POLICY IF EXISTS "Users can view lead activity log" ON lead_activity_log;

CREATE POLICY "Super admins can view all lead activity log"
  ON lead_activity_log FOR SELECT TO authenticated
  USING (is_super_admin(auth.uid()));

CREATE POLICY "Users can view lead activity log in their organization"
  ON lead_activity_log FOR SELECT TO authenticated
  USING (organization_id = get_user_organization_id(auth.uid()));

CREATE POLICY "Users can insert lead activity log in their organization"
  ON lead_activity_log FOR INSERT TO authenticated
  WITH CHECK (
    organization_id = get_user_organization_id(auth.uid())
    OR is_super_admin(auth.uid())
  );

-- ========== FILTER_PRESETS TABLE ==========
DROP POLICY IF EXISTS "Users can view filter presets" ON filter_presets;
DROP POLICY IF EXISTS "Users can manage their filter presets" ON filter_presets;

CREATE POLICY "Super admins can view all filter presets"
  ON filter_presets FOR SELECT TO authenticated
  USING (is_super_admin(auth.uid()));

CREATE POLICY "Users can view filter presets in their organization"
  ON filter_presets FOR SELECT TO authenticated
  USING (organization_id = get_user_organization_id(auth.uid()));

CREATE POLICY "Users can manage their filter presets in their organization"
  ON filter_presets FOR ALL TO authenticated
  USING (
    (organization_id = get_user_organization_id(auth.uid()) AND user_id = auth.uid())
    OR is_super_admin(auth.uid())
  );