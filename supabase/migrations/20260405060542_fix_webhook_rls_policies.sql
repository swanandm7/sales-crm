/*
  # Fix Webhook RLS Policies

  ## Issue
  The webhook configuration RLS policies were checking only for 'settings:manage' permission,
  but the new webhook-specific permissions were added later. This causes INSERT failures
  even for admins with 'webhooks:manage' permission.

  ## Solution
  Update all webhook-related RLS policies to accept either 'settings:manage' OR the
  new webhook-specific permissions ('webhooks:manage', 'integrations:manage').

  ## Changes
  - Update webhook_configurations INSERT, UPDATE, DELETE policies
  - Update webhook_sources policies
  - Update integration_endpoints policies
  - Update webhook_event_subscriptions policies
  - Update api_keys policies
*/

-- Drop existing policies for webhook_configurations
DROP POLICY IF EXISTS "Admins can insert webhook configs" ON webhook_configurations;
DROP POLICY IF EXISTS "Admins can update webhook configs" ON webhook_configurations;
DROP POLICY IF EXISTS "Admins can delete webhook configs" ON webhook_configurations;

-- Create new policies with webhook-specific permissions
CREATE POLICY "Admins can insert webhook configs"
  ON webhook_configurations FOR INSERT
  TO authenticated
  WITH CHECK (
    can_access_organization(auth.uid(), organization_id) AND
    EXISTS (
      SELECT 1 FROM profiles p
      JOIN role_permissions rp ON p.role_id = rp.role_id
      JOIN permissions perm ON rp.permission_id = perm.id
      WHERE p.id = auth.uid() 
      AND perm.permission_key IN ('settings:manage', 'webhooks:manage')
    )
  );

CREATE POLICY "Admins can update webhook configs"
  ON webhook_configurations FOR UPDATE
  TO authenticated
  USING (
    can_access_organization(auth.uid(), organization_id) AND
    EXISTS (
      SELECT 1 FROM profiles p
      JOIN role_permissions rp ON p.role_id = rp.role_id
      JOIN permissions perm ON rp.permission_id = perm.id
      WHERE p.id = auth.uid() 
      AND perm.permission_key IN ('settings:manage', 'webhooks:manage')
    )
  );

CREATE POLICY "Admins can delete webhook configs"
  ON webhook_configurations FOR DELETE
  TO authenticated
  USING (
    can_access_organization(auth.uid(), organization_id) AND
    EXISTS (
      SELECT 1 FROM profiles p
      JOIN role_permissions rp ON p.role_id = rp.role_id
      JOIN permissions perm ON rp.permission_id = perm.id
      WHERE p.id = auth.uid() 
      AND perm.permission_key IN ('settings:manage', 'webhooks:manage')
    )
  );

-- Drop and recreate webhook_sources policies
DROP POLICY IF EXISTS "Admins can manage webhook sources" ON webhook_sources;

CREATE POLICY "Admins can manage webhook sources"
  ON webhook_sources FOR ALL
  TO authenticated
  USING (
    can_access_organization(auth.uid(), organization_id) AND
    EXISTS (
      SELECT 1 FROM profiles p
      JOIN role_permissions rp ON p.role_id = rp.role_id
      JOIN permissions perm ON rp.permission_id = perm.id
      WHERE p.id = auth.uid() 
      AND perm.permission_key IN ('settings:manage', 'webhooks:manage')
    )
  );

-- Drop and recreate integration_endpoints policies
DROP POLICY IF EXISTS "Admins can manage integration endpoints" ON integration_endpoints;

CREATE POLICY "Admins can manage integration endpoints"
  ON integration_endpoints FOR ALL
  TO authenticated
  USING (
    can_access_organization(auth.uid(), organization_id) AND
    EXISTS (
      SELECT 1 FROM profiles p
      JOIN role_permissions rp ON p.role_id = rp.role_id
      JOIN permissions perm ON rp.permission_id = perm.id
      WHERE p.id = auth.uid() 
      AND perm.permission_key IN ('settings:manage', 'integrations:manage', 'webhooks:manage')
    )
  );

-- Drop and recreate webhook_event_subscriptions policies
DROP POLICY IF EXISTS "Admins can manage event subscriptions" ON webhook_event_subscriptions;

CREATE POLICY "Admins can manage event subscriptions"
  ON webhook_event_subscriptions FOR ALL
  TO authenticated
  USING (
    can_access_organization(auth.uid(), organization_id) AND
    EXISTS (
      SELECT 1 FROM profiles p
      JOIN role_permissions rp ON p.role_id = rp.role_id
      JOIN permissions perm ON rp.permission_id = perm.id
      WHERE p.id = auth.uid() 
      AND perm.permission_key IN ('settings:manage', 'integrations:manage', 'webhooks:manage')
    )
  );

-- Drop and recreate api_keys policies
DROP POLICY IF EXISTS "Admins can manage API keys" ON api_keys;

CREATE POLICY "Admins can manage API keys"
  ON api_keys FOR ALL
  TO authenticated
  USING (
    can_access_organization(auth.uid(), organization_id) AND
    EXISTS (
      SELECT 1 FROM profiles p
      JOIN role_permissions rp ON p.role_id = rp.role_id
      JOIN permissions perm ON rp.permission_id = perm.id
      WHERE p.id = auth.uid() 
      AND perm.permission_key IN ('settings:manage', 'webhooks:manage')
    )
  );