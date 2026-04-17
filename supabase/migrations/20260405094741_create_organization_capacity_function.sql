/*
  # Create Organization Capacity Function

  1. Purpose
    - Calculates organization capacity and invitation limits
    - Returns current users, max users, remaining slots, and whether new invitations are allowed

  2. Returns
    - current_users: Number of active users + pending invitations
    - max_users: Maximum allowed users (null for unlimited)
    - remaining_slots: Available slots (null for unlimited)
    - can_invite: Boolean indicating if new invitations are allowed

  3. Security
    - Returns capacity for the current user's organization
    - No RLS needed as function checks auth.uid()
*/

-- Create the function to get organization capacity
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
    AND deleted_at IS NULL;

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

-- Grant execute permission to authenticated users
GRANT EXECUTE ON FUNCTION get_organization_capacity() TO authenticated;
