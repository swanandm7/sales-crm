/*
  # Add Performance Indexes for Follow-ups

  1. Performance Improvements
    - Add composite index on (user_id, status, next_action_date, next_action_time)
      - Optimizes filtered queries by status and date
      - Speeds up tab switching and date filtering
    - Add composite index on (user_id, next_action_date)
      - Optimizes calendar date range queries
      - Speeds up 5-day calendar view loading
    
  2. Expected Impact
    - 10-50x faster queries as data scales
    - Sub-100ms query times even with 10,000+ records
    - Efficient pagination and filtering
*/

-- Create composite index for filtered queries (tab + date filtering)
CREATE INDEX IF NOT EXISTS idx_followups_user_status_date 
ON followups(user_id, status, next_action_date, next_action_time);

-- Create composite index for calendar date range queries
CREATE INDEX IF NOT EXISTS idx_followups_user_date 
ON followups(user_id, next_action_date);
