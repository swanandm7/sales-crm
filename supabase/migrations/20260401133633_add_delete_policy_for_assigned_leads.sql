/*
  # Add Delete Policy for Assigned Leads

  1. Changes
    - Add policy to allow users to delete their own assigned leads
    - This enables both admins and sales reps to delete leads they are assigned to
  
  2. Security
    - Users can only delete leads assigned to them
    - Admins can delete any lead (existing policy)
*/

-- Drop the existing restrictive delete policy
DROP POLICY IF EXISTS "Admins can delete leads" ON leads;

-- Create new delete policy for admins
CREATE POLICY "Admins can delete leads"
  ON leads FOR DELETE
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM profiles
      WHERE profiles.id = auth.uid()
      AND profiles.role = 'admin'
    )
  );

-- Create new delete policy for assigned leads
CREATE POLICY "Users can delete assigned leads"
  ON leads FOR DELETE
  TO authenticated
  USING (assigned_to = auth.uid());
