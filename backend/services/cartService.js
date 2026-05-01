/**
 * Cart Service — Business logic for cart operations.
 * Uses single-document-per-user pattern with embedded items array.
 */
const Cart = require('../models/Cart');
const Menu = require('../models/Menu');

/**
 * Get user's cart with populated menu item details
 */
const getCart = async (userId) => {
    let cart = await Cart.findOne({ userId }).populate('items.menuId', 'name imageUrl category isVeg');
    if (!cart) {
        cart = await Cart.create({ userId, items: [] });
    }

    // Format response
    const formattedItems = cart.items.map((item) => ({
        cart_item_id: item._id,
        menu_id: item.menuId?._id || item.menuId,
        name: item.menuId?.name || 'Item',
        image_url: item.menuId?.imageUrl || '',
        category: item.menuId?.category || '',
        is_veg: item.menuId?.isVeg ?? true,
        quantity: item.quantity,
        price: item.price,
        subtotal: item.price * item.quantity,
    }));

    return {
        items: formattedItems,
        totalPrice: cart.totalPrice,
        itemCount: cart.items.reduce((sum, i) => sum + i.quantity, 0),
    };
};

/**
 * Add or increment item in cart
 */
const addItem = async (userId, menuId, quantity = 1) => {
    // Validate menu item exists and is available
    const menuItem = await Menu.findById(menuId);
    if (!menuItem || menuItem.isDeleted || !menuItem.isAvailable) {
        throw Object.assign(new Error('Menu item not available'), { statusCode: 400 });
    }

    let cart = await Cart.findOne({ userId });
    if (!cart) {
        cart = await Cart.create({ userId, items: [] });
    }

    // Check if item already exists in cart
    const existingIndex = cart.items.findIndex(
        (item) => item.menuId.toString() === menuId.toString()
    );

    if (existingIndex >= 0) {
        // Increment quantity
        cart.items[existingIndex].quantity += quantity;
    } else {
        // Add new item
        cart.items.push({ menuId, quantity, price: menuItem.price });
    }

    await cart.save();
    return cart;
};

/**
 * Remove item from cart by menuId
 */
const removeItem = async (userId, menuId) => {
    const cart = await Cart.findOne({ userId });
    if (!cart) throw Object.assign(new Error('Cart not found'), { statusCode: 404 });

    cart.items = cart.items.filter((item) => item.menuId.toString() !== menuId.toString());
    await cart.save();
    return cart;
};

/**
 * Update item quantity in cart
 */
const updateQuantity = async (userId, menuId, quantity) => {
    const cart = await Cart.findOne({ userId });
    if (!cart) throw Object.assign(new Error('Cart not found'), { statusCode: 404 });

    const item = cart.items.find((i) => i.menuId.toString() === menuId.toString());
    if (!item) throw Object.assign(new Error('Item not in cart'), { statusCode: 404 });

    if (quantity <= 0) {
        // Remove item if quantity is 0 or less
        cart.items = cart.items.filter((i) => i.menuId.toString() !== menuId.toString());
    } else {
        item.quantity = quantity;
    }

    await cart.save();
    return cart;
};

/**
 * Clear all items from cart
 */
const clearCart = async (userId) => {
    const cart = await Cart.findOne({ userId });
    if (cart) {
        cart.items = [];
        await cart.save();
    }
    return { message: 'Cart cleared' };
};

module.exports = { getCart, addItem, removeItem, updateQuantity, clearCart };
