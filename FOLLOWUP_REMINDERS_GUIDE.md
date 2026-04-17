# Follow-up Reminders System

This guide explains the follow-up reminder notification system that has been implemented in your CRM application.

## Features Implemented

### 1. Calendar Bug Fix
- **Issue**: Follow-up dots were appearing on wrong dates (off by 1 day) due to timezone conversion
- **Solution**: Updated the `getFollowupsForDate` function to properly handle local timezone dates without UTC conversion
- **Location**: `src/components/followups/FollowupsManager.tsx`

### 2. Browser Push Notifications
The system now supports both in-app and browser push notifications for upcoming follow-ups.

#### In-App Notifications
- **Appearance**: Bottom-right corner toast notifications
- **Timing**: Appears 5 minutes before scheduled follow-up time
- **Features**:
  - Shows lead name and mobile number
  - Displays scheduled time and follow-up remarks
  - Three action buttons: "View", "Snooze 2min", "Dismiss"
  - Auto-dismisses after 30 seconds if no action taken
  - Supports multiple stacked notifications
  - Smooth animations

#### Browser Push Notifications
- **Timing**: Appears when app is closed or in a background tab
- **Features**:
  - Native browser notifications
  - Clicking notification opens app and navigates to specific follow-up
  - Shows lead name and follow-up details
  - Works even when browser is minimized

## How It Works

### Polling System
- Checks for upcoming follow-ups every 60 seconds
- Queries database for follow-ups scheduled within next 5 minutes
- Only shows notifications for 'planned' status follow-ups
- Filters out already dismissed/snoozed reminders

### Notification Actions

1. **View**: Navigates to Follow-ups Manager and highlights the specific follow-up
2. **Snooze 2min**: Dismisses notification and shows it again after 2 minutes
3. **Dismiss**: Permanently dismisses the notification for 24 hours

### Deep-Linking
When clicking "View" on a reminder:
- Automatically switches to Follow-ups Manager tab
- Scrolls to the specific follow-up
- Highlights it with an orange ring for 3 seconds
- Works from both in-app and browser notifications

## Technical Implementation

### New Files Created

1. **Notification Utilities**
   - `src/utils/notificationPermissions.ts` - Manages browser notification permissions
   - `src/utils/registerServiceWorker.ts` - Service worker registration and management

2. **Context & State Management**
   - `src/contexts/ReminderContext.tsx` - Global reminder state and polling logic

3. **UI Components**
   - `src/components/notifications/FollowupReminderToast.tsx` - Toast notification component

4. **Service Worker**
   - `public/service-worker.js` - Background notification handler

### Modified Files

1. **App.tsx**
   - Added service worker registration on app load
   - Requests notification permission 2 seconds after app initialization

2. **MainLayout.tsx**
   - Integrated ReminderProvider context
   - Added FollowupReminderToast component
   - Added navigation handler for viewing follow-ups from notifications

3. **FollowupsManager.tsx**
   - Fixed calendar date bug
   - Added support for deep-linking to specific follow-ups
   - Added scroll-to and highlight functionality

## Usage

### For End Users

1. **Grant Permission**: When first using the app, allow browser notifications when prompted
2. **Create Follow-ups**: Add follow-ups with specific dates and times
3. **Receive Reminders**: Get notified 5 minutes before each follow-up
4. **Take Action**: Click View to see the follow-up, Snooze to be reminded later, or Dismiss

### Testing the System

To test the reminder system:

1. Create a follow-up scheduled 5 minutes from now
2. Wait for the notification to appear
3. Test with app open (should see toast notification)
4. Test with app in background tab (should see browser notification)
5. Click "View" to verify navigation works correctly

## Local Storage

The system stores the following in localStorage:

- **Dismissed reminders**: Tracks which follow-ups were dismissed (24-hour expiry)
- **Snoozed reminders**: Tracks snoozed follow-ups and when to show them again
- **Permission status**: Whether notification permission has been requested

Storage key: `followup_reminders_state`

## Browser Compatibility

- Requires modern browser with Notification API support
- Requires Service Worker support
- Works on Chrome, Firefox, Edge, Safari (with limitations)
- Gracefully degrades to in-app only notifications if browser doesn't support push notifications

## Future Enhancements

Potential improvements that could be added:

- Configurable advance notice time (currently fixed at 5 minutes)
- Sound notifications with on/off toggle
- Multiple reminder times (e.g., 15 min, 5 min, at time)
- Reminder badge count in navigation
- Email/SMS notifications for important follow-ups
- Follow-up completion directly from notification
