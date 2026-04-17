/*
  # Fix Organization Capacity Function

  1. Changes
    - Replace deleted_at check with disabled_at (correct column name)
    - Also check status column to ensure user is active
    
  2. Security
    - Returns capacity for the current user's organization
    - No RLS needed as function checks auth.uid()
*/

-- Update the function to use correct column names
CREATE OR REPLACE FUNCTION get_organization_capacity()
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_organization_id uuid;
  v_max_users int;
  v_current_active_users int;
  v_pending_invitations int;
  v_total_users int;
  v_remaining_slots int;
  v_can_invite boolean;
BEGIN
  -- Get the current user's organization
  SELECT organization_id INTO v_organization_id
  FROM profiles
  WHERE id = auth.uid();

  IF v_organization_id IS NULL THEN
    RAISE EXCEPTION 'User not found or not in an organization';
  END IF;

  -- Get max_users from organization (null means unlimited)
  SELECT max_users INTO v_max_users
  FROM organizations
  WHERE id = v_organization_id;

  -- Count current active users in the organization
  SELECT COUNT(*) INTO v_current_active_users
  FROM profiles
  WHERE organization_id = v_organization_id
    AND disabled_at IS NULL
    AND status = 'active';

  -- Count pending invitations
  SELECT COUNT(*) INTO v_pending_invitations
  FROM invitations
  WHERE organization_id = v_organization_id
    AND status = 'pending'
    AND expires_at > now();

  -- Total users (active + pending)
  v_total_users := v_current_active_users + v_pending_invitations;

  -- Calculate remaining slots
  IF v_max_users IS NULL THEN
    v_remaining_slots := NULL; -- Unlimited
    v_can_invite := TRUE;
  ELSE
    v_remaining_slots := v_max_users - v_total_users;
    v_can_invite := v_remaining_slots > 0;
  END IF;

  -- Return as JSON
  RETURN jsonb_build_object(
    'current_users', v_current_active_users,
    'max_users', v_max_users,
    'pending_invitations', v_pending_invitations,
    'total_users', v_total_users,
    'remaining_slots', v_remaining_slots,
    'can_invite', v_can_invite
  );
END;
$$;
