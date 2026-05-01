"use client";

import { useEffect, useState } from "react";
import { Bell, X, Info, CheckCircle, ShoppingBag, Utensils } from "lucide-react";
import socketService from "@/services/socketService";
import { motion, AnimatePresence } from "framer-motion";

export default function GlobalNotification() {
  const [notifications, setNotifications] = useState([]);

  useEffect(() => {
    socketService.connect();

    const handleNewNotification = (data) => {
      console.log("📨 Socket Event: notification:new received", data);
      const { notification } = data;
      addToast(notification.title, notification.message, notification.type);
    };

    const handleOrderNew = (data) => {
      console.log("📦 Socket Event: order:new received", data);
      // Only show top toast if it wasn't already handled by notification:new (some redundancy is okay for robustness)
      addToast("New Order Received", `Order #${data.order?._id?.slice(-6).toUpperCase() || 'New'} placed for ₹${data.order?.totalAmount}`, "ORDER");
    };

    const handleBookingNew = (data) => {
      console.log("📅 Socket Event: booking:new received", data);
      addToast("New Reservation Request", `${data.booking?.guestCount || '?'} guests for ${data.booking?.date} at ${data.booking?.timeSlot}`, "BOOKING");
    };

    const addToast = (title, message, type) => {
      const id = Math.random().toString(36).substr(2, 9);
      setNotifications((prev) => [...prev, { id, title, message, type }]);
      setTimeout(() => {
        setNotifications((prev) => prev.filter((n) => n.id !== id));
      }, 7000);
    };

    socketService.on("notification:new", handleNewNotification);
    socketService.on("order:new", handleOrderNew);
    socketService.on("booking:new", handleBookingNew);

    return () => {
      socketService.off("notification:new", handleNewNotification);
      socketService.off("order:new", handleOrderNew);
      socketService.off("booking:new", handleBookingNew);
    };
  }, []);

  return (
    <div className="fixed top-6 right-6 z-[9999] flex flex-col gap-3 w-80 pointer-events-none">
      <AnimatePresence>
        {notifications.map((n) => (
          <motion.div
            key={n.id}
            initial={{ opacity: 0, x: 50, scale: 0.9 }}
            animate={{ opacity: 1, x: 0, scale: 1 }}
            exit={{ opacity: 0, scale: 0.9, transition: { duration: 0.2 } }}
            className="bg-white/90 backdrop-blur-xl border border-white/50 shadow-[0_15px_30px_rgb(0,0,0,0.12)] rounded-2xl p-4 pointer-events-auto relative overflow-hidden group"
          >
            {/* Animated Progress Bar */}
            <motion.div 
               initial={{ width: "100%" }}
               animate={{ width: "0%" }}
               transition={{ duration: 6, ease: "linear" }}
               className="absolute bottom-0 left-0 h-1 bg-amber-500/50"
            />

            <div className="flex gap-4">
              <div className={`p-3 rounded-xl flex items-center justify-center shrink-0 ${
                n.type === 'ORDER' ? 'bg-amber-100 text-amber-600' : 
                n.type === 'BOOKING' ? 'bg-blue-100 text-blue-600' : 'bg-slate-100 text-slate-600'
              }`}>
                {n.type === 'ORDER' ? <ShoppingBag className="w-5 h-5" /> : 
                 n.type === 'BOOKING' ? <Utensils className="w-5 h-5" /> : <Bell className="w-5 h-5" />}
              </div>
              <div className="flex flex-col gap-1 pr-4">
                <h4 className="text-sm font-black text-slate-900 leading-tight">{n.title}</h4>
                <p className="text-xs text-slate-500 leading-normal line-clamp-2">{n.message}</p>
              </div>
              <button 
                onClick={() => setNotifications(prev => prev.filter(item => item.id !== n.id))}
                className="absolute top-2 right-2 p-1 text-slate-300 hover:text-slate-600 transition-colors"
              >
                <X className="w-4 h-4" />
              </button>
            </div>
          </motion.div>
        ))}
      </AnimatePresence>
    </div>
  );
}
