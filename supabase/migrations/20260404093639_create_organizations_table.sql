/*
  # Create Organizations Table for Multi-Tenant CRM

  1. New Tables
    - `organizations`
      - `id` (uuid, primary key) - Unique organization identifier
      - `name` (text) - Organization display name
      - `slug` (text, unique) - URL-friendly identifier
      - `owner_id` (uuid) - Reference to profiles table (organization owner)
      - `status` (enum) - Organization status: active, suspended
      - `tier` (text) - Subscription tier: starter, pro, enterprise, custom
      - `max_users` (integer, nullable) - Maximum allowed users (null = unlimited)
      - `logo_url` (text, nullable) - Organization logo image URL
      - `settings` (jsonb) - Organization-specific settings
      - `created_at` (timestamptz) - Creation timestamp
      - `updated_at` (timestamptz) - Last update timestamp

  2. Security
    - Enable RLS on `organizations` table
    - Policies will be added after organization_members table is created

  3. Features
    - Automatic max_users calculation based on tier
    - Tier options: Starter (10), Pro (50), Enterprise (500), Custom (manual)
    - Trigger to auto-update max_users when tier changes
*/

-- Create enum for organization status
DO $$ BEGIN
  CREATE TYPE organization_status AS ENUM ('active', 'suspended');
EXCEPTION
  WHEN duplicate_object THEN null;
END $$;

-- Create organizations table
CREATE TABLE IF NOT EXISTS organizations (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  name text NOT NULL,
  slug text UNIQUE NOT NULL,
  owner_id uuid REFERENCES profiles(id) ON DELETE SET NULL,
  status organization_status NOT NULL DEFAULT 'active',
  tier text NOT NULL DEFAULT 'starter' CHECK (tier IN ('starter', 'pro', 'enterprise', 'custom')),
  max_users integer,
  logo_url text,
  settings jsonb DEFAULT '{
    "invitation_expiry_days": 7,
    "allow_team_lead_invites": false,
    "branding": {},
    "features": {},
    "notifications": {
      "user_joined": true,
      "user_limit_warning": true,
      "invitation_expired": true
    }
  }'::jsonb,
  created_at timestamptz DEFAULT now(),
  updated_at timestamptz DEFAULT now()
);

-- Create function to auto-calculate max_users based on tier
CREATE OR REPLACE FUNCTION calculate_max_users_from_tier()
RETURNS TRIGGER AS $$
BEGIN
  IF NEW.tier = 'starter' THEN
    NEW.max_users := 10;
  ELSIF NEW.tier = 'pro' THEN
    NEW.max_users := 50;
  ELSIF NEW.tier = 'enterprise' THEN
    NEW.max_users := 500;
  END IF;
  -- For 'custom' tier, max_users is set manually and not overridden
  
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Create trigger to auto-update max_users when tier changes
DROP TRIGGER IF EXISTS set_max_users_from_tier ON organizations;
CREATE TRIGGER set_max_users_from_tier
  BEFORE INSERT OR UPDATE OF tier ON organizations
  FOR EACH ROW
  WHEN (NEW.tier != 'custom')
  EXECUTE FUNCTION calculate_max_users_from_tier();

-- Create trigger to update updated_at timestamp
DROP TRIGGER IF EXISTS update_organizations_updated_at ON organizations;
CREATE TRIGGER update_organizations_updated_at
  BEFORE UPDATE ON organizations
  FOR EACH ROW
  EXECUTE FUNCTION update_updated_at_column();

-- Create index on slug for fast lookups
CREATE INDEX IF NOT EXISTS idx_organizations_slug ON organizations(slug);

-- Create index on owner_id
CREATE INDEX IF NOT EXISTS idx_organizations_owner_id ON organizations(owner_id);

-- Create index on status for filtering
CREATE INDEX IF NOT EXISTS idx_organizations_status ON organizations(status);

-- Enable RLS (policies will be added in next migration)
ALTER TABLE organizations ENABLE ROW LEVEL SECURITY;