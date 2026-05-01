const express = require('express');
const router = express.Router();
const bookingController = require('../controllers/bookingController');
const { authMiddleware } = require('../middleware/authMiddleware');
const validate = require('../middleware/validateRequest');

// All booking routes require authentication
router.use(authMiddleware);

// POST create a booking (auto-assigns table)
router.post('/', validate.createBooking, bookingController.createBooking);

// GET check availability — ?date=&timeSlot=&guests=
router.get('/availability', bookingController.checkAvailability);

// GET user's bookings
router.get('/', bookingController.getMyBookings);

// PUT cancel a booking
router.put('/cancel/:bookingId', bookingController.cancelBooking);

module.exports = router;
