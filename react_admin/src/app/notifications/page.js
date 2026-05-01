"use client";

import { useEffect, useState } from "react";
import { Bell, ShoppingBag, CalendarDays, Utensils, UserPlus, FileText, CheckCircle, CreditCard, ChevronRight } from "lucide-react";
import apiService from "@/services/apiService";
import socketService from "@/services/socketService";
import clsx from "clsx";

export default function NotificationsPage() {
  const [notifications, setNotifications] = useState([]);
  const [loading, setLoading] = useState(true);

  const fetchNotifications = async () => {
    try {
      const res = await apiService.get("/admin/notifications");
      // Handle the new stabilized response format { success, data: { notifications: [] } }
      if (res.data && res.data.success && res.data.data?.notifications) {
        setNotifications(res.data.data.notifications);
      } else {
        setNotifications([]); // Safe fallback to empty list
      }
    } catch (err) {
      console.error("Failed to fetch notifications");
      setNotifications([]); // Full catch protection fallback
    } finally {
      setLoading(false);
    }
  };

  useEffect(() => {
    fetchNotifications();
    socketService.connect();
    socketService.on("notification:new", fetchNotifications);
    socketService.on("notification:read", fetchNotifications);
    return () => {
      socketService.off("notification:new", fetchNotifications);
      socketService.off("notification:read", fetchNotifications);
    };
  }, []);

  const getIconAndColor = (type) => {
    switch (type) {
      case "NEW_ONLINE_ORDER":
      case "NEW_TAKEAWAY_ORDER":
        return { icon: ShoppingBag, color: "bg-indigo-100 text-indigo-600 border-indigo-200" };
      case "NEW_DINING_ORDER":
        return { icon: Utensils, color: "bg-orange-100 text-orange-600 border-orange-200" };
      case "BILL_REQUESTED":
        return { icon: FileText, color: "bg-purple-100 text-purple-600 border-purple-200" };
      case "PAYMENT_SUCCESS":
        return { icon: CreditCard, color: "bg-emerald-100 text-emerald-600 border-emerald-200" };
      case "NEW_USER":
        return { icon: UserPlus, color: "bg-cyan-100 text-cyan-600 border-cyan-200" };
      case "NEW_BOOKING":
        return { icon: CalendarDays, color: "bg-blue-100 text-blue-600 border-blue-200" };
      default:
        return { icon: Bell, color: "bg-slate-100 text-slate-600 border-slate-200" };
    }
  };

  const markAllAsRead = async () => {
    try {
      await apiService.put("/admin/notifications/read-all");
      fetchNotifications();
    } catch (err) {
      console.error("Failed to mark all as read");
    }
  };

  const markAsRead = async (id) => {
    try {
      await apiService.put(`/admin/notifications/${id}/read`);
      fetchNotifications();
    } catch (err) {
      console.error("Failed to mark as read");
    }
  };

  return (
    <div className="flex flex-col gap-8 h-full pr-1 pb-10 max-w-4xl mx-auto">
      <div className="flex items-end justify-between bg-white p-8 rounded-[32px] box-border shadow-[0_8px_30px_rgb(0,0,0,0.04)] border border-slate-100 relative overflow-hidden">
        <div className="absolute top-0 right-0 w-64 h-64 bg-amber-100/30 blur-[100px] rounded-full"></div>
        <div className="relative z-10 w-full flex items-center justify-between">
            <div>
              <h1 className="text-4xl font-black text-slate-900 tracking-tighter uppercase">Alerts Center</h1>
              <p className="text-slate-500 font-bold uppercase tracking-widest text-xs mt-2">Manage System Notifications</p>
            </div>
            <button 
                onClick={markAllAsRead}
                className="bg-slate-900 text-white font-black text-[10px] tracking-widest uppercase px-6 py-3 rounded-xl hover:scale-[1.02] hover:shadow-xl hover:bg-slate-800 transition-all flex items-center gap-2"
            >
                <CheckCircle className="w-4 h-4" />
                Mark All Read
            </button>
        </div>
      </div>

      <div className="flex flex-col gap-4">
        {loading ? (
            <div className="py-20 flex justify-center w-full"><div className="w-10 h-10 border-4 border-slate-200 border-t-amber-500 rounded-full animate-spin"></div></div>
        ) : notifications.length === 0 ? (
            <div className="py-20 flex flex-col items-center justify-center text-slate-400 bg-white rounded-[32px] border border-dashed border-slate-200">
                <Bell className="w-16 h-16 mb-4 text-slate-200" />
                <p className="font-black uppercase tracking-widest text-sm">You are all caught up!</p>
            </div>
        ) : notifications.map(n => {
          const { icon: Icon, color } = getIconAndColor(n.type);
          return (
            <div 
              key={n._id} 
              className={clsx(
                  "bg-white p-5 rounded-2xl flex items-start gap-4 shadow-[0_4px_15px_rgb(0,0,0,0.03)] border transition-all cursor-pointer hover:shadow-[0_8px_30px_rgb(0,0,0,0.08)]",
                  n.isRead ? "border-slate-100 opacity-60" : "border-amber-200 ring-2 ring-amber-500/10"
              )}
              onClick={() => !n.isRead && markAsRead(n._id)}
            >
              <div className={`w-12 h-12 rounded-2xl flex items-center justify-center border ${color}`}>
                <Icon className="w-6 h-6 stroke-[2]" />
              </div>
              <div className="flex-1 mt-1">
                <div className="flex items-center justify-between">
                    <h4 className={clsx("font-black tracking-tight", n.isRead ? "text-slate-600" : "text-slate-900")}>{n.title}</h4>
                    <span className="text-[10px] font-bold text-slate-400 uppercase tracking-wider bg-slate-50 px-2 py-1 rounded">
                        {new Date(n.createdAt).toLocaleTimeString([], { hour: '2-digit', minute: '2-digit' })}
                    </span>
                </div>
                <p className={clsx("text-sm mt-1 leading-snug", n.isRead ? "text-slate-400" : "text-slate-600 font-medium")}>{n.message}</p>
              </div>
              {!n.isRead && (
                  <div className="w-3 h-3 bg-red-500 rounded-full mt-2 shadow-[0_0_10px_rgb(239,68,68)]"></div>
              )}
            </div>
          )
        })}
      </div>
    </div>
  );
}
