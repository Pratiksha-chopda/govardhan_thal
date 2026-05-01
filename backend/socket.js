/**
 * Socket.IO Real-Time Event Hub
 * 
 * Manages WebSocket connections for real-time sync between
 * Admin Panel and Customer App.
 * 
 * Events emitted:
 *   menu:created, menu:updated, menu:deleted
 *   order:new, order:statusUpdated
 *   booking:new, booking:statusUpdated
 *   table:statusUpdated
 *   dining:sessionStarted, dining:sessionClosed, dining:orderNew, dining:orderStatusUpdated
 *   dashboard:refresh
 */
const { Server } = require('socket.io');
const notificationService = require('./services/notificationService');

let io = null;

/**
 * Initialize Socket.IO with the HTTP server
 */
const initSocket = (httpServer) => {
    io = new Server(httpServer, {
        cors: {
            origin: '*',
            methods: ['GET', 'POST', 'PUT', 'DELETE', 'PATCH'],
        },
        pingTimeout: 60000,
        pingInterval: 25000,
    });

    io.on('connection', (socket) => {
        console.log(`🔌 Socket connected: ${socket.id}`);

        // ── Room Management ──
        // Admin clients join 'admin' room
        socket.on('join:admin', () => {
            socket.join('admin');
            console.log(`🛡️  ADMIN JOINED: ${socket.id} is now in admin room`);
        });

        // Customer clients join their user-specific room
        socket.on('join:user', (userId) => {
            if (userId) {
                socket.join(`user:${userId}`);
                console.log(`👤 Socket ${socket.id} joined user:${userId} room`);
            }
        });

        socket.on('disconnect', (reason) => {
            console.log(`❌ Socket disconnected: ${socket.id} (${reason})`);
        });
    });

    console.log('⚡ Socket.IO initialized for real-time sync');
    return io;
};

/**
 * Get the Socket.IO instance
 */
const getIO = () => {
    if (!io) {
        throw new Error('Socket.IO not initialized. Call initSocket() first.');
    }
    return io;
};

// ═══════════════════════════════════════════════════════════════
// EVENT EMITTERS — Called from controllers/services
// ═══════════════════════════════════════════════════════════════

/**
 * Menu Events — Notify all connected clients
 */
const emitMenuCreated = (menuItem) => {
    if (!io) return;
    io.emit('menu:created', { item: menuItem });
    io.to('admin').emit('dashboard:refresh');
};

const emitMenuUpdated = (menuItem) => {
    if (!io) return;
    io.emit('menu:updated', { item: menuItem });
};

const emitMenuDeleted = (menuId) => {
    if (!io) return;
    io.emit('menu:deleted', { menuId });
    io.to('admin').emit('dashboard:refresh');
};

/**
 * Order Events
 */
const emitOrderNew = (order) => {
    if (!io) return;
    
    // Notify admin
    console.log(`📣 EMITTING order:new to admin room for order ${order._id}`);
    io.to('admin').emit('order:new', { order });
    io.to('admin').emit('dashboard:refresh');
    // Notify the specific user
    if (order.userId) {
        const userId = order.userId._id || order.userId;
        io.to(`user:${userId}`).emit('order:new', { order });
    }
};

const emitOrderStatusUpdated = (order) => {
    if (!io) return;
    
    // Generate the friendly tracking message for the user
    let message = `Order #${order.orderNumber || order._id} status updated to ${order.orderStatus}`;
    if (order.tableId && order.tableId.tableNumber) {
        message = `Table #${order.tableId.tableNumber} - Order #${order.orderNumber || order._id} is now ${order.orderStatus}!`;
    }

    if (order.userId) {
        const userId = order.userId._id || order.userId;
        notificationService.createUserNotification({
            title: 'Order Update',
            message,
            type: 'ORDER_STATUS_UPDATE',
            userId,
            orderId: order._id,
        });
    }

    // Notify admin
    io.to('admin').emit('order:statusUpdated', { order, message });
    io.to('admin').emit('dashboard:refresh');
    // Notify the specific user
    if (order.userId) {
        const userId = order.userId._id || order.userId;
        io.to(`user:${userId}`).emit('order:statusUpdated', { order, message });
    }
};

const emitPaymentUpdate = (order) => {
    if (!io) return;
    io.to('admin').emit('order:paymentUpdate', { order });
    io.to('admin').emit('dashboard:refresh');
    if (order.userId) {
        const userId = order.userId._id || order.userId;
        io.to(`user:${userId}`).emit('order:paymentUpdate', { order });
    }
};

/**
 * Booking Events
 */
const emitBookingNew = (booking) => {
    if (!io) return;

    console.log(`📣 EMITTING booking:new to admin room for booking ${booking._id}`);
    io.to('admin').emit('booking:new', { booking });
    io.to('admin').emit('dashboard:refresh');
    if (booking.userId) {
        const userId = booking.userId._id || booking.userId;
        io.to(`user:${userId}`).emit('booking:new', { booking });
    }
};

const emitBookingStatusUpdated = (booking) => {
    if (!io) return;

    if (booking.userId) {
        const userId = booking.userId._id || booking.userId;
        notificationService.createUserNotification({
            title: 'Booking Update',
            message: `Your booking for table is now ${booking.bookingStatus}.`,
            type: 'BOOKING_APPROVED',
            userId,
            bookingId: booking._id,
        });
    }

    // Notify admin
    console.log(`📣 EMITTING booking:statusUpdated [${booking.status}] for ${booking._id}`);
    io.to('admin').emit('booking:statusUpdated', { booking });
    io.to('admin').emit('dashboard:refresh');
    if (booking.userId) {
        const userId = booking.userId._id || booking.userId;
        io.to(`user:${userId}`).emit('booking:statusUpdated', { booking });
    }
};

/**
 * Table Events
 */
const emitTableStatusUpdated = (table) => {
    if (!io) return;
    io.emit('table:statusUpdated', { table });
    io.to('admin').emit('dashboard:refresh');
};

/**
 * Dining Events
 */
const emitDiningSessionStarted = (session) => {
    if (!io) return;
    io.to('admin').emit('dining:sessionStarted', { session });
    io.to('admin').emit('dashboard:refresh');
};

const emitDiningSessionClosed = (session) => {
    if (!io) return;
    io.to('admin').emit('dining:sessionClosed', { session });
    io.to('admin').emit('dashboard:refresh');
    if (session.userId) {
        const userId = session.userId._id || session.userId;
        io.to(`user:${userId}`).emit('dining:sessionClosed', { session });
    }
};

const emitDiningOrderNew = (order) => {
    if (!io) return;

    notificationService.createAdminNotification({
        title: 'New Dining Order',
        message: `Table dining order #${order.orderNumber || order._id} placed.`,
        type: 'NEW_DINING_ORDER',
        orderId: order._id,
        userId: order.userId?._id || order.userId,
    });

    io.to('admin').emit('dining:orderNew', { order });
    io.to('admin').emit('dashboard:refresh');
};

const emitDiningOrderStatusUpdated = (order) => {
    if (!io) return;
    
    let message = `Dining Order #${order.orderNumber || order._id} status updated to ${order.orderStatus}`;
    if (order.tableId && order.tableId.tableNumber) {
        message = `Table #${order.tableId.tableNumber} - Order #${order.orderNumber || order._id} is now ${order.orderStatus}!`;
    }

    if (order.userId) {
        const userId = order.userId._id || order.userId;
        notificationService.createUserNotification({
            title: 'Dining Order Update',
            message,
            type: 'ORDER_STATUS_UPDATE',
            userId,
            orderId: order._id,
        });
    }

    io.to('admin').emit('dining:orderStatusUpdated', { order, message });
    if (order.userId) {
        const userId = order.userId._id || order.userId;
        io.to(`user:${userId}`).emit('dining:orderStatusUpdated', { order, message });
    }
};

const emitDiningPaymentUpdate = (result) => {
    if (!io) return;
    io.to('admin').emit('dining:paymentUpdate', result);
    io.to('admin').emit('dashboard:refresh');
};

module.exports = {
    initSocket,
    getIO,
    // Menu
    emitMenuCreated,
    emitMenuUpdated,
    emitMenuDeleted,
    // Orders
    emitOrderNew,
    emitOrderStatusUpdated,
    // Bookings
    emitBookingNew,
    emitBookingStatusUpdated,
    // Tables
    emitTableStatusUpdated,
    // Dining
    emitDiningSessionStarted,
    emitDiningSessionClosed,
    emitDiningOrderNew,
    emitDiningOrderStatusUpdated,
    emitDiningPaymentUpdate,
    emitPaymentUpdate,
};
