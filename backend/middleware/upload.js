/**
 * Multer Cloudinary Upload Middleware — Handles file uploads for menu images.
 * Replaces local disk storage with Cloudinary storage.
 */
const { upload } = require('../config/cloudinary');

module.exports = upload;
