import { mobileSupabase as supabase } from './supabaseClient';
import {
  cacheQueue,
  clearPendingQuickUpdates,
  enqueueQuickUpdate,
  listPendingQuickUpdates,
  loadCachedQueue,
  replacePendingQuickUpdates,
  shouldQueueOffline,
} from './offlineQueue';
import type {
  FollowupItem,
  MobileDashboardSummary,
  MobileFilterOption,
  MobileLeadFilterOptions,
  MobileLeadFilters,
  MobileQueueLead,
  NativeCallOutcome,
  QuickUpdateInput,
  StatusOption,
  TeamSummary,
} from './types';

type QuickOutcomeDefinition = {
  label: string;
  statusName: string;
  subStatusName: string;
  followupMinutes?: number;
};

export const QUICK_OUTCOMES: Record<NativeCallOutcome, QuickOutcomeDefinition> = {
  not_connected_no_answer: {
    label: 'No Answer',
    statusName: 'no_response',
    subStatusName: 'no_response_ringing',
  },
  connected: {
    label: 'Connected',
    statusName: 'interested',
    subStatusName: 'interested_hot',
  },
  not_connected_busy: {
    label: 'Busy',
    statusName: 'no_response',
    subStatusName: 'new_lead_not_reachable',
  },
  not_connected_switched_off: {
    label: 'Switched Off',
    statusName: 'no_response',
    subStatusName: 'new_lead_switched_off',
  },
  callback_requested: {
    label: 'Callback',
    statusName: 'followup',
    subStatusName: 'followup_call_back',
    followupMinutes: 60,
  },
  wrong_number: {
    label: 'Wrong Number',
    statusName: 'junk',
    subStatusName: 'junk_invalid_number',
  },
};

export function splitFullName(fullName: string | null | undefined) {
  const trimmed = (fullName || '').trim();
  if (!trimmed) {
    return { firstName: '', lastName: '' };
  }

  const [firstName, ...rest] = trimmed.split(/\s+/);
  return {
    firstName,
    lastName: rest.join(' '),
  };
}

export function formatLeadSubtitle(lead: Pick<MobileQueueLead, 'course' | 'specialization' | 'city'>) {
  return [lead.course, lead.specialization, lead.city].filter(Boolean).join(' • ');
}

export const EMPTY_MOBILE_LEAD_FILTERS: MobileLeadFilters = {
  assignedTo: [],
  campaignNames: [],
  channels: [],
  sources: [],
  statuses: [],
  subStatuses: [],
  cities: [],
};

function addDayBoundary(date: string | undefined, boundary: 'start' | 'end') {
  if (!date) return undefined;
  return boundary === 'start'
    ? `${date}T00:00:00.000`
    : `${date}T23:59:59.999`;
}

function uniqueOptions(values: Array<string | null | undefined>): MobileFilterOption[] {
  return [...new Set(values.map((value) => value?.trim()).filter(Boolean) as string[])]
    .sort((a, b) => a.localeCompare(b))
    .map((value) => ({ value, label: value }));
}

function applyMobileLeadFilters(query: any, filters: MobileLeadFilters) {
  let nextQuery = query;

  if (filters.assignedTo.length > 0) {
    nextQuery = nextQuery.in('current_lead_owner', filters.assignedTo);
  }
  if (filters.campaignNames.length > 0) {
    nextQuery = nextQuery.in('campaign_name', filters.campaignNames);
  }
  if (filters.channels.length > 0) {
    nextQuery = nextQuery.in('channel', filters.channels);
  }
  if (filters.sources.length > 0) {
    nextQuery = nextQuery.in('source_id', filters.sources);
  }
  if (filters.statuses.length > 0) {
    nextQuery = nextQuery.in('status_id', filters.statuses);
  }
  if (filters.subStatuses.length > 0) {
    nextQuery = nextQuery.in('sub_status_id', filters.subStatuses);
  }
  if (filters.cities.length > 0) {
    nextQuery = nextQuery.in('city', filters.cities);
  }

  const createdFrom = addDayBoundary(filters.dateAddedFrom, 'start');
  const createdTo = addDayBoundary(filters.dateAddedTo, 'end');
  const updatedFrom = addDayBoundary(filters.dateEditedFrom, 'start');
  const updatedTo = addDayBoundary(filters.dateEditedTo, 'end');

  if (createdFrom) {
    nextQuery = nextQuery.gte('created_at', createdFrom);
  }
  if (createdTo) {
    nextQuery = nextQuery.lte('created_at', createdTo);
  }
  if (updatedFrom) {
    nextQuery = nextQuery.gte('updated_at', updatedFrom);
  }
  if (updatedTo) {
    nextQuery = nextQuery.lte('updated_at', updatedTo);
  }
  if (filters.callCountMin !== undefined) {
    nextQuery = nextQuery.gte('call_count', filters.callCountMin);
  }
  if (filters.callCountMax !== undefined) {
    nextQuery = nextQuery.lte('call_count', filters.callCountMax);
  }

  return nextQuery;
}

export async function getLeadStatuses(organizationId: string): Promise<StatusOption[]> {
  const { data, error } = await supabase
    .from('lead_statuses')
    .select('id, name, display_name, color, status_type, parent_status_id, requires_sub_status')
    .eq('organization_id', organizationId)
    .eq('is_active', true)
    .order('order_index');

  if (error) {
    throw error;
  }

  return (data || []) as StatusOption[];
}

export async function getMobileLeadFilterOptions(organizationId: string): Promise<MobileLeadFilterOptions> {
  const [ownersRes, sourcesRes, statusesRes, campaignsRes, cityChannelRes] = await Promise.all([
    supabase
      .from('profiles')
      .select('id, full_name')
      .eq('organization_id', organizationId)
      .order('full_name'),
    supabase
      .from('lead_sources')
      .select('id, name, color')
      .eq('is_active', true)
      .order('name'),
    getLeadStatuses(organizationId),
    supabase.rpc('get_distinct_campaign_names', {
      p_organization_id: organizationId,
      p_limit: 200,
    }),
    supabase
      .from('leads')
      .select('city, channel')
      .eq('organization_id', organizationId)
      .limit(500),
  ]);

  if (ownersRes.error) throw ownersRes.error;
  if (sourcesRes.error) throw sourcesRes.error;
  if (campaignsRes.error) throw campaignsRes.error;
  if (cityChannelRes.error) throw cityChannelRes.error;

  const owners: MobileFilterOption[] = (ownersRes.data || []).map((owner) => ({
    value: owner.id,
    label: owner.full_name || 'Unnamed user',
  }));

  const sources: MobileFilterOption[] = (sourcesRes.data || []).map((source) => ({
    value: source.id,
    label: source.name,
    color: source.color,
  }));

  const campaigns = uniqueOptions(
    (campaignsRes.data || []).map((row: any) => row.campaign_name)
  );

  const channels = uniqueOptions((cityChannelRes.data || []).map((row) => row.channel));
  const cities = uniqueOptions((cityChannelRes.data || []).map((row) => row.city));

  return {
    owners,
    campaigns,
    channels,
    sources,
    statuses: statusesRes,
    cities,
  };
}

export async function getRepQueue(userId: string, limit = 25): Promise<MobileQueueLead[]> {
  const { data, error } = await supabase.rpc('mobile_get_rep_queue', { p_limit: limit });

  if (error) {
    const cachedQueue = await loadCachedQueue(userId);
    if (cachedQueue.length > 0) {
      return cachedQueue;
    }
    throw error;
  }

  const queue = (data || []) as MobileQueueLead[];
  await cacheQueue(userId, queue);
  return queue;
}

export async function getNextLead(userId: string): Promise<MobileQueueLead | null> {
  const queue = await getRepQueue(userId, 1);
  return queue[0] ?? null;
}

export async function getTeamSummary(): Promise<TeamSummary | null> {
  const { data, error } = await supabase.rpc('mobile_get_team_summary');
  if (error) {
    throw error;
  }

  return (data || null) as TeamSummary | null;
}

export async function getDashboardSummary(
  organizationId: string,
  userId: string,
  period: 'today' | 'week' | 'month' = 'week'
): Promise<MobileDashboardSummary> {
  const today = new Date().toISOString().slice(0, 10);

  // Compute the "since" cutoff based on period (Issue #25 fix)
  const periodMs = period === 'today'
    ? 24 * 60 * 60 * 1000
    : period === 'week'
    ? 7 * 24 * 60 * 60 * 1000
    : 30 * 24 * 60 * 60 * 1000;
  const sinceDate = new Date(Date.now() - periodMs).toISOString();

  const [ownedLeadsRes, recentUpdatesRes, ownedLeadIdsRes] = await Promise.all([
    supabase
      .from('leads')
      .select('id', { count: 'exact', head: true })
      .eq('organization_id', organizationId)
      .eq('current_lead_owner', userId),
    supabase
      .from('leads')
      .select('id', { count: 'exact', head: true })
      .eq('organization_id', organizationId)
      .eq('current_lead_owner', userId)
      .gte('updated_at', sinceDate),
    supabase
      .from('leads')
      .select('id')
      .eq('organization_id', organizationId)
      .eq('current_lead_owner', userId)
      .limit(1000),
  ]);

  const firstError = ownedLeadsRes.error || recentUpdatesRes.error || ownedLeadIdsRes.error;

  if (firstError) {
    throw firstError;
  }

  const ownedLeadIds = (ownedLeadIdsRes.data || []).map((lead) => lead.id);

  if (ownedLeadIds.length === 0) {
    return {
      owned_lead_count: ownedLeadsRes.count || 0,
      pending_followups: 0,
      today_followups: 0,
      recent_updates: recentUpdatesRes.count || 0,
    };
  }

  const [pendingFollowupsRes, todayFollowupsRes] = await Promise.all([
    supabase
      .from('followups')
      .select('id', { count: 'exact', head: true })
      .eq('organization_id', organizationId)
      .eq('status', 'pending')
      .in('lead_id', ownedLeadIds),
    supabase
      .from('followups')
      .select('id', { count: 'exact', head: true })
      .eq('organization_id', organizationId)
      .eq('status', 'pending')
      .eq('next_action_date', today)
      .in('lead_id', ownedLeadIds),
  ]);

  const followupError = pendingFollowupsRes.error || todayFollowupsRes.error;
  if (followupError) {
    throw followupError;
  }

  return {
    owned_lead_count: ownedLeadsRes.count || 0,
    pending_followups: pendingFollowupsRes.count || 0,
    today_followups: todayFollowupsRes.count || 0,
    recent_updates: recentUpdatesRes.count || 0,
  };
}

export async function getLeadDetails(leadId: string, organizationId: string) {
  const { data, error } = await supabase
    .from('leads')
    .select(`
      id,
      name,
      email,
      mobile_number,
      city,
      state,
      country,
      course,
      specialization,
      company,
      university,
      campaign_name,
      channel,
      call_count,
      status_id,
      sub_status_id,
      current_lead_owner,
      created_at,
      updated_at,
      total_dials,
      connected_calls,
      last_called_at,
      last_call_outcome,
      lead_statuses!leads_status_id_fkey(display_name, color),
      sub_status:lead_statuses!leads_sub_status_id_fkey(display_name, color),
      owner:profiles!leads_current_lead_owner_fkey(full_name)
    `)
    .eq('id', leadId)
    .eq('organization_id', organizationId)
    .single();

  if (error) {
    throw error;
  }

  return data;
}

export async function searchLeads(
  organizationId: string,
  searchTerm: string,
  filters: MobileLeadFilters = EMPTY_MOBILE_LEAD_FILTERS
) {
  const trimmed = searchTerm.trim();
  let query = supabase
    .from('leads')
    .select(`
      id,
      name,
      email,
      mobile_number,
      city,
      course,
      specialization,
      campaign_name,
      call_count,
      status_id,
      sub_status_id,
      current_lead_owner,
      updated_at,
      total_dials,
      connected_calls,
      last_called_at,
      last_call_outcome,
      lead_statuses!leads_status_id_fkey(display_name, color),
      sub_status:lead_statuses!leads_sub_status_id_fkey(display_name),
      owner:profiles!leads_current_lead_owner_fkey(full_name)
    `)
    .eq('organization_id', organizationId)
    .order('updated_at', { ascending: false })
    .limit(40);

  query = applyMobileLeadFilters(query, filters);

  if (trimmed) {
    query = query.or(
      `name.ilike.%${trimmed}%,email.ilike.%${trimmed}%,mobile_number.ilike.%${trimmed}%,course.ilike.%${trimmed}%`
    );
  }

  const { data, error } = await query;

  if (error) {
    throw error;
  }

  return (data || []).map((lead: any) => ({
    lead_id: lead.id,
    name: lead.name,
    email: lead.email,
    mobile_number: lead.mobile_number,
    city: lead.city,
    course: lead.course,
    specialization: lead.specialization,
    campaign_name: lead.campaign_name,
    call_count: lead.call_count ?? 0,
    lead_value: null,
    status_id: lead.status_id,
    status_name: lead.lead_statuses?.display_name ?? null,
    status_color: lead.lead_statuses?.color ?? null,
    sub_status_id: lead.sub_status_id,
    sub_status_name: lead.sub_status?.display_name ?? null,
    current_lead_owner: lead.current_lead_owner,
    owner_name: lead.owner?.full_name ?? null,
    next_action_date: null,
    next_action_time: null,
    followup_status: null,
    is_overdue: false,
    last_updated: lead.updated_at,
    total_dials: lead.total_dials ?? 0,
    connected_calls: lead.connected_calls ?? 0,
    last_called_at: lead.last_called_at ?? null,
    last_call_outcome: lead.last_call_outcome ?? null,
  })) as MobileQueueLead[];
}

export async function getFollowups(
  organizationId: string,
  userId: string,
  filter: 'all' | 'today' | 'pending'
) {
  // Filter by user_id so reps only see their own follow-ups (Issue #5 fix)
  let query = supabase
    .from('followups')
    .select(`
      id,
      lead_id,
      next_action_date,
      next_action_time,
      followup_remarks,
      status,
      lead:leads(name, mobile_number)
    `)
    .eq('organization_id', organizationId)
    .eq('user_id', userId)
    .order('next_action_date', { ascending: true })
    .order('next_action_time', { ascending: true });

  if (filter === 'pending') {
    query = query.eq('status', 'pending');
  }

  if (filter === 'today') {
    const today = new Date().toISOString().slice(0, 10);
    query = query.eq('status', 'pending').eq('next_action_date', today);
  }

  const { data, error } = await query;
  if (error) {
    throw error;
  }

  return (data || []) as FollowupItem[];
}

export async function markFollowupComplete(followupId: string) {
  const { error } = await supabase
    .from('followups')
    .update({ status: 'completed' })
    .eq('id', followupId);

  if (error) {
    throw error;
  }
}

export function resolveQuickOutcome(
  statuses: StatusOption[],
  outcome: NativeCallOutcome
): { statusId: string | null; subStatusId: string | null; defaultFollowupAt: string | null } {
  const definition = QUICK_OUTCOMES[outcome];

  // Try exact match first, then case-insensitive, then partial match
  function findStatus(targetName: string) {
    const lower = targetName.toLowerCase();
    return (
      statuses.find((s) => s.name === targetName) ||
      statuses.find((s) => s.name?.toLowerCase() === lower) ||
      statuses.find((s) => s.name?.toLowerCase().includes(lower)) ||
      statuses.find((s) => s.display_name?.toLowerCase().includes(lower))
    );
  }

  const mainStatus = findStatus(definition.statusName);
  const subStatus = findStatus(definition.subStatusName);

  if (!mainStatus) {
    console.warn(`[resolveQuickOutcome] No status found for "${definition.statusName}" (outcome: ${outcome}). Available:`, statuses.map((s) => s.name).join(', '));
  }
  if (!subStatus) {
    console.warn(`[resolveQuickOutcome] No sub-status found for "${definition.subStatusName}" (outcome: ${outcome}). Available:`, statuses.map((s) => s.name).join(', '));
  }

  const defaultFollowupAt = definition.followupMinutes
    ? new Date(Date.now() + definition.followupMinutes * 60_000).toISOString()
    : null;

  return {
    statusId: mainStatus?.id ?? null,
    subStatusId: subStatus?.id ?? null,
    defaultFollowupAt,
  };
}

export async function quickUpdateLead(userId: string, input: QuickUpdateInput): Promise<{ queuedOffline: boolean }> {
  let error;
  if (input.disposition === 'manual_update') {
    const res = await supabase.rpc('mobile_quick_update_lead', {
      p_lead_id: input.leadId,
      p_status_id: input.statusId ?? null,
      p_sub_status_id: input.subStatusId ?? null,
      p_note: input.note ?? null,
      p_next_followup_at: input.nextFollowupAt ?? null,
      p_disposition: input.disposition ?? null,
    });
    error = res.error;
  } else {
    // It's a real call outcome
    const res = await supabase.rpc('mobile_log_call_outcome', {
      p_lead_id: input.leadId,
      p_outcome: input.disposition,
      p_talk_time_secs: input.talkTimeSecs ?? null,
      p_notes: input.note ?? null,
      p_next_followup: input.nextFollowupAt ?? null,
      p_called_at: input.calledAt ?? null,
      p_status_id: input.statusId ?? null,
      p_sub_status_id: input.subStatusId ?? null,
    });
    error = res.error;
  }

  if (error) {
    if (shouldQueueOffline(error)) {
      await enqueueQuickUpdate(userId, input);
      return { queuedOffline: true };
    }

    throw error;
  }

  return { queuedOffline: false };
}

export async function flushPendingQuickUpdates(userId: string): Promise<{
  flushedCount: number;
  remainingCount: number;
  errors: string[];
}> {
  const pending = await listPendingQuickUpdates(userId);
  if (pending.length === 0) {
    return { flushedCount: 0, remainingCount: 0, errors: [] };
  }

  const remaining = [];
  const errors: string[] = [];
  let flushedCount = 0;

  for (const update of pending) {
    const { error } = await supabase.rpc('mobile_log_call_outcome', {
      p_lead_id: update.leadId,
      p_outcome: update.disposition,
      p_talk_time_secs: update.talkTimeSecs ?? null,
      p_notes: update.note ?? null,
      p_next_followup: update.nextFollowupAt ?? null,
      p_called_at: update.calledAt ?? null,
    });

    if (error) {
      // Issue #22 fix: Track errors instead of silently swallowing them
      const msg = error.message || 'Unknown error';
      errors.push(`Lead ${update.leadId}: ${msg}`);
      // Only keep in queue if it's a network error (retriable)
      if (shouldQueueOffline(error)) {
        remaining.push(update);
      } else {
        // Non-retriable error (e.g. lead deleted, permissions) — discard after logging
        console.warn('[flushPendingQuickUpdates] Discarding non-retriable update:', update.leadId, msg);
      }
    } else {
      flushedCount += 1;
    }
  }

  if (remaining.length === 0) {
    await clearPendingQuickUpdates(userId);
  } else {
    await replacePendingQuickUpdates(userId, remaining);
  }

  return { flushedCount, remainingCount: remaining.length, errors };
}

export async function getAgentCallSummary(
  organizationId: string,
  userId: string,
  period: 'today' | 'week' | 'month' = 'week'
) {
  const periodMs = period === 'today'
    ? 24 * 60 * 60 * 1000
    : period === 'week'
    ? 7 * 24 * 60 * 60 * 1000
    : 30 * 24 * 60 * 60 * 1000;
  const sinceDate = period === 'today' 
    ? new Date(new Date().setHours(0,0,0,0)).toISOString() 
    : new Date(Date.now() - periodMs).toISOString();

  const { data, error } = await supabase.rpc('get_agent_call_summary', {
    p_organization_id: organizationId,
    p_agent_id: userId,
    p_from_date: sinceDate,
  });

  if (error) {
    console.error('Error fetching call summary', error);
    return null;
  }

  return data?.[0] || null;
}
