require('dotenv').config();
const mongoose = require('mongoose');
const bcrypt = require('bcryptjs');
const Admin = require('./models/Admin');
const connectDB = require('./config/db');

async function ensureAdmin() {
  try {
    await connectDB();
    
    await Admin.deleteMany({}); // Wipe out any weird old admin accounts
    
    const salt = await bcrypt.genSubtle ? await bcrypt.genSalt(10) : await bcrypt.genSalt(10);
    const hashedPassword = await bcrypt.hash('admin123', salt);
    
    const newAdmin = new Admin({
      name: 'Restaurant Admin',
      email: 'admin@govardhanthal.com',
      password: hashedPassword,
      role: 'admin'
    });
    await newAdmin.save();
    console.log('✅ FRESH ADMIN ACCOUNT CREATED!');
    console.log('Email: admin@govardhanthal.com');
    console.log('Password: admin123');
  } catch (err) {
    console.error('Error:', err);
  } finally {
    process.exit(0);
  }
}

ensureAdmin();
