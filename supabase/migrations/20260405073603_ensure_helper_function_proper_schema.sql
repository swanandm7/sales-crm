/*
  # Ensure Helper Function Uses Proper Schema Path

  1. Changes
    - Recreate get_my_role_hierarchy_level with explicit schema in query
    - This ensures it always uses public schema even when search_path changes

  2. Security
    - Maintains SECURITY DEFINER to bypass RLS
    - Uses explicit schema qualification for safety
*/

CREATE OR REPLACE FUNCTION public.get_my_role_hierarchy_level()
RETURNS integer
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = public
AS $$
  SELECT r.hierarchy_level
  FROM public.profiles p
  JOIN public.roles r ON p.role_id = r.id
  WHERE p.id = auth.uid()
$$;
