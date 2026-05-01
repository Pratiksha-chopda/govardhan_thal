const UserSettings = require('../models/UserSettings');

exports.getSettings = async (req, res) => {
    const { user_id } = req.params;
    try {
        let settings = await UserSettings.findOne({ userId: user_id });
        if (!settings) {
            settings = new UserSettings({ userId: user_id });
            await settings.save();
        }
        const formatted = { 
            user_id, 
            notifications_enabled: settings.notificationsEnabled, 
            order_updates: settings.orderUpdates, 
            promotions: settings.promotions 
        };
        res.status(200).json({ status: "success", data: formatted });
    } catch (error) {
        res.status(500).json({ status: "error", message: error.message });
    }
};

exports.updateSettings = async (req, res) => {
    const { user_id } = req.params;
    const { notifications_enabled, order_updates, promotions } = req.body;
    try {
        await UserSettings.findOneAndUpdate(
            { userId: user_id },
            { notificationsEnabled: notifications_enabled, orderUpdates: order_updates, promotions: promotions },
            { upsert: true, new: true }
        );
        res.status(200).json({ status: "success", message: "Settings updated" });
    } catch (error) {
        res.status(500).json({ status: "error", message: error.message });
    }
};
