/*
  # Remove Legacy Role Column from Profiles Table

  ## Overview
  This migration removes the deprecated `role` text column from the `profiles` table.
  The application now exclusively uses the `role_id` foreign key relationship with the `roles` table.

  ## Changes Made
  1. **Drop Legacy Column**
     - Removes `profiles.role` (text column)
     - This column is no longer used by the application
     - All role information is now accessed via `profiles.role_id` → `roles` table

  ## Safety Notes
  - All RLS policies have been updated to use the new role hierarchy system
  - The frontend already uses `role_id` exclusively for all role displays and checks
  - The legacy `role` column contains outdated values and is not referenced anywhere in the codebase
  - No data loss occurs as all role information is preserved in the `roles` table via `role_id`

  ## Impact
  - ✅ Frontend role displays continue to work unchanged (uses `role_id`)
  - ✅ All permissions and access control remain intact (now using hierarchy levels)
  - ✅ Cleaner database schema without redundant columns
  - ✅ Eliminates confusion from having two role-related columns
*/

-- Drop the legacy role column from profiles table
ALTER TABLE profiles DROP COLUMN IF EXISTS role;
