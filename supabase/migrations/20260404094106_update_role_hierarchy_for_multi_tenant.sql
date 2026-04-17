/*
  # Update Role Hierarchy for Multi-Tenant Model

  1. Changes
    - Add `is_global` flag to roles table (true only for super_admin)
    - Add new organization-scoped permissions
    - Maintain existing 4 roles with clarified scope

  2. New Permissions
    - organizations.create (super admin only)
    - organizations.edit (super admin for all, admin for own org)
    - organizations.view_all (super admin only)
    - organizations.manage_members (admin and above)
    - invitations.send (admin and above)
    - invitations.manage (admin and above)
    - invitations.resend (admin and above)
    - invitations.cancel (admin and above)

  3. Notes
    - super_admin: Global access across all organizations
    - admin: Full access within their organization only
    - team_lead: Team management within their organization
    - sales_rep: Limited access to own data within their organization
*/

-- Add is_global flag to roles table
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns
    WHERE table_name = 'roles' AND column_name = 'is_global'
  ) THEN
    ALTER TABLE roles ADD COLUMN is_global boolean NOT NULL DEFAULT false;
  END IF;
END $$;

-- Set is_global = true for super_admin role
UPDATE roles SET is_global = true WHERE hierarchy_level = 1;

-- Create index on is_global
CREATE INDEX IF NOT EXISTS idx_roles_is_global ON roles(is_global);

-- Insert new organization-scoped permissions
INSERT INTO permissions (module_name, action_name, permission_key, description)
VALUES
  ('organizations', 'create', 'organizations.create', 'Create new organizations'),
  ('organizations', 'edit', 'organizations.edit', 'Edit organization settings'),
  ('organizations', 'view_all', 'organizations.view_all', 'View all organizations (super admin only)'),
  ('organizations', 'manage_members', 'organizations.manage_members', 'Manage organization members'),
  ('invitations', 'send', 'invitations.send', 'Send invitations to join organization'),
  ('invitations', 'manage', 'invitations.manage', 'Manage all invitations'),
  ('invitations', 'resend', 'invitations.resend', 'Resend invitation emails'),
  ('invitations', 'cancel', 'invitations.cancel', 'Cancel pending invitations')
ON CONFLICT (permission_key) DO NOTHING;

-- Assign organization permissions to roles
DO $$
DECLARE
  v_super_admin_id uuid;
  v_admin_id uuid;
  v_team_lead_id uuid;
  v_sales_rep_id uuid;
BEGIN
  -- Get role IDs
  SELECT id INTO v_super_admin_id FROM roles WHERE hierarchy_level = 1 LIMIT 1;
  SELECT id INTO v_admin_id FROM roles WHERE hierarchy_level = 2 LIMIT 1;
  SELECT id INTO v_team_lead_id FROM roles WHERE hierarchy_level = 3 LIMIT 1;
  SELECT id INTO v_sales_rep_id FROM roles WHERE hierarchy_level = 4 LIMIT 1;
  
  -- Super Admin gets all organization permissions
  INSERT INTO role_permissions (role_id, permission_id)
  SELECT v_super_admin_id, id FROM permissions 
  WHERE permission_key IN (
    'organizations.create',
    'organizations.edit',
    'organizations.view_all',
    'organizations.manage_members',
    'invitations.send',
    'invitations.manage',
    'invitations.resend',
    'invitations.cancel'
  )
  ON CONFLICT DO NOTHING;
  
  -- Admin gets organization management within their org
  INSERT INTO role_permissions (role_id, permission_id)
  SELECT v_admin_id, id FROM permissions 
  WHERE permission_key IN (
    'organizations.edit',
    'organizations.manage_members',
    'invitations.send',
    'invitations.manage',
    'invitations.resend',
    'invitations.cancel'
  )
  ON CONFLICT DO NOTHING;
  
  -- Team Lead gets limited invitation permissions (can be toggled in org settings)
  -- For now, no invitation permissions for team leads
  
  -- Sales Rep has no organization management permissions
  
END $$;