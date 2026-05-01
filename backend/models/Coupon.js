const mongoose = require('mongoose');

/**
 * Coupon Model — Stores available discount codes.
 */
const couponSchema = new mongoose.Schema({
    code: { 
        type: String, 
        required: true, 
        unique: true, 
        uppercase: true,
        trim: true 
    },
    type: { 
        type: String, 
        enum: ['FLAT', 'PERCENTAGE', 'FREE_DELIVERY'], 
        required: true 
    },
    value: { 
        type: Number, 
        required: true, 
        min: 0 
    },
    minOrderAmount: { 
        type: Number, 
        default: 0 
    },
    maxDiscount: { 
        type: Number, 
        default: 0 // For percentage coupons
    },
    expiryDate: { 
        type: Date, 
        required: true 
    },
    isActive: { 
        type: Boolean, 
        default: true 
    },
    description: { 
        type: String, 
        default: '' 
    },
    applicableFor: {
        type: String,
        enum: ['ONLINE', 'DINING', 'TAKEAWAY', 'ALL'],
        default: 'ALL'
    }
}, { timestamps: true });

module.exports = mongoose.model('Coupon', couponSchema);
