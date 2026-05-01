/**
 * Table Seed Script — Creates 5 restaurant tables with QR codes.
 * Run: node backend/seedTables.js
 *
 * QR Code format stored in DB: TABLE_QR_T01, TABLE_QR_T02, etc.
 * Flutter app sends this string when scanning the QR code.
 *
 * Sample QR data to encode in physical QR codes:
 *   TABLE_QR_T01  → Table 1
 *   TABLE_QR_T02  → Table 2
 *   TABLE_QR_T03  → Table 3
 *   TABLE_QR_T04  → Table 4
 *   TABLE_QR_T05  → Table 5
 */
require('dotenv').config();
const mongoose = require('mongoose');
const Table    = require('./models/Table');

const tables = [
    { tableNumber: 1, capacity: 2, qrCode: 'TABLE_QR_T01', status: 'AVAILABLE' },
    { tableNumber: 2, capacity: 4, qrCode: 'TABLE_QR_T02', status: 'AVAILABLE' },
    { tableNumber: 3, capacity: 4, qrCode: 'TABLE_QR_T03', status: 'AVAILABLE' },
    { tableNumber: 4, capacity: 6, qrCode: 'TABLE_QR_T04', status: 'AVAILABLE' },
    { tableNumber: 5, capacity: 6, qrCode: 'TABLE_QR_T05', status: 'AVAILABLE' },
];

async function seedTables() {
    try {
        await mongoose.connect(process.env.MONGO_URI);
        console.log('✅ Connected to MongoDB');

        for (const t of tables) {
            const existing = await Table.findOne({ tableNumber: t.tableNumber });
            if (existing) {
                // Update qrCode if needed
                existing.qrCode   = t.qrCode;
                existing.capacity = t.capacity;
                await existing.save();
                console.log(`🔄 Updated Table #${t.tableNumber}`);
            } else {
                await Table.create(t);
                console.log(`✅ Created Table #${t.tableNumber} — QR: ${t.qrCode}`);
            }
        }

        console.log('\n📋 All Tables:');
        const all = await Table.find().sort({ tableNumber: 1 }).lean();
        all.forEach(t => {
            console.log(`  Table #${t.tableNumber} | Cap: ${t.capacity} | Status: ${t.status} | QR: ${t.qrCode}`);
        });

        console.log('\n🔑 Sample QR codes to encode (use any QR generator):');
        tables.forEach(t => {
            console.log(`  Table ${t.tableNumber}: ${t.qrCode}`);
        });

    } catch (err) {
        console.error('❌ Seed error:', err);
    } finally {
        await mongoose.disconnect();
        console.log('\n🔌 Disconnected from MongoDB');
    }
}

seedTables();
