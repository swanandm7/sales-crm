/*
  # Webhook Integration System - Database Schema

  ## 1. New Tables Created
  
  ### webhook_configurations
  - `id` (uuid, primary key) - Unique webhook configuration identifier
  - `organization_id` (uuid, foreign key) - Organization owning this configuration
  - `webhook_name` (text) - Friendly name for the webhook endpoint
  - `hmac_secret` (text) - Secret key for HMAC-SHA256 signature verification
  - `api_key` (text, unique) - API key for organization identification
  - `is_enabled` (boolean) - Whether webhook is active
  - `allowed_ip_addresses` (text[]) - Optional IP whitelist for security
  - `rate_limit_per_minute` (integer) - Max requests per minute
  - `created_by` (uuid) - User who created the configuration
  - `created_at` (timestamptz) - Creation timestamp
  - `updated_at` (timestamptz) - Last update timestamp

  ### webhook_sources
  - `id` (uuid, primary key) - Unique source identifier
  - `organization_id` (uuid, foreign key) - Organization owning this source
  - `source_name` (text) - Name of the lead source (e.g., "Facebook Ads", "Google Ads")
  - `source_type` (text) - Type category of source
  - `field_mappings` (jsonb) - Mapping rules from source fields to lead schema
  - `is_active` (boolean) - Whether source is enabled
  - `created_at` (timestamptz) - Creation timestamp
  - `updated_at` (timestamptz) - Last update timestamp

  ### webhook_delivery_queue
  - `id` (uuid, primary key) - Unique queue item identifier
  - `organization_id` (uuid, foreign key) - Organization for this delivery
  - `lead_id` (uuid, foreign key) - Lead being sent
  - `endpoint_id` (uuid, foreign key) - Target endpoint for delivery
  - `event_type` (text) - Type of event (e.g., "lead.created", "lead.assigned")
  - `payload` (jsonb) - Data to be sent
  - `status` (text) - Current status: pending, processing, completed, failed
  - `retry_count` (integer) - Number of retry attempts
  - `max_retries` (integer) - Maximum retry attempts allowed
  - `next_retry_at` (timestamptz) - When to retry next
  - `created_at` (timestamptz) - Queue creation timestamp
  - `updated_at` (timestamptz) - Last update timestamp

  ### webhook_delivery_log
  - `id` (uuid, primary key) - Unique log entry identifier
  - `queue_id` (uuid, foreign key) - Reference to queue item
  - `organization_id` (uuid, foreign key) - Organization for this delivery
  - `endpoint_id` (uuid, foreign key) - Target endpoint
  - `event_type` (text) - Type of event
  - `request_payload` (jsonb) - Request data sent
  - `response_status` (integer) - HTTP response status code
  - `response_body` (text) - Response from endpoint
  - `error_message` (text) - Error details if failed
  - `duration_ms` (integer) - Request duration in milliseconds
  - `created_at` (timestamptz) - Log entry timestamp

  ### integration_endpoints
  - `id` (uuid, primary key) - Unique endpoint identifier
  - `organization_id` (uuid, foreign key) - Organization owning this endpoint
  - `endpoint_name` (text) - Friendly name for endpoint
  - `endpoint_type` (text) - Type: slack, webhook, custom
  - `endpoint_url` (text) - Target URL for webhook delivery
  - `authentication_type` (text) - Auth method: none, api_key, hmac
  - `authentication_config` (jsonb) - Auth credentials/config
  - `is_active` (boolean) - Whether endpoint is enabled
  - `created_by` (uuid) - User who created endpoint
  - `created_at` (timestamptz) - Creation timestamp
  - `updated_at` (timestamptz) - Last update timestamp

  ### webhook_event_subscriptions
  - `id` (uuid, primary key) - Unique subscription identifier
  - `organization_id` (uuid, foreign key) - Organization for subscription
  - `endpoint_id` (uuid, foreign key) - Target endpoint
  - `event_type` (text) - Event to subscribe to
  - `filter_criteria` (jsonb) - Optional filters for events
  - `is_active` (boolean) - Whether subscription is enabled
  - `created_at` (timestamptz) - Creation timestamp

  ### api_keys
  - `id` (uuid, primary key) - Unique API key identifier
  - `organization_id` (uuid, foreign key) - Organization owning key
  - `key_name` (text) - Friendly name for API key
  - `key_hash` (text) - Hashed API key value
  - `key_prefix` (text) - First 8 chars for identification
  - `scopes` (text[]) - Allowed operations
  - `rate_limit_per_minute` (integer) - Rate limit for this key
  - `expires_at` (timestamptz) - Expiration timestamp (null = never)
  - `last_used_at` (timestamptz) - Last usage timestamp
  - `is_active` (boolean) - Whether key is valid
  - `created_by` (uuid) - User who created key
  - `created_at` (timestamptz) - Creation timestamp

  ### webhook_request_log
  - `id` (uuid, primary key) - Unique log identifier
  - `organization_id` (uuid) - Organization for request (null if auth failed)
  - `request_path` (text) - API endpoint path
  - `request_method` (text) - HTTP method
  - `request_headers` (jsonb) - Request headers (sanitized)
  - `request_body` (jsonb) - Request payload
  - `response_status` (integer) - HTTP response status
  - `error_message` (text) - Error details if failed
  - `ip_address` (text) - Source IP address
  - `user_agent` (text) - Client user agent
  - `duration_ms` (integer) - Request duration
  - `created_at` (timestamptz) - Request timestamp

  ### webhook_health_metrics
  - `id` (uuid, primary key) - Unique metric identifier
  - `organization_id` (uuid, foreign key) - Organization being measured
  - `metric_type` (text) - Type: incoming_success, incoming_failed, outgoing_success, outgoing_failed
  - `endpoint_id` (uuid) - Related endpoint (for outgoing metrics)
  - `count` (integer) - Number of events
  - `total_duration_ms` (bigint) - Total processing time
  - `hour_bucket` (timestamptz) - Hour bucket for aggregation
  - `created_at` (timestamptz) - Metric creation timestamp

  ## 2. Security
  - Enable RLS on all tables
  - Add policies for organization-based access control
  - Policies check user's organization membership
  - Super admins can view all data across organizations

  ## 3. Indexes
  - Performance indexes on foreign keys
  - Indexes on frequently queried columns
  - Composite indexes for common query patterns
*/

-- Create webhook_configurations table
CREATE TABLE IF NOT EXISTS webhook_configurations (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  organization_id uuid NOT NULL REFERENCES organizations(id) ON DELETE CASCADE,
  webhook_name text NOT NULL,
  hmac_secret text NOT NULL,
  api_key text UNIQUE NOT NULL,
  is_enabled boolean DEFAULT true,
  allowed_ip_addresses text[] DEFAULT NULL,
  rate_limit_per_minute integer DEFAULT 60,
  created_by uuid REFERENCES profiles(id) ON DELETE SET NULL,
  created_at timestamptz DEFAULT now(),
  updated_at timestamptz DEFAULT now(),
  UNIQUE(organization_id, webhook_name)
);

-- Create webhook_sources table
CREATE TABLE IF NOT EXISTS webhook_sources (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  organization_id uuid NOT NULL REFERENCES organizations(id) ON DELETE CASCADE,
  source_name text NOT NULL,
  source_type text NOT NULL,
  field_mappings jsonb DEFAULT '{}'::jsonb,
  is_active boolean DEFAULT true,
  created_at timestamptz DEFAULT now(),
  updated_at timestamptz DEFAULT now(),
  UNIQUE(organization_id, source_name)
);

-- Create integration_endpoints table
CREATE TABLE IF NOT EXISTS integration_endpoints (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  organization_id uuid NOT NULL REFERENCES organizations(id) ON DELETE CASCADE,
  endpoint_name text NOT NULL,
  endpoint_type text NOT NULL CHECK (endpoint_type IN ('slack', 'webhook', 'custom')),
  endpoint_url text NOT NULL,
  authentication_type text DEFAULT 'none' CHECK (authentication_type IN ('none', 'api_key', 'hmac', 'bearer')),
  authentication_config jsonb DEFAULT '{}'::jsonb,
  is_active boolean DEFAULT true,
  created_by uuid REFERENCES profiles(id) ON DELETE SET NULL,
  created_at timestamptz DEFAULT now(),
  updated_at timestamptz DEFAULT now(),
  UNIQUE(organization_id, endpoint_name)
);

-- Create webhook_delivery_queue table
CREATE TABLE IF NOT EXISTS webhook_delivery_queue (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  organization_id uuid NOT NULL REFERENCES organizations(id) ON DELETE CASCADE,
  lead_id uuid REFERENCES leads(id) ON DELETE CASCADE,
  endpoint_id uuid NOT NULL REFERENCES integration_endpoints(id) ON DELETE CASCADE,
  event_type text NOT NULL,
  payload jsonb NOT NULL,
  status text DEFAULT 'pending' CHECK (status IN ('pending', 'processing', 'completed', 'failed')),
  retry_count integer DEFAULT 0,
  max_retries integer DEFAULT 3,
  next_retry_at timestamptz DEFAULT now(),
  created_at timestamptz DEFAULT now(),
  updated_at timestamptz DEFAULT now()
);

-- Create webhook_delivery_log table
CREATE TABLE IF NOT EXISTS webhook_delivery_log (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  queue_id uuid REFERENCES webhook_delivery_queue(id) ON DELETE SET NULL,
  organization_id uuid NOT NULL REFERENCES organizations(id) ON DELETE CASCADE,
  endpoint_id uuid REFERENCES integration_endpoints(id) ON DELETE SET NULL,
  event_type text NOT NULL,
  request_payload jsonb,
  response_status integer,
  response_body text,
  error_message text,
  duration_ms integer,
  created_at timestamptz DEFAULT now()
);

-- Create webhook_event_subscriptions table
CREATE TABLE IF NOT EXISTS webhook_event_subscriptions (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  organization_id uuid NOT NULL REFERENCES organizations(id) ON DELETE CASCADE,
  endpoint_id uuid NOT NULL REFERENCES integration_endpoints(id) ON DELETE CASCADE,
  event_type text NOT NULL,
  filter_criteria jsonb DEFAULT '{}'::jsonb,
  is_active boolean DEFAULT true,
  created_at timestamptz DEFAULT now(),
  UNIQUE(endpoint_id, event_type)
);

-- Create api_keys table
CREATE TABLE IF NOT EXISTS api_keys (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  organization_id uuid NOT NULL REFERENCES organizations(id) ON DELETE CASCADE,
  key_name text NOT NULL,
  key_hash text NOT NULL UNIQUE,
  key_prefix text NOT NULL,
  scopes text[] DEFAULT ARRAY['webhook:receive', 'webhook:send'],
  rate_limit_per_minute integer DEFAULT 60,
  expires_at timestamptz DEFAULT NULL,
  last_used_at timestamptz DEFAULT NULL,
  is_active boolean DEFAULT true,
  created_by uuid REFERENCES profiles(id) ON DELETE SET NULL,
  created_at timestamptz DEFAULT now(),
  UNIQUE(organization_id, key_name)
);

-- Create webhook_request_log table
CREATE TABLE IF NOT EXISTS webhook_request_log (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  organization_id uuid REFERENCES organizations(id) ON DELETE CASCADE,
  request_path text NOT NULL,
  request_method text NOT NULL,
  request_headers jsonb,
  request_body jsonb,
  response_status integer,
  error_message text,
  ip_address text,
  user_agent text,
  duration_ms integer,
  created_at timestamptz DEFAULT now()
);

-- Create webhook_health_metrics table
CREATE TABLE IF NOT EXISTS webhook_health_metrics (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  organization_id uuid NOT NULL REFERENCES organizations(id) ON DELETE CASCADE,
  metric_type text NOT NULL CHECK (metric_type IN ('incoming_success', 'incoming_failed', 'outgoing_success', 'outgoing_failed')),
  endpoint_id uuid REFERENCES integration_endpoints(id) ON DELETE SET NULL,
  count integer DEFAULT 0,
  total_duration_ms bigint DEFAULT 0,
  hour_bucket timestamptz NOT NULL,
  created_at timestamptz DEFAULT now(),
  UNIQUE(organization_id, metric_type, endpoint_id, hour_bucket)
);

-- Create indexes for performance
CREATE INDEX IF NOT EXISTS idx_webhook_configs_org ON webhook_configurations(organization_id);
CREATE INDEX IF NOT EXISTS idx_webhook_configs_api_key ON webhook_configurations(api_key) WHERE is_enabled = true;

CREATE INDEX IF NOT EXISTS idx_webhook_sources_org ON webhook_sources(organization_id);
CREATE INDEX IF NOT EXISTS idx_webhook_sources_active ON webhook_sources(organization_id) WHERE is_active = true;

CREATE INDEX IF NOT EXISTS idx_integration_endpoints_org ON integration_endpoints(organization_id);
CREATE INDEX IF NOT EXISTS idx_integration_endpoints_active ON integration_endpoints(organization_id) WHERE is_active = true;

CREATE INDEX IF NOT EXISTS idx_delivery_queue_status ON webhook_delivery_queue(status, next_retry_at) WHERE status IN ('pending', 'processing');
CREATE INDEX IF NOT EXISTS idx_delivery_queue_org ON webhook_delivery_queue(organization_id);
CREATE INDEX IF NOT EXISTS idx_delivery_queue_lead ON webhook_delivery_queue(lead_id);

CREATE INDEX IF NOT EXISTS idx_delivery_log_org ON webhook_delivery_log(organization_id);
CREATE INDEX IF NOT EXISTS idx_delivery_log_endpoint ON webhook_delivery_log(endpoint_id);
CREATE INDEX IF NOT EXISTS idx_delivery_log_created ON webhook_delivery_log(created_at DESC);

CREATE INDEX IF NOT EXISTS idx_event_subscriptions_org ON webhook_event_subscriptions(organization_id);
CREATE INDEX IF NOT EXISTS idx_event_subscriptions_endpoint ON webhook_event_subscriptions(endpoint_id) WHERE is_active = true;
CREATE INDEX IF NOT EXISTS idx_event_subscriptions_event ON webhook_event_subscriptions(event_type) WHERE is_active = true;

CREATE INDEX IF NOT EXISTS idx_api_keys_org ON api_keys(organization_id);
CREATE INDEX IF NOT EXISTS idx_api_keys_hash ON api_keys(key_hash) WHERE is_active = true;

CREATE INDEX IF NOT EXISTS idx_request_log_org ON webhook_request_log(organization_id);
CREATE INDEX IF NOT EXISTS idx_request_log_created ON webhook_request_log(created_at DESC);

CREATE INDEX IF NOT EXISTS idx_health_metrics_org_bucket ON webhook_health_metrics(organization_id, hour_bucket DESC);
CREATE INDEX IF NOT EXISTS idx_health_metrics_endpoint ON webhook_health_metrics(endpoint_id, hour_bucket DESC);

-- Enable Row Level Security
ALTER TABLE webhook_configurations ENABLE ROW LEVEL SECURITY;
ALTER TABLE webhook_sources ENABLE ROW LEVEL SECURITY;
ALTER TABLE integration_endpoints ENABLE ROW LEVEL SECURITY;
ALTER TABLE webhook_delivery_queue ENABLE ROW LEVEL SECURITY;
ALTER TABLE webhook_delivery_log ENABLE ROW LEVEL SECURITY;
ALTER TABLE webhook_event_subscriptions ENABLE ROW LEVEL SECURITY;
ALTER TABLE api_keys ENABLE ROW LEVEL SECURITY;
ALTER TABLE webhook_request_log ENABLE ROW LEVEL SECURITY;
ALTER TABLE webhook_health_metrics ENABLE ROW LEVEL SECURITY;

-- RLS Policies for webhook_configurations
CREATE POLICY "Users can view own organization webhook configs"
  ON webhook_configurations FOR SELECT
  TO authenticated
  USING (can_access_organization(auth.uid(), organization_id));

CREATE POLICY "Admins can insert webhook configs"
  ON webhook_configurations FOR INSERT
  TO authenticated
  WITH CHECK (
    can_access_organization(auth.uid(), organization_id) AND
    EXISTS (
      SELECT 1 FROM profiles p
      JOIN role_permissions rp ON p.role_id = rp.role_id
      JOIN permissions perm ON rp.permission_id = perm.id
      WHERE p.id = auth.uid() 
      AND perm.permission_key = 'settings:manage'
    )
  );

CREATE POLICY "Admins can update webhook configs"
  ON webhook_configurations FOR UPDATE
  TO authenticated
  USING (
    can_access_organization(auth.uid(), organization_id) AND
    EXISTS (
      SELECT 1 FROM profiles p
      JOIN role_permissions rp ON p.role_id = rp.role_id
      JOIN permissions perm ON rp.permission_id = perm.id
      WHERE p.id = auth.uid() 
      AND perm.permission_key = 'settings:manage'
    )
  );

CREATE POLICY "Admins can delete webhook configs"
  ON webhook_configurations FOR DELETE
  TO authenticated
  USING (
    can_access_organization(auth.uid(), organization_id) AND
    EXISTS (
      SELECT 1 FROM profiles p
      JOIN role_permissions rp ON p.role_id = rp.role_id
      JOIN permissions perm ON rp.permission_id = perm.id
      WHERE p.id = auth.uid() 
      AND perm.permission_key = 'settings:manage'
    )
  );

-- RLS Policies for webhook_sources
CREATE POLICY "Users can view own organization webhook sources"
  ON webhook_sources FOR SELECT
  TO authenticated
  USING (can_access_organization(auth.uid(), organization_id));

CREATE POLICY "Admins can manage webhook sources"
  ON webhook_sources FOR ALL
  TO authenticated
  USING (
    can_access_organization(auth.uid(), organization_id) AND
    EXISTS (
      SELECT 1 FROM profiles p
      JOIN role_permissions rp ON p.role_id = rp.role_id
      JOIN permissions perm ON rp.permission_id = perm.id
      WHERE p.id = auth.uid() 
      AND perm.permission_key = 'settings:manage'
    )
  );

-- RLS Policies for integration_endpoints
CREATE POLICY "Users can view own organization endpoints"
  ON integration_endpoints FOR SELECT
  TO authenticated
  USING (can_access_organization(auth.uid(), organization_id));

CREATE POLICY "Admins can manage integration endpoints"
  ON integration_endpoints FOR ALL
  TO authenticated
  USING (
    can_access_organization(auth.uid(), organization_id) AND
    EXISTS (
      SELECT 1 FROM profiles p
      JOIN role_permissions rp ON p.role_id = rp.role_id
      JOIN permissions perm ON rp.permission_id = perm.id
      WHERE p.id = auth.uid() 
      AND perm.permission_key = 'settings:manage'
    )
  );

-- RLS Policies for webhook_delivery_queue
CREATE POLICY "Users can view own organization delivery queue"
  ON webhook_delivery_queue FOR SELECT
  TO authenticated
  USING (can_access_organization(auth.uid(), organization_id));

-- RLS Policies for webhook_delivery_log
CREATE POLICY "Users can view own organization delivery logs"
  ON webhook_delivery_log FOR SELECT
  TO authenticated
  USING (can_access_organization(auth.uid(), organization_id));

-- RLS Policies for webhook_event_subscriptions
CREATE POLICY "Users can view own organization event subscriptions"
  ON webhook_event_subscriptions FOR SELECT
  TO authenticated
  USING (can_access_organization(auth.uid(), organization_id));

CREATE POLICY "Admins can manage event subscriptions"
  ON webhook_event_subscriptions FOR ALL
  TO authenticated
  USING (
    can_access_organization(auth.uid(), organization_id) AND
    EXISTS (
      SELECT 1 FROM profiles p
      JOIN role_permissions rp ON p.role_id = rp.role_id
      JOIN permissions perm ON rp.permission_id = perm.id
      WHERE p.id = auth.uid() 
      AND perm.permission_key = 'settings:manage'
    )
  );

-- RLS Policies for api_keys
CREATE POLICY "Users can view own organization API keys"
  ON api_keys FOR SELECT
  TO authenticated
  USING (can_access_organization(auth.uid(), organization_id));

CREATE POLICY "Admins can manage API keys"
  ON api_keys FOR ALL
  TO authenticated
  USING (
    can_access_organization(auth.uid(), organization_id) AND
    EXISTS (
      SELECT 1 FROM profiles p
      JOIN role_permissions rp ON p.role_id = rp.role_id
      JOIN permissions perm ON rp.permission_id = perm.id
      WHERE p.id = auth.uid() 
      AND perm.permission_key = 'settings:manage'
    )
  );

-- RLS Policies for webhook_request_log
CREATE POLICY "Admins can view webhook request logs"
  ON webhook_request_log FOR SELECT
  TO authenticated
  USING (
    can_access_organization(auth.uid(), organization_id) AND
    EXISTS (
      SELECT 1 FROM profiles p
      JOIN role_permissions rp ON p.role_id = rp.role_id
      JOIN permissions perm ON rp.permission_id = perm.id
      WHERE p.id = auth.uid() 
      AND perm.permission_key IN ('analytics:view', 'settings:manage')
    )
  );

-- RLS Policies for webhook_health_metrics
CREATE POLICY "Users can view own organization health metrics"
  ON webhook_health_metrics FOR SELECT
  TO authenticated
  USING (can_access_organization(auth.uid(), organization_id));

-- Create function to update updated_at timestamp
CREATE OR REPLACE FUNCTION update_webhook_updated_at()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = now();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Create triggers for updated_at
CREATE TRIGGER update_webhook_configurations_updated_at
  BEFORE UPDATE ON webhook_configurations
  FOR EACH ROW
  EXECUTE FUNCTION update_webhook_updated_at();

CREATE TRIGGER update_webhook_sources_updated_at
  BEFORE UPDATE ON webhook_sources
  FOR EACH ROW
  EXECUTE FUNCTION update_webhook_updated_at();

CREATE TRIGGER update_integration_endpoints_updated_at
  BEFORE UPDATE ON integration_endpoints
  FOR EACH ROW
  EXECUTE FUNCTION update_webhook_updated_at();

CREATE TRIGGER update_webhook_delivery_queue_updated_at
  BEFORE UPDATE ON webhook_delivery_queue
  FOR EACH ROW
  EXECUTE FUNCTION update_webhook_updated_at();