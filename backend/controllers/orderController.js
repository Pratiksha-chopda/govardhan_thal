/**
 * Order Controller — Handles order endpoints.
 * Gets userId from JWT token (req.user.id).
 */
const orderService = require('../services/orderService');
const asyncHandler = require('../utils/asyncHandler');
const { sendSuccess, sendPaginated, sendError } = require('../utils/responseHelper');
const deliveryService = require('../services/deliveryService');
const Address = require('../models/Address');
const socket = require('../socket');

/**
 * POST /api/v1/orders
 * Body: { items: [{menuId, quantity, price}], orderType, tableId, paymentMethod }
 */
exports.placeOrder = asyncHandler(async (req, res) => {
    const { items, orderType, tableId, paymentMethod, paymentStatus, transactionId, deliveryAddress, addressId, deliveryFee, discountAmount, couponCode, gst } = req.body;
    const order = await orderService.placeOrder(req.user.id, { items, orderType, tableId, paymentMethod, paymentStatus, transactionId, deliveryAddress, addressId, deliveryFee, discountAmount, couponCode, gst });

    // Real-time: notify admin of new order
    socket.emitOrderNew(order);

    sendSuccess(res, { order_id: order._id, totalAmount: order.totalAmount, paymentStatus: order.paymentStatus, deliveryFee: order.deliveryFee }, 'Order placed successfully', 201);
});

/**
 * GET /api/v1/orders/calculate/delivery-fee?addressId=...&subtotal=...
 */
exports.getDeliveryFeePrediction = asyncHandler(async (req, res) => {
    const { addressId, subtotal } = req.query;
    
    if (!addressId) {
        return sendError(res, 'Address selection mandatory for delivery fee', 400);
    }

    const addr = await Address.findById(addressId);
    if (!addr) {
        return sendError(res, 'Address not found', 404);
    }

    const REST_LAT = parseFloat(process.env.RESTAURANT_LAT) || 23.0225;
    const REST_LNG = parseFloat(process.env.RESTAURANT_LNG) || 72.5714;

    const fee = deliveryService.getDeliveryFee(addr.latitude, addr.longitude, parseFloat(subtotal) || 0);
    const distanceVal = deliveryService.calculateDistance(REST_LAT, REST_LNG, addr.latitude, addr.longitude);
    
    sendSuccess(res, { 
        deliveryFee: fee, 
        isFree: fee === 0,
        distance: distanceVal.toFixed(1)
    });
});

/**
 * GET /api/v1/orders
 * Query: ?status=&page=&limit=
 */
exports.getUserOrders = asyncHandler(async (req, res) => {
    const { status, page, limit } = req.query;
    const result = await orderService.getOrders(req.user.id, { status, page, limit });

    sendPaginated(res, result.orders, result.page, result.limit, result.total);
});

/**
 * GET /api/v1/orders/:orderId
 */
exports.getOrderDetail = asyncHandler(async (req, res) => {
    const order = await orderService.getOrderDetail(req.params.orderId, req.user.id);
    sendSuccess(res, order);
});

exports.updateOrderStatus = asyncHandler(async (req, res) => {
    const { status, note } = req.body;
    const order = await orderService.updateStatus(req.params.orderId, status, note);
    sendSuccess(res, order, `Order status updated to ${status}`);
});

/**
 * POST /api/v1/orders/update-payment
 * Body: { orderId, paymentStatus, paymentMethod, transactionId }
 */
exports.updatePayment = asyncHandler(async (req, res) => {
    const { orderId, paymentStatus, paymentMethod, transactionId } = req.body;
    const order = await orderService.updatePaymentStatus(orderId, { paymentStatus, paymentMethod, transactionId });
    
    // Real-time: notify admin of payment sync
    socket.emitPaymentUpdate(order);

    sendSuccess(res, order, 'Payment status updated successfully');
});

/**
 * GET /api/v1/orders/admin/all (Admin)
 * Query: ?status=&page=&limit=
 */
exports.getAdminOrders = asyncHandler(async (req, res) => {
    const { status, page, limit } = req.query;
    const result = await orderService.getAdminOrders({ status, page, limit });
    sendPaginated(res, result.orders, result.page, result.limit, result.total);
});
