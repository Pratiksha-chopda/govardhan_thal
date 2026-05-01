const express = require('express');
const router = express.Router();
const settingsController = require('../controllers/settingsController');

// GET settings for user
router.get('/:user_id', settingsController.getSettings);

// UPDATE settings
router.put('/:user_id', settingsController.updateSettings);

module.exports = router;
