# Firebase Cloud Messaging (FCM) Setup Instructions

## ✅ What's Been Implemented

### 1. **Notification Service** (`lib/services/notification_service.dart`)
   - FCM token management
   - Local notifications for foreground messages
   - Background message handling
   - Send notifications to specific users
   - Send notifications to all admins
   - Check notification preferences

### 2. **Notification Settings Screen** (`lib/screens/common/notifications_screen.dart`)
   - Master toggle for all notifications
   - Individual toggles for:
     - Order Notifications
     - User Notifications (Admin only)
     - System Notifications
   - Settings saved to Firebase

### 3. **Automatic Notifications**
   - ✅ New crop request → Notifies all admins
   - ✅ New user registration → Notifies all admins
   - Settings stored in Firebase under `users/{userId}/notificationSettings`
   - FCM tokens stored in Firebase under `users/{userId}/fcmToken`

### 4. **UI Integration**
   - Admin Profile: Notifications option added
   - Kisan Dashboard: Notifications option (replaces Settings)
   - Vyapari Dashboard: Ready for notifications option

---

## 🚀 Setup Steps

### Step 1: Install Dependencies
Run the following command in your project directory:
```bash
flutter pub get
```

### Step 2: Firebase Console Setup

1. **Go to Firebase Console**: https://console.firebase.google.com/
2. **Select your project**: `mypocketmandi`
3. **Navigate to**: Project Settings → Cloud Messaging
4. **Enable Cloud Messaging API**:
   - Click on the three dots menu
   - Select "Manage API in Google Cloud Console"
   - Enable "Firebase Cloud Messaging API"

### Step 3: Android Configuration

Your Android app is already configured with:
- ✅ POST_NOTIFICATIONS permission added
- ✅ google-services.json should be in `android/app/`

If `google-services.json` is missing:
1. Go to Firebase Console → Project Settings
2. Download `google-services.json`
3. Place it in `android/app/` directory

### Step 4: iOS Configuration (Optional)

If you want iOS support:
1. Add `GoogleService-Info.plist` to `ios/Runner/`
2. Enable Push Notifications in Xcode
3. Upload APNs certificate to Firebase Console

### Step 5: Test Notifications

1. **Run the app**:
   ```bash
   flutter run
   ```

2. **Test scenarios**:
   - Register a new user → Admins should get notification
   - Add a new crop request → Admins should get notification
   - Check notification settings in profile

---

## 📱 How It Works

### For Farmers/Traders:
1. Go to Profile → Notifications
2. Toggle notification preferences
3. Receive notifications for:
   - Order updates
   - System announcements

### For Admins:
1. Go to Profile → Notifications
2. Toggle notification preferences
3. Receive notifications for:
   - New user registrations
   - New crop requests
   - Order updates
   - System announcements

---

## 🔧 Troubleshooting

### Notifications not working?

1. **Check FCM token**:
   - Look for "FCM Token saved" in console logs
   - Verify token exists in Firebase Database under `users/{userId}/fcmToken`

2. **Check notification settings**:
   - Ensure notifications are enabled in app settings
   - Check Firebase Database under `users/{userId}/notificationSettings`

3. **Check Android permissions**:
   - Ensure POST_NOTIFICATIONS permission is granted
   - Check in device Settings → Apps → PoketMandi → Notifications

4. **Verify Firebase setup**:
   - Ensure Cloud Messaging API is enabled
   - Check `google-services.json` is present

---

## 📊 Firebase Database Structure

```
users/
  {userId}/
    fcmToken: "device_fcm_token_here"
    notificationSettings/
      enabled: true
      orders: true
      users: true  (admin only)
      system: true
      updatedAt: timestamp

notifications/
  {userId}/
    {notificationId}/
      title: "Notification Title"
      body: "Notification Body"
      data: {...}
      read: false
      createdAt: timestamp
```

---

## 🎯 Next Steps (Optional Enhancements)

1. **Notification History**: Create a screen to show all past notifications
2. **In-app Notification Badge**: Show unread count
3. **Rich Notifications**: Add images and action buttons
4. **Scheduled Notifications**: Send reminders
5. **Cloud Functions**: Use Firebase Cloud Functions for server-side notification sending

---

## 📝 Notes

- Notifications are sent when users have them enabled in settings
- FCM tokens are automatically refreshed and updated
- Background notifications work even when app is closed
- Foreground notifications show as local notifications

---

## ✨ Features Summary

✅ Push notifications via FCM
✅ Local notifications for foreground messages
✅ Background message handling
✅ User notification preferences
✅ Role-based notifications (admin-specific)
✅ Automatic notifications for key events
✅ Beautiful notification settings UI
✅ Firebase integration complete

---

**Your notification system is ready to use! 🎉**
