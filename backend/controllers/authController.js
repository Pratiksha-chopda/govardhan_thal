/**
 * Auth Controller — Handles authentication endpoints.
 * Delegates business logic to authService.
 */
const authService = require('../services/authService');
const asyncHandler = require('../utils/asyncHandler');
const { sendSuccess, sendError } = require('../utils/responseHelper');

/**
 * POST /api/v1/auth/firebase-login
 * Body: { firebaseUID, email, name, profileImage }
 */
exports.firebaseLogin = asyncHandler(async (req, res) => {
    const { firebaseUID, email, name, profileImage } = req.body;
    const result = await authService.firebaseLogin({ firebaseUID, email, name, profileImage });

    sendSuccess(res, result, 'Login successful', 200);
});

/**
 * POST /api/v1/auth/login
 * Body: { mobile, password }
 */
exports.login = asyncHandler(async (req, res) => {
    const { mobile, password } = req.body;
    const result = await authService.mobileLogin({ mobile, password });

    sendSuccess(res, result, 'Login successful', 200);
});

/**
 * POST /api/v1/auth/register
 * Body: { name, email, mobile, password }
 */
exports.register = asyncHandler(async (req, res) => {
    const { name, email, mobile, password } = req.body;
    const result = await authService.register({ name, email, mobile, password });

    sendSuccess(res, result, 'User registered successfully', 201);
});

/**
 * POST /api/v1/auth/refresh-token
 * Body: { refreshToken }
 */
exports.refreshToken = asyncHandler(async (req, res) => {
    const { refreshToken } = req.body;
    const result = await authService.refreshToken(refreshToken);

    sendSuccess(res, result, 'Token refreshed', 200);
});

/**
 * POST /api/v1/auth/forgot-password
 * Body: { mobile }
 */
exports.forgotPassword = asyncHandler(async (req, res) => {
    const { mobile } = req.body;
    const result = await authService.forgotPassword({ mobile });
    sendSuccess(res, result, result.message, 200);
});

/**
 * POST /api/v1/auth/verify-otp
 * Body: { mobile, otp }
 */
exports.verifyOtp = asyncHandler(async (req, res) => {
    const { mobile, otp } = req.body;
    const result = await authService.verifyOtp({ mobile, otp });
    sendSuccess(res, result, result.message, 200);
});

/**
 * POST /api/v1/auth/reset-password
 * Body: { mobile, otp, newPassword }
 */
exports.resetPassword = asyncHandler(async (req, res) => {
    const { mobile, otp, newPassword } = req.body;
    const result = await authService.resetPassword({ mobile, otp, newPassword });
    sendSuccess(res, result, result.message, 200);
});

/**
 * POST /api/v1/auth/reset-password-firebase
 * Body: { mobile, newPassword, firebaseUID }
 */
exports.resetPasswordFirebase = asyncHandler(async (req, res) => {
    const { mobile, newPassword, firebaseUID } = req.body;
    const result = await authService.resetPasswordFirebase({ mobile, newPassword, firebaseUID });
    sendSuccess(res, result, result.message, 200);
});
