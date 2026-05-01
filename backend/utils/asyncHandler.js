/**
 * Async Handler Wrapper
 * Wraps async route handlers to automatically catch errors
 * and forward them to Express error middleware.
 *
 * Usage: router.get('/', asyncHandler(controller.method));
 */
const asyncHandler = (fn) => (req, res, next) => {
    Promise.resolve(fn(req, res, next)).catch(next);
};

module.exports = asyncHandler;
