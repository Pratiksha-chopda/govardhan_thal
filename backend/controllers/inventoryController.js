const Ingredient = require('../models/Ingredient');
const Menu = require('../models/Menu');
const asyncHandler = require('../utils/asyncHandler');
const { sendSuccess } = require('../utils/responseHelper');

/**
 * GET /ingredients
 */
exports.getIngredients = asyncHandler(async (req, res) => {
    const ingredients = await Ingredient.find().sort({ name: 1 }).lean();
    sendSuccess(res, ingredients);
});

/**
 * POST /ingredients
 */
exports.addIngredient = asyncHandler(async (req, res) => {
    const ingredient = await Ingredient.create(req.body);
    sendSuccess(res, ingredient, 'Ingredient added successfully', 201);
});

/**
 * PATCH /ingredients/:id/stock
 */
exports.updateStock = asyncHandler(async (req, res) => {
    const { amount, action } = req.body; // action: 'ADD' | 'SUBTRACT' | 'SET'
    const ingredient = await Ingredient.findById(req.params.id);
    if (!ingredient) return res.status(404).json({ success: false, message: 'Not found' });

    if (action === 'ADD') ingredient.stock += Number(amount);
    else if (action === 'SUBTRACT') ingredient.stock -= Number(amount);
    else if (action === 'SET') ingredient.stock = Number(amount);

    await ingredient.save();
    sendSuccess(res, ingredient, 'Stock updated');
});

/**
 * GET /inventory/low-stock
 */
exports.getLowStock = asyncHandler(async (req, res) => {
    const lowStock = await Ingredient.find({
        $expr: { $lte: ['$stock', '$lowStockThreshold'] }
    });
    sendSuccess(res, lowStock);
});

/**
 * POST /menu/:menuId/recipe
 */
exports.updateRecipe = asyncHandler(async (req, res) => {
    const { recipe } = req.body; // Array of { ingredientId, quantity, unit }
    const menuItem = await Menu.findByIdAndUpdate(
        req.params.menuId, 
        { recipe }, 
        { new: true }
    ).populate('recipe.ingredientId');
    
    sendSuccess(res, menuItem, 'Recipe updated successfully');
});
