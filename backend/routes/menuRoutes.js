const express = require('express');
const router = express.Router();
const menuController = require('../controllers/menuController');
const { authMiddleware, adminMiddleware } = require('../middleware/authMiddleware');

// ── Public Routes ─────────────────────────────────────────────────────────────

// GET all menu items — ?category=&search=&popular=&recommended=&todaySpecial=&page=&limit=
router.get('/', menuController.getMenu);

// GET distinct categories (must be before /:id or it gets swallowed)
router.get('/categories', menuController.getCategories);

// GET today's specials
router.get('/today-specials', menuController.getTodaySpecials);

// GET popular items — ?limit=10
router.get('/popular', menuController.getPopularItems);

// GET recommended items — ?limit=10
router.get('/recommended', menuController.getRecommended);

// GET single menu item by ID
router.get('/:id', menuController.getMenuById);

const { upload } = require('../config/cloudinary');

// ── Admin Routes ──────────────────────────────────────────────────────────────
router.post('/',    authMiddleware, adminMiddleware, upload.single('image'), menuController.createMenu);
router.put('/:id',  authMiddleware, adminMiddleware, upload.single('image'), menuController.updateMenu);
router.delete('/:id', authMiddleware, adminMiddleware, menuController.deleteMenu);

module.exports = router;
