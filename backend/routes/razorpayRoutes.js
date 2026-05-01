const express = require('express');
const router = express.Router();
const razorpayController = require('../controllers/razorpayController');
const { authMiddleware } = require('../middleware/authMiddleware');

// POST - Create a Razorpay order (requires auth)
router.post('/create-order', authMiddleware, razorpayController.createOrder);

// POST - Verify payment signature after customer pays (requires auth)
router.post('/verify-payment', authMiddleware, razorpayController.verifyPayment);

module.exports = router;

