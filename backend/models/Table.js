const mongoose = require('mongoose');

/**
 * Table Model — Represents a physical restaurant table.
 * Separate from DiningSession to track table metadata independently.
 */
const tableSchema = new mongoose.Schema({
    tableNumber: { type: Number, required: true, unique: true },
    capacity: { type: Number, required: true, default: 4, min: 1 },
    qrCode: { type: String, required: true, unique: true },
    status: {
        type: String,
        enum: ['AVAILABLE', 'OCCUPIED', 'RESERVED', 'CLEANING', 'WAITING_PAYMENT', 'PAID_WAITING_EXIT'],
        default: 'AVAILABLE',
    },
}, { timestamps: true });


tableSchema.index({ status: 1 });

module.exports = mongoose.model('Table', tableSchema);
