const mongoose = require('mongoose');

/**
 * DiningSession Model — Tracks an active dine-in session.
 * Created when a customer scans a QR code and starts ordering.
 * Stores order references and tracks billing/payment lifecycle.
 */
const diningSessionSchema = new mongoose.Schema({
    userId:        { type: mongoose.Schema.Types.ObjectId, ref: 'User', required: true }, // Initial user
    users:         [{ type: mongoose.Schema.Types.ObjectId, ref: 'User' }], // All participating users
    tableId:       { type: mongoose.Schema.Types.ObjectId, ref: 'Table', required: true },
    orders:        [{ type: mongoose.Schema.Types.ObjectId, ref: 'Order' }],
    totalAmount:   { type: Number, default: 0 },
    subtotal:      { type: Number, default: 0 },
    gstAmount:     { type: Number, default: 0 },
    gstPercent:    { type: Number, default: 5 },
    paymentStatus: {
        type: String,
        enum: ['UNPAID', 'PAYMENT_PENDING', 'PAID'],
        default: 'UNPAID',
    },
    paymentMethod: { type: String, default: null },
    transactionId: { type: String, default: null },
    startTime:     { type: Date, default: Date.now },
    endTime:       { type: Date, default: null },
    status: {
        type: String,
        enum: ['ACTIVE', 'BILL_REQUESTED', 'PAID_WAITING_EXIT', 'CLOSED', 'COMPLETED'],
        default: 'ACTIVE',
    },
}, { timestamps: true });

diningSessionSchema.index({ userId: 1, status: 1 });
diningSessionSchema.index({ users: 1, status: 1 });
diningSessionSchema.index({ tableId: 1, status: 1 });

module.exports = mongoose.model('DiningSession', diningSessionSchema);
