const mongoose = require('mongoose');

const notificationSchema = new mongoose.Schema({
    title: { type: String, required: true },
    message: { type: String, required: true },
    type: {
        type: String,
        enum: ['ORDER', 'NEW_ONLINE_ORDER', 'NEW_DINING_ORDER', 'NEW_TAKEAWAY_ORDER', 'NEW_BOOKING', 'ORDER_STATUS_UPDATE', 'BOOKING_APPROVED', 'PAYMENT_SUCCESS', 'BILL_REQUESTED', 'NEW_USER'],
        required: true
    },
    userId: { type: mongoose.Schema.Types.ObjectId, ref: 'User', default: null }, // For user notifications
    adminId: { type: mongoose.Schema.Types.ObjectId, ref: 'Admin', default: null }, // If specific to admin, or null for all admins
    orderId: { type: mongoose.Schema.Types.ObjectId, ref: 'Order', default: null },
    bookingId: { type: mongoose.Schema.Types.ObjectId, ref: 'Booking', default: null },
    isRead: { type: Boolean, default: false },
    isAdmin: { type: Boolean, default: false } // True if this notification is meant for the admin panel
}, { timestamps: true });

// Delete notifications older than 30 days to save space
notificationSchema.index({ createdAt: 1 }, { expireAfterSeconds: 30 * 24 * 60 * 60 });

module.exports = mongoose.model('Notification', notificationSchema);
