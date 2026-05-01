const express = require('express');
const router = express.Router();
const couponController = require('../controllers/couponController');
const { authMiddleware } = require('../middleware/authMiddleware');

router.use(authMiddleware);

// GET available coupons for user app
router.get('/available', couponController.getAvailableCoupons);

// POST validate coupon code
router.post('/validate', couponController.validateCoupon);

// POST create coupon (Admin - can be added to admin routes too)
router.post('/', couponController.createCoupon);

module.exports = router;
