const mongoose = require('mongoose');

/**
 * Booking Model — Production-ready with APPROVED/REJECTED statuses.
 */
const bookingSchema = new mongoose.Schema({
    userId: { type: mongoose.Schema.Types.ObjectId, ref: 'User', required: true },
    tableId: { type: mongoose.Schema.Types.ObjectId, ref: 'Table', default: null },
    bookingDate: { type: String, required: true },   // Format: YYYY-MM-DD
    timeSlot: { type: String, required: true },      // e.g. "12:00-14:00"
    guestCount: { type: Number, required: true, min: 1 },
    occasion: { type: String, default: null },
    specialRequest: { type: String, default: null },
    status: {
        type: String,
        enum: ['PENDING', 'APPROVED', 'REJECTED', 'CANCELLED'],
        default: 'PENDING',
    },
}, { timestamps: true });

// ── Compound index for conflict detection ──
bookingSchema.index({ bookingDate: 1, tableId: 1, status: 1 });
bookingSchema.index({ userId: 1, createdAt: -1 });

module.exports = mongoose.model('Booking', bookingSchema);
