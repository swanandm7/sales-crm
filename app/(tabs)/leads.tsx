import { View, Text, FlatList, TouchableOpacity, TextInput, RefreshControl, Linking, Alert } from 'react-native';
import { useState, useEffect } from 'react';
import { useRouter } from 'expo-router';
import { Search, Phone, Mail, MessageCircle, Plus } from 'lucide-react-native';
import { useAuth } from '../../mobile/contexts/AuthContext';
import { supabase } from '../../src/lib/supabase';

interface Lead {
  id: string;
  name: string;
  email: string;
  phone: string;
  status: string;
  sub_status: string;
  created_at: string;
}

export default function LeadsScreen() {
  const { profile } = useAuth();
  const router = useRouter();
  const [leads, setLeads] = useState<Lead[]>([]);
  const [filteredLeads, setFilteredLeads] = useState<Lead[]>([]);
  const [searchQuery, setSearchQuery] = useState('');
  const [refreshing, setRefreshing] = useState(false);
  const [loading, setLoading] = useState(true);

  const loadLeads = async () => {
    if (!profile?.organization_id) return;

    try {
      const { data, error } = await supabase
        .from('leads')
        .select('id, name, email, phone, status, sub_status, created_at')
        .eq('organization_id', profile.organization_id)
        .order('created_at', { ascending: false })
        .limit(50);

      if (error) throw error;
      setLeads(data || []);
      setFilteredLeads(data || []);
    } catch (error) {
      console.error('Error loading leads:', error);
      Alert.alert('Error', 'Failed to load leads');
    } finally {
      setLoading(false);
      setRefreshing(false);
    }
  };

  useEffect(() => {
    loadLeads();
  }, [profile?.organization_id]);

  useEffect(() => {
    if (searchQuery.trim()) {
      const filtered = leads.filter(
        (lead) =>
          lead.name.toLowerCase().includes(searchQuery.toLowerCase()) ||
          lead.email.toLowerCase().includes(searchQuery.toLowerCase()) ||
          lead.phone.includes(searchQuery)
      );
      setFilteredLeads(filtered);
    } else {
      setFilteredLeads(leads);
    }
  }, [searchQuery, leads]);

  const onRefresh = () => {
    setRefreshing(true);
    loadLeads();
  };

  const handleCall = (phone: string) => {
    Linking.openURL(`tel:${phone}`);
  };

  const handleEmail = (email: string) => {
    Linking.openURL(`mailto:${email}`);
  };

  const handleWhatsApp = (phone: string) => {
    const cleanPhone = phone.replace(/\D/g, '');
    Linking.openURL(`https://wa.me/${cleanPhone}`);
  };

  const getStatusColor = (status: string) => {
    switch (status) {
      case 'new':
        return 'bg-blue-100 text-blue-800';
      case 'contacted':
        return 'bg-yellow-100 text-yellow-800';
      case 'qualified':
        return 'bg-green-100 text-green-800';
      case 'converted':
        return 'bg-purple-100 text-purple-800';
      case 'lost':
        return 'bg-red-100 text-red-800';
      default:
        return 'bg-gray-100 text-gray-800';
    }
  };

  const renderLead = ({ item }: { item: Lead }) => (
    <TouchableOpacity
      className="bg-white rounded-xl p-4 mb-3 shadow-sm border border-gray-100"
      onPress={() => router.push(`/lead/${item.id}`)}
    >
      <View className="flex-row justify-between items-start mb-3">
        <View className="flex-1">
          <Text className="text-lg font-semibold text-gray-900 mb-1">{item.name}</Text>
          <Text className="text-sm text-gray-600">{item.email}</Text>
          <Text className="text-sm text-gray-600">{item.phone}</Text>
        </View>
        <View className={`px-3 py-1 rounded-full ${getStatusColor(item.status)}`}>
          <Text className="text-xs font-medium capitalize">{item.status}</Text>
        </View>
      </View>

      {item.sub_status && (
        <Text className="text-xs text-gray-500 mb-3">Sub-status: {item.sub_status}</Text>
      )}

      <View className="flex-row space-x-2">
        <TouchableOpacity
          className="flex-1 bg-blue-50 py-2 rounded-lg flex-row items-center justify-center"
          onPress={() => handleCall(item.phone)}
        >
          <Phone size={16} color="#2563eb" />
          <Text className="text-blue-600 ml-2 font-medium">Call</Text>
        </TouchableOpacity>
        <TouchableOpacity
          className="flex-1 bg-green-50 py-2 rounded-lg flex-row items-center justify-center"
          onPress={() => handleWhatsApp(item.phone)}
        >
          <MessageCircle size={16} color="#16a34a" />
          <Text className="text-green-600 ml-2 font-medium">WhatsApp</Text>
        </TouchableOpacity>
        <TouchableOpacity
          className="flex-1 bg-gray-50 py-2 rounded-lg flex-row items-center justify-center"
          onPress={() => handleEmail(item.email)}
        >
          <Mail size={16} color="#6b7280" />
          <Text className="text-gray-600 ml-2 font-medium">Email</Text>
        </TouchableOpacity>
      </View>
    </TouchableOpacity>
  );

  return (
    <View className="flex-1 bg-gray-50">
      <View className="bg-white px-4 py-3 border-b border-gray-200">
        <View className="flex-row items-center bg-gray-100 rounded-lg px-3 py-2">
          <Search size={20} color="#6b7280" />
          <TextInput
            className="flex-1 ml-2 text-base"
            placeholder="Search leads..."
            value={searchQuery}
            onChangeText={setSearchQuery}
          />
        </View>
      </View>

      <FlatList
        data={filteredLeads}
        renderItem={renderLead}
        keyExtractor={(item) => item.id}
        contentContainerStyle={{ padding: 16 }}
        refreshControl={<RefreshControl refreshing={refreshing} onRefresh={onRefresh} />}
        ListEmptyComponent={
          <View className="items-center justify-center py-12">
            <Users size={48} color="#9ca3af" />
            <Text className="text-gray-500 mt-4">No leads found</Text>
          </View>
        }
      />

      <TouchableOpacity className="absolute bottom-6 right-6 bg-blue-600 w-14 h-14 rounded-full items-center justify-center shadow-lg">
        <Plus size={24} color="white" />
      </TouchableOpacity>
    </View>
  );
}
