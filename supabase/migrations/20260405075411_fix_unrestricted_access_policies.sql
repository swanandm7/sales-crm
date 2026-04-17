/*
  # Fix Unrestricted Access Policies
  
  Fix policies that allow unrestricted access (always true conditions)
*/

-- assignment_rule_execution_log: Restrict to admins only
DROP POLICY IF EXISTS "System can insert assignment logs" ON public.assignment_rule_execution_log;
CREATE POLICY "System can insert assignment logs"
  ON public.assignment_rule_execution_log FOR INSERT
  TO authenticated
  WITH CHECK (
    -- Only admins and system processes can create logs
    get_my_role_hierarchy_from_jwt() <= 2
  );

-- invitations: Restrict update to proper conditions
DROP POLICY IF EXISTS "System can update invitation during acceptance" ON public.invitations;
CREATE POLICY "System can update invitation during acceptance"
  ON public.invitations FOR UPDATE
  TO authenticated
  USING (
    -- Can only update invitations for your email or if you're an admin
    email = (SELECT auth.jwt()->>'email')
    OR get_my_role_hierarchy_from_jwt() <= 2
  );

-- system_round_robin_state: Restrict to admins only
DROP POLICY IF EXISTS "System can update round robin state" ON public.system_round_robin_state;
CREATE POLICY "System can update round robin state"
  ON public.system_round_robin_state FOR ALL
  TO authenticated
  USING (get_my_role_hierarchy_from_jwt() <= 2)
  WITH CHECK (get_my_role_hierarchy_from_jwt() <= 2);
