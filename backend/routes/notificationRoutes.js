const express = require('express');
const router = express.Router();
const notificationController = require('../controllers/notificationController');
const { authMiddleware, adminMiddleware } = require('../middleware/authMiddleware');

// Get generic user notifications
router.route('/user').get(authMiddleware, notificationController.getUserNotifications);

// Get admin notifications
router.route('/admin').get(authMiddleware, adminMiddleware, notificationController.getAdminNotifications);
router.route('/admin/unread-count').get(authMiddleware, adminMiddleware, notificationController.getAdminUnreadCount);
router.route('/admin/read-all').put(authMiddleware, adminMiddleware, notificationController.markAllAdminAsRead);

// Mark read by ID
router.route('/:id/read').put(authMiddleware, notificationController.markAsRead);

module.exports = router;
