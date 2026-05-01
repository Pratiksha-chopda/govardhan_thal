require('dotenv').config();
const mongoose = require('mongoose');
const Ingredient = require('./models/Ingredient');
const Menu = require('./models/Menu');

const initialIngredients = [
    { name: 'Paneer', stock: 15, unit: 'kg', lowStockThreshold: 5, pricePerUnit: 350 },
    { name: 'Wheat Flour', stock: 50, unit: 'kg', lowStockThreshold: 10, pricePerUnit: 40 },
    { name: 'Basmati Rice', stock: 100, unit: 'kg', lowStockThreshold: 20, pricePerUnit: 120 },
    { name: 'Toor Dal', stock: 30, unit: 'kg', lowStockThreshold: 10, pricePerUnit: 150 },
    { name: 'Ghee', stock: 10, unit: 'l', lowStockThreshold: 3, pricePerUnit: 600 },
    { name: 'Onion', stock: 25, unit: 'kg', lowStockThreshold: 15, pricePerUnit: 30 },
    { name: 'Tomato', stock: 20, unit: 'kg', lowStockThreshold: 10, pricePerUnit: 50 },
    { name: 'Milk', stock: 15, unit: 'l', lowStockThreshold: 5, pricePerUnit: 60 },
    { name: 'Sugar', stock: 40, unit: 'kg', lowStockThreshold: 10, pricePerUnit: 45 },
    { name: 'Besan', stock: 20, unit: 'kg', lowStockThreshold: 5, pricePerUnit: 80 }
];

async function seedInventory() {
    try {
        await mongoose.connect(process.env.MONGO_URI);
        console.log('✅ Connected to MongoDB');

        // Clear existing ingredients to prevent duplicates during testing
        await Ingredient.deleteMany({});
        console.log('🗑️ Cleared existing ingredients');

        // Seed Ingredients
        const createdIngredients = await Ingredient.insertMany(initialIngredients);
        console.log(`✅ Seeded ${createdIngredients.length} ingredients.`);

        // Find some Menu items to attach recipes to
        const paneerItem = await Menu.findOne({ name: { $regex: /Paneer/i } });
        if (paneerItem) {
            const paneerId = createdIngredients.find(i => i.name === 'Paneer')._id;
            const onionId = createdIngredients.find(i => i.name === 'Onion')._id;
            const tomatoId = createdIngredients.find(i => i.name === 'Tomato')._id;

            paneerItem.recipe = [
                { ingredientId: paneerId, quantity: 0.2, unit: 'kg' },    // 200g
                { ingredientId: onionId, quantity: 0.1, unit: 'kg' },     // 100g
                { ingredientId: tomatoId, quantity: 0.1, unit: 'kg' },    // 100g
            ];
            await paneerItem.save();
            console.log(`✅ Attached recipe to Menu: ${paneerItem.name}`);
        }

        const thaliItem = await Menu.findOne({ name: { $regex: /Thali/i } });
        if (thaliItem) {
            const flourId = createdIngredients.find(i => i.name === 'Wheat Flour')._id;
            const riceId = createdIngredients.find(i => i.name === 'Basmati Rice')._id;
            const dalId = createdIngredients.find(i => i.name === 'Toor Dal')._id;
            const gheeId = createdIngredients.find(i => i.name === 'Ghee')._id;
            const sugarId = createdIngredients.find(i => i.name === 'Sugar')._id;
            const besanId = createdIngredients.find(i => i.name === 'Besan')._id;

            thaliItem.recipe = [
                { ingredientId: flourId, quantity: 0.1, unit: 'kg' },    // 100g Roti
                { ingredientId: riceId, quantity: 0.15, unit: 'kg' },    // 150g Rice
                { ingredientId: dalId, quantity: 0.05, unit: 'kg' },     // 50g Dal
                { ingredientId: gheeId, quantity: 0.02, unit: 'l' },     // 20ml Ghee
                { ingredientId: sugarId, quantity: 0.05, unit: 'kg' },   // 50g Sugar
                { ingredientId: besanId, quantity: 0.1, unit: 'kg' },    // 100g Besan (Farsan/Sweet)
            ];
            await thaliItem.save();
            console.log(`✅ Attached recipe to Menu: ${thaliItem.name}`);
        }

    } catch (err) {
        console.error('❌ Error during seeding:', err.message);
    } finally {
        await mongoose.disconnect();
        console.log('🔌 Disconnected from MongoDB');
    }
}

seedInventory();
