import { useEffect, useMemo, useRef, useState } from 'react';
import {
  ActivityIndicator,
  Alert,
  Animated,
  BackHandler,
  Keyboard,
  Linking,
  Modal,
  ScrollView,
  Text,
  TextInput,
  TouchableOpacity,
  TouchableWithoutFeedback,
  View,
  AppState,
} from 'react-native';
import { useLocalSearchParams, useRouter } from 'expo-router';
import {
  ArrowLeft,
  CalendarClock,
  CheckCircle2,
  Mail,
  MessageCircle,
  MoreHorizontal,
  Phone,
  PhoneCall,
  X,
  BellOff,
  PhoneForwarded,
  PhoneOff,
  Trophy,
  Trash,
  ClipboardList,
} from '../../mobile/components/icons';
import { Avatar, LeadDetailSkeleton, Pill, ToneDot } from '../../mobile/components/design';
import { useAuth } from '../../mobile/contexts/AuthContext';
import { useMobilePreferences } from '../../mobile/contexts/MobilePreferencesContext';
import {
  getLeadDetails,
  getLeadStatuses,
  QUICK_OUTCOMES,
  quickUpdateLead,
  resolveQuickOutcome,
} from '../../mobile/lib/leadQueue';
import type { NativeCallOutcome, StatusOption } from '../../mobile/lib/types';

const OUTCOME_TONES: Record<NativeCallOutcome, 'success' | 'warning' | 'info' | 'danger' | 'muted'> = {
  connected: 'success',
  not_connected_no_answer: 'warning',
  callback_requested: 'info',
  wrong_number: 'danger',
  not_connected_switched_off: 'muted',
  not_connected_busy: 'danger',
};

const OUTCOME_ICONS: Record<NativeCallOutcome, any> = {
  connected: Phone,
  not_connected_no_answer: BellOff,
  callback_requested: PhoneForwarded,
  wrong_number: X,
  not_connected_switched_off: PhoneOff, // I need to import PhoneOff! Wait.
  not_connected_busy: PhoneOff,
};

function toFollowupIso(preset: 'today' | 'tomorrow' | 'three_days' | 'week') {
  const date = new Date();
  if (preset === 'today') date.setHours(17, 0, 0, 0);
  if (preset === 'tomorrow') {
    date.setDate(date.getDate() + 1);
    date.setHours(11, 0, 0, 0);
  }
  if (preset === 'three_days') date.setDate(date.getDate() + 3);
  if (preset === 'week') date.setDate(date.getDate() + 7);
  return date.toISOString();
}

function formatFollowupDisplay(isoString: string) {
  const d = new Date(isoString);
  return d.toLocaleString('en-IN', {
    day: '2-digit',
    month: 'short',
    hour: '2-digit',
    minute: '2-digit',
  });
}

export default function LeadDetailScreen() {
  const { id, autoCall } = useLocalSearchParams<any>();
  const router = useRouter();
  const { profile, user } = useAuth();
  const { theme } = useMobilePreferences();
  const [lead, setLead] = useState<any>(null);
  const [statuses, setStatuses] = useState<StatusOption[]>([]);
  const [selectedStatusId, setSelectedStatusId] = useState<string | null>(null);
  const [selectedSubStatusId, setSelectedSubStatusId] = useState<string | null>(null);
  const [note, setNote] = useState('');
  const [followupAt, setFollowupAt] = useState('');
  const [saving, setSaving] = useState(false);
  const [loading, setLoading] = useState(true);

  // Call-guard state: once the rep dials, they must fill status before going back
  const [hasDialed, setHasDialed] = useState(false);
  const [showCallGuardModal, setShowCallGuardModal] = useState(false);
  const [selectedOutcome, setSelectedOutcome] = useState<NativeCallOutcome | null>(null);
  const [savingOutcome, setSavingOutcome] = useState(false);
  const [talkTimeMinutes, setTalkTimeMinutes] = useState('');
  const [dialedAt, setDialedAt] = useState<string | null>(null);
  const autoCallProcessed = useRef(false);

  const appState = useRef(AppState.currentState);

  const pulseAnim = useRef(new Animated.Value(1)).current;
  // Mutex ref — prevents concurrent save calls from inline buttons + modal (Issue #7 fix)
  const savingRef = useRef(false);

  const mainStatuses = useMemo(() => statuses.filter((status) => status.status_type === 'main'), [statuses]);
  const subStatuses = useMemo(
    () => statuses.filter((status) => status.parent_status_id === selectedStatusId),
    [statuses, selectedStatusId]
  );

  // Pulse animation for the call button after dialing
  useEffect(() => {
    if (hasDialed) {
      const pulse = Animated.loop(
        Animated.sequence([
          Animated.timing(pulseAnim, { toValue: 1.08, duration: 700, useNativeDriver: true }),
          Animated.timing(pulseAnim, { toValue: 1.0, duration: 700, useNativeDriver: true }),
        ])
      );
      pulse.start();
      return () => pulse.stop();
    }
  }, [hasDialed]);

  // Android hardware back button guard
  useEffect(() => {
    if (!hasDialed) return;
    const sub = BackHandler.addEventListener('hardwareBackPress', () => {
      setShowCallGuardModal(true);
      return true; // prevent default back
    });
    return () => sub.remove();
  }, [hasDialed]);

  // Handle return from native dialer (trigger modal)
  useEffect(() => {
    const subscription = AppState.addEventListener('change', (nextAppState) => {
      if (!hasDialed) return;
      // When returning from background (i.e. returning from dialer), force open the modal
      if (appState.current.match(/inactive|background/) && nextAppState === 'active') {
        setShowCallGuardModal(true);
      }
      appState.current = nextAppState;
    });
    return () => subscription.remove();
  }, [hasDialed]);

  useEffect(() => {
    const load = async () => {
      if (!id || id === 'undefined' || !profile?.organization_id) return;
      try {
        const [details, statusOptions] = await Promise.all([
          getLeadDetails(id, profile.organization_id),
          getLeadStatuses(profile.organization_id),
        ]);
        setLead(details);
        setStatuses(statusOptions);
        setSelectedStatusId(details.status_id);
        setSelectedSubStatusId(details.sub_status_id);
      } catch (error) {
        console.error('Error loading lead details:', error);
        Alert.alert('Lead unavailable', 'We could not load this lead right now.');
      } finally {
        setLoading(false);
      }
    };

    load();
  }, [id, profile?.organization_id]);

  useEffect(() => {
    if (lead?.mobile_number && autoCall === 'true' && !autoCallProcessed.current && !loading) {
      autoCallProcessed.current = true;
      handleDial();
    }
  }, [lead, autoCall, loading]);

  const handleBack = () => {
    if (hasDialed) {
      setShowCallGuardModal(true);
    } else {
      router.back();
    }
  };

  const handleDial = async () => {
    if (!lead?.mobile_number) {
      Alert.alert('No mobile number', 'This lead does not have a callable number yet.');
      return;
    }
    try {
      const url = `tel:${lead.mobile_number}`;
      const supported = await Linking.canOpenURL(url);
      if (supported) {
        setDialedAt(new Date().toISOString());
        setHasDialed(true);
        await Linking.openURL(url);
      } else {
        Alert.alert('Cannot open dialer', 'Please dial manually: ' + lead.mobile_number);
      }
    } catch (e) {
      Alert.alert('Cannot open dialer', 'Please dial manually: ' + lead.mobile_number);
    }
  };

  const handleWhatsApp = async () => {
    if (!lead?.mobile_number) return;
    const phone = lead.mobile_number.replace(/\D/g, '');
    const url = `whatsapp://send?phone=${phone}`;
    try {
      const canOpen = await Linking.canOpenURL(url);
      if (canOpen) {
        await Linking.openURL(url);
      } else {
        await Linking.openURL(`https://wa.me/${phone}`);
      }
    } catch {
      await Linking.openURL(`https://wa.me/${phone}`);
    }
  };

  const handleQuickOutcome = async (outcome: NativeCallOutcome) => {
    if (!lead || !user?.id) return;
    
    let talkTimeSecs: number | null = null;
    if (outcome === 'connected') {
      if (!talkTimeMinutes) {
        Alert.alert('Required', 'Please enter talk time in minutes for connected calls.');
        return;
      }
      const parsedTime = parseFloat(talkTimeMinutes);
      if (isNaN(parsedTime) || parsedTime < 0 || !/^\d*\.?\d*$/.test(talkTimeMinutes.trim())) {
        Alert.alert('Invalid format', 'Please enter a valid number for talk time (e.g. 5 or 2.5).');
        return;
      }
      talkTimeSecs = Math.round(parsedTime * 60);
    }

    // Mutex guard
    if (savingRef.current) return;
    savingRef.current = true;

    const resolved = resolveQuickOutcome(statuses, outcome);
    setSavingOutcome(true);
    try {
      await quickUpdateLead(user.id, {
        leadId: lead.id,
        disposition: outcome,
        statusId: resolved.statusId,
        subStatusId: resolved.subStatusId,
        note: note.trim() || `Quick outcome: ${QUICK_OUTCOMES[outcome].label}`,
        nextFollowupAt: resolved.defaultFollowupAt,
        talkTimeSecs,
        calledAt: dialedAt,
      });
      // After successful save, clear the dialed guard and go back
      setHasDialed(false);
      setShowCallGuardModal(false);
      setSelectedOutcome(outcome);
      setNote('');
      setTalkTimeMinutes('');
      Keyboard.dismiss();
      setTimeout(() => router.back(), 400);
    } catch (error) {
      console.error('Quick outcome failed:', error);
      Alert.alert('Save failed', 'We could not save that outcome. Please try again.');
    } finally {
      setSavingOutcome(false);
      savingRef.current = false;
    }
  };

  const handleManualSave = async () => {
    if (!lead || !user?.id) return;
    if (!selectedStatusId) {
      Alert.alert('Status required', 'Please select a status before saving.');
      return;
    }
    // Mutex guard — prevent double-save (Issue #7 fix)
    if (savingRef.current) return;
    savingRef.current = true;

    setSaving(true);
    try {
      await quickUpdateLead(user.id, {
        leadId: lead.id,
        disposition: 'manual_update',
        statusId: selectedStatusId,
        subStatusId: selectedSubStatusId,
        note: note.trim() || undefined,
        nextFollowupAt: followupAt || undefined,
      });
      setHasDialed(false);
      setShowCallGuardModal(false);
      setNote(''); // Clear note after success
      Keyboard.dismiss(); // Dismiss keyboard
      router.back();
    } catch (error) {
      console.error('Manual lead save failed:', error);
      Alert.alert('Save failed', 'We could not save that lead update.');
    } finally {
      setSaving(false);
      savingRef.current = false;
    }
  };

  if (loading) {
    return <LeadDetailSkeleton theme={theme} />;
  }

  if (!lead) {
    return (
      <View style={{ flex: 1, alignItems: 'center', justifyContent: 'center', backgroundColor: theme.bg }}>
        <Text style={{ color: theme.textDim, marginBottom: 20 }}>Lead not found.</Text>
        <TouchableOpacity
          onPress={() => router.back()}
          style={{
            paddingHorizontal: 20,
            paddingVertical: 10,
            backgroundColor: theme.surface2,
            borderRadius: 8,
          }}
        >
          <Text style={{ color: theme.text, fontWeight: '700' }}>Go Back</Text>
        </TouchableOpacity>
      </View>
    );
  }

  const currentStatus = lead.lead_statuses?.display_name || 'Unstaged';
  const currentSubStatus = lead.sub_status?.display_name || null;

  const selectedStatusName = mainStatuses.find((s) => s.id === selectedStatusId)?.display_name;
  const selectedSubStatusName = subStatuses.find((s) => s.id === selectedSubStatusId)?.display_name;

  const ActionTile = ({
    icon,
    label,
    color,
    filled,
    onPress,
    disabled,
  }: {
    icon: React.ReactNode;
    label: string;
    color: string;
    filled?: boolean;
    onPress?: () => void;
    disabled?: boolean;
  }) => (
    <TouchableOpacity
      onPress={onPress}
      disabled={disabled}
      style={{
        flex: 1,
        height: 68,
        borderRadius: 16,
        borderWidth: 1.5,
        borderColor: filled ? color : theme.border,
        backgroundColor: filled ? color : theme.surface,
        alignItems: 'center',
        justifyContent: 'center',
        gap: 6,
        opacity: disabled ? 0.5 : 1,
      }}
    >
      {icon}
      <Text style={{ color: filled ? '#fff' : color, fontSize: 11, fontWeight: '800' }}>{label}</Text>
    </TouchableOpacity>
  );

  const FieldRow = ({
    icon,
    label,
    value,
    mono = false,
  }: {
    icon: React.ReactNode;
    label: string;
    value: string;
    mono?: boolean;
  }) => (
    <View
      style={{
        paddingVertical: 12,
        paddingHorizontal: 14,
        flexDirection: 'row',
        alignItems: 'center',
        gap: 12,
        borderBottomWidth: 1,
        borderBottomColor: theme.borderSoft,
      }}
    >
      <View
        style={{
          width: 32,
          height: 32,
          borderRadius: 16,
          backgroundColor: theme.surface2,
          alignItems: 'center',
          justifyContent: 'center',
        }}
      >
        {icon}
      </View>
      <View style={{ flex: 1 }}>
        <Text style={{ color: theme.textMute, fontSize: 11, fontWeight: '700', marginBottom: 2 }}>{label}</Text>
        <Text
          style={{ color: theme.text, fontSize: 13.5, fontWeight: '700', fontFamily: mono ? 'monospace' : undefined }}
          numberOfLines={1}
        >
          {value}
        </Text>
      </View>
    </View>
  );

  const ContextCell = ({ label, value }: { label: string; value: string | number | null | undefined }) => (
    <View
      style={{
        width: '48.5%',
        borderRadius: 10,
        backgroundColor: theme.surface,
        borderWidth: 1,
        borderColor: theme.border,
        paddingVertical: 9,
        paddingHorizontal: 10,
      }}
    >
      <Text style={{ color: theme.textMute, fontSize: 10, fontWeight: '800', letterSpacing: 0.6, textTransform: 'uppercase' }}>
        {label}
      </Text>
      <Text style={{ color: theme.text, fontSize: 12.5, fontWeight: '700', marginTop: 3 }} numberOfLines={1}>
        {value || 'Not set'}
      </Text>
    </View>
  );

  return (
    <View style={{ flex: 1, backgroundColor: theme.bg }}>
      {/* CALL GUARD MODAL */}
      <Modal visible={showCallGuardModal} transparent animationType="slide">
        <TouchableWithoutFeedback onPress={Keyboard.dismiss}>
          <View
            style={{
              flex: 1,
              backgroundColor: 'rgba(0,0,0,0.65)',
              justifyContent: 'flex-end',
            }}
          >
            <TouchableWithoutFeedback>
          <View
            style={{
              backgroundColor: theme.surface,
              borderTopLeftRadius: 24,
              borderTopRightRadius: 24,
              padding: 24,
              paddingBottom: 40,
            }}
          >
            <View style={{ alignItems: 'center', marginBottom: 18 }}>
              <View style={{ marginBottom: 12 }}>
                <ClipboardList size={36} color={theme.text} />
              </View>
              <Text style={{ color: theme.text, fontSize: 20, fontWeight: '900', textAlign: 'center' }}>
                Log call outcome
              </Text>
              <Text style={{ color: theme.textDim, fontSize: 13, textAlign: 'center', marginTop: 6, lineHeight: 20 }}>
                You made a call to {lead.name}. Choose what happened so the lead is updated correctly.
              </Text>
            </View>

            {/* Quick outcomes in the modal */}
            <View style={{ flexDirection: 'row', flexWrap: 'wrap', gap: 10, marginBottom: 16 }}>
              {(Object.keys(QUICK_OUTCOMES) as NativeCallOutcome[]).map((key) => {
                const tone = OUTCOME_TONES[key];
                const color =
                  tone === 'success'
                    ? theme.success
                    : tone === 'danger'
                    ? theme.danger
                    : tone === 'warning'
                    ? theme.warning
                    : tone === 'info'
                    ? theme.info
                    : theme.textDim;
                const isSelected = selectedOutcome === key;

                return (
                  <TouchableOpacity
                    key={key}
                    onPress={() => setSelectedOutcome(key)}
                    disabled={savingOutcome}
                    style={{
                      width: '47%',
                      borderRadius: 14,
                      backgroundColor: isSelected ? color : theme.surface2,
                      borderWidth: 1.5,
                      borderColor: isSelected ? color : theme.border,
                      paddingVertical: 14,
                      paddingHorizontal: 12,
                      flexDirection: 'row',
                      alignItems: 'center',
                      gap: 10,
                      opacity: savingOutcome ? 0.6 : 1,
                    }}
                  >
                    {(() => {
                      const Icon = OUTCOME_ICONS[key] || Phone;
                      return <Icon size={20} color={isSelected ? '#fff' : color} />;
                    })()}
                    <Text
                      style={{
                        color: isSelected ? '#fff' : color,
                        fontSize: 13.5,
                        fontWeight: '800',
                        flexShrink: 1,
                      }}
                    >
                      {QUICK_OUTCOMES[key].label}
                    </Text>
                  </TouchableOpacity>
                );
              })}
            </View>

            {/* Talk Time Field */}
            {selectedOutcome === 'connected' && (
              <View style={{ marginBottom: 16 }}>
                <Text style={{ color: theme.textMute, fontSize: 11, fontWeight: '800', letterSpacing: 1.1, marginBottom: 8 }}>
                  TALK TIME (MINUTES)
                </Text>
                <TextInput
                  style={{
                    backgroundColor: theme.surface2,
                    borderWidth: 1,
                    borderColor: theme.border,
                    borderRadius: 12,
                    color: theme.text,
                    paddingHorizontal: 14,
                    paddingVertical: 12,
                    fontSize: 15,
                  }}
                  keyboardType="numeric"
                  placeholder="e.g. 5"
                  placeholderTextColor={theme.textMute}
                  value={talkTimeMinutes}
                  onChangeText={setTalkTimeMinutes}
                />
              </View>
            )}

            {/* Note field in modal */}
            <View style={{ marginBottom: 20 }}>
              <TextInput
                style={{
                  borderRadius: 14,
                  borderWidth: 1,
                  borderColor: theme.border,
                  backgroundColor: theme.bg,
                  color: theme.text,
                  padding: 12,
                  fontSize: 14,
                  minHeight: 64,
                  textAlignVertical: 'top',
                }}
                placeholder="Add a quick note (optional)"
                placeholderTextColor={theme.textMute}
                value={note}
                onChangeText={setNote}
                multiline
              />
            </View>

            {/* Save Button */}
            <View style={{ flexDirection: 'row', marginBottom: 12 }}>
              <TouchableOpacity
                onPress={() => selectedOutcome && handleQuickOutcome(selectedOutcome)}
                disabled={savingOutcome || !selectedOutcome}
                style={{
                  flex: 1,
                  backgroundColor: selectedOutcome ? theme.accent : theme.surface2,
                  borderRadius: 14,
                  paddingVertical: 14,
                  alignItems: 'center',
                }}
              >
                {savingOutcome ? (
                  <ActivityIndicator color="#fff" />
                ) : (
                  <Text style={{ color: selectedOutcome ? theme.onAccent : theme.textMute, fontSize: 16, fontWeight: '800' }}>
                    Save Outcome
                  </Text>
                )}
              </TouchableOpacity>
            </View>

            {/* Skip Call (Cancel guard) */}
            <TouchableOpacity
              disabled={savingOutcome}
              onPress={() => {
                Alert.alert(
                  'Skip tracking?',
                  'This call will not be recorded. Are you sure?',
                  [
                    { text: 'Stay', style: 'cancel' },
                    {
                      text: 'Leave anyway',
                      style: 'destructive',
                      onPress: () => {
                        setHasDialed(false);
                        setShowCallGuardModal(false);
                        router.back();
                      },
                    },
                  ]
                );
              }}
              style={{ paddingVertical: 14, alignItems: 'center' }}
            >
              <Text style={{ color: theme.textMute, fontSize: 13, fontWeight: '700' }}>Skip (don't log this call)</Text>
            </TouchableOpacity>
            </View>
          </TouchableWithoutFeedback>
        </View>
      </TouchableWithoutFeedback>
    </Modal>

      {/* HEADER */}
      <View
        style={{
          paddingHorizontal: 12,
          paddingTop: 52,
          paddingBottom: 12,
          borderBottomWidth: 1,
          borderBottomColor: theme.borderSoft,
          backgroundColor: theme.bg,
        }}
      >
        <View style={{ flexDirection: 'row', alignItems: 'center', gap: 8 }}>
          <TouchableOpacity
            onPress={handleBack}
            style={{
              width: 40,
              height: 40,
              borderRadius: 20,
              backgroundColor: hasDialed ? theme.warningSoft : theme.surface,
              borderWidth: 1,
              borderColor: hasDialed ? theme.warning : theme.border,
              alignItems: 'center',
              justifyContent: 'center',
            }}
          >
            <ArrowLeft size={18} color={hasDialed ? theme.warning : theme.text} />
          </TouchableOpacity>
          <View style={{ flex: 1 }}>
            <Text style={{ color: theme.text, fontSize: 16, fontWeight: '800' }} numberOfLines={1}>
              {lead.name}
            </Text>
            <Text style={{ color: theme.textMute, fontSize: 11, fontFamily: 'monospace' }} numberOfLines={1}>
              {lead.id}
            </Text>
          </View>
          {hasDialed ? (
            <View
              style={{
                paddingHorizontal: 10,
                paddingVertical: 5,
                borderRadius: 999,
                backgroundColor: theme.warningSoft,
                borderWidth: 1,
                borderColor: theme.warning,
              }}
            >
              <Text style={{ color: theme.warning, fontSize: 11, fontWeight: '800' }}>📋 Log required</Text>
            </View>
          ) : (
            <TouchableOpacity
              style={{
                width: 40,
                height: 40,
                borderRadius: 20,
                backgroundColor: theme.surface,
                borderWidth: 1,
                borderColor: theme.border,
                alignItems: 'center',
                justifyContent: 'center',
              }}
            >
              <MoreHorizontal size={18} color={theme.text} />
            </TouchableOpacity>
          )}
        </View>
      </View>

      {/* CALL LOGGED BANNER */}
      {hasDialed ? (
        <View
          style={{
            marginHorizontal: 16,
            marginTop: 12,
            backgroundColor: theme.warningSoft,
            borderRadius: 12,
            borderWidth: 1,
            borderColor: theme.warning,
            paddingVertical: 10,
            paddingHorizontal: 14,
            flexDirection: 'row',
            alignItems: 'center',
            gap: 10,
          }}
        >
          <Phone size={20} color={theme.warning} />
          <View style={{ flex: 1 }}>
            <Text style={{ color: theme.warning, fontSize: 13, fontWeight: '800' }}>Call in progress / completed</Text>
            <Text style={{ color: theme.textDim, fontSize: 11, marginTop: 2 }}>
              Please select an outcome below before leaving this screen.
            </Text>
          </View>
        </View>
      ) : null}

      <ScrollView style={{ flex: 1 }} contentContainerStyle={{ paddingBottom: 32 }}>
        {/* LEAD HEADER */}
        <View style={{ paddingHorizontal: 16, paddingTop: 16, paddingBottom: 12, flexDirection: 'row', alignItems: 'center', gap: 14 }}>
          <Avatar name={lead.name} theme={theme} size={56} />
          <View style={{ flex: 1 }}>
            <Text style={{ color: theme.text, fontSize: 20, fontWeight: '800', letterSpacing: -0.4 }} numberOfLines={1}>
              {lead.name}
            </Text>
            <Text style={{ color: theme.textDim, fontSize: 12.5, marginTop: 3 }} numberOfLines={1}>
              {[lead.course, lead.city].filter(Boolean).join(' · ') || lead.mobile_number || lead.email || 'Lead'}
            </Text>
          </View>
        </View>

        {/* STATUS PILL */}
        <View style={{ paddingHorizontal: 16, paddingBottom: 14 }}>
          <View
            style={{
              backgroundColor: theme.surface,
              borderWidth: 1,
              borderColor: theme.border,
              borderRadius: 14,
              padding: 14,
              flexDirection: 'row',
              alignItems: 'center',
              gap: 12,
            }}
          >
            <View style={{ flex: 1 }}>
              <Text style={{ color: theme.textMute, fontSize: 10.5, fontWeight: '800', letterSpacing: 1, marginBottom: 7 }}>
                CURRENT STATUS
              </Text>
              <View style={{ flexDirection: 'row', alignItems: 'center', gap: 8, flexWrap: 'wrap' }}>
                <Pill label={currentStatus} theme={theme} tone="accent" />
                {currentSubStatus ? (
                  <Text style={{ color: theme.textDim, fontSize: 12.5 }}>· {currentSubStatus}</Text>
                ) : null}
              </View>
            </View>
          </View>
        </View>

        {/* ACTION TILES: CALL / WHATSAPP / EMAIL */}
        <View style={{ paddingHorizontal: 16, paddingBottom: 16 }}>
          <Animated.View style={{ transform: [{ scale: hasDialed ? pulseAnim : 1 }], flex: 1 }}>
            <View style={{ flexDirection: 'row', gap: 10 }}>
              <ActionTile
                icon={<Phone size={22} color="#fff" />}
                label={hasDialed ? 'Call again' : 'Call'}
                color={theme.accent}
                filled
                onPress={handleDial}
              />
              <ActionTile
                icon={<MessageCircle size={22} color="#25D366" />}
                label="WhatsApp"
                color="#25D366"
                onPress={handleWhatsApp}
              />
              <ActionTile
                icon={<Mail size={22} color={theme.info} />}
                label="Email"
                color={theme.info}
                onPress={() => lead.email && Linking.openURL(`mailto:${lead.email}`)}
              />
            </View>
          </Animated.View>
        </View>

        {/* CONTACT INFO */}
        <View style={{ paddingHorizontal: 16, paddingBottom: 14 }}>
          <View
            style={{
              backgroundColor: theme.surface,
              borderWidth: 1,
              borderColor: theme.border,
              borderRadius: 14,
              overflow: 'hidden',
            }}
          >
            <FieldRow icon={<Phone size={14} color={theme.textDim} />} label="Mobile" value={lead.mobile_number || 'Not set'} mono />
            <FieldRow icon={<Mail size={14} color={theme.textDim} />} label="Email" value={lead.email || 'Not set'} />
            <FieldRow icon={<ToneDot color={theme.textDim} size={8} />} label="City" value={lead.city || 'Not set'} />
          </View>
        </View>

        {/* LEAD CONTEXT */}
        <View style={{ paddingHorizontal: 16, paddingBottom: 14 }}>
          <Text style={{ color: theme.textMute, fontSize: 11, fontWeight: '800', letterSpacing: 1.1, marginBottom: 8 }}>
            LEAD CONTEXT
          </Text>
          <View style={{ flexDirection: 'row', flexWrap: 'wrap', gap: 8 }}>
            <ContextCell label="Campaign" value={lead.campaign_name} />
            <ContextCell label="Channel" value={lead.channel} />
            <ContextCell label="Owner" value={lead.owner?.full_name || 'Unassigned'} />
            <ContextCell label="Calls" value={lead.call_count ?? 0} />
            <ContextCell label="Course" value={lead.course} />
            <ContextCell label="University" value={lead.university} />
          </View>
        </View>

        {/* NEXT FOLLOW-UP DISPLAY */}
        <View style={{ paddingHorizontal: 16, paddingBottom: 14 }}>
          <View
            style={{
              backgroundColor: theme.surface,
              borderWidth: 1,
              borderColor: followupAt ? theme.accentRing : theme.border,
              borderRadius: 14,
              padding: 14,
              flexDirection: 'row',
              alignItems: 'center',
              gap: 12,
            }}
          >
            <View
              style={{
                width: 40,
                height: 40,
                borderRadius: 20,
                backgroundColor: followupAt ? theme.accentSoft : theme.surface2,
                alignItems: 'center',
                justifyContent: 'center',
              }}
            >
              <CalendarClock size={18} color={followupAt ? theme.accent : theme.textDim} />
            </View>
            <View style={{ flex: 1 }}>
              <Text style={{ color: theme.textMute, fontSize: 11, fontWeight: '800', letterSpacing: 0.8 }}>
                NEXT FOLLOW-UP
              </Text>
              <Text
                style={{
                  color: followupAt ? theme.text : theme.textDim,
                  fontSize: 14,
                  fontWeight: '800',
                  marginTop: 3,
                }}
                numberOfLines={1}
              >
                {followupAt ? formatFollowupDisplay(followupAt) : 'Pick a preset below'}
              </Text>
            </View>
            {followupAt ? (
              <TouchableOpacity onPress={() => setFollowupAt('')}>
                <X size={16} color={theme.textMute} />
              </TouchableOpacity>
            ) : null}
          </View>
        </View>

        {/* ─── QUICK OUTCOME SECTION ─── */}
        <View style={{ paddingHorizontal: 16, paddingBottom: 14 }}>
          <View style={{ flexDirection: 'row', alignItems: 'center', marginBottom: 10, gap: 8 }}>
            <Text style={{ color: theme.textMute, fontSize: 11, fontWeight: '800', letterSpacing: 1.1 }}>
              QUICK OUTCOME
            </Text>
            {hasDialed ? (
              <View
                style={{
                  paddingHorizontal: 8,
                  paddingVertical: 3,
                  borderRadius: 999,
                  backgroundColor: theme.warningSoft,
                }}
              >
                <Text style={{ color: theme.warning, fontSize: 10, fontWeight: '800' }}>Required after call</Text>
              </View>
            ) : null}
          </View>
          <View style={{ flexDirection: 'row', flexWrap: 'wrap', gap: 10 }}>
            {(Object.keys(QUICK_OUTCOMES) as NativeCallOutcome[]).map((key) => {
              const tone = OUTCOME_TONES[key];
              const color =
                tone === 'success'
                  ? theme.success
                  : tone === 'danger'
                  ? theme.danger
                  : tone === 'warning'
                  ? theme.warning
                  : tone === 'info'
                  ? theme.info
                  : theme.textDim;
              const isSelected = selectedOutcome === key;

              return (
                <TouchableOpacity
                  key={key}
                  onPress={() => {
                    setSelectedOutcome(key);
                    handleQuickOutcome(key);
                  }}
                  disabled={saving || savingOutcome}
                  activeOpacity={0.75}
                  style={{
                    width: '47%',
                    borderRadius: 14,
                    backgroundColor: isSelected ? color : theme.surface,
                    borderWidth: 1.5,
                    borderColor: isSelected ? color : hasDialed ? color + '55' : theme.border,
                    paddingVertical: 14,
                    paddingHorizontal: 12,
                    flexDirection: 'row',
                    alignItems: 'center',
                    gap: 10,
                    opacity: saving || savingOutcome ? 0.6 : 1,
                  }}
                >
                  {(() => {
                    const Icon = OUTCOME_ICONS[key] || Phone;
                    return <Icon size={20} color={isSelected ? '#fff' : color} />;
                  })()}
                  <Text
                    style={{
                      color: isSelected ? '#fff' : color,
                      fontSize: 13,
                      fontWeight: '800',
                      flex: 1,
                    }}
                  >
                    {QUICK_OUTCOMES[key].label}
                  </Text>
                </TouchableOpacity>
              );
            })}
          </View>
        </View>

        {/* ─── STATUS UPDATE ─── */}
        <View style={{ paddingHorizontal: 16, paddingBottom: 14 }}>
          <Text style={{ color: theme.textMute, fontSize: 11, fontWeight: '800', letterSpacing: 1.1, marginBottom: 10 }}>
            STATUS UPDATE
          </Text>
          {/* Main status */}
          <Text style={{ color: theme.textMute, fontSize: 10, fontWeight: '700', marginBottom: 6 }}>Main Status</Text>
          <ScrollView horizontal showsHorizontalScrollIndicator={false} style={{ marginBottom: 12 }}>
            {mainStatuses.map((status) => (
              <Pill
                key={status.id}
                label={status.display_name}
                theme={theme}
                active={selectedStatusId === status.id}
                onPress={() => {
                  setSelectedStatusId(status.id);
                  setSelectedSubStatusId(null);
                }}
                style={{ marginRight: 8 }}
              />
            ))}
          </ScrollView>

          {/* Sub status */}
          {selectedStatusId ? (
            <>
              <Text style={{ color: theme.textMute, fontSize: 10, fontWeight: '700', marginBottom: 6 }}>Sub Status</Text>
              <ScrollView horizontal showsHorizontalScrollIndicator={false}>
                {subStatuses.length > 0 ? (
                  subStatuses.map((status) => (
                    <Pill
                      key={status.id}
                      label={status.display_name}
                      theme={theme}
                      active={selectedSubStatusId === status.id}
                      onPress={() => setSelectedSubStatusId(status.id)}
                      style={{ marginRight: 8 }}
                    />
                  ))
                ) : (
                  <Text style={{ color: theme.textMute, fontSize: 12 }}>No sub-statuses for this status.</Text>
                )}
              </ScrollView>
            </>
          ) : null}

          {/* Selected status summary */}
          {selectedStatusName ? (
            <View
              style={{
                marginTop: 10,
                padding: 10,
                borderRadius: 10,
                backgroundColor: theme.accentSoft,
                borderWidth: 1,
                borderColor: theme.accentRing,
                flexDirection: 'row',
                alignItems: 'center',
                gap: 8,
              }}
            >
              <Text style={{ fontSize: 16 }}>✅</Text>
              <Text style={{ color: theme.accent, fontSize: 12, fontWeight: '800' }}>
                {selectedStatusName}
                {selectedSubStatusName ? ` › ${selectedSubStatusName}` : ''}
              </Text>
            </View>
          ) : null}
        </View>

        {/* FOLLOW-UP PRESETS */}
        <View style={{ paddingHorizontal: 16, paddingBottom: 14 }}>
          <Text style={{ color: theme.textMute, fontSize: 11, fontWeight: '800', letterSpacing: 1.1, marginBottom: 8 }}>
            FOLLOW-UP PRESETS
          </Text>
          <View style={{ flexDirection: 'row', flexWrap: 'wrap', gap: 8 }}>
            {[
              ['🌆 Today 5pm', 'today'],
              ['🌅 Tomorrow 11am', 'tomorrow'],
              ['📅 In 3 days', 'three_days'],
              ['📅 Next week', 'week'],
            ].map(([label, preset]) => (
              <TouchableOpacity
                key={preset}
                onPress={() => setFollowupAt(toFollowupIso(preset as any))}
                style={{
                  borderRadius: 999,
                  paddingHorizontal: 14,
                  paddingVertical: 8,
                  backgroundColor: followupAt && toFollowupIso(preset as any).slice(0, 13) === followupAt.slice(0, 13)
                    ? theme.accentSoft
                    : theme.surface,
                  borderWidth: 1,
                  borderColor: theme.border,
                }}
              >
                <Text style={{ color: theme.text, fontSize: 13, fontWeight: '700' }}>{label}</Text>
              </TouchableOpacity>
            ))}
          </View>
        </View>

        {/* NOTE */}
        <View style={{ paddingHorizontal: 16, paddingBottom: 14 }}>
          <View style={{ flexDirection: 'row', alignItems: 'center', justifyContent: 'space-between', marginBottom: 8 }}>
            <Text style={{ color: theme.textMute, fontSize: 11, fontWeight: '800', letterSpacing: 1.1 }}>NOTE</Text>
            {note ? (
              <TouchableOpacity onPress={() => setNote('')} style={{ flexDirection: 'row', alignItems: 'center', gap: 4 }}>
                <X size={12} color={theme.accent} />
                <Text style={{ color: theme.accent, fontSize: 12, fontWeight: '800' }}>Clear</Text>
              </TouchableOpacity>
            ) : null}
          </View>
          <TextInput
            style={{
              minHeight: 86,
              borderRadius: 14,
              borderWidth: 1,
              borderColor: theme.border,
              backgroundColor: theme.surface,
              color: theme.text,
              padding: 13,
              fontSize: 14,
              textAlignVertical: 'top',
            }}
            placeholder="Add a short note..."
            placeholderTextColor={theme.textMute}
            value={note}
            onChangeText={setNote}
            multiline
          />
        </View>

        {/* SAVE BUTTON */}
        <View style={{ paddingHorizontal: 16, paddingBottom: 8 }}>
          <TouchableOpacity
            onPress={handleManualSave}
            disabled={saving || !selectedStatusId}
            style={{
              minHeight: 56,
              borderRadius: 16,
              backgroundColor: selectedStatusId ? theme.accent : theme.surface2,
              alignItems: 'center',
              justifyContent: 'center',
              flexDirection: 'row',
              gap: 10,
              opacity: saving ? 0.7 : 1,
              borderWidth: selectedStatusId ? 0 : 1,
              borderColor: theme.border,
            }}
          >
            {saving ? (
              <ActivityIndicator size="small" color={theme.onAccent} />
            ) : (
              <Text style={{ fontSize: 18 }}>💾</Text>
            )}
            <Text
              style={{
                color: selectedStatusId ? theme.onAccent : theme.textMute,
                fontSize: 15,
                fontWeight: '800',
              }}
            >
              {saving ? 'Saving...' : selectedStatusId ? 'Save & log update' : 'Select a status to save'}
            </Text>
          </TouchableOpacity>
        </View>
      </ScrollView>
    </View>
  );
}
