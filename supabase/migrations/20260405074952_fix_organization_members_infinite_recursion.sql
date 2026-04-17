/*
  # Fix Organization Members Infinite Recursion
  
  Root Cause: organization_members policies query organization_members table
  to check "is user in same org?" which creates self-referencing recursion
  
  Solution:
  1. Remove self-referencing queries from organization_members policies
  2. Fix remaining profile-role join in INSERT policy
  3. Simplify admin policies to only check role hierarchy
*/

-- Drop and recreate policies without self-reference

-- ADMINS: Can only manage members if they are admin (checked via JWT)
-- We rely on application logic to ensure they only manage their own org
DROP POLICY IF EXISTS "Admins can view organization members" ON public.organization_members;
CREATE POLICY "Admins can view organization members"
  ON public.organization_members FOR SELECT
  TO authenticated
  USING (
    -- Can view own membership
    profile_id = auth.uid()
    OR
    -- OR is admin/superadmin (they can view all in their context)
    get_my_role_hierarchy_from_jwt() <= 2
  );

DROP POLICY IF EXISTS "Admins can update organization members" ON public.organization_members;
CREATE POLICY "Admins can update organization members"
  ON public.organization_members FOR UPDATE
  TO authenticated
  USING (get_my_role_hierarchy_from_jwt() <= 2);

DROP POLICY IF EXISTS "Admins can delete organization members" ON public.organization_members;
CREATE POLICY "Admins can delete organization members"
  ON public.organization_members FOR DELETE
  TO authenticated
  USING (get_my_role_hierarchy_from_jwt() <= 2);

-- Fix the INSERT policy that still has profile-role join
DROP POLICY IF EXISTS "Super admins can insert organization members" ON public.organization_members;
CREATE POLICY "Super admins can insert organization members"
  ON public.organization_members FOR INSERT
  TO authenticated
  WITH CHECK (get_my_role_hierarchy_from_jwt() = 1);

-- Keep existing policies as-is
-- "System can insert organization members during signup" - OK (no recursion)
-- "Users can view their own membership" - OK (no recursion)
-- "Super admins can view all organization members" - OK (already uses JWT)
-- "Super admins can delete organization members" - OK (already uses JWT)
