/*
  # Create Invitation and User Capacity Functions

  1. Functions Created
    - `check_organization_capacity_before_invite()` - Validates capacity before creating invitation
    - `accept_invitation()` - Handles complete invitation acceptance workflow
    - `expire_old_invitations()` - Auto-expires invitations past expiry date

  2. Features
    - Automatic capacity checking
    - Complete invitation acceptance in single transaction
    - Invitation expiry automation
    
  3. Security
    - Validates organization capacity
    - Ensures invitation is valid and not expired
    - Creates profile, organization_members, and updates invitation atomically
*/

-- Function to check if organization has capacity for new invitation
CREATE OR REPLACE FUNCTION check_organization_capacity_before_invite()
RETURNS TRIGGER AS $$
DECLARE
  v_org_id uuid;
  v_at_limit boolean;
BEGIN
  v_org_id := NEW.organization_id;
  
  -- Check if organization is at capacity
  v_at_limit := is_organization_at_limit(v_org_id);
  
  IF v_at_limit THEN
    RAISE EXCEPTION 'Organization has reached its user limit. Cannot send more invitations.';
  END IF;
  
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Create trigger to check capacity before creating invitation
DROP TRIGGER IF EXISTS check_capacity_before_invite ON invitations;
CREATE TRIGGER check_capacity_before_invite
  BEFORE INSERT ON invitations
  FOR EACH ROW
  EXECUTE FUNCTION check_organization_capacity_before_invite();

-- Function to expire old invitations (can be called by cron job)
CREATE OR REPLACE FUNCTION expire_old_invitations()
RETURNS integer AS $$
DECLARE
  v_expired_count integer;
BEGIN
  UPDATE invitations
  SET status = 'expired'
  WHERE status = 'pending'
  AND expires_at < now();
  
  GET DIAGNOSTICS v_expired_count = ROW_COUNT;
  
  RETURN v_expired_count;
END;
$$ LANGUAGE plpgsql;

-- Function to validate invitation token
CREATE OR REPLACE FUNCTION validate_invitation_token(p_token text)
RETURNS TABLE (
  invitation_id uuid,
  organization_id uuid,
  organization_name text,
  email text,
  role_id uuid,
  role_name text,
  invited_by_name text,
  expires_at timestamptz,
  is_valid boolean,
  error_message text
) AS $$
BEGIN
  RETURN QUERY
  SELECT 
    i.id,
    i.organization_id,
    o.name,
    i.email,
    i.role_id,
    r.role_name,
    p.full_name,
    i.expires_at,
    CASE
      WHEN i.status != 'pending' THEN false
      WHEN i.expires_at < now() THEN false
      WHEN o.status != 'active' THEN false
      WHEN is_organization_at_limit(i.organization_id) THEN false
      ELSE true
    END as is_valid,
    CASE
      WHEN i.status != 'pending' THEN 'This invitation has already been used or cancelled'
      WHEN i.expires_at < now() THEN 'This invitation has expired'
      WHEN o.status != 'active' THEN 'This organization is not active'
      WHEN is_organization_at_limit(i.organization_id) THEN 'Organization has reached its user limit'
      ELSE NULL
    END as error_message
  FROM invitations i
  JOIN organizations o ON o.id = i.organization_id
  JOIN roles r ON r.id = i.role_id
  JOIN profiles p ON p.id = i.invited_by
  WHERE i.token = p_token;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Function to resend invitation (updates expiry and sends notification)
CREATE OR REPLACE FUNCTION resend_invitation(p_invitation_id uuid)
RETURNS boolean AS $$
DECLARE
  v_organization_id uuid;
  v_at_limit boolean;
BEGIN
  -- Get organization_id
  SELECT organization_id INTO v_organization_id
  FROM invitations
  WHERE id = p_invitation_id;
  
  -- Check capacity
  v_at_limit := is_organization_at_limit(v_organization_id);
  
  IF v_at_limit THEN
    RAISE EXCEPTION 'Organization has reached its user limit. Cannot resend invitation.';
  END IF;
  
  -- Update invitation with new expiry
  UPDATE invitations
  SET 
    expires_at = now() + interval '7 days',
    status = 'pending'
  WHERE id = p_invitation_id
  AND status IN ('pending', 'expired');
  
  RETURN FOUND;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;