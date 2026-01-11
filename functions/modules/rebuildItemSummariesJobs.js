//this file is run only ONCE
const functions = require("firebase-functions");
const admin = require("firebase-admin");

exports.rebuildItemSummariesJob = functions.firestore
  .document("admin_jobs/rebuild_item_summaries")
  .onCreate(async (snap, context) => {
    const db = admin.firestore();

    // 🔒 Run-once lock
    const lockRef = db.doc("system_flags/item_summary_rebuild");
    const lockSnap = await lockRef.get();
    if (lockSnap.exists && lockSnap.data().done === true) {
      return null;
    }

    const bookingsSnap = await db.collection("bookings").get();
    const summaries = {};

    bookingsSnap.forEach(doc => {
      const b = doc.data();
      if (!b.itemId) return;

      if (!summaries[b.itemId]) {
        summaries[b.itemId] = {
          bookingsTotal: 0,
          bookingsPending: 0,
          bookingsConfirmed: 0,
          bookingsOngoing: 0,
          bookingsCompleted: 0,
          bookingsCancelled: 0,
          totalEarnings: 0,
          totalRentalDays: 0,
          earningsByMonth: {},
          updatedAt: admin.firestore.FieldValue.serverTimestamp(),
        };
      }

      const s = summaries[b.itemId];
      s.bookingsTotal++;

      switch (b.status) {
        case "pending": s.bookingsPending++; break;
        case "confirmed": s.bookingsConfirmed++; break;
        case "ongoing": s.bookingsOngoing++; break;
        case "completed": s.bookingsCompleted++; break;
        case "cancelled": s.bookingsCancelled++; break;
      }

      if (b.status === "completed") {
        const fee = Number(b.finalFee || 0);
        const days = Number(b.rentalDays || 0);

        s.totalEarnings += fee;
        s.totalRentalDays += days;

        if (b.completedAt) {
          const d = b.completedAt.toDate();
          const ym = `${d.getFullYear()}-${String(d.getMonth() + 1).padStart(2, "0")}`;
          if (!s.earningsByMonth[ym]) {
            s.earningsByMonth[ym] = { earnings: 0, bookings: 0 };
          }
          s.earningsByMonth[ym].earnings += fee;
          s.earningsByMonth[ym].bookings += 1;
        }
      }
    });

    const batch = db.batch();
    Object.entries(summaries).forEach(([itemId, data]) => {
      batch.set(db.collection("item_summaries").doc(itemId), data, { merge: true });
    });

    await batch.commit();

    // 🔐 Lock AFTER success
    await lockRef.set({
      done: true,
      executedAt: admin.firestore.FieldValue.serverTimestamp(),
      triggeredBy: snap.data()?.requestedBy ?? null,
    });

    // Optional: mark job as done
    await snap.ref.set(
      { status: "done", finishedAt: admin.firestore.FieldValue.serverTimestamp() },
      { merge: true }
    );

    return null;
  });
