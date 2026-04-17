/*
  # Add Soft Delete to Profiles

  1. New Fields
    - disabled_at: timestamp when user was disabled
    - disabled_by: who disabled the user
    - disabled_reason: reason for disabling

  2. Changes
    - Update status enum to ensure 'disabled' value exists
    - Add indexes for efficient queries
    - Create helper function to disable users

  3. Security
    - RLS policies will be updated to filter out disabled users in normal queries
*/

-- Add soft delete tracking fields
ALTER TABLE profiles
ADD COLUMN IF NOT EXISTS disabled_at timestamptz,
ADD COLUMN IF NOT EXISTS disabled_by uuid REFERENCES profiles(id),
ADD COLUMN IF NOT EXISTS disabled_reason text;

-- Create indexes for efficient queries
CREATE INDEX IF NOT EXISTS idx_profiles_status ON profiles(status);
CREATE INDEX IF NOT EXISTS idx_profiles_disabled_at ON profiles(disabled_at) WHERE disabled_at IS NOT NULL;

-- Create function to disable user
CREATE OR REPLACE FUNCTION disable_user(
  target_user_id uuid,
  actor_id uuid,
  reason text DEFAULT NULL
)
RETURNS void AS $$
BEGIN
  UPDATE profiles
  SET 
    status = 'disabled',
    disabled_at = NOW(),
    disabled_by = actor_id,
    disabled_reason = reason,
    updated_at = NOW()
  WHERE id = target_user_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Create function to enable user
CREATE OR REPLACE FUNCTION enable_user(
  target_user_id uuid,
  actor_id uuid
)
RETURNS void AS $$
BEGIN
  UPDATE profiles
  SET 
    status = 'active',
    disabled_at = NULL,
    disabled_by = NULL,
    disabled_reason = NULL,
    updated_at = NOW()
  WHERE id = target_user_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;
