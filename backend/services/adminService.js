/**
 * Admin Service — Business logic for admin dashboard & analytics.
 */
const Order = require('../models/Order');
const Table = require('../models/Table');
const Booking = require('../models/Booking');
const Menu = require('../models/Menu');
const User = require('../models/User');
const DiningSession = require('../models/DiningSession');

/**
 * Get dashboard analytics
 */
const getDashboard = async () => {
    const today = new Date();
    today.setHours(0, 0, 0, 0);

    const [
        totalRevenueAggregate,
        todayRevenueAggregate,
        totalOrdersToday,
        activeTables,
        pendingBookings,
        menuCount,
        totalUsers,
        newUsersToday,
        pendingOrders,
        onlineOrders,
        diningOrders,
        takeawayOrders,
    ] = await Promise.all([
        Order.aggregate([
            { $match: { orderStatus: 'COMPLETED' } },
            { $group: { _id: null, total: { $sum: '$totalAmount' } } },
        ]),
        Order.aggregate([
            { $match: { orderStatus: 'COMPLETED', createdAt: { $gte: today } } },
            { $group: { _id: null, total: { $sum: '$totalAmount' } } },
        ]),
        Order.countDocuments({ createdAt: { $gte: today } }),
        Table.countDocuments({ status: { $ne: 'AVAILABLE' } }), // Any occupied table
        Booking.countDocuments({ status: 'PENDING' }),
        Menu.countDocuments({ isAvailable: true, isDeleted: false }),
        User.countDocuments(),
        User.countDocuments({ createdAt: { $gte: today } }),
        Order.countDocuments({ orderStatus: { $in: ['ORDERED', 'PREPARING'] } }),
        Order.countDocuments({ orderType: 'ONLINE' }),
        Order.countDocuments({ orderType: 'DINING' }),
        Order.countDocuments({ orderType: 'TAKEAWAY' }),
    ]);

    // Calculate revenue history (7 days trailing)
    const sevenDaysAgo = new Date();
    sevenDaysAgo.setDate(sevenDaysAgo.getDate() - 6);
    sevenDaysAgo.setHours(0, 0, 0, 0);

    const revenuePerDay = await Order.aggregate([
        { $match: { orderStatus: 'COMPLETED', createdAt: { $gte: sevenDaysAgo } } },
        {
            $group: {
                _id: { $dayOfWeek: "$createdAt" }, // 1: Sun, 2: Mon, etc.
                revenue: { $sum: "$totalAmount" }
            }
        }
    ]);

    const daysMap = ["Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat"];
    // Build a 7-day array up to today
    const revenueHistory = [];
    for (let i = 6; i >= 0; i--) {
        const d = new Date();
        d.setDate(d.getDate() - i);
        const dayIdx = d.getDay(); // 0: Sun ... 6: Sat
        const dayName = daysMap[dayIdx];
        
        const found = revenuePerDay.find(r => r._id === dayIdx + 1);
        revenueHistory.push({
            name: dayName,
            revenue: found ? found.revenue : 0
        });
    }

    return {
        totalRevenue: totalRevenueAggregate[0]?.total || 0,
        revenueToday: todayRevenueAggregate[0]?.total || 0,
        totalOrdersToday,
        activeTables,
        pendingBookings,
        menuCount,
        totalUsers,
        newUsersToday,
        pendingOrders,
        onlineOrders,
        diningOrders,
        takeawayOrders,
        revenueHistory
    };
};
/**
 * Get all users (Admin)
 */
const getUsers = async ({ page = 1, limit = 20 } = {}) => {
    const skip = (Number(page) - 1) * Number(limit);
    const total = await User.countDocuments();
    
    const users = await User.aggregate([
        { $sort: { createdAt: -1 } },
        { $skip: skip },
        { $limit: Number(limit) },
        {
            $lookup: {
                from: 'orders',
                localField: '_id',
                foreignField: 'userId',
                as: 'userOrders'
            }
        },
        {
            $project: {
                password: 0,
                refreshToken: 0,
                orderCount: { $size: '$userOrders' },
                lastOrderDate: { $max: '$userOrders.createdAt' },
                name: 1,
                email: 1,
                mobile: 1,
                profileUrl: 1,
                createdAt: 1,
                updatedAt: 1,
                role: 1
            }
        }
    ]);

    return { users, total, page: Number(page), limit: Number(limit) };
};

module.exports = { getDashboard, getUsers };
