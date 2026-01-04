// functions/index.js
const functions = require('firebase-functions');
const admin = require('firebase-admin');

admin.initializeApp();

exports.generateRentalInsights = functions.https.onCall(async (data, context) => {
  if (!context.auth) {
    throw new functions.https.HttpsError('unauthenticated', 'User must be logged in.');
  }

  const userId = context.auth.uid;
  const db = admin.firestore();
  const snapshot = await db
    .collection('bookings')
    .where('userId', '==', userId)
    .where('status', '==', 'completed')
    .get();

  const bookings = [];
  snapshot.forEach(doc => {
    const d = doc.data();
    bookings.push({
      finalFee: d.finalFee || 0,
      itemPrice: d.itemPrice || 0,
      startDate: d.startDate,
      returnDate: d.returnDate,
      actualReturnDate: d.actualReturnDate,
      itemCategory: d.itemCategory || 'Other',
    });
  });

  const totalRentals = bookings.length;
  const totalSpent = bookings.reduce((sum, b) => sum + b.finalFee, 0);
  const moneySaved = bookings.reduce((sum, b) => sum + Math.max(0, b.itemPrice - b.finalFee), 0);

  const onTime = bookings.filter(b => {
    if (!b.actualReturnDate || !b.returnDate) return false;
    try {
      return b.actualReturnDate.toDate() <= b.returnDate.toDate();
    } catch {
      return false;
    }
  }).length;
  const returnScore = totalRentals > 0 ? Math.round((onTime / totalRentals) * 100) : 0;

  const monthly = {};
  bookings.forEach(b => {
    try {
      const date = b.startDate.toDate();
      const key = `${date.getFullYear()}-${String(date.getMonth() + 1).padStart(2, '0')}`;
      monthly[key] = (monthly[key] || 0) + b.finalFee;
    } catch (e) {}
  });

  const categories = {};
  bookings.forEach(b => {
    const cat = b.itemCategory;
    categories[cat] = (categories[cat] || 0) + 1;
  });

  const avgRental = totalRentals ? totalSpent / totalRentals : 0;
  const avgBuy = totalRentals ? bookings.reduce((s, b) => s + b.itemPrice, 0) / totalRentals : 0;
  const percentSaved = avgBuy > 0 ? Math.round(((avgBuy - avgRental) / avgBuy) * 100) : 0;

  return {
    success: true,
    data: {
      totalRentals,
      totalSpent: parseFloat(totalSpent.toFixed(2)),
      moneySaved: parseFloat(moneySaved.toFixed(2)),
      returnScore,
      monthlySpending: Object.entries(monthly).map(([month, amount]) => ({
        month,
        amount: parseFloat(amount.toFixed(2)),
      })),
      categoryStats: Object.entries(categories).map(([name, count]) => ({
        name,
        count,
      })),
      costComparison: {
        rental: parseFloat(avgRental.toFixed(2)),
        buying: parseFloat(avgBuy.toFixed(2)),
        percentSaved,
      },
    },
  };
});