/*
  # Fix Final Profile-Role Joins
  
  Fix remaining INSERT policies on leads and organizations tables
*/

-- LEADS
DROP POLICY IF EXISTS "Super admins can insert leads" ON public.leads;
CREATE POLICY "Super admins can insert leads"
  ON public.leads FOR INSERT
  TO authenticated
  WITH CHECK (get_my_role_hierarchy_from_jwt() = 1);

-- ORGANIZATIONS
DROP POLICY IF EXISTS "Super admins can create organizations" ON public.organizations;
CREATE POLICY "Super admins can create organizations"
  ON public.organizations FOR INSERT
  TO authenticated
  WITH CHECK (get_my_role_hierarchy_from_jwt() = 1);
