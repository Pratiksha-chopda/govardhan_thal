/**
 * Dining Service — Complete production restaurant dining flow.
 * QR → verify table → start session → place orders → bill → payment → close.
 */
const Table = require('../models/Table');
const DiningSession = require('../models/DiningSession');
const Order = require('../models/Order');
const Menu = require('../models/Menu');
const GlobalSettings = require('../models/GlobalSettings');

const GET_GST_PERCENT = async () => {
    const setting = await GlobalSettings.findOne({ key: 'tax_gst' }).lean();
    return setting ? parseFloat(setting.value) : 5;
};


// ──────────────────────────────────────────────────────
// 1. Verify Table by QR code
// ──────────────────────────────────────────────────────
const verifyTable = async (qrCode) => {
    const table = await Table.findOne({ qrCode }).lean();
    if (!table) {
        throw Object.assign(new Error('Invalid QR code. Table not found.'), { statusCode: 404 });
    }

    // Check for any existing ACTIVE session on this table
    let activeSession = null;
    if (table.status === 'OCCUPIED') {
        activeSession = await DiningSession.findOne({ tableId: table._id, status: 'ACTIVE' })
            .select('_id')
            .lean();
    }

    return {
        table_id: table._id,
        table_number: table.tableNumber,
        qr_code: table.qrCode,
        capacity: table.capacity,
        status: table.status,
        is_available: table.status === 'AVAILABLE',
        active_session: activeSession ? activeSession._id : null,
    };
};

// ──────────────────────────────────────────────────────
// 2. Start Dining Session
// ──────────────────────────────────────────────────────
const startSession = async (userId, tableId, confirmSwitch = false) => {
    const table = await Table.findById(tableId);
    if (!table) throw Object.assign(new Error('Table not found'), { statusCode: 404 });

    // Mark table OCCUPIED if it was available
    if (table.status === 'RESERVED') {
        throw Object.assign(new Error('Table is reserved'), { statusCode: 409 });
    }

    // SECTION 3: Check if TABLE has an ACTIVE session first (Join Rule)
    const tableActiveSession = await DiningSession.findOne({ tableId: table._id, status: 'ACTIVE' });
    if (tableActiveSession) {
        // Attach user to existing table session
        if (!tableActiveSession.users.includes(userId)) {
            tableActiveSession.users.push(userId);
            await tableActiveSession.save();
        }
        return {
            session_id: tableActiveSession._id,
            table_number: table.tableNumber,
            table_id: table._id,
            start_time: tableActiveSession.startTime,
            status: tableActiveSession.status,
            is_existing: true,
            is_joined: true
        };
    }

    // Check if current user already has an ACTIVE session on ANOTHER table (Switch Rule)
    const userActiveSession = await DiningSession.findOne({ userId, status: 'ACTIVE' }).populate('tableId');
    if (userActiveSession) {
        if (confirmSwitch) {
            // User confirmed SWITCH — Close old session (Forces payment/admin check? Req says Section 3: "If switch: Close old session.")
            userActiveSession.status = 'CLOSED'; 
            userActiveSession.endTime = new Date();
            await userActiveSession.save();
            
            // Free the OLD table
            await Table.findByIdAndUpdate(userActiveSession.tableId._id, { status: 'AVAILABLE' });
            
            // Proceed to create NEW session below
        } else {
            const err = new Error(`You already have an active dining session on Table #${userActiveSession.tableId.tableNumber}.`);
            err.statusCode = 409;
            err.code = 'ACTIVE_SESSION_EXISTS';
            err.existingTable = userActiveSession.tableId.tableNumber;
            err.existingSessionId = userActiveSession._id;
            throw err;
        }
    }

    // Mark table OCCUPIED
    table.status = 'OCCUPIED';
    await table.save();

    // Create dining session
    const session = await DiningSession.create({
        userId,
        users: [userId], 
        tableId: table._id,
        startTime: new Date(),
        status: 'ACTIVE',
    });

    return {
        session_id: session._id,
        table_number: table.tableNumber,
        table_id: table._id,
        start_time: session.startTime,
        status: session.status,
        is_existing: false,
    };
};

// ──────────────────────────────────────────────────────
// 3. Place Dining Order (attaches to session)
// ──────────────────────────────────────────────────────
const placeDiningOrder = async (userId, { sessionId, tableId, items, couponCode, discountAmount = 0, source = 'QR' }) => {
    // Validate session
    const session = await DiningSession.findById(sessionId);
    if (!session) throw Object.assign(new Error('Session not found'), { statusCode: 404 });
    
    // Requirement 3 & 5: Only block if session is finalized
    if (['COMPLETED', 'CLOSED'].includes(session.status)) {
        throw Object.assign(new Error(`Session is already ${session.status}. Please scan QR again for new session.`), { statusCode: 400 });
    }

    // Revert to ACTIVE if they ordered more after requesting bill
    if (session.status === 'BILL_REQUESTED') {
        session.status = 'ACTIVE';
        session.paymentStatus = 'PENDING';
        await Table.findByIdAndUpdate(session.tableId, { status: 'OCCUPIED' });
    }

    // Validate table
    const table = await Table.findById(tableId || session.tableId);
    if (!table) throw Object.assign(new Error('Table not found'), { statusCode: 404 });

    // Build order items
    let subtotal = 0;
    const orderItems = [];
    const parsedDiscount = parseFloat(discountAmount) || 0;

    for (const item of items) {
        const menuItem = await Menu.findById(item.menuId).lean();
        if (!menuItem || menuItem.isDeleted) throw Object.assign(new Error(`Menu item ${item.menuId} not found`), { statusCode: 400 });
        const lineTotal = menuItem.price * item.quantity;
        subtotal += lineTotal;
        orderItems.push({ menuId: item.menuId, name: menuItem.name, quantity: item.quantity, price: menuItem.price });
    }

    const finalDiscount = Math.min(parsedDiscount, subtotal);
    const rawTotal = Math.max(0, subtotal - finalDiscount);
    const gstAmount = parseFloat((rawTotal * 0.05).toFixed(2));
    const finalTotal = parseFloat((rawTotal + gstAmount).toFixed(2));

    // Section 5: Order status flow — Start with ORDERED
    const order = await Order.create({
        userId,
        sessionId: session._id,
        items: orderItems,
        subtotal,
        discountAmount: finalDiscount,
        couponCode,
        gst: gstAmount,
        totalAmount: finalTotal,
        order_type: 'DINING',
        tableId: session.tableId,
        status: 'PLACED', // Section 5: Standardized to PLACED
        paymentStatus: 'PENDING',
        source: source, // Section 4: QR or ADMIN
        timeline: [{ status: 'PLACED', timestamp: new Date(), note: `Dining order placed via ${source}` }],
    });

    session.orders.push(order._id);
    await session.save();

    return {
        order_id: order._id,
        session_id: session._id,
        table_number: table.tableNumber,
        items: orderItems,
        subtotal,
        order_status: order.status,
    };
};

// ──────────────────────────────────────────────────────
// 4. Get Session (with all orders)
// ──────────────────────────────────────────────────────
const getSession = async (sessionId, userId = null) => {
    const query = { _id: sessionId };
    if (userId) {
        query.$or = [ { userId: userId }, { users: userId } ];
    }

    const session = await DiningSession.findOne(query)
        .populate('tableId', 'tableNumber capacity qrCode status')
        .populate({
            path: 'orders',
            select: 'items totalAmount orderStatus paymentStatus createdAt timeline',
        })
        .lean();

    if (!session) throw Object.assign(new Error('Session not found'), { statusCode: 404 });

    // Ensure session totals are recalculated dynamically
    const activeOrders = (session.orders || []).filter(o => o.status !== 'CANCELLED');
    const session_subtotal = activeOrders.reduce((sum, o) => sum + (parseFloat(o.totalAmount) || 0), 0);
    const gst_percent = await GET_GST_PERCENT();
    const gst_amount = parseFloat(((session_subtotal * gst_percent) / 100).toFixed(2));
    const final_total = parseFloat((session_subtotal + gst_amount).toFixed(2));

    session.subtotal = session_subtotal;
    session.gstPercent = gst_percent;
    session.gstAmount = gst_amount;
    session.totalAmount = final_total;

    return session;
};

// ──────────────────────────────────────────────────────
// 5. Get Bill (calculate totals with GST)
// ──────────────────────────────────────────────────────
const getBill = async (sessionId) => {
    const session = await DiningSession.findById(sessionId)
        .populate('tableId', 'tableNumber capacity')
        .populate({
            path: 'orders',
            select: 'items totalAmount orderStatus paymentStatus createdAt',
        })
        .lean();

    if (!session) throw Object.assign(new Error('Session not found'), { statusCode: 404 });
    
    // Dynamically fetch all non-cancelled orders belonging to this session
    const activeOrders = await Order.find({ 
        sessionId: session._id, 
        status: { $ne: 'CANCELLED' } 
    }).lean();
    
    const gst_percent = await GET_GST_PERCENT();
    
    // Sum the subtotal components from all orders
    // subtotal = Sum(item.price * quantity) - discountAmount
    const session_subtotal = activeOrders.reduce((sum, o) => sum + (parseFloat(o.subtotal || 0) - parseFloat(o.discountAmount || 0)), 0);
    
    // Calculate global GST from the session-wide subtotal
    const gst_amount = parseFloat(((session_subtotal * gst_percent) / 100).toFixed(2));
    
    // Resulting rounded integer total
    const final_total = Math.round(session_subtotal + gst_amount);

    // Update session record if it's active
    if (session.status !== 'CLOSED' && session.status !== 'COMPLETED') {
        await DiningSession.findByIdAndUpdate(sessionId, {
            subtotal: session_subtotal,
            gstPercent: gst_percent,
            gstAmount: gst_amount,
            totalAmount: final_total
        });
    }

    return {
        session_id: session._id,
        table_number: session.tableId?.tableNumber,
        table_id: session.tableId?._id,
        orders: activeOrders, 
        subtotal: session_subtotal,
        gst_percent: gst_percent,
        gst_amount: gst_amount,
        total: final_total,
        payment_status: session.paymentStatus,
        session_status: session.status,
        start_time: session.startTime,
        end_time: session.endTime
    };
};


const _buildBillResponse = (session) => {
    const activeOrders = (session.orders || []).filter(o => o.status !== 'CANCELLED');
    return {
        session_id: session._id,
        table_number: session.tableId?.tableNumber,
        table_id: session.tableId?._id,
        orders: activeOrders,
        subtotal: session.subtotal,
        gst_percent: session.gstPercent,
        gst_amount: session.gstAmount,
        total: session.totalAmount,
        payment_status: session.paymentStatus,
        session_status: session.status,
        start_time: session.startTime,
        end_time: session.endTime,
    };
};

// ──────────────────────────────────────────────────────
// 6b. User: Request Bill (Sets status to BILL_REQUESTED Section 8)
// ──────────────────────────────────────────────────────
const requestBill = async (sessionId) => {
    const session = await DiningSession.findById(sessionId).populate('orders');
    if (!session) throw Object.assign(new Error('Session not found'), { statusCode: 404 });
    
    // Requirement: Bill request only marks session BILL_REQUESTED (no payment update)
    const bill = await getBill(sessionId);
    session.status = 'BILL_REQUESTED';
    // Removed: session.paymentStatus = 'PAYMENT_PENDING';
    // Removed: orderStatus = 'WAITING_PAYMENT';
    
    // Use requestBill final rounded values
    session.subtotal = bill.subtotal;
    session.gstAmount = bill.gst_amount;
    session.totalAmount = bill.total;
    await session.save();

    // SECTION 15: Admin Color Support
    await Table.findByIdAndUpdate(session.tableId, { status: 'BILL_REQUESTED' });

    return { 
        ...bill, 
        status: 'BILL_REQUESTED', 
        payment_status: 'PAYMENT_PENDING' 
    };
};



// ──────────────────────────────────────────────────────
// 7. Admin: Verify Payment (Section 11 & 12)
// ──────────────────────────────────────────────────────
const verifyDiningPayment = async (sessionId, { paymentMethod, transactionId, amountPaid = null } = {}) => {
    const session = await DiningSession.findById(sessionId).populate('orders');
    if (!session) throw Object.assign(new Error('Session not found'), { statusCode: 404 });
    
    const bill = await getBill(sessionId);
    const totalDue = bill.total;

    // Mark session as PAID per requirement
    session.paymentStatus = 'PAID';
    session.paymentMethod = paymentMethod || 'COUNTER';
    session.transactionId = transactionId || 'ADMIN-PAID';
    session.subtotal = bill.subtotal;
    session.gstAmount = bill.gst_amount;
    session.totalAmount = bill.total;
    
    // Requirement 5: Keep session open (PAID_WAITING_EXIT) until admin ends it
    session.status = 'PAID_WAITING_EXIT'; 
    await session.save();

    // Table stays 'BILL_REQUESTED' or 'PAID' until closed entirely
    await Table.findByIdAndUpdate(session.tableId, { status: 'PAID' });

    return {
        session_id: session._id,
        payment_status: 'PAID',
        session_status: 'PAID_WAITING_EXIT',
        total_due: totalDue
    };
};


// ──────────────────────────────────────────────────────
// 7. Close Session
// ──────────────────────────────────────────────────────
const closeSession = async (sessionId, { force = false, unpaid = false } = {}) => {
    const session = await DiningSession.findById(sessionId);
    if (!session) throw Object.assign(new Error('Session not found'), { statusCode: 404 });
    
    if (session.status === 'COMPLETED') return { session_id: session._id, status: 'COMPLETED' };

    // SECTION 12 & 14: Session Close Rule
    if (!force && session.paymentStatus !== 'PAID') {
        throw Object.assign(new Error('Cannot close session. Payment must be PAID first. (Admin can force close)'), { statusCode: 400 });
    }

    if (unpaid) {
        // SECTION 14: Unpaid Session Rule
        session.paymentStatus = 'UNPAID';
        // Recalculate orders to unpaid
        const activeOrders = await Order.find({ sessionId: session._id, status: { $ne: 'CANCELLED' } });
        for (const order of activeOrders) {
            order.paymentStatus = 'UNPAID';
            order.status = 'CANCELLED'; // Effectively cancel or mark as unpaid loss
            await order.save();
        }
    }

    session.status = 'COMPLETED';
    session.endTime = new Date();
    await session.save();

    // Free the table
    await Table.findByIdAndUpdate(session.tableId, { status: 'AVAILABLE' });

    return {
        session_id: session._id,
        end_time: session.endTime,
        status: session.status,
    };
};

// ──────────────────────────────────────────────────────
// 8. Get active session for a user
// ──────────────────────────────────────────────────────
const getActiveSession = async (userId) => {
    return DiningSession.findOne({ 
        $or: [ { userId: userId }, { users: userId } ],
        status: { $in: ['ACTIVE', 'BILL_REQUESTED', 'PAID_WAITING_EXIT'] } 
    })
        .populate('tableId', 'tableNumber capacity qrCode status')
        .lean();
};

// ──────────────────────────────────────────────────────
// 9. Legacy end-session (alias for closeSession)
// ──────────────────────────────────────────────────────
const endSession = closeSession;

// ──────────────────────────────────────────────────────
// 10. Admin: Get all active sessions with table/order info
// ──────────────────────────────────────────────────────
const getActiveSessions = async () => {
    const sessions = await DiningSession.find({ status: { $in: ['ACTIVE', 'BILL_REQUESTED', 'PAID_WAITING_EXIT'] } })
        .populate('tableId', 'tableNumber capacity status qrCode')
        .populate('userId', 'name mobile')
        .populate('users', 'name mobile')
        .populate({ path: 'orders', select: 'totalAmount orderStatus createdAt' })
        .sort({ startTime: -1 })
        .lean();

    const gst_percent = await GET_GST_PERCENT();

    // Dynamically recalculate totals for admin view using the same rounding rule (Requirement 1)
    for (const session of sessions) {
        const activeOrders = (session.orders || []).filter(o => o.status !== 'CANCELLED');
        const session_subtotal = activeOrders.reduce((sum, o) => sum + (parseFloat(o.subtotal || 0) - parseFloat(o.discountAmount || 0)), 0);
        const gst_amount = parseFloat(((session_subtotal * gst_percent) / 100).toFixed(2));
        
        session.subtotal = session_subtotal;
        session.gstPercent = gst_percent;
        session.gstAmount = gst_amount;
        session.totalAmount = Math.round(session_subtotal + gst_amount); // Rounded integer total
    }
    
    return sessions;
};
module.exports = {
    verifyTable,
    startSession,
    placeDiningOrder,
    getSession,
    getBill,
    requestBill,
    verifyDiningPayment,
    closeSession,
    endSession,
    getActiveSession,
    getActiveSessions,
};
