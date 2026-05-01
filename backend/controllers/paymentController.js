exports.processPayment = async (req, res) => {
    const { user_id, amount, payment_method } = req.body;
    
    try {
        console.info(`[Payment] Initialized for ${user_id} - ${amount} via ${payment_method}`);
        
        // Simulating network delay for gateway integration
        await new Promise(resolve => setTimeout(resolve, 1500));
        
        // Generate simulated transaction ID
        const mockTransactionId = "txn_" + Math.random().toString(36).substring(2, 15);

        console.info(`[Payment] Success: ${mockTransactionId}`);

        res.status(200).json({ 
            status: "success", 
            message: "Payment processed successfully", 
            transaction_id: mockTransactionId,
            amount_paid: amount
        });
        
    } catch (error) {
        console.error(`[Payment] CRITICAL ERROR: ${error.message}`);
        res.status(500).json({ status: "error", message: "Payment Gateway Error. Please try again later." });
    }
};
