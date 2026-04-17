# CRM Mobile App

This project now includes a fully functional React Native mobile application built with Expo!

## Features

- **Authentication**: Secure login with email/password
- **Dashboard**: Overview of leads, conversions, and follow-ups
- **Leads Management**: View, search, and interact with leads
- **Follow-ups**: Track and manage scheduled follow-ups
- **Quick Actions**: One-tap call, WhatsApp, and email
- **Profile**: User profile and settings

## Running the Mobile App

### Prerequisites

1. Install the Expo Go app on your mobile device:
   - iOS: [Expo Go on App Store](https://apps.apple.com/app/expo-go/id982107779)
   - Android: [Expo Go on Play Store](https://play.google.com/store/apps/details?id=host.exp.exponent)

### Start the Development Server

```bash
npm run mobile
```

This will start the Expo development server and display a QR code.

### Open on Your Device

1. **iOS**: Open the Camera app and scan the QR code
2. **Android**: Open the Expo Go app and scan the QR code

### Alternative Methods

```bash
# Run on Android emulator
npm run android

# Run on iOS simulator (macOS only)
npm run ios

# Run with tunnel (for external networks)
npm run mobile:tunnel
```

## Project Structure

```
/app                    # Expo Router screens
  /(auth)              # Authentication screens
    /login.tsx         # Login screen
  /(tabs)              # Main tab navigation
    /index.tsx         # Dashboard
    /leads.tsx         # Leads list
    /followups.tsx     # Follow-ups
    /profile.tsx       # Profile
  /lead/[id].tsx       # Lead details (dynamic route)
  /_layout.tsx         # Root layout

/mobile                # Mobile-specific code
  /contexts            # React contexts
    /AuthContext.tsx   # Authentication provider

/assets                # App icons and splash screens
```

## Key Technologies

- **Expo Router**: File-based routing
- **NativeWind**: Tailwind CSS for React Native
- **Supabase**: Backend and authentication
- **Lucide React Native**: Beautiful icons
- **TypeScript**: Type safety

## Shared Code

The mobile app shares:
- Supabase configuration (`src/lib/supabase.ts`)
- Database types (`src/lib/database.types.ts`)
- Authentication logic
- API calls

## Building for Production

```bash
# Build for Android
eas build --platform android

# Build for iOS
eas build --platform ios
```

Note: You'll need an Expo account and EAS CLI installed.

## Troubleshooting

### QR Code Not Working?

Try using tunnel mode:
```bash
npm run mobile:tunnel
```

### App Not Loading?

1. Make sure your phone and computer are on the same WiFi network
2. Check that the Expo development server is running
3. Try restarting the Expo Go app

### Assets Missing?

Add these files to `/assets`:
- `icon.png` (1024x1024)
- `splash.png` (1284x2778)
- `adaptive-icon.png` (1024x1024)
- `favicon.png` (48x48)

## Next Steps

1. Add custom app icons and splash screen
2. Implement push notifications
3. Add offline support
4. Build production apps with EAS Build
5. Submit to App Store and Play Store
