/*
  # Optimize Remaining RLS Policies - Part 1

  1. Changes
    - Optimizes calls, notes, lead_interactions, lead_ownership_history
    - Uses (SELECT auth.uid()) pattern for performance
*/

-- Calls table policies
DROP POLICY IF EXISTS "Super admins can view all calls" ON public.calls;
DROP POLICY IF EXISTS "Users can delete own calls" ON public.calls;
DROP POLICY IF EXISTS "Users can insert calls" ON public.calls;
DROP POLICY IF EXISTS "Users can manage calls in their organization" ON public.calls;
DROP POLICY IF EXISTS "Users can update own calls" ON public.calls;
DROP POLICY IF EXISTS "Users can view calls for their leads" ON public.calls;
DROP POLICY IF EXISTS "Users can view calls in their organization" ON public.calls;

CREATE POLICY "Super admins can view all calls"
  ON public.calls FOR SELECT
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM public.profiles p
      JOIN public.roles r ON p.role_id = r.id
      WHERE p.id = (SELECT auth.uid())
      AND r.hierarchy_level = 1
    )
  );

CREATE POLICY "Users can delete own calls"
  ON public.calls FOR DELETE
  TO authenticated
  USING (user_id = (SELECT auth.uid()));

CREATE POLICY "Users can insert calls"
  ON public.calls FOR INSERT
  TO authenticated
  WITH CHECK (user_id = (SELECT auth.uid()));

CREATE POLICY "Users can manage calls in their organization"
  ON public.calls FOR ALL
  TO authenticated
  USING (
    organization_id IN (
      SELECT organization_id
      FROM public.organization_members
      WHERE profile_id = (SELECT auth.uid())
    )
  );

CREATE POLICY "Users can update own calls"
  ON public.calls FOR UPDATE
  TO authenticated
  USING (user_id = (SELECT auth.uid()));

CREATE POLICY "Users can view calls for their leads"
  ON public.calls FOR SELECT
  TO authenticated
  USING (
    lead_id IN (
      SELECT id FROM public.leads
      WHERE current_lead_owner = (SELECT auth.uid())
    )
  );

CREATE POLICY "Users can view calls in their organization"
  ON public.calls FOR SELECT
  TO authenticated
  USING (
    organization_id IN (
      SELECT organization_id
      FROM public.organization_members
      WHERE profile_id = (SELECT auth.uid())
    )
  );

-- Notes table policies
DROP POLICY IF EXISTS "Super admins can view all notes" ON public.notes;
DROP POLICY IF EXISTS "Users can delete own notes" ON public.notes;
DROP POLICY IF EXISTS "Users can insert notes" ON public.notes;
DROP POLICY IF EXISTS "Users can manage notes in their organization" ON public.notes;
DROP POLICY IF EXISTS "Users can update own notes" ON public.notes;
DROP POLICY IF EXISTS "Users can view notes for their leads" ON public.notes;
DROP POLICY IF EXISTS "Users can view notes in their organization" ON public.notes;

CREATE POLICY "Super admins can view all notes"
  ON public.notes FOR SELECT
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM public.profiles p
      JOIN public.roles r ON p.role_id = r.id
      WHERE p.id = (SELECT auth.uid())
      AND r.hierarchy_level = 1
    )
  );

CREATE POLICY "Users can delete own notes"
  ON public.notes FOR DELETE
  TO authenticated
  USING (user_id = (SELECT auth.uid()));

CREATE POLICY "Users can insert notes"
  ON public.notes FOR INSERT
  TO authenticated
  WITH CHECK (user_id = (SELECT auth.uid()));

CREATE POLICY "Users can manage notes in their organization"
  ON public.notes FOR ALL
  TO authenticated
  USING (
    organization_id IN (
      SELECT organization_id
      FROM public.organization_members
      WHERE profile_id = (SELECT auth.uid())
    )
  );

CREATE POLICY "Users can update own notes"
  ON public.notes FOR UPDATE
  TO authenticated
  USING (user_id = (SELECT auth.uid()));

CREATE POLICY "Users can view notes for their leads"
  ON public.notes FOR SELECT
  TO authenticated
  USING (
    lead_id IN (
      SELECT id FROM public.leads
      WHERE current_lead_owner = (SELECT auth.uid())
    )
  );

CREATE POLICY "Users can view notes in their organization"
  ON public.notes FOR SELECT
  TO authenticated
  USING (
    organization_id IN (
      SELECT organization_id
      FROM public.organization_members
      WHERE profile_id = (SELECT auth.uid())
    )
  );

-- Lead interactions policies
DROP POLICY IF EXISTS "Users can create interactions for their leads" ON public.lead_interactions;
DROP POLICY IF EXISTS "Users can view interactions for their leads" ON public.lead_interactions;

CREATE POLICY "Users can create interactions for their leads"
  ON public.lead_interactions FOR INSERT
  TO authenticated
  WITH CHECK (
    lead_id IN (
      SELECT id FROM public.leads
      WHERE current_lead_owner = (SELECT auth.uid())
    )
  );

CREATE POLICY "Users can view interactions for their leads"
  ON public.lead_interactions FOR SELECT
  TO authenticated
  USING (
    lead_id IN (
      SELECT id FROM public.leads
      WHERE current_lead_owner = (SELECT auth.uid())
    )
  );

-- Lead ownership history policies
DROP POLICY IF EXISTS "Users can view ownership history for their leads" ON public.lead_ownership_history;

CREATE POLICY "Users can view ownership history for their leads"
  ON public.lead_ownership_history FOR SELECT
  TO authenticated
  USING (
    lead_id IN (
      SELECT id FROM public.leads
      WHERE current_lead_owner = (SELECT auth.uid())
    )
  );