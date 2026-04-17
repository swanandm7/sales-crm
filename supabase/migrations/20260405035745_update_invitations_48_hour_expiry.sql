/*
  # Update Invitations for 48-Hour Expiry and Enhanced Tracking

  1. Changes
    - Change default expiry from 7 days to 48 hours (2 days)
    - Add 'cancelled' to invitation_status enum
    - Add resend tracking fields
    - Add cancellation tracking fields

  2. New Fields
    - resend_count: tracks how many times invitation was resent
    - last_resent_at: timestamp of last resend
    - cancelled_at: timestamp when invitation was cancelled
    - cancelled_by: who cancelled the invitation

  3. Security
    - RLS policies remain unchanged
*/

-- Add 'cancelled' status to enum if not exists
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_enum 
    WHERE enumlabel = 'cancelled' 
    AND enumtypid = (SELECT oid FROM pg_type WHERE typname = 'invitation_status')
  ) THEN
    ALTER TYPE invitation_status ADD VALUE 'cancelled';
  END IF;
END $$;

-- Add new tracking fields
ALTER TABLE invitations
ADD COLUMN IF NOT EXISTS resend_count integer DEFAULT 0,
ADD COLUMN IF NOT EXISTS last_resent_at timestamptz,
ADD COLUMN IF NOT EXISTS cancelled_at timestamptz,
ADD COLUMN IF NOT EXISTS cancelled_by uuid REFERENCES profiles(id);

-- Update default expiry to 48 hours (2 days) for NEW invitations
ALTER TABLE invitations 
ALTER COLUMN expires_at SET DEFAULT (now() + interval '2 days');

-- Create index for efficient expiry checks
CREATE INDEX IF NOT EXISTS idx_invitations_expires_at ON invitations(expires_at);
CREATE INDEX IF NOT EXISTS idx_invitations_status ON invitations(status);

-- Create function to auto-expire invitations
CREATE OR REPLACE FUNCTION check_invitation_expiry()
RETURNS TRIGGER AS $$
BEGIN
  IF NEW.expires_at < NOW() AND NEW.status = 'pending' THEN
    NEW.status := 'expired';
  END IF;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Create trigger to check expiry on select
DROP TRIGGER IF EXISTS invitations_check_expiry ON invitations;
CREATE TRIGGER invitations_check_expiry
  BEFORE UPDATE ON invitations
  FOR EACH ROW
  EXECUTE FUNCTION check_invitation_expiry();
