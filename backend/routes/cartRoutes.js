const express = require('express');
const router = express.Router();
const cartController = require('../controllers/cartController');
const { authMiddleware } = require('../middleware/authMiddleware');
const validate = require('../middleware/validateRequest');

// All cart routes require authentication
router.use(authMiddleware);

// GET user's cart
router.get('/', cartController.getCart);

// POST add item to cart
router.post('/add', validate.addToCart, cartController.addToCart);

// PUT update item quantity
router.put('/item/:menuId', cartController.updateQuantity);

// DELETE remove single item from cart
router.delete('/item/:menuId', cartController.removeFromCart);

// DELETE clear entire cart
router.delete('/', cartController.clearCart);

module.exports = router;
