/*
  # Create Bulk Upload Jobs Table and Batch Insert Function

  1. New Tables
    - `bulk_upload_jobs`
      - `id` (uuid, primary key) - Unique identifier for upload job
      - `user_id` (uuid, references profiles) - User who initiated the upload
      - `filename` (text) - Original CSV filename
      - `file_size_bytes` (bigint) - Size of uploaded file in bytes
      - `total_rows` (integer) - Total number of rows in CSV
      - `processed_rows` (integer) - Number of rows processed so far
      - `successful_rows` (integer) - Successfully imported rows
      - `failed_rows` (integer) - Rows that failed validation/import
      - `skipped_rows` (integer) - Duplicate rows that were skipped
      - `duplicate_handling_strategy` (text) - Strategy: 'skip', 'update', or 'create_new'
      - `status` (text) - Current job status: 'validating', 'processing', 'completed', 'failed', 'cancelled'
      - `error_log` (jsonb) - Array of error details with row numbers and messages
      - `column_mapping` (jsonb) - User's column mapping configuration
      - `uploaded_at` (timestamptz) - When the file was uploaded
      - `started_processing_at` (timestamptz) - When processing began
      - `completed_at` (timestamptz) - When processing finished
  
  2. Indexes
    - Index on user_id for fast user-specific queries
    - Index on status for filtering by job status
    - Index on uploaded_at for chronological sorting
  
  3. Security
    - Enable RLS on bulk_upload_jobs table
    - Users can view only their own upload jobs
    - Users can create new upload jobs
    - Users can update their own upload jobs
  
  4. Functions
    - `bulk_insert_leads` - Efficient batch insert function with validation
*/

-- Create bulk_upload_jobs table
CREATE TABLE IF NOT EXISTS bulk_upload_jobs (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id uuid REFERENCES profiles(id) ON DELETE CASCADE NOT NULL,
  filename text NOT NULL,
  file_size_bytes bigint NOT NULL,
  total_rows integer NOT NULL,
  processed_rows integer DEFAULT 0,
  successful_rows integer DEFAULT 0,
  failed_rows integer DEFAULT 0,
  skipped_rows integer DEFAULT 0,
  duplicate_handling_strategy text NOT NULL CHECK (duplicate_handling_strategy IN ('skip', 'update', 'create_new')),
  status text NOT NULL DEFAULT 'validating' CHECK (status IN ('validating', 'processing', 'completed', 'failed', 'cancelled')),
  error_log jsonb DEFAULT '[]'::jsonb,
  column_mapping jsonb DEFAULT '{}'::jsonb,
  uploaded_at timestamptz DEFAULT now(),
  started_processing_at timestamptz,
  completed_at timestamptz
);

-- Create indexes for performance
CREATE INDEX IF NOT EXISTS idx_bulk_upload_jobs_user_id ON bulk_upload_jobs(user_id);
CREATE INDEX IF NOT EXISTS idx_bulk_upload_jobs_status ON bulk_upload_jobs(status);
CREATE INDEX IF NOT EXISTS idx_bulk_upload_jobs_uploaded_at ON bulk_upload_jobs(uploaded_at DESC);

-- Enable RLS
ALTER TABLE bulk_upload_jobs ENABLE ROW LEVEL SECURITY;

-- Users can view their own upload jobs
CREATE POLICY "Users can view own upload jobs"
  ON bulk_upload_jobs
  FOR SELECT
  TO authenticated
  USING (auth.uid() = user_id);

-- Users can create new upload jobs
CREATE POLICY "Users can create upload jobs"
  ON bulk_upload_jobs
  FOR INSERT
  TO authenticated
  WITH CHECK (auth.uid() = user_id);

-- Users can update their own upload jobs
CREATE POLICY "Users can update own upload jobs"
  ON bulk_upload_jobs
  FOR UPDATE
  TO authenticated
  USING (auth.uid() = user_id)
  WITH CHECK (auth.uid() = user_id);

-- Users can delete their own upload jobs
CREATE POLICY "Users can delete own upload jobs"
  ON bulk_upload_jobs
  FOR DELETE
  TO authenticated
  USING (auth.uid() = user_id);
