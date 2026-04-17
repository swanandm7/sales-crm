/*
  # Add Mobile Number to Profiles Table

  1. Changes
    - Add `mobile_number` column to `profiles` table (nullable text field)
    - Add non-unique index on `mobile_number` for faster lookups
    - Email remains the unique identifier for CRM users

  2. Notes
    - Mobile number is optional and not enforced to be unique
    - Multiple users can have the same mobile number across different organizations
    - Index improves query performance for mobile number searches
*/

-- Add mobile_number column to profiles table
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns
    WHERE table_name = 'profiles' AND column_name = 'mobile_number'
  ) THEN
    ALTER TABLE profiles ADD COLUMN mobile_number text;
  END IF;
END $$;

-- Add index on mobile_number for faster lookups (non-unique)
CREATE INDEX IF NOT EXISTS idx_profiles_mobile_number ON profiles(mobile_number);
