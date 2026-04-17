/*
  # Reorganize Status and Sub-Status Mappings

  This migration reorganizes the parent-child relationships between statuses and sub-statuses
  to match the updated business requirements.

  ## Changes Made

  ### 1. Status: 02-No Response
  - **Removed**: "Follow up" sub-status

  ### 2. Status: 03-Followup
  - **Kept**: "Call back"
  - **Removed**: "Warm", "Cold" (moved to 04-Interested)

  ### 3. Status: 04-Interested
  - **Added**: "Cold", "Warm", "Hot" (moved from 03-Followup)
  - **Removed**: "Documents Pending", "Documents Uploaded", "Document Discrepancy" (moved to Registration Done)

  ### 4. Status: Registration Done
  - **Added**: "Documents Pending", "Documents Uploaded", "Document Discrepancy" (moved from 04-Interested)
  - **Removed**: "Registration Fee Paid", "Annual fee paid", "Full course fee paid", "Loan Applied", "Reference received" (moved to Admission Done)

  ### 5. Status: Admission Done
  - **Added**: "Registration Fee Paid", "Annual fee paid", "Full course fee paid", "Loan Applied", "Reference received" (moved from Registration Done)
  - **Removed**: "Sem fee paid", "Language barrier", "Test", "Duplicate" (moved to 05-Junk)

  ### 6. Status: 05-Junk
  - **Added**: "Sem fee paid", "Language barrier", "Test", "Duplicate" (moved from Admission Done)
  - **Kept**: All existing junk sub-statuses

  ## Final Mapping
  - 1- New Lead: Untouched, Switched Off, Not Reachable
  - 02-No Response: Ringing-Not picked
  - 03-Followup: Call back
  - 04-Interested: Cold, Warm, Hot
  - Registration Done: Documents Pending, Documents Uploaded, Document Discrepancy, Registration Fee Paid
  - Admission Done: Sem fee paid, Annual fee paid, Full course fee paid, Loan Applied, Reference received
  - 05-Junk: Invalid Number, Taken Admission Elsewhere, Not Eligible, Financial Issue, Contact Next year, Bad lead quality, Did not enquire, Language barrier, Test, Duplicate
  - 06-Closed: Not Interested, Not eligible for incentive
  - Post Sales: Incentive Paid
*/

-- Get the IDs of all main statuses
DO $$
DECLARE
  v_new_lead_id uuid;
  v_no_response_id uuid;
  v_followup_id uuid;
  v_interested_id uuid;
  v_registration_done_id uuid;
  v_admission_done_id uuid;
  v_junk_id uuid;
  v_closed_id uuid;
  v_post_sales_id uuid;
BEGIN
  -- Fetch main status IDs
  SELECT id INTO v_new_lead_id FROM lead_statuses WHERE display_name = '1- New Lead' AND status_type = 'main';
  SELECT id INTO v_no_response_id FROM lead_statuses WHERE display_name = '02-No Response' AND status_type = 'main';
  SELECT id INTO v_followup_id FROM lead_statuses WHERE display_name = '03-Followup' AND status_type = 'main';
  SELECT id INTO v_interested_id FROM lead_statuses WHERE display_name = '04-Interested' AND status_type = 'main';
  SELECT id INTO v_registration_done_id FROM lead_statuses WHERE display_name = 'Registration Done' AND status_type = 'main';
  SELECT id INTO v_admission_done_id FROM lead_statuses WHERE display_name = 'Admission Done' AND status_type = 'main';
  SELECT id INTO v_junk_id FROM lead_statuses WHERE display_name = '05-Junk' AND status_type = 'main';
  SELECT id INTO v_closed_id FROM lead_statuses WHERE display_name = '06-Closed' AND status_type = 'main';
  SELECT id INTO v_post_sales_id FROM lead_statuses WHERE display_name = 'Post Sales' AND status_type = 'main';

  -- 1. Move "Cold", "Warm", "Hot" from 03-Followup to 04-Interested
  UPDATE lead_statuses SET parent_status_id = v_interested_id 
  WHERE display_name IN ('Cold', 'Warm', 'Hot') AND status_type = 'sub';

  -- 2. Delete "Follow up" from 02-No Response
  DELETE FROM lead_statuses WHERE display_name = 'Follow up' AND status_type = 'sub' AND parent_status_id = v_no_response_id;

  -- 3. Move "Documents Pending", "Documents Uploaded", "Document Discrepancy" from 04-Interested to Registration Done
  UPDATE lead_statuses SET parent_status_id = v_registration_done_id 
  WHERE display_name IN ('Documents Pending', 'Documents Uploaded', 'Document Discrepancy') AND status_type = 'sub';

  -- 4. Move "Registration Fee Paid", "Annual fee paid", "Full course fee paid", "Loan Applied", "Reference received" from Registration Done to Admission Done
  UPDATE lead_statuses SET parent_status_id = v_admission_done_id 
  WHERE display_name IN ('Registration Fee Paid', 'Annual fee paid', 'Full course fee paid', 'Loan Applied', 'Reference received') AND status_type = 'sub';

  -- 5. Move "Sem fee paid", "Language barrier", "Test", "Duplicate" from Admission Done to 05-Junk
  UPDATE lead_statuses SET parent_status_id = v_junk_id 
  WHERE display_name IN ('Sem fee paid', 'Language barrier', 'Test', 'Duplicate') AND status_type = 'sub';

END $$;