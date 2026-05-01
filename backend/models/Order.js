const mongoose = require('mongoose');

/**
 * Order Model — Full lifecycle with timeline tracking.
 */
const orderItemSchema = new mongoose.Schema({
    menuId: { type: mongoose.Schema.Types.ObjectId, ref: 'Menu', required: true },
    name: { type: String, default: '' },         // Denormalized for fast reads
    quantity: { type: Number, required: true, min: 1 },
    price: { type: Number, required: true, min: 0 },
});

const timelineEntrySchema = new mongoose.Schema({
    status: { type: String, required: true },
    timestamp: { type: Date, default: Date.now },
    note: { type: String, default: '' },
});

const orderSchema = new mongoose.Schema({
    userId: { type: mongoose.Schema.Types.ObjectId, ref: 'User', required: true },
    items: [orderItemSchema],
    totalAmount: { type: Number, required: true, min: 0 }, // Final amount after tips/discounts/taxes
    subtotal: { type: Number, default: 0 },
    discountAmount: { type: Number, default: 0 },
    couponCode: { type: String, default: null },
    deliveryFee: { type: Number, default: 0 },
    gst: { type: Number, default: 0 },
    transactionId: { type: String, default: null },
    order_type: {
        type: String,
        enum: ['DINING', 'ONLINE', 'TAKEAWAY'],
        default: 'ONLINE',
    },
    tableId: { type: mongoose.Schema.Types.ObjectId, ref: 'Table', default: null },
    status: {
        type: String,
        enum: ['PLACED', 'ORDERED', 'CONFIRMED', 'PREPARING', 'READY', 'SERVED', 'WAITING_PAYMENT', 'PAYMENT_PENDING', 'OUT_FOR_DELIVERY', 'READY_FOR_PICKUP', 'DELIVERED', 'COMPLETED', 'CANCELLED'],
        default: 'PLACED',
    },
    paymentMethod: { type: String, default: 'UPI' },
    paymentStatus: {
        type: String,
        enum: ['PENDING', 'PAID', 'SUCCESS', 'FAILED', 'REFUNDED', 'PENDING_VERIFICATION', 'PARTIAL_PAID', 'UNPAID'],
        default: 'PENDING',
    },
    timeline: [timelineEntrySchema],             // Status change history
    deliveryAddress: {
        label: { type: String },
        addressLine: { type: String },
        city: { type: String },
        state: { type: String },
        pincode: { type: String },
        area: { type: String },
        latitude: { type: Number },
        longitude: { type: Number }
    },
    addressId: { type: mongoose.Schema.Types.ObjectId, ref: 'Address' },
    sessionId: { type: mongoose.Schema.Types.ObjectId, ref: 'DiningSession', default: null }, // Section 5: Group by session
    source: { type: String, enum: ['QR', 'ADMIN'], default: 'QR' }, // Section 4: Order source
    // ── Phase 1: Professional order enhancements (safe optional fields) ──
    estimatedDeliveryTime: { type: Number, default: null },          // Minutes until delivery
    isCancelled: { type: Boolean, default: false },
    cancellationReason: { type: String, default: null },
    cancelledAt: { type: Date, default: null },
    ratingExists: { type: Boolean, default: false },
    complaintExists: { type: Boolean, default: false },
}, { timestamps: true });

// ── Indexes ──
orderSchema.index({ userId: 1, createdAt: -1 });
orderSchema.index({ status: 1 });
orderSchema.index({ order_type: 1 });

module.exports = mongoose.model('Order', orderSchema);
