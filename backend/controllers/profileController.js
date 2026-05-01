const User = require('../models/User');

exports.getProfile = async (req, res) => {
    const { user_id } = req.params;
    try {
        const user = await User.findById(user_id).select('-password');
        if (!user) return res.status(404).json({ status: "error", message: "User not found" });
        
        const userData = { ...user._doc, user_id: user._id };
        res.status(200).json({ status: "success", data: userData });
    } catch (error) {
        res.status(500).json({ status: "error", message: error.message });
    }
};

exports.updateProfile = async (req, res) => {
    const { user_id } = req.params;
    const { name, email, mobile } = req.body;
    try {
        await User.findByIdAndUpdate(user_id, { name, email, mobile }, { new: true });
        res.status(200).json({ status: "success", message: "Profile updated successfully" });
    } catch (error) {
        res.status(500).json({ status: "error", message: error.message });
    }
};

/**
 * Toggle item in wishlist
 * POST /api/v1/profile/wishlist/:menuId
 */
exports.toggleWishlist = async (req, res) => {
    const menuId = req.params.menuId;
    const userId = req.user.id; // From authMiddleware
    try {
        const user = await User.findById(userId);
        if (!user) return res.status(404).json({ status: 'error', message: 'User not found' });

        const isFavorite = user.wishlist.includes(menuId);
        if (isFavorite) {
            await User.findByIdAndUpdate(userId, { $pull: { wishlist: menuId } });
            res.json({ status: 'success', message: 'Removed from favorites', isFavorite: false });
        } else {
            await User.findByIdAndUpdate(userId, { $addToSet: { wishlist: menuId } });
            res.json({ status: 'success', message: 'Added to favorites', isFavorite: true });
        }
    } catch (error) {
        res.status(500).json({ status: 'error', message: error.message });
    }
};

/**
 * Get wishlist items
 * GET /api/v1/profile/wishlist
 */
exports.getWishlist = async (req, res) => {
    try {
        const user = await User.findById(req.user.id).populate('wishlist');
        res.json({ status: 'success', data: user.wishlist });
    } catch (error) {
        res.status(500).json({ status: 'error', message: error.message });
    }
};

/**
 * Save FCM token for push notifications
 * POST /api/v1/profile/fcm-token
 * Body: { fcmToken: "..." }
 */
exports.saveFcmToken = async (req, res) => {
    const { fcmToken } = req.body;
    const userId = req.user.id;
    try {
        if (!fcmToken) return res.status(400).json({ status: 'error', message: 'fcmToken required' });
        const fcmService = require('../services/fcmService');
        await fcmService.saveToken(userId, fcmToken);
        res.json({ status: 'success', message: 'FCM token saved' });
    } catch (error) {
        res.status(500).json({ status: 'error', message: error.message });
    }
};

/**
 * Remove FCM token (on logout)
 * DELETE /api/v1/profile/fcm-token
 */
exports.removeFcmToken = async (req, res) => {
    const userId = req.user.id;
    try {
        const fcmService = require('../services/fcmService');
        await fcmService.removeToken(userId);
        res.json({ status: 'success', message: 'FCM token removed' });
    } catch (error) {
        res.status(500).json({ status: 'error', message: error.message });
    }
};

/**
 * DELETE /api/v1/profile/delete-account
 * Permanently deletes the user's account and all associated data.
 */
exports.deleteAccount = async (req, res) => {
    const userId = req.user.id;
    try {
        const user = await User.findById(userId);
        if (!user) {
            return res.status(404).json({ success: false, message: 'User not found' });
        }

        // Delete associated data from other collections
        const mongoose = require('mongoose');

        // Safely delete from collections that only belong specifically to the user's active session state
        // CRITICAL DELETION RULE: NEVER DELETE from 'orders' or 'bookings' because these are permanent financial records for the restaurant's Admin Panel business intelligence.
        const collectionsToClean = ['carts', 'addresses', 'usersettings'];
        for (const col of collectionsToClean) {
            try {
                await mongoose.connection.db.collection(col).deleteMany({ user_id: userId });
            } catch (_) {
                // Collection might not exist — safe to skip
            }
            try {
                await mongoose.connection.db.collection(col).deleteMany({ userId: new mongoose.Types.ObjectId(userId) });
            } catch (_) {}
        }

        // Delete the user document itself
        await User.findByIdAndDelete(userId);

        res.json({ success: true, message: 'Account deleted successfully' });
    } catch (error) {
        res.status(500).json({ success: false, message: error.message });
    }
};
