const functions = require("firebase-functions");
const admin = require("firebase-admin");

/**
 * 🔔 Send push notification when a notification document is created
 * Trigger: Firestore → notifications/{notificationId}
 */
exports.sendNotificationOnCreate = functions.firestore
  .document("notifications/{notificationId}")
  .onCreate(async (snap, context) => {
    try {
      const data = snap.data();
      const notificationId = context.params.notificationId;

      console.log("============================================");
      console.log("🔔 NEW NOTIFICATION CREATED");
      console.log(`   ID: ${notificationId}`);
      console.log(`   User: ${data.userId}`);
      console.log(`   Title: ${data.title}`);
      console.log("============================================");

      // Basic validation
      if (!data || !data.userId) {
        console.log("❌ Invalid notification data");
        return null;
      }

      const userId = data.userId;
      const title = data.title || "Notification";
      const body = data.body || "";

      // Get user document
      const userDoc = await admin
        .firestore()
        .collection("users")
        .doc(userId)
        .get();

      if (!userDoc.exists) {
        console.log(`❌ User not found: ${userId}`);
        return null;
      }

      const fcmToken = userDoc.data().fcmToken;

      if (!fcmToken) {
        console.log(`❌ No FCM token for user: ${userId}`);
        return null;
      }

      console.log(`✅ FCM token found: ${fcmToken.substring(0, 30)}...`);

      // Build push payload
      const payload = {
        notification: {
            title,
            body,
        },
        data: {
            type: data.type || "general",
            notificationId: notificationId,

            // ✅ THESE MUST COME FROM FIRESTORE DATA
            bookingId: data.bookingId || "",
            renterId: data.renterId || "",
            itemId: data.itemId || "",
        },
        token: fcmToken,
        };

      // Send push notification
      console.log("📤 Sending push notification...");
      const response = await admin.messaging().send(payload);

      console.log("✅ PUSH NOTIFICATION SENT");
      console.log(`   Response ID: ${response}`);

      // Mark notification as sent
      await snap.ref.update({
        sent: true,
        sentAt: admin.firestore.FieldValue.serverTimestamp(),
      });

      return response;
    } catch (error) {
      console.error("============================================");
      console.error("❌ ERROR SENDING PUSH NOTIFICATION");
      console.error(error);
      console.error("============================================");

      // Optional: store error in Firestore
      try {
        await snap.ref.update({
          sent: false,
          error: error.message,
        });
      } catch (_) {}

      return null;
    }
  });
