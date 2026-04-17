/*
  # Fix RLS Performance - Leads and Organizations Tables
  
  Replace auth.uid() with (SELECT auth.uid()) to prevent re-evaluation per row
*/

-- LEADS TABLE: Fix auth.uid() performance
DROP POLICY IF EXISTS "Admins can view all leads in their organization" ON public.leads;
CREATE POLICY "Admins can view all leads in their organization"
  ON public.leads FOR SELECT
  TO authenticated
  USING (
    organization_id IN (
      SELECT organization_id
      FROM organization_members
      WHERE profile_id = (SELECT auth.uid())
    )
    AND get_my_role_hierarchy_from_jwt() <= 2
  );

DROP POLICY IF EXISTS "Admins can update all leads in their organization" ON public.leads;
CREATE POLICY "Admins can update all leads in their organization"
  ON public.leads FOR UPDATE
  TO authenticated
  USING (
    organization_id IN (
      SELECT organization_id
      FROM organization_members
      WHERE profile_id = (SELECT auth.uid())
    )
    AND get_my_role_hierarchy_from_jwt() <= 2
  );

DROP POLICY IF EXISTS "Admins can delete leads in their organization" ON public.leads;
CREATE POLICY "Admins can delete leads in their organization"
  ON public.leads FOR DELETE
  TO authenticated
  USING (
    organization_id IN (
      SELECT organization_id
      FROM organization_members
      WHERE profile_id = (SELECT auth.uid())
    )
    AND get_my_role_hierarchy_from_jwt() <= 2
  );

-- ORGANIZATIONS TABLE: Fix auth.uid() performance
DROP POLICY IF EXISTS "Admins can update their organization" ON public.organizations;
CREATE POLICY "Admins can update their organization"
  ON public.organizations FOR UPDATE
  TO authenticated
  USING (
    id IN (
      SELECT organization_id
      FROM organization_members
      WHERE profile_id = (SELECT auth.uid())
    )
    AND get_my_role_hierarchy_from_jwt() <= 2
  );
