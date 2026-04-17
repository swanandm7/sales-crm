/*
  # Update Leads RLS Policies with Organization Filtering

  1. Changes
    - Drop all existing policies on leads table
    - Create new policies that include organization filtering
    - Maintain role-based access (sales reps see only their leads, etc.)
    - Add organization isolation

  2. Security
    - Super admins see all leads across all organizations
    - Users only see leads within their organization
    - Sales reps see only their assigned leads
    - Team leads see their team's leads
    - Admins see all leads in their organization
*/

-- Drop existing policies on leads
DROP POLICY IF EXISTS "Users can view leads they have access to" ON leads;
DROP POLICY IF EXISTS "Sales reps can view their own leads" ON leads;
DROP POLICY IF EXISTS "Team leads can view their team's leads" ON leads;
DROP POLICY IF EXISTS "Admins can view all leads" ON leads;
DROP POLICY IF EXISTS "Super admins can view all leads" ON leads;
DROP POLICY IF EXISTS "Users can insert leads" ON leads;
DROP POLICY IF EXISTS "Admins can insert leads" ON leads;
DROP POLICY IF EXISTS "Super admins can insert leads" ON leads;
DROP POLICY IF EXISTS "Users can update their own leads" ON leads;
DROP POLICY IF EXISTS "Team leads can update their team's leads" ON leads;
DROP POLICY IF EXISTS "Admins can update all leads" ON leads;
DROP POLICY IF EXISTS "Super admins can update all leads" ON leads;
DROP POLICY IF EXISTS "Admins can delete leads" ON leads;
DROP POLICY IF EXISTS "Super admins can delete leads" ON leads;

-- Policy: Super admins can view all leads across all organizations
CREATE POLICY "Super admins can view all leads"
  ON leads
  FOR SELECT
  TO authenticated
  USING (is_super_admin(auth.uid()));

-- Policy: Admins can view all leads in their organization
CREATE POLICY "Admins can view all leads in their organization"
  ON leads
  FOR SELECT
  TO authenticated
  USING (
    organization_id = get_user_organization_id(auth.uid())
    AND get_user_hierarchy_level(auth.uid()) <= 2
  );

-- Policy: Team leads can view their team's leads in their organization
CREATE POLICY "Team leads can view their team's leads"
  ON leads
  FOR SELECT
  TO authenticated
  USING (
    organization_id = get_user_organization_id(auth.uid())
    AND get_user_hierarchy_level(auth.uid()) = 3
    AND (
      assigned_to = auth.uid()
      OR assigned_to IN (
        SELECT id FROM profiles 
        WHERE team_id IN (
          SELECT team_id FROM profiles WHERE id = auth.uid()
        )
      )
    )
  );

-- Policy: Sales reps can view their own leads in their organization
CREATE POLICY "Sales reps can view their own leads"
  ON leads
  FOR SELECT
  TO authenticated
  USING (
    organization_id = get_user_organization_id(auth.uid())
    AND assigned_to = auth.uid()
  );

-- Policy: Super admins can insert leads for any organization
CREATE POLICY "Super admins can insert leads"
  ON leads
  FOR INSERT
  TO authenticated
  WITH CHECK (is_super_admin(auth.uid()));

-- Policy: Users can insert leads in their organization
CREATE POLICY "Users can insert leads in their organization"
  ON leads
  FOR INSERT
  TO authenticated
  WITH CHECK (
    organization_id = get_user_organization_id(auth.uid())
  );

-- Policy: Super admins can update all leads
CREATE POLICY "Super admins can update all leads"
  ON leads
  FOR UPDATE
  TO authenticated
  USING (is_super_admin(auth.uid()));

-- Policy: Admins can update all leads in their organization
CREATE POLICY "Admins can update all leads in their organization"
  ON leads
  FOR UPDATE
  TO authenticated
  USING (
    organization_id = get_user_organization_id(auth.uid())
    AND get_user_hierarchy_level(auth.uid()) <= 2
  );

-- Policy: Team leads can update their team's leads
CREATE POLICY "Team leads can update their team's leads"
  ON leads
  FOR UPDATE
  TO authenticated
  USING (
    organization_id = get_user_organization_id(auth.uid())
    AND get_user_hierarchy_level(auth.uid()) = 3
    AND (
      assigned_to = auth.uid()
      OR assigned_to IN (
        SELECT id FROM profiles 
        WHERE team_id IN (
          SELECT team_id FROM profiles WHERE id = auth.uid()
        )
      )
    )
  );

-- Policy: Sales reps can update their own leads
CREATE POLICY "Sales reps can update their own leads"
  ON leads
  FOR UPDATE
  TO authenticated
  USING (
    organization_id = get_user_organization_id(auth.uid())
    AND assigned_to = auth.uid()
  );

-- Policy: Super admins can delete leads
CREATE POLICY "Super admins can delete leads"
  ON leads
  FOR DELETE
  TO authenticated
  USING (is_super_admin(auth.uid()));

-- Policy: Admins can delete leads in their organization
CREATE POLICY "Admins can delete leads in their organization"
  ON leads
  FOR DELETE
  TO authenticated
  USING (
    organization_id = get_user_organization_id(auth.uid())
    AND get_user_hierarchy_level(auth.uid()) <= 2
  );