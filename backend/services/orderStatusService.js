/**
 * Order Status Service — Phase 2
 * 
 * Isolated service for professional order status management.
 * Does NOT modify existing orderService.js or orderController.js.
 * 
 * Features:
 *   - Safe status updates with timeline tracking
 *   - Order cancellation with validation
 *   - Order tracking data retrieval
 *   - Estimated delivery time management
 */
const Order = require('../models/Order');
const socket = require('../socket');
const notificationService = require('./notificationService');
const { getAllowedStatuses } = require('../utils/orderStatusConstants');

// Valid status transitions (state machine)
const VALID_TRANSITIONS = {
    'PLACED':             ['CONFIRMED', 'CANCELLED'],
    'CONFIRMED':          ['PREPARING', 'CANCELLED'],
    'PREPARING':          ['READY', 'READY_FOR_PICKUP'],
    'READY':              ['OUT_FOR_DELIVERY', 'SERVED', 'COMPLETED'],
    'READY_FOR_PICKUP':   ['COMPLETED'],
    'OUT_FOR_DELIVERY':   ['DELIVERED'],
    'DELIVERED':          ['COMPLETED'],
    'SERVED':             ['WAITING_PAYMENT', 'COMPLETED'],
    'WAITING_PAYMENT':    ['COMPLETED'],
    'ORDERED':            ['CONFIRMED', 'PREPARING', 'CANCELLED'],
};

// Status messages for customer notifications
const STATUS_MESSAGES = {
    'CONFIRMED':          { title: 'Order Confirmed ✅', message: 'The restaurant has accepted your order.' },
    'PREPARING':          { title: 'Preparing Your Food 👨‍🍳', message: 'The chef is preparing your meal with care.' },
    'READY':              { title: 'Order Ready! 🍱', message: 'Your order is ready.' },
    'READY_FOR_PICKUP':   { title: 'Ready for Pickup! 🥡', message: 'Your food is packed and waiting at the counter.' },
    'OUT_FOR_DELIVERY':   { title: 'Out for Delivery 🛵', message: 'Our delivery partner is on the way!' },
    'DELIVERED':          { title: 'Delivered! 🎉', message: 'Enjoy your meal! We hope you love it.' },
    'COMPLETED':          { title: 'Order Completed 🌟', message: 'Thank you for choosing Govardhan Thal!' },
    'CANCELLED':          { title: 'Order Cancelled ❌', message: 'Your order has been cancelled.' },
};

/**
 * Update order status safely with timeline tracking.
 * Called from the new admin status route — does NOT replace existing updateStatus.
 */
const updateStatus = async (orderId, newStatus, note = '') => {
    try {
        const order = await Order.findById(orderId)
            .populate('userId', 'name mobile email')
            .populate('tableId', 'tableNumber');

        if (!order) {
            throw Object.assign(new Error('Order not found'), { statusCode: 404 });
        }

        const currentStatus = order.status;
        const orderType = order.order_type || 'ONLINE';

        // Validate transition
        let allowed = VALID_TRANSITIONS[currentStatus] || [];
        
        // PHASE 4: Separate status workflow for DINE_IN
        if (orderType === 'DINING' || orderType === 'DINE_IN') {
             const dtAllowed = getAllowedStatuses('DINING', currentStatus);
             // We only allow the immediate next status or CANCELLED
             allowed = dtAllowed.length > 0 ? [dtAllowed[0], 'CANCELLED'] : ['CANCELLED'];
             // Exception: COMPLETED is final, SERVED -> COMPLETED
             if (currentStatus === 'SERVED') allowed = ['COMPLETED', 'WAITING_PAYMENT']; 
        }

        if (!allowed.includes(newStatus)) {
            throw Object.assign(
                new Error(`Cannot move from "${currentStatus}" to "${newStatus}" for order type ${orderType}. Allowed: ${allowed.join(', ')}`),
                { statusCode: 400 }
            );
        }

        // Update status
        order.status = newStatus;

        // Push timeline entry
        order.timeline.push({
            status: newStatus,
            timestamp: new Date(),
            note: note || `Order moved to ${newStatus}`,
        });

        // Handle cancellation fields
        if (newStatus === 'CANCELLED') {
            order.isCancelled = true;
            order.cancelledAt = new Date();
            order.paymentStatus = order.paymentStatus === 'PAID' ? 'REFUNDED' : order.paymentStatus;
        }

        // Auto-set estimated delivery time on CONFIRMED
        if (newStatus === 'CONFIRMED' && !order.estimatedDeliveryTime) {
            order.estimatedDeliveryTime = order.order_type === 'ONLINE' ? 45 : 25;
        }

        // Mark payment as PAID on finalization
        if (['COMPLETED', 'DELIVERED', 'SERVED'].includes(newStatus)) {
            if (!['PAID', 'SUCCESS'].includes(order.paymentStatus)) {
                order.paymentStatus = 'PAID';
            }
        }

        await order.save();

        // Send real-time Socket.IO event
        try {
            socket.emitOrderStatusUpdated(order);
        } catch (socketErr) {
            console.error('Socket emit failed (non-fatal):', socketErr.message);
        }

        // Send notification to customer
        try {
            const msg = STATUS_MESSAGES[newStatus];
            if (msg && order.userId) {
                const userId = order.userId._id || order.userId;
                await notificationService.createUserNotification({
                    title: msg.title,
                    message: msg.message,
                    type: 'ORDER',
                    userId,
                    orderId: order._id,
                });
            }
        } catch (notifErr) {
            console.error('Notification failed (non-fatal):', notifErr.message);
        }

        return order;
    } catch (error) {
        throw error;
    }
};

/**
 * Cancel an order (customer-initiated).
 * Only allowed before PREPARING status.
 */
const cancelOrder = async (orderId, userId, reason = '') => {
    try {
        const order = await Order.findById(orderId)
            .populate('userId', 'name mobile email')
            .populate('tableId', 'tableNumber');

        if (!order) {
            throw Object.assign(new Error('Order not found'), { statusCode: 404 });
        }

        // Verify ownership
        const orderUserId = (order.userId._id || order.userId).toString();
        if (orderUserId !== userId.toString()) {
            throw Object.assign(new Error('Unauthorized: This is not your order'), { statusCode: 403 });
        }

        // Only allow cancellation before PREPARING
        const cancellableStatuses = ['PLACED', 'CONFIRMED', 'ORDERED'];
        if (!cancellableStatuses.includes(order.status)) {
            throw Object.assign(
                new Error(`Cannot cancel order in "${order.status}" status. Cancellation only allowed before food preparation begins.`),
                { statusCode: 400 }
            );
        }

        // Already cancelled check
        if (order.isCancelled) {
            throw Object.assign(new Error('Order is already cancelled'), { statusCode: 400 });
        }

        // Apply cancellation
        order.status = 'CANCELLED';
        order.isCancelled = true;
        order.cancellationReason = reason || 'Customer requested cancellation';
        order.cancelledAt = new Date();

        // Handle refund status
        if (['PAID', 'SUCCESS'].includes(order.paymentStatus)) {
            order.paymentStatus = 'REFUNDED';
        }

        // Push timeline entry
        order.timeline.push({
            status: 'CANCELLED',
            timestamp: new Date(),
            note: `Cancelled by customer: ${reason || 'No reason provided'}`,
        });

        await order.save();

        // Notify admin about cancellation
        try {
            socket.emitOrderStatusUpdated(order);
            await notificationService.createAdminNotification({
                title: 'Order Cancelled ❌',
                message: `Order #${orderId.toString().slice(-6).toUpperCase()} cancelled. Reason: ${reason || 'Not specified'}`,
                type: 'ORDER',
                orderId: order._id,
                userId,
            });
        } catch (err) {
            console.error('Cancel notification failed (non-fatal):', err.message);
        }

        return order;
    } catch (error) {
        throw error;
    }
};

/**
 * Get tracking data for an order.
 * Returns only tracking-relevant fields (lightweight response).
 */
const getTracking = async (orderId, userId = null) => {
    try {
        const query = { _id: orderId };
        if (userId) query.userId = userId;

        const order = await Order.findOne(query)
            .select('status timeline estimatedDeliveryTime isCancelled cancellationReason cancelledAt order_type createdAt deliveryAddress ratingExists')
            .populate('tableId', 'tableNumber')
            .lean();

        if (!order) {
            throw Object.assign(new Error('Order not found'), { statusCode: 404 });
        }

        return {
            orderId: order._id,
            orderStatus: order.status,
            orderType: order.order_type,
            statusTimeline: order.timeline || [],
            estimatedDeliveryTime: order.estimatedDeliveryTime,
            isCancelled: order.isCancelled || false,
            cancellationReason: order.cancellationReason,
            cancelledAt: order.cancelledAt,
            ratingExists: order.ratingExists || false,
            canCancel: ['PLACED', 'CONFIRMED', 'ORDERED'].includes(order.status) && !order.isCancelled,
            tableNumber: order.tableId?.tableNumber || null,
            placedAt: order.createdAt,
        };
    } catch (error) {
        throw error;
    }
};

module.exports = {
    updateStatus,
    cancelOrder,
    getTracking,
    VALID_TRANSITIONS,
    STATUS_MESSAGES,
};
