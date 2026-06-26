-- Fix invitation update policy for newly signed up users
DROP POLICY IF EXISTS "System can update invitation during acceptance" ON public.invitations;
CREATE POLICY "System can update invitation during acceptance"
  ON public.invitations FOR UPDATE
  TO authenticated
  USING (
    LOWER(email) = LOWER(auth.jwt()->>'email')
    OR get_my_role_hierarchy_from_jwt() <= 2
  );
