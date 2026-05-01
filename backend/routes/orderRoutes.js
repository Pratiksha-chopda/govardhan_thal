const express = require('express');
const router = express.Router();
const orderController = require('../controllers/orderController');
const { authMiddleware } = require('../middleware/authMiddleware');
const validate = require('../middleware/validateRequest');

// All order routes require authentication
router.use(authMiddleware);

// GET calculate delivery fee (S3)
router.get('/calculate/delivery-fee', orderController.getDeliveryFeePrediction);

// POST place new order
router.post('/', validate.placeOrder, orderController.placeOrder);

// POST update payment status (S2 Fix)
router.post('/update-payment', orderController.updatePayment);

// GET user's orders with optional ?status=&page=&limit=
router.get('/', orderController.getUserOrders);

// ==========================================
// ADMIN ROUTES
// ==========================================
const { adminMiddleware } = require('../middleware/authMiddleware');

// GET all orders (Admin)
router.get('/admin/all', adminMiddleware, orderController.getAdminOrders);

// PUT update order status (Admin)
router.put('/:orderId/status', adminMiddleware, orderController.updateOrderStatus);

// GET single order detail
router.get('/:orderId', orderController.getOrderDetail);

module.exports = router;
