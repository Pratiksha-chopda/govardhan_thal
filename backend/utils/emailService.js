/**
 * Email Utility — Sends transactional emails via Nodemailer + Gmail SMTP.
 * 
 * Setup:
 *   1. Go to Google Account → Security → 2-Step Verification → Enable it.
 *   2. Go to Google Account → Security → App Passwords → Generate one for "Mail".
 *   3. Paste that 16-character app password in .env as EMAIL_PASS.
 */
const nodemailer = require('nodemailer');

const transporter = nodemailer.createTransport({
    service: 'gmail',
    auth: {
        user: process.env.EMAIL_USER,
        pass: process.env.EMAIL_PASS,
    },
});

/**
 * Send OTP email for password reset.
 * @param {string} to - Recipient email address
 * @param {string} otp - The 4-digit OTP code
 * @param {string} userName - User's name for personalization
 */
const sendOtpEmail = async (to, otp, userName = 'User') => {
    const mailOptions = {
        from: `"Govardhan Thal" <${process.env.EMAIL_USER}>`,
        to,
        subject: '🔐 Password Reset OTP - Govardhan Thal',
        html: `
        <div style="font-family: 'Segoe UI', Arial, sans-serif; max-width: 480px; margin: 0 auto; background: #fff; border-radius: 16px; overflow: hidden; border: 1px solid #f0f0f0;">
            <!-- Header -->
            <div style="background: linear-gradient(135deg, #FF6B00, #FF8C33); padding: 32px 24px; text-align: center;">
                <h1 style="color: white; margin: 0; font-size: 24px; letter-spacing: 0.5px;">Govardhan Thal</h1>
                <p style="color: rgba(255,255,255,0.9); margin: 8px 0 0; font-size: 14px;">Password Reset Request</p>
            </div>
            
            <!-- Body -->
            <div style="padding: 32px 24px;">
                <p style="color: #333; font-size: 16px; margin: 0 0 8px;">Hello <strong>${userName}</strong>,</p>
                <p style="color: #666; font-size: 14px; line-height: 1.6; margin: 0 0 24px;">
                    We received a request to reset your password. Use the OTP below to verify your identity:
                </p>
                
                <!-- OTP Box -->
                <div style="background: #FFF5EB; border: 2px dashed #FF6B00; border-radius: 12px; padding: 24px; text-align: center; margin: 0 0 24px;">
                    <p style="color: #999; font-size: 12px; text-transform: uppercase; letter-spacing: 2px; margin: 0 0 8px;">Your OTP Code</p>
                    <h2 style="color: #FF6B00; font-size: 36px; letter-spacing: 8px; margin: 0; font-weight: bold;">${otp}</h2>
                </div>
                
                <p style="color: #999; font-size: 13px; line-height: 1.5; margin: 0 0 8px;">
                    ⏰ This OTP is valid for <strong>10 minutes</strong>.
                </p>
                <p style="color: #999; font-size: 13px; line-height: 1.5; margin: 0;">
                    If you didn't request this, please ignore this email. Your password will remain unchanged.
                </p>
            </div>
            
            <!-- Footer -->
            <div style="background: #FAFAFA; padding: 16px 24px; text-align: center; border-top: 1px solid #f0f0f0;">
                <p style="color: #bbb; font-size: 11px; margin: 0;">© ${new Date().getFullYear()} Govardhan Thal. All rights reserved.</p>
            </div>
        </div>
        `,
    };

    try {
        const info = await transporter.sendMail(mailOptions);
        console.log(`[EMAIL] OTP sent to ${to}: ${info.messageId}`);
        return true;
    } catch (error) {
        console.error(`[EMAIL ERROR] Failed to send OTP to ${to}:`, error.message);
        return false;
    }
};

module.exports = { sendOtpEmail };
