/**
 * App-wide constants for the mobile CRM
 */

export const APP_VERSION = '2.4.1';
export const APP_NAME = 'degreebaba CRM';

// Queue configuration
export const QUEUE_FETCH_LIMIT = 100; // Increased from 25 (Issue #10 fix)
export const OFFLINE_QUEUE_MAX_SIZE = 50;
export const OFFLINE_QUEUE_MAX_AGE_HOURS = 48;

// Date format helpers
export function formatDateForDisplay(isoDate: string): string {
  const d = new Date(isoDate);
  return d.toLocaleDateString('en-IN', { day: '2-digit', month: 'short', year: 'numeric' });
}

export function formatTimeForDisplay(isoDate: string): string {
  const d = new Date(isoDate);
  return d.toLocaleTimeString('en-IN', { hour: '2-digit', minute: '2-digit' });
}

export const DATE_INPUT_REGEX = /^\d{4}-(0[1-9]|1[0-2])-(0[1-9]|[12]\d|3[01])$/;

export function isValidDateString(value: string): boolean {
  if (!DATE_INPUT_REGEX.test(value)) return false;
  const d = new Date(value);
  return !isNaN(d.getTime());
}
