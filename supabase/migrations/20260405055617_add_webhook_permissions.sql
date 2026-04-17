/*
  # Add Webhook Integration Permissions

  ## Purpose
  Adds webhook-related permissions to the system for controlling access
  to webhook configurations and integrations.

  ## New Permissions
  1. webhooks:view - View webhook configurations and logs
  2. webhooks:manage - Create, update, delete webhook configurations
  3. webhooks:test - Test webhook endpoints
  4. integrations:view - View integration endpoints
  5. integrations:manage - Create, update, delete integration endpoints

  ## Permission Assignments
  - Super Admin: All permissions
  - Admin: All permissions
  - Manager: View only
  - Counselor: No webhook permissions
*/

-- Insert webhook permissions
INSERT INTO permissions (module_name, action_name, permission_key, description)
VALUES 
  ('webhooks', 'view', 'webhooks:view', 'View webhook configurations, sources, and activity logs'),
  ('webhooks', 'manage', 'webhooks:manage', 'Create, update, and delete webhook configurations'),
  ('webhooks', 'test', 'webhooks:test', 'Send test webhooks to verify integrations'),
  ('integrations', 'view', 'integrations:view', 'View integration endpoints and subscriptions'),
  ('integrations', 'manage', 'integrations:manage', 'Create, update, and delete integration endpoints')
ON CONFLICT (permission_key) DO NOTHING;

-- Grant all webhook permissions to Super Admin role
INSERT INTO role_permissions (role_id, permission_id)
SELECT r.id, p.id
FROM roles r
CROSS JOIN permissions p
WHERE r.role_name = 'Super Admin'
  AND p.permission_key IN ('webhooks:view', 'webhooks:manage', 'webhooks:test', 'integrations:view', 'integrations:manage')
ON CONFLICT (role_id, permission_id) DO NOTHING;

-- Grant all webhook permissions to Admin role
INSERT INTO role_permissions (role_id, permission_id)
SELECT r.id, p.id
FROM roles r
CROSS JOIN permissions p
WHERE r.role_name = 'Admin'
  AND p.permission_key IN ('webhooks:view', 'webhooks:manage', 'webhooks:test', 'integrations:view', 'integrations:manage')
ON CONFLICT (role_id, permission_id) DO NOTHING;

-- Grant view-only webhook permissions to Manager role
INSERT INTO role_permissions (role_id, permission_id)
SELECT r.id, p.id
FROM roles r
CROSS JOIN permissions p
WHERE r.role_name = 'Manager'
  AND p.permission_key IN ('webhooks:view', 'integrations:view')
ON CONFLICT (role_id, permission_id) DO NOTHING;