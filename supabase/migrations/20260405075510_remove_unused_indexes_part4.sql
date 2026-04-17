/*
  # Remove Unused Indexes - Part 4
  
  Continue removing unused indexes
*/

-- Message templates indexes
DROP INDEX IF EXISTS public.idx_message_templates_organization_id;
DROP INDEX IF EXISTS public.idx_message_templates_approved;
DROP INDEX IF EXISTS public.idx_message_templates_approved_by;
DROP INDEX IF EXISTS public.idx_message_templates_created_by;
DROP INDEX IF EXISTS public.idx_message_template_users_user;
DROP INDEX IF EXISTS public.idx_message_template_usage_user;
DROP INDEX IF EXISTS public.idx_message_template_usage_log_lead_id;

-- Organization indexes
DROP INDEX IF EXISTS public.idx_organizations_owner_id;
DROP INDEX IF EXISTS public.idx_organizations_suspended_at;
DROP INDEX IF EXISTS public.idx_organizations_suspended_by;
DROP INDEX IF EXISTS public.idx_org_members_role_id;

-- Invitations indexes
DROP INDEX IF EXISTS public.idx_invitations_organization_id;
DROP INDEX IF EXISTS public.idx_invitations_email;
DROP INDEX IF EXISTS public.idx_invitations_token;
DROP INDEX IF EXISTS public.idx_invitations_status;
DROP INDEX IF EXISTS public.idx_invitations_expires_at;
DROP INDEX IF EXISTS public.idx_invitations_cancelled_by;
DROP INDEX IF EXISTS public.idx_invitations_invited_by;
DROP INDEX IF EXISTS public.idx_invitations_role_id;
DROP INDEX IF EXISTS public.idx_organization_members_invited_by;
