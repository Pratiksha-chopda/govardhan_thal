/**
 * Booking Controller — Handles booking endpoints.
 * Gets userId from JWT token (req.user.id).
 */
const bookingService = require('../services/bookingService');
const asyncHandler = require('../utils/asyncHandler');
const { sendSuccess } = require('../utils/responseHelper');
const socket = require('../socket');
const User = require('../models/User');

/**
 * POST /api/v1/bookings
 * Body: { date, timeSlot, guestCount }
 */
exports.createBooking = asyncHandler(async (req, res) => {
    const { date, timeSlot, guestCount, occasion, specialRequest, mobile } = req.body;
    const userId = req.user.id || req.user._id;

    // Update user mobile if missing
    if (mobile) {
        const user = await User.findById(userId);
        if (user && !user.mobile) {
            user.mobile = mobile;
            await user.save();
        }
    }

    const result = await bookingService.createBooking(userId, { date, timeSlot, guestCount, occasion, specialRequest });
    socket.emitBookingNew(result);
    sendSuccess(res, result, 'Booking request received', 201);
});

/**
 * GET /api/v1/bookings/availability
 * Query: ?date=&timeSlot=&guests=
 */
exports.checkAvailability = asyncHandler(async (req, res) => {
    const { date, timeSlot, guests } = req.query;
    const tables = await bookingService.checkAvailability({ date, timeSlot, guests });
    sendSuccess(res, tables);
});

/**
 * GET /api/v1/bookings
 * Get authenticated user's bookings
 */
exports.getMyBookings = asyncHandler(async (req, res) => {
    const userId = req.user.id || req.user._id;
    const bookings = await bookingService.getBookings(userId);
    sendSuccess(res, bookings);
});

/**
 * PUT /api/v1/bookings/cancel/:bookingId
 */
exports.cancelBooking = asyncHandler(async (req, res) => {
    const booking = await bookingService.cancelBooking(req.params.bookingId, req.user._id);
    socket.emitBookingStatusUpdated(booking);
    sendSuccess(res, booking, 'Booking cancelled');
});

/**
 * GET /api/v1/admin/bookings  (Admin)
 */
exports.getAllBookings = asyncHandler(async (req, res) => {
    const bookings = await bookingService.adminGetAll();
    sendSuccess(res, bookings);
});

/**
 * PUT /api/v1/admin/bookings/:bookingId/status  (Admin)
 * Body: { status }
 */
exports.updateBookingStatus = asyncHandler(async (req, res) => {
    const booking = await bookingService.adminUpdateStatus(req.params.bookingId, req.body.status);
    sendSuccess(res, booking, `Booking status updated to ${req.body.status}`);
});
