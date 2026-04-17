/*
  # Seed Webhook Source Templates

  ## Purpose
  Creates preset lead source configurations with field mappings for common
  lead sources like Facebook Ads, Google Ads, and generic web forms.

  ## Templates Created
  1. Facebook Lead Ads - Standard Facebook lead form field mapping
  2. Google Ads - Google Ads lead extension field mapping
  3. Website Contact Form - Generic website form mapping
  4. LinkedIn Lead Gen - LinkedIn lead gen forms mapping
  5. HubSpot - HubSpot CRM export format

  ## Note
  These are system templates and will be available to all organizations.
  Organizations can customize or create their own source mappings.
*/

-- Insert system-level webhook source templates
-- These will be copied to organizations when they enable webhooks

-- Create a function to seed webhook sources for an organization
CREATE OR REPLACE FUNCTION seed_webhook_sources_for_org(org_id uuid)
RETURNS void AS $$
BEGIN
  -- Facebook Lead Ads Template
  INSERT INTO webhook_sources (organization_id, source_name, source_type, field_mappings, is_active)
  VALUES (
    org_id,
    'Facebook Lead Ads',
    'facebook_ads',
    jsonb_build_object(
      'name', 'full_name',
      'first_name', 'first_name',
      'last_name', 'last_name',
      'email', 'email',
      'mobile_number', 'phone_number',
      'company', 'company_name',
      'city', 'city',
      'state', 'state',
      'country', 'country',
      'course', 'course_of_interest',
      'specialization', 'specialization',
      'campaign_name', 'campaign_name',
      'campaign_id', 'campaign_id',
      'adgroup_id', 'adset_id'
    ),
    true
  )
  ON CONFLICT (organization_id, source_name) DO NOTHING;

  -- Google Ads Template
  INSERT INTO webhook_sources (organization_id, source_name, source_type, field_mappings, is_active)
  VALUES (
    org_id,
    'Google Ads',
    'google_ads',
    jsonb_build_object(
      'name', 'Full_Name',
      'first_name', 'First_Name',
      'last_name', 'Last_Name',
      'email', 'Email',
      'mobile_number', 'Phone_Number',
      'company', 'Company',
      'city', 'City',
      'state', 'State',
      'country', 'Country',
      'course', 'Course_Interest',
      'specialization', 'Specialization',
      'campaign_name', 'Campaign_Name',
      'campaign_id', 'Campaign_ID',
      'adgroup_id', 'AdGroup_ID',
      'keyword', 'Keyword'
    ),
    true
  )
  ON CONFLICT (organization_id, source_name) DO NOTHING;

  -- Website Contact Form Template
  INSERT INTO webhook_sources (organization_id, source_name, source_type, field_mappings, is_active)
  VALUES (
    org_id,
    'Website Contact Form',
    'website_form',
    jsonb_build_object(
      'name', 'name',
      'first_name', 'firstName',
      'last_name', 'lastName',
      'email', 'email',
      'mobile_number', 'phone',
      'company', 'company',
      'city', 'city',
      'state', 'state',
      'country', 'country',
      'course', 'program',
      'specialization', 'specialization',
      'address_line1', 'address'
    ),
    true
  )
  ON CONFLICT (organization_id, source_name) DO NOTHING;

  -- LinkedIn Lead Gen Template
  INSERT INTO webhook_sources (organization_id, source_name, source_type, field_mappings, is_active)
  VALUES (
    org_id,
    'LinkedIn Lead Gen',
    'linkedin',
    jsonb_build_object(
      'first_name', 'FirstName',
      'last_name', 'LastName',
      'email', 'Email',
      'mobile_number', 'PhoneNumber',
      'company', 'Company',
      'city', 'City',
      'state', 'State',
      'country', 'Country',
      'campaign_name', 'CampaignName'
    ),
    true
  )
  ON CONFLICT (organization_id, source_name) DO NOTHING;

  -- HubSpot Template
  INSERT INTO webhook_sources (organization_id, source_name, source_type, field_mappings, is_active)
  VALUES (
    org_id,
    'HubSpot',
    'hubspot',
    jsonb_build_object(
      'first_name', 'firstname',
      'last_name', 'lastname',
      'email', 'email',
      'mobile_number', 'phone',
      'company', 'company',
      'city', 'city',
      'state', 'state',
      'country', 'country',
      'address_line1', 'address',
      'pincode', 'zip'
    ),
    true
  )
  ON CONFLICT (organization_id, source_name) DO NOTHING;

  -- Zoho CRM Template
  INSERT INTO webhook_sources (organization_id, source_name, source_type, field_mappings, is_active)
  VALUES (
    org_id,
    'Zoho CRM',
    'zoho',
    jsonb_build_object(
      'first_name', 'First Name',
      'last_name', 'Last Name',
      'email', 'Email',
      'mobile_number', 'Mobile',
      'company', 'Company',
      'city', 'City',
      'state', 'State',
      'country', 'Country',
      'address_line1', 'Street',
      'pincode', 'Zip Code'
    ),
    true
  )
  ON CONFLICT (organization_id, source_name) DO NOTHING;

END;
$$ LANGUAGE plpgsql;

-- Seed webhook sources for all existing organizations
DO $$
DECLARE
  org RECORD;
BEGIN
  FOR org IN SELECT id FROM organizations
  LOOP
    PERFORM seed_webhook_sources_for_org(org.id);
  END LOOP;
END $$;