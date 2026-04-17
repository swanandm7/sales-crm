/*
  # Replace ALL Profile-Role JOINs with JWT Function
  
  Root cause: Multiple tables have policies that JOIN profiles with roles
  This triggers infinite recursion when querying those tables
  
  Solution: Replace ALL instances of:
    EXISTS (SELECT 1 FROM profiles p JOIN roles r ON p.role_id = r.id WHERE p.id = auth.uid() AND r.hierarchy_level = X)
  
  With:
    get_my_role_hierarchy_from_jwt() = X (or <= X)
*/

-- FOLLOWUPS table
DROP POLICY IF EXISTS "Super admins can view all followups" ON public.followups;
CREATE POLICY "Super admins can view all followups"
  ON public.followups FOR SELECT
  TO authenticated
  USING (get_my_role_hierarchy_from_jwt() = 1);

-- LEADS table
DROP POLICY IF EXISTS "Super admins can delete leads" ON public.leads;
DROP POLICY IF EXISTS "Admins can view all leads in their organization" ON public.leads;
DROP POLICY IF EXISTS "Admins can update all leads in their organization" ON public.leads;
DROP POLICY IF EXISTS "Admins can delete leads in their organization" ON public.leads;
DROP POLICY IF EXISTS "Super admins can view all leads" ON public.leads;
DROP POLICY IF EXISTS "Super admins can update all leads" ON public.leads;

CREATE POLICY "Super admins can delete leads"
  ON public.leads FOR DELETE
  TO authenticated
  USING (get_my_role_hierarchy_from_jwt() = 1);

CREATE POLICY "Admins can view all leads in their organization"
  ON public.leads FOR SELECT
  TO authenticated
  USING (
    organization_id IN (
      SELECT organization_id
      FROM organization_members
      WHERE profile_id = auth.uid()
    )
    AND get_my_role_hierarchy_from_jwt() <= 2
  );

CREATE POLICY "Admins can update all leads in their organization"
  ON public.leads FOR UPDATE
  TO authenticated
  USING (
    organization_id IN (
      SELECT organization_id
      FROM organization_members
      WHERE profile_id = auth.uid()
    )
    AND get_my_role_hierarchy_from_jwt() <= 2
  );

CREATE POLICY "Admins can delete leads in their organization"
  ON public.leads FOR DELETE
  TO authenticated
  USING (
    organization_id IN (
      SELECT organization_id
      FROM organization_members
      WHERE profile_id = auth.uid()
    )
    AND get_my_role_hierarchy_from_jwt() <= 2
  );

CREATE POLICY "Super admins can view all leads"
  ON public.leads FOR SELECT
  TO authenticated
  USING (get_my_role_hierarchy_from_jwt() = 1);

CREATE POLICY "Super admins can update all leads"
  ON public.leads FOR UPDATE
  TO authenticated
  USING (get_my_role_hierarchy_from_jwt() = 1);

-- ORGANIZATION_MEMBERS table
DROP POLICY IF EXISTS "Admins can update organization members" ON public.organization_members;
DROP POLICY IF EXISTS "Admins can delete organization members" ON public.organization_members;
DROP POLICY IF EXISTS "Super admins can delete organization members" ON public.organization_members;
DROP POLICY IF EXISTS "Admins can view organization members" ON public.organization_members;
DROP POLICY IF EXISTS "Super admins can view all organization members" ON public.organization_members;

CREATE POLICY "Admins can update organization members"
  ON public.organization_members FOR UPDATE
  TO authenticated
  USING (
    organization_id IN (
      SELECT organization_id
      FROM organization_members
      WHERE profile_id = auth.uid()
    )
    AND get_my_role_hierarchy_from_jwt() <= 2
  );

CREATE POLICY "Admins can delete organization members"
  ON public.organization_members FOR DELETE
  TO authenticated
  USING (
    organization_id IN (
      SELECT organization_id
      FROM organization_members
      WHERE profile_id = auth.uid()
    )
    AND get_my_role_hierarchy_from_jwt() <= 2
  );

CREATE POLICY "Super admins can delete organization members"
  ON public.organization_members FOR DELETE
  TO authenticated
  USING (get_my_role_hierarchy_from_jwt() = 1);

CREATE POLICY "Admins can view organization members"
  ON public.organization_members FOR SELECT
  TO authenticated
  USING (
    organization_id IN (
      SELECT organization_id
      FROM organization_members
      WHERE profile_id = auth.uid()
    )
    AND get_my_role_hierarchy_from_jwt() <= 2
  );

CREATE POLICY "Super admins can view all organization members"
  ON public.organization_members FOR SELECT
  TO authenticated
  USING (get_my_role_hierarchy_from_jwt() = 1);

-- ORGANIZATIONS table
DROP POLICY IF EXISTS "Super admins can delete organizations" ON public.organizations;
DROP POLICY IF EXISTS "Admins can update their organization" ON public.organizations;
DROP POLICY IF EXISTS "Super admins can view all organizations" ON public.organizations;
DROP POLICY IF EXISTS "Super admins can update all organizations" ON public.organizations;

CREATE POLICY "Super admins can delete organizations"
  ON public.organizations FOR DELETE
  TO authenticated
  USING (get_my_role_hierarchy_from_jwt() = 1);

CREATE POLICY "Admins can update their organization"
  ON public.organizations FOR UPDATE
  TO authenticated
  USING (
    id IN (
      SELECT organization_id
      FROM organization_members
      WHERE profile_id = auth.uid()
    )
    AND get_my_role_hierarchy_from_jwt() <= 2
  );

CREATE POLICY "Super admins can view all organizations"
  ON public.organizations FOR SELECT
  TO authenticated
  USING (get_my_role_hierarchy_from_jwt() = 1);

CREATE POLICY "Super admins can update all organizations"
  ON public.organizations FOR UPDATE
  TO authenticated
  USING (get_my_role_hierarchy_from_jwt() = 1);
