require('dotenv').config();
const express = require('express');
const http = require('http');
const cors = require('cors');
const helmet = require('helmet');
const rateLimit = require('express-rate-limit');
const mongoSanitize = require('express-mongo-sanitize');
const { initSocket } = require('./socket');

const app = express();

// ── Create HTTP server (needed for Socket.IO) ──
const server = http.createServer(app);

// ── Initialize Socket.IO ──
initSocket(server);

// ── Security Middleware ──
app.use(helmet());                          // Security headers
                   // Prevent NoSQL injection
app.use(cors());                            // Cross-origin support
app.use(express.static('public'));           // Serve static images
app.use('/images', express.static('public/images'));  // Serve uploaded images at /images/

// Rate limiting — 100 requests per 15 minutes per IP
const limiter = rateLimit({
    windowMs: 15 * 60 * 1000,
    max: 5000,
    message: { status: 'error', message: 'Too many requests, please try again later.' },
});
app.use('/api/', limiter);

// ── Body Parsing ──
app.use(express.json({ limit: '10mb' }));
app.use(express.urlencoded({ extended: true }));

// Data sanitization against NoSQL query injection
// Express 5 fix: req.query is read-only, so we sanitize body and params specifically
app.use((req, res, next) => {
    if (req.body) mongoSanitize.sanitize(req.body);
    if (req.params) mongoSanitize.sanitize(req.params);
    next();
});

// ── Database Connection ──
const connectDB = require('./config/db');
connectDB();

// ── Import Routes ──
const authRoutes = require('./routes/authRoutes');
const menuRoutes = require('./routes/menuRoutes');
const cartRoutes = require('./routes/cartRoutes');
const orderRoutes = require('./routes/orderRoutes');
const profileRoutes = require('./routes/profileRoutes');
const paymentRoutes = require('./routes/paymentRoutes');
const addressRoutes = require('./routes/addressRoutes');
const settingsRoutes = require('./routes/settingsRoutes');
const bookingRoutes = require('./routes/bookingRoutes');
const diningRoutes = require('./routes/diningRoutes');
const adminRoutes = require('./routes/adminRoutes');
const tableRoutes = require('./routes/tableRoutes');
const couponRoutes = require('./routes/couponRoutes');
const notificationRoutes = require('./routes/notificationRoutes');
const orderEnhancedRoutes = require('./routes/orderEnhancedRoutes'); // Phase 3-8: Professional order features
const inventoryRoutes = require('./routes/inventoryRoutes');
const razorpayRoutes = require('./routes/razorpayRoutes');

// ── API v1 Routes ──
app.use('/api/v1/auth', authRoutes);
app.use('/api/v1/menu', menuRoutes);
app.use('/api/v1/cart', cartRoutes);
app.use('/api/v1/orders', orderRoutes);
app.use('/api/v1/profile', profileRoutes);
app.use('/api/v1/payment', paymentRoutes);
app.use('/api/v1/addresses', addressRoutes);
app.use('/api/v1/settings', settingsRoutes);
app.use('/api/v1/bookings', bookingRoutes);
app.use('/api/v1/dining', diningRoutes);
app.use('/api/v1/admin', adminRoutes);
app.use('/api/v1/tables', tableRoutes);
app.use('/api/v1/coupons', couponRoutes);
app.use('/api/v1/notifications', notificationRoutes);
app.use('/api/v1/order-enhanced', orderEnhancedRoutes); // Phase 3-8: Professional order features
app.use('/api/v1/inventory', inventoryRoutes);
app.use('/api/v1/razorpay', razorpayRoutes);

// ── Backward compatibility: old /api/ routes still work ──
app.use('/api/auth', authRoutes);
app.use('/api/menu', menuRoutes);
app.use('/api/cart', cartRoutes);
app.use('/api/orders', orderRoutes);
app.use('/api/profile', profileRoutes);
app.use('/api/payment', paymentRoutes);
app.use('/api/tables', diningRoutes);            // Old table routes → dining
app.use('/api/addresses', addressRoutes);
app.use('/api/settings', settingsRoutes);
app.use('/api/bookings', bookingRoutes);

// ── Health Check ──
app.get('/', (req, res) => {
    res.send({
        status: 'success',
        message: 'Govardhan Thal Backend API is running.',
        version: 'v1',
        features: ['REST API', 'Socket.IO Real-Time'],
        timestamp: new Date().toISOString(),
    });
});

// ── Central Error Handler (must be last) ──
const errorHandler = require('./middleware/errorMiddleware');
app.use(errorHandler);

// ── Start Server (use `server.listen` for Socket.IO) ──
const PORT = process.env.PORT || 3000;
server.listen(PORT, () => {
    console.log(`🚀 Server is running on port ${PORT}`);
    console.log(`📡 API Base URL: http://localhost:${PORT}/api/v1`);
    console.log(`⚡ Socket.IO ready for real-time connections`);
}).on('error', (err) => {
    if (err.code === 'EADDRINUSE') {
        process.stdout.write(`\n❌ Error: Port ${PORT} is already in use.\n👉 Please wait 5 seconds and try again, or run: npm run predev\n\n`);
        process.exit(1);
    } else {
        throw err;
    }
});
