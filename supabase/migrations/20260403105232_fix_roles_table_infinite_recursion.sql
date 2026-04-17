/*
  # Fix infinite recursion in roles table policies

  1. Changes
    - Drop the problematic "Only admins can modify roles" policy that causes infinite recursion
    - Create separate policies for INSERT, UPDATE, DELETE that check admin status
    - Keep the simple SELECT policy that allows all authenticated users to view roles
    
  2. Security
    - SELECT: All authenticated users can view roles (needed for profile joins)
    - INSERT/UPDATE/DELETE: Only users with hierarchy_level <= 2 (admins) can modify
    - Prevents infinite recursion by avoiding joins in the admin check for these operations
*/

-- Drop the problematic policy
DROP POLICY IF EXISTS "Only admins can modify roles" ON roles;

-- Create separate policies for each operation to avoid infinite recursion
CREATE POLICY "Only admins can insert roles"
  ON roles
  FOR INSERT
  TO authenticated
  WITH CHECK (
    EXISTS (
      SELECT 1 FROM profiles
      WHERE profiles.id = auth.uid()
      AND profiles.role_id IN (
        SELECT id FROM roles WHERE hierarchy_level <= 2
      )
    )
  );

CREATE POLICY "Only admins can update roles"
  ON roles
  FOR UPDATE
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM profiles
      WHERE profiles.id = auth.uid()
      AND profiles.role_id IN (
        SELECT id FROM roles WHERE hierarchy_level <= 2
      )
    )
  )
  WITH CHECK (
    EXISTS (
      SELECT 1 FROM profiles
      WHERE profiles.id = auth.uid()
      AND profiles.role_id IN (
        SELECT id FROM roles WHERE hierarchy_level <= 2
      )
    )
  );

CREATE POLICY "Only admins can delete roles"
  ON roles
  FOR DELETE
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM profiles
      WHERE profiles.id = auth.uid()
      AND profiles.role_id IN (
        SELECT id FROM roles WHERE hierarchy_level <= 2
      )
    )
  );
