/*
  # Create Webhook Delivery Trigger System

  ## Purpose
  Creates database triggers that automatically queue webhook deliveries
  when leads are created and assigned to counselors.

  ## Trigger Logic
  1. Fires after INSERT on leads table
  2. Only triggers when lead has been assigned (assigned_to IS NOT NULL)
  3. Finds all active webhook subscriptions for the organization
  4. Creates delivery queue entries for each subscribed endpoint
  5. Builds webhook payload with lead and assignment details

  ## Security
  - Trigger runs with SECURITY DEFINER to bypass RLS
  - Only creates queue entries for valid, active subscriptions
*/

-- Create function to queue webhook deliveries for lead events
CREATE OR REPLACE FUNCTION queue_webhook_delivery_for_lead()
RETURNS TRIGGER AS $$
DECLARE
  subscription RECORD;
  webhook_payload jsonb;
  lead_profile RECORD;
BEGIN
  -- Only queue webhooks if lead is assigned
  IF NEW.assigned_to IS NULL THEN
    RETURN NEW;
  END IF;

  -- Get assigned user details
  SELECT 
    id,
    full_name,
    email
  INTO lead_profile
  FROM profiles
  WHERE id = NEW.assigned_to;

  -- Build webhook payload
  webhook_payload := jsonb_build_object(
    'event_type', 'lead.created',
    'event_id', gen_random_uuid(),
    'timestamp', NOW(),
    'organization_id', NEW.organization_id,
    'lead', jsonb_build_object(
      'id', NEW.id,
      'name', NEW.name,
      'first_name', NEW.first_name,
      'last_name', NEW.last_name,
      'email', NEW.email,
      'mobile_number', NEW.mobile_number,
      'company', NEW.company,
      'lead_value', NEW.lead_value,
      'channel', NEW.channel,
      'campaign_name', NEW.campaign_name,
      'country', NEW.country,
      'city', NEW.city,
      'state', NEW.state,
      'course', NEW.course,
      'specialization', NEW.specialization,
      'tags', NEW.tags,
      'created_at', NEW.created_at
    ),
    'assignment', jsonb_build_object(
      'assigned_to_id', NEW.assigned_to,
      'assigned_to_name', lead_profile.full_name,
      'assigned_to_email', lead_profile.email,
      'assigned_at', NEW.created_at
    )
  );

  -- Find all active subscriptions for this event type and organization
  FOR subscription IN
    SELECT 
      es.id as subscription_id,
      es.endpoint_id,
      es.filter_criteria,
      ep.endpoint_type,
      ep.endpoint_url,
      ep.is_active as endpoint_active
    FROM webhook_event_subscriptions es
    JOIN integration_endpoints ep ON es.endpoint_id = ep.id
    WHERE es.organization_id = NEW.organization_id
      AND es.event_type = 'lead.created'
      AND es.is_active = true
      AND ep.is_active = true
  LOOP
    -- Apply filter criteria if specified
    -- For now, we'll queue all events and handle filtering in the processor
    
    -- Insert into delivery queue
    INSERT INTO webhook_delivery_queue (
      organization_id,
      lead_id,
      endpoint_id,
      event_type,
      payload,
      status,
      retry_count,
      max_retries,
      next_retry_at
    ) VALUES (
      NEW.organization_id,
      NEW.id,
      subscription.endpoint_id,
      'lead.created',
      webhook_payload,
      'pending',
      0,
      3,
      NOW()
    );
  END LOOP;

  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Create trigger on leads table
DROP TRIGGER IF EXISTS trigger_queue_webhook_on_lead_created ON leads;

CREATE TRIGGER trigger_queue_webhook_on_lead_created
  AFTER INSERT ON leads
  FOR EACH ROW
  EXECUTE FUNCTION queue_webhook_delivery_for_lead();

-- Create function to queue webhooks when lead assignment changes
CREATE OR REPLACE FUNCTION queue_webhook_delivery_for_lead_update()
RETURNS TRIGGER AS $$
DECLARE
  subscription RECORD;
  webhook_payload jsonb;
  new_assignee RECORD;
  old_assignee RECORD;
BEGIN
  -- Only queue webhooks if assignment changed
  IF OLD.assigned_to IS NOT DISTINCT FROM NEW.assigned_to THEN
    RETURN NEW;
  END IF;

  -- Get new assigned user details if exists
  IF NEW.assigned_to IS NOT NULL THEN
    SELECT 
      id,
      full_name,
      email
    INTO new_assignee
    FROM profiles
    WHERE id = NEW.assigned_to;
  END IF;

  -- Get old assigned user details if exists
  IF OLD.assigned_to IS NOT NULL THEN
    SELECT 
      id,
      full_name,
      email
    INTO old_assignee
    FROM profiles
    WHERE id = OLD.assigned_to;
  END IF;

  -- Build webhook payload
  webhook_payload := jsonb_build_object(
    'event_type', 'lead.reassigned',
    'event_id', gen_random_uuid(),
    'timestamp', NOW(),
    'organization_id', NEW.organization_id,
    'lead', jsonb_build_object(
      'id', NEW.id,
      'name', NEW.name,
      'first_name', NEW.first_name,
      'last_name', NEW.last_name,
      'email', NEW.email,
      'mobile_number', NEW.mobile_number,
      'company', NEW.company,
      'lead_value', NEW.lead_value,
      'channel', NEW.channel,
      'campaign_name', NEW.campaign_name,
      'country', NEW.country,
      'city', NEW.city,
      'state', NEW.state,
      'course', NEW.course,
      'specialization', NEW.specialization,
      'tags', NEW.tags
    ),
    'assignment_change', jsonb_build_object(
      'previous_assignee', CASE 
        WHEN old_assignee.id IS NOT NULL THEN
          jsonb_build_object(
            'id', old_assignee.id,
            'name', old_assignee.full_name,
            'email', old_assignee.email
          )
        ELSE NULL
      END,
      'new_assignee', CASE 
        WHEN new_assignee.id IS NOT NULL THEN
          jsonb_build_object(
            'id', new_assignee.id,
            'name', new_assignee.full_name,
            'email', new_assignee.email
          )
        ELSE NULL
      END,
      'changed_at', NOW()
    )
  );

  -- Find all active subscriptions for this event type
  FOR subscription IN
    SELECT 
      es.id as subscription_id,
      es.endpoint_id,
      es.filter_criteria,
      ep.endpoint_type,
      ep.endpoint_url,
      ep.is_active as endpoint_active
    FROM webhook_event_subscriptions es
    JOIN integration_endpoints ep ON es.endpoint_id = ep.id
    WHERE es.organization_id = NEW.organization_id
      AND es.event_type = 'lead.reassigned'
      AND es.is_active = true
      AND ep.is_active = true
  LOOP
    -- Insert into delivery queue
    INSERT INTO webhook_delivery_queue (
      organization_id,
      lead_id,
      endpoint_id,
      event_type,
      payload,
      status,
      retry_count,
      max_retries,
      next_retry_at
    ) VALUES (
      NEW.organization_id,
      NEW.id,
      subscription.endpoint_id,
      'lead.reassigned',
      webhook_payload,
      'pending',
      0,
      3,
      NOW()
    );
  END LOOP;

  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Create trigger for lead updates
DROP TRIGGER IF EXISTS trigger_queue_webhook_on_lead_updated ON leads;

CREATE TRIGGER trigger_queue_webhook_on_lead_updated
  AFTER UPDATE ON leads
  FOR EACH ROW
  EXECUTE FUNCTION queue_webhook_delivery_for_lead_update();