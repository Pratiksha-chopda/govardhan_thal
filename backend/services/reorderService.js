/**
 * Reorder Service — Phase 8
 * 
 * Allows customers to re-order items from a previous order.
 * Reuses existing Cart model — does NOT modify cartService.js.
 */
const Order = require('../models/Order');
const Menu = require('../models/Menu');
const Cart = require('../models/Cart');

/**
 * Reorder items from a previous order.
 * Checks each item's current availability before adding to cart.
 * 
 * @param {string} orderId - The previous order to reorder from
 * @param {string} userId - The authenticated user
 * @returns {{ addedItems: Array, unavailableItems: Array, cartItemCount: number }}
 */
const reorder = async (orderId, userId) => {
    try {
        // 1. Find the previous order
        const previousOrder = await Order.findOne({ _id: orderId, userId })
            .populate('items.menuId', 'name price isDeleted isAvailable')
            .lean();

        if (!previousOrder) {
            throw Object.assign(new Error('Order not found or does not belong to you'), { statusCode: 404 });
        }

        const addedItems = [];
        const unavailableItems = [];

        // 2. Check each item's current availability
        for (const item of previousOrder.items) {
            const menuItem = await Menu.findById(item.menuId?._id || item.menuId).lean();

            if (!menuItem || menuItem.isDeleted || menuItem.isAvailable === false) {
                unavailableItems.push({
                    name: item.name || menuItem?.name || 'Unknown Item',
                    reason: !menuItem ? 'Item no longer exists' : menuItem.isDeleted ? 'Item has been removed' : 'Currently unavailable',
                });
                continue;
            }

            addedItems.push({
                menuId: menuItem._id,
                name: menuItem.name,
                quantity: item.quantity,
                price: menuItem.price, // Use current price, not old price
            });
        }

        // 3. Add available items to cart (using Cart model directly, not modifying cartService)
        if (addedItems.length > 0) {
            let cart = await Cart.findOne({ userId });
            if (!cart) {
                cart = await Cart.create({ userId, items: [] });
            }

            for (const item of addedItems) {
                // Check if item already exists in cart
                const existingIdx = cart.items.findIndex(
                    (ci) => ci.menuId.toString() === item.menuId.toString()
                );

                if (existingIdx >= 0) {
                    // Increment quantity
                    cart.items[existingIdx].quantity += item.quantity;
                } else {
                    // Add new item
                    cart.items.push({
                        menuId: item.menuId,
                        quantity: item.quantity,
                        price: item.price,
                    });
                }
            }

            await cart.save();
        }

        // 4. Get updated cart count
        const updatedCart = await Cart.findOne({ userId }).lean();
        const cartItemCount = updatedCart ? updatedCart.items.reduce((sum, i) => sum + i.quantity, 0) : 0;

        return {
            addedItems,
            unavailableItems,
            cartItemCount,
            message: unavailableItems.length > 0
                ? `${addedItems.length} items added to cart. ${unavailableItems.length} items are no longer available.`
                : `All ${addedItems.length} items added to cart successfully!`,
        };
    } catch (error) {
        throw error;
    }
};

module.exports = { reorder };
