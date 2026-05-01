const express = require('express');
const router = express.Router();
const inventoryController = require('../controllers/inventoryController');
const { authMiddleware, adminMiddleware } = require('../middleware/authMiddleware');

// All inventory routes require admin access
router.use(authMiddleware);
router.use(adminMiddleware);

router.get('/ingredients', inventoryController.getIngredients);
router.post('/ingredients', inventoryController.addIngredient);
router.patch('/ingredients/:id/stock', inventoryController.updateStock);
router.get('/low-stock', inventoryController.getLowStock);

router.post('/menu/:menuId/recipe', inventoryController.updateRecipe);

module.exports = router;
