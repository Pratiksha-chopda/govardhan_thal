const mongoose = require('mongoose');

/**
 * Admin Model — Separate from User for security isolation.
 * Admin accounts are created via seed or CLI, not public registration.
 */
const adminSchema = new mongoose.Schema({
    email: { type: String, required: true, unique: true, lowercase: true, trim: true },
    password: { type: String, required: true, select: false },
    role: { type: String, default: 'admin' },
    name: { type: String, default: 'Admin' },
}, { timestamps: true });

module.exports = mongoose.model('Admin', adminSchema);
