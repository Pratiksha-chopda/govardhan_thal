const express = require('express');
const router = express.Router();
const paymentController = require('../controllers/paymentController');

// POST a process payment request
router.post('/process', paymentController.processPayment);

module.exports = router;
