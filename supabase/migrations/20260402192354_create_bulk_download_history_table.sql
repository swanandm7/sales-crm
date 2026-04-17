/*
  # Create Bulk Download History Table

  ## Overview
  This migration creates a table to track all bulk data download operations performed by users.
  This enables audit trails and allows users to view their download history.

  ## New Tables
  
  ### `bulk_download_history`
  Tracks every bulk download operation with complete metadata
  
  **Columns:**
  - `id` (uuid, primary key) - Unique identifier for the download record
  - `user_id` (uuid, required) - User who performed the download
  - `cc_users` (text[], nullable) - Array of user IDs who were CC'd on the download
  - `bcc_users` (text[], nullable) - Array of user IDs who were BCC'd on the download
  - `download_source` (text, default 'Leads') - Source of the download (e.g., 'Leads', 'Contacts')
  - `total_records` (integer, default 0) - Number of records in the download
  - `filter_criteria` (jsonb, default '{}') - The filter criteria applied to the download
  - `file_format` (text, default 'csv') - Format of the downloaded file
  - `status` (text, default 'completed') - Status of the download operation
  - `downloaded_at` (timestamptz, default now()) - Timestamp when download was initiated
  - `completed_at` (timestamptz, nullable) - Timestamp when download completed
  - `error_message` (text, nullable) - Error message if download failed
  - `file_size_bytes` (bigint, nullable) - Size of the downloaded file in bytes
  
  ## Security
  
  **Row Level Security (RLS):**
  - Enable RLS on the table
  - Users can view their own download history
  - Admins can view all download history
  - Users can create new download records
  
  ## Indexes
  - Index on `user_id` for fast user-specific queries
  - Index on `downloaded_at` for chronological sorting
*/

-- Create bulk_download_history table
CREATE TABLE IF NOT EXISTS bulk_download_history (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id uuid NOT NULL REFERENCES profiles(id),
  cc_users text[] DEFAULT '{}',
  bcc_users text[] DEFAULT '{}',
  download_source text NOT NULL DEFAULT 'Leads',
  total_records integer NOT NULL DEFAULT 0,
  filter_criteria jsonb DEFAULT '{}'::jsonb,
  file_format text NOT NULL DEFAULT 'csv',
  status text NOT NULL DEFAULT 'completed' CHECK (status IN ('pending', 'completed', 'failed')),
  downloaded_at timestamptz DEFAULT now(),
  completed_at timestamptz,
  error_message text,
  file_size_bytes bigint,
  created_at timestamptz DEFAULT now()
);

-- Enable RLS
ALTER TABLE bulk_download_history ENABLE ROW LEVEL SECURITY;

-- Create indexes
CREATE INDEX IF NOT EXISTS idx_bulk_download_history_user_id ON bulk_download_history(user_id);
CREATE INDEX IF NOT EXISTS idx_bulk_download_history_downloaded_at ON bulk_download_history(downloaded_at DESC);

-- RLS Policies
CREATE POLICY "Users can view own download history"
  ON bulk_download_history FOR SELECT
  TO authenticated
  USING (auth.uid() = user_id);

CREATE POLICY "Admins can view all download history"
  ON bulk_download_history FOR SELECT
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM profiles
      WHERE profiles.id = auth.uid()
      AND profiles.role = 'admin'
    )
  );

CREATE POLICY "Users can create download records"
  ON bulk_download_history FOR INSERT
  TO authenticated
  WITH CHECK (auth.uid() = user_id);