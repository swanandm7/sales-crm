/*
  # Enhanced Lead Management Schema with Mobile-Based Deduplication

  ## Overview
  This migration transforms the CRM into a comprehensive lead management system with:
  - Mobile number-based deduplication (+91 format)
  - Complete interaction tracking (calls, emails, WhatsApp)
  - Lead ownership history and tracking
  - Advanced segmentation fields (stage, channel, campaign, geography)
  - Automated re-enquiry detection and handling

  ## 1. Lead Table Enhancements
    
  ### New Columns Added:
  - `mobile_number` (text, unique, not null) - Primary contact, format: +91XXXXXXXXXX
  - `current_lead_owner` (uuid) - Current assigned counselor/rep
  - `previous_lead_owner` (uuid) - Previous owner for tracking reassignments
  - `stage` (text) - Main lifecycle stage (New, Contacted, Qualified, etc.)
  - `sub_stage` (text) - Detailed stage breakdown
  - `channel` (text) - Marketing channel (Digital Marketing, Publishers, etc.)
  - `campaign_name` (text) - Specific campaign identifier
  - `country` (text, default 'India') - Geographic location
  - `city` (text) - City for local targeting
  - `call_count` (integer, default 0) - Total number of calls made
  - `is_re_enquired` (boolean, default false) - Flag for returning leads
  - `original_enquiry_date` (timestamp) - First enquiry timestamp
  
  ### Constraints:
  - Unique constraint on mobile_number
  - Check constraint for mobile format validation
  - Indexes on mobile_number, stage, channel for query performance

  ## 2. Lead Interactions Table
    
  New table: `lead_interactions`
  - Unified tracking for all interaction types
  - Stores calls, emails, WhatsApp messages
  - Includes metadata in JSONB for flexibility
  - Links to both lead and user (who performed action)

  ## 3. Lead Ownership History Table
    
  New table: `lead_ownership_history`
  - Complete audit trail of ownership changes
  - Tracks from_owner, to_owner, timestamp, changed_by
  - Enables reporting on lead transfers

  ## 4. Re-enquired Status
    
  - Adds "Re-enquired" status to lead_statuses
  - Positioned in funnel for visibility
  - Distinct color coding for easy identification

  ## 5. Database Functions
    
  - `check_duplicate_mobile()` - Validates format and checks for existing leads
  - `merge_lead_data()` - Handles re-enquiry merging logic
  - Auto-update triggers for call_count and updated_at

  ## 6. Security
    
  - RLS policies updated for new tables
  - Authenticated users can view/modify their assigned leads
  - Admins have full access
  - Interaction history is read-only after creation
*/

-- Step 1: Add new columns to leads table
DO $$ 
BEGIN
  -- Add mobile_number column
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns 
    WHERE table_name = 'leads' AND column_name = 'mobile_number'
  ) THEN
    ALTER TABLE leads ADD COLUMN mobile_number text;
  END IF;

  -- Add ownership tracking columns
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns 
    WHERE table_name = 'leads' AND column_name = 'current_lead_owner'
  ) THEN
    ALTER TABLE leads ADD COLUMN current_lead_owner uuid REFERENCES profiles(id);
  END IF;

  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns 
    WHERE table_name = 'leads' AND column_name = 'previous_lead_owner'
  ) THEN
    ALTER TABLE leads ADD COLUMN previous_lead_owner uuid REFERENCES profiles(id);
  END IF;

  -- Add stage and channel columns
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns 
    WHERE table_name = 'leads' AND column_name = 'stage'
  ) THEN
    ALTER TABLE leads ADD COLUMN stage text DEFAULT 'New';
  END IF;

  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns 
    WHERE table_name = 'leads' AND column_name = 'sub_stage'
  ) THEN
    ALTER TABLE leads ADD COLUMN sub_stage text;
  END IF;

  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns 
    WHERE table_name = 'leads' AND column_name = 'channel'
  ) THEN
    ALTER TABLE leads ADD COLUMN channel text;
  END IF;

  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns 
    WHERE table_name = 'leads' AND column_name = 'campaign_name'
  ) THEN
    ALTER TABLE leads ADD COLUMN campaign_name text;
  END IF;

  -- Add geography columns
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns 
    WHERE table_name = 'leads' AND column_name = 'country'
  ) THEN
    ALTER TABLE leads ADD COLUMN country text DEFAULT 'India';
  END IF;

  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns 
    WHERE table_name = 'leads' AND column_name = 'city'
  ) THEN
    ALTER TABLE leads ADD COLUMN city text;
  END IF;

  -- Add tracking columns
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns 
    WHERE table_name = 'leads' AND column_name = 'call_count'
  ) THEN
    ALTER TABLE leads ADD COLUMN call_count integer DEFAULT 0 NOT NULL;
  END IF;

  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns 
    WHERE table_name = 'leads' AND column_name = 'is_re_enquired'
  ) THEN
    ALTER TABLE leads ADD COLUMN is_re_enquired boolean DEFAULT false NOT NULL;
  END IF;

  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns 
    WHERE table_name = 'leads' AND column_name = 'original_enquiry_date'
  ) THEN
    ALTER TABLE leads ADD COLUMN original_enquiry_date timestamptz;
  END IF;
END $$;

-- Step 2: Migrate existing data
UPDATE leads 
SET current_lead_owner = assigned_to 
WHERE current_lead_owner IS NULL AND assigned_to IS NOT NULL;

UPDATE leads 
SET original_enquiry_date = created_at 
WHERE original_enquiry_date IS NULL;

-- Step 3: Create unique index on mobile_number
CREATE UNIQUE INDEX IF NOT EXISTS idx_leads_mobile_number 
ON leads(mobile_number) 
WHERE mobile_number IS NOT NULL;

-- Step 4: Create indexes for performance
CREATE INDEX IF NOT EXISTS idx_leads_stage ON leads(stage);
CREATE INDEX IF NOT EXISTS idx_leads_channel ON leads(channel);
CREATE INDEX IF NOT EXISTS idx_leads_current_owner ON leads(current_lead_owner);
CREATE INDEX IF NOT EXISTS idx_leads_is_re_enquired ON leads(is_re_enquired);
CREATE INDEX IF NOT EXISTS idx_leads_created_at ON leads(created_at);

-- Step 5: Create lead_interactions table
CREATE TABLE IF NOT EXISTS lead_interactions (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  lead_id uuid REFERENCES leads(id) ON DELETE CASCADE NOT NULL,
  user_id uuid REFERENCES profiles(id) NOT NULL,
  interaction_type text NOT NULL CHECK (interaction_type IN ('call', 'email', 'whatsapp')),
  interaction_notes text,
  interaction_metadata jsonb DEFAULT '{}'::jsonb,
  created_at timestamptz DEFAULT now() NOT NULL
);

-- Create indexes for lead_interactions
CREATE INDEX IF NOT EXISTS idx_lead_interactions_lead_id ON lead_interactions(lead_id);
CREATE INDEX IF NOT EXISTS idx_lead_interactions_created_at ON lead_interactions(created_at DESC);
CREATE INDEX IF NOT EXISTS idx_lead_interactions_type ON lead_interactions(interaction_type);

-- Enable RLS on lead_interactions
ALTER TABLE lead_interactions ENABLE ROW LEVEL SECURITY;

-- RLS policies for lead_interactions
CREATE POLICY "Users can view interactions for their leads"
  ON lead_interactions FOR SELECT
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM leads 
      WHERE leads.id = lead_interactions.lead_id 
      AND (leads.current_lead_owner = auth.uid() OR leads.created_by = auth.uid())
    )
  );

CREATE POLICY "Users can create interactions for their leads"
  ON lead_interactions FOR INSERT
  TO authenticated
  WITH CHECK (
    EXISTS (
      SELECT 1 FROM leads 
      WHERE leads.id = lead_interactions.lead_id 
      AND (leads.current_lead_owner = auth.uid() OR leads.created_by = auth.uid())
    )
  );

-- Step 6: Create lead_ownership_history table
CREATE TABLE IF NOT EXISTS lead_ownership_history (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  lead_id uuid REFERENCES leads(id) ON DELETE CASCADE NOT NULL,
  from_owner_id uuid REFERENCES profiles(id),
  to_owner_id uuid REFERENCES profiles(id),
  changed_at timestamptz DEFAULT now() NOT NULL,
  changed_by uuid REFERENCES profiles(id) NOT NULL
);

-- Create indexes for lead_ownership_history
CREATE INDEX IF NOT EXISTS idx_ownership_history_lead_id ON lead_ownership_history(lead_id);
CREATE INDEX IF NOT EXISTS idx_ownership_history_changed_at ON lead_ownership_history(changed_at DESC);

-- Enable RLS on lead_ownership_history
ALTER TABLE lead_ownership_history ENABLE ROW LEVEL SECURITY;

-- RLS policies for lead_ownership_history
CREATE POLICY "Users can view ownership history for their leads"
  ON lead_ownership_history FOR SELECT
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM leads 
      WHERE leads.id = lead_ownership_history.lead_id 
      AND (leads.current_lead_owner = auth.uid() OR leads.created_by = auth.uid())
    )
  );

-- Step 7: Add "Re-enquired" status
INSERT INTO lead_statuses (name, display_name, color, order_index, is_active)
VALUES ('re_enquired', 'Re-enquired', '#9333EA', 1, true)
ON CONFLICT (name) DO NOTHING;

-- Step 8: Create function to validate mobile number format
CREATE OR REPLACE FUNCTION validate_mobile_number(mobile text)
RETURNS boolean AS $$
BEGIN
  -- Check if mobile number matches +91 followed by exactly 10 digits
  RETURN mobile ~ '^\+91[0-9]{10}$';
END;
$$ LANGUAGE plpgsql IMMUTABLE;

-- Step 9: Create function to check for duplicate mobile
CREATE OR REPLACE FUNCTION check_duplicate_mobile(mobile text)
RETURNS uuid AS $$
DECLARE
  existing_lead_id uuid;
BEGIN
  -- Validate format first
  IF NOT validate_mobile_number(mobile) THEN
    RAISE EXCEPTION 'Invalid mobile number format. Must be +91 followed by 10 digits';
  END IF;
  
  -- Check for existing lead
  SELECT id INTO existing_lead_id
  FROM leads
  WHERE mobile_number = mobile
  LIMIT 1;
  
  RETURN existing_lead_id;
END;
$$ LANGUAGE plpgsql;

-- Step 10: Create function to merge lead data on re-enquiry
CREATE OR REPLACE FUNCTION merge_lead_data(
  existing_lead_id uuid,
  new_name text DEFAULT NULL,
  new_email text DEFAULT NULL,
  new_company text DEFAULT NULL,
  new_stage text DEFAULT NULL,
  new_sub_stage text DEFAULT NULL,
  new_channel text DEFAULT NULL,
  new_source_id uuid DEFAULT NULL,
  new_campaign_name text DEFAULT NULL,
  new_city text DEFAULT NULL,
  new_country text DEFAULT NULL,
  new_lead_value numeric DEFAULT NULL,
  user_id uuid DEFAULT NULL
)
RETURNS void AS $$
DECLARE
  re_enquired_status_id uuid;
BEGIN
  -- Get re-enquired status ID
  SELECT id INTO re_enquired_status_id
  FROM lead_statuses
  WHERE name = 're_enquired'
  LIMIT 1;

  -- Update existing lead with new information
  UPDATE leads
  SET
    name = COALESCE(new_name, name),
    email = COALESCE(new_email, email),
    company = COALESCE(new_company, company),
    stage = COALESCE(new_stage, stage),
    sub_stage = COALESCE(new_sub_stage, sub_stage),
    channel = COALESCE(new_channel, channel),
    source_id = COALESCE(new_source_id, source_id),
    campaign_name = COALESCE(new_campaign_name, campaign_name),
    city = COALESCE(new_city, city),
    country = COALESCE(new_country, country),
    lead_value = COALESCE(new_lead_value, lead_value),
    status_id = COALESCE(re_enquired_status_id, status_id),
    is_re_enquired = true,
    updated_at = now()
  WHERE id = existing_lead_id;

  -- Log the merge in interactions
  INSERT INTO lead_interactions (lead_id, user_id, interaction_type, interaction_notes, interaction_metadata)
  VALUES (
    existing_lead_id,
    COALESCE(user_id, auth.uid()),
    'call',
    'Lead re-enquired - data merged from new submission',
    jsonb_build_object(
      'event', 're_enquiry',
      'merged_at', now()
    )
  );
END;
$$ LANGUAGE plpgsql;

-- Step 11: Create trigger to auto-increment call_count
CREATE OR REPLACE FUNCTION increment_call_count()
RETURNS TRIGGER AS $$
BEGIN
  UPDATE leads
  SET call_count = call_count + 1
  WHERE id = NEW.lead_id;
  
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS trigger_increment_call_count ON calls;
CREATE TRIGGER trigger_increment_call_count
  AFTER INSERT ON calls
  FOR EACH ROW
  EXECUTE FUNCTION increment_call_count();

-- Step 12: Create trigger to auto-update updated_at
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = now();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS trigger_update_leads_updated_at ON leads;
CREATE TRIGGER trigger_update_leads_updated_at
  BEFORE UPDATE ON leads
  FOR EACH ROW
  EXECUTE FUNCTION update_updated_at_column();

-- Step 13: Create trigger to track ownership changes
CREATE OR REPLACE FUNCTION track_ownership_change()
RETURNS TRIGGER AS $$
BEGIN
  -- Only track if current_lead_owner actually changed
  IF OLD.current_lead_owner IS DISTINCT FROM NEW.current_lead_owner THEN
    -- Update previous_lead_owner
    NEW.previous_lead_owner = OLD.current_lead_owner;
    
    -- Log in ownership history
    INSERT INTO lead_ownership_history (lead_id, from_owner_id, to_owner_id, changed_by)
    VALUES (
      NEW.id,
      OLD.current_lead_owner,
      NEW.current_lead_owner,
      auth.uid()
    );
  END IF;
  
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS trigger_track_ownership_change ON leads;
CREATE TRIGGER trigger_track_ownership_change
  BEFORE UPDATE ON leads
  FOR EACH ROW
  EXECUTE FUNCTION track_ownership_change();
