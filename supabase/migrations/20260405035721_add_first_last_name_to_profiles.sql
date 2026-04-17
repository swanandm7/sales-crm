/*
  # Add First Name and Last Name to Profiles

  1. Changes
    - Add `first_name` column to profiles table
    - Add `last_name` column to profiles table
    - Backfill existing full_name data by splitting into first and last name
    - Create trigger to auto-populate full_name from first_name + last_name

  2. Notes
    - Keeps full_name column for backward compatibility
    - Existing data will be split on first space
    - New records will auto-generate full_name
*/

-- Add first_name and last_name columns
ALTER TABLE profiles 
ADD COLUMN IF NOT EXISTS first_name text,
ADD COLUMN IF NOT EXISTS last_name text;

-- Backfill existing data (split full_name on first space)
UPDATE profiles
SET 
  first_name = CASE 
    WHEN position(' ' in full_name) > 0 THEN split_part(full_name, ' ', 1)
    ELSE full_name
  END,
  last_name = CASE 
    WHEN position(' ' in full_name) > 0 THEN substring(full_name from position(' ' in full_name) + 1)
    ELSE ''
  END
WHERE first_name IS NULL;

-- Create function to auto-update full_name
CREATE OR REPLACE FUNCTION update_full_name()
RETURNS TRIGGER AS $$
BEGIN
  NEW.full_name := TRIM(CONCAT(NEW.first_name, ' ', NEW.last_name));
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Create trigger to auto-update full_name
DROP TRIGGER IF EXISTS profiles_update_full_name ON profiles;
CREATE TRIGGER profiles_update_full_name
  BEFORE INSERT OR UPDATE OF first_name, last_name ON profiles
  FOR EACH ROW
  EXECUTE FUNCTION update_full_name();
