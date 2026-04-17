/*
  # Add RLS Policies to Organizations Table

  1. Security Policies
    - Super admins can view all organizations
    - Organization members can view their own organization
    - Only super admins can create/delete organizations
    - Super admins and organization admins can update organizations

  2. Notes
    - These policies reference organization_members table which now exists
*/

-- Policy: Super admins can view all organizations
CREATE POLICY "Super admins can view all organizations"
  ON organizations
  FOR SELECT
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM profiles
      WHERE profiles.id = auth.uid()
      AND profiles.role_id IN (
        SELECT id FROM roles WHERE hierarchy_level = 1
      )
    )
  );

-- Policy: Organization members can view their own organization
CREATE POLICY "Organization members can view their organization"
  ON organizations
  FOR SELECT
  TO authenticated
  USING (
    id IN (
      SELECT organization_id 
      FROM organization_members 
      WHERE profile_id = auth.uid()
    )
  );

-- Policy: Only super admins can create organizations
CREATE POLICY "Super admins can create organizations"
  ON organizations
  FOR INSERT
  TO authenticated
  WITH CHECK (
    EXISTS (
      SELECT 1 FROM profiles
      WHERE profiles.id = auth.uid()
      AND profiles.role_id IN (
        SELECT id FROM roles WHERE hierarchy_level = 1
      )
    )
  );

-- Policy: Super admins can update all organizations
CREATE POLICY "Super admins can update all organizations"
  ON organizations
  FOR UPDATE
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM profiles
      WHERE profiles.id = auth.uid()
      AND profiles.role_id IN (
        SELECT id FROM roles WHERE hierarchy_level = 1
      )
    )
  );

-- Policy: Organization admins can update their own organization (limited fields)
CREATE POLICY "Admins can update their organization"
  ON organizations
  FOR UPDATE
  TO authenticated
  USING (
    id IN (
      SELECT om.organization_id 
      FROM organization_members om
      JOIN profiles p ON p.id = om.profile_id
      JOIN roles r ON r.id = p.role_id
      WHERE om.profile_id = auth.uid()
      AND r.hierarchy_level <= 2
    )
  );

-- Policy: Only super admins can delete organizations
CREATE POLICY "Super admins can delete organizations"
  ON organizations
  FOR DELETE
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM profiles
      WHERE profiles.id = auth.uid()
      AND profiles.role_id IN (
        SELECT id FROM roles WHERE hierarchy_level = 1
      )
    )
  );