/**
 * Admin Auth Controller — Handles admin-specific authentication.
 * Uses the Admin model (separate from User) for security isolation.
 * Admin accounts are created via seed/CLI, not public registration.
 */
const jwt = require('jsonwebtoken');
const bcrypt = require('bcryptjs');
const Admin = require('../models/Admin');
const asyncHandler = require('../utils/asyncHandler');
const { sendSuccess, sendError } = require('../utils/responseHelper');

const JWT_SECRET = process.env.JWT_SECRET || 'govardhan_thal_super_secret_key';
const REFRESH_SECRET = process.env.REFRESH_SECRET || 'govardhan_thal_refresh_secret';
const JWT_EXPIRE = process.env.JWT_EXPIRE || '1d';

/**
 * POST /api/v1/auth/admin-login
 * Body: { email, password }
 * 
 * Authenticates against Admin collection (not User collection).
 * Returns JWT token with role='admin'.
 */
exports.adminLogin = asyncHandler(async (req, res) => {
    const { email, password } = req.body;

    if (!email || !password) {
        return sendError(res, 'Email and password are required', 400);
    }

    // Find admin by email (include password for comparison)
    const admin = await Admin.findOne({ email: email.toLowerCase().trim() }).select('+password');
    if (!admin) {
        return sendError(res, 'Invalid admin credentials', 401);
    }

    // Compare password
    const isMatch = await bcrypt.compare(password, admin.password);
    if (!isMatch) {
        return sendError(res, 'Invalid admin credentials', 401);
    }

    // Generate JWT tokens
    const payload = { id: admin._id, role: 'admin' };
    const accessToken = jwt.sign(payload, JWT_SECRET, { expiresIn: JWT_EXPIRE });
    const refreshToken = jwt.sign(payload, REFRESH_SECRET, { expiresIn: '30d' });

    sendSuccess(res, {
        accessToken,
        refreshToken,
        user: {
            user_id: admin._id,
            name: admin.name,
            email: admin.email,
            role: 'admin',
        },
    }, 'Admin login successful');
});
