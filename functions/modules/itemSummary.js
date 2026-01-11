const functions = require("firebase-functions");
const admin = require("firebase-admin");

const db = admin.firestore();
const { FieldValue } = admin.firestore;

// ----------------------------
// Helpers
// ----------------------------

function statusToField(status) {
  switch ((status || "").toString()) {
    case "pending":
      return "bookingsPending";
    case "confirmed":
      return "bookingsConfirmed";
    case "ongoing":
      return "bookingsOngoing";
    case "completed":
      return "bookingsCompleted";
    case "cancelled":
      return "bookingsCancelled";
    default:
      return null;
  }
}

function monthKeyFromDate(d) {
  const date = d instanceof Date ? d : new Date(d);
  const y = String(date.getFullYear()).padStart(4, "0");
  const m = String(date.getMonth() + 1).padStart(2, "0");
  return `${y}-${m}`;
}

async function ensureSummaryForItem(itemId) {
  const summaryRef = db.collection("item_summaries").doc(itemId);

  await db.runTransaction(async (tx) => {
    const snap = await tx.get(summaryRef);
    if (snap.exists) return;

    // Pull item metadata for a nicer summary row.
    let itemData = null;
    const itemRef = db.collection("items").doc(itemId);
    const itemSnap = await tx.get(itemRef);
    if (itemSnap.exists) itemData = itemSnap.data() || null;

    tx.set(summaryRef, {
      itemId,
      renterId: itemData?.renterId ?? null,
      itemName: itemData?.name ?? null,
      category: itemData?.category ?? null,
      size: itemData?.size ?? null,
      pricePerDay:
        typeof itemData?.pricePerDay === "number" ? itemData.pricePerDay : 0,

      views: 0,
      edits: 0,

      bookingsTotal: 0,
      bookingsPending: 0,
      bookingsConfirmed: 0,
      bookingsOngoing: 0,
      bookingsCompleted: 0,
      bookingsCancelled: 0,

      totalRentalDays: 0,
      totalEarnings: 0,

      lastViewedAt: null,
      lastBookedAt: null,
      lastCompletedAt: null,

      createdAt: FieldValue.serverTimestamp(),
      updatedAt: FieldValue.serverTimestamp(),
    });
  });
}

async function applyBookingCreate(bookingData) {
  const itemId = bookingData?.itemId;
  if (!itemId) return;

  await ensureSummaryForItem(itemId);

  const status = (bookingData.status || "pending").toString();
  const statusField = statusToField(status);

  const summaryRef = db.collection("item_summaries").doc(itemId);
  const update = {
    bookingsTotal: FieldValue.increment(1),
    lastBookedAt: FieldValue.serverTimestamp(),
    updatedAt: FieldValue.serverTimestamp(),
  };
  if (statusField) update[statusField] = FieldValue.increment(1);

  await summaryRef.set(update, { merge: true });
}

async function applyBookingDelete(bookingData) {
  const itemId = bookingData?.itemId;
  if (!itemId) return;

  await ensureSummaryForItem(itemId);

  const status = (bookingData.status || "pending").toString();
  const statusField = statusToField(status);

  const finalFee = Number(bookingData.finalFee ?? bookingData.totalAmount ?? 0) || 0;
  const rentalDays = Number(bookingData.rentalDays ?? 0) || 0;

  // Prefer actualReturnDate for completed month bucket
  const completedAtTs = bookingData.actualReturnDate || bookingData.updatedAt || null;
  const completedAt = completedAtTs?.toDate ? completedAtTs.toDate() : null;
  const monthKey = completedAt ? monthKeyFromDate(completedAt) : null;

  const summaryRef = db.collection("item_summaries").doc(itemId);
  await db.runTransaction(async (tx) => {
    const snap = await tx.get(summaryRef);
    if (!snap.exists) return; // nothing to do

    const updates = {
      bookingsTotal: FieldValue.increment(-1),
      updatedAt: FieldValue.serverTimestamp(),
    };
    if (statusField) updates[statusField] = FieldValue.increment(-1);

    // If a completed booking is deleted, roll back earnings.
    if (status === "completed") {
      updates.totalEarnings = FieldValue.increment(-finalFee);
      updates.totalRentalDays = FieldValue.increment(-rentalDays);
      if (monthKey) {
        updates[`earningsByMonth.${monthKey}.earnings`] = FieldValue.increment(-finalFee);
        updates[`earningsByMonth.${monthKey}.rentalDays`] = FieldValue.increment(-rentalDays);
        updates[`earningsByMonth.${monthKey}.completedBookings`] = FieldValue.increment(-1);
      }
    }

    tx.set(summaryRef, updates, { merge: true });
  });
}

async function applyBookingUpdate(before, after) {
  const itemId = after?.itemId || before?.itemId;
  if (!itemId) return;

  await ensureSummaryForItem(itemId);

  const oldStatus = (before?.status || "pending").toString();
  const newStatus = (after?.status || "pending").toString();

  const oldField = statusToField(oldStatus);
  const newField = statusToField(newStatus);

  const newFinalFee = Number(after?.finalFee ?? after?.totalAmount ?? 0) || 0;
  const oldFinalFee = Number(before?.finalFee ?? before?.totalAmount ?? 0) || 0;
  const newRentalDays = Number(after?.rentalDays ?? 0) || 0;
  const oldRentalDays = Number(before?.rentalDays ?? 0) || 0;

  // Determine completedAt month bucket.
  const completedAtTs = after?.actualReturnDate || after?.updatedAt || null;
  const completedAt = completedAtTs?.toDate ? completedAtTs.toDate() : null;
  const monthKey = completedAt ? monthKeyFromDate(completedAt) : null;

  const summaryRef = db.collection("item_summaries").doc(itemId);
  await db.runTransaction(async (tx) => {
    const snap = await tx.get(summaryRef);
    if (!snap.exists) {
      // Shouldn't happen because ensureSummaryForItem ran, but just in case.
      tx.set(summaryRef, { itemId, createdAt: FieldValue.serverTimestamp() }, { merge: true });
    }

    const updates = {
      updatedAt: FieldValue.serverTimestamp(),
    };

    // Status counters
    if (oldField && oldField !== newField) updates[oldField] = FieldValue.increment(-1);
    if (newField && oldField !== newField) updates[newField] = FieldValue.increment(1);

    // Earnings only when ENTERING completed
    if (newStatus === "completed" && oldStatus !== "completed") {
      updates.totalEarnings = FieldValue.increment(newFinalFee);
      updates.totalRentalDays = FieldValue.increment(newRentalDays);
      updates.lastCompletedAt = FieldValue.serverTimestamp();
      if (monthKey) {
        updates[`earningsByMonth.${monthKey}.earnings`] = FieldValue.increment(newFinalFee);
        updates[`earningsByMonth.${monthKey}.rentalDays`] = FieldValue.increment(newRentalDays);
        updates[`earningsByMonth.${monthKey}.completedBookings`] = FieldValue.increment(1);
      }
    }

    // Rollback if LEAVING completed
    if (oldStatus === "completed" && newStatus !== "completed") {
      updates.totalEarnings = FieldValue.increment(-oldFinalFee);
      updates.totalRentalDays = FieldValue.increment(-oldRentalDays);
      if (monthKey) {
        updates[`earningsByMonth.${monthKey}.earnings`] = FieldValue.increment(-oldFinalFee);
        updates[`earningsByMonth.${monthKey}.rentalDays`] = FieldValue.increment(-oldRentalDays);
        updates[`earningsByMonth.${monthKey}.completedBookings`] = FieldValue.increment(-1);
      }
    }

    // If already completed and fee/days changed, adjust the delta.
    if (oldStatus === "completed" && newStatus === "completed") {
      const feeDelta = newFinalFee - oldFinalFee;
      const daysDelta = newRentalDays - oldRentalDays;
      if (feeDelta !== 0) updates.totalEarnings = FieldValue.increment(feeDelta);
      if (daysDelta !== 0) updates.totalRentalDays = FieldValue.increment(daysDelta);
      if (monthKey) {
        if (feeDelta !== 0) updates[`earningsByMonth.${monthKey}.earnings`] = FieldValue.increment(feeDelta);
        if (daysDelta !== 0) updates[`earningsByMonth.${monthKey}.rentalDays`] = FieldValue.increment(daysDelta);
      }
    }

    // Keep lastBookedAt fresh whenever booking doc changes.
    updates.lastBookedAt = FieldValue.serverTimestamp();

    tx.set(summaryRef, updates, { merge: true });
  });
}

// ----------------------------
// Triggers
// ----------------------------

exports.onBookingCreated = functions.firestore
  .document("bookings/{bookingId}")
  .onCreate(async (snap) => applyBookingCreate(snap.data()));

exports.onBookingUpdated = functions.firestore
  .document("bookings/{bookingId}")
  .onUpdate(async (change) => applyBookingUpdate(change.before.data(), change.after.data()));

exports.onBookingDeleted = functions.firestore
  .document("bookings/{bookingId}")
  .onDelete(async (snap) => applyBookingDelete(snap.data()));

/**
 * Increment "edits" and keep summary metadata in sync when an item is updated.
 * - Useful because your Flutter app currently edits items from the client.
 */
exports.onItemUpdated = functions.firestore
  .document("items/{itemId}")
  .onUpdate(async (change, context) => {
    const itemId = context.params.itemId;
    await ensureSummaryForItem(itemId);

    const after = change.after.data() || {};
    const summaryRef = db.collection("item_summaries").doc(itemId);

    await summaryRef.set(
      {
        edits: FieldValue.increment(1),
        renterId: after.renterId ?? null,
        itemName: after.name ?? null,
        category: after.category ?? null,
        size: after.size ?? null,
        pricePerDay: typeof after.pricePerDay === "number" ? after.pricePerDay : 0,
        updatedAt: FieldValue.serverTimestamp(),
      },
      { merge: true }
    );
  });

/**
 * Optional: write a tiny "view event" doc from the client and let the backend increment the summary.
 *
 * Client writes: item_views/{autoId}
 * Fields: { itemId, userId?, createdAt }
 */
exports.onItemViewCreated = functions.firestore
  .document("item_views/{viewId}")
  .onCreate(async (snap) => {
    const data = snap.data() || {};
    const itemId = data.itemId;
    if (!itemId) return;

    await ensureSummaryForItem(itemId);
    const summaryRef = db.collection("item_summaries").doc(itemId);
    await summaryRef.set(
      {
        views: FieldValue.increment(1),
        lastViewedAt: FieldValue.serverTimestamp(),
        updatedAt: FieldValue.serverTimestamp(),
      },
      { merge: true }
    );
  });
