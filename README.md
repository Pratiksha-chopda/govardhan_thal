# 🥗 Govardhan Thal - Premium Restaurant Management System

A comprehensive, full-stack solution for modern restaurant management, featuring a high-performance **Flutter Mobile App**, a robust **Node.js Backend**, and a data-driven **React Admin Dashboard**.

---

## 🚀 Overview
**Govardhan Thal** is designed to streamline restaurant operations and enhance customer experience. It handles everything from real-time online ordering and table reservations to inventory management and kitchen coordination.

## ✨ Key Features

### 📱 Customer Mobile App (Flutter)
- **Smart Menu**: Categorized menu with real-time availability.
- **Online Ordering**: Seamless checkout with Razorpay integration.
- **Table Booking**: Real-time reservation system with status tracking.
- **Live Notifications**: Order status updates via FCM (Firebase Cloud Messaging).
- **Profile & Address Management**: Multi-address support and user preferences.

### 📊 Admin Dashboard (React/Next.js)
- **Live Order Tracking**: Real-time monitoring of Online, Dining, and Takeaway orders.
- **KDS (Kitchen Display System)**: Dedicated view for kitchen staff to manage active orders.
- **Inventory Control**: Track stock levels and automated low-stock alerts.
- **Analytics & Reports**: Visualized sales data and customer insights.
- **Table Management**: Manage restaurant layout and reservation slots.

### ⚙️ Backend & API (Node.js/Express)
- **Socket.io Integration**: Real-time synchronization between the app and admin panel.
- **JWT Authentication**: Secure user and admin login.
- **Database (MongoDB)**: Scalable data storage for orders, users, and menu items.

---

## 🛠️ Technology Stack

| Layer | Technologies |
|-------|--------------|
| **Frontend** | Flutter (Dart), Next.js (JavaScript), TailwindCSS |
| **Backend** | Node.js, Express.js, Socket.io |
| **Database** | MongoDB (Mongoose) |
| **Services** | Firebase (Auth/FCM), Razorpay (Payments) |

---

## 🏗️ Getting Started

### Prerequisites
- Flutter SDK
- Node.js (v16+)
- MongoDB

### Installation

1. **Clone the repository**
   ```bash
   git clone https://github.com/Pratiksha-chopda/govardhan_thal.git
   ```

2. **Backend Setup**
   ```bash
   cd backend
   npm install
   # Create a .env file with your MongoDB URI and JWT_SECRET
   npm start
   ```

3. **Flutter App Setup**
   ```bash
   flutter pub get
   flutter run
   ```

4. **Admin Panel Setup**
   ```bash
   cd react_admin
   npm install
   npm run dev
   ```

---

## 🤝 Contact
**Pratiksha Chopda**  
[GitHub Profile](https://github.com/Pratiksha-chopda)

---
*Created with ❤️ for the Govardhan Thal Project.*
