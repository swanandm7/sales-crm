/*
  # Fix Infinite Recursion in organization_members RLS Policies

  1. Problem
    - The policy "Users can view members of their organization" queries organization_members 
      within a policy on organization_members itself, causing infinite recursion
    - Several other policies have the same issue

  2. Solution
    - Drop the recursive policies
    - Create new non-recursive policies that don't reference organization_members within 
      organization_members policies
    - Use a helper function or direct profile checks instead

  3. Changes
    - Drop problematic policies on organization_members
    - Create simpler, non-recursive policies
*/

-- Drop the policies that cause infinite recursion on organization_members
DROP POLICY IF EXISTS "Users can view members of their organization" ON organization_members;
DROP POLICY IF EXISTS "Admins can update members in their organization" ON organization_members;
DROP POLICY IF EXISTS "Admins can delete members from their organization" ON organization_members;

-- Create new non-recursive policy: Users can view their own membership record
CREATE POLICY "Users can view their own membership"
  ON organization_members
  FOR SELECT
  TO authenticated
  USING (profile_id = auth.uid());

-- Create new non-recursive policy: Admins can view members (checks profiles directly, not org_members)
CREATE POLICY "Admins can view organization members"
  ON organization_members
  FOR SELECT
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM profiles p
      JOIN roles r ON r.id = p.role_id
      WHERE p.id = auth.uid()
      AND r.hierarchy_level <= 2
    )
  );

-- Create new non-recursive policy: Admins can update members
CREATE POLICY "Admins can update organization members"
  ON organization_members
  FOR UPDATE
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM profiles p
      JOIN roles r ON r.id = p.role_id
      WHERE p.id = auth.uid()
      AND r.hierarchy_level <= 2
    )
  );

-- Create new non-recursive policy: Admins can delete members
CREATE POLICY "Admins can delete organization members"
  ON organization_members
  FOR DELETE
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM profiles p
      JOIN roles r ON r.id = p.role_id
      WHERE p.id = auth.uid()
      AND r.hierarchy_level <= 2
    )
  );

-- Also fix the recursive policies on invitations table
DROP POLICY IF EXISTS "Admins can view invitations for their organization" ON invitations;
DROP POLICY IF EXISTS "Admins can create invitations for their organization" ON invitations;
DROP POLICY IF EXISTS "Admins can update invitations in their organization" ON invitations;
DROP POLICY IF EXISTS "Admins can delete invitations from their organization" ON invitations;

-- Create new non-recursive policy for invitations: Admins can manage all invitations
CREATE POLICY "Admins can view all invitations"
  ON invitations
  FOR SELECT
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM profiles p
      JOIN roles r ON r.id = p.role_id
      WHERE p.id = auth.uid()
      AND r.hierarchy_level <= 2
    )
  );

CREATE POLICY "Admins can create invitations"
  ON invitations
  FOR INSERT
  TO authenticated
  WITH CHECK (
    EXISTS (
      SELECT 1 FROM profiles p
      JOIN roles r ON r.id = p.role_id
      WHERE p.id = auth.uid()
      AND r.hierarchy_level <= 2
    )
    AND invited_by = auth.uid()
  );

CREATE POLICY "Admins can update invitations"
  ON invitations
  FOR UPDATE
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM profiles p
      JOIN roles r ON r.id = p.role_id
      WHERE p.id = auth.uid()
      AND r.hierarchy_level <= 2
    )
  );

CREATE POLICY "Admins can delete invitations"
  ON invitations
  FOR DELETE
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM profiles p
      JOIN roles r ON r.id = p.role_id
      WHERE p.id = auth.uid()
      AND r.hierarchy_level <= 2
    )
  );