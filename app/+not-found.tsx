import { View, Text } from 'react-native';
import { Link } from 'expo-router';

export default function NotFoundScreen() {
  return (
    <View className="flex-1 items-center justify-center bg-white">
      <Text className="text-2xl font-bold text-gray-900 mb-2">Screen not found</Text>
      <Link href="/(tabs)" className="text-blue-600 mt-4">
        Go to Home
      </Link>
    </View>
  );
}
