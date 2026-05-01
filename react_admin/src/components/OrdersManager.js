"use client";

import { useState, useEffect, useRef } from "react";
import { Package, UtensilsCrossed, Activity, Search, Filter, MapPin, X, CreditCard, ChevronRight, BellRing, Clock, ShoppingCart } from "lucide-react";
import clsx from "clsx";
import apiService from "@/services/apiService";
import socketService from "@/services/socketService";

const tabs = [
  { id: "ALL", label: "All Orders", icon: ShoppingCart },
  { id: "ONLINE", label: "Online Orders", icon: Package },
  { id: "DINING", label: "Dining In", icon: UtensilsCrossed },
  { id: "TAKEAWAY", label: "Takeaway", icon: Activity },
];

const ORDER_STATUSES = ["PLACED", "CONFIRMED", "PREPARING", "READY", "OUT_FOR_DELIVERY", "DELIVERED", "SERVED", "WAITING_PAYMENT", "COMPLETED", "CANCELLED"];

export default function OrdersManager({ fixedType = null }) {
  const [activeTab, setActiveTab] = useState(fixedType || "ONLINE");
  const [statusFilter, setStatusFilter] = useState("ALL");
  const [searchTerm, setSearchTerm] = useState("");
  const [orders, setOrders] = useState([]);
  const [totalOrders, setTotalOrders] = useState(0);
  const [currentPage, setCurrentPage] = useState(1);
  const [loading, setLoading] = useState(true);
  const [selectedOrder, setSelectedOrder] = useState(null);
  const audioRef = useRef(null);
  
  const activeTabRef = useRef(activeTab);
  const statusFilterRef = useRef(statusFilter);
  const currentPageRef = useRef(currentPage);

  useEffect(() => {
    activeTabRef.current = activeTab;
    statusFilterRef.current = statusFilter;
    currentPageRef.current = currentPage;
  }, [activeTab, statusFilter, currentPage]);

  const limit = 20;

  const fetchOrders = async (isBackground = false) => {
    try {
      if (!isBackground) setLoading(true);
      const curPage = currentPageRef.current || currentPage;
      const curTab = activeTabRef.current || activeTab;
      const curStat = statusFilterRef.current || statusFilter;

      const params = {
        page: curPage,
        limit: limit,
      };
      if (curTab !== "ALL") params.order_type = curTab;
      if (curStat !== "ALL") params.status = curStat;
      
      const res = await apiService.get("/admin/orders", { params });
      
      const data = res.data;
      if (data.success) { 
        setOrders(data.data || []);
        setTotalOrders(data.pagination?.total || data.data?.length || 0);
      }
    } catch (err) {
      console.error("Error fetching orders:", err);
    } finally {
      if (!isBackground) setLoading(false);
    }
  };

  const playNotificationSound = () => {
    if (audioRef.current) {
      audioRef.current.currentTime = 0;
      audioRef.current.play().catch(err => console.log("Audio play failed, user interaction might be needed."));
    }
  };

  useEffect(() => {
    socketService.connect();
    
    socketService.on("order:new", (data) => {
      playNotificationSound();
      fetchOrders();
    });
    
    socketService.on("order:statusUpdated", (data) => {
      fetchOrders();
    });

    const interval = setInterval(() => {
      fetchOrders(true);
    }, 5000); // Admin panel refreshes every 5 seconds
    
    return () => {
        socketService.off("order:new");
        socketService.off("order:statusUpdated");
        clearInterval(interval);
    };
  }, []);

  useEffect(() => {
    fetchOrders();
  }, [activeTab, statusFilter, currentPage]);

  const filteredOrders = orders.filter(
    (o) =>
      o.orderNumber?.toLowerCase().includes(searchTerm.toLowerCase()) ||
      o.userId?.name?.toLowerCase().includes(searchTerm.toLowerCase()) ||
      o._id.toLowerCase().includes(searchTerm.toLowerCase())
  );

  const updateStatus = async (orderId, status) => {
    try {
      await apiService.put(`/admin/orders/${orderId}/status`, { status });
      fetchOrders();
      if (selectedOrder && selectedOrder._id === orderId) {
        setSelectedOrder(prev => ({ ...prev, orderStatus: status }));
      }
    } catch (err) {
      console.error("Update failed:", err);
      alert(err.response?.data?.message || "Failed to update order status. Please try again.");
    }
  };

  const groupDiningOrders = () => {
    const groups = {};
    filteredOrders.forEach(order => {
      const key = order.sessionId || order.tableId?._id || 'others';
      if (!groups[key]) {
        groups[key] = {
          id: key,
          session_id: order.sessionId,
          table: order.tableId,
          user: order.userId,
          orders: []
        };
      }
      groups[key].orders.push(order);
    });
    return Object.values(groups).sort((a, b) => (b.orders[0]?.createdAt > a.orders[0]?.createdAt ? 1 : -1));
  };

  const OrderCard = ({ order }) => (
    <div 
      onClick={() => setSelectedOrder(order)}
      className={clsx(
        "bg-white p-5 rounded-2xl shadow-sm border flex flex-col md:flex-row items-start md:items-center justify-between gap-4 cursor-pointer hover:border-slate-300 transition-all",
        selectedOrder?._id === order._id ? "border-amber-400 ring-2 ring-amber-500/10 scale-[1.01] z-10" : "border-slate-100"
      )}
    >
      <div className="flex items-center gap-4">
        <div className={clsx(
            "w-12 h-12 rounded-full flex items-center justify-center border",
            order.order_type === 'ONLINE' ? "bg-indigo-50 text-indigo-500 border-indigo-100" :
            order.order_type === 'DINING' ? "bg-orange-50 text-orange-500 border-orange-100" :
            "bg-teal-50 text-teal-500 border-teal-100"
        )}>
          {order.order_type === 'ONLINE' && <Package className="w-6 h-6" />}
          {order.order_type === 'DINING' && <UtensilsCrossed className="w-6 h-6" />}
          {order.order_type === 'TAKEAWAY' && <Activity className="w-6 h-6" />}
        </div>
        <div>
          <div className="flex items-center gap-2">
            <h4 className="font-bold text-slate-800 text-lg">#{order.orderNumber || String(order._id).substring(String(order._id).length-6)}</h4>
            <span className="text-[10px] bg-slate-100 text-slate-500 px-2 py-0.5 rounded font-black uppercase">{order.order_type}</span>
          </div>
          <p className="text-sm text-slate-500">{order.userId?.name || 'Guest'} {order.userId?.mobile ? `• ${order.userId.mobile}` : ''}</p>
        </div>
      </div>
      
      <div className="flex-1 px-4 py-2 bg-slate-50 rounded-xl md:mx-4 mt-4 md:mt-0 max-w-sm hidden xl:block">
        <div className="flex items-center justify-between gap-4">
            <div className="flex items-center gap-2">
                <div className={clsx(
                    "w-2 h-2 rounded-full shadow-[0_0_8px_currentColor]",
                    order.paymentStatus === 'PAID' || order.paymentStatus === 'SUCCESS' ? "text-emerald-500 bg-emerald-500" : 
                    order.paymentStatus === 'PENDING_VERIFICATION' || order.status === 'WAITING_PAYMENT' ? "text-amber-500 bg-amber-500" : "text-slate-300 bg-slate-300"
                )}></div>
                <span className="text-xs font-bold text-slate-700">
                    {order.paymentMethod || 'UPI'} • {order.status === 'WAITING_PAYMENT' ? 'BILL REQUESTED' : order.paymentStatus}
                </span>
            </div>
            <div className="flex items-center gap-1 text-slate-400">
                <Clock className="w-3 h-3" />
                <span className="text-[10px] font-bold uppercase">{new Date(order.createdAt).toLocaleTimeString([], { hour: '2-digit', minute: '2-digit' })}</span>
            </div>
        </div>
      </div>

      <div className="flex items-center gap-6 w-full md:w-auto mt-4 md:mt-0 justify-between md:justify-end flex-wrap">
        <div className="text-right">
          <p className="font-black text-slate-800 text-xl">₹{Math.round(order.totalAmount)}</p>
          {order.deliveryFee > 0 && (
            <p className="text-sm text-slate-600">Delivery: ₹{Math.round(order.deliveryFee)}</p>
          )}
        </div>
        
        <span className={clsx(
          "px-4 py-1.5 rounded-full text-[10px] font-black uppercase tracking-wider border shadow-sm",
          ['PLACED', 'ORDERED', 'CONFIRMED'].includes(order.status) ? "bg-blue-50 text-blue-700 border-blue-200" :
          order.status === 'PREPARING' ? "bg-amber-50 text-amber-700 border-amber-200" :
          order.status === 'READY_FOR_PICKUP' ? "bg-indigo-50 text-indigo-700 border-indigo-200" :
          order.status === 'READY' ? "bg-teal-50 text-teal-700 border-teal-200" :
          order.status === 'WAITING_PAYMENT' ? "bg-purple-50 text-purple-700 border-purple-200" :
          ['COMPLETED', 'DELIVERED', 'SERVED', 'PAID'].includes(order.status) ? "bg-emerald-50 text-emerald-700 border-emerald-200" :
          order.status === 'CANCELLED' ? "bg-rose-50 text-rose-700 border-rose-200" :
          "bg-slate-50 text-slate-700 border-slate-200"
        )}>
          {(order.status || 'UNKNOWN').replaceAll('_', ' ')}
        </span>
        
        <ChevronRight className="w-5 h-5 text-slate-300" />
      </div>
    </div>
  );

  const OrderDetailsPanel = () => {
    if (!selectedOrder) return null;
    
    return (
      <div className="w-[450px] bg-white border-l border-slate-200 flex flex-col h-full animate-in slide-in-from-right duration-300 z-[99] fixed right-0 top-0 shadow-2xl">
        {/* Header */}
        <div className="p-6 border-b border-slate-100 flex items-center justify-between bg-white">
          <div>
            <div className="flex items-center gap-2 mb-1">
              <span className="text-xs font-black uppercase tracking-widest text-slate-400">Management Panel</span>
              <BellRing className="w-4 h-4 text-amber-500 animate-pulse" />
            </div>
            <h2 className="text-2xl font-black text-slate-900 tracking-tight">#{selectedOrder.orderNumber || String(selectedOrder._id).substring(String(selectedOrder._id).length-6)}</h2>
          </div>
          <button onClick={() => setSelectedOrder(null)} className="p-2.5 bg-white border border-slate-200 rounded-xl hover:bg-slate-100 transition-colors shadow-sm">
            <X className="w-5 h-5 text-slate-600" />
          </button>
        </div>

        <div className="flex-1 overflow-y-auto p-6 space-y-8 bg-slate-50/30">
          {/* Status Tracker */}
          <div className="p-4 bg-white rounded-3xl border border-slate-100 shadow-sm">
             <div className="flex justify-between items-center mb-4">
                <span className="text-[10px] font-black uppercase text-slate-400 tracking-widest">Live Progress Tracking</span>
                <span className="text-[10px] font-black text-slate-400">Created: {new Date(selectedOrder.createdAt).toLocaleTimeString()}</span>
             </div>
             <div className="flex items-center justify-between px-2">
                {(() => {
                    const statusList = selectedOrder.order_type === 'DINING' 
                        ? ['PLACED', 'PREPARING', 'READY', 'SERVED'] 
                        : ['PLACED', 'PREPARING', 'READY', 'DELIVERED'];
                    
                    let currentStatusIdx = statusList.indexOf(selectedOrder.status);
                    
                    // Map intermediate or beyond statuses to the last visible step
                    if (selectedOrder.status === 'CONFIRMED') currentStatusIdx = 0;
                    if (selectedOrder.order_type === 'DINING' && ['COMPLETED'].includes(selectedOrder.status)) {
                        currentStatusIdx = 3;
                    }
                    if (['OUT_FOR_DELIVERY'].includes(selectedOrder.status)) {
                        currentStatusIdx = 2; // Still in Ready/Dispatch phase visually
                    }
                    if (selectedOrder.status === 'COMPLETED' || selectedOrder.status === 'DELIVERED') {
                        currentStatusIdx = 3;
                    }

                    return statusList.map((s, i) => (
                        <div key={s} className="flex flex-col items-center gap-2 flex-1 relative">
                            <div className={clsx(
                                "w-6 h-6 rounded-full flex items-center justify-center text-[10px] font-bold transition-all duration-500 z-10",
                                i <= currentStatusIdx ? "bg-slate-900 text-white shadow-lg scale-110" : "bg-slate-100 text-slate-400"
                            )}>
                                {i + 1}
                            </div>
                            <span className={clsx("text-[9px] font-black uppercase tracking-tighter", i <= currentStatusIdx ? "text-slate-900" : "text-slate-300")}>
                                {s === 'READY' && selectedOrder.order_type === 'DINING' ? 'READY' : s}
                            </span>
                            {i < 3 && <div className={clsx("absolute top-3 left-[calc(50%+10px)] w-[calc(100%-20px)] h-[1.5px]", i < currentStatusIdx ? "bg-slate-900" : "bg-slate-100 segment-line")}></div>}
                        </div>
                    ));
                })()}
             </div>
          </div>

          {/* Customer & Payment */}
          <div className="grid grid-cols-2 gap-4">
            <div className="p-4 bg-white rounded-2xl border border-slate-100 shadow-sm">
              <p className="text-[10px] uppercase font-black text-slate-400 mb-2">Customer</p>
              <h4 className="font-bold text-slate-800">{selectedOrder.userId?.name || 'Guest'}</h4>
              <p className="text-sm text-slate-500">{selectedOrder.userId?.mobile || 'No contact'}</p>
            </div>
            <div className="p-4 bg-white rounded-2xl border border-slate-100 shadow-sm">
              <p className="text-[10px] uppercase font-black text-slate-400 mb-2">Payment</p>
              <div className="flex items-center gap-2">
                <CreditCard className="w-4 h-4 text-slate-400" />
                <h4 className="font-bold text-slate-800">{selectedOrder.paymentMethod || 'COD'}</h4>
              </div>
              <span className={clsx(
                "text-[10px] font-black uppercase tracking-widest mt-1 inline-block",
                selectedOrder.paymentStatus === 'PAID' || selectedOrder.paymentStatus === 'SUCCESS' ? "text-emerald-600" : "text-amber-500"
              )}>
                • {selectedOrder.paymentStatus}
              </span>
            </div>
          </div>

          {/* Table Info if Dining */}
          {selectedOrder.order_type === 'DINING' && selectedOrder.tableId && (
            <div className="p-4 bg-orange-50/50 rounded-2xl border border-orange-100 flex items-center justify-between">
                <div className="flex items-center gap-3">
                    <div className="w-10 h-10 bg-white shadow-sm border border-orange-200 rounded-xl flex items-center justify-center text-orange-500 font-black">
                        {selectedOrder.tableId.tableNumber}
                    </div>
                    <div>
                        <h4 className="text-sm font-bold text-slate-800">Table {selectedOrder.tableId.tableNumber}</h4>
                        <p className="text-xs text-slate-500">Dining In Location</p>
                    </div>
                </div>
                <div className="flex flex-col items-end gap-1">
                    <div className="px-3 py-1 bg-white border border-orange-100 rounded-full text-[10px] font-black text-orange-600 uppercase">
                        {selectedOrder.tableId.status}
                    </div>
                    {selectedOrder.sessionId && (
                        <span className="text-[9px] font-black text-slate-400 opacity-60">
                            SID: {String(selectedOrder.sessionId).substring(String(selectedOrder.sessionId).length - 6).toUpperCase()}
                        </span>
                    )}
                </div>
            </div>
          )}

          {/* Delivery Address if Online */}
          {selectedOrder.order_type === 'ONLINE' && (
            <div>
               <h3 className="text-xs font-black uppercase tracking-widest text-slate-400 mb-4 px-2">Delivery Location</h3>
               <div className="p-4 bg-white border border-slate-100 rounded-2xl flex items-start gap-4 shadow-sm">
                 <div className="w-10 h-10 bg-red-50 rounded-xl flex items-center justify-center text-red-500 shadow-sm border border-red-100">
                   <MapPin className="w-5 h-5" />
                 </div>
                 <div className="flex-1">
                   <h4 className="font-bold text-slate-800 mb-1">{selectedOrder.deliveryAddress?.label || 'Home'}</h4>
                   <p className="text-sm text-slate-500 leading-relaxed font-medium">
                     {typeof selectedOrder.deliveryAddress === 'string' 
                       ? selectedOrder.deliveryAddress 
                       : `${selectedOrder.deliveryAddress?.addressLine}, ${selectedOrder.deliveryAddress?.area}, ${selectedOrder.deliveryAddress?.city}`}
                   </p>
                 </div>
               </div>
            </div>
          )}

          {/* Items */}
          <div>
            <h3 className="text-xs font-black uppercase tracking-widest text-slate-400 mb-4 px-2">Order Summary</h3>
            <div className="space-y-3">
              {selectedOrder.items?.map((item, idx) => (
                <div key={idx} className="flex items-center justify-between p-3 bg-white rounded-xl border border-slate-100 shadow-sm">
                  <div className="flex items-center gap-3">
                    <div className="w-8 h-8 font-black text-xs text-slate-400 border border-slate-100 rounded-lg flex items-center justify-center bg-slate-50">{item.quantity}x</div>
                    <span className="font-bold text-slate-800">{item.name || item.menuId?.name || 'Item'}</span>
                  </div>
                  <span className="font-bold text-slate-800">₹{(item.price || item.menuId?.price) * item.quantity}</span>
                </div>
              ))}
            </div>
          </div>

          {/* Billing Detail */}
          <div className="p-6 bg-slate-900 rounded-[32px] text-white shadow-xl relative overflow-hidden group">
             <div className="absolute top-0 right-0 w-32 h-32 bg-white/5 blur-[80px] rounded-full"></div>
             <div className="space-y-4 relative z-10">
                 <div className="flex justify-between items-center text-slate-400 text-sm font-medium">
                    <span>Subtotal</span>
                    <span className="font-bold">₹{Math.round(selectedOrder.subtotal || (selectedOrder.totalAmount - (selectedOrder.gst || 0) - (selectedOrder.deliveryFee || 0)))}</span>
                 </div>
                 {selectedOrder.gst > 0 && (
                  <div className="flex justify-between items-center text-slate-400 text-sm font-medium">
                      <span>Taxes & Charges (GST)</span>
                      <span className="font-bold">₹{Math.round(selectedOrder.gst)}</span>
                  </div>
                 )}
                 {selectedOrder.deliveryFee > 0 && (
                  <div className="flex justify-between items-center text-slate-400 text-sm font-medium">
                      <span>Delivery Fee</span>
                      <span className="font-bold">₹{Math.round(selectedOrder.deliveryFee)}</span>
                  </div>
                 )}
                 {selectedOrder.discountAmount > 0 && (
                  <div className="flex justify-between text-slate-400 text-sm font-medium">
                    <span>Coupon Discount</span>
                    <span className="text-emerald-400 font-bold">-₹{selectedOrder.discountAmount}</span>
                  </div>
                )}
                 <div className="flex justify-between items-center pt-2 border-t border-white/10 mt-2">
                    <span className="text-white text-sm font-bold">Grand Total</span>
                    <span className="text-2xl font-black text-white">₹{Math.round(selectedOrder.totalAmount)}</span>
                </div>
                <div className="pt-4 border-t border-white/10 flex justify-between items-center">
                   <p className="text-[10px] text-slate-500 font-black tracking-widest uppercase">Current State</p>
                   <span className="font-black text-amber-500 tracking-tight uppercase text-sm bg-amber-500/10 px-3 py-1 rounded-full">{selectedOrder.status}</span>
                </div>
             </div>
          </div>
        </div>

        {/* Action Footer */}
        <div className="p-6 border-t border-slate-100 bg-white shadow-[0_-10px_40px_rgba(0,0,0,0.04)]">
            {/* Phase 5 — Admin panel button logic (minimal change) */}
            
            {/* 1. CONFIRM ORDER (Common) */}
            {selectedOrder.status === 'PLACED' && (
              <button 
                onClick={() => updateStatus(selectedOrder._id, 'CONFIRMED')} 
                className="w-full py-4 bg-blue-600 text-white rounded-2xl text-sm font-black tracking-widest uppercase hover:bg-blue-700 active:scale-[0.98] transition-all shadow-lg"
              >
                CONFIRM ORDER
              </button>
            )}

            {/* 2. PROCEED TO KITCHEN / PREPARING (Common) */}
            {['CONFIRMED'].includes(selectedOrder.status) && (
              <button 
                onClick={() => updateStatus(selectedOrder._id, 'PREPARING')} 
                className="w-full py-4 bg-slate-900 text-white rounded-2xl text-sm font-black tracking-widest uppercase hover:bg-slate-800 active:scale-[0.98] transition-all shadow-lg"
              >
                PROCEED TO KITCHEN
              </button>
            )}

            {/* 3. READY (Shared but descriptive) */}
            {selectedOrder.status === 'PREPARING' && (
              <button 
                onClick={() => updateStatus(selectedOrder._id, selectedOrder.order_type === 'TAKEAWAY' ? 'READY_FOR_PICKUP' : 'READY')} 
                className="w-full py-4 bg-amber-500 text-white rounded-2xl text-sm font-black tracking-widest uppercase hover:bg-amber-600 active:scale-[0.98] transition-all shadow-lg"
              >
                {selectedOrder.order_type === 'TAKEAWAY' ? 'READY FOR PICKUP' : 'MARK AS READY'}
              </button>
            )}

            {/* 4. ONLINE SPECIFIC FLOW */}
            {selectedOrder.order_type === 'ONLINE' && (
              <>
                {selectedOrder.status === 'READY' && (
                  <button 
                    onClick={() => updateStatus(selectedOrder._id, 'OUT_FOR_DELIVERY')} 
                    className="w-full py-4 bg-indigo-600 text-white rounded-2xl text-sm font-black tracking-widest uppercase hover:bg-indigo-700 active:scale-[0.98] transition-all shadow-lg"
                  >
                    DISPATCH ORDER
                  </button>
                )}
                {selectedOrder.status === 'OUT_FOR_DELIVERY' && (
                  <button 
                    onClick={() => updateStatus(selectedOrder._id, 'DELIVERED')} 
                    className="w-full py-4 bg-emerald-600 text-white rounded-2xl text-sm font-black tracking-widest uppercase hover:bg-emerald-700 active:scale-[0.98] transition-all shadow-lg"
                  >
                    MARK AS DELIVERED
                  </button>
                )}
              </>
            )}

            {/* 5. DINING SPECIFIC FLOW */}
            {selectedOrder.order_type === 'DINING' && (
              <>
                {selectedOrder.status === 'READY' && (
                  <button 
                    onClick={() => updateStatus(selectedOrder._id, 'SERVED')} 
                    className="w-full py-4 bg-emerald-600 text-white rounded-2xl text-sm font-black tracking-widest uppercase hover:bg-emerald-700 active:scale-[0.98] transition-all shadow-lg"
                  >
                    SERVE TO TABLE
                  </button>
                )}
                {selectedOrder.status === 'SERVED' && (
                  <button 
                    onClick={() => updateStatus(selectedOrder._id, 'COMPLETED')} 
                    className="w-full py-4 bg-indigo-600 text-white rounded-2xl text-sm font-black tracking-widest uppercase hover:bg-indigo-700 active:scale-[0.98] transition-all shadow-lg"
                  >
                    COMPLETE BILL
                  </button>
                )}
              </>
            )}
            
            {/* 6. CANCEL ORDER (Safety) */}
            {!['COMPLETED', 'DELIVERED', 'CANCELLED'].includes(selectedOrder.status) && (
              <button 
                onClick={async () => {
                   if(window.confirm("Are you sure you want to cancel this order? This cannot be undone.")) {
                       try {
                           await apiService.patch(`/order-enhanced/${selectedOrder._id}/cancel`, { cancellationReason: "Admin cancelled from dashboard" });
                           fetchOrders();
                           setSelectedOrder(null);
                       } catch(e) {
                           alert(e.response?.data?.message || "Failed to cancel order");
                       }
                   }
                }}
                className="w-full py-4 mt-2 bg-white border-2 border-rose-100 text-rose-600 rounded-2xl text-sm font-black tracking-widest uppercase hover:bg-rose-50 active:scale-[0.98] transition-all"
              >
                CANCEL ORDER
              </button>
            )}

            {selectedOrder.order_type === 'DINING' && selectedOrder.sessionId && (
              <div className="flex flex-col gap-3 pt-4 border-t border-slate-100">
                <div className="flex items-center justify-between px-2">
                  <span className="text-[10px] font-black text-slate-400 uppercase tracking-widest">Counter Payment Control (MODEL-2)</span>
                  {selectedOrder.status === 'WAITING_PAYMENT' && <span className="text-[9px] bg-purple-100 text-purple-700 px-2 py-0.5 rounded-full font-black animate-pulse">BILL REQUESTED</span>}
                </div>
                <div className="grid grid-cols-3 gap-2">
                  <button 
                    onClick={async () => {
                       if (confirm(`Settle Bill ₹${Math.round(selectedOrder.totalAmount)} using UPI?`)) {
                          try {
                            await apiService.post("dining/verify-payment", { 
                              sessionId: selectedOrder.sessionId,
                              paymentMethod: 'UPI'
                            });
                            fetchOrders();
                          } catch (err) { alert(err.response?.data?.message || "Verify failed"); }
                       }
                    }} 
                    className="py-3 bg-white border border-emerald-200 text-emerald-600 rounded-xl text-[10px] font-black uppercase hover:bg-emerald-600 hover:text-white transition-all shadow-sm"
                  >
                    UPI
                  </button>
                  <button 
                    onClick={async () => {
                       if (confirm(`Settle Bill ₹${Math.round(selectedOrder.totalAmount)} using CASH?`)) {
                          try {
                            await apiService.post("dining/verify-payment", { 
                              sessionId: selectedOrder.sessionId,
                              paymentMethod: 'CASH'
                            });
                            fetchOrders();
                          } catch (err) { alert(err.response?.data?.message || "Verify failed"); }
                       }
                    }} 
                    className="py-3 bg-white border border-emerald-200 text-emerald-600 rounded-xl text-[10px] font-black uppercase hover:bg-emerald-600 hover:text-white transition-all shadow-sm"
                  >
                    CASH
                  </button>
                  <button 
                    onClick={async () => {
                       if (confirm(`Settle Bill ₹${Math.round(selectedOrder.totalAmount)} using CARD?`)) {
                          try {
                            await apiService.post("dining/verify-payment", { 
                              sessionId: selectedOrder.sessionId,
                              paymentMethod: 'CARD'
                            });
                            fetchOrders();
                          } catch (err) { alert(err.response?.data?.message || "Verify failed"); }
                       }
                    }} 
                    className="py-3 bg-white border border-emerald-200 text-emerald-600 rounded-xl text-[10px] font-black uppercase hover:bg-emerald-600 hover:text-white transition-all shadow-sm"
                  >
                    CARD
                  </button>
                </div>
                
                <div className="flex gap-2">
                  <button 
                    onClick={async () => {
                      if (confirm("End session and free table? Ensure customer has left.")) {
                        try {
                          await apiService.post("dining/close-session", { sessionId: selectedOrder.sessionId });
                          fetchOrders();
                          setSelectedOrder(null);
                        } catch (err) { alert(err.response?.data?.message || "Close session failed"); }
                      }
                    }} 
                    className="flex-1 py-3 bg-slate-900 text-white rounded-xl text-[10px] font-black uppercase hover:bg-slate-800 transition-all shadow-lg"
                  >
                    End Session & Free Table
                  </button>
                </div>
              </div>
            )}
           </div>
        </div>
    );
  };

  return (
    <div className="flex flex-col gap-6 h-full pb-10">
      <div className="flex md:items-center justify-between flex-col md:flex-row gap-4">
        <div>
          <h1 className="text-3xl font-black text-slate-900 tracking-tighter uppercase">Ordering Central</h1>
          <p className="text-slate-500 font-medium text-sm flex items-center gap-2 mt-1">
              <span className="w-2 h-2 bg-emerald-500 rounded-full animate-pulse shadow-[0_0_8px_rgb(16,185,129)]"></span>
              Real-time synchronization active
          </p>
        </div>
        
        <div className="flex items-center gap-3">
          <div className="relative shadow-sm rounded-2xl group flex-1 md:flex-none">
            <Search className="w-4 h-4 absolute left-4 top-1/2 -translate-y-1/2 text-slate-400 group-focus-within:text-slate-900 transition-colors" />
            <input 
              type="text" 
              placeholder="Filter by No, Name..." 
              value={searchTerm}
              onChange={(e) => setSearchTerm(e.target.value)}
              className="pl-11 pr-4 py-3 bg-white border border-slate-200 rounded-2xl text-sm font-bold focus:outline-none focus:ring-4 focus:ring-slate-900/5 focus:border-slate-900 transition-all w-full md:w-64"
            />
          </div>
          
          <div className="relative">
            <Filter className="w-4 h-4 absolute left-3 top-1/2 -translate-y-1/2 text-slate-400 pointer-events-none" />
            <select 
                value={statusFilter}
                onChange={(e) => {
                    setStatusFilter(e.target.value);
                    setCurrentPage(1);
                }}
                className="pl-9 pr-8 py-3 bg-white border border-slate-200 rounded-2xl text-xs font-black uppercase tracking-widest focus:outline-none focus:ring-4 focus:ring-slate-900/5 appearance-none cursor-pointer shadow-sm min-w-[140px]"
            >
                <option value="ALL">All States</option>
                {ORDER_STATUSES.map(s => <option key={s} value={s}>{s.replaceAll('_', ' ')}</option>)}
            </select>
          </div>
        </div>
      </div>

      {/* Tabs - Only show if not fixedType */}
      {!fixedType && (
        <div className="flex gap-2 p-1.5 bg-white/60 backdrop-blur-md rounded-[20px] w-max border border-white/40 shadow-sm">
            {tabs.map(tab => (
            <button
                key={tab.id}
                onClick={() => {
                    setActiveTab(tab.id);
                    setCurrentPage(1);
                }}
                className={clsx(
                "flex items-center gap-2 px-6 py-2.5 rounded-2xl text-xs font-black uppercase tracking-widest transition-all duration-300",
                activeTab === tab.id 
                    ? "bg-slate-900 text-white shadow-xl translate-y-[-1px]" 
                    : "text-slate-400 hover:text-slate-900 hover:bg-slate-50"
                )}
            >
                <tab.icon className={clsx("w-4 h-4", activeTab === tab.id ? "text-white" : "text-slate-400")} />
                {tab.label}
            </button>
            ))}
        </div>
      )}

      {/* Main List Area */}
      <div className="flex-1 overflow-y-auto pr-2 rounded-3xl flex flex-col gap-3 min-h-[400px]">
        {loading ? (
           <div className="flex-1 flex flex-col items-center justify-center text-slate-400 gap-4">
             <div className="w-10 h-10 border-4 border-slate-200 border-t-slate-900 rounded-full animate-spin"></div>
             <p className="text-xs font-black uppercase tracking-widest">Compiling Orders...</p>
           </div>
        ) : filteredOrders.length === 0 ? (
          <div className="flex-1 flex flex-col items-center justify-center text-slate-400 gap-6 bg-white/40 border border-dashed border-slate-200 rounded-[40px]">
            <div className="w-20 h-20 bg-slate-50 flex items-center justify-center rounded-3xl border border-slate-100 shadow-inner">
                <ShoppingCart className="w-10 h-10 text-slate-200" />
            </div>
            <div className="text-center">
                <h3 className="font-black text-slate-900 uppercase text-sm tracking-widest">No matching orders</h3>
                <p className="text-xs font-medium text-slate-400 mt-2">Adjust your filters or type to find what you're looking for.</p>
            </div>
          </div>
        ) : activeTab === "DINING" && !searchTerm ? (
            // SECTION 16: DINING GROUPED VIEW
            <div className="space-y-12 pb-10">
                {groupDiningOrders().map(group => (
                    <div key={group.id} className="space-y-4">
                         <div className="flex items-center justify-between px-2">
                             <div className="flex items-center gap-4">
                               <div className="w-12 h-12 bg-slate-900 text-amber-500 rounded-2xl flex items-center justify-center font-black text-xl shadow-lg border-2 border-slate-800">
                                   {group.table?.tableNumber || '?'}
                               </div>
                               <div>
                                   <h4 className="font-black text-slate-900 uppercase tracking-tighter text-lg">Table {group.table?.tableNumber}</h4>
                                   <div className="flex items-center gap-2">
                                       <span className="text-[10px] font-black text-slate-400 uppercase tracking-widest">{group.orders.length} ORDERS</span>
                                       <span className="w-1 h-1 bg-slate-300 rounded-full"></span>
                                       <span className={clsx(
                                           "text-[10px] font-black uppercase tracking-widest",
                                           group.orders.some(o => o.paymentStatus === 'PENDING_VERIFICATION') ? "text-amber-500" : "text-slate-400"
                                       )}>
                                           {group.orders.some(o => o.paymentStatus === 'PENDING_VERIFICATION') ? "Verification Pending" : "In Session"}
                                       </span>
                                   </div>
                               </div>
                             </div>
                             {group.session_id && (
                               <button 
                                 onClick={async (e) => {
                                   e.stopPropagation();
                                   if (confirm(`End session for Table ${group.table?.tableNumber}?`)) {
                                      try {
                                        await apiService.post("/admin/dining/close-session", { sessionId: group.session_id });
                                        fetchOrders();
                                      } catch (err) {
                                        alert(err.response?.data?.message || "Failed to close session");
                                      }
                                   }
                                 }}
                                 className="px-4 py-2 bg-slate-900 text-white text-[10px] font-black uppercase rounded-xl hover:bg-slate-800 shadow-md"
                               >
                                 End Session
                               </button>
                             )}
                         </div>
                         <div className="grid grid-cols-1 xl:grid-cols-2 gap-4">
                            {group.orders.map(order => <OrderCard key={order._id} order={order} />)}
                         </div>
                    </div>
                ))}
            </div>
        ) : (
          <>
            {filteredOrders.map(order => <OrderCard key={order._id} order={order} />)}
            
            {/* Pagination Controls */}
            {totalOrders > limit && (
                <div className="flex items-center justify-center gap-2 py-8">
                    <button 
                        disabled={currentPage === 1}
                        onClick={() => setCurrentPage(p => p - 1)}
                        className="p-2 bg-white border border-slate-200 rounded-xl disabled:opacity-30 disabled:cursor-not-allowed hover:bg-slate-50 transition-all font-bold text-xs"
                    >
                        PREV
                    </button>
                    <div className="bg-white border border-slate-200 px-4 py-2 rounded-xl text-xs font-black">
                        PAGE {currentPage}
                    </div>
                    <button 
                        disabled={currentPage * limit >= totalOrders}
                        onClick={() => setCurrentPage(p => p + 1)}
                        className="p-2 bg-white border border-slate-200 rounded-xl disabled:opacity-30 disabled:cursor-not-allowed hover:bg-slate-50 transition-all font-bold text-xs"
                    >
                        NEXT
                    </button>
                </div>
            )}
          </>
        )}
      </div>

      <OrderDetailsPanel />

      <audio ref={audioRef} src="https://assets.mixkit.co/active_storage/sfx/2358/2358-preview.mp3" preload="auto" />
    </div>
  );
}
