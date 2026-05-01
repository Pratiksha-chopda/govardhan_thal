/**
 * Booking Service — Business logic for table reservations.
 * Handles conflict detection, auto table assignment, and booking management.
 */
const Booking = require('../models/Booking');
const Table = require('../models/Table');
const notificationService = require('./notificationService');

/**
 * Create a new booking with automatic table assignment.
 * Prevents double-booking by checking existing bookings for the same date/slot.
 */
const createBooking = async (userId, { date, timeSlot, guestCount, occasion, specialRequest }) => {
    // Find tables that are already booked for this date & time slot
    const conflictingBookings = await Booking.find({
        bookingDate: date,
        timeSlot,
        status: { $in: ['PENDING', 'APPROVED'] },
    });
    const bookedTableIds = conflictingBookings.map((b) => b.tableId?.toString()).filter(Boolean);

    // Find an available table with enough capacity
    const availableTable = await Table.findOne({
        _id: { $nin: bookedTableIds },
        capacity: { $gte: Number(guestCount) },
        status: { $in: ['AVAILABLE', 'RESERVED'] },  // Not currently OCCUPIED
    }).sort({ capacity: 1 }); // Pick smallest fitting table

    if (!availableTable) {
        throw Object.assign(
            new Error('No tables available for the selected date, time, and guest count'),
            { statusCode: 409 }
        );
    }

    const booking = await Booking.create({
        userId,
        tableId: availableTable._id,
        bookingDate: date,
        timeSlot,
        guestCount,
        occasion,
        specialRequest,
        status: 'PENDING',
    });

    await notificationService.createAdminNotification({
        title: 'New Table Booking',
        message: `New booking request for ${guestCount} guests on ${date} at ${timeSlot}`,
        type: 'BOOKING',
        bookingId: booking._id,
        userId: userId,
    });

    return {
        booking_id: booking._id,
        tableNumber: availableTable.tableNumber,
        capacity: availableTable.capacity,
        date: booking.bookingDate,
        timeSlot: booking.timeSlot,
        guestCount: booking.guestCount,
        occasion: booking.occasion,
        specialRequest: booking.specialRequest,
        status: booking.status,
    };
};

/**
 * Check table availability for a date & time slot
 */
const checkAvailability = async ({ date, timeSlot, guests }) => {
    const conflictingBookings = await Booking.find({
        bookingDate: date,
        timeSlot,
        status: { $in: ['PENDING', 'APPROVED'] },
    });
    const bookedTableIds = conflictingBookings.map((b) => b.tableId?.toString()).filter(Boolean);

    const availableTables = await Table.find({
        _id: { $nin: bookedTableIds },
        capacity: { $gte: Number(guests) },
    }).sort({ capacity: 1 }).lean();

    return availableTables;
};

/**
 * Get bookings for a specific user
 */
const getBookings = async (userId) => {
    return Booking.find({ userId })
        .populate('tableId', 'tableNumber capacity')
        .sort({ createdAt: -1 })
        .lean();
};

/**
 * Cancel a booking
 */
const cancelBooking = async (bookingId, userId) => {
    const booking = await Booking.findOne({ _id: bookingId, userId });
    if (!booking) throw Object.assign(new Error('Booking not found'), { statusCode: 404 });
    if (booking.status === 'CANCELLED') {
        throw Object.assign(new Error('Booking already cancelled'), { statusCode: 400 });
    }

    booking.status = 'CANCELLED';
    await booking.save();
    return booking;
};

/**
 * Get all bookings (Admin)
 */
const adminGetAll = async () => {
    return Booking.find()
        .populate('userId', 'name email mobile')
        .populate('tableId', 'tableNumber capacity')
        .sort({ createdAt: -1 })
        .lean();
};

/**
 * Update booking status (Admin)
 */
const adminUpdateStatus = async (bookingId, status) => {
    const booking = await Booking.findByIdAndUpdate(bookingId, { status }, { new: true });
    if (!booking) throw Object.assign(new Error('Booking not found'), { statusCode: 404 });

    // Notify user about the status change
    let title = 'Booking Update';
    let message = `Your booking for ${booking.bookingDate} at ${booking.timeSlot} has been ${status.toLowerCase()}.`;
    
    if (status === 'APPROVED') {
        title = 'Booking Confirmed! 🎉';
        message = 'Great news! Your table reservation has been approved. See you soon!';
    } else if (status === 'REJECTED') {
        title = 'Booking Unavailable';
        message = 'Sorry, we couldn\'t accommodate your booking at this time. Please try another slot.';
    }

    await notificationService.createUserNotification({
        title,
        message,
        type: 'BOOKING',
        userId: booking.userId,
        bookingId: booking._id,
    });

    return booking;
};

module.exports = { createBooking, checkAvailability, getBookings, cancelBooking, adminGetAll, adminUpdateStatus };
