/**
 * Cart Controller — Handles cart endpoints.
 * Gets userId from JWT token (req.user.id).
 */
const cartService = require('../services/cartService');
const asyncHandler = require('../utils/asyncHandler');
const { sendSuccess } = require('../utils/responseHelper');

/**
 * GET /api/v1/cart
 * Get authenticated user's cart
 */
exports.getCart = asyncHandler(async (req, res) => {
    const cart = await cartService.getCart(req.user.id);
    sendSuccess(res, cart);
});

/**
 * POST /api/v1/cart/add
 * Body: { menuId, quantity }
 */
exports.addToCart = asyncHandler(async (req, res) => {
    const { menuId, quantity } = req.body;
    await cartService.addItem(req.user.id, menuId, quantity || 1);
    const cart = await cartService.getCart(req.user.id);
    sendSuccess(res, cart, 'Item added to cart', 201);
});

/**
 * DELETE /api/v1/cart/item/:menuId
 * Remove specific item from cart
 */
exports.removeFromCart = asyncHandler(async (req, res) => {
    await cartService.removeItem(req.user.id, req.params.menuId);
    const cart = await cartService.getCart(req.user.id);
    sendSuccess(res, cart, 'Item removed from cart');
});

/**
 * PUT /api/v1/cart/item/:menuId
 * Body: { quantity }
 */
exports.updateQuantity = asyncHandler(async (req, res) => {
    await cartService.updateQuantity(req.user.id, req.params.menuId, req.body.quantity);
    const cart = await cartService.getCart(req.user.id);
    sendSuccess(res, cart, 'Cart updated');
});

/**
 * DELETE /api/v1/cart
 * Clear entire cart
 */
exports.clearCart = asyncHandler(async (req, res) => {
    await cartService.clearCart(req.user.id);
    sendSuccess(res, null, 'Cart cleared');
});
