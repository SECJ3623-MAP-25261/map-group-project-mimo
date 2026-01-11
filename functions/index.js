const admin = require("firebase-admin");
admin.initializeApp();

// Export modules
const spending = require("./modules/spending");
const notifications = require("./modules/pushNotifications");
const itemSummary = require("./modules/itemSummary");

// Spending Analysis Functions
exports.generateSpendingAnalysis = spending.generateSpendingAnalysis;
exports.regenerateSpendingAnalysis = spending.regenerateSpendingAnalysis;
exports.scheduledSpendingAnalysisUpdate = spending.scheduledSpendingAnalysisUpdate;

// Notification Functions
exports.sendNotificationOnCreate = notifications.sendNotificationOnCreate;

// Item Summary (backend counters)
exports.onBookingCreated = itemSummary.onBookingCreated;
exports.onBookingUpdated = itemSummary.onBookingUpdated;
exports.onBookingDeleted = itemSummary.onBookingDeleted;
exports.onItemUpdated = itemSummary.onItemUpdated;
exports.onItemViewCreated = itemSummary.onItemViewCreated;