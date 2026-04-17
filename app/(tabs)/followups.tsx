import { View, Text, FlatList, TouchableOpacity, RefreshControl, Alert } from 'react-native';
import { useState, useEffect } from 'react';
import { useRouter } from 'expo-router';
import { Calendar, Clock, CircleCheck as CheckCircle2, Circle } from 'lucide-react-native';
import { useAuth } from '../../mobile/contexts/AuthContext';
import { supabase } from '../../src/lib/supabase';

interface Followup {
  id: string;
  title: string;
  description: string;
  scheduled_at: string;
  status: string;
  lead_id: string;
  lead: {
    name: string;
    phone: string;
  };
}

export default function FollowupsScreen() {
  const { profile } = useAuth();
  const router = useRouter();
  const [followups, setFollowups] = useState<Followup[]>([]);
  const [refreshing, setRefreshing] = useState(false);
  const [filter, setFilter] = useState<'all' | 'today' | 'pending'>('pending');

  const loadFollowups = async () => {
    if (!profile?.organization_id) return;

    try {
      let query = supabase
        .from('followups')
        .select(`
          id,
          title,
          description,
          scheduled_at,
          status,
          lead_id,
          lead:leads(name, phone)
        `)
        .eq('organization_id', profile.organization_id)
        .order('scheduled_at', { ascending: true });

      if (filter === 'pending') {
        query = query.eq('status', 'pending');
      } else if (filter === 'today') {
        const today = new Date();
        today.setHours(0, 0, 0, 0);
        const tomorrow = new Date(today);
        tomorrow.setDate(tomorrow.getDate() + 1);

        query = query
          .eq('status', 'pending')
          .gte('scheduled_at', today.toISOString())
          .lt('scheduled_at', tomorrow.toISOString());
      }

      const { data, error } = await query;

      if (error) throw error;
      setFollowups(data || []);
    } catch (error) {
      console.error('Error loading followups:', error);
      Alert.alert('Error', 'Failed to load follow-ups');
    } finally {
      setRefreshing(false);
    }
  };

  useEffect(() => {
    loadFollowups();
  }, [profile?.organization_id, filter]);

  const onRefresh = () => {
    setRefreshing(true);
    loadFollowups();
  };

  const handleMarkComplete = async (id: string) => {
    try {
      const { error } = await supabase
        .from('followups')
        .update({ status: 'completed' })
        .eq('id', id);

      if (error) throw error;
      loadFollowups();
      Alert.alert('Success', 'Follow-up marked as complete');
    } catch (error) {
      Alert.alert('Error', 'Failed to update follow-up');
    }
  };

  const formatDate = (dateString: string) => {
    const date = new Date(dateString);
    const now = new Date();
    const diffDays = Math.floor((date.getTime() - now.getTime()) / (1000 * 60 * 60 * 24));

    if (diffDays === 0) return 'Today';
    if (diffDays === 1) return 'Tomorrow';
    if (diffDays === -1) return 'Yesterday';
    if (diffDays < -1) return `${Math.abs(diffDays)} days ago`;

    return date.toLocaleDateString('en-US', { month: 'short', day: 'numeric' });
  };

  const formatTime = (dateString: string) => {
    const date = new Date(dateString);
    return date.toLocaleTimeString('en-US', { hour: 'numeric', minute: '2-digit' });
  };

  const isOverdue = (dateString: string) => {
    return new Date(dateString) < new Date();
  };

  const renderFollowup = ({ item }: { item: Followup }) => {
    const overdue = isOverdue(item.scheduled_at) && item.status === 'pending';

    return (
      <TouchableOpacity
        className={`bg-white rounded-xl p-4 mb-3 shadow-sm border ${
          overdue ? 'border-red-200' : 'border-gray-100'
        }`}
        onPress={() => router.push(`/lead/${item.lead_id}`)}
      >
        <View className="flex-row justify-between items-start mb-2">
          <View className="flex-1">
            <Text className="text-lg font-semibold text-gray-900 mb-1">{item.title}</Text>
            <Text className="text-sm text-gray-600 mb-2">{item.lead?.name}</Text>
          </View>
          {item.status === 'pending' ? (
            <TouchableOpacity
              className="bg-green-50 p-2 rounded-full"
              onPress={() => handleMarkComplete(item.id)}
            >
              <Circle size={20} color="#16a34a" />
            </TouchableOpacity>
          ) : (
            <View className="bg-green-100 p-2 rounded-full">
              <CheckCircle2 size={20} color="#16a34a" />
            </View>
          )}
        </View>

        {item.description && (
          <Text className="text-sm text-gray-600 mb-3">{item.description}</Text>
        )}

        <View className="flex-row items-center">
          <View className={`flex-row items-center px-3 py-1 rounded-full ${
            overdue ? 'bg-red-100' : 'bg-blue-100'
          }`}>
            <Calendar size={14} color={overdue ? '#dc2626' : '#2563eb'} />
            <Text className={`ml-1 text-xs font-medium ${
              overdue ? 'text-red-700' : 'text-blue-700'
            }`}>
              {formatDate(item.scheduled_at)}
            </Text>
          </View>
          <View className="flex-row items-center ml-2 px-3 py-1 rounded-full bg-gray-100">
            <Clock size={14} color="#6b7280" />
            <Text className="ml-1 text-xs font-medium text-gray-700">
              {formatTime(item.scheduled_at)}
            </Text>
          </View>
        </View>
      </TouchableOpacity>
    );
  };

  return (
    <View className="flex-1 bg-gray-50">
      <View className="bg-white px-4 py-3 border-b border-gray-200">
        <View className="flex-row space-x-2">
          <TouchableOpacity
            className={`flex-1 py-2 rounded-lg ${
              filter === 'pending' ? 'bg-blue-600' : 'bg-gray-100'
            }`}
            onPress={() => setFilter('pending')}
          >
            <Text className={`text-center font-medium ${
              filter === 'pending' ? 'text-white' : 'text-gray-700'
            }`}>
              Pending
            </Text>
          </TouchableOpacity>
          <TouchableOpacity
            className={`flex-1 py-2 rounded-lg ${
              filter === 'today' ? 'bg-blue-600' : 'bg-gray-100'
            }`}
            onPress={() => setFilter('today')}
          >
            <Text className={`text-center font-medium ${
              filter === 'today' ? 'text-white' : 'text-gray-700'
            }`}>
              Today
            </Text>
          </TouchableOpacity>
          <TouchableOpacity
            className={`flex-1 py-2 rounded-lg ${
              filter === 'all' ? 'bg-blue-600' : 'bg-gray-100'
            }`}
            onPress={() => setFilter('all')}
          >
            <Text className={`text-center font-medium ${
              filter === 'all' ? 'text-white' : 'text-gray-700'
            }`}>
              All
            </Text>
          </TouchableOpacity>
        </View>
      </View>

      <FlatList
        data={followups}
        renderItem={renderFollowup}
        keyExtractor={(item) => item.id}
        contentContainerStyle={{ padding: 16 }}
        refreshControl={<RefreshControl refreshing={refreshing} onRefresh={onRefresh} />}
        ListEmptyComponent={
          <View className="items-center justify-center py-12">
            <Calendar size={48} color="#9ca3af" />
            <Text className="text-gray-500 mt-4">No follow-ups found</Text>
          </View>
        }
      />
    </View>
  );
}
