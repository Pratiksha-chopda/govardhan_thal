/**
 * Auth Service — Business logic for authentication.
 * Handles Firebase login, mobile login, registration, token refresh, and password reset.
 */
const jwt = require('jsonwebtoken');
const bcrypt = require('bcryptjs');
const User = require('../models/User');
const UserSettings = require('../models/UserSettings');
const { sendOtpEmail } = require('../utils/emailService');

const JWT_SECRET = process.env.JWT_SECRET || 'govardhan_thal_super_secret_key';
const REFRESH_SECRET = process.env.REFRESH_SECRET || 'govardhan_thal_refresh_secret';
const JWT_EXPIRE = process.env.JWT_EXPIRE || '1d';

// ── Helper: Generate tokens ──
const generateTokens = (user) => {
    const payload = { id: user._id, role: user.role };
    const accessToken = jwt.sign(payload, JWT_SECRET, { expiresIn: JWT_EXPIRE });
    const refreshToken = jwt.sign(payload, REFRESH_SECRET, { expiresIn: '30d' });
    return { accessToken, refreshToken };
};

/**
 * Firebase Google Sign-In Login
 * Flutter sends: { firebaseUID, email, name, profileImage }
 * Backend: find-or-create user → generate tokens → return
 */
const firebaseLogin = async ({ firebaseUID, email, name, profileImage }) => {
    // Check if user already exists by firebaseUID
    let user = await User.findOne({ firebaseUID });

    if (!user) {
        // Check if email already exists (user might have registered via mobile first)
        user = await User.findOne({ email });
        if (user) {
            // Link Firebase UID to existing account
            user.firebaseUID = firebaseUID;
            user.profileImage = profileImage || user.profileImage;
            user.loginType = 'google';
            await user.save();
        } else {
            // Create brand new user
            user = await User.create({
                name,
                email,
                firebaseUID,
                profileImage: profileImage || '',
                loginType: 'google',
                role: 'user',
            });
            // Create default settings for new user
            await UserSettings.create({ userId: user._id });
        }
    }

    // Generate JWT tokens
    const { accessToken, refreshToken } = generateTokens(user);

    // Store refresh token in DB
    user.refreshToken = refreshToken;
    await user.save();

    return {
        accessToken,
        refreshToken,
        user: {
            user_id: user._id,
            name: user.name,
            email: user.email,
            profileImage: user.profileImage,
            role: user.role,
        },
    };
};

/**
 * Mobile Login — existing mobile + password flow
 */
const mobileLogin = async ({ mobile, password }) => {
    const user = await User.findOne({ mobile }).select('+password');
    if (!user) throw Object.assign(new Error('User not found'), { statusCode: 401 });

    const isMatch = await bcrypt.compare(password, user.password);
    if (!isMatch) throw Object.assign(new Error('Invalid credentials'), { statusCode: 401 });

    const { accessToken, refreshToken } = generateTokens(user);

    user.refreshToken = refreshToken;
    await user.save();

    return {
        accessToken,
        refreshToken,
        user: {
            user_id: user._id,
            name: user.name,
            mobile: user.mobile,
            role: user.role,
        },
    };
};

/**
 * Register — mobile signup
 */
const register = async ({ name, email, mobile, password }) => {
    const existing = await User.findOne({ mobile });
    if (existing) throw Object.assign(new Error('Mobile already in use'), { statusCode: 400 });

    // Also check if email is provided and already taken
    const trimmedEmail = email && email.trim() ? email.trim().toLowerCase() : undefined;
    if (trimmedEmail) {
        const emailExists = await User.findOne({ email: trimmedEmail });
        if (emailExists) throw Object.assign(new Error('Email already in use'), { statusCode: 400 });
    }

    const hashedPassword = await bcrypt.hash(password, 10);
    const newUser = await User.create({
        name,
        email: trimmedEmail,  // undefined when empty → sparse index ignores it
        mobile,
        password: hashedPassword,
        loginType: 'mobile',
        role: 'user',
    });

    // Create default settings
    await UserSettings.create({ userId: newUser._id });

    return { user_id: newUser._id };
};

/**
 * Refresh Token — issue new access token using valid refresh token
 */
const refreshTokenService = async (token) => {
    const decoded = jwt.verify(token, REFRESH_SECRET);
    const user = await User.findById(decoded.id).select('+refreshToken');

    if (!user || user.refreshToken !== token) {
        throw Object.assign(new Error('Invalid refresh token'), { statusCode: 401 });
    }

    const { accessToken, refreshToken: newRefreshToken } = generateTokens(user);

    user.refreshToken = newRefreshToken;
    await user.save();

    return { accessToken, refreshToken: newRefreshToken };
};

/**
 * Forgot Password - Generates OTP and sends via Email
 */
const forgotPassword = async ({ mobile }) => {
    const user = await User.findOne({ mobile });
    if (!user) throw Object.assign(new Error('User not found'), { statusCode: 404 });

    // Ensure user has an email to send OTP to
    if (!user.email) {
        throw Object.assign(new Error('No email linked to this account. Contact support.'), { statusCode: 400 });
    }

    // Generate 4 digit OTP
    const otp = Math.floor(1000 + Math.random() * 9000).toString();
    
    // Set OTP and expiration (10 mins)
    user.resetOtp = otp;
    user.resetOtpExpires = Date.now() + 10 * 60 * 1000;
    await user.save();

    // Send OTP via email
    const emailSent = await sendOtpEmail(user.email, otp, user.name);

    // Mask email for privacy (e.g., pr***@gmail.com)
    const [localPart, domain] = user.email.split('@');
    const maskedEmail = localPart.substring(0, 2) + '***@' + domain;

    if (emailSent) {
        return { message: `OTP sent to ${maskedEmail}`, maskedEmail };
    } else {
        // Fallback: if email config is not set up yet, return OTP for dev testing
        console.log(`[FALLBACK] Email send failed. OTP for ${mobile} is: ${otp}`);
        return { message: `OTP sent to ${maskedEmail}`, maskedEmail, devOtp: otp };
    }
};

/**
 * Verify OTP
 */
const verifyOtp = async ({ mobile, otp }) => {
    const user = await User.findOne({ 
        mobile, 
        resetOtp: otp, 
        resetOtpExpires: { $gt: Date.now() } 
    });

    if (!user) {
        throw Object.assign(new Error('Invalid or expired OTP'), { statusCode: 400 });
    }

    return { message: 'OTP verified successfully' };
};

/**
 * Reset Password
 */
const resetPassword = async ({ mobile, otp, newPassword }) => {
    const user = await User.findOne({ 
        mobile, 
        resetOtp: otp, 
        resetOtpExpires: { $gt: Date.now() } 
    });

    if (!user) {
        throw Object.assign(new Error('Invalid or expired OTP'), { statusCode: 400 });
    }

    const hashedPassword = await bcrypt.hash(newPassword, 10);
    user.password = hashedPassword;
    
    // Clear OTP logic
    user.resetOtp = undefined;
    user.resetOtpExpires = undefined;
    await user.save();

    return { message: 'Password reset successful' };
};

/**
 * Reset Password via Firebase Phone Auth
 * Flutter authenticates the OTP directly with Firebase, then calls this endpoint.
 */
const resetPasswordFirebase = async ({ mobile, newPassword, firebaseUID }) => {
    const user = await User.findOne({ mobile });

    if (!user) {
        throw Object.assign(new Error('User not found'), { statusCode: 400 });
    }

    if (!firebaseUID) {
        throw Object.assign(new Error('Validation failed. Firebase UID missing.'), { statusCode: 400 });
    }

    const hashedPassword = await bcrypt.hash(newPassword, 10);
    user.password = hashedPassword;
    
    // Optionally link the Firebase UID if they didn't have one
    if (!user.firebaseUID) {
        user.firebaseUID = firebaseUID;
    }
    
    // Clear any pending email OTPs just in case
    user.resetOtp = undefined;
    user.resetOtpExpires = undefined;
    
    await user.save();

    return { message: 'Password reset successful' };
};

module.exports = { 
    firebaseLogin, 
    mobileLogin, 
    register, 
    refreshToken: refreshTokenService,
    forgotPassword,
    verifyOtp,
    resetPassword,
    resetPasswordFirebase
};
