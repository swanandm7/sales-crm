/*
  # Create Follow-ups Table

  ## Overview
  This migration creates the `followups` table to track scheduled follow-up actions for leads.
  Follow-ups allow CRM users to schedule future actions with leads and track them in the Follow-ups Manager module.

  ## New Tables
  
  ### `followups`
  - `id` (uuid, primary key) - Unique identifier for the follow-up
  - `lead_id` (uuid, foreign key → leads.id, required) - Reference to the lead
  - `user_id` (uuid, foreign key → profiles.id, required) - User who created the follow-up
  - `next_action_date` (timestamptz, required) - Date when the follow-up action should occur
  - `next_action_time` (time, required) - Time when the follow-up action should occur
  - `followup_remarks` (text, required) - Notes/comments about the follow-up
  - `status` (text, default 'planned') - Status of the follow-up (planned, done, missed)
  - `created_at` (timestamptz, default now()) - Timestamp when the follow-up was created
  - `updated_at` (timestamptz, default now()) - Timestamp when the follow-up was last updated

  ## Security
  - Enable RLS on `followups` table
  - Add policy for authenticated users to view their own follow-ups
  - Add policy for authenticated users to create follow-ups
  - Add policy for authenticated users to update their own follow-ups
  - Add policy for authenticated users to delete their own follow-ups

  ## Important Notes
  - The `next_action_date` and `next_action_time` fields allow precise scheduling of follow-ups
  - The `status` field helps categorize follow-ups as planned, done, or missed
  - RLS policies ensure users can only manage their own follow-ups
*/

-- Create followups table
CREATE TABLE IF NOT EXISTS followups (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  lead_id uuid NOT NULL REFERENCES leads(id) ON DELETE CASCADE,
  user_id uuid NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
  next_action_date timestamptz NOT NULL,
  next_action_time time NOT NULL,
  followup_remarks text NOT NULL,
  status text DEFAULT 'planned' CHECK (status IN ('planned', 'done', 'missed')),
  created_at timestamptz DEFAULT now(),
  updated_at timestamptz DEFAULT now()
);

-- Enable RLS
ALTER TABLE followups ENABLE ROW LEVEL SECURITY;

-- Policy: Users can view their own follow-ups
CREATE POLICY "Users can view own followups"
  ON followups
  FOR SELECT
  TO authenticated
  USING (auth.uid() = user_id);

-- Policy: Users can create follow-ups
CREATE POLICY "Users can create followups"
  ON followups
  FOR INSERT
  TO authenticated
  WITH CHECK (auth.uid() = user_id);

-- Policy: Users can update their own follow-ups
CREATE POLICY "Users can update own followups"
  ON followups
  FOR UPDATE
  TO authenticated
  USING (auth.uid() = user_id)
  WITH CHECK (auth.uid() = user_id);

-- Policy: Users can delete their own follow-ups
CREATE POLICY "Users can delete own followups"
  ON followups
  FOR DELETE
  TO authenticated
  USING (auth.uid() = user_id);

-- Create index for efficient queries
CREATE INDEX IF NOT EXISTS idx_followups_lead_id ON followups(lead_id);
CREATE INDEX IF NOT EXISTS idx_followups_user_id ON followups(user_id);
CREATE INDEX IF NOT EXISTS idx_followups_next_action_date ON followups(next_action_date);
CREATE INDEX IF NOT EXISTS idx_followups_status ON followups(status);