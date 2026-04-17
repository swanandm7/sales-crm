/*
  # Add Suspension Tracking to Organizations

  1. New Fields
    - suspended_at: timestamp when organization was suspended
    - suspended_by: who suspended the organization
    - suspension_reason: detailed reason for suspension

  2. Changes
    - Add indexes for efficient queries
    - Create helper functions for suspension management

  3. Notes
    - Organizations already have 'status' field with 'active' and 'suspended' values
    - This migration adds tracking fields for audit purposes
*/

-- Add suspension tracking fields
ALTER TABLE organizations
ADD COLUMN IF NOT EXISTS suspended_at timestamptz,
ADD COLUMN IF NOT EXISTS suspended_by uuid REFERENCES profiles(id),
ADD COLUMN IF NOT EXISTS suspension_reason text;

-- Create indexes for efficient queries
CREATE INDEX IF NOT EXISTS idx_organizations_status ON organizations(status);
CREATE INDEX IF NOT EXISTS idx_organizations_suspended_at ON organizations(suspended_at) WHERE suspended_at IS NOT NULL;

-- Create function to suspend organization
CREATE OR REPLACE FUNCTION suspend_organization(
  target_org_id uuid,
  actor_id uuid,
  reason text DEFAULT NULL
)
RETURNS void AS $$
BEGIN
  UPDATE organizations
  SET 
    status = 'suspended',
    suspended_at = NOW(),
    suspended_by = actor_id,
    suspension_reason = reason,
    updated_at = NOW()
  WHERE id = target_org_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Create function to activate organization
CREATE OR REPLACE FUNCTION activate_organization(
  target_org_id uuid,
  actor_id uuid
)
RETURNS void AS $$
BEGIN
  UPDATE organizations
  SET 
    status = 'active',
    suspended_at = NULL,
    suspended_by = NULL,
    suspension_reason = NULL,
    updated_at = NOW()
  WHERE id = target_org_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;
