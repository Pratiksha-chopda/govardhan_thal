const notificationService = require('../services/notificationService');
const asyncHandler = require('../utils/asyncHandler');
const { sendSuccess } = require('../utils/responseHelper');
const Notification = require('../models/Notification');

// ── GET /api/v1/admin/notifications
// GET /api/v1/notifications/admin (deprecated entry point)
// Stabilized: returns 200 even on error to prevent UI crash.
exports.getAdminNotifications = async (req, res) => {
    try {
        // Ensure Notification model is used correctly
        // Response format must be: { success: true, data: { notifications: [] } }
        const notifications = await Notification.find({})
            .sort({ createdAt: -1 })
            .limit(100)
            .lean();

        return res.status(200).json({
            success: true,
            data: {
                notifications: notifications || []
            }
        });
    } catch (error) {
        // Backend logging:
        console.error("Admin notifications fetch error:", error);

        // Fallback protection: If database failure return empty array instead of 500
        return res.status(200).json({
            success: true,
            data: {
                notifications: []
            }
        });
    }
};

// ── GET /api/v1/notifications/user
exports.getUserNotifications = asyncHandler(async (req, res) => {
    const notifications = await notificationService.getUserNotifications(req.user.id);
    sendSuccess(res, notifications);
});

const socket = require('../socket');

// ── PUT /api/v1/notifications/:id/read
exports.markAsRead = asyncHandler(async (req, res) => {
    const notification = await notificationService.markAsRead(req.params.id);
    socket.getIO().emit('notification:read');
    sendSuccess(res, notification, 'Notification marked as read');
});

// ── PUT /api/v1/notifications/admin/read-all
exports.markAllAdminAsRead = asyncHandler(async (req, res) => {
    const result = await notificationService.markAllAdminAsRead();
    socket.getIO().emit('notification:read');
    sendSuccess(res, result, 'All admin notifications marked as read');
});
// ── GET /api/v1/notifications/admin/unread-count
// Stabilized: returns 200 even on error to prevent UI crash.
exports.getAdminUnreadCount = async (req, res) => {
    try {
        // Direct query for safety
        const count = await Notification.countDocuments({ isAdmin: true, isRead: false });
        
        return res.status(200).json({
            success: true,
            count: count || 0
        });
    } catch (error) {
        // Backend logging:
        console.error("Admin notification count error:", error);

        // Fallback protection: If database fails return count:0 instead of 500
        return res.status(200).json({
            success: true,
            count: 0
        });
    }
};
