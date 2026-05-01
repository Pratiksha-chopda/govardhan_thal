const mongoose = require('mongoose');

const userSettingsSchema = new mongoose.Schema({
    userId: { type: mongoose.Schema.Types.ObjectId, ref: 'User', required: true, unique: true },
    notificationsEnabled: { type: Boolean, default: true },
    orderUpdates: { type: Boolean, default: true },
    promotions: { type: Boolean, default: false }
}, { timestamps: true });

module.exports = mongoose.model('UserSettings', userSettingsSchema);
