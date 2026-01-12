const functions = require("firebase-functions");
const admin = require("firebase-admin");
const db = admin.firestore();

exports.regenerateSpendingAnalysis = functions.https.onCall(async (data, context) => {
  if (!context.auth) throw new functions.https.HttpsError("unauthenticated", "Auth required");
  return await updateUserSpendingAnalysis(context.auth.uid);
});

async function updateUserSpendingAnalysis(userId) {
  const bookingsSnapshot = await db.collection("bookings")
    .where("userId", "==", userId)
    .where("status", "==", "completed")
    .get();

  const bookingPromises = bookingsSnapshot.docs.map(async (doc) => {
    const data = doc.data();
    const finalFee = parseFloat(data.finalFee?.toString() || "0") || 0;
    const startDate = data.startDate?.toDate ? data.startDate.toDate() : new Date();
    let category = "Other";

    if (data.itemId) {
      const itemDoc = await db.collection("items").doc(data.itemId).get();
      if (itemDoc.exists) category = itemDoc.data().category || "Other";
    }
    return { finalFee, startDate, category };
  });

  const resolvedBookings = await Promise.all(bookingPromises);

  const analysisData = {
    monthly: calculateMonthlyAnalysis(resolvedBookings),
    weeklyGroups: calculateWeeklyByMonth(resolvedBookings), 
    category: calculateCategoryAnalysis(resolvedBookings),
    summary: {
      totalSpent: resolvedBookings.reduce((sum, b) => sum + b.finalFee, 0),
      totalBookings: resolvedBookings.length,
      averagePerBooking: resolvedBookings.length > 0 ? 
        (resolvedBookings.reduce((sum, b) => sum + b.finalFee, 0) / resolvedBookings.length) : 0,
    },
    lastUpdated: admin.firestore.FieldValue.serverTimestamp(),
  };

  //create collection at firestore
  await db.collection("spendingAnalysis").doc(userId).set(analysisData);
  return analysisData;
}

function calculateWeeklyByMonth(bookings) {
  const groups = {};
  const monthNames = ["Jan", "Feb", "Mar", "Apr", "May", "Jun", "Jul", "Aug", "Sep", "Oct", "Nov", "Dec"];

  bookings.forEach((b) => {
    const d = b.startDate;
    const monthKey = `${monthNames[d.getMonth()]} ${d.getFullYear()}`;
    const weekNum = Math.ceil(d.getDate() / 7);
    const weekLabel = `Week ${weekNum}`;

    if (!groups[monthKey]) groups[monthKey] = {};
    groups[monthKey][weekLabel] = (groups[monthKey][weekLabel] || 0) + b.finalFee;
  });

  return Object.keys(groups).map(month => ({
    monthName: month,
    weeks: Object.keys(groups[month]).map(w => ({
      label: w,
      amount: groups[month][w]
    })).sort((a, b) => a.label.localeCompare(b.label))
  })).sort((a, b) => new Date(b.monthName) - new Date(a.monthName));
}


function calculateMonthlyAnalysis(bookings) {
  const monthlySpending = {};
  const monthNames = ["Jan", "Feb", "Mar", "Apr", "May", "Jun", "Jul", "Aug", "Sep", "Oct", "Nov", "Dec"];
  
  bookings.forEach((b) => {
    const key = `${b.startDate.getFullYear()}-${String(b.startDate.getMonth() + 1).padStart(2, "0")}`;
    monthlySpending[key] = (monthlySpending[key] || 0) + b.finalFee;
  });

  const chartData = [];
  for (let i = 5; i >= 0; i--) {
    const d = new Date();
    d.setMonth(d.getMonth() - i);
    const key = `${d.getFullYear()}-${String(d.getMonth() + 1).padStart(2, "0")}`;
    chartData.push({ 
      month: monthNames[d.getMonth()], 
      year: d.getFullYear(), 
      amount: monthlySpending[key] || 0 
    });
  }
  return { chartData, period: "Last 6 months" };
}

function calculateCategoryAnalysis(bookings) {
  const spending = {};
  const counts = {};
  let total = 0;

  bookings.forEach((b) => {
    spending[b.category] = (spending[b.category] || 0) + b.finalFee;
    counts[b.category] = (counts[b.category] || 0) + 1;
    total += b.finalFee;
  });

  const chartData = Object.entries(spending).map(([category, amount]) => ({
    category, 
    amount, 
    count: counts[category], 
    percentage: total > 0 ? (amount / total) * 100 : 0
  })).sort((a, b) => b.amount - a.amount);

  return { chartData, topCategory: chartData[0]?.category || "N/A" };
}