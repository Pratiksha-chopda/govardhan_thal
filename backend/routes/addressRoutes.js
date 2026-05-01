const express = require('express');
const router = express.Router();
const addressController = require('../controllers/addressController');

// GET all addresses for user
router.get('/:user_id', addressController.getAddresses);

// ADD address
router.post('/', addressController.addAddress);

// UPDATE address
router.put('/:address_id', addressController.updateAddress);

// DELETE address
router.delete('/:address_id', addressController.deleteAddress);

// SET as default
router.patch('/:address_id/default', addressController.setDefaultAddress);

module.exports = router;
