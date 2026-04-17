/*
  # Fix Profile Creation Trigger and Orphaned Users

  1. Changes
    - Create automatic profile creation trigger for new auth.users
    - Fix existing orphaned user (Pratik Singh) by creating their profile
    - Ensure all future signups automatically create profiles

  2. Security
    - Trigger runs with security definer to bypass RLS
    - Only creates profiles for new users, doesn't modify existing ones
*/

-- Create function to automatically create profile when user signs up
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS TRIGGER
SECURITY DEFINER
SET search_path = public
LANGUAGE plpgsql
AS $$
DECLARE
  default_org_id uuid;
BEGIN
  -- Get the first organization (fallback for users without specific org)
  SELECT id INTO default_org_id
  FROM organizations
  ORDER BY created_at ASC
  LIMIT 1;

  -- Create profile for new user
  INSERT INTO public.profiles (
    id,
    email,
    full_name,
    first_name,
    last_name,
    organization_id,
    status
  )
  VALUES (
    NEW.id,
    NEW.email,
    COALESCE(
      TRIM(CONCAT(
        COALESCE(NEW.raw_user_meta_data->>'first_name', ''),
        ' ',
        COALESCE(NEW.raw_user_meta_data->>'last_name', '')
      )),
      NEW.email
    ),
    NEW.raw_user_meta_data->>'first_name',
    NEW.raw_user_meta_data->>'last_name',
    default_org_id,
    'pending'
  );

  RETURN NEW;
END;
$$;

-- Create trigger on auth.users table
DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;

CREATE TRIGGER on_auth_user_created
  AFTER INSERT ON auth.users
  FOR EACH ROW
  EXECUTE FUNCTION public.handle_new_user();

-- Fix the existing orphaned user (Pratik Singh)
DO $$
DECLARE
  default_org_id uuid;
  orphaned_user_id uuid := 'c0a25393-1168-4246-a662-2f790f269d13';
  user_exists boolean;
BEGIN
  -- Check if this user exists in auth.users
  SELECT EXISTS (
    SELECT 1 FROM auth.users WHERE id = orphaned_user_id
  ) INTO user_exists;

  IF user_exists THEN
    -- Get the first organization
    SELECT id INTO default_org_id
    FROM organizations
    ORDER BY created_at ASC
    LIMIT 1;

    -- Create profile if it doesn't exist
    INSERT INTO public.profiles (
      id,
      email,
      full_name,
      first_name,
      last_name,
      organization_id,
      status
    )
    SELECT
      u.id,
      u.email,
      TRIM(CONCAT(
        COALESCE(u.raw_user_meta_data->>'first_name', ''),
        ' ',
        COALESCE(u.raw_user_meta_data->>'last_name', '')
      )),
      u.raw_user_meta_data->>'first_name',
      u.raw_user_meta_data->>'last_name',
      default_org_id,
      'pending'
    FROM auth.users u
    WHERE u.id = orphaned_user_id
    ON CONFLICT (id) DO NOTHING;
  END IF;
END;
$$;
