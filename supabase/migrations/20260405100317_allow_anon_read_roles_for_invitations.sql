/*
  # Allow Anonymous Users to Read Roles for Invitation Acceptance

  1. Changes
    - Add SELECT policy on roles table for anonymous users
    - This allows invitation acceptance page to display role information
    
  2. Security
    - Only allows reading role data, not modification
    - Enables invitation flow for non-authenticated users
*/

-- Drop the policy if it exists and recreate it
DO $$ 
BEGIN
  DROP POLICY IF EXISTS "Anonymous users can view roles for invitations" ON roles;
END $$;

-- Allow anonymous users to read roles (needed for invitation acceptance)
CREATE POLICY "Anonymous users can view roles for invitations"
  ON roles
  FOR SELECT
  TO anon
  USING (true);
