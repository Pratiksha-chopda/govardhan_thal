const Notification = require('../models/Notification');
// Avoid global requires of ../socket due to circular dependency; require it dynamically instead.

exports.createAdminNotification = async ({ title, message, type, orderId, bookingId, userId }) => {
    try {
        const notification = await Notification.create({
            title,
            message,
            type,
            isAdmin: true,
            orderId,
            bookingId,
            userId,
        });

        const io = require('../socket').getIO();
        io.to('admin').emit('notification:new', { notification });
        return notification;
    } catch (err) {
        console.error('Error creating admin notification:', err);
    }
};

exports.createUserNotification = async ({ title, message, type, userId, orderId, bookingId }) => {
    try {
        const notification = await Notification.create({
            title,
            message,
            type,
            isAdmin: false,
            userId,
            orderId,
            bookingId,
        });

        // Socket.IO real-time delivery
        const io = require('../socket').getIO();
        io.to(`user:${userId}`).emit('notification:new', { notification });

        // FCM push notification delivery (non-blocking)
        try {
            const fcmService = require('./fcmService');
            await fcmService.sendToUser(userId, title, message, {
                type: type || 'GENERAL',
                orderId: orderId ? orderId.toString() : '',
                bookingId: bookingId ? bookingId.toString() : '',
            });
        } catch (fcmErr) {
            // FCM failures are non-fatal — Socket.IO still delivers
            console.warn('FCM push failed (non-fatal):', fcmErr.message);
        }

        return notification;
    } catch (err) {
        console.error('Error creating user notification:', err);
    }
};

exports.getAdminNotifications = async (limit = 20) => {
    return Notification.find({ isAdmin: true })
        .sort({ createdAt: -1 })
        .limit(limit)
        .populate('userId', 'name')
        .lean();
};

exports.getUserNotifications = async (userId, limit = 20) => {
    return Notification.find({ userId, isAdmin: false })
        .sort({ createdAt: -1 })
        .limit(limit)
        .lean();
};

exports.markAsRead = async (notificationId) => {
    return Notification.findByIdAndUpdate(notificationId, { isRead: true }, { new: true });
};

exports.markAllAdminAsRead = async () => {
    return Notification.updateMany({ isAdmin: true }, { isRead: true });
};

exports.getAdminUnreadCount = async () => {
    return Notification.countDocuments({ isAdmin: true, isRead: false });
};
