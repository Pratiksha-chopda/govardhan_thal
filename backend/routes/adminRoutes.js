const express = require('express');
const router = express.Router();
const adminController = require('../controllers/adminController');
const couponController = require('../controllers/couponController');
const notificationController = require('../controllers/notificationController');
const { authMiddleware, adminMiddleware } = require('../middleware/authMiddleware');
const validate = require('../middleware/validateRequest');
const upload = require('../middleware/upload');

// All admin routes require authentication + admin role
router.use(authMiddleware);
router.use(adminMiddleware);

// ── Dashboard ──
router.get('/dashboard', adminController.getDashboard);
router.get('/reports', adminController.getReports);

// ── Menu Management ──
router.post('/menu',                          upload.single('image'), ...validate.createMenu, adminController.createMenu);
router.put('/menu/:id',                       upload.single('image'), adminController.updateMenu);
router.delete('/menu/:id',                    adminController.deleteMenu);
router.post('/menu/:id/upload',               upload.single('image'), adminController.uploadMenuImage);

// Admin menu patch endpoints
router.patch('/menu/:id/image-url',           adminController.changeImageUrl);
router.patch('/menu/:id/image-keyword',       adminController.changeImageKeyword);
router.patch('/menu/:id/popular',             adminController.setPopular);
router.patch('/menu/:id/today-special',       adminController.setTodaySpecial);
router.patch('/menu/:id/recommended',         adminController.setRecommended);
router.patch('/menu/:id/available',           adminController.setAvailable);
router.patch('/menu/:id/category',            adminController.changeCategory);

// ── Order Management ──
router.get('/orders', adminController.getOrders);
router.put('/orders/:orderId/status', ...validate.updateOrderStatus, adminController.updateOrderStatus);

// ── Booking Management ──
router.get('/bookings', adminController.getBookings);
router.put('/bookings/:bookingId/status', adminController.updateBookingStatus);

// ── Table Management ──
router.get('/tables',                                    adminController.getTables);
router.post('/tables',                                   adminController.createTable);
router.put('/tables/:id',                                adminController.updateTable);
router.delete('/tables/:id',                             adminController.deleteTable);

// ── Dining Management ──
router.get('/active-tables',                             adminController.getActiveTables);
router.get('/dining-sessions',                           adminController.getDiningSessions);
router.get('/dining-orders',                             adminController.getDiningOrders);
router.put('/dining-orders/:orderId/status', ...validate.updateOrderStatus, adminController.updateDiningOrderStatus);
router.post('/dining/verify-payment',                    adminController.adminVerifyDiningPayment);
router.post('/dining/close-session',                     adminController.adminCloseSession);

// ── User Management ──
router.get('/users', adminController.getUsers);

// ── Coupon Management ──
router.get('/coupons', couponController.getAdminCoupons);
router.post('/coupons', couponController.createCoupon);
router.delete('/coupons/:id', couponController.deleteCoupon);

// ── Administrator Profile & Staff Management ──
router.get('/profile', adminController.getProfile);
router.put('/profile', adminController.updateProfile);

router.get('/staff', adminController.getStaff);
router.post('/staff', adminController.createStaff);
router.put('/staff/:id', adminController.updateStaff);
router.delete('/staff/:id', adminController.deleteStaff);
 
// ── Admin Notifications (Routed from admin page) ──
router.get('/notifications',                        notificationController.getAdminNotifications);
router.get('/notifications/unread-count',           notificationController.getAdminUnreadCount);
router.put('/notifications/read-all',               notificationController.markAllAdminAsRead);
router.put('/notifications/:id/read',               notificationController.markAsRead);


module.exports = router;
