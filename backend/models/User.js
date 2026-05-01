const mongoose = require('mongoose');

const userSchema = new mongoose.Schema({
    name: { type: String, required: true, trim: true },
    email: { type: String, unique: true, sparse: true, lowercase: true, trim: true },
    mobile: { type: String, sparse: true, trim: true },          // Optional for Google users
    password: { type: String, select: false },                     // Hidden by default, select:false
    firebaseUID: { type: String, unique: true, sparse: true },    // Firebase Google Sign-In UID
    profileImage: { type: String, default: '' },                  // Google profile photo URL
    loginType: { type: String, enum: ['mobile', 'google'], default: 'mobile' },
    role: { type: String, enum: ['user', 'admin'], default: 'user' },
    refreshToken: { type: String, select: false },                // JWT refresh token, hidden
    fcmToken: { type: String, default: '' },                       // Firebase Cloud Messaging token
    wishlist: [{ type: mongoose.Schema.Types.ObjectId, ref: 'Menu' }],  // Array of favorite menu item IDs
    resetOtp: { type: String },                                   // For forgot password
    resetOtpExpires: { type: Date },                              // Expiration time for reset OTP
}, { timestamps: true });

// ── Indexes for fast lookup ──


module.exports = mongoose.model('User', userSchema);
