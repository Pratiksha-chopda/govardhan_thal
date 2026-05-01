/**
 * Order Enhanced Routes — Phases 3-8
 * 
 * NEW route file for professional order features.
 * Does NOT modify existing orderRoutes.js or adminRoutes.js.
 * 
 * Customer routes (require authMiddleware):
 *   PATCH  /api/v1/order-enhanced/:orderId/cancel     — Cancel order
 *   GET    /api/v1/order-enhanced/:orderId/tracking    — Get tracking
 *   POST   /api/v1/order-enhanced/:orderId/rating      — Rate order
 *   POST   /api/v1/order-enhanced/:orderId/complaint   — Report issue
 *   POST   /api/v1/order-enhanced/:orderId/reorder     — Reorder past items
 * 
 * Admin routes (require adminMiddleware):
 *   PATCH  /api/v1/order-enhanced/admin/:orderId/status  — Update status
 *   GET    /api/v1/order-enhanced/admin/ratings           — View ratings
 *   GET    /api/v1/order-enhanced/admin/complaints        — View complaints
 *   PATCH  /api/v1/order-enhanced/admin/complaints/:id/status — Update complaint
 */
const express = require('express');
const router = express.Router();
const controller = require('../controllers/orderEnhancedController');
const { authMiddleware, adminMiddleware } = require('../middleware/authMiddleware');

// ═══════════════════════════════════════════════════
// CUSTOMER ROUTES (authenticated users)
// ═══════════════════════════════════════════════════
router.use(authMiddleware);

// Phase 4 — Cancel order
router.patch('/:orderId/cancel', controller.cancelOrder);

// Phase 5 — Get tracking data
router.get('/:orderId/tracking', controller.getTracking);

// Phase 6 — Rate delivered order
router.post('/:orderId/rating', controller.rateOrder);

// Phase 7 — Report complaint/issue
router.post('/:orderId/complaint', controller.reportComplaint);

// Phase 8 — Reorder from past order
router.post('/:orderId/reorder', controller.reorder);

// ═══════════════════════════════════════════════════
// ADMIN ROUTES (admin role required)
// ═══════════════════════════════════════════════════

// Phase 3 — Admin updates order status
router.patch('/admin/:orderId/status', adminMiddleware, controller.adminUpdateStatus);

// Phase 6 — Admin views ratings
router.get('/admin/ratings', adminMiddleware, controller.getAdminRatings);

// Phase 7 — Admin views complaints
router.get('/admin/complaints', adminMiddleware, controller.getAdminComplaints);

// Phase 7 — Admin updates complaint status
router.patch('/admin/complaints/:id/status', adminMiddleware, controller.updateComplaintStatus);

module.exports = router;
