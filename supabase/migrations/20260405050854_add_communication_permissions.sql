/*
  # Add Communication Permissions

  ## Overview
  This migration adds new permissions for communication actions (WhatsApp, Email, Phone)
  to enable granular access control for communication features in the CRM.

  ## New Permissions Added
  
  ### Communications Module
  - `communications.send_whatsapp` - Permission to send WhatsApp messages via wa.me integration
  - `communications.send_email` - Permission to send emails via mailto: integration
  - `communications.make_call` - Permission to make phone calls and log call outcomes
  - `communications.view_analytics` - Permission to view communication analytics and metrics

  ## Role Mapping
  - Super Admin: All communication permissions
  - Admin: All communication permissions
  - Team Lead: All communication permissions
  - Sales Rep: All communication permissions (default access for all roles)

  ## Important Notes
  - These permissions control access to communication action buttons on lead cards
  - Analytics permission controls visibility of communication metrics in dashboard
  - All existing users retain their current access through role-based permissions
*/

-- Insert communication permissions
INSERT INTO permissions (module_name, action_name, permission_key, description)
VALUES
  ('Communications', 'Send WhatsApp', 'communications.send_whatsapp', 'Allows user to send WhatsApp messages to leads using template-based wa.me integration'),
  ('Communications', 'Send Email', 'communications.send_email', 'Allows user to send emails to leads using template-based mailto: integration'),
  ('Communications', 'Make Call', 'communications.make_call', 'Allows user to initiate phone calls and log call outcomes'),
  ('Communications', 'View Analytics', 'communications.view_analytics', 'Allows user to view communication analytics and metrics in dashboard')
ON CONFLICT (permission_key) DO NOTHING;

-- Grant all communication permissions to all roles by default
DO $$
DECLARE
  role_record RECORD;
  permission_record RECORD;
BEGIN
  -- Loop through all active roles
  FOR role_record IN SELECT id FROM roles WHERE is_active = true LOOP
    -- Loop through all new communication permissions
    FOR permission_record IN 
      SELECT id FROM permissions 
      WHERE permission_key LIKE 'communications.%' 
    LOOP
      -- Insert role-permission mapping if it doesn't exist
      INSERT INTO role_permissions (role_id, permission_id)
      VALUES (role_record.id, permission_record.id)
      ON CONFLICT DO NOTHING;
    END LOOP;
  END LOOP;
END $$;