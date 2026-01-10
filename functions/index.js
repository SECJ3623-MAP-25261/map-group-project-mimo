const admin = require("firebase-admin");
admin.initializeApp();

// Export modules
const spending = require("./modules/spending");
const notifications = require("./modules/notifications");

// Spending Analysis Functions
exports.generateSpendingAnalysis = spending.generateSpendingAnalysis;
exports.regenerateSpendingAnalysis = spending.regenerateSpendingAnalysis;
exports.scheduledSpendingAnalysisUpdate = spending.scheduledSpendingAnalysisUpdate;

// Notification Functions
exports.sendNotificationOnCreate = notifications.sendNotificationOnCreate;