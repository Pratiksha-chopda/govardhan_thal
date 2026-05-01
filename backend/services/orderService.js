/**
 * Order Service — Business logic for order lifecycle.
 * Handles placing, listing, status updates with timeline tracking.
 */
const Order = require('../models/Order');
const Cart = require('../models/Cart');
const Menu = require('../models/Menu');
const notificationService = require('./notificationService');
const deliveryService = require('./deliveryService');

/**
 * Place a new order from cart items
 */
const placeOrder = async (userId, { items, orderType = 'ONLINE', tableId = null, paymentMethod = 'UPI', paymentStatus = 'PENDING', transactionId = null, deliveryAddress = null, addressId = null, discountAmount = 0, couponCode = null, deliveryFee = 0, gst = 0 }) => {
    // SECTION 9: Backend must validate
    if (!items || items.length === 0) {
        throw Object.assign(new Error('No items in order'), { statusCode: 400 });
    }

    // SECTION 1: Clean separation
    const type = orderType.toUpperCase();

    // Calculate total from items (server-side validation)
    let calculatedGst = 0;
    let subtotal = 0;
    let orderItems = [];
    for (const item of items) {
        const menuItem = await Menu.findById(item.menuId).lean();
        if (!menuItem || menuItem.isDeleted) {
            throw Object.assign(new Error(`Menu item ${item.menuId} not found`), { statusCode: 400 });
        }
        const itemSubtotal = menuItem.price * item.quantity;
        subtotal += itemSubtotal;
        calculatedGst += (itemSubtotal * (menuItem.gstRate || 5)) / 100;

        orderItems.push({
            menuId: item.menuId,
            name: menuItem.name,        // Denormalize name for fast reads
            quantity: item.quantity,
            price: menuItem.price,       // Use server price, not client price
        });
    }
    const finalGst = Math.round(calculatedGst);

    // SECTION 16: Address logic
    if (type === 'ONLINE' && !addressId && !deliveryAddress) {
        throw Object.assign(new Error('Address mandatory for Online orders'), { statusCode: 400 });
    }
    if (type === 'TAKEAWAY' || type === 'DINING') {
        deliveryFee = 0; // SECTION 5: No delivery fee for Takeaway/Dining
    } else if (type === 'ONLINE') {
        // Automatically calculate based on distance if address data is available
        const AddressModel = require('../models/Address');
        let destLat = deliveryAddress?.latitude;
        let destLng = deliveryAddress?.longitude;

        if (addressId && (!destLat || !destLng)) {
            const addr = await AddressModel.findById(addressId);
            if (addr) {
                destLat = addr.latitude;
                destLng = addr.longitude;
            }
        }

        if (destLat && destLng) {
            deliveryFee = deliveryService.getDeliveryFee(destLat, destLng, subtotal);
        }
    }

    // SECTION 6: Discount <= subtotal
    const finalDiscount = Math.min(discountAmount, subtotal);

    // Final total calculation: (subtotal - discount) + delivery + gst
    let totalAmount = (subtotal - finalDiscount) + deliveryFee + finalGst;
    if (totalAmount < 0) totalAmount = 0;

    // SECTION 8: Payment logic
    let finalPaymentStatus = paymentStatus;
    if (paymentMethod === 'CASH') {
        finalPaymentStatus = 'PENDING';
    } else if (['UPI', 'CARD', 'ONLINE'].includes(paymentMethod)) {
        finalPaymentStatus = 'PAID';
    }

    // Populate delivery address if addressId is provided 
    let finalDeliveryAddress = type === 'ONLINE' ? deliveryAddress : null;
    const AddressModel = require('../models/Address');
    if (type === 'ONLINE' && addressId && !finalDeliveryAddress) {
        const addr = await AddressModel.findById(addressId);
        if (addr) {
            finalDeliveryAddress = {
                label: addr.label,
                addressLine: addr.addressLine,
                city: addr.city,
                state: addr.state,
                pincode: addr.pincode,
                area: addr.area,
                latitude: addr.latitude,
                longitude: addr.longitude
            };
        }
    }

    // SECTION 2/9: Validate Dining Session
    if (type === 'DINING') {
        const DiningSession = require('../models/DiningSession');
        const session = await DiningSession.findOne({ userId, tableId, status: 'ACTIVE' });
        if (!session) {
            throw Object.assign(new Error('No active dining session found for this table'), { statusCode: 400 });
        }
    }

    const order = await Order.create({
        userId,
        items: orderItems,
        subtotal,
        discountAmount: finalDiscount,
        couponCode,
        deliveryFee,
        gst: finalGst,
        totalAmount,
        order_type: type,
        tableId,
        paymentMethod,
        paymentStatus: finalPaymentStatus,
        transactionId,
        deliveryAddress: finalDeliveryAddress,
        addressId,
        status: 'PLACED',
        timeline: [{ 
            status: 'PLACED', 
            timestamp: new Date(), 
            note: `Order placed via ${type} using ${paymentMethod}` 
        }],
    });

    // DINING SESSION UPDATE
    if (type === 'DINING') {
        const DiningSession = require('../models/DiningSession');
        await DiningSession.findOneAndUpdate(
            { userId, tableId, status: 'ACTIVE' },
            { 
                $push: { orders: order._id },
                $inc: { totalBill: totalAmount }
            }
        );
    }

    // Clear the user's cart after placing order
    await Cart.findOneAndUpdate({ userId }, { items: [] });
    
    // Notify admin about new order
    await notificationService.createAdminNotification({
        title: 'New Order Received',
        message: `New ${type} order for ₹${totalAmount}`,
        type: 'ORDER',
        orderId: order._id,
        userId,
    });

    return order;
};

/**
 * Get orders for a user with optional status filter and pagination
 */
const getOrders = async (userId, { status: filterStatus, page = 1, limit = 10 } = {}) => {
    const query = { userId };
    if (filterStatus) query.status = filterStatus;

    const skip = (Number(page) - 1) * Number(limit);
    const total = await Order.countDocuments(query);
    const orders = await Order.find(query)
        .sort({ createdAt: -1 })
        .skip(skip)
        .limit(Number(limit))
        .populate('items.menuId', 'name imageUrl')
        .populate('tableId', 'tableNumber')
        .lean();

    return { orders, total, page: Number(page), limit: Number(limit) };
};

/**
 * Get single order detail
 */
const getOrderDetail = async (orderId, userId = null) => {
    const query = { _id: orderId };
    if (userId) query.userId = userId;

    const order = await Order.findOne(query)
        .populate('items.menuId', 'name imageUrl category')
        .populate('userId', 'name email mobile')
        .lean();

    if (!order) throw Object.assign(new Error('Order not found'), { statusCode: 404 });
    return order;
};

/**
 * Update order status (Admin) with timeline tracking
 */
const updateStatus = async (orderId, status, note, paymentStatus) => {
    const { ORDER_STATUS, ORDER_TYPES, getAllowedStatuses } = require('../utils/orderStatusConstants');
    const order = await Order.findById(orderId).populate('userId', 'name mobile email fcmToken');
    if (!order) throw Object.assign(new Error('Order not found'), { statusCode: 404 });

    const currentStatus = order.status;
    const type = order.order_type || ORDER_TYPES.ONLINE;

    // Phase 10 — Status transition validator
    if (status && status !== currentStatus) {
        const allowed = getAllowedStatuses(type, currentStatus);
        if (!allowed.includes(status) && status !== ORDER_STATUS.CANCELLED) {
            throw Object.assign(new Error(`Invalid status transition from ${currentStatus} to ${status} for ${type}`), { statusCode: 400 });
        }
    }

    if (status) {
        // Timeline message generator based on order type
        let timelineNote = note || `Order moved to ${status}`;
        
        if (type === 'DINING') {
            if (status === ORDER_STATUS.CONFIRMED) timelineNote = "Kitchen Confirmed";
            else if (status === ORDER_STATUS.PREPARING) timelineNote = "Preparing Food";
            else if (status === ORDER_STATUS.READY) timelineNote = "Food Ready";
            else if (status === ORDER_STATUS.SERVED) timelineNote = "Served to Table";
            else if (status === ORDER_STATUS.COMPLETED) timelineNote = "Billing Completed";
        }

        order.status = status;
        order.timeline.push({ status, timestamp: new Date(), note: timelineNote });
    }

    if (paymentStatus) {
        order.paymentStatus = paymentStatus;
        order.timeline.push({ status: order.status, timestamp: new Date(), note: `Payment status updated to ${paymentStatus}` });
    }

    // SECTION 11: Mark PAID on finalization
    if (status === ORDER_STATUS.COMPLETED || status === ORDER_STATUS.DELIVERED || status === ORDER_STATUS.SERVED) {
        if (order.paymentStatus !== 'PAID' && order.paymentStatus !== 'SUCCESS') {
            order.paymentStatus = 'PAID';
        }
    }
    if (status === ORDER_STATUS.CANCELLED) {
        order.paymentStatus = 'REFUNDED';
    }

    await order.save();
    
    // ── Inventory Deduction Logic ──────────────────────────────────────────
    if (status === ORDER_STATUS.COMPLETED || status === ORDER_STATUS.DELIVERED || status === ORDER_STATUS.SERVED) {
        try {
            const Ingredient = require('../models/Ingredient');
            for (const item of order.items) {
                const menuItem = await Menu.findById(item.menuId).lean();
                if (menuItem && menuItem.recipe && menuItem.recipe.length > 0) {
                    for (const recipeItem of menuItem.recipe) {
                        const deduction = recipeItem.quantity * item.quantity;
                        await Ingredient.findByIdAndUpdate(recipeItem.ingredientId, {
                            $inc: { stock: -deduction }
                        });
                    }
                }
            }
        } catch (invErr) {
            console.error("Inventory deduction failed:", invErr.message);
            // We don't throw here to ensure order status update still succeeds
        }
    }

    await order.populate('tableId', 'tableNumber');

    // Notify user about order status change (Phase 6: Timeline messages)
    let title = 'Order Update';
    let message = `Your ${type} order #${order.orderNumber || orderId.toString().slice(-6).toUpperCase()} is now ${status}.`;

    if (status === 'CONFIRMED') {
        title = type === 'DINING' ? 'Kitchen Confirmed! 👨‍🍳' : 'Confirmed! ✅';
        message = type === 'DINING' ? 'The kitchen has received your ticket.' : 'The kitchen has confirmed your order.';
    } else if (status === 'PREPARING') {
        title = 'Chef is Cooking 👨‍🍳';
        message = 'Your meal is being prepared with care.';
    } else if (status === 'READY') {
        title = 'Order Ready! 🍱';
        message = type === 'TAKEAWAY' ? 'Your takeaway order is ready for pickup.' : 'Your food is ready to serve!';
    } else if (status === 'SERVED') {
        title = 'Enjoy Your Meal! 🍽️';
        message = 'Your food has more been served. Enjoy it hot!';
    } else if (status === 'OUT_FOR_DELIVERY') {
        title = 'Out for Delivery! 🛵';
        message = 'Our rider is on the way with your food.';
    } else if (status === 'DELIVERED') {
        title = 'Order Delivered! 🥡';
        message = 'Enjoy your delicious meal!';
    } else if (status === 'COMPLETED') {
        title = 'Session Completed! ✨';
        message = 'Thank you for dining with Govardhan Thal!';
    }

    await notificationService.createUserNotification({
        title,
        message,
        type: 'ORDER',
        userId: order.userId,
        orderId: order._id,
    });

    return order;
};

/**
 * Update payment status
 */
const updatePaymentStatus = async (orderId, { paymentStatus, paymentMethod, transactionId }) => {
    const order = await Order.findById(orderId);
    if (!order) throw Object.assign(new Error('Order not found'), { statusCode: 404 });

    order.paymentStatus = paymentStatus;
    if (paymentMethod) order.paymentMethod = paymentMethod;
    if (transactionId) order.transactionId = transactionId;

    await order.save();
    return order;
};

/**
 * Get all orders (Admin) with pagination
 */
const getAdminOrders = async ({ status: filterStatus, order_type, page = 1, limit = 20 } = {}) => {
    const query = {};
    if (filterStatus) query.status = filterStatus;
    if (order_type) query.order_type = order_type;

    const skip = (Number(page) - 1) * Number(limit);
    const total = await Order.countDocuments(query);
    const orders = await Order.find(query)
        .sort({ createdAt: -1 })
        .skip(skip)
        .limit(Number(limit))
        .populate('userId', 'name email mobile')
        .populate('items.menuId', 'name imageUrl')
        .populate('tableId', 'tableNumber status')
        .lean();

    return { orders, total, page: Number(page), limit: Number(limit) };
};

const getDashboardStats = async (filter = 'TODAY') => {
    const today = new Date();
    today.setHours(0, 0, 0, 0);

    let startDate = new Date(today);
    if (filter === 'WEEK') startDate.setDate(today.getDate() - 7);
    else if (filter === 'MONTH') startDate.setDate(today.getDate() - 30);
    else if (filter === 'ALL') startDate = new Date(0); // Epoch

    const [totalOrdersToday, revenueStats, onlineOrders, diningOrders, takeawayOrders, activeTables, pendingBookings, pendingPayments, newUsersToday, totalUsers, pendingDeliveries] = await Promise.all([
        Order.countDocuments({ createdAt: { $gte: startDate } }),
        Order.aggregate([
            { $match: { createdAt: { $gte: startDate }, paymentStatus: { $in: ['PAID', 'SUCCESS'] } } },
            { $group: { _id: '$order_type', total: { $sum: '$totalAmount' } } }
        ]),
        Order.countDocuments({ createdAt: { $gte: startDate }, order_type: 'ONLINE' }),
        Order.countDocuments({ createdAt: { $gte: startDate }, order_type: 'DINING' }),
        Order.countDocuments({ createdAt: { $gte: startDate }, order_type: 'TAKEAWAY' }),
        require('../models/Table').countDocuments({ status: 'OCCUPIED' }),
        require('../models/Booking').countDocuments({ date: { $gte: today }, status: 'PENDING' }),
        Order.countDocuments({ paymentStatus: 'PENDING', status: { $ne: 'CANCELLED' } }), // Pending payments
        require('../models/User').countDocuments({ createdAt: { $gte: today } }),
        require('../models/User').countDocuments(),
        Order.countDocuments({ 
            order_type: 'ONLINE', 
            status: { $in: ['PLACED', 'CONFIRMED', 'PREPARING', 'OUT_FOR_DELIVERY'] } 
        }),
    ]);

    const revOnline = revenueStats.find(r => r._id === 'ONLINE')?.total || 0;
    const revDining = revenueStats.find(r => r._id === 'DINING')?.total || 0;
    const revTakeaway = revenueStats.find(r => r._id === 'TAKEAWAY')?.total || 0;

    const sevenDaysAgo = new Date(today);
    sevenDaysAgo.setDate(today.getDate() - 6);
    sevenDaysAgo.setHours(0, 0, 0, 0);

    const history = await Order.aggregate([
        { $match: { createdAt: { $gte: sevenDaysAgo }, paymentStatus: { $in: ['PAID', 'SUCCESS'] } } },
        { 
            $group: { 
                _id: { $dateToString: { format: "%Y-%m-%d", date: "$createdAt", timezone: "+05:30" } }, 
                revenue: { $sum: "$totalAmount" } 
            } 
        },
        { $sort: { _id: 1 } }
    ]);

    const days = ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'];
    const revenueHistory = [];
    for (let i = 0; i < 7; i++) {
        const d = new Date(sevenDaysAgo);
        d.setDate(sevenDaysAgo.getDate() + i);
        // Explicit calculation instead of toISOString to respect the local date
        const dateStr = `${d.getFullYear()}-${String(d.getMonth() + 1).padStart(2, '0')}-${String(d.getDate()).padStart(2, '0')}`;
        const dayData = history.find(h => h._id === dateStr);
        revenueHistory.push({ name: days[d.getDay()], revenue: dayData ? dayData.revenue : 0 });
    }

    return {
        filter,
        totalOrders: totalOrdersToday,
        onlineOrders,
        diningOrders,
        takeawayOrders,
        revenueToday: revOnline + revDining + revTakeaway, // This is filtered revenue based on range
        revOnline,
        revDining,
        revTakeaway,
        activeTables,
        pendingBookings,
        pendingPayments,
        pendingDeliveries,
        newUsersToday,
        totalUsers,
        revenueHistory
    };
};

const getReports = async (filter = 'ALL') => {
    const today = new Date();
    today.setHours(0, 0, 0, 0);

    let startDate = new Date(0); // Default to ALL
    if (filter === 'TODAY') startDate = new Date(today);
    else if (filter === 'WEEK') startDate.setDate(today.getDate() - 7);
    else if (filter === 'MONTH') startDate.setDate(today.getDate() - 30);

        Order.calculateDetailedReports = async () => {}; // Placeholder for structure 

    const [total, paid, pending, revenueByType, paymentMethods, couponUsage, topItems, categorySales] = await Promise.all([
        Order.countDocuments({ createdAt: { $gte: startDate } }),
        Order.countDocuments({ createdAt: { $gte: startDate }, paymentStatus: { $in: ['PAID', 'SUCCESS'] } }),
        Order.countDocuments({ createdAt: { $gte: startDate }, paymentStatus: 'PENDING' }),
        Order.aggregate([
            { $match: { createdAt: { $gte: startDate }, paymentStatus: { $in: ['PAID', 'SUCCESS'] } } },
            { $group: { _id: '$order_type', count: { $sum: 1 }, total: { $sum: '$totalAmount' } } }
        ]),
        Order.aggregate([
            { $match: { createdAt: { $gte: startDate } } },
            { $group: { _id: '$paymentMethod', count: { $sum: 1 } } }
        ]),
        Order.countDocuments({ couponCode: { $ne: null } }),
        Order.aggregate([
            { $unwind: '$items' },
            { $group: { _id: '$items.menuId', name: { $first: '$items.name' }, count: { $sum: '$items.quantity' } } },
            { $sort: { count: -1 } },
            { $limit: 10 }
        ]),
        // Sales breakdown by category
        Order.aggregate([
            { $match: { status: 'COMPLETED' } },
            { $unwind: '$items' },
            {
                $lookup: {
                    from: 'menus',
                    localField: 'items.menuId',
                    foreignField: '_id',
                    as: 'menuInfo'
                }
            },
            { $unwind: '$menuInfo' },
            {
                $group: {
                    _id: '$menuInfo.category',
                    quantity: { $sum: '$items.quantity' },
                    revenue: { $sum: { $multiply: ['$items.price', '$items.quantity'] } }
                }
            },
            { $sort: { quantity: -1 } }
        ])
    ]);

    return {
        totalOrders: total,
        paidOrders: paid,
        pendingOrders: pending,
        totalRevenue: revenueByType.reduce((sum, r) => sum + r.total, 0),
        revenueByType,
        paymentMethods,
        couponUsage,
        topItems,
        categorySales
    };
};

module.exports = { 
    placeOrder, 
    getOrders, 
    getOrderDetail, 
    updateStatus, 
    updatePaymentStatus, 
    getAdminOrders,
    getDashboardStats,
    getReports
};
