/*
  # Fix Infinite Recursion by Using JWT Claims Instead of Database Queries

  1. Problem
    - SECURITY DEFINER functions still trigger RLS in Supabase
    - Any query to profiles from within profiles policies causes infinite recursion
    - Current helper function doesn't actually bypass RLS

  2. Solution
    - Store role hierarchy level in JWT claims (app_metadata)
    - Update profiles trigger to sync role info to auth.users metadata
    - Update policies to read from JWT instead of querying database
    - This completely eliminates the need to query profiles table

  3. Changes
    - Create trigger to sync role_id to user metadata
    - Drop all policies using get_my_role_hierarchy_level()
    - Recreate policies using auth.jwt() to read metadata
*/

-- First, create a function to sync role info to JWT metadata
CREATE OR REPLACE FUNCTION public.sync_user_role_to_jwt()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  -- Update the user's app_metadata with their role_id
  -- This will be included in their JWT on next login
  UPDATE auth.users
  SET raw_app_meta_data = 
    COALESCE(raw_app_meta_data, '{}'::jsonb) || 
    jsonb_build_object('role_id', NEW.role_id)
  WHERE id = NEW.id;
  
  RETURN NEW;
END;
$$;

-- Create trigger to auto-sync role changes
DROP TRIGGER IF EXISTS sync_role_to_jwt_trigger ON public.profiles;
CREATE TRIGGER sync_role_to_jwt_trigger
  AFTER INSERT OR UPDATE OF role_id ON public.profiles
  FOR EACH ROW
  EXECUTE FUNCTION public.sync_user_role_to_jwt();

-- Now update all existing users to have role_id in their JWT
DO $$
DECLARE
  profile_record RECORD;
BEGIN
  FOR profile_record IN SELECT id, role_id FROM public.profiles LOOP
    UPDATE auth.users
    SET raw_app_meta_data = 
      COALESCE(raw_app_meta_data, '{}'::jsonb) || 
      jsonb_build_object('role_id', profile_record.role_id)
    WHERE id = profile_record.id;
  END LOOP;
END $$;

-- Create a new helper function that reads from JWT and queries roles (NOT profiles)
-- This breaks the circular dependency because it doesn't touch profiles table
CREATE OR REPLACE FUNCTION public.get_my_role_hierarchy_from_jwt()
RETURNS integer
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = public
AS $$
  SELECT r.hierarchy_level
  FROM public.roles r
  WHERE r.id = (auth.jwt() -> 'app_metadata' ->> 'role_id')::uuid
$$;

-- Drop ALL existing profiles policies
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

-- Recreate profiles policies using JWT-based helper function
CREATE POLICY "Users can view their own profile"
  ON public.profiles FOR SELECT
  TO authenticated
  USING (id = auth.uid());

CREATE POLICY "Users can insert own profile"
  ON public.profiles FOR INSERT
  TO authenticated
  WITH CHECK (id = auth.uid());

CREATE POLICY "Users can update own profile"
  ON public.profiles FOR UPDATE
  TO authenticated
  USING (id = auth.uid())
  WITH CHECK (id = auth.uid());

CREATE POLICY "Super admins can view all profiles"
  ON public.profiles FOR SELECT
  TO authenticated
  USING (get_my_role_hierarchy_from_jwt() = 1);

CREATE POLICY "Super admins can insert profiles"
  ON public.profiles FOR INSERT
  TO authenticated
  WITH CHECK (get_my_role_hierarchy_from_jwt() = 1);

CREATE POLICY "Super admins can update all profiles"
  ON public.profiles FOR UPDATE
  TO authenticated
  USING (get_my_role_hierarchy_from_jwt() = 1);

CREATE POLICY "Only super admins can delete profiles"
  ON public.profiles FOR DELETE
  TO authenticated
  USING (get_my_role_hierarchy_from_jwt() = 1);

CREATE POLICY "System can insert new profiles during signup"
  ON public.profiles FOR INSERT
  TO authenticated
  WITH CHECK (id = auth.uid());

CREATE POLICY "Users can view profiles in their organization"
  ON public.profiles FOR SELECT
  TO authenticated
  USING (
    organization_id IN (
      SELECT organization_id
      FROM organization_members
      WHERE profile_id = auth.uid()
    )
  );

CREATE POLICY "Admins can update profiles in their organization"
  ON public.profiles FOR UPDATE
  TO authenticated
  USING (
    get_my_role_hierarchy_from_jwt() <= 2
    AND organization_id IN (
      SELECT organization_id
      FROM organization_members
      WHERE profile_id = auth.uid()
    )
  )
  WITH CHECK (
    get_my_role_hierarchy_from_jwt() <= 2
    AND organization_id IN (
      SELECT organization_id
      FROM organization_members
      WHERE profile_id = auth.uid()
    )
  );
