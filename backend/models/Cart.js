const mongoose = require('mongoose');

/**
 * Cart Model — One cart document per user.
 * Each cart contains an items array with menuId references.
 */
const cartItemSchema = new mongoose.Schema({
    menuId: { type: mongoose.Schema.Types.ObjectId, ref: 'Menu', required: true },
    quantity: { type: Number, required: true, min: 1, default: 1 },
    price: { type: Number, required: true, min: 0 },
}, { _id: true });

const cartSchema = new mongoose.Schema({
    userId: { type: mongoose.Schema.Types.ObjectId, ref: 'User', required: true, unique: true },
    items: [cartItemSchema],
}, { timestamps: true });

// Virtual: total price computed from items
cartSchema.virtual('totalPrice').get(function () {
    return this.items.reduce((sum, item) => sum + item.price * item.quantity, 0);
});

// Ensure virtuals are included in JSON output
cartSchema.set('toJSON', { virtuals: true });

module.exports = mongoose.model('Cart', cartSchema);
