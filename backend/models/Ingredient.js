const mongoose = require('mongoose');

/**
 * Ingredient Model — Tracks raw materials used in recipes.
 * Linked to Menu items to automate inventory deduction.
 */
const ingredientSchema = new mongoose.Schema({
    name: { type: String, required: true, unique: true, trim: true },
    stock: { type: Number, default: 0, min: 0 },
    unit: { type: String, required: true, enum: ['kg', 'g', 'l', 'ml', 'pcs', 'box'] },
    lowStockThreshold: { type: Number, default: 5 },
    pricePerUnit: { type: Number, default: 0 }, // For costing analysis
    lastPurchasedAt: { type: Date },
}, { timestamps: true });

module.exports = mongoose.model('Ingredient', ingredientSchema);
