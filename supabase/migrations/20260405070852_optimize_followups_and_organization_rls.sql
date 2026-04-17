/*
  # Optimize Followups and Organization RLS Policies

  1. Changes
    - Optimizes RLS policies for followups and organizations tables
    - Uses (SELECT auth.uid()) pattern for performance
*/

-- Followups policies
DROP POLICY IF EXISTS "Users can view own followups" ON public.followups;
DROP POLICY IF EXISTS "Users can create followups" ON public.followups;
DROP POLICY IF EXISTS "Users can update own followups" ON public.followups;
DROP POLICY IF EXISTS "Users can update their own followups" ON public.followups;
DROP POLICY IF EXISTS "Users can delete own followups" ON public.followups;
DROP POLICY IF EXISTS "Super admins can view all followups" ON public.followups;
DROP POLICY IF EXISTS "Users can view followups in their organization" ON public.followups;
DROP POLICY IF EXISTS "Users can manage their followups in their organization" ON public.followups;
DROP POLICY IF EXISTS "Users can create followups based on permissions" ON public.followups;
DROP POLICY IF EXISTS "Users can delete followups based on permissions" ON public.followups;
DROP POLICY IF EXISTS "Users can view followups based on role and team" ON public.followups;

CREATE POLICY "Users can view own followups"
  ON public.followups FOR SELECT
  TO authenticated
  USING (user_id = (SELECT auth.uid()));

CREATE POLICY "Users can create followups"
  ON public.followups FOR INSERT
  TO authenticated
  WITH CHECK (user_id = (SELECT auth.uid()));

CREATE POLICY "Users can update own followups"
  ON public.followups FOR UPDATE
  TO authenticated
  USING (user_id = (SELECT auth.uid()));

CREATE POLICY "Users can delete own followups"
  ON public.followups FOR DELETE
  TO authenticated
  USING (user_id = (SELECT auth.uid()));

CREATE POLICY "Super admins can view all followups"
  ON public.followups FOR SELECT
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM public.profiles p
      JOIN public.roles r ON p.role_id = r.id
      WHERE p.id = (SELECT auth.uid())
      AND r.hierarchy_level = 1
    )
  );

CREATE POLICY "Users can view followups in their organization"
  ON public.followups FOR SELECT
  TO authenticated
  USING (
    organization_id IN (
      SELECT organization_id
      FROM public.organization_members
      WHERE profile_id = (SELECT auth.uid())
    )
  );

-- Organizations policies
DROP POLICY IF EXISTS "Organization members can view their organization" ON public.organizations;
DROP POLICY IF EXISTS "Super admins can view all organizations" ON public.organizations;
DROP POLICY IF EXISTS "Super admins can create organizations" ON public.organizations;
DROP POLICY IF EXISTS "Super admins can update all organizations" ON public.organizations;
DROP POLICY IF EXISTS "Super admins can delete organizations" ON public.organizations;
DROP POLICY IF EXISTS "Admins can update their organization" ON public.organizations;

CREATE POLICY "Organization members can view their organization"
  ON public.organizations FOR SELECT
  TO authenticated
  USING (
    id IN (
      SELECT organization_id
      FROM public.organization_members
      WHERE profile_id = (SELECT auth.uid())
    )
  );

CREATE POLICY "Super admins can view all organizations"
  ON public.organizations FOR SELECT
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM public.profiles p
      JOIN public.roles r ON p.role_id = r.id
      WHERE p.id = (SELECT auth.uid())
      AND r.hierarchy_level = 1
    )
  );

CREATE POLICY "Super admins can create organizations"
  ON public.organizations FOR INSERT
  TO authenticated
  WITH CHECK (
    EXISTS (
      SELECT 1 FROM public.profiles p
      JOIN public.roles r ON p.role_id = r.id
      WHERE p.id = (SELECT auth.uid())
      AND r.hierarchy_level = 1
    )
  );

CREATE POLICY "Super admins can update all organizations"
  ON public.organizations FOR UPDATE
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM public.profiles p
      JOIN public.roles r ON p.role_id = r.id
      WHERE p.id = (SELECT auth.uid())
      AND r.hierarchy_level = 1
    )
  );

CREATE POLICY "Super admins can delete organizations"
  ON public.organizations FOR DELETE
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM public.profiles p
      JOIN public.roles r ON p.role_id = r.id
      WHERE p.id = (SELECT auth.uid())
      AND r.hierarchy_level = 1
    )
  );

CREATE POLICY "Admins can update their organization"
  ON public.organizations FOR UPDATE
  TO authenticated
  USING (
    id IN (
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

-- Organization members policies
DROP POLICY IF EXISTS "Users can view their own membership" ON public.organization_members;
DROP POLICY IF EXISTS "Admins can view organization members" ON public.organization_members;
DROP POLICY IF EXISTS "Super admins can view all organization members" ON public.organization_members;
DROP POLICY IF EXISTS "Super admins can insert organization members" ON public.organization_members;
DROP POLICY IF EXISTS "System can insert organization members during signup" ON public.organization_members;
DROP POLICY IF EXISTS "Admins can update organization members" ON public.organization_members;
DROP POLICY IF EXISTS "Admins can delete organization members" ON public.organization_members;
DROP POLICY IF EXISTS "Super admins can delete organization members" ON public.organization_members;

CREATE POLICY "Users can view their own membership"
  ON public.organization_members FOR SELECT
  TO authenticated
  USING (profile_id = (SELECT auth.uid()));

CREATE POLICY "Admins can view organization members"
  ON public.organization_members FOR SELECT
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

CREATE POLICY "Super admins can view all organization members"
  ON public.organization_members FOR SELECT
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM public.profiles p
      JOIN public.roles r ON p.role_id = r.id
      WHERE p.id = (SELECT auth.uid())
      AND r.hierarchy_level = 1
    )
  );

CREATE POLICY "Super admins can insert organization members"
  ON public.organization_members FOR INSERT
  TO authenticated
  WITH CHECK (
    EXISTS (
      SELECT 1 FROM public.profiles p
      JOIN public.roles r ON p.role_id = r.id
      WHERE p.id = (SELECT auth.uid())
      AND r.hierarchy_level = 1
    )
  );

CREATE POLICY "System can insert organization members during signup"
  ON public.organization_members FOR INSERT
  TO authenticated
  WITH CHECK (profile_id = (SELECT auth.uid()));

CREATE POLICY "Admins can update organization members"
  ON public.organization_members FOR UPDATE
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

CREATE POLICY "Admins can delete organization members"
  ON public.organization_members FOR DELETE
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

CREATE POLICY "Super admins can delete organization members"
  ON public.organization_members FOR DELETE
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM public.profiles p
      JOIN public.roles r ON p.role_id = r.id
      WHERE p.id = (SELECT auth.uid())
      AND r.hierarchy_level = 1
    )
  );