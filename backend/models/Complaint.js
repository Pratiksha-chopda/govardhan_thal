/**
 * Complaint Model — Phase 7
 * 
 * Separate collection for order complaints/issues.
 * Does NOT modify existing models.
 */
const mongoose = require('mongoose');

const complaintSchema = new mongoose.Schema({
    orderId: { type: mongoose.Schema.Types.ObjectId, ref: 'Order', required: true },
    userId: { type: mongoose.Schema.Types.ObjectId, ref: 'User', required: true },
    issueType: {
        type: String,
        enum: ['WRONG_ITEM', 'MISSING_ITEM', 'FOOD_QUALITY', 'LATE_DELIVERY', 'PACKAGING', 'OTHER'],
        required: true,
    },
    description: { type: String, default: '', maxlength: 1000 },
    status: {
        type: String,
        enum: ['OPEN', 'IN_PROGRESS', 'RESOLVED', 'CLOSED'],
        default: 'OPEN',
    },
    adminNote: { type: String, default: '' },
    resolvedAt: { type: Date, default: null },
}, { timestamps: true });

complaintSchema.index({ orderId: 1 });
complaintSchema.index({ userId: 1, createdAt: -1 });
complaintSchema.index({ status: 1 });

module.exports = mongoose.model('Complaint', complaintSchema);
