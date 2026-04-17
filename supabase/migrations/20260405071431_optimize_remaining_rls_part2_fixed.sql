/*
  # Optimize Remaining RLS Policies - Part 2

  1. Changes
    - Optimizes lead_sources, lead_statuses, bulk_upload_jobs, time_tracking_sessions
    - Uses (SELECT auth.uid()) pattern for performance
*/

-- Lead sources policies
DROP POLICY IF EXISTS "Admins can manage lead sources in their organization" ON public.lead_sources;
DROP POLICY IF EXISTS "Super admins can view all lead sources" ON public.lead_sources;
DROP POLICY IF EXISTS "Users can view lead sources in their organization" ON public.lead_sources;

CREATE POLICY "Admins can manage lead sources in their organization"
  ON public.lead_sources FOR ALL
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

CREATE POLICY "Super admins can view all lead sources"
  ON public.lead_sources FOR SELECT
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM public.profiles p
      JOIN public.roles r ON p.role_id = r.id
      WHERE p.id = (SELECT auth.uid())
      AND r.hierarchy_level = 1
    )
  );

CREATE POLICY "Users can view lead sources in their organization"
  ON public.lead_sources FOR SELECT
  TO authenticated
  USING (
    organization_id IN (
      SELECT organization_id
      FROM public.organization_members
      WHERE profile_id = (SELECT auth.uid())
    )
  );

-- Lead statuses policies
DROP POLICY IF EXISTS "Admins can manage lead statuses in their organization" ON public.lead_statuses;
DROP POLICY IF EXISTS "Super admins can view all lead statuses" ON public.lead_statuses;
DROP POLICY IF EXISTS "Users can view lead statuses in their organization" ON public.lead_statuses;

CREATE POLICY "Admins can manage lead statuses in their organization"
  ON public.lead_statuses FOR ALL
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

CREATE POLICY "Super admins can view all lead statuses"
  ON public.lead_statuses FOR SELECT
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM public.profiles p
      JOIN public.roles r ON p.role_id = r.id
      WHERE p.id = (SELECT auth.uid())
      AND r.hierarchy_level = 1
    )
  );

CREATE POLICY "Users can view lead statuses in their organization"
  ON public.lead_statuses FOR SELECT
  TO authenticated
  USING (
    organization_id IN (
      SELECT organization_id
      FROM public.organization_members
      WHERE profile_id = (SELECT auth.uid())
    )
  );

-- Bulk upload jobs policies
DROP POLICY IF EXISTS "Super admins can view all bulk upload jobs" ON public.bulk_upload_jobs;
DROP POLICY IF EXISTS "Users can create upload jobs" ON public.bulk_upload_jobs;
DROP POLICY IF EXISTS "Users can delete own upload jobs" ON public.bulk_upload_jobs;
DROP POLICY IF EXISTS "Users can manage bulk upload jobs in their organization" ON public.bulk_upload_jobs;
DROP POLICY IF EXISTS "Users can update own upload jobs" ON public.bulk_upload_jobs;
DROP POLICY IF EXISTS "Users can view bulk upload jobs in their organization" ON public.bulk_upload_jobs;
DROP POLICY IF EXISTS "Users can view own upload jobs" ON public.bulk_upload_jobs;

CREATE POLICY "Super admins can view all bulk upload jobs"
  ON public.bulk_upload_jobs FOR SELECT
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM public.profiles p
      JOIN public.roles r ON p.role_id = r.id
      WHERE p.id = (SELECT auth.uid())
      AND r.hierarchy_level = 1
    )
  );

CREATE POLICY "Users can create upload jobs"
  ON public.bulk_upload_jobs FOR INSERT
  TO authenticated
  WITH CHECK (user_id = (SELECT auth.uid()));

CREATE POLICY "Users can delete own upload jobs"
  ON public.bulk_upload_jobs FOR DELETE
  TO authenticated
  USING (user_id = (SELECT auth.uid()));

CREATE POLICY "Users can manage bulk upload jobs in their organization"
  ON public.bulk_upload_jobs FOR ALL
  TO authenticated
  USING (
    organization_id IN (
      SELECT organization_id
      FROM public.organization_members
      WHERE profile_id = (SELECT auth.uid())
    )
  );

CREATE POLICY "Users can update own upload jobs"
  ON public.bulk_upload_jobs FOR UPDATE
  TO authenticated
  USING (user_id = (SELECT auth.uid()));

CREATE POLICY "Users can view bulk upload jobs in their organization"
  ON public.bulk_upload_jobs FOR SELECT
  TO authenticated
  USING (
    organization_id IN (
      SELECT organization_id
      FROM public.organization_members
      WHERE profile_id = (SELECT auth.uid())
    )
  );

CREATE POLICY "Users can view own upload jobs"
  ON public.bulk_upload_jobs FOR SELECT
  TO authenticated
  USING (user_id = (SELECT auth.uid()));

-- Time tracking sessions policies
DROP POLICY IF EXISTS "Super admins can view all time tracking sessions" ON public.time_tracking_sessions;
DROP POLICY IF EXISTS "Users can insert own time tracking sessions" ON public.time_tracking_sessions;
DROP POLICY IF EXISTS "Users can manage their time tracking sessions" ON public.time_tracking_sessions;
DROP POLICY IF EXISTS "Users can update own time tracking sessions" ON public.time_tracking_sessions;
DROP POLICY IF EXISTS "Users can view own time tracking sessions" ON public.time_tracking_sessions;
DROP POLICY IF EXISTS "Users can view time tracking sessions in their organization" ON public.time_tracking_sessions;

CREATE POLICY "Super admins can view all time tracking sessions"
  ON public.time_tracking_sessions FOR SELECT
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM public.profiles p
      JOIN public.roles r ON p.role_id = r.id
      WHERE p.id = (SELECT auth.uid())
      AND r.hierarchy_level = 1
    )
  );

CREATE POLICY "Users can insert own time tracking sessions"
  ON public.time_tracking_sessions FOR INSERT
  TO authenticated
  WITH CHECK (user_id = (SELECT auth.uid()));

CREATE POLICY "Users can manage their time tracking sessions"
  ON public.time_tracking_sessions FOR ALL
  TO authenticated
  USING (user_id = (SELECT auth.uid()));

CREATE POLICY "Users can update own time tracking sessions"
  ON public.time_tracking_sessions FOR UPDATE
  TO authenticated
  USING (user_id = (SELECT auth.uid()));

CREATE POLICY "Users can view own time tracking sessions"
  ON public.time_tracking_sessions FOR SELECT
  TO authenticated
  USING (user_id = (SELECT auth.uid()));

CREATE POLICY "Users can view time tracking sessions in their organization"
  ON public.time_tracking_sessions FOR SELECT
  TO authenticated
  USING (
    organization_id IN (
      SELECT organization_id
      FROM public.organization_members
      WHERE profile_id = (SELECT auth.uid())
    )
  );