const functions = require("firebase-functions");
const admin = require("firebase-admin");

exports.sendNotificationOnCreate = functions.firestore
  .document("notifications/{notificationId}")
  .onCreate(async (snap, context) => {
    const data = snap.data();
    const notificationId = context.params.notificationId;

    try {
      const userDoc = await admin.firestore().collection("users").doc(data.userId).get();

      if (!userDoc.exists || !userDoc.data().fcmToken) {
        console.error(`❌ FCM Token missing for user: ${data.userId}`);
        return null;
      }

      const fcmToken = userDoc.data().fcmToken;
      const payload = {
        notification: {
          title: data.title || "Notification",
          body: data.body || "",
          sound: "default",
        },
        data: {
          type: data.type || "general",
          notificationId: notificationId,
        },
        token: fcmToken,
      };

      const response = await admin.messaging().send(payload);

      await snap.ref.update({
        sent: true,
        sentAt: admin.firestore.FieldValue.serverTimestamp(),
      });

      console.log(`✅ Notification ${notificationId} sent successfully`);
      return response;

    } catch (error) {
      console.error(`❌ Error sending notification: ${error.message}`);
      await snap.ref.update({
        sent: false,
        error: error.message,
      });
      return null;
    }
  });