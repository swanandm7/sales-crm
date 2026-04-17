/*
  # Simplify Profiles Policies - Emergency Fix
  
  The issue is that we're overthinking this. Most users just need to see their own profile.
  Super admin features can be handled differently.
  
  Strategy: Make basic policies work WITHOUT any complex queries
*/

-- Drop ALL existing policies on profiles
DROP POLICY IF EXISTS "Users can view their own profile" ON public.profiles;
DROP POLICY IF EXISTS "Users can insert own profile" ON public.profiles;
DROP POLICY IF EXISTS "Users can update own profile" ON public.profiles;
DROP POLICY IF EXISTS "Super admins can view all profiles" ON public.profiles;
DROP POLICY IF EXISTS "Super admins can insert profiles" ON public.profiles;
DROP POLICY IF EXISTS "Super admins can update all profiles" ON public.profiles;
DROP POLICY IF EXISTS "Only super admins can delete profiles" ON public.profiles;
DROP POLICY IF EXISTS "System can insert new profiles during signup" ON public.profiles;
DROP POLICY IF EXISTS "Users can view profiles in their organization" ON public.profiles;
DROP POLICY IF EXISTS "Admins can update profiles in their organization" ON public.profiles;

-- Create SIMPLE policies that don't cause recursion
-- These work for 99% of use cases

-- 1. Users can always see/update their own profile (no recursion)
CREATE POLICY "own_profile_select"
  ON public.profiles FOR SELECT
  TO authenticated
  USING (id = auth.uid());

CREATE POLICY "own_profile_update"
  ON public.profiles FOR UPDATE
  TO authenticated
  USING (id = auth.uid())
  WITH CHECK (id = auth.uid());

-- 2. Users can insert their own profile during signup (no recursion)
CREATE POLICY "own_profile_insert"
  ON public.profiles FOR INSERT
  TO authenticated
  WITH CHECK (id = auth.uid());

-- 3. Allow viewing profiles in the same organization (no recursion - doesn't query profiles)
CREATE POLICY "org_profiles_select"
  ON public.profiles FOR SELECT
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 
      FROM organization_members om1
      JOIN organization_members om2 ON om1.organization_id = om2.organization_id
      WHERE om1.profile_id = auth.uid()
      AND om2.profile_id = profiles.id
    )
  );

-- 4. For super admin access, we'll use a separate admin-only policy
-- This uses JWT metadata which doesn't query profiles table
CREATE POLICY "superadmin_all_access"
  ON public.profiles FOR ALL
  TO authenticated
  USING (
    (auth.jwt() -> 'app_metadata' ->> 'role_id')::uuid IN (
      SELECT id FROM roles WHERE hierarchy_level = 1
    )
  )
  WITH CHECK (
    (auth.jwt() -> 'app_metadata' ->> 'role_id')::uuid IN (
      SELECT id FROM roles WHERE hierarchy_level = 1
    )
  );
