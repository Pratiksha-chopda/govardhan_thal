/**
 * Rating Model — Phase 6
 * 
 * Separate collection for order ratings/reviews.
 * Does NOT modify existing Order or Menu models.
 */
const mongoose = require('mongoose');

const ratingSchema = new mongoose.Schema({
    orderId: { type: mongoose.Schema.Types.ObjectId, ref: 'Order', required: true, unique: true },
    userId: { type: mongoose.Schema.Types.ObjectId, ref: 'User', required: true },
    rating: { type: Number, required: true, min: 1, max: 5 },
    review: { type: String, default: '', maxlength: 500 },
    itemRatings: [{
        menuId: { type: mongoose.Schema.Types.ObjectId, ref: 'Menu' },
        rating: { type: Number, min: 1, max: 5 },
    }],
}, { timestamps: true });

ratingSchema.index({ userId: 1, createdAt: -1 });

module.exports = mongoose.model('Rating', ratingSchema);
