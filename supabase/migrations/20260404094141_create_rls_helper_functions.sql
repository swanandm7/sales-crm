/*
  # Create RLS Helper Functions for Organization Access

  1. Helper Functions
    - `get_user_organization_id(user_uuid)` - Returns the organization_id for a user
    - `is_super_admin(user_uuid)` - Checks if user is a super admin
    - `can_access_organization(user_uuid, org_uuid)` - Checks if user can access an organization

  2. Usage
    - These functions simplify RLS policies
    - Used throughout the system for organization-based access control
    - Super admins have global access, regular users limited to their organization

  3. Performance
    - Functions are marked STABLE for query optimization
    - Indexes on related tables ensure fast lookups
*/

-- Function to get user's organization ID
CREATE OR REPLACE FUNCTION get_user_organization_id(user_uuid uuid)
RETURNS uuid
LANGUAGE sql
STABLE
SECURITY DEFINER
AS $$
  SELECT organization_id
  FROM organization_members
  WHERE profile_id = user_uuid
  LIMIT 1;
$$;

-- Function to check if user is super admin
CREATE OR REPLACE FUNCTION is_super_admin(user_uuid uuid)
RETURNS boolean
LANGUAGE sql
STABLE
SECURITY DEFINER
AS $$
  SELECT EXISTS (
    SELECT 1
    FROM profiles p
    JOIN roles r ON r.id = p.role_id
    WHERE p.id = user_uuid
    AND r.hierarchy_level = 1
  );
$$;

-- Function to check if user can access an organization
CREATE OR REPLACE FUNCTION can_access_organization(user_uuid uuid, org_uuid uuid)
RETURNS boolean
LANGUAGE sql
STABLE
SECURITY DEFINER
AS $$
  SELECT (
    -- Super admin can access all organizations
    is_super_admin(user_uuid)
    OR
    -- User is a member of the organization
    EXISTS (
      SELECT 1
      FROM organization_members
      WHERE profile_id = user_uuid
      AND organization_id = org_uuid
    )
  );
$$;

-- Function to get user's role hierarchy level
CREATE OR REPLACE FUNCTION get_user_hierarchy_level(user_uuid uuid)
RETURNS integer
LANGUAGE sql
STABLE
SECURITY DEFINER
AS $$
  SELECT r.hierarchy_level
  FROM profiles p
  JOIN roles r ON r.id = p.role_id
  WHERE p.id = user_uuid
  LIMIT 1;
$$;

-- Function to check if organization is at user limit
CREATE OR REPLACE FUNCTION is_organization_at_limit(org_uuid uuid)
RETURNS boolean
LANGUAGE plpgsql
STABLE
SECURITY DEFINER
AS $$
DECLARE
  v_max_users integer;
  v_current_count integer;
  v_pending_count integer;
BEGIN
  -- Get max_users for the organization
  SELECT max_users INTO v_max_users
  FROM organizations
  WHERE id = org_uuid;
  
  -- If max_users is NULL, organization has unlimited users
  IF v_max_users IS NULL THEN
    RETURN false;
  END IF;
  
  -- Count active members
  SELECT COUNT(*) INTO v_current_count
  FROM organization_members om
  JOIN profiles p ON p.id = om.profile_id
  WHERE om.organization_id = org_uuid
  AND p.status = 'active';
  
  -- Count pending invitations
  SELECT COUNT(*) INTO v_pending_count
  FROM invitations
  WHERE organization_id = org_uuid
  AND status = 'pending'
  AND expires_at > now();
  
  -- Check if at or over limit
  RETURN (v_current_count + v_pending_count) >= v_max_users;
END;
$$;