/*
  # Migrate Existing Users to New Role System

  1. Updates
    - Map existing 'admin' role to 'Admin' role_id
    - Map existing 'sales_rep' role to 'Sales Representative' role_id
    - Set all users as active by default
    
  2. Notes
    - Preserves existing role data in the old 'role' column for now
    - Updates the new role_id column with references to the roles table
*/

-- Update existing admins to Admin role
UPDATE profiles
SET role_id = (SELECT id FROM roles WHERE role_name = 'Admin')
WHERE role = 'admin' AND role_id IS NULL;

-- Update existing sales reps to Sales Representative role
UPDATE profiles
SET role_id = (SELECT id FROM roles WHERE role_name = 'Sales Representative')
WHERE role = 'sales_rep' AND role_id IS NULL;

-- Set all users as active
UPDATE profiles
SET is_active = true
WHERE is_active IS NULL;