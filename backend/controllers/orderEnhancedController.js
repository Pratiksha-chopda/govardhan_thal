/**
 * Order Enhanced Controller — Phases 3-8
 * 
 * NEW controller for professional order features.
 * Does NOT modify existing orderController.js.
 * 
 * Endpoints:
 *   PATCH  /orders/:orderId/cancel      — Customer cancels order (Phase 4)
 *   GET    /orders/:orderId/tracking    — Get tracking data (Phase 5)
 *   POST   /orders/:orderId/rating      — Rate delivered order (Phase 6)
 *   POST   /orders/:orderId/complaint   — Report issue (Phase 7)
 *   POST   /orders/:orderId/reorder     — Reorder past items (Phase 8)
 *   PATCH  /admin/order/:orderId/status — Admin updates status (Phase 3)
 *   GET    /admin/ratings               — Admin views ratings (Phase 6)
 *   GET    /admin/complaints            — Admin views complaints (Phase 7)
 *   PATCH  /admin/complaints/:id/status — Admin updates complaint (Phase 7)
 */
const asyncHandler = require('../utils/asyncHandler');
const { sendSuccess, sendError } = require('../utils/responseHelper');
const orderStatusService = require('../services/orderStatusService');
const reorderService = require('../services/reorderService');
const Order = require('../models/Order');
const Rating = require('../models/Rating');
const Complaint = require('../models/Complaint');

// ═══════════════════════════════════════════════════
// CUSTOMER ENDPOINTS
// ═══════════════════════════════════════════════════

/**
 * PATCH /api/v1/orders/:orderId/cancel — Phase 4
 * Body: { reason: "Changed my mind" }
 */
exports.cancelOrder = asyncHandler(async (req, res) => {
    const { reason } = req.body;
    const order = await orderStatusService.cancelOrder(
        req.params.orderId,
        req.user.id,
        reason || ''
    );

    sendSuccess(res, {
        orderId: order._id,
        status: order.status,
        isCancelled: order.isCancelled,
        cancellationReason: order.cancellationReason,
        paymentStatus: order.paymentStatus,
    }, 'Order cancelled successfully');
});

/**
 * GET /api/v1/orders/:orderId/tracking — Phase 5
 */
exports.getTracking = asyncHandler(async (req, res) => {
    const tracking = await orderStatusService.getTracking(
        req.params.orderId,
        req.user.id
    );
    sendSuccess(res, tracking, 'Tracking data retrieved');
});

/**
 * POST /api/v1/orders/:orderId/rating — Phase 6
 * Body: { rating: 5, review: "Delicious!", itemRatings: [{menuId, rating}] }
 */
exports.rateOrder = asyncHandler(async (req, res) => {
    const { rating, review, itemRatings } = req.body;
    const orderId = req.params.orderId;
    const userId = req.user.id;

    // Validation
    if (!rating || rating < 1 || rating > 5) {
        return sendError(res, 'Rating must be between 1 and 5', 400);
    }

    // Check order exists and belongs to user
    const order = await Order.findOne({ _id: orderId, userId });
    if (!order) {
        return sendError(res, 'Order not found', 404);
    }

    // Only allow rating for delivered/completed orders
    if (!['DELIVERED', 'COMPLETED', 'SERVED'].includes(order.status)) {
        return sendError(res, 'Can only rate delivered or completed orders', 400);
    }

    // Check if already rated
    const existing = await Rating.findOne({ orderId });
    if (existing) {
        return sendError(res, 'You have already rated this order', 400);
    }

    // Create rating
    const newRating = await Rating.create({
        orderId,
        userId,
        rating: Math.round(rating),
        review: review || '',
        itemRatings: itemRatings || [],
    });

    // Mark order as rated (safe optional field update)
    order.ratingExists = true;
    await order.save();

    sendSuccess(res, {
        ratingId: newRating._id,
        rating: newRating.rating,
        review: newRating.review,
    }, 'Thank you for your rating!', 201);
});

/**
 * POST /api/v1/orders/:orderId/complaint — Phase 7
 * Body: { issueType: "WRONG_ITEM", description: "Received paneer instead of dal" }
 */
exports.reportComplaint = asyncHandler(async (req, res) => {
    const { issueType, description } = req.body;
    const orderId = req.params.orderId;
    const userId = req.user.id;

    // Validation
    const validTypes = ['WRONG_ITEM', 'MISSING_ITEM', 'FOOD_QUALITY', 'LATE_DELIVERY', 'PACKAGING', 'OTHER'];
    if (!issueType || !validTypes.includes(issueType)) {
        return sendError(res, `Invalid issue type. Valid types: ${validTypes.join(', ')}`, 400);
    }

    // Check order exists and belongs to user
    const order = await Order.findOne({ _id: orderId, userId });
    if (!order) {
        return sendError(res, 'Order not found', 404);
    }

    // Create complaint
    const complaint = await Complaint.create({
        orderId,
        userId,
        issueType,
        description: description || '',
    });

    // Mark order as having a complaint
    order.complaintExists = true;
    await order.save();

    sendSuccess(res, {
        complaintId: complaint._id,
        issueType: complaint.issueType,
        status: complaint.status,
    }, 'Complaint registered. We will look into this.', 201);
});

/**
 * POST /api/v1/orders/:orderId/reorder — Phase 8
 */
exports.reorder = asyncHandler(async (req, res) => {
    const result = await reorderService.reorder(
        req.params.orderId,
        req.user.id
    );
    sendSuccess(res, result, result.message);
});

// ═══════════════════════════════════════════════════
// ADMIN ENDPOINTS
// ═══════════════════════════════════════════════════

/**
 * PATCH /api/v1/admin/order/:orderId/status — Phase 3
 * Body: { status: "PREPARING", note: "Kitchen started" }
 */
exports.adminUpdateStatus = asyncHandler(async (req, res) => {
    const { status, note } = req.body;

    if (!status) {
        return sendError(res, 'Status is required', 400);
    }

    const order = await orderStatusService.updateStatus(
        req.params.orderId,
        status,
        note || ''
    );

    sendSuccess(res, {
        orderId: order._id,
        status: order.status,
        timeline: order.timeline,
        paymentStatus: order.paymentStatus,
    }, `Order status updated to ${status}`);
});

/**
 * GET /api/v1/admin/ratings — Phase 6
 * Query: ?page=1&limit=20
 */
exports.getAdminRatings = asyncHandler(async (req, res) => {
    const page = Number(req.query.page) || 1;
    const limit = Number(req.query.limit) || 20;
    const skip = (page - 1) * limit;

    const total = await Rating.countDocuments();
    const ratings = await Rating.find()
        .sort({ createdAt: -1 })
        .skip(skip)
        .limit(limit)
        .populate('userId', 'name email')
        .populate('orderId', 'totalAmount order_type createdAt')
        .lean();

    sendSuccess(res, { ratings, total, page, limit, totalPages: Math.ceil(total / limit) });
});

/**
 * GET /api/v1/admin/complaints — Phase 7
 * Query: ?status=OPEN&page=1&limit=20
 */
exports.getAdminComplaints = asyncHandler(async (req, res) => {
    const page = Number(req.query.page) || 1;
    const limit = Number(req.query.limit) || 20;
    const skip = (page - 1) * limit;

    const query = {};
    if (req.query.status) query.status = req.query.status;

    const total = await Complaint.countDocuments(query);
    const complaints = await Complaint.find(query)
        .sort({ createdAt: -1 })
        .skip(skip)
        .limit(limit)
        .populate('userId', 'name email mobile')
        .populate('orderId', 'totalAmount order_type items createdAt')
        .lean();

    sendSuccess(res, { complaints, total, page, limit, totalPages: Math.ceil(total / limit) });
});

/**
 * PATCH /api/v1/admin/complaints/:id/status — Phase 7
 * Body: { status: "RESOLVED", adminNote: "Refund issued" }
 */
exports.updateComplaintStatus = asyncHandler(async (req, res) => {
    const { status, adminNote } = req.body;

    const validStatuses = ['OPEN', 'IN_PROGRESS', 'RESOLVED', 'CLOSED'];
    if (!status || !validStatuses.includes(status)) {
        return sendError(res, `Invalid status. Valid: ${validStatuses.join(', ')}`, 400);
    }

    const complaint = await Complaint.findById(req.params.id);
    if (!complaint) {
        return sendError(res, 'Complaint not found', 404);
    }

    complaint.status = status;
    if (adminNote) complaint.adminNote = adminNote;
    if (status === 'RESOLVED' || status === 'CLOSED') {
        complaint.resolvedAt = new Date();
    }

    await complaint.save();
    sendSuccess(res, complaint, `Complaint status updated to ${status}`);
});
