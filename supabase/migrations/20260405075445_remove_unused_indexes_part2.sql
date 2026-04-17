/*
  # Remove Unused Indexes - Part 2
  
  Continue removing unused indexes
*/

-- Lead indexes
DROP INDEX IF EXISTS public.idx_leads_updated_at;
DROP INDEX IF EXISTS public.idx_leads_status_id;
DROP INDEX IF EXISTS public.idx_leads_source_id;
DROP INDEX IF EXISTS public.idx_leads_sub_status_id;
DROP INDEX IF EXISTS public.idx_leads_first_name;
DROP INDEX IF EXISTS public.idx_leads_last_name;
DROP INDEX IF EXISTS public.idx_leads_university;
DROP INDEX IF EXISTS public.idx_leads_course;
DROP INDEX IF EXISTS public.idx_leads_state;
DROP INDEX IF EXISTS public.idx_leads_pincode;
DROP INDEX IF EXISTS public.idx_leads_campaign_id;
DROP INDEX IF EXISTS public.idx_leads_keyword;
DROP INDEX IF EXISTS public.idx_leads_channel;
DROP INDEX IF EXISTS public.idx_leads_current_owner;
DROP INDEX IF EXISTS public.idx_leads_is_re_enquired;
DROP INDEX IF EXISTS public.idx_leads_created_by;
DROP INDEX IF EXISTS public.idx_leads_previous_owner;

-- Calls indexes
DROP INDEX IF EXISTS public.idx_calls_user_id;
DROP INDEX IF EXISTS public.idx_calls_organization_id;

-- Notes indexes
DROP INDEX IF EXISTS public.idx_notes_organization_id;
DROP INDEX IF EXISTS public.idx_notes_user_id;

-- Lead sources indexes
DROP INDEX IF EXISTS public.idx_lead_sources_organization_id;
