const mongoose = require('mongoose');
const bcrypt = require('bcryptjs');
const Menu = require('../models/Menu');
const Table = require('../models/Table');
const User = require('../models/User');
const Admin = require('../models/Admin');
const GlobalSettings = require('../models/GlobalSettings');

const connectDB = async () => {

    try {
        await mongoose.connect(process.env.MONGO_URI || 'mongodb://localhost:27017/govardhan_thal');
        console.log('✅ Connected to MongoDB Server');
        await seedDatabase();
    } catch (error) {
        console.error('❌ MongoDB Connection Failed:', error.message);
        console.error('👉 Please check if your IP is whitelisted in MongoDB Atlas or if local DB is running.');
        // Do not exit process, let the server stay alive for diagnostics
    }
};

const seedDatabase = async () => {
    try {
        // ── Seed Menu Items ──
        const menuCount = await Menu.countDocuments();
        if (menuCount === 0) {
            console.log("🌱 Seeding Gujarati Menu...");
            const menuItems = [
                // --- THALI ---
                { name: 'Premium Gujarati Thali', category: 'Thali', description: 'Complete authentic meal with 3 Roti, 2 Sabzi, Dal, Bhaat, Farsan, Sweet, Chaas.', price: 349.00, imageUrl: 'https://images.unsplash.com/photo-1585937421612-70a008356fbe?w=400&fit=crop', isVeg: true, rating: 4.8, isPopular: true, isRecommended: true },
                { name: 'Kathiyawadi Thali', category: 'Thali', description: 'Spicy regional thali with Bajra Rotla, Sev Tameta, Ringan no Olo, Chaas.', price: 299.00, imageUrl: 'https://images.unsplash.com/photo-1546833999-b9f581a1996d?w=400&fit=crop', isVeg: true, rating: 4.6, isPopular: true },
                { name: 'Jain Thali', category: 'Thali', description: 'Pure Jain preparation with no onion/garlic. Roti, 2 Jain Sabzi, Dal, Bhaat.', price: 279.00, imageUrl: 'https://images.unsplash.com/photo-1567337710282-00832b415979?w=400&fit=crop', isVeg: true, rating: 4.5 },
                { name: 'Mini Thali', category: 'Thali', description: 'Lighter portion with 2 Roti, 1 Sabzi, Dal, Rice and Chaas.', price: 199.00, imageUrl: 'https://images.unsplash.com/photo-1631452180519-c014fe946bc7?w=400&fit=crop', isVeg: true, rating: 4.3, isRecommended: true },
                // --- FARSAN ---
                { name: 'Khaman Dhokla', category: 'Farsan', description: 'Soft, spongy Gujarati snack made from besan, tempered with mustard seeds and curry leaves.', price: 90.00, imageUrl: 'https://images.unsplash.com/photo-1589302168068-964664d93dc0?w=400&fit=crop', isVeg: true, rating: 4.7, isPopular: true },
                { name: 'Khandvi', category: 'Farsan', description: 'Thin, rolled besan layers tempered with mustard seeds and coconut.', price: 110.00, imageUrl: 'https://images.unsplash.com/photo-1567337710282-00832b415979?w=400&fit=crop', isVeg: true, rating: 4.5, isRecommended: true },
                { name: 'Patra', category: 'Farsan', description: 'Colocasia leaves coated with spiced besan paste, rolled and steamed.', price: 120.00, imageUrl: 'https://images.unsplash.com/photo-1601050633647-81a35d377f86?w=400&fit=crop', isVeg: true, rating: 4.4 },
                { name: 'Fafda Jalebi', category: 'Farsan', description: 'Crispy gram flour strips served with sweet jalebi and green chutney.', price: 80.00, imageUrl: 'https://images.unsplash.com/photo-1589301760014-d929f3979dbc?w=400&fit=crop', isVeg: true, rating: 4.6, isPopular: true },
                // --- SABZI ---
                { name: 'Undhiyu', category: 'Sabzi', description: 'Surti mixed vegetable specialty with muthiya, seasonal vegetables, and spices.', price: 199.00, imageUrl: 'https://images.unsplash.com/photo-1512058564366-18510be2db19?w=400&fit=crop', isVeg: true, rating: 4.7, isRecommended: true },
                { name: 'Sev Tameta Nu Shaak', category: 'Sabzi', description: 'Sweet and spicy tomato curry topped with crispy besan sev.', price: 160.00, imageUrl: 'https://images.unsplash.com/photo-1565557623262-b51c2513a641?w=400&fit=crop', isVeg: true, rating: 4.4 },
                { name: 'Ringan no Olo', category: 'Sabzi', description: 'Roasted eggplant mash with garlic, onion, and fresh coriander.', price: 140.00, imageUrl: 'https://images.unsplash.com/photo-1589113883398-75c1a700142e?w=400&fit=crop', isVeg: true, rating: 4.3 },
                // --- BREADS ---
                { name: 'Phulka Roti (4 pcs)', category: 'Breads', description: 'Soft whole wheat flatbreads puffed on open flame, served with ghee.', price: 40.00, imageUrl: 'https://images.unsplash.com/photo-1565557623262-b51c2513a641?w=400&fit=crop', isVeg: true, rating: 4.5 },
                { name: 'Bajra Rotla (2 pcs)', category: 'Breads', description: 'Millet flatbread, traditionally hand-pressed. Served with white butter.', price: 50.00, imageUrl: 'https://images.unsplash.com/photo-1541518763669-279f00ed51ca?w=400&fit=crop', isVeg: true, rating: 4.4 },
                { name: 'Methi Thepla (4 pcs)', category: 'Breads', description: 'Fenugreek spiced flatbread. Perfect for travel or a light meal.', price: 60.00, imageUrl: 'https://images.unsplash.com/photo-1568901346375-23c9450c58cd?w=400&fit=crop', isVeg: true, rating: 4.6, isPopular: true },
                // --- SWEETS ---
                { name: 'Aamras', category: 'Sweets', description: 'Sweet, creamy mango pulp served chilled. Seasonal delicacy.', price: 140.00, imageUrl: 'https://images.unsplash.com/photo-1505253304418-45b4ec10e5bb?w=400&fit=crop', isVeg: true, rating: 4.8, isPopular: true },
                { name: 'Basundi', category: 'Sweets', description: 'Rich condensed milk dessert with cardamom and nuts.', price: 120.00, imageUrl: 'https://images.unsplash.com/photo-1631452180519-c014fe946bc7?w=400&fit=crop', isVeg: true, rating: 4.5, isRecommended: true },
                { name: 'Gulab Jamun (2 pcs)', category: 'Sweets', description: 'Deep-fried milk dumplings soaked in sugar syrup with rose water.', price: 80.00, imageUrl: 'https://images.unsplash.com/photo-1666190070960-0bd6e4869760?w=400&fit=crop', isVeg: true, rating: 4.6 },
                // --- DRINKS ---
                { name: 'Masala Chaas', category: 'Drinks', description: 'Spiced buttermilk with cumin, mint, and a pinch of salt.', price: 40.00, imageUrl: 'https://images.unsplash.com/photo-1461023058943-07fcbe16d735?w=400&fit=crop', isVeg: true, rating: 4.7, isPopular: true },
                { name: 'Mango Lassi', category: 'Drinks', description: 'Creamy yogurt blended with ripe Alphonso mango. Thick and refreshing.', price: 80.00, imageUrl: 'https://images.unsplash.com/photo-1553530666-ba11a7da3888?w=400&fit=crop', isVeg: true, rating: 4.8, isRecommended: true },
                { name: 'Fresh Lime Soda', category: 'Drinks', description: 'Sweet or salty — freshly squeezed lime with soda water.', price: 50.00, imageUrl: 'https://images.unsplash.com/photo-1556881286-fc6915169721?w=400&fit=crop', isVeg: true, rating: 4.3 },
            ];
            await Menu.insertMany(menuItems);
            console.log(`✅ Seeded ${menuItems.length} Gujarati menu items.`);
        }

        // ── Seed Dining Tables ──
        const tableCount = await Table.countDocuments();
        if (tableCount === 0) {
            console.log("🌱 Seeding dining tables...");
            const tables = [
                { tableNumber: 1, qrCode: 'TABLE_QR_001', capacity: 4 },
                { tableNumber: 2, qrCode: 'TABLE_QR_002', capacity: 2 },
                { tableNumber: 3, qrCode: 'TABLE_QR_003', capacity: 6 },
                { tableNumber: 4, qrCode: 'TABLE_QR_004', capacity: 4 },
                { tableNumber: 5, qrCode: 'TABLE_QR_005', capacity: 8 },
                { tableNumber: 6, qrCode: 'TABLE_QR_006', capacity: 2 },
            ];
            await Table.insertMany(tables);
            console.log("✅ Seeded 6 dining tables.");
        }

        // ── Seed Admin User ──
        const adminCount = await User.countDocuments({ role: 'admin' });
        if (adminCount === 0) {
            console.log("🌱 Seeding admin user...");
            const hashedPassword = await bcrypt.hash('admin123', 10);
            await User.create({
                name: 'Admin',
                email: 'admin@govardhanthal.com',
                mobile: '9999999999',
                password: hashedPassword,
                role: 'admin',
                loginType: 'mobile',
            });
            console.log("✅ Seeded admin user (admin@govardhanthal.com / admin123).");
        }

        // ── Seed Admin Collection (separate from User, for admin-login endpoint) ──
        const adminCollectionCount = await Admin.countDocuments();
        if (adminCollectionCount === 0) {
            console.log("🌱 Seeding Admin collection...");
            const hashedPassword = await bcrypt.hash('admin123', 10);
            await Admin.create({
                name: 'Super Admin',
                email: 'admin@govardhanthal.com',
                password: hashedPassword,
                role: 'admin',
            });
            console.log("✅ Seeded Admin collection (admin@govardhanthal.com / admin123).");
        }

        // ── Seed Global Settings (Requirement 4) ──
        const gstSetting = await GlobalSettings.findOne({ key: 'GST_PERCENT' });
        if (!gstSetting) {
            console.log("🌱 Seeding Global GST Setting (5%)...");
            await GlobalSettings.create({
                key: 'GST_PERCENT',
                value: 5.0,
                description: 'GST Percentage for all dining bills'
            });
            console.log("✅ Seeded GST_PERCENT: 5.0");
        }
    } catch (e) {

        console.error("❌ Error seeding database:", e);
    }
};

module.exports = connectDB;
