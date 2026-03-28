const {onValueCreated} = require('firebase-functions/v2/database');
const admin = require('firebase-admin');

admin.initializeApp();

// Trigger when a new notification is added
exports.sendNotificationOnCreate = onValueCreated(
  '/notifications/{userId}/{notificationId}',
  async (event) => {
    const userId = event.params.userId;
    const notificationData = event.data.val();

    try {
      // Get user's FCM token
      const userSnapshot = await admin.database()
        .ref(`/users/${userId}/fcmToken`)
        .once('value');
      
      const fcmToken = userSnapshot.val();

      if (!fcmToken) {
        console.log('No FCM token found for user:', userId);
        return null;
      }

      // Prepare notification payload
      const payload = {
        notification: {
          title: notificationData.title || 'New Notification',
          body: notificationData.body || '',
        },
        data: {
          type: notificationData.type || 'notification',
        },
        android: {
          priority: 'high',
          notification: {
            channelId: 'high_importance_channel',
            sound: 'default',
          },
        },
        apns: {
          payload: {
            aps: {
              sound: 'default',
            },
          },
        },
        token: fcmToken,
      };

      // Send notification
      const response = await admin.messaging().send(payload);
      console.log('Successfully sent notification:', response);
      return response;

    } catch (error) {
      console.error('Error sending notification:', error);
      return null;
    }
  }
);
