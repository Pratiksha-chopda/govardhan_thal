/**
 * Request Validation Middleware
 * Uses express-validator to validate incoming request bodies.
 * Each export is an array of validation rules that can be used directly in routes.
 *
 * Usage in route: router.post('/login', validate.firebaseLogin, controller.method);
 */
const { body, query, param, validationResult } = require('express-validator');

/**
 * Middleware that checks validation results and returns 400 if invalid.
 * Must be placed AFTER the validation rules in the route chain.
 */
const checkValidation = (req, res, next) => {
    const errors = validationResult(req);
    if (!errors.isEmpty()) {
        return res.status(400).json({
            status: 'error',
            message: 'Validation failed',
            errors: errors.array().map((e) => ({ field: e.path, message: e.msg })),
        });
    }
    next();
};

// ────────────────────────────────────────────────────────────
// AUTH VALIDATORS
// ────────────────────────────────────────────────────────────

const firebaseLogin = [
    body('firebaseUID').notEmpty().withMessage('firebaseUID is required'),
    body('email').isEmail().withMessage('Valid email is required'),
    body('name').notEmpty().withMessage('Name is required'),
    checkValidation,
];

const mobileLogin = [
    body('mobile').isLength({ min: 10, max: 10 }).withMessage('Mobile must be 10 digits'),
    body('password').notEmpty().withMessage('Password is required'),
    checkValidation,
];

const register = [
    body('name').notEmpty().withMessage('Name is required'),
    body('mobile').isLength({ min: 10, max: 10 }).withMessage('Mobile must be 10 digits'),
    body('password').isLength({ min: 6 }).withMessage('Password must be at least 6 characters'),
    checkValidation,
];

const refreshToken = [
    body('refreshToken').notEmpty().withMessage('Refresh token is required'),
    checkValidation,
];

const forgotPassword = [
    body('mobile').isLength({ min: 10, max: 10 }).withMessage('Mobile must be 10 digits'),
    checkValidation,
];

const verifyOtp = [
    body('mobile').isLength({ min: 10, max: 10 }).withMessage('Mobile must be 10 digits'),
    body('otp').isLength({ min: 4 }).withMessage('OTP must be at least 4 digits'),
    checkValidation,
];

const resetPassword = [
    body('mobile').isLength({ min: 10, max: 10 }).withMessage('Mobile must be 10 digits'),
    body('otp').isLength({ min: 4 }).withMessage('OTP must be at least 4 digits'),
    body('newPassword').isLength({ min: 6 }).withMessage('Password must be at least 6 characters'),
    checkValidation,
];

const resetPasswordFirebase = [
    body('mobile').isLength({ min: 10, max: 10 }).withMessage('Mobile must be 10 digits'),
    body('firebaseUID').notEmpty().withMessage('Firebase UID must be provided'),
    body('newPassword').isLength({ min: 6 }).withMessage('Password must be at least 6 characters'),
    checkValidation,
];

// ────────────────────────────────────────────────────────────
// CART VALIDATORS
// ────────────────────────────────────────────────────────────

const addToCart = [
    body('menuId').notEmpty().withMessage('menuId is required'),
    body('quantity').isInt({ min: 1 }).withMessage('Quantity must be at least 1'),
    checkValidation,
];

// ────────────────────────────────────────────────────────────
// ORDER VALIDATORS
// ────────────────────────────────────────────────────────────

const placeOrder = [
    body('items').isArray({ min: 1 }).withMessage('Items array is required'),
    body('items.*.menuId').notEmpty().withMessage('Each item needs a menuId'),
    body('items.*.quantity').isInt({ min: 1 }).withMessage('Each item needs quantity >= 1'),
    body('items.*.price').isFloat({ min: 0 }).withMessage('Each item needs a valid price'),
    body('orderType').optional().isIn(['DINING', 'ONLINE', 'TAKEAWAY']).withMessage('orderType must be DINING, ONLINE or TAKEAWAY'),
    checkValidation,
];

const updateOrderStatus = [
    param('orderId').notEmpty().withMessage('orderId is required'),
    body('status').optional().isIn(['PLACED', 'CONFIRMED', 'PREPARING', 'READY', 'SERVED', 'PAYMENT_PENDING', 'OUT_FOR_DELIVERY', 'READY_FOR_PICKUP', 'DELIVERED', 'COMPLETED', 'CANCELLED'])
        .withMessage('Invalid order status'),
    body('paymentStatus').optional().isIn(['PENDING', 'PAID', 'SUCCESS', 'FAILED', 'REFUNDED'])
        .withMessage('Invalid payment status'),
    checkValidation,
];

// ────────────────────────────────────────────────────────────
// BOOKING VALIDATORS
// ────────────────────────────────────────────────────────────

const createBooking = [
    body('date').notEmpty().withMessage('Date is required (YYYY-MM-DD)'),
    body('timeSlot').notEmpty().withMessage('Time slot is required'),
    body('guestCount').isInt({ min: 1 }).withMessage('Guest count must be at least 1'),
    checkValidation,
];

// ────────────────────────────────────────────────────────────
// MENU VALIDATORS (Admin)
// ────────────────────────────────────────────────────────────

const createMenu = [
    body('name').notEmpty().withMessage('Menu item name is required'),
    body('category').notEmpty().withMessage('Category is required'),
    body('price').optional().isFloat({ min: 0 }).withMessage('Price must be a positive number'),
    body('priceINR').optional().isFloat({ min: 0 }).withMessage('Price (INR) must be a positive number'),
    // Ensure at least one price field is present
    body().custom((value, { req }) => {
        if (!req.body.price && !req.body.priceINR) {
            throw new Error('Price or priceINR is required');
        }
        return true;
    }),
    checkValidation,
];

// ────────────────────────────────────────────────────────────
// DINING VALIDATORS
// ────────────────────────────────────────────────────────────

const verifyTable = [
    body('qrCode').notEmpty().withMessage('QR code is required'),
    checkValidation,
];

module.exports = {
    firebaseLogin,
    mobileLogin,
    register,
    refreshToken,
    addToCart,
    placeOrder,
    updateOrderStatus,
    createBooking,
    createMenu,
    verifyTable,
    forgotPassword,
    verifyOtp,
    resetPassword,
    resetPasswordFirebase,
};
