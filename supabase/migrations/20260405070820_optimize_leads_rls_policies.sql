/*
  # Optimize Leads RLS Policies for Performance

  1. Changes
    - Rewrites auth.uid() calls to use (SELECT auth.uid()) pattern
    - Optimizes the most frequently accessed table's policies
    - Prevents auth function re-evaluation per row

  2. Security
    - Maintains exact same security logic
*/

-- Drop existing policies
DROP POLICY IF EXISTS "Sales reps can view their own leads" ON public.leads;
DROP POLICY IF EXISTS "Sales reps can update their own leads" ON public.leads;
DROP POLICY IF EXISTS "Team leads can view their team's leads" ON public.leads;
DROP POLICY IF EXISTS "Team leads can update their team's leads" ON public.leads;
DROP POLICY IF EXISTS "Admins can view all leads in their organization" ON public.leads;
DROP POLICY IF EXISTS "Admins can update all leads in their organization" ON public.leads;
DROP POLICY IF EXISTS "Admins can delete leads in their organization" ON public.leads;
DROP POLICY IF EXISTS "Super admins can view all leads" ON public.leads;
DROP POLICY IF EXISTS "Super admins can insert leads" ON public.leads;
DROP POLICY IF EXISTS "Super admins can update all leads" ON public.leads;
DROP POLICY IF EXISTS "Super admins can delete leads" ON public.leads;
DROP POLICY IF EXISTS "Users can view leads based on role and team" ON public.leads;
DROP POLICY IF EXISTS "Users can update leads based on role and team" ON public.leads;
DROP POLICY IF EXISTS "Users can create leads based on permissions" ON public.leads;
DROP POLICY IF EXISTS "Users can delete leads based on permissions" ON public.leads;
DROP POLICY IF EXISTS "Users can insert leads in their organization" ON public.leads;
DROP POLICY IF EXISTS "Users can delete assigned leads" ON public.leads;

-- Recreate optimized policies
CREATE POLICY "Sales reps can view their own leads"
  ON public.leads FOR SELECT
  TO authenticated
  USING (current_lead_owner = (SELECT auth.uid()));

CREATE POLICY "Sales reps can update their own leads"
  ON public.leads FOR UPDATE
  TO authenticated
  USING (current_lead_owner = (SELECT auth.uid()));

CREATE POLICY "Team leads can view their team's leads"
  ON public.leads FOR SELECT
  TO authenticated
  USING (
    current_lead_owner IN (
      SELECT id FROM public.profiles
      WHERE team_id IN (
        SELECT team_id FROM public.profiles
        WHERE id = (SELECT auth.uid())
      )
    )
  );

CREATE POLICY "Team leads can update their team's leads"
  ON public.leads FOR UPDATE
  TO authenticated
  USING (
    current_lead_owner IN (
      SELECT id FROM public.profiles
      WHERE team_id IN (
        SELECT team_id FROM public.profiles
        WHERE id = (SELECT auth.uid())
      )
    )
  );

CREATE POLICY "Admins can view all leads in their organization"
  ON public.leads FOR SELECT
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

CREATE POLICY "Admins can update all leads in their organization"
  ON public.leads FOR UPDATE
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

CREATE POLICY "Admins can delete leads in their organization"
  ON public.leads FOR DELETE
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

CREATE POLICY "Super admins can view all leads"
  ON public.leads FOR SELECT
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM public.profiles p
      JOIN public.roles r ON p.role_id = r.id
      WHERE p.id = (SELECT auth.uid())
      AND r.hierarchy_level = 1
    )
  );

CREATE POLICY "Super admins can insert leads"
  ON public.leads FOR INSERT
  TO authenticated
  WITH CHECK (
    EXISTS (
      SELECT 1 FROM public.profiles p
      JOIN public.roles r ON p.role_id = r.id
      WHERE p.id = (SELECT auth.uid())
      AND r.hierarchy_level = 1
    )
  );

CREATE POLICY "Super admins can update all leads"
  ON public.leads FOR UPDATE
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM public.profiles p
      JOIN public.roles r ON p.role_id = r.id
      WHERE p.id = (SELECT auth.uid())
      AND r.hierarchy_level = 1
    )
  );

CREATE POLICY "Super admins can delete leads"
  ON public.leads FOR DELETE
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM public.profiles p
      JOIN public.roles r ON p.role_id = r.id
      WHERE p.id = (SELECT auth.uid())
      AND r.hierarchy_level = 1
    )
  );

CREATE POLICY "Users can insert leads in their organization"
  ON public.leads FOR INSERT
  TO authenticated
  WITH CHECK (
    organization_id IN (
      SELECT organization_id
      FROM public.organization_members
      WHERE profile_id = (SELECT auth.uid())
    )
  );