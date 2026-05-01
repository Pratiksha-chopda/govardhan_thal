const express    = require('express');
const router     = express.Router();
const ctrl       = require('../controllers/diningController');
const { authMiddleware, adminMiddleware } = require('../middleware/authMiddleware');
const validate   = require('../middleware/validateRequest');

// ── Public (no auth needed — QR scan before login) ──
router.post('/verify-table', validate.verifyTable, ctrl.verifyTable);

// ── Authenticated routes ──
router.use(authMiddleware);

router.post('/start-session',   ctrl.startSession);
router.post('/order',           ctrl.placeDiningOrder);      // NEW: place dining order
router.get( '/session/:id',     ctrl.getSession);            // NEW: get session + orders
router.get( '/bill/:sessionId', ctrl.getBill);               // NEW: calculated bill
router.post('/request-bill',   ctrl.requestBill);      // User: Section 8
router.post('/verify-payment',  ctrl.verifyDiningPayment); // Admin: Section 11 (Actually this should be admin restricted but it's used in orders manager)
router.post('/close-session',   ctrl.closeSession);          // Admin/User: close & free table
router.post('/end-session',     ctrl.closeSession);          // legacy alias
router.get( '/active-session',  ctrl.getActiveSession);

// ── Admin only ──
router.get('/admin/active-sessions', adminMiddleware, ctrl.getActiveSessions);

module.exports = router;
