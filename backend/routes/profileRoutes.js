const express = require('express');
const router = express.Router();
const profileController = require('../controllers/profileController');

const { authMiddleware } = require('../middleware/authMiddleware');

router.get('/:user_id', authMiddleware, profileController.getProfile);
router.put('/:user_id', authMiddleware, profileController.updateProfile);

// Wishlist routes
router.post('/wishlist/:menuId', authMiddleware, profileController.toggleWishlist);
router.get('/wishlist/all', authMiddleware, profileController.getWishlist);

// FCM Token routes
router.post('/fcm-token', authMiddleware, profileController.saveFcmToken);
router.delete('/fcm-token', authMiddleware, profileController.removeFcmToken);

// Account deletion
router.delete('/delete-account', authMiddleware, profileController.deleteAccount);

module.exports = router;
