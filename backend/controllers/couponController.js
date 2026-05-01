const Coupon = require('../models/Coupon');
const asyncHandler = require('../utils/asyncHandler');
const { sendSuccess } = require('../utils/responseHelper');

/**
 * GET /api/v1/coupons/available?type=ONLINE|DINING
 */
exports.getAvailableCoupons = asyncHandler(async (req, res) => {
    const { type } = req.query;
    const filter = { 
        isActive: true, 
        expiryDate: { $gt: new Date() } 
    };

    if (type) {
        filter.applicableFor = { $in: [type.toUpperCase(), 'ALL'] };
    }

    const coupons = await Coupon.find(filter).sort({ createdAt: -1 });
    sendSuccess(res, coupons);
});

/**
 * POST /api/v1/coupons/validate
 * Body: { code, orderAmount, type }
 */
exports.validateCoupon = asyncHandler(async (req, res) => {
    const { code, orderAmount, type } = req.body;
    const coupon = await Coupon.findOne({ code: code.toUpperCase(), isActive: true });

    if (!coupon) {
        throw Object.assign(new Error('Unable to apply coupon. Code does not exist.'), { statusCode: 400 });
    }

    if (new Date() > coupon.expiryDate) {
        throw Object.assign(new Error('Unable to apply coupon. Code has expired.'), { statusCode: 400 });
    }

    const orderType = type ? type.toUpperCase() : 'ONLINE';
    if (coupon.applicableFor !== 'ALL' && coupon.applicableFor !== orderType) {
        throw Object.assign(new Error(`This coupon is only available for ${coupon.applicableFor} orders.`), { statusCode: 400 });
    }

    if (orderAmount < coupon.minOrderAmount) {
        const remaining = coupon.minOrderAmount - orderAmount;
        throw Object.assign(new Error(`Add ₹${remaining} more to apply ${code.toUpperCase()}`), { statusCode: 400 });
    }

    let discountAmount = 0;
    if (coupon.type === 'FLAT') {
        discountAmount = coupon.value;
    } else if (coupon.type === 'PERCENTAGE') {
        discountAmount = (orderAmount * coupon.value) / 100;
        if (coupon.maxDiscount > 0 && discountAmount > coupon.maxDiscount) {
            discountAmount = coupon.maxDiscount;
        }
    }

    // SECTION 6: Discount <= subtotal
    discountAmount = Math.min(discountAmount, orderAmount);

    sendSuccess(res, { coupon, discountAmount }, 'Coupon is valid');
});

/**
 * Admin: Create Coupon
 */
exports.createCoupon = asyncHandler(async (req, res) => {
    // Map frontend fields (discountType/Value) to model fields (type/value)
    const payload = { ...req.body };
    if (payload.discountType) {
        payload.type = payload.discountType.toUpperCase() === 'PERCENTAGE' ? 'PERCENTAGE' : 'FLAT';
        delete payload.discountType;
    }
    if (payload.discountValue) {
        payload.value = Number(payload.discountValue);
        delete payload.discountValue;
    }

    const coupon = await Coupon.create(payload);
    sendSuccess(res, coupon, 'Coupon created successfully', 201);
});

/**
 * Admin: Get All Coupons
 */
exports.getAdminCoupons = asyncHandler(async (req, res) => {
    const coupons = await Coupon.find().sort({ createdAt: -1 });
    sendSuccess(res, coupons);
});

/**
 * Admin: Delete Coupon
 */
exports.deleteCoupon = asyncHandler(async (req, res) => {
    const coupon = await Coupon.findByIdAndDelete(req.params.id);
    if (!coupon) throw new Error('Coupon not found');
    sendSuccess(res, null, 'Coupon deleted successfully');
});
