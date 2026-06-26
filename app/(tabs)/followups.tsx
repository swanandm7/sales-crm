import { useEffect, useState } from 'react';
import {
  Alert,
  FlatList,
  RefreshControl,
  Text,
  TouchableOpacity,
  View,
} from 'react-native';
import { useRouter } from 'expo-router';
import { CheckCircle2, Circle, Phone, Calendar, Clock } from '../../mobile/components/icons';
import { EmptyState, ToneDot } from '../../mobile/components/design';
import { useAuth } from '../../mobile/contexts/AuthContext';
import { useMobilePreferences } from '../../mobile/contexts/MobilePreferencesContext';
import { getFollowups, markFollowupComplete } from '../../mobile/lib/leadQueue';
import type { FollowupItem } from '../../mobile/lib/types';

export default function FollowupsScreen() {
  const { profile, user } = useAuth();
  const { theme, preferences } = useMobilePreferences();
  const router = useRouter();
  const [filter, setFilter] = useState<'all' | 'today' | 'pending'>('pending');
  const [followups, setFollowups] = useState<FollowupItem[]>([]);
  const [refreshing, setRefreshing] = useState(false);

  const loadFollowups = async () => {
    if (!profile?.organization_id || !user?.id) return;
    try {
      // Pass user.id so reps only see their own follow-ups (Issue #5 fix)
      const data = await getFollowups(profile.organization_id, user.id, filter);
      setFollowups(data);
    } catch (error) {
      console.error('Error loading follow-ups:', error);
      Alert.alert('Unable to load follow-ups', 'Please try again in a moment.');
    } finally {
      setRefreshing(false);
    }
  };

  useEffect(() => {
    loadFollowups();
  }, [filter, profile?.organization_id, user?.id]);

  const onRefresh = () => {
    setRefreshing(true);
    loadFollowups();
  };

  const handleMarkComplete = async (followupId: string) => {
    try {
      await markFollowupComplete(followupId);
      // Optimistic update — remove from list immediately
      setFollowups((prev) => prev.filter((f) => f.id !== followupId));
    } catch (error) {
      console.error('Error marking follow-up complete:', error);
      Alert.alert('Could not update', 'The follow-up could not be marked complete.');
      // Reload to get accurate state
      loadFollowups();
    }
  };

  const handleOpenLead = (leadId: string) => {
    // Navigate to lead detail — calls made from there will be properly logged (Issue #16 fix)
    router.push(`/lead/${leadId}`);
  };

  const renderFollowup = ({ item }: { item: FollowupItem }) => {
    const dueDate = new Date(`${item.next_action_date}T${item.next_action_time}`);
    const overdue = item.status === 'pending' && dueDate.getTime() < Date.now();
    const leadName = item.lead?.name || 'Lead follow-up';
    const isToday = dueDate.toDateString() === new Date().toDateString();

    return (
      <TouchableOpacity
        style={{
          marginBottom: 12,
          borderRadius: 16,
          backgroundColor: theme.surface,
          borderWidth: 1,
          borderColor: overdue ? theme.danger + '55' : theme.border,
          padding: 14,
          overflow: 'hidden',
        }}
        onPress={() => handleOpenLead(item.lead_id)}
        activeOpacity={0.8}
      >
        {/* Left accent stripe for overdue */}
        {overdue ? (
          <View
            style={{
              position: 'absolute',
              left: 0,
              top: 0,
              bottom: 0,
              width: 4,
              backgroundColor: theme.danger,
              borderTopLeftRadius: 16,
              borderBottomLeftRadius: 16,
            }}
          />
        ) : isToday ? (
          <View
            style={{
              position: 'absolute',
              left: 0,
              top: 0,
              bottom: 0,
              width: 4,
              backgroundColor: theme.warning,
              borderTopLeftRadius: 16,
              borderBottomLeftRadius: 16,
            }}
          />
        ) : null}

        <View style={{ flexDirection: 'row', alignItems: 'flex-start', gap: 12, paddingLeft: overdue || isToday ? 8 : 0 }}>
          <View style={{ flex: 1 }}>
            {/* Lead name + status badge */}
            <View style={{ flexDirection: 'row', alignItems: 'center', gap: 8, marginBottom: 4 }}>
              <Text
                style={{ color: theme.text, fontSize: 15, fontWeight: '800', flex: 1 }}
                numberOfLines={1}
              >
                {leadName}
              </Text>
              <View
                style={{
                  flexDirection: 'row',
                  alignItems: 'center',
                  gap: 4,
                  backgroundColor: overdue ? theme.dangerSoft : isToday ? theme.warningSoft : theme.surface2,
                  paddingHorizontal: 8,
                  paddingVertical: 3,
                  borderRadius: 999,
                }}
              >
                <ToneDot
                  color={overdue ? theme.danger : isToday ? theme.warning : theme.accent}
                  size={5}
                />
                <Text
                  style={{
                    color: overdue ? theme.danger : isToday ? theme.warning : theme.accent,
                    fontSize: 10.5,
                    fontWeight: '800',
                  }}
                >
                  {overdue ? 'Overdue' : isToday ? 'Today' : item.status}
                </Text>
              </View>
            </View>

            {/* Remarks */}
            {item.followup_remarks ? (
              <Text
                style={{
                  color: theme.textDim,
                  fontSize: 12.5,
                  lineHeight: 18,
                  marginBottom: 8,
                }}
                numberOfLines={2}
              >
                {item.followup_remarks}
              </Text>
            ) : null}

            {/* Date + time + phone number */}
            <View style={{ flexDirection: 'row', alignItems: 'center', gap: 8, flexWrap: 'wrap' }}>
              <View style={{ flexDirection: 'row', alignItems: 'center', gap: 4 }}>
                <Calendar size={12} color={overdue ? theme.danger : theme.textMute} />
                <Text
                  style={{
                    color: overdue ? theme.danger : theme.textMute,
                    fontSize: 11.5,
                    fontWeight: '700',
                  }}
                >
                  {item.next_action_date}
                </Text>
              </View>
              <View style={{ flexDirection: 'row', alignItems: 'center', gap: 4 }}>
                <Clock size={12} color={theme.textMute} />
                <Text style={{ color: theme.textMute, fontSize: 11.5, fontWeight: '700' }}>
                  {item.next_action_time?.slice(0, 5) || '--:--'}
                </Text>
              </View>
              {item.lead?.mobile_number ? (
                <View style={{ flexDirection: 'row', alignItems: 'center', gap: 4 }}>
                  <Phone size={12} color={theme.textMute} />
                  <Text style={{ color: theme.textMute, fontSize: 11.5 }}>
                    {item.lead.mobile_number}
                  </Text>
                </View>
              ) : null}
            </View>
          </View>

          {/* Action buttons */}
          <View style={{ flexDirection: 'column', gap: 8, alignItems: 'center' }}>
            {/* Open Lead + Call button — navigates to lead detail for proper call logging */}
            <TouchableOpacity
              style={{
                width: 40,
                height: 40,
                borderRadius: 20,
                backgroundColor: theme.accent,
                alignItems: 'center',
                justifyContent: 'center',
              }}
              onPress={(event) => {
                event.stopPropagation();
                // Navigate to lead detail — calls made there are properly tracked (Issue #16 fix)
                handleOpenLead(item.lead_id);
              }}
            >
              <Phone size={16} color={theme.onAccent} />
            </TouchableOpacity>

            {/* Mark complete button */}
            {item.status === 'pending' ? (
              <TouchableOpacity
                style={{
                  width: 40,
                  height: 40,
                  borderRadius: 20,
                  backgroundColor: 'transparent',
                  borderWidth: 1.5,
                  borderColor: theme.border,
                  alignItems: 'center',
                  justifyContent: 'center',
                }}
                onPress={(event) => {
                  event.stopPropagation();
                  Alert.alert(
                    'Mark complete?',
                    `Mark the follow-up for "${leadName}" as done?`,
                    [
                      { text: 'Cancel', style: 'cancel' },
                      { text: 'Mark done', onPress: () => handleMarkComplete(item.id) },
                    ]
                  );
                }}
              >
                <Circle size={14} color={theme.textMute} />
              </TouchableOpacity>
            ) : (
              <View
                style={{
                  width: 40,
                  height: 40,
                  borderRadius: 20,
                  backgroundColor: theme.successSoft,
                  alignItems: 'center',
                  justifyContent: 'center',
                }}
              >
                <CheckCircle2 size={14} color={theme.success} />
              </View>
            )}
          </View>
        </View>
      </TouchableOpacity>
    );
  };

  const overdueCount = followups.filter((item) => {
    const dueDate = new Date(`${item.next_action_date}T${item.next_action_time}`);
    return item.status === 'pending' && dueDate.getTime() < Date.now();
  }).length;

  const todayCount = followups.filter((item) => {
    const dueDate = new Date(`${item.next_action_date}T${item.next_action_time}`);
    return dueDate.toDateString() === new Date().toDateString();
  }).length;

  const tabCounts: Record<'today' | 'pending' | 'all', number> = {
    today: todayCount,
    pending: followups.filter((f) => f.status === 'pending').length,
    all: followups.length,
  };

  return (
    <View style={{ flex: 1, backgroundColor: theme.bg }}>
      {/* Header */}
      <View style={{ paddingHorizontal: 16, paddingTop: 14, paddingBottom: 10 }}>
        <Text style={{ color: theme.text, fontSize: 22, fontWeight: '800', letterSpacing: -0.4 }}>
          Follow-ups
        </Text>
        <Text style={{ color: theme.textDim, fontSize: 12, marginTop: 3 }}>
          {followups.length} open ·{' '}
          <Text style={{ color: theme.danger, fontWeight: '800' }}>{overdueCount} overdue</Text>
          {todayCount > 0 ? (
            <Text style={{ color: theme.warning, fontWeight: '700' }}> · {todayCount} due today</Text>
          ) : null}
        </Text>

        {/* Tab selector */}
        <View
          style={{
            flexDirection: 'row',
            gap: 8,
            marginTop: 14,
            backgroundColor: theme.surface,
            borderRadius: 18,
            borderWidth: 1,
            borderColor: theme.border,
            padding: 4,
          }}
        >
          {(['today', 'pending', 'all'] as const).map((tab) => (
            <TouchableOpacity
              key={tab}
              style={{
                flex: 1,
                borderRadius: 14,
                paddingVertical: 11,
                backgroundColor: filter === tab ? theme.accent : 'transparent',
                alignItems: 'center',
                justifyContent: 'center',
                flexDirection: 'row',
                gap: 6,
              }}
              onPress={() => setFilter(tab)}
            >
              <Text
                style={{
                  color: filter === tab ? theme.onAccent : theme.textDim,
                  fontWeight: '900',
                  fontSize: 13,
                }}
              >
                {tab === 'pending' ? 'Pending' : tab === 'today' ? 'Today' : 'All'}
              </Text>
              <View
                style={{
                  borderRadius: 8,
                  paddingHorizontal: 6,
                  paddingVertical: 1,
                  backgroundColor: filter === tab ? 'rgba(0,0,0,0.15)' : theme.surface2,
                }}
              >
                <Text
                  style={{
                    color: filter === tab ? theme.onAccent : theme.textMute,
                    fontSize: 10,
                    fontWeight: '800',
                  }}
                >
                  {tabCounts[tab]}
                </Text>
              </View>
            </TouchableOpacity>
          ))}
        </View>
      </View>

      {/* Overdue banner */}
      {overdueCount > 0 && filter !== 'all' ? (
        <View style={{ paddingHorizontal: 16, paddingBottom: 8 }}>
          <View
            style={{
              backgroundColor: theme.dangerSoft,
              borderWidth: 1,
              borderColor: theme.danger + '40',
              borderRadius: 12,
              paddingVertical: 10,
              paddingHorizontal: 14,
              flexDirection: 'row',
              alignItems: 'center',
              gap: 10,
            }}
          >
            <Text style={{ fontSize: 16 }}>🚨</Text>
            <Text style={{ color: theme.text, fontSize: 12.5, fontWeight: '700', flex: 1 }}>
              <Text style={{ color: theme.danger, fontWeight: '900' }}>{overdueCount} overdue</Text>{' '}
              — tap any card to open the lead and log the call outcome.
            </Text>
          </View>
        </View>
      ) : null}

      <FlatList
        data={followups}
        renderItem={renderFollowup}
        keyExtractor={(item) => item.id}
        contentContainerStyle={{
          padding: 16,
          paddingBottom: preferences.bottomNavStyle === 'pill' ? 110 : 88,
        }}
        refreshControl={
          <RefreshControl refreshing={refreshing} onRefresh={onRefresh} tintColor={theme.accent} />
        }
        ListEmptyComponent={
          <View style={{ paddingTop: 40 }}>
            <EmptyState
              title={filter === 'today' ? 'No follow-ups today 🎉' : 'No follow-ups here'}
              body={
                filter === 'today'
                  ? "You're all caught up for today. Check 'Pending' for upcoming ones."
                  : "When a lead needs another touchpoint, it will show up here."
              }
              theme={theme}
            />
          </View>
        }
      />
    </View>
  );
}
