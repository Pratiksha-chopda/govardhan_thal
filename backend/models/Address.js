const mongoose = require('mongoose');

const addressSchema = new mongoose.Schema({
    userId: { type: mongoose.Schema.Types.ObjectId, ref: 'User', required: true },
    label: { type: String, default: 'Home' },
    addressLine: { type: String },
    city: { type: String, required: true },
    state: { type: String, default: 'Gujarat' },
    pincode: { type: String },
    isDefault: { type: Boolean, default: false },
    house: { type: String },
    street: { type: String },
    area: { type: String },
    landmark: { type: String },
    latitude: { type: Number },
    longitude: { type: Number },
    type: { type: String, enum: ['Home', 'Work', 'Other'], default: 'Home' },
}, { timestamps: true });

module.exports = mongoose.model('Address', addressSchema);
