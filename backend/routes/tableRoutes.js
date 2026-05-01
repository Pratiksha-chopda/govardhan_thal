const express = require('express');
const router = express.Router();
const tableController = require('../controllers/tableController');

router.get('/:qr_code', tableController.getTableByQr);
router.post('/book', tableController.bookTable);
router.post('/end', tableController.endSession);
router.get('/', tableController.getTables);

module.exports = router;
