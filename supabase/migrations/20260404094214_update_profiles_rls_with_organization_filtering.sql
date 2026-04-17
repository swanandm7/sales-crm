/*
  # Update Profiles RLS Policies with Organization Filtering

  1. Changes
    - Drop all existing policies on profiles table
    - Create new policies that include organization filtering
    - Super admins can see all profiles across all organizations
    - Users can only see profiles within their organization

  2. Security
    - Strict organization-based data isolation
    - Role-based access control maintained
    - Users cannot access profiles from other organizations
*/

-- Drop existing policies on profiles
DROP POLICY IF EXISTS "Users can view all profiles" ON profiles;
DROP POLICY IF EXISTS "Admins can view all profiles" ON profiles;
DROP POLICY IF EXISTS "Super admins can view all profiles" ON profiles;
DROP POLICY IF EXISTS "Users can view their own profile" ON profiles;
DROP POLICY IF EXISTS "Users can update their own profile" ON profiles;
DROP POLICY IF EXISTS "Admins can update all profiles" ON profiles;
DROP POLICY IF EXISTS "Super admins can update all profiles" ON profiles;
DROP POLICY IF EXISTS "Only super admins can delete profiles" ON profiles;
DROP POLICY IF EXISTS "Admins can insert profiles" ON profiles;
DROP POLICY IF EXISTS "Super admins can insert profiles" ON profiles;
DROP POLICY IF EXISTS "System can insert new profiles" ON profiles;

-- Policy: Super admins can view all profiles across all organizations
CREATE POLICY "Super admins can view all profiles"
  ON profiles
  FOR SELECT
  TO authenticated
  USING (is_super_admin(auth.uid()));

-- Policy: Users can view profiles in their organization
CREATE POLICY "Users can view profiles in their organization"
  ON profiles
  FOR SELECT
  TO authenticated
  USING (
    organization_id = get_user_organization_id(auth.uid())
  );

-- Policy: Users can view their own profile
CREATE POLICY "Users can view their own profile"
  ON profiles
  FOR SELECT
  TO authenticated
  USING (id = auth.uid());

-- Policy: Super admins can insert profiles for any organization
CREATE POLICY "Super admins can insert profiles"
  ON profiles
  FOR INSERT
  TO authenticated
  WITH CHECK (is_super_admin(auth.uid()));

-- Policy: System can insert new profiles during signup (invitation acceptance)
CREATE POLICY "System can insert new profiles during signup"
  ON profiles
  FOR INSERT
  TO authenticated
  WITH CHECK (id = auth.uid());

-- Policy: Users can update their own profile
CREATE POLICY "Users can update their own profile"
  ON profiles
  FOR UPDATE
  TO authenticated
  USING (id = auth.uid())
  WITH CHECK (id = auth.uid());

-- Policy: Admins can update profiles in their organization
CREATE POLICY "Admins can update profiles in their organization"
  ON profiles
  FOR UPDATE
  TO authenticated
  USING (
    organization_id = get_user_organization_id(auth.uid())
    AND get_user_hierarchy_level(auth.uid()) <= 2
  );

-- Policy: Super admins can update all profiles
CREATE POLICY "Super admins can update all profiles"
  ON profiles
  FOR UPDATE
  TO authenticated
  USING (is_super_admin(auth.uid()));

-- Policy: Only super admins can delete profiles
CREATE POLICY "Only super admins can delete profiles"
  ON profiles
  FOR DELETE
  TO authenticated
  USING (is_super_admin(auth.uid()));