/*
  # Create Webhook Health Metric Upsert Function

  ## Purpose
  Creates a PostgreSQL function to efficiently upsert webhook health metrics
  using hour-based aggregation for performance tracking.

  ## Details
  - Function upserts metrics into webhook_health_metrics table
  - Aggregates by hour bucket for efficient time-series data
  - Increments count and adds to total duration on conflict
*/

CREATE OR REPLACE FUNCTION upsert_webhook_health_metric(
  p_organization_id uuid,
  p_metric_type text,
  p_endpoint_id uuid,
  p_count integer,
  p_duration_ms integer,
  p_hour_bucket timestamptz
)
RETURNS void AS $$
BEGIN
  INSERT INTO webhook_health_metrics (
    organization_id,
    metric_type,
    endpoint_id,
    count,
    total_duration_ms,
    hour_bucket
  )
  VALUES (
    p_organization_id,
    p_metric_type,
    p_endpoint_id,
    p_count,
    p_duration_ms,
    p_hour_bucket
  )
  ON CONFLICT (organization_id, metric_type, endpoint_id, hour_bucket)
  DO UPDATE SET
    count = webhook_health_metrics.count + p_count,
    total_duration_ms = webhook_health_metrics.total_duration_ms + p_duration_ms;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;