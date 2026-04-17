/*
  # Remove Unused Indexes - Part 5
  
  Continue removing unused indexes - Email and Webhook systems
*/

-- Email system indexes
DROP INDEX IF EXISTS public.idx_email_queue_status;
DROP INDEX IF EXISTS public.idx_email_queue_scheduled_at;
DROP INDEX IF EXISTS public.idx_email_queue_priority;
DROP INDEX IF EXISTS public.idx_email_queue_organization_id;
DROP INDEX IF EXISTS public.idx_email_queue_template_id;
DROP INDEX IF EXISTS public.idx_email_logs_to_email;
DROP INDEX IF EXISTS public.idx_email_logs_sent_at;
DROP INDEX IF EXISTS public.idx_email_logs_organization_id;
DROP INDEX IF EXISTS public.idx_email_logs_queue_id;
DROP INDEX IF EXISTS public.idx_email_templates_organization_id;

-- Webhook system indexes
DROP INDEX IF EXISTS public.idx_webhook_configs_org;
DROP INDEX IF EXISTS public.idx_webhook_configs_api_key;
DROP INDEX IF EXISTS public.idx_webhook_configurations_created_by;
DROP INDEX IF EXISTS public.idx_webhook_sources_org;
DROP INDEX IF EXISTS public.idx_webhook_sources_active;
DROP INDEX IF EXISTS public.idx_integration_endpoints_org;
DROP INDEX IF EXISTS public.idx_integration_endpoints_active;
DROP INDEX IF EXISTS public.idx_integration_endpoints_created_by;
DROP INDEX IF EXISTS public.idx_delivery_queue_status;
DROP INDEX IF EXISTS public.idx_delivery_queue_org;
DROP INDEX IF EXISTS public.idx_delivery_queue_lead;
DROP INDEX IF EXISTS public.idx_delivery_queue_endpoint_id;
DROP INDEX IF EXISTS public.idx_delivery_log_org;
DROP INDEX IF EXISTS public.idx_delivery_log_endpoint;
DROP INDEX IF EXISTS public.idx_delivery_log_created;
DROP INDEX IF EXISTS public.idx_delivery_log_queue_id;
DROP INDEX IF EXISTS public.idx_webhook_delivery_log_queue_id;
