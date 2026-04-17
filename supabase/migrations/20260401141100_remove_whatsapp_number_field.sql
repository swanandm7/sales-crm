/*
  # Remove WhatsApp Number Field

  ## Overview
  This migration removes the whatsapp_number column from the leads table as it is no longer needed.

  ## Changes
  1. Drop whatsapp_number column from leads table
  2. Drop associated index if exists

  ## Notes
  - This is a non-destructive operation as the field is being removed from the application
  - Data in this column will be permanently deleted
*/

-- Step 1: Drop the index if it exists
DROP INDEX IF EXISTS idx_leads_whatsapp_number;

-- Step 2: Drop the whatsapp_number column
DO $$ 
BEGIN
  IF EXISTS (
    SELECT 1 FROM information_schema.columns 
    WHERE table_name = 'leads' AND column_name = 'whatsapp_number'
  ) THEN
    ALTER TABLE leads DROP COLUMN whatsapp_number;
  END IF;
END $$;
