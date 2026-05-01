/**
 * Delivery Service — Calculates distance and delivery fees.
 * Uses Haversine formula for distance calculation (fallback) 
 * or Google Maps Distance Matrix.
 */

const RESTAURANT_LAT = parseFloat(process.env.RESTAURANT_LAT) || 23.0225; // Default Ahmedabad
const RESTAURANT_LNG = parseFloat(process.env.RESTAURANT_LNG) || 72.5714;
const PRICE_PER_KM = parseFloat(process.env.DELIVERY_PRICE_PER_KM) || 10;
const FREE_DELIVERY_MIN = parseFloat(process.env.FREE_DELIVERY_THRESHOLD) || 500;

/**
 * Calculates distance between two points (in KM) using Haversine
 */
const calculateDistance = (lat1, lon1, lat2, lon2) => {
    const R = 6371; // Radius of the earth in km
    const dLat = (lat2 - lat1) * Math.PI / 180;
    const dLon = (lon2 - lon1) * Math.PI / 180;
    const a = 
        0.5 - Math.cos(dLat)/2 + 
        Math.cos(lat1 * Math.PI / 180) * Math.cos(lat2 * Math.PI / 180) * 
        (1 - Math.cos(dLon))/2;

    return R * 2 * Math.asin(Math.sqrt(a));
};

/**
 * Calculate Delivery Fee based on distance and order subtotal
 */
const getDeliveryFee = (destLat, destLng, subtotal = 0) => {
    // 1. Check free delivery threshold
    if (subtotal >= FREE_DELIVERY_MIN) return 0;

    // 2. Calculate distance
    const distance = calculateDistance(RESTAURANT_LAT, RESTAURANT_LNG, destLat, destLng);
    
    // NEW: Free delivery within 3km
    if (distance <= 3) return 0;
    
    // 3. Professional Pricing Model (Internal Restaurant logic)
    let fee = 20; // Start with base ₹20
    
    if (distance > 2 && distance <= 5) {
        fee = 35;
    } else if (distance > 5 && distance <= 10) {
        fee = 50;
    } else if (distance > 10) {
        // Beyond 10km: First 10km (50) + 10 per additional KM
        const additionalKm = distance - 10;
        fee = 50 + (additionalKm * (parseFloat(process.env.DELIVERY_PRICE_PER_KM) || 10));
    }

    // 4. Round for professionalism
    const roundedFee = Math.ceil(fee / 5) * 5;
    
    // Safety Cap: Don't charge more than ₹75 for accidental distant address selection
    return Math.min(75, Math.max(20, roundedFee));
};

module.exports = { calculateDistance, getDeliveryFee };
