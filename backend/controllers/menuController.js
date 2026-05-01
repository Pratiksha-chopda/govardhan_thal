/**
 * Menu Controller — Handles menu endpoints.
 * Endpoints:
 *   GET /api/v1/menu                — All menu items (paginated, filterable)
 *   GET /api/v1/menu/categories     — Distinct categories
 *   GET /api/v1/menu/today-specials — Today's specials
 *   GET /api/v1/menu/popular        — Popular items
 *   GET /api/v1/menu/recommended    — Recommended items
 *   GET /api/v1/menu/:id            — Single item
 *   POST /api/v1/menu               — Create (Admin)
 *   PUT  /api/v1/menu/:id           — Update (Admin)
 *   DELETE /api/v1/menu/:id         — Soft delete (Admin)
 */
const menuService = require('../services/menuService');
const asyncHandler = require('../utils/asyncHandler');
const { sendSuccess, sendPaginated } = require('../utils/responseHelper');
const { cloudinary } = require('../config/cloudinary');

// Helper to extract Cloudinary public_id from URL
const extractPublicId = (url) => {
    if (!url || !url.includes('res.cloudinary.com')) return null;
    // URL example: https://res.cloudinary.com/demo/image/upload/v1234567890/govardhan_thal_menu/paneer.jpg
    const parts = url.split('/');
    const fileWithExt = parts.pop();
    const folder = parts.pop();
    const publicId = `${folder}/${fileWithExt.split('.')[0]}`;
    return publicId;
};

/**
 * GET /api/v1/menu
 * Query: ?category=&search=&popular=true&recommended=true&todaySpecial=true&page=&limit=
 */
exports.getMenu = asyncHandler(async (req, res) => {
    const { category, search, popular, recommended, todaySpecial, page, limit } = req.query;
    const result = await menuService.getMenu({ category, search, popular, recommended, todaySpecial, page, limit });
    sendPaginated(res, result.items, result.page, result.limit, result.total);
});

/**
 * GET /api/v1/menu/categories
 */
exports.getCategories = asyncHandler(async (req, res) => {
    const categories = await menuService.getCategories();
    sendSuccess(res, categories);
});

/**
 * GET /api/v1/menu/today-specials
 */
exports.getTodaySpecials = asyncHandler(async (req, res) => {
    const items = await menuService.getTodaySpecials();
    sendSuccess(res, items, "Today's Specials");
});

/**
 * GET /api/v1/menu/popular
 */
exports.getPopularItems = asyncHandler(async (req, res) => {
    const limitParam = parseInt(req.query.limit) || 10;
    const items = await menuService.getPopularItems(limitParam);
    sendSuccess(res, items, 'Popular Items');
});

/**
 * GET /api/v1/menu/recommended
 */
exports.getRecommended = asyncHandler(async (req, res) => {
    const limitParam = parseInt(req.query.limit) || 10;
    const items = await menuService.getRecommended(limitParam);
    sendSuccess(res, items, 'Recommended Items');
});

/**
 * GET /api/v1/menu/:id
 */
exports.getMenuById = asyncHandler(async (req, res) => {
    const item = await menuService.getById(req.params.id);
    if (!item) {
        return res.status(404).json({ status: 'error', message: 'Menu item not found' });
    }
    sendSuccess(res, item);
});

/**
 * POST /api/v1/menu (Admin)
 */
exports.createMenu = asyncHandler(async (req, res) => {
    const data = { ...req.body };
    if (req.file) {
        data.imageUrl = req.file.path;
    }
    const item = await menuService.create(data);
    sendSuccess(res, item, 'Menu item created successfully', 201);
});

/**
 * PUT /api/v1/menu/:id (Admin)
 */
exports.updateMenu = asyncHandler(async (req, res) => {
    const data = { ...req.body };
    
    if (req.file) {
        data.imageUrl = req.file.path;
        
        // Optionally delete old Cloudinary image
        const oldItem = await menuService.getById(req.params.id);
        if (oldItem && oldItem.imageUrl) {
            const publicId = extractPublicId(oldItem.imageUrl);
            if (publicId) {
                // Ignore errors to prevent failing the update if image deletion fails
                cloudinary.uploader.destroy(publicId).catch(console.error);
            }
        }
    }
    
    const item = await menuService.update(req.params.id, data);
    if (!item) {
        return res.status(404).json({ status: 'error', message: 'Menu item not found' });
    }
    sendSuccess(res, item, 'Menu item updated successfully');
});

/**
 * DELETE /api/v1/menu/:id (Admin)
 */
exports.deleteMenu = asyncHandler(async (req, res) => {
    // Optionally delete old Cloudinary image
    const oldItem = await menuService.getById(req.params.id);
    if (oldItem && oldItem.imageUrl) {
        const publicId = extractPublicId(oldItem.imageUrl);
        if (publicId) {
            cloudinary.uploader.destroy(publicId).catch(console.error);
        }
    }

    const item = await menuService.softDelete(req.params.id);
    if (!item) {
        return res.status(404).json({ status: 'error', message: 'Menu item not found' });
    }
    sendSuccess(res, item, 'Menu item deleted successfully');
});
