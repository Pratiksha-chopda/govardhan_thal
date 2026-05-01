const Razorpay = require('razorpay');
const crypto = require('crypto');

// Initialize Razorpay instance with keys from .env
const razorpay = new Razorpay({
    key_id: process.env.RAZORPAY_KEY_ID,
    key_secret: process.env.RAZORPAY_KEY_SECRET,
});

/**
 * POST /api/v1/razorpay/create-order
 * Creates a Razorpay order on the server side.
 * The Flutter app uses the returned order_id to open the Razorpay checkout.
 */
exports.createOrder = async (req, res) => {
    const { amount } = req.body;

    try {
        if (!amount || amount <= 0) {
            return res.status(400).json({ success: false, message: 'Invalid amount' });
        }

        const options = {
            amount: Math.round(amount * 100), // Razorpay expects amount in paise (INR * 100)
            currency: 'INR',
            receipt: `rcpt_${Date.now()}`,
            notes: {
                app: 'Govardhan Thal',
                user_id: req.user?.id || 'guest',
            },
        };

        const order = await razorpay.orders.create(options);

        console.info(`[Razorpay] Order created: ${order.id} for ₹${amount}`);

        res.status(200).json({
            success: true,
            order_id: order.id,
            amount: order.amount,
            currency: order.currency,
            key_id: process.env.RAZORPAY_KEY_ID, // Flutter needs this to open checkout
        });
    } catch (error) {
        console.error(`[Razorpay] Order creation error: ${error.message}`);
        res.status(500).json({ success: false, message: 'Failed to create payment order. Please try again.' });
    }
};

/**
 * POST /api/v1/razorpay/verify-payment
 * Verifies the Razorpay payment signature after the customer completes payment.
 * This ensures the payment was not tampered with.
 */
exports.verifyPayment = async (req, res) => {
    const { razorpay_order_id, razorpay_payment_id, razorpay_signature } = req.body;

    try {
        if (!razorpay_order_id || !razorpay_payment_id || !razorpay_signature) {
            return res.status(400).json({ success: false, message: 'Missing payment verification data' });
        }

        // Generate expected signature using HMAC SHA256
        const body = razorpay_order_id + '|' + razorpay_payment_id;
        const expectedSignature = crypto
            .createHmac('sha256', process.env.RAZORPAY_KEY_SECRET)
            .update(body)
            .digest('hex');

        if (expectedSignature === razorpay_signature) {
            console.info(`[Razorpay] Payment verified: ${razorpay_payment_id}`);
            res.status(200).json({
                success: true,
                message: 'Payment verified successfully',
                transaction_id: razorpay_payment_id,
            });
        } else {
            console.warn(`[Razorpay] Signature mismatch for order: ${razorpay_order_id}`);
            res.status(400).json({
                success: false,
                message: 'Payment verification failed. Signature mismatch.',
            });
        }
    } catch (error) {
        console.error(`[Razorpay] Verification error: ${error.message}`);
        res.status(500).json({ success: false, message: 'Payment verification error.' });
    }
};
