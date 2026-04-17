/*
  # Fix Roles and Permissions Policies

  Roles, permissions, and role_permissions tables don't have organization_id
  So we just check hierarchy level from JWT
*/

-- Roles (no organization_id)
DROP POLICY IF EXISTS "Only admins can view roles" ON public.roles;
DROP POLICY IF EXISTS "Only admins can insert roles" ON public.roles;
DROP POLICY IF EXISTS "Only admins can update roles" ON public.roles;
DROP POLICY IF EXISTS "Only admins can delete roles" ON public.roles;

CREATE POLICY "Only admins can view roles"
  ON public.roles FOR SELECT
  TO authenticated
  USING (get_my_role_hierarchy_from_jwt() <= 2);

CREATE POLICY "Only admins can insert roles"
  ON public.roles FOR INSERT
  TO authenticated
  WITH CHECK (get_my_role_hierarchy_from_jwt() <= 2);

CREATE POLICY "Only admins can update roles"
  ON public.roles FOR UPDATE
  TO authenticated
  USING (get_my_role_hierarchy_from_jwt() <= 2);

CREATE POLICY "Only admins can delete roles"
  ON public.roles FOR DELETE
  TO authenticated
  USING (get_my_role_hierarchy_from_jwt() <= 2);

-- Permissions (no organization_id)
DROP POLICY IF EXISTS "Only super admins can modify permissions" ON public.permissions;
CREATE POLICY "Only super admins can modify permissions"
  ON public.permissions FOR ALL
  TO authenticated
  USING (get_my_role_hierarchy_from_jwt() = 1);

-- Role permissions (no organization_id)
DROP POLICY IF EXISTS "Only admins can modify role permissions" ON public.role_permissions;
CREATE POLICY "Only admins can modify role permissions"
  ON public.role_permissions FOR ALL
  TO authenticated
  USING (get_my_role_hierarchy_from_jwt() <= 2);
