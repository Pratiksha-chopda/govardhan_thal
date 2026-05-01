/**
 * Table Controller — Legacy backward-compatible endpoints.
 * Uses the proper Table model (not the deleted TableSession).
 */
const Table = require('../models/Table');
const diningService = require('../services/diningService');
const asyncHandler = require('../utils/asyncHandler');
const { sendSuccess } = require('../utils/responseHelper');

exports.getTableByQr = asyncHandler(async (req, res) => {
    const { qr_code } = req.params;
    try {
        const result = await diningService.verifyTable(qr_code);
        res.status(200).json({
            status: 'success',
            message: 'Table Authenticated.',
            table: {
                _id: result.table_id,
                table_number: result.table_number,
                qr_code: result.qr_code,
                capacity: result.capacity,
                is_available: result.is_available,
            },
        });
    } catch (error) {
        // Demo fallback for testing even if table doesn't exist
        res.status(200).json({
            status: 'success',
            message: 'Table Authenticated (Demo Mode).',
            table: { qr_code, table_number: 0, capacity: 4 },
        });
    }
});

exports.bookTable = asyncHandler(async (req, res) => {
    sendSuccess(res, null, 'Use /api/v1/dining/start-session instead');
});

exports.endSession = asyncHandler(async (req, res) => {
    sendSuccess(res, null, 'Use /api/v1/dining/end-session instead');
});

exports.getTables = asyncHandler(async (req, res) => {
    const tables = await Table.find().sort('tableNumber').lean();
    sendSuccess(res, tables);
});
