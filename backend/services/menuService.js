/**
 * Menu Service — Production-ready business logic for menu operations.
 * Supports pagination, search, filtering by category/popular/recommended/todaySpecial, and soft delete.
 */
const Menu = require('../models/Menu');

// Generic fallback (keyword-based Unsplash)
const DEFAULT_IMAGE = 'https://source.unsplash.com/600x400/?indian,food';
const INR_TO_SGD   = 0.016;

/** Build the resolved image URL — stored URL wins, else keyword dynamic URL, else generic fallback */
const resolveImage = (item) => {
    if (item.imageUrl && item.imageUrl.trim()) return item.imageUrl.trim();
    const kw = (item.imageKeyword || 'indian,food').trim();
    return `https://source.unsplash.com/600x400/?${encodeURIComponent(kw)}`;
};

/**
 * Sanitize a single menu item.
 * Computes priceSGD and image resolution inline — no dependency on lean virtuals.
 */
const formatItem = (item) => {
    const imgUrl = resolveImage(item);
    return {
        _id:               item._id,
        menu_id:           item._id,
        name:              item.name,
        category:          item.category,
        description:       item.description,
        price:             item.price,
        priceINR:          item.price,
        priceSGD:          +(item.price * INR_TO_SGD).toFixed(2),
        image_url:         imgUrl,
        imageUrl:          imgUrl,
        imageURL:          imgUrl,
        imageKeyword:      item.imageKeyword || 'indian,food',
        isVeg:             item.isVeg,
        rating:            item.rating,
        isAvailable:       item.isAvailable,
        isPopular:         item.isPopular,
        isRecommended:     item.isRecommended,
        isTodaySpecial:    item.isTodaySpecial,
        // Legacy snake_case aliases (backward compat)
        is_veg:            item.isVeg,
        is_available:      item.isAvailable,
        is_popular:        item.isPopular,
        is_recommended:    item.isRecommended,
        is_today_special:  item.isTodaySpecial,
    };
};

/**
 * Get menu items with pagination, category filter, popular/recommended/todaySpecial filters, and text search.
 * @param {object} options - { category, search, popular, recommended, todaySpecial, page, limit }
 */
const getMenu = async ({
    category, search, popular, recommended, todaySpecial, page = 1, limit = 100
} = {}) => {
    const query = { isAvailable: true, isDeleted: false };

    // Case-insensitive category match
    if (category) {
        query.category = { $regex: new RegExp(`^${category}$`, 'i') };
    }
    if (popular === 'true'      || popular === true)         query.isPopular = true;
    if (recommended === 'true'  || recommended === true)     query.isRecommended = true;
    if (todaySpecial === 'true' || todaySpecial === true)    query.isTodaySpecial = true;

    // Text search across name & description
    if (search) {
        query.$or = [
            { name:        { $regex: search, $options: 'i' } },
            { description: { $regex: search, $options: 'i' } },
        ];
    }

    const skip  = (Number(page) - 1) * Number(limit);
    const total = await Menu.countDocuments(query);
    const items = await Menu.find(query)
        .sort({ isTodaySpecial: -1, isPopular: -1, isRecommended: -1, category: 1, name: 1 })
        .skip(skip)
        .limit(Number(limit))
        .lean({ virtuals: true });

    return { items: items.map(formatItem), total, page: Number(page), limit: Number(limit) };
};

/**
 * Get today's specials (convenience shortcut)
 */
const getTodaySpecials = async () => {
    const items = await Menu.find({ isTodaySpecial: true, isAvailable: true, isDeleted: false })
        .sort({ rating: -1 })
        .lean({ virtuals: true });
    return items.map(formatItem);
};

/**
 * Get popular items
 */
const getPopularItems = async (limit = 10) => {
    const items = await Menu.find({ isPopular: true, isAvailable: true, isDeleted: false })
        .sort({ rating: -1 })
        .limit(limit)
        .lean({ virtuals: true });
    return items.map(formatItem);
};

/**
 * Get distinct categories (only from available, non-deleted items)
 */
const getCategories = async () => {
    return Menu.distinct('category', { isAvailable: true, isDeleted: false });
};

/**
 * Get single menu item by ID (includes virtuals)
 */
const getById = async (id) => {
    if (!id || id === 'null') return null;
    const item = await Menu.findById(id).lean({ virtuals: true });
    if (!item || item.isDeleted) return null;
    return formatItem(item);
};

/**
 * Get recommended items
 */
const getRecommended = async (limit = 10) => {
    const items = await Menu.find({ isRecommended: true, isAvailable: true, isDeleted: false })
        .sort({ rating: -1 })
        .limit(limit)
        .lean({ virtuals: true });
    return items.map(formatItem);
};

/**
 * Create a new menu item (Admin)
 * - If imageUrl is not provided, leave it blank so resolvedImageUrl virtual uses imageKeyword.
 * - imageKeyword defaults to 'indian,food' if not supplied.
 */
const create = async (data) => {
    if (!data.imageKeyword) data.imageKeyword = 'indian,food';
    // Mapping aliases for findByIdAndUpdate-compatible objects
    if (data.imageURL !== undefined) data.imageUrl = data.imageURL;
    if (data.priceINR !== undefined) data.price    = data.priceINR;
    
    // Don't force a hard-coded fallback — the model virtual handles it via keyword
    if (data.imageUrl === undefined) data.imageUrl = '';
    const item = await Menu.create(data);
    const created = await Menu.findById(item._id).lean({ virtuals: true });
    return formatItem(created);
};

/**
 * Update a menu item (Admin)
 * Supports: imageUrl upload, imageKeyword change, isPopular, isTodaySpecial, category edits.
 * - Clearing imageUrl ('') falls back gracefully to keyword Unsplash URL.
 */
const update = async (id, data) => {
    // ID validation to prevent crashes for "null" or invalid IDs
    if (!id || id === 'null') return null;
    
    // Mapping aliases for findByIdAndUpdate-compatible objects
    if (data.imageURL !== undefined) data.imageUrl = data.imageURL;
    if (data.priceINR !== undefined) data.price    = data.priceINR;

    // Allow clearing imageUrl — virtual will fall back to keyword URL
    if (data.imageUrl === null) data.imageUrl = '';
    const item = await Menu.findByIdAndUpdate(
        id, data, { new: true, runValidators: true }
    ).lean({ virtuals: true });
    return item ? formatItem(item) : null;
};

/**
 * Soft delete a menu item (Admin) — sets isDeleted=true
 */
const softDelete = async (id) => {
    if (!id || id === 'null') return null;
    return Menu.findByIdAndUpdate(id, { isDeleted: true, isAvailable: false }, { new: true });
};

module.exports = { getMenu, getTodaySpecials, getPopularItems, getRecommended, getCategories, getById, create, update, softDelete };
