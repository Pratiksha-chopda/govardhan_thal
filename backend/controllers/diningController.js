/**
 * Dining Controller — Full production restaurant dining flow.
 * QR scan → verify → start session → order → bill → payment → close.
 */
const diningService = require('../services/diningService');
const asyncHandler  = require('../utils/asyncHandler');
const { sendSuccess } = require('../utils/responseHelper');
const socket = require('../socket');

// ── POST /api/v1/dining/verify-table  { qrCode }
exports.verifyTable = asyncHandler(async (req, res) => {
    const result = await diningService.verifyTable(req.body.qrCode);
    sendSuccess(res, result, 'Table verified');
});

// ── POST /api/v1/dining/start-session  { tableId, confirmSwitch }
exports.startSession = asyncHandler(async (req, res) => {
    const result = await diningService.startSession(req.user.id, req.body.tableId, req.body.confirmSwitch);
    socket.emitDiningSessionStarted(result);
    sendSuccess(res, result, 'Dining session started', 201);
});

// ── POST /api/v1/dining/order  { sessionId, tableId, items[], couponCode, discountAmount }
exports.placeDiningOrder = asyncHandler(async (req, res) => {
    const { sessionId, tableId, items, couponCode, discountAmount } = req.body;
    const result = await diningService.placeDiningOrder(req.user.id, { 
        sessionId, 
        tableId, 
        items, 
        couponCode, 
        discountAmount 
    });
    socket.emitDiningOrderNew(result);
    sendSuccess(res, result, 'Order placed', 201);
});

// ── GET /api/v1/dining/session/:id
exports.getSession = asyncHandler(async (req, res) => {
    const session = await diningService.getSession(req.params.id, req.user.id);
    sendSuccess(res, session);
});

// ── GET /api/v1/dining/bill/:sessionId
exports.getBill = asyncHandler(async (req, res) => {
    const bill = await diningService.getBill(req.params.sessionId);
    sendSuccess(res, bill, 'Bill calculated');
});

// ── POST /api/v1/dining/request-bill (User: "I WANT TO PAY")
exports.requestBill = asyncHandler(async (req, res) => {
    const { sessionId } = req.body;
    const result = await diningService.requestBill(sessionId);
    socket.emitDiningOrderUpdate(result); // Notify admin
    sendSuccess(res, result, 'Bill requested');
});

// ── POST /api/v1/dining/verify-payment (Admin: Verify & Finalize Section 11)
exports.verifyDiningPayment = asyncHandler(async (req, res) => {
    const { sessionId, paymentMethod, transactionId, amountPaid } = req.body;
    const result = await diningService.verifyDiningPayment(sessionId, { 
        paymentMethod, 
        transactionId,
        amountPaid 
    });
    socket.emitDiningPaymentUpdate(result);
    sendSuccess(res, result, 'Payment verified successfully');
});

// ── POST /api/v1/dining/close-session  { sessionId }
exports.closeSession = asyncHandler(async (req, res) => {
    const { sessionId, force, unpaid } = req.body;
    const result = await diningService.closeSession(sessionId, { force, unpaid });
    socket.emitDiningSessionClosed(result);
    sendSuccess(res, result, 'Session closed');
});

// ── POST /api/v1/dining/end-session  (legacy alias)
exports.endSession = asyncHandler(async (req, res) => {
    const { sessionId, force, unpaid } = req.body;
    const result = await diningService.closeSession(sessionId, { force, unpaid });
    sendSuccess(res, result, 'Session ended');
});

// ── GET /api/v1/dining/active-session
exports.getActiveSession = asyncHandler(async (req, res) => {
    const session = await diningService.getActiveSession(req.user.id);
    sendSuccess(res, session);
});

// ── GET /api/v1/dining/admin/active-sessions  (Admin)
exports.getActiveSessions = asyncHandler(async (req, res) => {
    const sessions = await diningService.getActiveSessions();
    sendSuccess(res, sessions);
});
