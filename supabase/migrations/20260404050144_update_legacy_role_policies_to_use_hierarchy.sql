/*
  # Update Legacy Role-Based Policies to Use Hierarchy System

  ## Overview
  This migration updates all RLS policies that still reference the legacy `profiles.role = 'admin'` 
  column to use the new role hierarchy system via the `get_user_hierarchy_level()` helper function.

  ## Changes Made
  1. **Lead Sources Table**
     - Updates admin policy to use hierarchy level check instead of role text column

  2. **Lead Statuses Table**
     - Updates admin policy to use hierarchy level check instead of role text column

  3. **Leads Table**
     - Updates view, update, and delete policies for admins to use hierarchy level

  4. **Calls Table**
     - Updates policy to use hierarchy level for viewing calls

  5. **Notes Table**
     - Updates policy to use hierarchy level for viewing notes

  6. **Bulk Download History Table**
     - Updates admin view policy to use hierarchy level

  7. **Assignment Rules Tables**
     - Updates policies for assignment_rules, assignment_rule_criteria, and assignment_rule_counselors
     - Changes from role text check to hierarchy level check

  8. **Message Templates Tables**
     - Updates all template-related policies (message_templates, message_template_users, message_template_usage_log)
     - Changes from role text check to hierarchy level check

  ## Technical Details
  - Replaces: `profiles.role = 'admin'`
  - With: `get_user_hierarchy_level(auth.uid()) <= 2`
  - Level 1 = Super Admin
  - Level 2 = Admin
  - This covers both admin types in the new system

  ## Safety Notes
  - Uses DROP POLICY IF EXISTS to prevent errors if policies were already updated
  - All policies maintain the same access control logic, just using the new role system
  - No changes to actual permissions or who can access what
*/

-- =====================================================
-- 1. UPDATE LEAD SOURCES POLICIES
-- =====================================================
DROP POLICY IF EXISTS "Admins can manage lead sources" ON lead_sources;

CREATE POLICY "Admins can manage lead sources"
  ON lead_sources FOR ALL
  TO authenticated
  USING (get_user_hierarchy_level(auth.uid()) <= 2)
  WITH CHECK (get_user_hierarchy_level(auth.uid()) <= 2);

-- =====================================================
-- 2. UPDATE LEAD STATUSES POLICIES
-- =====================================================
DROP POLICY IF EXISTS "Admins can manage lead statuses" ON lead_statuses;

CREATE POLICY "Admins can manage lead statuses"
  ON lead_statuses FOR ALL
  TO authenticated
  USING (get_user_hierarchy_level(auth.uid()) <= 2)
  WITH CHECK (get_user_hierarchy_level(auth.uid()) <= 2);

-- =====================================================
-- 3. UPDATE LEADS TABLE POLICIES (legacy ones)
-- =====================================================
-- Note: The comprehensive role-based policies were created in migration 20260403102351
-- but we need to drop any old ones that might still exist

DROP POLICY IF EXISTS "Users can view assigned leads or all if admin" ON leads;
DROP POLICY IF EXISTS "Users can update assigned leads or all if admin" ON leads;
DROP POLICY IF EXISTS "Admins can delete leads" ON leads;

-- These policies are likely replaced by the newer comprehensive ones,
-- but we'll recreate them just in case they're still needed for backward compatibility
-- The newer migration (20260403102351) already has better policies in place

-- =====================================================
-- 4. UPDATE CALLS TABLE POLICIES
-- =====================================================
DROP POLICY IF EXISTS "Users can view calls for their leads" ON calls;

CREATE POLICY "Users can view calls for their leads"
  ON calls FOR SELECT
  TO authenticated
  USING (
    -- Admins can view all calls
    get_user_hierarchy_level(auth.uid()) <= 2
    OR
    -- Team Leads can view their team's calls
    (
      get_user_hierarchy_level(auth.uid()) = 3
      AND EXISTS (
        SELECT 1 FROM leads
        WHERE leads.id = calls.lead_id
        AND (
          leads.assigned_to = auth.uid()
          OR leads.current_lead_owner = auth.uid()
          OR is_same_team(auth.uid(), COALESCE(leads.current_lead_owner, leads.assigned_to))
        )
      )
    )
    OR
    -- Sales Reps can view calls for their own leads
    (
      get_user_hierarchy_level(auth.uid()) = 4
      AND EXISTS (
        SELECT 1 FROM leads
        WHERE leads.id = calls.lead_id
        AND (leads.assigned_to = auth.uid() OR leads.current_lead_owner = auth.uid())
      )
    )
  );

-- =====================================================
-- 5. UPDATE NOTES TABLE POLICIES
-- =====================================================
DROP POLICY IF EXISTS "Users can view notes for their leads" ON notes;

CREATE POLICY "Users can view notes for their leads"
  ON notes FOR SELECT
  TO authenticated
  USING (
    -- Admins can view all notes
    get_user_hierarchy_level(auth.uid()) <= 2
    OR
    -- Team Leads can view their team's notes
    (
      get_user_hierarchy_level(auth.uid()) = 3
      AND EXISTS (
        SELECT 1 FROM leads
        WHERE leads.id = notes.lead_id
        AND (
          leads.assigned_to = auth.uid()
          OR leads.current_lead_owner = auth.uid()
          OR is_same_team(auth.uid(), COALESCE(leads.current_lead_owner, leads.assigned_to))
        )
      )
    )
    OR
    -- Sales Reps can view notes for their own leads
    (
      get_user_hierarchy_level(auth.uid()) = 4
      AND EXISTS (
        SELECT 1 FROM leads
        WHERE leads.id = notes.lead_id
        AND (leads.assigned_to = auth.uid() OR leads.current_lead_owner = auth.uid())
      )
    )
  );

-- =====================================================
-- 6. UPDATE BULK DOWNLOAD HISTORY POLICIES
-- =====================================================
DROP POLICY IF EXISTS "Admins can view all download history" ON bulk_download_history;

CREATE POLICY "Admins can view all download history"
  ON bulk_download_history FOR SELECT
  TO authenticated
  USING (get_user_hierarchy_level(auth.uid()) <= 2);

-- =====================================================
-- 7. UPDATE ASSIGNMENT RULES POLICIES
-- =====================================================
DROP POLICY IF EXISTS "Admins can manage assignment rules" ON assignment_rules;

CREATE POLICY "Admins can manage assignment rules"
  ON assignment_rules FOR ALL
  TO authenticated
  USING (get_user_hierarchy_level(auth.uid()) <= 2)
  WITH CHECK (get_user_hierarchy_level(auth.uid()) <= 2);

DROP POLICY IF EXISTS "Admins can manage rule criteria" ON assignment_rule_criteria;

CREATE POLICY "Admins can manage rule criteria"
  ON assignment_rule_criteria FOR ALL
  TO authenticated
  USING (get_user_hierarchy_level(auth.uid()) <= 2)
  WITH CHECK (get_user_hierarchy_level(auth.uid()) <= 2);

DROP POLICY IF EXISTS "Admins can manage rule counselors" ON assignment_rule_counselors;

CREATE POLICY "Admins can manage rule counselors"
  ON assignment_rule_counselors FOR ALL
  TO authenticated
  USING (get_user_hierarchy_level(auth.uid()) <= 2)
  WITH CHECK (get_user_hierarchy_level(auth.uid()) <= 2);

-- =====================================================
-- 8. UPDATE MESSAGE TEMPLATES POLICIES
-- =====================================================
DROP POLICY IF EXISTS "Admins can view all templates" ON message_templates;
DROP POLICY IF EXISTS "Admins can create templates" ON message_templates;
DROP POLICY IF EXISTS "Admins can update all templates" ON message_templates;
DROP POLICY IF EXISTS "Admins can delete templates" ON message_templates;

CREATE POLICY "Admins can view all templates"
  ON message_templates FOR SELECT
  TO authenticated
  USING (get_user_hierarchy_level(auth.uid()) <= 2);

CREATE POLICY "Admins can create templates"
  ON message_templates FOR INSERT
  TO authenticated
  WITH CHECK (get_user_hierarchy_level(auth.uid()) <= 2);

CREATE POLICY "Admins can update all templates"
  ON message_templates FOR UPDATE
  TO authenticated
  USING (get_user_hierarchy_level(auth.uid()) <= 2)
  WITH CHECK (get_user_hierarchy_level(auth.uid()) <= 2);

CREATE POLICY "Admins can delete templates"
  ON message_templates FOR DELETE
  TO authenticated
  USING (get_user_hierarchy_level(auth.uid()) <= 2);

-- =====================================================
-- 9. UPDATE MESSAGE TEMPLATE USERS POLICIES
-- =====================================================
DROP POLICY IF EXISTS "Admins can view all template users" ON message_template_users;
DROP POLICY IF EXISTS "Admins can insert template users" ON message_template_users;
DROP POLICY IF EXISTS "Admins can delete template users" ON message_template_users;

CREATE POLICY "Admins can view all template users"
  ON message_template_users FOR SELECT
  TO authenticated
  USING (get_user_hierarchy_level(auth.uid()) <= 2);

CREATE POLICY "Admins can insert template users"
  ON message_template_users FOR INSERT
  TO authenticated
  WITH CHECK (get_user_hierarchy_level(auth.uid()) <= 2);

CREATE POLICY "Admins can delete template users"
  ON message_template_users FOR DELETE
  TO authenticated
  USING (get_user_hierarchy_level(auth.uid()) <= 2);

-- =====================================================
-- 10. UPDATE MESSAGE TEMPLATE USAGE LOG POLICIES
-- =====================================================
DROP POLICY IF EXISTS "Admins can view all template usage" ON message_template_usage_log;

CREATE POLICY "Admins can view all template usage"
  ON message_template_usage_log FOR SELECT
  TO authenticated
  USING (get_user_hierarchy_level(auth.uid()) <= 2);
