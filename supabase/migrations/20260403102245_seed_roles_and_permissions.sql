/*
  # Seed Default Roles and Permissions

  1. Insert Default Roles
    - Super Admin (hierarchy level 1) - Full system access
    - Admin (hierarchy level 2) - Full operational access
    - Team Lead (hierarchy level 3) - Team management access
    - Sales Representative (hierarchy level 4) - Limited to own leads

  2. Insert All Permissions
    Organized by modules:
    - Leads: view_own, view_team, view_all, create, edit_own, edit_team, edit_all, delete, assign, export
    - Analytics: view_own, view_team, view_all, export_reports
    - Bulk Actions: upload, download, mass_update, delete
    - Settings: manage_statuses, manage_sources, manage_rules, manage_templates
    - Users: view, create, edit, delete, change_roles, manage_teams
    - Follow-ups: view_own, view_team, view_all, create, edit, delete
    - Templates: view, create, edit, delete, approve
    - Teams: view, create, edit, delete, manage_members

  3. Map Permissions to Roles
    - Create default role-permission mappings for each hierarchy level
*/

-- Insert default roles
INSERT INTO roles (role_name, hierarchy_level, is_active) VALUES
  ('Super Admin', 1, true),
  ('Admin', 2, true),
  ('Team Lead', 3, true),
  ('Sales Representative', 4, true)
ON CONFLICT (role_name) DO NOTHING;

-- Insert permissions for Leads module
INSERT INTO permissions (module_name, action_name, permission_key, description) VALUES
  ('Leads', 'view_own', 'leads.view_own', 'View own leads only'),
  ('Leads', 'view_team', 'leads.view_team', 'View team leads'),
  ('Leads', 'view_all', 'leads.view_all', 'View all leads in system'),
  ('Leads', 'create', 'leads.create', 'Create new leads'),
  ('Leads', 'edit_own', 'leads.edit_own', 'Edit own leads'),
  ('Leads', 'edit_team', 'leads.edit_team', 'Edit team leads'),
  ('Leads', 'edit_all', 'leads.edit_all', 'Edit all leads'),
  ('Leads', 'delete', 'leads.delete', 'Delete leads'),
  ('Leads', 'assign', 'leads.assign', 'Assign leads to users'),
  ('Leads', 'export', 'leads.export', 'Export lead data')
ON CONFLICT (permission_key) DO NOTHING;

-- Insert permissions for Analytics module
INSERT INTO permissions (module_name, action_name, permission_key, description) VALUES
  ('Analytics', 'view_own', 'analytics.view_own', 'View own analytics'),
  ('Analytics', 'view_team', 'analytics.view_team', 'View team analytics'),
  ('Analytics', 'view_all', 'analytics.view_all', 'View all analytics'),
  ('Analytics', 'export_reports', 'analytics.export_reports', 'Export analytics reports')
ON CONFLICT (permission_key) DO NOTHING;

-- Insert permissions for Bulk Actions module
INSERT INTO permissions (module_name, action_name, permission_key, description) VALUES
  ('Bulk Actions', 'upload', 'bulk_actions.upload', 'Bulk upload leads'),
  ('Bulk Actions', 'download', 'bulk_actions.download', 'Bulk download data'),
  ('Bulk Actions', 'mass_update', 'bulk_actions.mass_update', 'Mass update records'),
  ('Bulk Actions', 'delete', 'bulk_actions.delete', 'Bulk delete records')
ON CONFLICT (permission_key) DO NOTHING;

-- Insert permissions for Settings module
INSERT INTO permissions (module_name, action_name, permission_key, description) VALUES
  ('Settings', 'manage_statuses', 'settings.manage_statuses', 'Manage lead statuses'),
  ('Settings', 'manage_sources', 'settings.manage_sources', 'Manage lead sources'),
  ('Settings', 'manage_rules', 'settings.manage_rules', 'Manage assignment rules'),
  ('Settings', 'manage_templates', 'settings.manage_templates', 'Manage message templates'),
  ('Settings', 'view', 'settings.view', 'View settings')
ON CONFLICT (permission_key) DO NOTHING;

-- Insert permissions for Users module
INSERT INTO permissions (module_name, action_name, permission_key, description) VALUES
  ('Users', 'view', 'users.view', 'View user list'),
  ('Users', 'create', 'users.create', 'Create new users'),
  ('Users', 'edit', 'users.edit', 'Edit user details'),
  ('Users', 'delete', 'users.delete', 'Delete users'),
  ('Users', 'change_roles', 'users.change_roles', 'Change user roles'),
  ('Users', 'manage_teams', 'users.manage_teams', 'Manage user teams')
ON CONFLICT (permission_key) DO NOTHING;

-- Insert permissions for Follow-ups module
INSERT INTO permissions (module_name, action_name, permission_key, description) VALUES
  ('Follow-ups', 'view_own', 'followups.view_own', 'View own follow-ups'),
  ('Follow-ups', 'view_team', 'followups.view_team', 'View team follow-ups'),
  ('Follow-ups', 'view_all', 'followups.view_all', 'View all follow-ups'),
  ('Follow-ups', 'create', 'followups.create', 'Create follow-ups'),
  ('Follow-ups', 'edit', 'followups.edit', 'Edit follow-ups'),
  ('Follow-ups', 'delete', 'followups.delete', 'Delete follow-ups')
ON CONFLICT (permission_key) DO NOTHING;

-- Insert permissions for Templates module
INSERT INTO permissions (module_name, action_name, permission_key, description) VALUES
  ('Templates', 'view', 'templates.view', 'View templates'),
  ('Templates', 'create', 'templates.create', 'Create templates'),
  ('Templates', 'edit', 'templates.edit', 'Edit templates'),
  ('Templates', 'delete', 'templates.delete', 'Delete templates'),
  ('Templates', 'approve', 'templates.approve', 'Approve templates')
ON CONFLICT (permission_key) DO NOTHING;

-- Insert permissions for Teams module
INSERT INTO permissions (module_name, action_name, permission_key, description) VALUES
  ('Teams', 'view', 'teams.view', 'View teams'),
  ('Teams', 'create', 'teams.create', 'Create teams'),
  ('Teams', 'edit', 'teams.edit', 'Edit teams'),
  ('Teams', 'delete', 'teams.delete', 'Delete teams'),
  ('Teams', 'manage_members', 'teams.manage_members', 'Manage team members')
ON CONFLICT (permission_key) DO NOTHING;

-- Insert permissions for Admin Dashboard
INSERT INTO permissions (module_name, action_name, permission_key, description) VALUES
  ('Admin', 'access_dashboard', 'admin.access_dashboard', 'Access admin dashboard'),
  ('Admin', 'view_audit_log', 'admin.view_audit_log', 'View audit log')
ON CONFLICT (permission_key) DO NOTHING;

-- Now create role-permission mappings
-- Super Admin gets ALL permissions
INSERT INTO role_permissions (role_id, permission_id)
SELECT r.id, p.id
FROM roles r
CROSS JOIN permissions p
WHERE r.role_name = 'Super Admin'
ON CONFLICT (role_id, permission_id) DO NOTHING;

-- Admin gets all permissions except super admin specific ones
INSERT INTO role_permissions (role_id, permission_id)
SELECT r.id, p.id
FROM roles r
CROSS JOIN permissions p
WHERE r.role_name = 'Admin'
ON CONFLICT (role_id, permission_id) DO NOTHING;

-- Team Lead permissions
INSERT INTO role_permissions (role_id, permission_id)
SELECT r.id, p.id
FROM roles r
CROSS JOIN permissions p
WHERE r.role_name = 'Team Lead'
AND p.permission_key IN (
  'leads.view_team', 'leads.view_own', 'leads.create', 'leads.edit_team', 'leads.edit_own', 'leads.assign', 'leads.export',
  'analytics.view_team', 'analytics.view_own', 'analytics.export_reports',
  'followups.view_team', 'followups.view_own', 'followups.create', 'followups.edit',
  'templates.view', 'templates.create',
  'teams.view',
  'settings.view'
)
ON CONFLICT (role_id, permission_id) DO NOTHING;

-- Sales Representative permissions (most limited)
INSERT INTO role_permissions (role_id, permission_id)
SELECT r.id, p.id
FROM roles r
CROSS JOIN permissions p
WHERE r.role_name = 'Sales Representative'
AND p.permission_key IN (
  'leads.view_own', 'leads.create', 'leads.edit_own', 'leads.export',
  'analytics.view_own',
  'followups.view_own', 'followups.create', 'followups.edit',
  'templates.view',
  'settings.view'
)
ON CONFLICT (role_id, permission_id) DO NOTHING;