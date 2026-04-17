/*
  # Fix RLS Performance - Organization Members Table
  
  Replace auth.uid() with (SELECT auth.uid()) to prevent re-evaluation per row
*/

-- ORGANIZATION_MEMBERS TABLE: Fix auth.uid() performance
DROP POLICY IF EXISTS "Admins can view organization members" ON public.organization_members;
CREATE POLICY "Admins can view organization members"
  ON public.organization_members FOR SELECT
  TO authenticated
  USING (
    profile_id = (SELECT auth.uid())
    OR
    get_my_role_hierarchy_from_jwt() <= 2
  );

DROP POLICY IF EXISTS "Users can view their own membership" ON public.organization_members;
CREATE POLICY "Users can view their own membership"
  ON public.organization_members FOR SELECT
  TO authenticated
  USING (profile_id = (SELECT auth.uid()));

DROP POLICY IF EXISTS "System can insert organization members during signup" ON public.organization_members;
CREATE POLICY "System can insert organization members during signup"
  ON public.organization_members FOR INSERT
  TO authenticated
  WITH CHECK (profile_id = (SELECT auth.uid()));
