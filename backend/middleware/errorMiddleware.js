/**
 * Central Error Handler Middleware
 * Catches all unhandled errors thrown by controllers/services
 * and returns a standardized JSON error response.
 *
 * Must be registered LAST in server.js via app.use(errorHandler).
 */

// eslint-disable-next-line no-unused-vars
const errorHandler = (err, req, res, _next) => {
    const statusCode = err.statusCode || (err.code === 11000 ? 409 : (err.name === 'ValidationError' ? 400 : 500));
    
    // Only log as a scary stacktrace error if it's an actual 500 server crash, otherwise just log it as a standard rejection
    if (statusCode >= 500) {
        console.error('❌ Critical Server Error:', err.message);
        if (process.env.NODE_ENV !== 'production') console.error(err.stack);
    } else {
        console.warn(`⚠️ API Rejection (${statusCode}):`, err.message);
    }

    // Mongoose validation error
    if (err.name === 'ValidationError') {
        const messages = Object.values(err.errors).map((e) => e.message);
        return res.status(400).json({
            success: false,
            status: 'error',
            message: 'Validation Error',
            errors: messages,
        });
    }

    // Mongoose duplicate key
    if (err.code === 11000) {
        const field = Object.keys(err.keyValue).join(', ');
        return res.status(409).json({
            success: false,
            status: 'error',
            message: `Duplicate value for: ${field}`,
        });
    }

    // Mongoose bad ObjectId
    if (err.name === 'CastError') {
        return res.status(400).json({
            success: false,
            status: 'error',
            message: `Invalid ${err.path}: ${err.value}`,
        });
    }

    // JWT errors
    if (err.name === 'JsonWebTokenError') {
        return res.status(401).json({
            success: false,
            status: 'error',
            message: 'Invalid token',
        });
    }

    if (err.name === 'TokenExpiredError') {
        return res.status(401).json({
            success: false,
            status: 'error',
            message: 'Token expired',
        });
    }

    // Default server error
    res.status(statusCode).json({
        success: false,
        status: 'error',
        message: err.message || 'Internal Server Error',
        code: err.code,
        // Include any custom metadata attached to the error
        ...(err.existingTable && { existingTable: err.existingTable }),
        ...(err.existingSessionId && { existingSessionId: err.existingSessionId }),
    });
};

module.exports = errorHandler;
