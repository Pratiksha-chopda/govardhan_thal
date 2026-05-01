"use client";

import { useState, useEffect, useRef } from "react";
import { motion, AnimatePresence } from "framer-motion";
import { 
  Utensils, 
  Clock, 
  CheckCircle2, 
  AlertCircle, 
  Soup, 
  Timer,
  Maximize2
} from "lucide-react";
import apiService from "@/services/apiService";
import socketService from "@/services/socketService";
import clsx from "clsx";

export default function KDSPage() {
  const [orders, setOrders] = useState([]);
  const [loading, setLoading] = useState(true);
  const audioRef = useRef(null);

  useEffect(() => {
    fetchActiveOrders();
    socketService.connect();
    
    socketService.on("order:new", () => {
      if (audioRef.current) audioRef.current.play().catch(() => {});
      fetchActiveOrders();
    });
    
    socketService.on("order:statusUpdated", fetchActiveOrders);
    
    const interval = setInterval(fetchActiveOrders, 10000); // 10s sync
    return () => {
      socketService.off("order:new");
      socketService.off("order:statusUpdated");
      clearInterval(interval);
    };
  }, []);

  const fetchActiveOrders = async () => {
    try {
      // Fetch orders that are PLACED, CONFIRMED, or PREPARING
      const res = await apiService.get("/admin/orders", { 
        params: { status: 'CONFIRMED', limit: 50 } 
      });
      const res2 = await apiService.get("/admin/orders", { 
        params: { status: 'PREPARING', limit: 50 } 
      });
      
      const allActive = [...(res.data.data || []), ...(res2.data.data || [])];
      // Sort by creation time (oldest first for FIFO)
      setOrders(allActive.sort((a, b) => new Date(a.createdAt) - new Date(b.createdAt)));
    } catch (err) {
      console.error("KDS fetch failed");
    } finally {
      setLoading(false);
    }
  };

  const updateStatus = async (orderId, status) => {
    try {
      await apiService.put(`/admin/orders/${orderId}/status`, { status });
      fetchActiveOrders();
    } catch (err) {
      alert("Status update failed");
    }
  };

  return (
    <div className="flex flex-col h-full gap-6 pb-20 overflow-hidden">
      {/* KDS Header */}
      <div className="flex items-center justify-between bg-slate-900 p-8 rounded-[40px] shadow-2xl relative overflow-hidden">
         <div className="absolute top-0 right-0 w-64 h-64 bg-amber-500/10 blur-[100px] rounded-full"></div>
         <div>
            <h1 className="text-4xl font-black text-white tracking-tighter uppercase flex items-center gap-4">
              <Soup className="w-10 h-10 text-amber-500" />
              Kitchen Display
            </h1>
            <p className="text-slate-400 font-bold text-xs uppercase tracking-[0.3em] mt-2 flex items-center gap-2">
               <span className="w-2 h-2 bg-emerald-500 rounded-full animate-pulse"></span>
               Live Preparation Station
            </p>
         </div>
         <div className="flex items-center gap-6">
            <div className="text-right">
               <p className="text-3xl font-black text-white tracking-tighter">{orders.length}</p>
               <p className="text-[10px] font-black text-slate-500 uppercase tracking-widest">Active Tickets</p>
            </div>
            <button className="p-4 bg-white/10 text-white rounded-2xl hover:bg-white/20 transition-all border border-white/10">
               <Maximize2 className="w-6 h-6" />
            </button>
         </div>
      </div>

      {/* Tickets Grid */}
      <div className="flex-1 overflow-x-auto pb-4 scrollbar-hide">
         <div className="flex gap-6 h-full min-w-max p-2">
           <AnimatePresence>
             {loading ? (
                <div className="w-full h-full flex items-center justify-center">
                  <div className="w-20 h-20 border-8 border-slate-100 border-t-amber-500 rounded-full animate-spin"></div>
                </div>
             ) : orders.length === 0 ? (
                <div className="flex-1 flex flex-col items-center justify-center opacity-30 gap-6 min-w-[1000px]">
                   <Utensils className="w-32 h-32" />
                   <h2 className="text-4xl font-black uppercase tracking-tighter">Kitchen Clear</h2>
                </div>
             ) : (
                orders.map((order, idx) => (
                  <motion.div
                    key={order._id}
                    layout
                    initial={{ opacity: 0, scale: 0.9, x: 50 }}
                    animate={{ opacity: 1, scale: 1, x: 0 }}
                    exit={{ opacity: 0, scale: 0.8, y: -50 }}
                    className={clsx(
                      "w-[350px] bg-white rounded-[48px] shadow-xl border-4 flex flex-col overflow-hidden h-full max-h-[700px]",
                      order.status === 'PREPARING' ? "border-amber-400" : "border-slate-100"
                    )}
                  >
                    {/* Ticket Header */}
                    <div className={clsx(
                      "p-8 border-b transition-colors",
                      order.status === 'PREPARING' ? "bg-amber-400 text-slate-900 border-amber-500/20" : "bg-slate-50 text-slate-900 border-slate-100"
                    )}>
                       <div className="flex justify-between items-start mb-4">
                          <span className="text-[10px] font-black uppercase tracking-widest opacity-60 italic">Order Ticket</span>
                          <div className="flex items-center gap-2 bg-black/10 px-3 py-1 rounded-full">
                             <Timer className="w-3 h-3" />
                             <span className="text-xs font-black">{Math.floor((new Date() - new Date(order.createdAt)) / 60000)}m</span>
                          </div>
                       </div>
                       <h2 className="text-4xl font-black tracking-tighter italic">#{order.orderNumber || order._id.slice(-6).toUpperCase()}</h2>
                       <p className="text-xs font-bold uppercase tracking-widest mt-2">{order.order_type} • {order.tableId?.tableNumber ? `Table ${order.tableId.tableNumber}` : 'Online'}</p>
                    </div>

                    {/* Ticket Items */}
                    <div className="flex-1 overflow-y-auto p-8 space-y-6">
                       {order.items.map((item, i) => (
                         <div key={i} className="flex items-start gap-4">
                            <div className="w-10 h-10 bg-slate-900 text-amber-400 rounded-2xl flex items-center justify-center font-black text-lg shadow-sm shrink-0">
                               {item.quantity}
                            </div>
                            <div>
                               <h4 className="text-xl font-black text-slate-900 tracking-tight leading-tight">{item.name}</h4>
                               {item.notes && <p className="text-xs font-bold text-rose-500 mt-1 uppercase italic">Note: {item.notes}</p>}
                            </div>
                         </div>
                       ))}
                    </div>

                    {/* Ticket Footer (Actions) */}
                    <div className="p-6 bg-slate-50 mt-auto border-t border-slate-100">
                       {order.status === 'CONFIRMED' ? (
                          <button 
                            onClick={() => updateStatus(order._id, 'PREPARING')}
                            className="w-full py-6 bg-slate-900 text-white rounded-[32px] font-black uppercase tracking-widest hover:bg-slate-800 transition-all shadow-xl active:scale-95"
                          >
                            Start Cooking
                          </button>
                       ) : (
                          <button 
                            onClick={() => updateStatus(order._id, 'READY')}
                            className="w-full py-6 bg-emerald-500 text-white rounded-[32px] font-black uppercase tracking-widest hover:bg-emerald-600 transition-all shadow-xl active:scale-95 flex items-center justify-center gap-3"
                          >
                            <CheckCircle2 className="w-6 h-6" />
                            Mark Ready
                          </button>
                       )}
                    </div>
                  </motion.div>
                ))
             )}
           </AnimatePresence>
         </div>
      </div>

      <audio ref={audioRef} src="https://assets.mixkit.co/active_storage/sfx/2358/2358-preview.mp3" preload="auto" />
    </div>
  );
}
