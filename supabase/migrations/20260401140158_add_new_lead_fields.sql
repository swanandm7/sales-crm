/*
  # Add New Lead Fields for Enhanced Lead Management

  ## Overview
  This migration adds new fields to the leads table to support a more comprehensive
  lead capture form with applicant details, family information, and enhanced source tracking.

  ## Changes

  ### 1. Lead Personal Information
  - `first_name` (text) - Applicant's first name
  - `last_name` (text) - Applicant's last name
  - `whatsapp_number` (text) - WhatsApp contact number
  - `university` (text) - University of interest
  - `course` (text) - Course name
  - `specialization` (text) - Course specialization

  ### 2. Family & Address Information
  - `father_name` (text) - Father's name
  - `mother_name` (text) - Mother's name
  - `address_line1` (text) - Address line 1
  - `address_line2` (text) - Address line 2
  - `state` (text) - State
  - `pincode` (text) - Postal/ZIP code

  ### 3. Enhanced Source Tracking
  - `campaign_id` (text) - Campaign identifier
  - `adgroup_id` (text) - Ad group identifier
  - `keyword` (text) - Marketing keyword

  ### 4. Indexes
  - Create indexes for frequently queried fields

  ### 5. Security
  - Maintains existing RLS policies
*/

-- Step 1: Add new personal information columns
DO $$ 
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns 
    WHERE table_name = 'leads' AND column_name = 'first_name'
  ) THEN
    ALTER TABLE leads ADD COLUMN first_name text;
  END IF;

  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns 
    WHERE table_name = 'leads' AND column_name = 'last_name'
  ) THEN
    ALTER TABLE leads ADD COLUMN last_name text;
  END IF;

  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns 
    WHERE table_name = 'leads' AND column_name = 'whatsapp_number'
  ) THEN
    ALTER TABLE leads ADD COLUMN whatsapp_number text;
  END IF;

  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns 
    WHERE table_name = 'leads' AND column_name = 'university'
  ) THEN
    ALTER TABLE leads ADD COLUMN university text;
  END IF;

  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns 
    WHERE table_name = 'leads' AND column_name = 'course'
  ) THEN
    ALTER TABLE leads ADD COLUMN course text;
  END IF;

  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns 
    WHERE table_name = 'leads' AND column_name = 'specialization'
  ) THEN
    ALTER TABLE leads ADD COLUMN specialization text;
  END IF;
END $$;

-- Step 2: Add family & address information columns
DO $$ 
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns 
    WHERE table_name = 'leads' AND column_name = 'father_name'
  ) THEN
    ALTER TABLE leads ADD COLUMN father_name text;
  END IF;

  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns 
    WHERE table_name = 'leads' AND column_name = 'mother_name'
  ) THEN
    ALTER TABLE leads ADD COLUMN mother_name text;
  END IF;

  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns 
    WHERE table_name = 'leads' AND column_name = 'address_line1'
  ) THEN
    ALTER TABLE leads ADD COLUMN address_line1 text;
  END IF;

  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns 
    WHERE table_name = 'leads' AND column_name = 'address_line2'
  ) THEN
    ALTER TABLE leads ADD COLUMN address_line2 text;
  END IF;

  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns 
    WHERE table_name = 'leads' AND column_name = 'state'
  ) THEN
    ALTER TABLE leads ADD COLUMN state text;
  END IF;

  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns 
    WHERE table_name = 'leads' AND column_name = 'pincode'
  ) THEN
    ALTER TABLE leads ADD COLUMN pincode text;
  END IF;
END $$;

-- Step 3: Add enhanced source tracking columns
DO $$ 
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns 
    WHERE table_name = 'leads' AND column_name = 'campaign_id'
  ) THEN
    ALTER TABLE leads ADD COLUMN campaign_id text;
  END IF;

  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns 
    WHERE table_name = 'leads' AND column_name = 'adgroup_id'
  ) THEN
    ALTER TABLE leads ADD COLUMN adgroup_id text;
  END IF;

  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns 
    WHERE table_name = 'leads' AND column_name = 'keyword'
  ) THEN
    ALTER TABLE leads ADD COLUMN keyword text;
  END IF;
END $$;

-- Step 4: Create indexes for new fields
CREATE INDEX IF NOT EXISTS idx_leads_first_name ON leads(first_name);
CREATE INDEX IF NOT EXISTS idx_leads_last_name ON leads(last_name);
CREATE INDEX IF NOT EXISTS idx_leads_university ON leads(university);
CREATE INDEX IF NOT EXISTS idx_leads_course ON leads(course);
CREATE INDEX IF NOT EXISTS idx_leads_state ON leads(state);
CREATE INDEX IF NOT EXISTS idx_leads_pincode ON leads(pincode);
CREATE INDEX IF NOT EXISTS idx_leads_campaign_id ON leads(campaign_id);
CREATE INDEX IF NOT EXISTS idx_leads_keyword ON leads(keyword);

-- Step 5: Migrate existing 'name' field to first_name and last_name where needed
UPDATE leads 
SET first_name = SPLIT_PART(name, ' ', 1),
    last_name = CASE 
      WHEN ARRAY_LENGTH(STRING_TO_ARRAY(name, ' '), 1) > 1 
      THEN SUBSTRING(name FROM POSITION(' ' IN name) + 1)
      ELSE ''
    END
WHERE first_name IS NULL AND name IS NOT NULL;
