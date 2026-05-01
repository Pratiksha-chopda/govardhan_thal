const mongoose = require('mongoose');

/**
 * Menu Model — Production-ready Gujarati/Indian restaurant menu.
 *
 * Fields:
 *   name, category, description
 *   price / priceINR  — stored in INR (both accepted on write; price is canonical)
 *   priceSGD          — virtual, computed at 1 INR = 0.016 SGD
 *   imageUrl          — stored URL (admin upload / direct URL). Takes priority.
 *   imageKeyword      — drives dynamic Unsplash fallback when imageUrl is empty
 *   resolvedImageUrl  — virtual: imageUrl || Unsplash keyword URL || generic fallback
 *   isVeg, rating, isAvailable
 *   isPopular, isRecommended, isTodaySpecial
 *   isDeleted         — soft delete flag
 *
 * Categories: Thali | Sabji | Farsan | Sweets | Dal | Rice | Roti | Beverages | Extras
 */

const VALID_CATEGORIES = ['Thali', 'Sabji', 'Farsan', 'Sweets', 'Dal', 'Rice', 'Roti', 'Beverages', 'Extras'];
const INR_TO_SGD_RATE  = 0.016; // 1 INR ≈ 0.016 SGD — update periodically
const FALLBACK_IMAGE   = 'https://upload.wikimedia.org/wikipedia/commons/6/65/Indian_food.jpg';

const menuSchema = new mongoose.Schema({
    name:           { type: String, required: true, trim: true },
    category:       { type: String, required: true, trim: true, enum: VALID_CATEGORIES },
    description:    { type: String, default: '' },

    // ── Price & Tax ───────────────────────────────────────────────────────────
    // Stored as `price` (INR). `priceINR` is a write alias accepted in pre-save.
    price:          { type: Number, required: true, min: 0 },
    gstRate:        { type: Number, default: 5, min: 0, max: 100 }, // Individual GST % (0, 5, 12, 18)

    // ── Image ─────────────────────────────────────────────────────────────────
    // Admin can upload a file (imageUrl = '/images/filename') OR set a direct URL.
    // When imageUrl is empty, resolvedImageUrl falls back to the Unsplash keyword URL.
    imageUrl:       { type: String, default: '' },
    imageKeyword:   { type: String, default: 'indian,food' },

    // ── Flags ─────────────────────────────────────────────────────────────────
    isVeg:          { type: Boolean, default: true },
    rating:         { type: Number,  default: 4.0, min: 0, max: 5 },
    isAvailable:    { type: Boolean, default: true },
    isPopular:      { type: Boolean, default: false },
    isRecommended:  { type: Boolean, default: false },
    isTodaySpecial: { type: Boolean, default: false },
    isDeleted:      { type: Boolean, default: false },  // Soft delete

    // ── Inventory / Recipe ───────────────────────────────────────────────────
    recipe: [{
        ingredientId: { type: mongoose.Schema.Types.ObjectId, ref: 'Ingredient' },
        quantity:     { type: Number, required: true },
        unit:         { type: String, required: true }
    }],
}, {
    timestamps: true,
    // Make virtuals available in toJSON / toObject
    toJSON:   { virtuals: true },
    toObject: { virtuals: true },
});

// ── Pre-save: accept aliases ───────────────────────
menuSchema.pre('save', async function () {
    if (this.priceINR !== undefined && this.price === undefined) {
        this.price = this.priceINR;
    }
    if (this.imageURL !== undefined && (this.imageUrl === undefined || this.imageUrl === '')) {
        this.imageUrl = this.imageURL;
    }
});

// ── Virtual: SGD price ────────────────────────────────────────────────────────
menuSchema.virtual('priceSGD').get(function () {
    return +(this.price * INR_TO_SGD_RATE).toFixed(2);
});

// ── Virtual: priceINR (alias) ─────────────────────────────────────────────────
menuSchema.virtual('priceINR').get(function () {
    return this.price;
});

// ── Virtual: imageURL (alias) ─────────────────────────────────────────────────
menuSchema.virtual('imageURL').get(function () {
    return this.imageUrl;
});
menuSchema.virtual('imageURL').set(function (val) {
    this.imageUrl = val;
});

// ── Virtual: resolved image URL ───────────────────────────────────────────────
// Priority: stored imageUrl > keyword Unsplash URL > generic fallback
menuSchema.virtual('resolvedImageUrl').get(function () {
    if (this.imageUrl && this.imageUrl.trim()) return this.imageUrl.trim();
    const kw = (this.imageKeyword || '').trim();
    return kw
        ? `https://source.unsplash.com/600x400/?${encodeURIComponent(kw)}`
        : FALLBACK_IMAGE;
});

// ── Indexes ───────────────────────────────────────────────────────────────────
menuSchema.index({ name: 'text', description: 'text' });          // Full-text search
menuSchema.index({ category: 1, isAvailable: 1, isDeleted: 1 }); // Category filter
menuSchema.index({ isPopular: 1, isDeleted: 1 });                 // Popular filter
menuSchema.index({ isRecommended: 1, isDeleted: 1 });             // Recommended filter
menuSchema.index({ isTodaySpecial: 1, isDeleted: 1 });            // Today's specials
menuSchema.index({ rating: -1 });                                  // Sort by rating

module.exports = mongoose.model('Menu', menuSchema);

