import { View, Text, ScrollView, TouchableOpacity, RefreshControl } from 'react-native';
import { useState, useEffect } from 'react';
import { Users, CircleCheck as CheckCircle2, Clock, TrendingUp } from 'lucide-react-native';
import { useAuth } from '../../mobile/contexts/AuthContext';
import { supabase } from '../../src/lib/supabase';

interface DashboardStats {
  totalLeads: number;
  convertedLeads: number;
  pendingFollowups: number;
  todayFollowups: number;
}

export default function DashboardScreen() {
  const { user, profile } = useAuth();
  const [stats, setStats] = useState<DashboardStats>({
    totalLeads: 0,
    convertedLeads: 0,
    pendingFollowups: 0,
    todayFollowups: 0,
  });
  const [refreshing, setRefreshing] = useState(false);
  const [loading, setLoading] = useState(true);

  const loadStats = async () => {
    if (!profile?.organization_id) return;

    try {
      const today = new Date();
      today.setHours(0, 0, 0, 0);
      const tomorrow = new Date(today);
      tomorrow.setDate(tomorrow.getDate() + 1);

      const { count: totalLeads } = await supabase
        .from('leads')
        .select('*', { count: 'exact', head: true })
        .eq('organization_id', profile.organization_id);

      const { count: convertedLeads } = await supabase
        .from('leads')
        .select('*', { count: 'exact', head: true })
        .eq('organization_id', profile.organization_id)
        .eq('status', 'converted');

      const { count: pendingFollowups } = await supabase
        .from('followups')
        .select('*', { count: 'exact', head: true })
        .eq('organization_id', profile.organization_id)
        .eq('status', 'pending');

      const { count: todayFollowups } = await supabase
        .from('followups')
        .select('*', { count: 'exact', head: true })
        .eq('organization_id', profile.organization_id)
        .eq('status', 'pending')
        .gte('scheduled_at', today.toISOString())
        .lt('scheduled_at', tomorrow.toISOString());

      setStats({
        totalLeads: totalLeads || 0,
        convertedLeads: convertedLeads || 0,
        pendingFollowups: pendingFollowups || 0,
        todayFollowups: todayFollowups || 0,
      });
    } catch (error) {
      console.error('Error loading stats:', error);
    } finally {
      setLoading(false);
      setRefreshing(false);
    }
  };

  useEffect(() => {
    loadStats();
  }, [profile?.organization_id]);

  const onRefresh = () => {
    setRefreshing(true);
    loadStats();
  };

  const StatCard = ({ icon: Icon, label, value, color }: any) => (
    <View className="bg-white rounded-xl p-4 shadow-sm border border-gray-100 flex-1 m-1">
      <View className={`w-12 h-12 rounded-full items-center justify-center mb-3 ${color}`}>
        <Icon size={24} color="white" />
      </View>
      <Text className="text-2xl font-bold text-gray-900 mb-1">{value}</Text>
      <Text className="text-sm text-gray-600">{label}</Text>
    </View>
  );

  return (
    <ScrollView
      className="flex-1 bg-gray-50"
      refreshControl={<RefreshControl refreshing={refreshing} onRefresh={onRefresh} />}
    >
      <View className="p-4">
        <View className="mb-6">
          <Text className="text-2xl font-bold text-gray-900">
            Welcome back, {profile?.first_name || 'User'}!
          </Text>
          <Text className="text-gray-600 mt-1">Here's your CRM overview</Text>
        </View>

        <View className="flex-row flex-wrap -m-1">
          <StatCard
            icon={Users}
            label="Total Leads"
            value={stats.totalLeads}
            color="bg-blue-600"
          />
          <StatCard
            icon={CheckCircle2}
            label="Converted"
            value={stats.convertedLeads}
            color="bg-green-600"
          />
        </View>

        <View className="flex-row flex-wrap -m-1 mt-2">
          <StatCard
            icon={Clock}
            label="Pending Follow-ups"
            value={stats.pendingFollowups}
            color="bg-orange-600"
          />
          <StatCard
            icon={TrendingUp}
            label="Today's Tasks"
            value={stats.todayFollowups}
            color="bg-purple-600"
          />
        </View>

        <View className="mt-6 bg-white rounded-xl p-4 shadow-sm border border-gray-100">
          <Text className="text-lg font-semibold text-gray-900 mb-3">Quick Actions</Text>
          <TouchableOpacity className="bg-blue-600 py-3 rounded-lg mb-3">
            <Text className="text-white text-center font-semibold">Add New Lead</Text>
          </TouchableOpacity>
          <TouchableOpacity className="bg-gray-100 py-3 rounded-lg">
            <Text className="text-gray-900 text-center font-semibold">View All Leads</Text>
          </TouchableOpacity>
        </View>
      </View>
    </ScrollView>
  );
}
