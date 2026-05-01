const Address = require('../models/Address');

exports.getAddresses = async (req, res) => {
    const { user_id } = req.params;
    try {
        const addresses = await Address.find({ userId: user_id }).sort({ isDefault: -1, createdAt: -1 });
        const formatted = addresses.map(addr => ({ ...addr._doc, address_id: addr._id, is_default: addr.isDefault, address_line: addr.addressLine }));
        res.status(200).json({ status: "success", data: formatted });
    } catch (error) {
        res.status(500).json({ status: "error", message: error.message });
    }
};

exports.addAddress = async (req, res) => {
    const { user_id, label, address_line, city, state, pincode, is_default, house, street, area, landmark, latitude, longitude, type } = req.body;
    try {
        if (is_default) {
            await Address.updateMany({ userId: user_id }, { isDefault: false });
        }
        
        let finalLabel = type || label || 'Home';
        let finalAddressLine = address_line || '';
        if (!finalAddressLine && house && street && area) {
            finalAddressLine = `${house}, ${street}, ${area}`;
        }

        const newAddress = new Address({
            userId: user_id, 
            label: finalLabel, 
            addressLine: finalAddressLine, 
            city, 
            state: state || 'Gujarat', 
            pincode, 
            isDefault: is_default || false,
            house, street, area, landmark, latitude, longitude, type: type || 'Home'
        });
        await newAddress.save();
        res.status(201).json({ status: "success", message: "Address added", address_id: newAddress._id });
    } catch (error) {
        res.status(500).json({ status: "error", message: error.message });
    }
};

exports.updateAddress = async (req, res) => {
    const { address_id } = req.params;
    const { label, address_line, city, state, pincode, is_default, user_id } = req.body;
    try {
        if (is_default && user_id) {
            await Address.updateMany({ userId: user_id }, { isDefault: false });
        }
        await Address.findByIdAndUpdate(address_id, {
            label, addressLine: address_line, city, state, pincode, isDefault: is_default
        });
        res.status(200).json({ status: "success", message: "Address updated" });
    } catch (error) {
        res.status(500).json({ status: "error", message: error.message });
    }
};

exports.deleteAddress = async (req, res) => {
    const { address_id } = req.params;
    try {
        await Address.findByIdAndDelete(address_id);
        res.status(200).json({ status: "success", message: "Address deleted" });
    } catch (error) {
        res.status(500).json({ status: "error", message: error.message });
    }
};

exports.setDefaultAddress = async (req, res) => {
    const { address_id } = req.params;
    const { user_id } = req.body;
    try {
        await Address.updateMany({ userId: user_id }, { isDefault: false });
        await Address.findByIdAndUpdate(address_id, { isDefault: true });
        res.status(200).json({ status: "success", message: "Default address updated" });
    } catch (error) {
        res.status(500).json({ status: "error", message: error.message });
    }
};
