import { createContext, useContext, useEffect, useState, useCallback, useRef } from 'react';
import { supabase } from '../lib/supabase';
import { useAuth } from './AuthContext';
import { showBrowserNotification, getNotificationPermission } from '../utils/notificationPermissions';
import type { Database } from '../lib/database.types';

type Followup = Database['public']['Tables']['followups']['Row'] & {
  leads?: {
    id: string;
    first_name: string | null;
    last_name: string | null;
    name: string;
    mobile_number: string;
  };
};

interface ReminderState {
  followupId: string;
  snoozeUntil: number;
  count: number;
}

interface DismissedState {
  [followupId: string]: number;
}

interface SnoozedState {
  [followupId: string]: ReminderState;
}

interface LocalStorageState {
  dismissed: DismissedState;
  snoozed: SnoozedState;
  permissionAsked: boolean;
}

export interface FollowupReminder {
  id: string;
  leadName: string;
  mobileNumber: string;
  scheduledTime: Date;
  remarks: string;
  minutesUntil: number;
}

interface ReminderContextType {
  reminders: FollowupReminder[];
  dismissReminder: (followupId: string) => void;
  snoozeReminder: (followupId: string) => void;
  viewFollowup: (followupId: string) => void;
  hasPermission: boolean;
}

const ReminderContext = createContext<ReminderContextType | undefined>(undefined);

const STORAGE_KEY = 'followup_reminders_state';
const POLL_INTERVAL = 60000;
const REMINDER_ADVANCE_TIME = 5 * 60 * 1000;
const SNOOZE_DURATION = 2 * 60 * 1000;

export function ReminderProvider({ children, onViewFollowup }: { children: React.ReactNode; onViewFollowup: (followupId: string) => void }) {
  const { user } = useAuth();
  const [reminders, setReminders] = useState<FollowupReminder[]>([]);
  const [hasPermission, setHasPermission] = useState(false);
  const pollIntervalRef = useRef<NodeJS.Timeout | null>(null);
  const shownRemindersRef = useRef<Set<string>>(new Set());

  const getLocalStorage = useCallback((): LocalStorageState => {
    try {
      const stored = localStorage.getItem(STORAGE_KEY);
      if (stored) {
        return JSON.parse(stored);
      }
    } catch (error) {
      console.error('Error reading reminder state from localStorage:', error);
    }

    return {
      dismissed: {},
      snoozed: {},
      permissionAsked: false,
    };
  }, []);

  const setLocalStorage = useCallback((state: Partial<LocalStorageState>) => {
    try {
      const current = getLocalStorage();
      const updated = { ...current, ...state };
      localStorage.setItem(STORAGE_KEY, JSON.stringify(updated));
    } catch (error) {
      console.error('Error saving reminder state to localStorage:', error);
    }
  }, [getLocalStorage]);

  const checkPermission = useCallback(() => {
    const permission = getNotificationPermission();
    setHasPermission(permission.granted);
    return permission.granted;
  }, []);

  const fetchUpcomingFollowups = useCallback(async () => {
    if (!user) return [];

    try {
      const now = new Date();
      const fiveMinutesLater = new Date(now.getTime() + REMINDER_ADVANCE_TIME);

      const { data, error } = await supabase
        .from('followups')
        .select(`
          *,
          leads:lead_id (
            id,
            first_name,
            last_name,
            name,
            mobile_number
          )
        `)
        .eq('user_id', user.id)
        .eq('status', 'planned')
        .gte('next_action_date', now.toISOString().split('T')[0])
        .lte('next_action_date', fiveMinutesLater.toISOString().split('T')[0]);

      if (error) throw error;

      const followups = (data || []) as Followup[];

      const upcoming = followups.filter(f => {
        const [hours, minutes] = f.next_action_time.split(':').map(Number);
        const scheduledTime = new Date(f.next_action_date);
        scheduledTime.setHours(hours, minutes, 0, 0);

        const timeDiff = scheduledTime.getTime() - now.getTime();

        return timeDiff > 0 && timeDiff <= REMINDER_ADVANCE_TIME;
      });

      return upcoming;
    } catch (error) {
      console.error('Error fetching upcoming follow-ups:', error);
      return [];
    }
  }, [user]);

  const checkAndShowReminders = useCallback(async () => {
    const upcoming = await fetchUpcomingFollowups();
    const storage = getLocalStorage();
    const now = Date.now();

    const validReminders: FollowupReminder[] = [];

    for (const followup of upcoming) {
      if (shownRemindersRef.current.has(followup.id)) {
        continue;
      }

      if (storage.dismissed[followup.id]) {
        const dismissedTime = storage.dismissed[followup.id];
        if (now - dismissedTime < 24 * 60 * 60 * 1000) {
          continue;
        }
      }

      if (storage.snoozed[followup.id]) {
        const snoozedState = storage.snoozed[followup.id];
        if (now < snoozedState.snoozeUntil) {
          continue;
        }
      }

      const lead = followup.leads as any;
      const leadName = lead?.first_name || lead?.last_name
        ? `${lead.first_name || ''} ${lead.last_name || ''}`.trim()
        : lead?.name || 'Unknown Lead';

      const [hours, minutes] = followup.next_action_time.split(':').map(Number);
      const scheduledTime = new Date(followup.next_action_date);
      scheduledTime.setHours(hours, minutes, 0, 0);

      const minutesUntil = Math.floor((scheduledTime.getTime() - now) / 60000);

      const reminder: FollowupReminder = {
        id: followup.id,
        leadName,
        mobileNumber: lead?.mobile_number || '',
        scheduledTime,
        remarks: followup.followup_remarks,
        minutesUntil,
      };

      validReminders.push(reminder);
      shownRemindersRef.current.add(followup.id);

      if (hasPermission && document.hidden) {
        showBrowserNotification(`Follow-up Reminder: ${leadName}`, {
          body: `In ${minutesUntil} minute${minutesUntil !== 1 ? 's' : ''}: ${followup.followup_remarks}`,
          icon: '/favicon.ico',
          tag: followup.id,
          requireInteraction: true,
          onClick: () => onViewFollowup(followup.id),
        });
      }
    }

    setReminders(validReminders);
  }, [fetchUpcomingFollowups, getLocalStorage, hasPermission, onViewFollowup]);

  const dismissReminder = useCallback((followupId: string) => {
    const storage = getLocalStorage();
    storage.dismissed[followupId] = Date.now();
    setLocalStorage({ dismissed: storage.dismissed });
    setReminders(prev => prev.filter(r => r.id !== followupId));
  }, [getLocalStorage, setLocalStorage]);

  const snoozeReminder = useCallback((followupId: string) => {
    const storage = getLocalStorage();
    const existingSnooze = storage.snoozed[followupId];

    storage.snoozed[followupId] = {
      followupId,
      snoozeUntil: Date.now() + SNOOZE_DURATION,
      count: (existingSnooze?.count || 0) + 1,
    };

    setLocalStorage({ snoozed: storage.snoozed });
    setReminders(prev => prev.filter(r => r.id !== followupId));
    shownRemindersRef.current.delete(followupId);

    setTimeout(() => {
      checkAndShowReminders();
    }, SNOOZE_DURATION);
  }, [getLocalStorage, setLocalStorage, checkAndShowReminders]);

  const viewFollowup = useCallback((followupId: string) => {
    dismissReminder(followupId);
    onViewFollowup(followupId);
  }, [dismissReminder, onViewFollowup]);

  useEffect(() => {
    if (!user) {
      setReminders([]);
      if (pollIntervalRef.current) {
        clearInterval(pollIntervalRef.current);
        pollIntervalRef.current = null;
      }
      return;
    }

    checkPermission();
    checkAndShowReminders();

    pollIntervalRef.current = setInterval(() => {
      checkAndShowReminders();
    }, POLL_INTERVAL);

    return () => {
      if (pollIntervalRef.current) {
        clearInterval(pollIntervalRef.current);
      }
    };
  }, [user, checkPermission, checkAndShowReminders]);

  useEffect(() => {
    const handleVisibilityChange = () => {
      if (!document.hidden) {
        checkAndShowReminders();
      }
    };

    document.addEventListener('visibilitychange', handleVisibilityChange);

    return () => {
      document.removeEventListener('visibilitychange', handleVisibilityChange);
    };
  }, [checkAndShowReminders]);

  const value = {
    reminders,
    dismissReminder,
    snoozeReminder,
    viewFollowup,
    hasPermission,
  };

  return <ReminderContext.Provider value={value}>{children}</ReminderContext.Provider>;
}

export function useReminders() {
  const context = useContext(ReminderContext);
  if (context === undefined) {
    throw new Error('useReminders must be used within a ReminderProvider');
  }
  return context;
}
