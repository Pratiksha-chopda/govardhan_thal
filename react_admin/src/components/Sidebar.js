"use client";

import Link from "next/link";
import { usePathname } from "next/navigation";
import clsx from "clsx";
import { motion } from "framer-motion";
import {
  LayoutDashboard,
  ShoppingCart,
  CalendarDays,
  Utensils,
  Grid3X3,
  Users,
  LineChart,
  Bell,
  Settings,
  LogOut,
  Ticket,
  Star,
  AlertCircle,
  PackageCheck,
  Monitor,
  ShieldCheck
} from "lucide-react";

const NAV_ITEMS = [
  { name: "Executive Suite", href: "/", icon: LayoutDashboard },
  { name: "Orders Pipeline", href: "/orders", icon: ShoppingCart },
  { name: "Kitchen Display", href: "/kds", icon: Monitor }, // NEW: KDS
  { name: "Inventory Hub", href: "/inventory", icon: PackageCheck }, // NEW: Inventory
  { name: "Floor Intelligence", href: "/tables", icon: Grid3X3 },
  { name: "Culinary Assets", href: "/menu", icon: Utensils },
  { name: "Reservation Desk", href: "/bookings", icon: CalendarDays },
  { name: "Staff Management", href: "/staff", icon: ShieldCheck }, // NEW: Staff Roles
  { name: "Customer Hub", href: "/users", icon: Users },
  { name: "Business Intel", href: "/reports", icon: LineChart },
  { name: "Marketing Tools", href: "/coupons", icon: Ticket },
  { name: "Customer Reviews", href: "/ratings", icon: Star },
  { name: "Support Tickets", href: "/complaints", icon: AlertCircle },
  { name: "System Alerts", href: "/notifications", icon: Bell },
];

import { useEffect, useState } from "react";
import apiService from "@/services/apiService";
import socketService from "@/services/socketService";

export default function Sidebar() {
  const pathname = usePathname();
  const [unreadCount, setUnreadCount] = useState(0);

  useEffect(() => {
    if (pathname === "/login") return;

    const fetchUnread = async () => {
      try {
        const res = await apiService.get("/notifications/admin/unread-count");
        // Update to handle { success, count } format and provide safety fallback
        if (res.data && res.data.success) {
          setUnreadCount(typeof res.data.count === 'number' ? res.data.count : 0);
        } else {
          setUnreadCount(0); // Fallback on missing data
        }
      } catch (e) {
        if (e.response?.status !== 401) {
          console.error("Failed to fetch unread notification count");
        }
        setUnreadCount(0); // Ensure no crash by defaulting to 0
      }
    };
    fetchUnread();

    const handleNewNotification = () => {
      setUnreadCount(prev => prev + 1);
    };

    const handleReadNotification = () => {
      fetchUnread(); // Or selectively decrement
    };

    socketService.connect();
    socketService.on("notification:new", handleNewNotification);
    socketService.on("notification:read", handleReadNotification);

    return () => {
      socketService.off("notification:new", handleNewNotification);
      socketService.off("notification:read", handleReadNotification);
    };
  }, [pathname]);

  if (pathname === "/login") return null;

  return (
    <div className="w-72 h-full p-4 flex flex-col">
      {/* Glossy Sidebar Container */}
      <div className="bg-white/70 backdrop-blur-xl border border-white/50 shadow-[0_8px_30px_rgb(0,0,0,0.04)] h-full flex flex-col rounded-[32px] overflow-hidden relative">
        
        {/* Brand Header */}
        <div className="pt-10 pb-8 px-6 flex items-center justify-center border-b border-slate-100/50 relative">
          <div className="absolute top-0 right-0 w-24 h-24 bg-amber-100/30 blur-[40px] rounded-full"></div>
          <div className="flex flex-col items-center gap-1 relative z-10">
            <div className="w-14 h-14 bg-slate-900 text-white rounded-[20px] flex items-center justify-center shadow-2xl shadow-slate-900/40 rotate-3 transition-transform duration-500">
              <Utensils className="w-7 h-7" />
            </div>
            <h1 className="text-[10px] font-black text-slate-900 tracking-[0.4em] uppercase mt-4 opacity-80 text-center leading-relaxed">
              Govardhan<br/>Thal Admin
            </h1>
          </div>
        </div>

        {/* Navigation */}
        <div className="flex-1 overflow-y-auto py-8 px-4 space-y-2 scrollbar-hide">
          {NAV_ITEMS.map((item, index) => {
            const isActive = pathname === item.href || (item.href !== '/' && pathname.startsWith(item.href));
            return (
              <motion.div
                key={item.href}
                initial={{ opacity: 0, x: -10 }}
                animate={{ opacity: 1, x: 0 }}
                transition={{ delay: index * 0.05 }}
              >
                <Link
                  href={item.href}
                  className={clsx(
                    "group relative flex items-center gap-4 px-5 py-3.5 rounded-2xl transition-all duration-500 font-bold text-[11px] uppercase tracking-widest overflow-hidden",
                    isActive
                      ? "bg-slate-900 text-white shadow-xl shadow-slate-900/20"
                      : "text-slate-400 hover:text-slate-900 hover:bg-slate-100"
                  )}
                >
                  <item.icon className={clsx("w-4 h-4 transition-transform duration-500", isActive ? "text-amber-400" : "text-slate-300 group-hover:scale-125 group-hover:rotate-6")} />
                  <span className="relative z-10 flex-1">{item.name}</span>
                  
                  {item.href === "/notifications" && unreadCount > 0 && (
                      <span className="bg-red-500 text-white text-[9px] font-black px-2 py-0.5 rounded-full z-10 animate-pulse">
                          {unreadCount > 99 ? '99+' : unreadCount}
                      </span>
                  )}

                  {isActive && (
                    <motion.div layoutId="activeNav" className="absolute right-4 w-1.5 h-1.5 bg-amber-400 rounded-full shadow-[0_0_10px_#F59E0B]"></motion.div>
                  )}
                </Link>
              </motion.div>
            );
          })}
        </div>

        {/* Bottom Profile / Logout */}
        <div className="p-4 bg-slate-50/80 backdrop-blur-md border-t border-slate-100/50 m-4 rounded-[24px]">
          <Link
            href="/profile"
            className="flex items-center gap-3 px-4 py-3 rounded-xl text-slate-500 hover:text-slate-900 hover:bg-white transition-all duration-300 font-black text-[10px] uppercase tracking-widest group mb-1"
          >
            <Settings className="w-4 h-4 text-slate-400 group-hover:rotate-90 group-hover:text-amber-500 transition-all duration-500" />
            <span>Profile Settings</span>
          </Link>

          <button
            onClick={() => {
              localStorage.removeItem("adminToken");
              window.location.href = "/login";
            }}
            className="flex items-center gap-3 px-4 py-3 w-full rounded-xl text-slate-400 hover:text-rose-600 hover:bg-rose-50/50 transition-all duration-300 font-black text-[10px] uppercase tracking-widest group"
          >
            <LogOut className="w-4 h-4 group-hover:-translate-x-1 transition-transform" />
            <span>Secure Logout</span>
          </button>
        </div>

      </div>
    </div>
  );
}
