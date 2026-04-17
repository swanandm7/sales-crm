/*
  # Remove Stage and Sub-Stage Columns from Leads Table

  This migration removes the legacy `stage` and `sub_stage` text columns from the leads table.
  These fields are redundant as the system now exclusively uses the hierarchical status system
  with `status_id` and `sub_status_id` foreign key relationships to the `lead_statuses` table.

  ## Changes Made

  1. **Dropped Columns**
     - `stage` (text) - Legacy main lifecycle stage field
     - `sub_stage` (text) - Legacy detailed stage breakdown field

  2. **Dropped Indexes**
     - `idx_leads_stage` - Index on the stage column for query performance

  ## Data Safety

  - All 125 existing leads have `status_id` and `sub_status_id` populated
  - The legacy `stage` column contains data but `sub_stage` is empty across all records
  - No database functions, triggers, or stored procedures depend on these columns
  - The application now exclusively uses the hierarchical status system

  ## Important Notes

  - This migration is **irreversible** - the stage and sub_stage data will be permanently removed
  - Ensure backups are in place before applying this migration
  - The hierarchical status system (`status_id` and `sub_status_id`) remains fully functional
*/

-- Drop the index on stage column
DROP INDEX IF EXISTS idx_leads_stage;

-- Drop the stage and sub_stage columns from leads table
ALTER TABLE leads 
  DROP COLUMN IF EXISTS stage,
  DROP COLUMN IF EXISTS sub_stage;
