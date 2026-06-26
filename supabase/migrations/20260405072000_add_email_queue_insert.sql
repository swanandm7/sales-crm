-- Add INSERT policy for email_queue so the frontend can send emails via Resend

CREATE POLICY "Users can insert into email queue for their organization"
  ON public.email_queue FOR INSERT
  TO authenticated
  WITH CHECK (
    organization_id IN (
      SELECT organization_id
      FROM public.organization_members
      WHERE profile_id = (SELECT auth.uid())
    )
  );

