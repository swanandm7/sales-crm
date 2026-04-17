/*
  # Create Team-Based and Role-Based RLS Policies

  1. Updates to Leads Table Policies
    - Sales Representatives can only view/edit their own leads
    - Team Leads can view/edit their team's leads
    - Admins and Super Admins can view/edit all leads
    
  2. Updates to Follow-ups Table Policies
    - Similar hierarchy-based access control
    
  3. Helper Functions
    - Function to get user's hierarchy level
    - Function to check if user is team lead of another user
    - Function to check if user has specific permission
*/

-- Create helper function to get user's hierarchy level
CREATE OR REPLACE FUNCTION get_user_hierarchy_level(user_uuid uuid)
RETURNS integer
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  hierarchy_level integer;
BEGIN
  SELECT r.hierarchy_level INTO hierarchy_level
  FROM profiles p
  JOIN roles r ON p.role_id = r.id
  WHERE p.id = user_uuid;
  
  RETURN COALESCE(hierarchy_level, 4); -- Default to lowest level
END;
$$;

-- Create helper function to check if user is in same team
CREATE OR REPLACE FUNCTION is_same_team(user_uuid uuid, target_user_uuid uuid)
RETURNS boolean
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  same_team boolean;
BEGIN
  SELECT EXISTS (
    SELECT 1
    FROM profiles p1
    JOIN profiles p2 ON p1.team_id = p2.team_id
    WHERE p1.id = user_uuid
    AND p2.id = target_user_uuid
    AND p1.team_id IS NOT NULL
  ) INTO same_team;
  
  RETURN same_team;
END;
$$;

-- Create helper function to check if user is team lead of a team
CREATE OR REPLACE FUNCTION is_team_lead_of(user_uuid uuid, team_uuid uuid)
RETURNS boolean
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
  RETURN EXISTS (
    SELECT 1
    FROM teams
    WHERE id = team_uuid
    AND team_lead_id = user_uuid
  );
END;
$$;

-- Create helper function to check if user has a specific permission
CREATE OR REPLACE FUNCTION user_has_permission(user_uuid uuid, perm_key text)
RETURNS boolean
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
  RETURN EXISTS (
    SELECT 1
    FROM profiles p
    JOIN role_permissions rp ON p.role_id = rp.role_id
    JOIN permissions perm ON rp.permission_id = perm.id
    WHERE p.id = user_uuid
    AND perm.permission_key = perm_key
    AND p.is_active = true
  );
END;
$$;

-- Drop existing lead policies that conflict
DROP POLICY IF EXISTS "Users can view leads assigned to them" ON leads;
DROP POLICY IF EXISTS "Users can update leads assigned to them" ON leads;
DROP POLICY IF EXISTS "Users can create leads" ON leads;
DROP POLICY IF EXISTS "Users can delete leads assigned to them" ON leads;

-- Create new comprehensive lead policies
-- Sales Reps: View only their own leads
-- Team Leads: View their team's leads
-- Admins: View all leads
CREATE POLICY "Users can view leads based on role and team"
  ON leads FOR SELECT
  TO authenticated
  USING (
    -- Super Admin and Admin can view all
    get_user_hierarchy_level(auth.uid()) <= 2
    OR
    -- Team Lead can view their team's leads
    (
      get_user_hierarchy_level(auth.uid()) = 3
      AND (
        assigned_to = auth.uid()
        OR current_lead_owner = auth.uid()
        OR is_same_team(auth.uid(), COALESCE(current_lead_owner, assigned_to))
      )
    )
    OR
    -- Sales Rep can view only their own leads
    (
      get_user_hierarchy_level(auth.uid()) = 4
      AND (assigned_to = auth.uid() OR current_lead_owner = auth.uid())
    )
  );

CREATE POLICY "Users can create leads based on permissions"
  ON leads FOR INSERT
  TO authenticated
  WITH CHECK (
    user_has_permission(auth.uid(), 'leads.create')
  );

CREATE POLICY "Users can update leads based on role and team"
  ON leads FOR UPDATE
  TO authenticated
  USING (
    -- Admins can edit all
    (
      get_user_hierarchy_level(auth.uid()) <= 2
      AND user_has_permission(auth.uid(), 'leads.edit_all')
    )
    OR
    -- Team Leads can edit their team's leads
    (
      get_user_hierarchy_level(auth.uid()) = 3
      AND user_has_permission(auth.uid(), 'leads.edit_team')
      AND (
        assigned_to = auth.uid()
        OR current_lead_owner = auth.uid()
        OR is_same_team(auth.uid(), COALESCE(current_lead_owner, assigned_to))
      )
    )
    OR
    -- Sales Reps can edit only their own leads
    (
      get_user_hierarchy_level(auth.uid()) = 4
      AND user_has_permission(auth.uid(), 'leads.edit_own')
      AND (assigned_to = auth.uid() OR current_lead_owner = auth.uid())
    )
  );

CREATE POLICY "Users can delete leads based on permissions"
  ON leads FOR DELETE
  TO authenticated
  USING (
    user_has_permission(auth.uid(), 'leads.delete')
    AND get_user_hierarchy_level(auth.uid()) <= 2
  );

-- Update profiles table policies
DROP POLICY IF EXISTS "Users can view their own profile" ON profiles;
DROP POLICY IF EXISTS "Users can view all profiles" ON profiles;
DROP POLICY IF EXISTS "Users can update their own profile" ON profiles;

CREATE POLICY "Users can view profiles based on role"
  ON profiles FOR SELECT
  TO authenticated
  USING (
    -- Everyone can view their own profile
    id = auth.uid()
    OR
    -- Admins can view all profiles
    get_user_hierarchy_level(auth.uid()) <= 2
    OR
    -- Team Leads can view their team members
    (
      get_user_hierarchy_level(auth.uid()) = 3
      AND is_same_team(auth.uid(), id)
    )
  );

CREATE POLICY "Users can update profiles based on permissions"
  ON profiles FOR UPDATE
  TO authenticated
  USING (
    -- Users can update their own profile
    id = auth.uid()
    OR
    -- Admins can update any profile
    (
      get_user_hierarchy_level(auth.uid()) <= 2
      AND user_has_permission(auth.uid(), 'users.edit')
    )
  );

-- Update followups policies
DROP POLICY IF EXISTS "Users can view followups for their leads" ON followups;
DROP POLICY IF EXISTS "Users can create followups for their leads" ON followups;
DROP POLICY IF EXISTS "Users can update followups for their leads" ON followups;
DROP POLICY IF EXISTS "Users can delete followups for their leads" ON followups;

CREATE POLICY "Users can view followups based on role and team"
  ON followups FOR SELECT
  TO authenticated
  USING (
    -- Admins can view all
    get_user_hierarchy_level(auth.uid()) <= 2
    OR
    -- Team Leads can view their team's followups
    (
      get_user_hierarchy_level(auth.uid()) = 3
      AND (
        user_id = auth.uid()
        OR is_same_team(auth.uid(), user_id)
      )
    )
    OR
    -- Sales Reps can view their own followups
    (
      get_user_hierarchy_level(auth.uid()) = 4
      AND user_id = auth.uid()
    )
  );

CREATE POLICY "Users can create followups based on permissions"
  ON followups FOR INSERT
  TO authenticated
  WITH CHECK (
    user_has_permission(auth.uid(), 'followups.create')
    AND user_id = auth.uid()
  );

CREATE POLICY "Users can update their own followups"
  ON followups FOR UPDATE
  TO authenticated
  USING (
    user_has_permission(auth.uid(), 'followups.edit')
    AND (
      user_id = auth.uid()
      OR get_user_hierarchy_level(auth.uid()) <= 2
    )
  );

CREATE POLICY "Users can delete followups based on permissions"
  ON followups FOR DELETE
  TO authenticated
  USING (
    user_has_permission(auth.uid(), 'followups.delete')
    AND (
      user_id = auth.uid()
      OR get_user_hierarchy_level(auth.uid()) <= 2
    )
  );