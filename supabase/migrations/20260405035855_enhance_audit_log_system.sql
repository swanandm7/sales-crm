/*
  # Enhance Audit Log System

  1. Changes
    - Rename user_id to actor_user_id for clarity
    - Add target_organization_id for org-level actions
    - Add notes field for admin comments
    - Expand action_type to include new events
    - Add indexes for efficient queries

  2. New Action Types
    - user_invited
    - invite_accepted
    - invite_resent
    - invite_cancelled
    - user_disabled
    - user_enabled
    - organization_created
    - organization_updated
    - organization_suspended
    - organization_activated

  3. Security
    - RLS policies remain restrictive
*/

-- Rename user_id to actor_user_id
DO $$
BEGIN
  IF EXISTS (
    SELECT 1 FROM information_schema.columns 
    WHERE table_name = 'audit_log' AND column_name = 'user_id'
  ) THEN
    ALTER TABLE audit_log RENAME COLUMN user_id TO actor_user_id;
  END IF;
END $$;

-- Add new fields
ALTER TABLE audit_log
ADD COLUMN IF NOT EXISTS target_organization_id uuid REFERENCES organizations(id),
ADD COLUMN IF NOT EXISTS notes text,
ADD COLUMN IF NOT EXISTS ip_address text,
ADD COLUMN IF NOT EXISTS user_agent text;

-- Create indexes for efficient queries
CREATE INDEX IF NOT EXISTS idx_audit_log_actor ON audit_log(actor_user_id);
CREATE INDEX IF NOT EXISTS idx_audit_log_target_user ON audit_log(target_user_id);
CREATE INDEX IF NOT EXISTS idx_audit_log_target_org ON audit_log(target_organization_id);
CREATE INDEX IF NOT EXISTS idx_audit_log_action_type ON audit_log(action_type);
CREATE INDEX IF NOT EXISTS idx_audit_log_created_at ON audit_log(created_at DESC);

-- Create helper function to log audit events
CREATE OR REPLACE FUNCTION log_audit_event(
  p_actor_user_id uuid,
  p_action_type text,
  p_target_user_id uuid DEFAULT NULL,
  p_target_organization_id uuid DEFAULT NULL,
  p_old_value text DEFAULT NULL,
  p_new_value text DEFAULT NULL,
  p_metadata jsonb DEFAULT NULL,
  p_notes text DEFAULT NULL
)
RETURNS uuid AS $$
DECLARE
  v_audit_id uuid;
BEGIN
  INSERT INTO audit_log (
    actor_user_id,
    action_type,
    target_user_id,
    target_organization_id,
    old_value,
    new_value,
    metadata,
    notes
  ) VALUES (
    p_actor_user_id,
    p_action_type,
    p_target_user_id,
    p_target_organization_id,
    p_old_value,
    p_new_value,
    COALESCE(p_metadata, '{}'::jsonb),
    p_notes
  )
  RETURNING id INTO v_audit_id;
  
  RETURN v_audit_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Update existing foreign key constraints
ALTER TABLE audit_log
DROP CONSTRAINT IF EXISTS audit_log_user_id_fkey;

ALTER TABLE audit_log
ADD CONSTRAINT audit_log_actor_user_id_fkey 
FOREIGN KEY (actor_user_id) REFERENCES profiles(id);
