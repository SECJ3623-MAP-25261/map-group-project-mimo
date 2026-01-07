// functions/index.js
const functions = require("firebase-functions");
const admin = require("firebase-admin");

admin.initializeApp();
const db = admin.firestore();

/**
 * Generates spending analysis for a user
 * Triggered when a booking status changes to 'completed'
 */
exports.generateSpendingAnalysis = functions.firestore
  .document("bookings/{bookingId}")
  .onUpdate(async (change, context) => {
    const newData = change.after.data();
    const previousData = change.before.data();

    // Only run when status changes to completed
    if (newData.status === "completed" && previousData.status !== "completed") {
      const userId = newData.userId;

      try {
        console.log(`🔄 Generating analysis for user: ${userId}`);
        await updateUserSpendingAnalysis(userId);
        console.log(`✅ Analysis updated for user: ${userId}`);
      } catch (error) {
        console.error(`❌ Error generating analysis for user ${userId}:`, error);
      }
    }

    return null;
  });

/**
 * Manual trigger to regenerate analysis for a user
 * Can be called from the Flutter app
 */
exports.regenerateSpendingAnalysis = functions.https.onCall(async (data, context) => {
  // Check authentication
  if (!context.auth) {
    throw new functions.https.HttpsError(
      "unauthenticated",
      "User must be authenticated to regenerate analysis"
    );
  }

  const userId = context.auth.uid;

  try {
    console.log(`🔄 Manual regeneration for user: ${userId}`);
    const result = await updateUserSpendingAnalysis(userId);
    return {
      success: true,
      message: "Analysis regenerated successfully",
      data: result,
    };
  } catch (error) {
    console.error(`❌ Error regenerating analysis:`, error);
    throw new functions.https.HttpsError(
      "internal",
      "Failed to regenerate analysis",
      error.message
    );
  }
});

/**
 * Core function to calculate and update spending analysis
 */
async function updateUserSpendingAnalysis(userId) {
  // Fetch all completed bookings for the user
  const bookingsSnapshot = await db
    .collection("bookings")
    .where("userId", "==", userId)
    .where("status", "==", "completed")
    .get();

  const bookings = [];
  bookingsSnapshot.forEach((doc) => {
    const data = doc.data();

    // Parse finalFee safely
    let finalFee = 0;
    if (data.finalFee) {
      const parsed = parseFloat(data.finalFee.toString());
      if (!isNaN(parsed)) {
        finalFee = parsed;
      }
    }

    // Parse startDate
    let startDate = new Date();
    if (data.startDate) {
      if (data.startDate.toDate) {
        startDate = data.startDate.toDate();
      } else if (data.startDate instanceof Date) {
        startDate = data.startDate;
      }
    }

    bookings.push({
      id: doc.id,
      itemName: data.itemName || "Unknown",
      finalFee: finalFee,
      startDate: startDate,
    });
  });

  console.log(`📊 Processing ${bookings.length} bookings`);

  // Calculate all analyses
  const monthly = calculateMonthlyAnalysis(bookings);
  const weekly = calculateWeeklyAnalysis(bookings);
  const category = calculateCategoryAnalysis(bookings);

  // Calculate summary statistics
  const totalSpent = bookings.reduce((sum, b) => sum + b.finalFee, 0);
  const totalBookings = bookings.length;
  const averagePerBooking = totalBookings > 0 ? totalSpent / totalBookings : 0;

  const analysisData = {
    monthly: monthly,
    weekly: weekly,
    category: category,
    summary: {
      totalSpent: totalSpent,
      totalBookings: totalBookings,
      averagePerBooking: averagePerBooking,
    },
    lastUpdated: admin.firestore.FieldValue.serverTimestamp(),
    processedBy: "cloud-function",
  };

  // Save to Firestore
  await db.collection("spendingAnalysis").doc(userId).set(analysisData);

  console.log(`💾 Analysis saved for user: ${userId}`);
  return analysisData;
}

/**
 * Calculate monthly spending analysis
 */
function calculateMonthlyAnalysis(bookings) {
  const monthlySpending = {};
  const now = new Date();
  const months = 6;

  // Aggregate spending by month
  bookings.forEach((booking) => {
    const date = booking.startDate;
    const monthKey = `${date.getFullYear()}-${String(date.getMonth() + 1).padStart(2, "0")}`;
    monthlySpending[monthKey] = (monthlySpending[monthKey] || 0) + booking.finalFee;
  });

  // Generate chart data for last 6 months
  const chartData = [];
  const monthNames = ["Jan", "Feb", "Mar", "Apr", "May", "Jun", "Jul", "Aug", "Sep", "Oct", "Nov", "Dec"];

  for (let i = months - 1; i >= 0; i--) {
    const date = new Date(now.getFullYear(), now.getMonth() - i, 1);
    const monthKey = `${date.getFullYear()}-${String(date.getMonth() + 1).padStart(2, "0")}`;

    chartData.push({
      month: monthNames[date.getMonth()],
      year: date.getFullYear(),
      amount: monthlySpending[monthKey] || 0,
      monthKey: monthKey,
    });
  }

  return {
    chartData: chartData,
    period: `Last ${months} months`,
  };
}

/**
 * Calculate weekly spending analysis
 */
function calculateWeeklyAnalysis(bookings) {
  const weeklySpending = {};
  const now = new Date();
  const weeks = 8;

  // Helper function to get week of month
  function getWeekOfMonth(date) {
    return Math.floor((date.getDate() - 1) / 7) + 1;
  }

  // Aggregate spending by week
  bookings.forEach((booking) => {
    const date = booking.startDate;
    const startOfWeek = new Date(date);
    startOfWeek.setDate(date.getDate() - date.getDay() + 1); // Monday

    const weekKey = `${startOfWeek.getFullYear()}-W${getWeekOfMonth(startOfWeek)}`;
    weeklySpending[weekKey] = (weeklySpending[weekKey] || 0) + booking.finalFee;
  });

  // Generate chart data for last 8 weeks
  const chartData = [];

  for (let i = weeks - 1; i >= 0; i--) {
    const date = new Date(now);
    date.setDate(date.getDate() - i * 7);

    const startOfWeek = new Date(date);
    startOfWeek.setDate(date.getDate() - date.getDay() + 1);

    const weekKey = `${startOfWeek.getFullYear()}-W${getWeekOfMonth(startOfWeek)}`;
    const weekLabel = `${startOfWeek.getDate()}/${startOfWeek.getMonth() + 1}`;

    chartData.push({
      week: weekLabel,
      amount: weeklySpending[weekKey] || 0,
      weekKey: weekKey,
    });
  }

  return {
    chartData: chartData,
    period: `Last ${weeks} weeks`,
  };
}

/**
 * Calculate category-based spending analysis
 */
function calculateCategoryAnalysis(bookings) {
  const categorySpending = {};
  const categoryCount = {};
  let totalSpent = 0;

  // Aggregate spending by category (itemName)
  bookings.forEach((booking) => {
    const category = booking.itemName;
    categorySpending[category] = (categorySpending[category] || 0) + booking.finalFee;
    categoryCount[category] = (categoryCount[category] || 0) + 1;
    totalSpent += booking.finalFee;
  });

  // Sort categories by spending amount
  const sortedCategories = Object.entries(categorySpending).sort((a, b) => b[1] - a[1]);

  // Generate chart data
  const chartData = sortedCategories.map(([category, amount]) => ({
    category: category,
    amount: amount,
    count: categoryCount[category],
    percentage: totalSpent > 0 ? (amount / totalSpent) * 100 : 0,
  }));

  return {
    chartData: chartData,
    topCategory: chartData.length > 0 ? chartData[0].category : "N/A",
    topCategoryAmount: chartData.length > 0 ? chartData[0].amount : 0,
  };
}

/**
 * Scheduled function to update all users' analyses daily
 * Runs every day at 2 AM
 */
exports.scheduledSpendingAnalysisUpdate = functions.pubsub
  .schedule("0 2 * * *")
  .timeZone("Asia/Kuala_Lumpur")
  .onRun(async (context) => {
    console.log("🕐 Starting scheduled analysis update...");

    try {
      // Get all unique user IDs from bookings
      const bookingsSnapshot = await db.collection("bookings").where("status", "==", "completed").get();

      const userIds = new Set();
      bookingsSnapshot.forEach((doc) => {
        const userId = doc.data().userId;
        if (userId) {
          userIds.add(userId);
        }
      });

      console.log(`📋 Found ${userIds.size} users with completed bookings`);

      // Update analysis for each user
      const updatePromises = Array.from(userIds).map((userId) =>
        updateUserSpendingAnalysis(userId).catch((error) => {
          console.error(`Failed to update user ${userId}:`, error);
        })
      );

      await Promise.all(updatePromises);

      console.log("✅ Scheduled analysis update completed");
      return null;
    } catch (error) {
      console.error("❌ Error in scheduled update:", error);
      return null;
    }
  });

/**
 * Push notification function
 */
exports.sendNotificationOnCreate = functions.firestore
  .document("notifications/{id}")
  .onCreate(async (snap) => {
    const data = snap.data();

    const userId = data.userId;
    const title = data.title;
    const body = data.body;

    const userDoc = await admin.firestore().collection("users").doc(userId).get();

    if (!userDoc.exists) return;

    const fcmToken = userDoc.data().fcmToken;
    if (!fcmToken) return;

    const payload = {
      notification: {
        title,
        body,
      },
      data: {
        type: data.type || "general",
      },
    };

    await admin.messaging().sendToDevice(fcmToken, payload);
  });
  
  const functions = require("firebase-functions");
const admin = require("firebase-admin");

admin.initializeApp();

// Send notification when created
exports.sendNotificationOnCreate = functions.firestore
  .document("notifications/{notificationId}")
  .onCreate(async (snap, context) => {
    const data = snap.data();
    const notificationId = context.params.notificationId;

    console.log("==========================================");
    console.log("🔔 NEW NOTIFICATION");
    console.log(`   ID: ${notificationId}`);
    console.log(`   User: ${data.userId}`);
    console.log(`   Title: ${data.title}`);

    try {
      // Get user
      const userDoc = await admin.firestore().collection("users").doc(data.userId).get();

      if (!userDoc.exists) {
        console.log("❌ User not found");
        return null;
      }

      const fcmToken = userDoc.data().fcmToken;

      if (!fcmToken) {
        console.log("❌ No FCM token");
        return null;
      }

      console.log(`✅ Token: ${fcmToken.substring(0, 30)}...`);

      // Send
      const response = await admin.messaging().send({
        notification: {
          title: data.title,
          body: data.body,
        },
        data: {
          type: data.type || "general",
        },
        token: fcmToken,
      });

      console.log("✅ SENT!");
      console.log("==========================================");

      // Mark as sent
      await snap.ref.update({
        sent: true,
        sentAt: admin.firestore.FieldValue.serverTimestamp(),
      });

      return response;
    } catch (error) {
      console.error("❌ ERROR:", error.message);
      return null;
    }
  });

const functions = require("firebase-functions");
const admin = require("firebase-admin");

admin.initializeApp();

// ========== NOTIFICATION SENDER ==========
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

      const userId = data.userId;
      const title = data.title || "Notification";
      const body = data.body || "";

      // Get user's FCM token
      const userDoc = await admin.firestore().collection("users").doc(userId).get();

      if (!userDoc.exists) {
        console.error(`❌ User not found: ${userId}`);
        return null;
      }

      console.log("✅ User document found");

      const fcmToken = userDoc.data().fcmToken;

      if (!fcmToken) {
        console.error(`❌ No FCM token for user: ${userId}`);
        console.log(`   User data: ${JSON.stringify(userDoc.data())}`);
        return null;
      }

      console.log(`✅ FCM token found: ${fcmToken.substring(0, 50)}...`);

      // Send notification
      const payload = {
        notification: {
          title: title,
          body: body,
          sound: "default",
        },
        data: {
          type: data.type || "general",
          notificationId: notificationId,
        },
        token: fcmToken,
      };

      console.log("📤 Sending push notification...");

      const response = await admin.messaging().send(payload);

      console.log("✅ PUSH NOTIFICATION SENT SUCCESSFULLY!");
      console.log(`   Response: ${response}`);

      // Mark as sent
      await snap.ref.update({
        sent: true,
        sentAt: admin.firestore.FieldValue.serverTimestamp(),
      });

      console.log("✅ Notification marked as sent");
      console.log("============================================");

      return response;
    } catch (error) {
      console.error("============================================");
      console.error("❌ ERROR SENDING NOTIFICATION");
      console.error(`   Error: ${error}`);
      console.error(`   Code: ${error.code}`);
      console.error(`   Message: ${error.message}`);
      console.error("============================================");

      await snap.ref.update({
        sent: false,
        error: error.message,
      });

      return null;
    }
  });

// ========== SPENDING ANALYSIS (Keep your existing code) ==========
exports.generateSpendingAnalysis = functions.firestore
  .document("bookings/{bookingId}")
  .onUpdate(async (change, context) => {
    // Your existing code here...
    return null;
  });
