/*
  # Hierarchical Lead Status System with Sub-Statuses

  ## Overview
  This migration transforms the lead status system into a hierarchical structure
  that supports main statuses and their associated sub-statuses based on the
  comprehensive lead lifecycle management requirements.

  ## Changes

  ### 1. Lead Statuses Table Enhancements
  - `parent_status_id` (uuid, nullable) - References parent status for sub-statuses
  - `status_type` (text) - Either 'main' or 'sub' to distinguish hierarchy level
  - `requires_sub_status` (boolean) - Indicates if status requires sub-status selection

  ### 2. Lead Table Updates
  - `sub_status_id` (uuid, nullable) - References the selected sub-status
  - Foreign key constraints to ensure data integrity

  ### 3. Status Data Population
  Populates all main statuses and their sub-statuses:
  
  **Main Statuses:**
  - 1- New Lead (Untouched, Switched Off, Not Reachable)
  - 02-No Response (Ringing-Not picked, Follow up)
  - 03-Followup (Call back, Warm, Cold)
  - 04-Interested (Hot, Documents Pending, Documents Uploaded, Document Discrepancy)
  - Registration Done (Registration Fee Paid, Annual fee paid, Full course fee paid, Loan Applied, Reference received)
  - Admission Done (Sem fee paid, Language barrier, Test, Duplicate)
  - 05-Junk (Invalid Number, Taken Admission Elsewhere, Not Eligible, Financial Issue, Contact Next year, Bad lead quality, Did not enquire)
  - 06-Closed (Not Interested, Not eligible for incentive)
  - Post Sales (Incentive Paid)

  ### 4. Database Functions
  - Validation function to ensure sub-status matches parent status
  - Helper functions for querying hierarchical status data

  ### 5. Security
  - Maintains existing RLS policies
  - Ensures data integrity through constraints
*/

-- Step 1: Add new columns to lead_statuses table
DO $$ 
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns 
    WHERE table_name = 'lead_statuses' AND column_name = 'parent_status_id'
  ) THEN
    ALTER TABLE lead_statuses ADD COLUMN parent_status_id uuid REFERENCES lead_statuses(id) ON DELETE CASCADE;
  END IF;

  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns 
    WHERE table_name = 'lead_statuses' AND column_name = 'status_type'
  ) THEN
    ALTER TABLE lead_statuses ADD COLUMN status_type text DEFAULT 'main' CHECK (status_type IN ('main', 'sub'));
  END IF;

  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns 
    WHERE table_name = 'lead_statuses' AND column_name = 'requires_sub_status'
  ) THEN
    ALTER TABLE lead_statuses ADD COLUMN requires_sub_status boolean DEFAULT false;
  END IF;
END $$;

-- Step 2: Mark existing statuses as main statuses
UPDATE lead_statuses SET status_type = 'main' WHERE status_type IS NULL OR status_type = 'main';

-- Step 3: Clear existing data and repopulate with hierarchical structure
TRUNCATE TABLE lead_statuses CASCADE;

-- Step 4: Insert main statuses with proper order and configuration
INSERT INTO lead_statuses (name, display_name, color, order_index, status_type, requires_sub_status, is_active) VALUES
  ('new_lead', '1- New Lead', '#3b82f6', 1, 'main', true, true),
  ('no_response', '02-No Response', '#f59e0b', 2, 'main', true, true),
  ('followup', '03-Followup', '#8b5cf6', 3, 'main', true, true),
  ('interested', '04-Interested', '#10b981', 4, 'main', true, true),
  ('registration_done', 'Registration Done', '#06b6d4', 5, 'main', true, true),
  ('admission_done', 'Admission Done', '#059669', 6, 'main', true, true),
  ('junk', '05-Junk', '#dc2626', 7, 'main', true, true),
  ('closed', '06-Closed', '#4b5563', 8, 'main', true, true),
  ('post_sales', 'Post Sales', '#14b8a6', 9, 'main', true, true);

-- Step 5: Insert sub-statuses for each main status
-- 1- New Lead sub-statuses
INSERT INTO lead_statuses (name, display_name, color, order_index, status_type, parent_status_id, is_active)
SELECT 'new_lead_untouched', 'Untouched', '#93c5fd', 1, 'sub', id, true FROM lead_statuses WHERE name = 'new_lead';

INSERT INTO lead_statuses (name, display_name, color, order_index, status_type, parent_status_id, is_active)
SELECT 'new_lead_switched_off', 'Switched Off', '#7dd3fc', 2, 'sub', id, true FROM lead_statuses WHERE name = 'new_lead';

INSERT INTO lead_statuses (name, display_name, color, order_index, status_type, parent_status_id, is_active)
SELECT 'new_lead_not_reachable', 'Not Reachable', '#60a5fa', 3, 'sub', id, true FROM lead_statuses WHERE name = 'new_lead';

-- 02-No Response sub-statuses
INSERT INTO lead_statuses (name, display_name, color, order_index, status_type, parent_status_id, is_active)
SELECT 'no_response_ringing', 'Ringing-Not picked', '#fcd34d', 1, 'sub', id, true FROM lead_statuses WHERE name = 'no_response';

INSERT INTO lead_statuses (name, display_name, color, order_index, status_type, parent_status_id, is_active)
SELECT 'no_response_follow_up', 'Follow up', '#fbbf24', 2, 'sub', id, true FROM lead_statuses WHERE name = 'no_response';

-- 03-Followup sub-statuses
INSERT INTO lead_statuses (name, display_name, color, order_index, status_type, parent_status_id, is_active)
SELECT 'followup_call_back', 'Call back', '#c4b5fd', 1, 'sub', id, true FROM lead_statuses WHERE name = 'followup';

INSERT INTO lead_statuses (name, display_name, color, order_index, status_type, parent_status_id, is_active)
SELECT 'followup_warm', 'Warm', '#a78bfa', 2, 'sub', id, true FROM lead_statuses WHERE name = 'followup';

INSERT INTO lead_statuses (name, display_name, color, order_index, status_type, parent_status_id, is_active)
SELECT 'followup_cold', 'Cold', '#8b5cf6', 3, 'sub', id, true FROM lead_statuses WHERE name = 'followup';

-- 04-Interested sub-statuses
INSERT INTO lead_statuses (name, display_name, color, order_index, status_type, parent_status_id, is_active)
SELECT 'interested_hot', 'Hot', '#6ee7b7', 1, 'sub', id, true FROM lead_statuses WHERE name = 'interested';

INSERT INTO lead_statuses (name, display_name, color, order_index, status_type, parent_status_id, is_active)
SELECT 'interested_documents_pending', 'Documents Pending', '#5eead4', 2, 'sub', id, true FROM lead_statuses WHERE name = 'interested';

INSERT INTO lead_statuses (name, display_name, color, order_index, status_type, parent_status_id, is_active)
SELECT 'interested_documents_uploaded', 'Documents Uploaded', '#34d399', 3, 'sub', id, true FROM lead_statuses WHERE name = 'interested';

INSERT INTO lead_statuses (name, display_name, color, order_index, status_type, parent_status_id, is_active)
SELECT 'interested_document_discrepancy', 'Document Discrepancy', '#10b981', 4, 'sub', id, true FROM lead_statuses WHERE name = 'interested';

-- Registration Done sub-statuses
INSERT INTO lead_statuses (name, display_name, color, order_index, status_type, parent_status_id, is_active)
SELECT 'registration_fee_paid', 'Registration Fee Paid', '#67e8f9', 1, 'sub', id, true FROM lead_statuses WHERE name = 'registration_done';

INSERT INTO lead_statuses (name, display_name, color, order_index, status_type, parent_status_id, is_active)
SELECT 'registration_annual_fee_paid', 'Annual fee paid', '#22d3ee', 2, 'sub', id, true FROM lead_statuses WHERE name = 'registration_done';

INSERT INTO lead_statuses (name, display_name, color, order_index, status_type, parent_status_id, is_active)
SELECT 'registration_full_course_fee_paid', 'Full course fee paid', '#06b6d4', 3, 'sub', id, true FROM lead_statuses WHERE name = 'registration_done';

INSERT INTO lead_statuses (name, display_name, color, order_index, status_type, parent_status_id, is_active)
SELECT 'registration_loan_applied', 'Loan Applied', '#0891b2', 4, 'sub', id, true FROM lead_statuses WHERE name = 'registration_done';

INSERT INTO lead_statuses (name, display_name, color, order_index, status_type, parent_status_id, is_active)
SELECT 'registration_reference_received', 'Reference received', '#0e7490', 5, 'sub', id, true FROM lead_statuses WHERE name = 'registration_done';

-- Admission Done sub-statuses
INSERT INTO lead_statuses (name, display_name, color, order_index, status_type, parent_status_id, is_active)
SELECT 'admission_sem_fee_paid', 'Sem fee paid', '#6ee7b7', 1, 'sub', id, true FROM lead_statuses WHERE name = 'admission_done';

INSERT INTO lead_statuses (name, display_name, color, order_index, status_type, parent_status_id, is_active)
SELECT 'admission_language_barrier', 'Language barrier', '#34d399', 2, 'sub', id, true FROM lead_statuses WHERE name = 'admission_done';

INSERT INTO lead_statuses (name, display_name, color, order_index, status_type, parent_status_id, is_active)
SELECT 'admission_test', 'Test', '#10b981', 3, 'sub', id, true FROM lead_statuses WHERE name = 'admission_done';

INSERT INTO lead_statuses (name, display_name, color, order_index, status_type, parent_status_id, is_active)
SELECT 'admission_duplicate', 'Duplicate', '#059669', 4, 'sub', id, true FROM lead_statuses WHERE name = 'admission_done';

-- 05-Junk sub-statuses
INSERT INTO lead_statuses (name, display_name, color, order_index, status_type, parent_status_id, is_active)
SELECT 'junk_invalid_number', 'Invalid Number', '#fca5a5', 1, 'sub', id, true FROM lead_statuses WHERE name = 'junk';

INSERT INTO lead_statuses (name, display_name, color, order_index, status_type, parent_status_id, is_active)
SELECT 'junk_taken_admission_elsewhere', 'Taken Admission Elsewhere', '#f87171', 2, 'sub', id, true FROM lead_statuses WHERE name = 'junk';

INSERT INTO lead_statuses (name, display_name, color, order_index, status_type, parent_status_id, is_active)
SELECT 'junk_not_eligible', 'Not Eligible', '#ef4444', 3, 'sub', id, true FROM lead_statuses WHERE name = 'junk';

INSERT INTO lead_statuses (name, display_name, color, order_index, status_type, parent_status_id, is_active)
SELECT 'junk_financial_issue', 'Financial Issue', '#dc2626', 4, 'sub', id, true FROM lead_statuses WHERE name = 'junk';

INSERT INTO lead_statuses (name, display_name, color, order_index, status_type, parent_status_id, is_active)
SELECT 'junk_contact_next_year', 'Contact Next year', '#b91c1c', 5, 'sub', id, true FROM lead_statuses WHERE name = 'junk';

INSERT INTO lead_statuses (name, display_name, color, order_index, status_type, parent_status_id, is_active)
SELECT 'junk_bad_lead_quality', 'Bad lead quality', '#991b1b', 6, 'sub', id, true FROM lead_statuses WHERE name = 'junk';

INSERT INTO lead_statuses (name, display_name, color, order_index, status_type, parent_status_id, is_active)
SELECT 'junk_did_not_enquire', 'Did not enquire', '#7f1d1d', 7, 'sub', id, true FROM lead_statuses WHERE name = 'junk';

-- 06-Closed sub-statuses
INSERT INTO lead_statuses (name, display_name, color, order_index, status_type, parent_status_id, is_active)
SELECT 'closed_not_interested', 'Not Interested', '#9ca3af', 1, 'sub', id, true FROM lead_statuses WHERE name = 'closed';

INSERT INTO lead_statuses (name, display_name, color, order_index, status_type, parent_status_id, is_active)
SELECT 'closed_not_eligible_incentive', 'Not eligible for incentive', '#6b7280', 2, 'sub', id, true FROM lead_statuses WHERE name = 'closed';

-- Post Sales sub-statuses
INSERT INTO lead_statuses (name, display_name, color, order_index, status_type, parent_status_id, is_active)
SELECT 'post_sales_incentive_paid', 'Incentive Paid', '#5eead4', 1, 'sub', id, true FROM lead_statuses WHERE name = 'post_sales';

-- Step 6: Add sub_status_id column to leads table
DO $$ 
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns 
    WHERE table_name = 'leads' AND column_name = 'sub_status_id'
  ) THEN
    ALTER TABLE leads ADD COLUMN sub_status_id uuid REFERENCES lead_statuses(id);
  END IF;
END $$;

-- Step 7: Create indexes
CREATE INDEX IF NOT EXISTS idx_leads_sub_status_id ON leads(sub_status_id);
CREATE INDEX IF NOT EXISTS idx_lead_statuses_parent ON lead_statuses(parent_status_id);

-- Step 8: Create validation function for sub-status (optional validation for now)
CREATE OR REPLACE FUNCTION validate_sub_status()
RETURNS TRIGGER AS $$
DECLARE
  parent_id uuid;
  status_requires_sub boolean;
BEGIN
  -- If sub_status_id is provided, validate it matches the parent status
  IF NEW.sub_status_id IS NOT NULL THEN
    -- Get the parent_status_id of the sub_status
    SELECT parent_status_id INTO parent_id
    FROM lead_statuses
    WHERE id = NEW.sub_status_id;
    
    -- Ensure the sub_status's parent matches the lead's main status
    IF parent_id IS NOT NULL AND parent_id != NEW.status_id THEN
      RAISE EXCEPTION 'Sub-status does not belong to the selected main status';
    END IF;
  END IF;
  
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Step 9: Create trigger for sub-status validation
DROP TRIGGER IF EXISTS trigger_validate_sub_status ON leads;
CREATE TRIGGER trigger_validate_sub_status
  BEFORE INSERT OR UPDATE ON leads
  FOR EACH ROW
  EXECUTE FUNCTION validate_sub_status();

-- Step 10: Create helper function to get status hierarchy
CREATE OR REPLACE FUNCTION get_lead_status_display(lead_status_id uuid, lead_sub_status_id uuid)
RETURNS text AS $$
DECLARE
  main_status text;
  sub_status text;
BEGIN
  SELECT display_name INTO main_status
  FROM lead_statuses
  WHERE id = lead_status_id;
  
  IF lead_sub_status_id IS NOT NULL THEN
    SELECT display_name INTO sub_status
    FROM lead_statuses
    WHERE id = lead_sub_status_id;
    
    RETURN main_status || ' - ' || sub_status;
  END IF;
  
  RETURN main_status;
END;
$$ LANGUAGE plpgsql IMMUTABLE;
