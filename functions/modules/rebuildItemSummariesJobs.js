const functions = require("firebase-functions/v1");
const admin = require("firebase-admin");

exports.rebuildItemSummariesJob = functions.firestore
  .document("admin_jobs/rebuild_item_summaries") //delete the existing document under admin_jobs and create it again named "rebuild_item_summaries"
  .onCreate(async (snap, context) => {
    const db = admin.firestore();

    // 1) Read all bookings
    const bookingsSnap = await db.collection("bookings").get();

    // 2) Aggregate bookings -> per item
    const summaries = {};
    const itemIds = new Set();

    bookingsSnap.forEach((doc) => {
      const b = doc.data();
      const itemId = b.itemId;
      if (!itemId) return;

      itemIds.add(itemId);

      if (!summaries[itemId]) {
        summaries[itemId] = {
          // Booking counters
          bookingsTotal: 0,
          bookingsPending: 0,
          bookingsConfirmed: 0,
          bookingsOngoing: 0,
          bookingsCompleted: 0,
          bookingsCancelled: 0,

          // Totals
          totalEarnings: 0,
          totalRentalDays: 0,

          // Monthly breakdown
          earningsByMonth: {},

          // Timestamps (set later)
          lastBookedAt: null,
          lastCompletedAt: null,

          // Metadata (filled later)
          itemId,
          itemName: null,
          renterId: null,
          category: null,
          size: null,
          pricePerDay: null,
          createdAt: null,

          // Views (preserve from existing summary if any)
          views: 0,
          lastViewedAt: null,

          updatedAt: admin.firestore.FieldValue.serverTimestamp(),
        };
      }

      const s = summaries[itemId];

      // total bookings
      s.bookingsTotal += 1;

      // status counters
      switch (b.status) {
        case "pending": s.bookingsPending += 1; break;
        case "confirmed": s.bookingsConfirmed += 1; break;
        case "ongoing": s.bookingsOngoing += 1; break;
        case "completed": s.bookingsCompleted += 1; break;
        case "cancelled": s.bookingsCancelled += 1; break;
      }

      // lastBookedAt
      const bookedTs = b.createdAt || b.bookingCreatedAt || b.startDate; // adjust if your schema differs
      if (bookedTs && typeof bookedTs.toMillis === "function") {
        if (!s.lastBookedAt || bookedTs.toMillis() > s.lastBookedAt.toMillis()) {
          s.lastBookedAt = bookedTs;
        }
      }

      // completed stats
      if (b.status === "completed") {
        const fee = Number(b.finalFee || 0);
        const days = Number(b.rentalDays || 0);

        s.totalEarnings += fee;
        s.totalRentalDays += days;

        const completedTs = b.completedAt || b.updatedAt || b.endDate; // adjust if needed
        if (completedTs && typeof completedTs.toMillis === "function") {
          if (!s.lastCompletedAt || completedTs.toMillis() > s.lastCompletedAt.toMillis()) {
            s.lastCompletedAt = completedTs;
          }

          const d = completedTs.toDate();
          const ym = `${d.getFullYear()}-${String(d.getMonth() + 1).padStart(2, "0")}`;

          if (!s.earningsByMonth[ym]) {
            s.earningsByMonth[ym] = {
              completedBookings: 0,
              earnings: 0,
              rentalDays: 0,
            };
          }

          s.earningsByMonth[ym].completedBookings += 1;
          s.earningsByMonth[ym].earnings += fee;
          s.earningsByMonth[ym].rentalDays += days;
        }
      }
    });

    // 3) Fetch item metadata + existing summary views (preserve)
    //    (If you prefer recalc from item_views, tell me and I’ll change it.)
    const itemIdList = Array.from(itemIds);

    // Fetch existing summaries to preserve views/lastViewedAt if present
    const existingSummaryDocs = await Promise.all(
      itemIdList.map((id) => db.collection("item_summaries").doc(id).get())
    );

    const existingSummaryMap = new Map();
    existingSummaryDocs.forEach((doc) => {
      if (doc.exists) existingSummaryMap.set(doc.id, doc.data());
    });

    // Fetch items docs
    const itemDocs = await Promise.all(
      itemIdList.map((id) => db.collection("items").doc(id).get())
    );

    itemDocs.forEach((doc) => {
      const itemId = doc.id;
      const s = summaries[itemId];
      if (!s) return;

      if (doc.exists) {
        const item = doc.data() || {};
        s.itemName = item.itemName ?? item.name ?? s.itemName;
        s.renterId = item.renterId ?? item.ownerId ?? s.renterId;
        s.category = item.category ?? s.category;
        s.size = item.size ?? s.size;
        s.pricePerDay = item.pricePerDay ?? item.price ?? s.pricePerDay;
        s.createdAt = item.createdAt ?? s.createdAt;
      }

      // Preserve views from existing summary
      const old = existingSummaryMap.get(itemId);
      if (old) {
        s.views = Number(old.views || 0);
        s.lastViewedAt = old.lastViewedAt || null;
      }
    });

    // 4) Write summaries back (overwrite)
    const entries = Object.entries(summaries);
    const CHUNK_SIZE = 400;

    for (let i = 0; i < entries.length; i += CHUNK_SIZE) {
      const batch = db.batch();
      entries.slice(i, i + CHUNK_SIZE).forEach(([itemId, data]) => {
        batch.set(db.collection("item_summaries").doc(itemId), data); // overwrite
      });
      await batch.commit();
    }

    // 5) Mark job doc
    await snap.ref.set(
      { status: "done", finishedAt: admin.firestore.FieldValue.serverTimestamp() },
      { merge: true }
    );

    return null;
  });
