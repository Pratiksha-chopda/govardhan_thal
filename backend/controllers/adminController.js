/**
 * Admin Controller — Dashboard, menu CRUD, order management, booking management,
 * table management, dining management, user management, image upload.
 * All endpoints require auth + admin middleware.
 */
const adminService   = require('../services/adminService');
const menuService    = require('../services/menuService');
const orderService   = require('../services/orderService');
const bookingService = require('../services/bookingService');
const diningService  = require('../services/diningService');
const Table          = require('../models/Table');
const DiningSession  = require('../models/DiningSession');
const Menu           = require('../models/Menu');
const Admin          = require('../models/Admin');
const User           = require('../models/User');
const bcrypt         = require('bcryptjs');
const asyncHandler   = require('../utils/asyncHandler');
const { sendSuccess, sendPaginated } = require('../utils/responseHelper');
const { cloudinary } = require('../config/cloudinary');
const socket         = require('../socket');

// Helper to extract Cloudinary public_id from URL
const extractPublicId = (url) => {
    if (!url || !url.includes('res.cloudinary.com')) return null;
    const parts = url.split('/');
    const fileWithExt = parts.pop();
    const folder = parts.pop();
    const publicId = `${folder}/${fileWithExt.split('.')[0]}`;
    return publicId;
};

/**
 * GET /api/v1/admin/dashboard
 */
exports.getDashboard = asyncHandler(async (req, res) => {
    const { filter } = req.query; // TODAY, WEEK, MONTH, ALL
    const data = await orderService.getDashboardStats(filter);
    sendSuccess(res, data);
});

/**
 * GET /api/v1/admin/reports
 */
exports.getReports = asyncHandler(async (req, res) => {
    const { filter } = req.query; // TODAY, WEEK, MONTH, ALL
    const data = await orderService.getReports(filter);
    sendSuccess(res, data);
});

// ── Menu CRUD (Admin) ──

/**
 * POST /api/v1/admin/menu
 */
exports.createMenu = asyncHandler(async (req, res) => {
    const data = { ...req.body };
    if (req.file) {
        data.imageUrl = req.file.path;
    }
    const item = await menuService.create(data);
    socket.emitMenuCreated(item);
    sendSuccess(res, item, 'Menu item created', 201);
});

/**
 * PUT /api/v1/admin/menu/:id
 */
exports.updateMenu = asyncHandler(async (req, res) => {
    const data = { ...req.body };
    
    if (req.file) {
        data.imageUrl = req.file.path;
        
        // Optionally delete old Cloudinary image
        const oldItem = await menuService.getById(req.params.id);
        if (oldItem && oldItem.imageUrl) {
            const publicId = extractPublicId(oldItem.imageUrl);
            if (publicId) {
                cloudinary.uploader.destroy(publicId).catch(console.error);
            }
        }
    }
    
    const item = await menuService.update(req.params.id, data);
    if (!item) return res.status(404).json({ status: 'error', message: 'Menu item not found' });
    socket.emitMenuUpdated(item);
    sendSuccess(res, item, 'Menu item updated');
});

/**
 * DELETE /api/v1/admin/menu/:id  (Soft delete)
 */
exports.deleteMenu = asyncHandler(async (req, res) => {
    // Optionally delete old Cloudinary image
    const oldItem = await menuService.getById(req.params.id);
    if (oldItem && oldItem.imageUrl) {
        const publicId = extractPublicId(oldItem.imageUrl);
        if (publicId) {
            cloudinary.uploader.destroy(publicId).catch(console.error);
        }
    }
    const item = await menuService.softDelete(req.params.id);
    if (!item) return res.status(404).json({ status: 'error', message: 'Menu item not found' });
    socket.emitMenuDeleted(req.params.id);
    sendSuccess(res, null, 'Menu item deleted');
});

/**
 * POST /api/v1/admin/menu/:id/upload  —  Upload / replace menu image via multer
 * After upload the stored imageUrl takes priority over keyword fallback.
 */
exports.uploadMenuImage = asyncHandler(async (req, res) => {
    if (!req.file) {
        return res.status(400).json({ status: 'error', message: 'No image file provided' });
    }
    const imageUrl = req.file.path; // Cloudinary URL
    
    // Optionally delete old Cloudinary image
    const oldItem = await menuService.getById(req.params.id);
    if (oldItem && oldItem.imageUrl) {
        const publicId = extractPublicId(oldItem.imageUrl);
        if (publicId) {
            cloudinary.uploader.destroy(publicId).catch(console.error);
        }
    }
    
    const item = await menuService.update(req.params.id, { imageUrl });
    if (!item) return res.status(404).json({ status: 'error', message: 'Menu item not found' });
    socket.emitMenuUpdated(item);
    sendSuccess(res, item, 'Image uploaded successfully');
});

/**
 * PATCH /api/v1/admin/menu/:id/image-url
 * Body: { imageUrl }  — Change image to any direct URL
 */
exports.changeImageUrl = asyncHandler(async (req, res) => {
    const { imageUrl } = req.body;
    if (!imageUrl) return res.status(400).json({ status: 'error', message: 'imageUrl required' });
    const item = await menuService.update(req.params.id, { imageUrl });
    if (!item) return res.status(404).json({ status: 'error', message: 'Menu item not found' });
    socket.emitMenuUpdated(item);
    sendSuccess(res, item, 'Image URL updated');
});

/**
 * PATCH /api/v1/admin/menu/:id/image-keyword
 * Body: { imageKeyword }  — Change keyword used for dynamic Unsplash image
 */
exports.changeImageKeyword = asyncHandler(async (req, res) => {
    const { imageKeyword } = req.body;
    if (!imageKeyword) return res.status(400).json({ status: 'error', message: 'imageKeyword required' });
    // Clear stored imageUrl so the new keyword becomes the active image
    const item = await menuService.update(req.params.id, { imageKeyword, imageUrl: '' });
    if (!item) return res.status(404).json({ status: 'error', message: 'Menu item not found' });
    socket.emitMenuUpdated(item);
    sendSuccess(res, item, 'Image keyword updated — dynamic URL now active');
});

/**
 * PATCH /api/v1/admin/menu/:id/popular
 * Body: { isPopular: true|false }
 */
exports.setPopular = asyncHandler(async (req, res) => {
    const { isPopular } = req.body;
    if (typeof isPopular !== 'boolean') {
        return res.status(400).json({ status: 'error', message: 'isPopular must be boolean' });
    }
    const item = await menuService.update(req.params.id, { isPopular });
    if (!item) return res.status(404).json({ status: 'error', message: 'Menu item not found' });
    socket.emitMenuUpdated(item);
    sendSuccess(res, item, `Item marked as ${isPopular ? 'popular' : 'not popular'}`);
});

/**
 * PATCH /api/v1/admin/menu/:id/today-special
 * Body: { isTodaySpecial: true|false }
 */
exports.setTodaySpecial = asyncHandler(async (req, res) => {
    const { isTodaySpecial } = req.body;
    if (typeof isTodaySpecial !== 'boolean') {
        return res.status(400).json({ status: 'error', message: 'isTodaySpecial must be boolean' });
    }
    const item = await menuService.update(req.params.id, { isTodaySpecial });
    if (!item) return res.status(404).json({ status: 'error', message: 'Menu item not found' });
    socket.emitMenuUpdated(item);
    sendSuccess(res, item, `Item marked as ${isTodaySpecial ? "today's special" : 'not today special'}`);
});

/**
 * PATCH /api/v1/admin/menu/:id/recommended
 * Body: { isRecommended: true|false }
 */
exports.setRecommended = asyncHandler(async (req, res) => {
    const { isRecommended } = req.body;
    if (typeof isRecommended !== 'boolean') {
        return res.status(400).json({ status: 'error', message: 'isRecommended must be boolean' });
    }
    const item = await menuService.update(req.params.id, { isRecommended });
    if (!item) return res.status(404).json({ status: 'error', message: 'Menu item not found' });
    socket.emitMenuUpdated(item);
    sendSuccess(res, item, `Item marked as ${isRecommended ? 'recommended' : 'not recommended'}`);
});

/**
 * PATCH /api/v1/admin/menu/:id/available
 * Body: { isAvailable: true|false }
 */
exports.setAvailable = asyncHandler(async (req, res) => {
    const { isAvailable } = req.body;
    if (typeof isAvailable !== 'boolean') {
        return res.status(400).json({ status: 'error', message: 'isAvailable must be boolean' });
    }
    const item = await menuService.update(req.params.id, { isAvailable });
    if (!item) return res.status(404).json({ status: 'error', message: 'Menu item not found' });
    socket.emitMenuUpdated(item);
    sendSuccess(res, item, `Item marked as ${isAvailable ? 'available' : 'unavailable'}`);
});

/**
 * PATCH /api/v1/admin/menu/:id/category
 * Body: { category }
 */
exports.changeCategory = asyncHandler(async (req, res) => {
    const { category } = req.body;
    if (!category) return res.status(400).json({ status: 'error', message: 'category required' });
    const item = await menuService.update(req.params.id, { category });
    if (!item) return res.status(404).json({ status: 'error', message: 'Menu item not found' });
    socket.emitMenuUpdated(item);
    sendSuccess(res, item, `Category changed to ${category}`);
});

// ── Order Management (Admin) ──

/**
 * GET /api/v1/admin/orders
 * Query: ?status=&page=&limit=
 */
exports.getOrders = asyncHandler(async (req, res) => {
    const { status, order_type } = req.query;
    const page = parseInt(req.query.page) || 1;
    const limit = parseInt(req.query.limit) || 20;
    const result = await orderService.getAdminOrders({ status, order_type, page, limit });
    sendPaginated(res, result.orders, result.page, result.limit, result.total);
});

/**
 * PUT /api/v1/admin/orders/:orderId/status
 * Body: { status, note }
 */
exports.updateOrderStatus = asyncHandler(async (req, res) => {
    const { status, note, paymentStatus } = req.body;
    const order = await orderService.updateStatus(req.params.orderId, status, note, paymentStatus);
    socket.emitOrderStatusUpdated(order);
    sendSuccess(res, order, `Order updated`);
});

// ── Booking Management (Admin) ──

/**
 * GET /api/v1/admin/bookings
 */
exports.getBookings = asyncHandler(async (req, res) => {
    const bookings = await bookingService.adminGetAll();
    sendSuccess(res, bookings);
});

/**
 * PUT /api/v1/admin/bookings/:bookingId/status
 * Body: { status }  — APPROVED, REJECTED, CANCELLED
 */
exports.updateBookingStatus = asyncHandler(async (req, res) => {
    const booking = await bookingService.adminUpdateStatus(req.params.bookingId, req.body.status);
    socket.emitBookingStatusUpdated(booking);
    sendSuccess(res, booking, `Booking status updated`);
});

// ── Table Management (Admin) ──

/**
 * GET /api/v1/admin/tables
 */
exports.getTables = asyncHandler(async (req, res) => {
    const tables = await Table.find().sort({ tableNumber: 1 }).lean();
    sendSuccess(res, tables);
});

/**
 * POST /api/v1/admin/tables
 */
exports.createTable = asyncHandler(async (req, res) => {
    const { tableNumber, capacity, qrCode } = req.body;
    const table = await Table.create({
        tableNumber,
        capacity: capacity || 4,
        qrCode: qrCode || `TABLE_QR_${String(tableNumber).padStart(3, '0')}`,
    });
    sendSuccess(res, table, 'Table created', 201);
});

/**
 * PUT /api/v1/admin/tables/:id
 */
exports.updateTable = asyncHandler(async (req, res) => {
    const table = await Table.findByIdAndUpdate(req.params.id, req.body, { new: true });
    if (!table) return res.status(404).json({ status: 'error', message: 'Table not found' });
    socket.emitTableStatusUpdated(table);
    sendSuccess(res, table, 'Table updated');
});

/**
 * DELETE /api/v1/admin/tables/:id
 */
exports.deleteTable = asyncHandler(async (req, res) => {
    const table = await Table.findByIdAndDelete(req.params.id);
    if (!table) return res.status(404).json({ status: 'error', message: 'Table not found' });
    sendSuccess(res, null, 'Table deleted');
});

// ── Dining Management (Admin) ──

/**
 * GET /api/v1/admin/active-tables
 * Returns all tables that are currently OCCUPIED, with their active session.
 */
exports.getActiveTables = asyncHandler(async (req, res) => {
    // Requirement 10: Fetch all tables that are not AVAILABLE to show status on dashboard
    const tables = await Table.find({ status: { $ne: 'AVAILABLE' } }).sort({ tableNumber: 1 }).lean();
    
    // Attach active session info to each table
    const result = await Promise.all(tables.map(async (t) => {
        const session = await DiningSession.findOne({ 
            tableId: t._id, 
            status: { $in: ['ACTIVE', 'BILL_REQUESTED', 'PAID_WAITING_EXIT'] } 
        })
            .populate('userId', 'name mobile')
            .populate('users', 'name mobile') 
            .populate({ path: 'orders', select: 'totalAmount status createdAt' })
            .lean();
        return { ...t, activeSession: session };
    }));
    sendSuccess(res, result);
});


/**
 * GET /api/v1/admin/dining-sessions
 * Query: ?status=ACTIVE|CLOSED
 */
exports.getDiningSessions = asyncHandler(async (req, res) => {
    const { status } = req.query;
    const query = {};
    if (status) query.status = status;
    const sessions = await DiningSession.find(query)
        .populate('tableId', 'tableNumber capacity')
        .populate('userId', 'name mobile')
        .populate({ path: 'orders', select: 'items totalAmount status paymentStatus createdAt' })
        .sort({ createdAt: -1 })
        .lean();
    sendSuccess(res, sessions);
});

/**
 * GET /api/v1/admin/dining-orders
 * Get all DINING type orders (with session context).
 */
exports.getDiningOrders = asyncHandler(async (req, res) => {
    const { status, page, limit } = req.query;
    const query = { order_type: 'DINING' };
    if (status) query.status = status;
    const result = await orderService.getAdminOrders({ ...query, page, limit });
    sendPaginated(res, result.orders, result.page, result.limit, result.total);
});

/**
 * PUT /api/v1/admin/dining-orders/:orderId/status
 * Update dining order status: PLACED→PREPARING→READY→SERVED→COMPLETED
 * Body: { status, note }
 */
exports.updateDiningOrderStatus = asyncHandler(async (req, res) => {
    const { status, note, paymentStatus } = req.body;
    const order = await orderService.updateStatus(req.params.orderId, status, note, paymentStatus);
    
    // If order is completed (Settle & Complete), close the session too
    if (status === 'COMPLETED') {
        const session = await DiningSession.findOne({ orders: order._id, status: 'ACTIVE' });
        if (session) {
            // Check if payment is already success? 
            // The UI button only shows if payment status is SUCCESS or PAID.
            // But we should enforce server side rule here if possible or trust the rule in diningService.closeSession.
            try {
                await diningService.closeSession(session._id);
                socket.emitDiningSessionClosed({ session_id: session._id, status: 'COMPLETED' });
            } catch (err) {
                console.error("Session auto-close failed:", err.message);
                // Non-fatal, order was updated
            }
        }
    }

    socket.emitDiningOrderStatusUpdated(order);
    sendSuccess(res, order, `Dining order status updated to ${status}`);
});

/**
 * POST /api/v1/admin/dining/verify-payment (Section 11)
 * Body: { sessionId, paymentMethod, transactionId }
 */
exports.adminVerifyDiningPayment = asyncHandler(async (req, res) => {
    const { sessionId, paymentMethod, transactionId, amountPaid } = req.body;
    const result = await diningService.verifyDiningPayment(sessionId, { 
        paymentMethod, 
        transactionId,
        amountPaid 
    });
    socket.emitDiningPaymentUpdate(result);
    sendSuccess(res, result, 'Payment verified successfully');
});

/**
 * POST /api/v1/admin/dining/close-session
 * Body: { sessionId }
 */
exports.adminCloseSession = asyncHandler(async (req, res) => {
    // Section 14: Admin can force close Table (with unpaid option)
    const { sessionId, force = true, unpaid = false } = req.body;
    const result = await diningService.closeSession(sessionId, { force, unpaid });
    socket.emitDiningSessionClosed(result);
    sendSuccess(res, result, 'Session closed by admin');
});

// ── User Management (Admin) ──

/**
 * GET /api/v1/admin/users
 * Query: ?page=&limit=
 * Stabilized: returns 200 even on error to prevent UI crash.
 */
exports.getUsers = async (req, res) => {
    try {
        const limit = parseInt(req.query.limit) || 50;
        const today = new Date();
        today.setHours(0, 0, 0, 0);

        const [users, totalUsers, usersToday] = await Promise.all([
            User.find({}).sort({ createdAt: -1 }).limit(limit).lean(),
            User.countDocuments(),
            User.countDocuments({ createdAt: { $gte: today } })
        ]);

        return res.status(200).json({
            success: true,
            data: {
                users: users || [],
                totalUsers,
                usersToday
            }
        });
    } catch (error) {
        console.error("Admin users error:", error);
        return res.status(200).json({
            success: true,
            data: {
                users: [],
                totalUsers: 0,
                usersToday: 0
            }
        });
    }
};

/**
 * GET /api/v1/admin/profile
 */
exports.getProfile = asyncHandler(async (req, res) => {
    const admin = await Admin.findById(req.user.id).select('-password');
    if (!admin) return res.status(404).json({ status: 'error', message: 'Admin profile not found' });
    sendSuccess(res, admin);
});


/**
 * PUT /api/v1/admin/profile
 * Body: { name, password }
 */
exports.updateProfile = asyncHandler(async (req, res) => {
    const { name, password } = req.body;
    let updateData = {};
    if (name) updateData.name = name;
    if (password) {
        const salt = await bcrypt.genSalt(10);
        updateData.password = await bcrypt.hash(password, salt);
    }
    const admin = await Admin.findByIdAndUpdate(req.user.id, updateData, { new: true }).select('-password');
    sendSuccess(res, admin, 'Profile updated successfully');
});

// ── Staff Management ──

exports.getStaff = asyncHandler(async (req, res) => {
    const staff = await Admin.find().select('-password').sort({ createdAt: -1 }).lean();
    sendSuccess(res, staff);
});

exports.createStaff = asyncHandler(async (req, res) => {
    const { name, email, password, role } = req.body;
    if (!name || !email || !password || !role) {
        return res.status(400).json({ success: false, message: 'Please provide name, email, password, and role.' });
    }

    const existingUser = await Admin.findOne({ email });
    if (existingUser) return res.status(400).json({ success: false, message: 'Email already exists' });

    const bcrypt = require('bcryptjs');
    const salt = await bcrypt.genSalt(10);
    const hashedPassword = await bcrypt.hash(password, salt);

    const newStaff = await Admin.create({
        name,
        email,
        password: hashedPassword,
        role
    });

    const staffObj = newStaff.toObject();
    delete staffObj.password;
    sendSuccess(res, staffObj, 'Staff created successfully', 201);
});

exports.updateStaff = asyncHandler(async (req, res) => {
    const { name, role, password } = req.body;
    let updateData = {};
    if (name) updateData.name = name;
    if (role) updateData.role = role;
    if (password) {
        const bcrypt = require('bcryptjs');
        const salt = await bcrypt.genSalt(10);
        updateData.password = await bcrypt.hash(password, salt);
    }

    const staff = await Admin.findByIdAndUpdate(req.params.id, updateData, { new: true }).select('-password');
    if (!staff) return res.status(404).json({ success: false, message: 'Staff not found' });
    sendSuccess(res, staff, 'Staff updated successfully');
});

exports.deleteStaff = asyncHandler(async (req, res) => {
    // Prevent deleting the main admin trying to delete themselves (optional safety check)
    if (req.user.id === req.params.id) {
         return res.status(400).json({ success: false, message: 'You cannot delete yourself' });
    }

    const staff = await Admin.findByIdAndDelete(req.params.id);
    if (!staff) return res.status(404).json({ success: false, message: 'Staff not found' });
    sendSuccess(res, null, 'Staff deleted successfully');
});
