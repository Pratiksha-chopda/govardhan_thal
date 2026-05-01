const express = require('express');
const router = express.Router();
const authController = require('../controllers/authController');
const adminAuthController = require('../controllers/adminAuthController');
const validate = require('../middleware/validateRequest');

// Firebase Google Sign-In login
router.post('/firebase-login', validate.firebaseLogin, authController.firebaseLogin);

// Mobile login
router.post('/login', validate.mobileLogin, authController.login);

// Register
router.post('/register', validate.register, authController.register);

// Refresh token
router.post('/refresh-token', validate.refreshToken, authController.refreshToken);

// Forgot Password Flow
router.post('/forgot-password', validate.forgotPassword, authController.forgotPassword);
router.post('/verify-otp', validate.verifyOtp, authController.verifyOtp);
router.post('/reset-password', validate.resetPassword, authController.resetPassword);
router.post('/reset-password-firebase', validate.resetPasswordFirebase, authController.resetPasswordFirebase);

// ── Admin Login (uses Admin model, not User model) ──
router.post('/admin-login', adminAuthController.adminLogin);

module.exports = router;
