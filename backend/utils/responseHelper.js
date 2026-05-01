/**
 * Standardized API Response Helpers
 * Use these in every controller to ensure consistent JSON structure.
 */

/**
 * Send a success response
 * @param {object} res - Express response object
 * @param {any} data - Payload to send
 * @param {string} message - Human-readable message
 * @param {number} statusCode - HTTP status (default 200)
 */
const sendSuccess = (res, data = null, message = 'Success', statusCode = 200) => {
    const response = { success: true, message };
    if (data !== null && data !== undefined) response.data = data;
    return res.status(statusCode).json(response);
};

/**
 * Send an error response
 * @param {object} res - Express response object
 * @param {string} message - Error description
 * @param {number} statusCode - HTTP status (default 500)
 * @param {any} errors - Optional validation errors array
 */
const sendError = (res, message = 'Something went wrong', statusCode = 500, errors = null) => {
    const response = { success: false, message };
    if (errors) response.errors = errors;
    return res.status(statusCode).json(response);
};

/**
 * Send a paginated success response
 */
const sendPaginated = (res, data, page, limit, total, message = 'Success') => {
    return res.status(200).json({
        success: true,
        message,
        data,
        pagination: {
            page: Number(page),
            limit: Number(limit),
            total,
            totalPages: Math.ceil(total / limit),
        },
    });
};

module.exports = { sendSuccess, sendError, sendPaginated };
