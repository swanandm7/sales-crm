import AsyncStorage from '@react-native-async-storage/async-storage';
import type { MobileQueueLead, QuickUpdateInput } from './types';

const pendingKey = (userId: string) => `mobile_pending_updates:${userId}`;
const queueCacheKey = (userId: string) => `mobile_queue_cache:${userId}`;

// Safety limits — prevent unbounded queue growth (Issue #6)
const MAX_PENDING_UPDATES = 50;
const MAX_AGE_HOURS = 48;

type PendingQuickUpdate = QuickUpdateInput & {
  queuedAt: string;
};

export async function loadCachedQueue(userId: string): Promise<MobileQueueLead[]> {
  const raw = await AsyncStorage.getItem(queueCacheKey(userId));
  if (!raw) return [];

  try {
    return JSON.parse(raw) as MobileQueueLead[];
  } catch {
    return [];
  }
}

export async function cacheQueue(userId: string, queue: MobileQueueLead[]): Promise<void> {
  await AsyncStorage.setItem(queueCacheKey(userId), JSON.stringify(queue));
}

export async function listPendingQuickUpdates(userId: string): Promise<PendingQuickUpdate[]> {
  const raw = await AsyncStorage.getItem(pendingKey(userId));
  if (!raw) return [];

  try {
    const all = JSON.parse(raw) as PendingQuickUpdate[];
    // Filter out stale entries older than MAX_AGE_HOURS
    const cutoff = Date.now() - MAX_AGE_HOURS * 60 * 60 * 1000;
    const fresh = all.filter((item) => new Date(item.queuedAt).getTime() > cutoff);

    const staleCount = all.length - fresh.length;
    if (staleCount > 0) {
      console.warn(`[offlineQueue] Dropped ${staleCount} stale updates older than ${MAX_AGE_HOURS}h`);
      // Persist cleaned list immediately
      await AsyncStorage.setItem(pendingKey(userId), JSON.stringify(fresh));
    }

    return fresh;
  } catch {
    return [];
  }
}

export async function enqueueQuickUpdate(userId: string, update: QuickUpdateInput): Promise<{ queued: boolean; reason?: string }> {
  const pending = await listPendingQuickUpdates(userId);

  // Enforce max queue size
  if (pending.length >= MAX_PENDING_UPDATES) {
    console.warn(`[offlineQueue] Queue full (${MAX_PENDING_UPDATES} items). Dropping oldest entry.`);
    // Drop the oldest item to make room (FIFO eviction)
    pending.shift();
  }

  pending.push({
    ...update,
    queuedAt: new Date().toISOString(),
  });

  await AsyncStorage.setItem(pendingKey(userId), JSON.stringify(pending));
  return { queued: true };
}

export async function clearPendingQuickUpdates(userId: string): Promise<void> {
  await AsyncStorage.removeItem(pendingKey(userId));
}

export async function replacePendingQuickUpdates(userId: string, updates: PendingQuickUpdate[]): Promise<void> {
  await AsyncStorage.setItem(pendingKey(userId), JSON.stringify(updates));
}

/**
 * Returns the number of pending updates that are stale (older than MAX_AGE_HOURS).
 * Used for showing warnings in UI.
 */
export async function countStaleUpdates(userId: string): Promise<number> {
  const raw = await AsyncStorage.getItem(pendingKey(userId));
  if (!raw) return 0;
  try {
    const all = JSON.parse(raw) as PendingQuickUpdate[];
    const cutoff = Date.now() - MAX_AGE_HOURS * 60 * 60 * 1000;
    return all.filter((item) => new Date(item.queuedAt).getTime() <= cutoff).length;
  } catch {
    return 0;
  }
}

export function shouldQueueOffline(error: unknown): boolean {
  const message = error instanceof Error ? error.message.toLowerCase() : String(error).toLowerCase();

  return (
    message.includes('network') ||
    message.includes('fetch') ||
    message.includes('timeout') ||
    message.includes('connection') ||
    message.includes('offline')
  );
}
