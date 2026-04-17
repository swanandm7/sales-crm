import { View, Text, ScrollView, TouchableOpacity, Linking, Alert, ActivityIndicator } from 'react-native';
import { useState, useEffect } from 'react';
import { useLocalSearchParams, useRouter } from 'expo-router';
import { Phone, Mail, MessageCircle, Calendar, ArrowLeft, CreditCard as Edit } from 'lucide-react-native';
import { useAuth } from '../../mobile/contexts/AuthContext';
import { supabase } from '../../src/lib/supabase';

interface LeadDetails {
  id: string;
  name: string;
  email: string;
  phone: string;
  status: string;
  sub_status: string;
  source: string;
  budget: number;
  notes: string;
  created_at: string;
}

export default function LeadDetailScreen() {
  const { id } = useLocalSearchParams();
  const router = useRouter();
  const { profile } = useAuth();
  const [lead, setLead] = useState<LeadDetails | null>(null);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    loadLeadDetails();
  }, [id]);

  const loadLeadDetails = async () => {
    if (!id || !profile?.organization_id) return;

    try {
      const { data, error } = await supabase
        .from('leads')
        .select('*')
        .eq('id', id)
        .eq('organization_id', profile.organization_id)
        .single();

      if (error) throw error;
      setLead(data);
    } catch (error) {
      console.error('Error loading lead:', error);
      Alert.alert('Error', 'Failed to load lead details');
    } finally {
      setLoading(false);
    }
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

  if (loading) {
    return (
      <View className="flex-1 bg-white items-center justify-center">
        <ActivityIndicator size="large" color="#2563eb" />
      </View>
    );
  }

  if (!lead) {
    return (
      <View className="flex-1 bg-white items-center justify-center">
        <Text className="text-gray-500">Lead not found</Text>
      </View>
    );
  }

  return (
    <View className="flex-1 bg-gray-50">
      <View className="bg-blue-600 px-4 pt-12 pb-6">
        <TouchableOpacity
          className="mb-4"
          onPress={() => router.back()}
        >
          <ArrowLeft size={24} color="white" />
        </TouchableOpacity>
        <Text className="text-white text-2xl font-bold mb-2">{lead.name}</Text>
        <View className={`self-start px-3 py-1 rounded-full ${getStatusColor(lead.status)}`}>
          <Text className="text-xs font-medium capitalize">{lead.status}</Text>
        </View>
      </View>

      <ScrollView className="flex-1">
        <View className="bg-white mx-4 mt-4 rounded-xl p-4 shadow-sm border border-gray-100">
          <Text className="text-lg font-semibold text-gray-900 mb-4">Contact Information</Text>

          <View className="mb-3">
            <Text className="text-sm text-gray-600 mb-1">Email</Text>
            <Text className="text-base text-gray-900">{lead.email}</Text>
          </View>

          <View className="mb-3">
            <Text className="text-sm text-gray-600 mb-1">Phone</Text>
            <Text className="text-base text-gray-900">{lead.phone}</Text>
          </View>

          {lead.source && (
            <View className="mb-3">
              <Text className="text-sm text-gray-600 mb-1">Source</Text>
              <Text className="text-base text-gray-900 capitalize">{lead.source}</Text>
            </View>
          )}

          {lead.budget && (
            <View className="mb-3">
              <Text className="text-sm text-gray-600 mb-1">Budget</Text>
              <Text className="text-base text-gray-900">${lead.budget.toLocaleString()}</Text>
            </View>
          )}

          {lead.sub_status && (
            <View className="mb-3">
              <Text className="text-sm text-gray-600 mb-1">Sub-status</Text>
              <Text className="text-base text-gray-900 capitalize">{lead.sub_status}</Text>
            </View>
          )}
        </View>

        {lead.notes && (
          <View className="bg-white mx-4 mt-4 rounded-xl p-4 shadow-sm border border-gray-100">
            <Text className="text-lg font-semibold text-gray-900 mb-2">Notes</Text>
            <Text className="text-base text-gray-700">{lead.notes}</Text>
          </View>
        )}

        <View className="mx-4 my-4">
          <Text className="text-lg font-semibold text-gray-900 mb-3">Quick Actions</Text>

          <TouchableOpacity
            className="bg-blue-600 py-4 rounded-lg flex-row items-center justify-center mb-3"
            onPress={() => handleCall(lead.phone)}
          >
            <Phone size={20} color="white" />
            <Text className="text-white font-semibold ml-2">Call Lead</Text>
          </TouchableOpacity>

          <TouchableOpacity
            className="bg-green-600 py-4 rounded-lg flex-row items-center justify-center mb-3"
            onPress={() => handleWhatsApp(lead.phone)}
          >
            <MessageCircle size={20} color="white" />
            <Text className="text-white font-semibold ml-2">WhatsApp</Text>
          </TouchableOpacity>

          <TouchableOpacity
            className="bg-gray-600 py-4 rounded-lg flex-row items-center justify-center mb-3"
            onPress={() => handleEmail(lead.email)}
          >
            <Mail size={20} color="white" />
            <Text className="text-white font-semibold ml-2">Send Email</Text>
          </TouchableOpacity>

          <TouchableOpacity className="bg-white border border-gray-300 py-4 rounded-lg flex-row items-center justify-center">
            <Calendar size={20} color="#4b5563" />
            <Text className="text-gray-700 font-semibold ml-2">Schedule Follow-up</Text>
          </TouchableOpacity>
        </View>
      </ScrollView>
    </View>
  );
}
