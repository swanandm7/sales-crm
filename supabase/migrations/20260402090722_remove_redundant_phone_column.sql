/*
  # Remove redundant phone column from leads table

  1. Changes
    - Drop the `phone` column from `leads` table
    - The `mobile_number` column already contains all contact information
    - This eliminates data redundancy and simplifies the schema
  
  2. Rationale
    - Both `phone` and `mobile_number` were storing identical values
    - `mobile_number` has proper validation (unique constraint, format validation)
    - `mobile_number` is used for deduplication logic
    - Single source of truth reduces maintenance complexity
  
  3. Data Safety
    - All existing data is already present in `mobile_number` column
    - No data loss occurs from this change
*/

-- Drop the phone column from leads table
ALTER TABLE leads DROP COLUMN IF EXISTS phone;