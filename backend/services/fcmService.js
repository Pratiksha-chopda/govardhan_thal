/**
 * FCM Service — Firebase Cloud Messaging for Push Notifications
 * 
 * Uses firebase-admin SDK to send push notifications to user devices.
 * Integrates with existing notificationService for dual delivery
 * (in-app via Socket.IO + push via FCM).
 */
const admin = require('firebase-admin');
const User = require('../models/User');

// Initialize Firebase Admin SDK (only once)
let firebaseInitialized = false;

const initFirebase = () => {
    if (firebaseInitialized) return;
    try {
        // Try to initialize with service account file if it exists
        const path = require('path');
        const serviceAccountPath = path.join(__dirname, '../config/firebase-service-account.json');
        const fs = require('fs');
        
        if (fs.existsSync(serviceAccountPath)) {
            const serviceAccount = require(serviceAccountPath);
            admin.initializeApp({
                credential: admin.credential.cert(serviceAccount),
            });
            console.log('✅ Firebase Admin SDK initialized with service account');
        } else {
            // Fallback: use application default credentials (for deployed environments)
            admin.initializeApp({
                credential: admin.credential.applicationDefault(),
            });
            console.log('✅ Firebase Admin SDK initialized with default credentials');
        }
        firebaseInitialized = true;
    } catch (err) {
        console.warn('⚠️  Firebase Admin SDK initialization failed:', err.message);
        console.warn('   Push notifications will be disabled. Add firebase-service-account.json to config/ folder.');
    }
};

// Initialize on load
initFirebase();

/**
 * Save/update FCM token for a user
 * Called when the Flutter app starts or token refreshes
 */
const saveToken = async (userId, fcmToken) => {
    if (!userId || !fcmToken) return;
    try {
        await User.findByIdAndUpdate(userId, { fcmToken });
    } catch (err) {
        console.error('Error saving FCM token:', err.message);
    }
};

/**
 * Remove FCM token (on logout)
 */
const removeToken = async (userId) => {
    try {
        await User.findByIdAndUpdate(userId, { fcmToken: '' });
    } catch (err) {
        console.error('Error removing FCM token:', err.message);
    }
};

/**
 * Send push notification to a specific user
 * @param {string} userId - Target user MongoDB ID
 * @param {string} title - Notification title
 * @param {string} body - Notification body
 * @param {Object} data - Additional data payload (optional)
 */
const sendToUser = async (userId, title, body, data = {}) => {
    if (!firebaseInitialized) return;
    
    try {
        const user = await User.findById(userId).select('fcmToken').lean();
        if (!user?.fcmToken) return;

        const message = {
            token: user.fcmToken,
            notification: {
                title,
                body,
            },
            data: {
                ...Object.fromEntries(
                    Object.entries(data).map(([k, v]) => [k, String(v)])
                ),
                click_action: 'FLUTTER_NOTIFICATION_CLICK',
            },
            android: {
                priority: 'high',
                notification: {
                    channelId: 'govardhan_orders',
                    sound: 'default',
                    icon: 'ic_notification',
                    color: '#FF6A00',
                },
            },
            apns: {
                payload: {
                    aps: {
                        sound: 'default',
                        badge: 1,
                    },
                },
            },
        };

        const response = await admin.messaging().send(message);
        console.log(`📱 FCM sent to user ${userId}:`, response);
        return response;
    } catch (err) {
        // Handle invalid/expired tokens
        if (err.code === 'messaging/registration-token-not-registered' ||
            err.code === 'messaging/invalid-registration-token') {
            console.warn(`🗑️  Removing invalid FCM token for user ${userId}`);
            await removeToken(userId);
        } else {
            console.error('FCM send error:', err.message);
        }
    }
};

/**
 * Send push notification to multiple users
 */
const sendToMultipleUsers = async (userIds, title, body, data = {}) => {
    if (!firebaseInitialized) return;
    
    try {
        const users = await User.find({ _id: { $in: userIds }, fcmToken: { $ne: '' } })
            .select('fcmToken')
            .lean();

        const tokens = users.map(u => u.fcmToken).filter(Boolean);
        if (tokens.length === 0) return;

        const message = {
            notification: { title, body },
            data: {
                ...Object.fromEntries(
                    Object.entries(data).map(([k, v]) => [k, String(v)])
                ),
                click_action: 'FLUTTER_NOTIFICATION_CLICK',
            },
            android: {
                priority: 'high',
                notification: {
                    channelId: 'govardhan_orders',
                    sound: 'default',
                    color: '#FF6A00',
                },
            },
        };

        const response = await admin.messaging().sendEachForMulticast({
            tokens,
            ...message,
        });

        console.log(`📱 FCM multicast: ${response.successCount} success, ${response.failureCount} failures`);
        return response;
    } catch (err) {
        console.error('FCM multicast error:', err.message);
    }
};

/**
 * Send push to all admin devices (topic-based)
 */
const sendToAdmins = async (title, body, data = {}) => {
    if (!firebaseInitialized) return;

    try {
        const message = {
            topic: 'admin_notifications',
            notification: { title, body },
            data: {
                ...Object.fromEntries(
                    Object.entries(data).map(([k, v]) => [k, String(v)])
                ),
            },
            android: {
                priority: 'high',
                notification: {
                    channelId: 'govardhan_admin',
                    sound: 'default',
                    color: '#FF6A00',
                },
            },
        };

        const response = await admin.messaging().send(message);
        console.log('📱 FCM sent to admin topic:', response);
        return response;
    } catch (err) {
        console.error('FCM admin topic error:', err.message);
    }
};

module.exports = {
    saveToken,
    removeToken,
    sendToUser,
    sendToMultipleUsers,
    sendToAdmins,
};
