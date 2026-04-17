import { View, Text, TouchableOpacity, ScrollView, Alert } from 'react-native';
import { useRouter } from 'expo-router';
import { LogOut, User, Mail, Phone, Building2, Shield } from 'lucide-react-native';
import { useAuth } from '../../mobile/contexts/AuthContext';

export default function ProfileScreen() {
  const { user, profile, signOut } = useAuth();
  const router = useRouter();

  const handleSignOut = async () => {
    Alert.alert(
      'Sign Out',
      'Are you sure you want to sign out?',
      [
        { text: 'Cancel', style: 'cancel' },
        {
          text: 'Sign Out',
          style: 'destructive',
          onPress: async () => {
            await signOut();
            router.replace('/(auth)/login');
          },
        },
      ]
    );
  };

  const InfoRow = ({ icon: Icon, label, value }: any) => (
    <View className="flex-row items-center py-4 border-b border-gray-100">
      <View className="bg-gray-100 p-2 rounded-full mr-4">
        <Icon size={20} color="#6b7280" />
      </View>
      <View className="flex-1">
        <Text className="text-sm text-gray-600 mb-1">{label}</Text>
        <Text className="text-base text-gray-900 font-medium">{value || 'Not set'}</Text>
      </View>
    </View>
  );

  return (
    <ScrollView className="flex-1 bg-gray-50">
      <View className="bg-blue-600 px-4 pt-12 pb-8">
        <View className="items-center">
          <View className="bg-white w-24 h-24 rounded-full items-center justify-center mb-4">
            <User size={40} color="#2563eb" />
          </View>
          <Text className="text-white text-2xl font-bold">
            {profile?.first_name && profile?.last_name
              ? `${profile.first_name} ${profile.last_name}`
              : 'User Profile'}
          </Text>
          <Text className="text-blue-100 mt-1">{user?.email}</Text>
        </View>
      </View>

      <View className="bg-white rounded-t-3xl -mt-6 px-4 pt-6">
        <Text className="text-lg font-semibold text-gray-900 mb-4">Account Information</Text>

        <InfoRow icon={User} label="Full Name" value={
          profile?.first_name && profile?.last_name
            ? `${profile.first_name} ${profile.last_name}`
            : 'Not set'
        } />
        <InfoRow icon={Mail} label="Email" value={user?.email} />
        <InfoRow icon={Phone} label="Mobile Number" value={profile?.mobile_number} />
        <InfoRow icon={Shield} label="Role" value={profile?.role_name || 'User'} />
        <InfoRow icon={Building2} label="Organization" value={profile?.organization_name || 'Not set'} />

        <View className="mt-8 mb-6">
          <TouchableOpacity
            className="bg-red-600 py-4 rounded-lg flex-row items-center justify-center"
            onPress={handleSignOut}
          >
            <LogOut size={20} color="white" />
            <Text className="text-white font-semibold ml-2 text-base">Sign Out</Text>
          </TouchableOpacity>
        </View>

        <View className="items-center py-4">
          <Text className="text-gray-500 text-sm">CRM Mobile v1.0.0</Text>
        </View>
      </View>
    </ScrollView>
  );
}
