"use client";

import { useEffect, useState } from "react";
import { 
  CalendarDays, 
  CheckCircle, 
  XCircle, 
  Phone, 
  Users, 
  MessageSquare, 
  Clock, 
  Loader2,
  Bell,
} from "lucide-react";
import apiService from "@/services/apiService";
import socketService from "@/services/socketService";
import { motion, AnimatePresence } from "framer-motion";
import clsx from "clsx";

export default function BookingsPage() {
  const [bookings, setBookings] = useState([]);
  const [isLoading, setIsLoading] = useState(true);
  const [isUpdating, setIsUpdating] = useState(null);
  const [error, setError] = useState(null);

  useEffect(() => {
    fetchBookings();

    const handleNewBooking = () => {
      fetchBookings();
    };

    const handleStatusUpdate = () => {
      fetchBookings();
    };

    socketService.connect();
    socketService.on("booking:new", handleNewBooking);
    socketService.on("booking:statusUpdated", handleStatusUpdate);

    return () => {
      socketService.off("booking:new", handleNewBooking);
      socketService.off("booking:statusUpdated", handleStatusUpdate);
    };
  }, []);

  const fetchBookings = async () => {
    try {
      setIsLoading(true);
      setError(null);
      const res = await apiService.get('/admin/bookings');
      if (res.data.success) {
        setBookings(res.data.data || []);
      } else {
        setError(res.data.message || "Failed to fetch bookings");
      }
    } catch (err) {
      console.error("Failed to fetch bookings:", err);
      setError(err.response?.data?.message || err.message || "Network Error");
    } finally {
      setIsLoading(false);
    }
  };

  const updateStatus = async (id, status) => {
    try {
      setIsUpdating(id);
      await apiService.put(`/admin/bookings/${id}/status`, { status });
      fetchBookings();
    } catch (err) {
      console.error("Failed to update status:", err);
      alert("Error updating status.");
    } finally {
      setIsUpdating(null);
    }
  };

  const getStatusColor = (status) => {
    switch (status) {
      case 'PENDING': return 'bg-amber-100 text-amber-700 border-amber-200';
      case 'APPROVED': return 'bg-blue-100 text-blue-700 border-blue-200';
      case 'REJECTED': return 'bg-rose-100 text-rose-700 border-rose-200';
      case 'CANCELLED': return 'bg-slate-100 text-slate-500 border-slate-200';
      case 'COMPLETED': return 'bg-emerald-100 text-emerald-700 border-emerald-200';
      default: return 'bg-slate-100 text-slate-700 border-slate-200';
    }
  };

  return (
    <div className="flex flex-col gap-6 h-full p-4 md:p-0">
      <div className="flex items-center justify-between">
        <div>
          <h1 className="text-3xl font-black text-slate-900 tracking-tighter uppercase">Reservation Desk</h1>
          <p className="text-slate-500 text-sm font-bold mt-1 flex items-center gap-2">
              <span className="w-2 h-2 bg-emerald-500 rounded-full animate-pulse shadow-[0_0_8px_rgb(16,185,129)]"></span>
              Live Booking Registry
          </p>
        </div>
        <button 
          onClick={fetchBookings} 
          disabled={isLoading}
          className="p-3 bg-white border border-slate-200 rounded-2xl text-slate-600 hover:bg-slate-50 transition-all shadow-sm active:scale-95 disabled:opacity-50"
        >
          <Bell className={clsx("w-6 h-6", isLoading && "animate-spin")} />
        </button>
      </div>

      {error && (
        <motion.div 
          initial={{ opacity: 0, y: -10 }}
          animate={{ opacity: 1, y: 0 }}
          className="bg-rose-50 border border-rose-200 text-rose-600 p-4 rounded-2xl text-sm font-medium flex items-center justify-between"
        >
          <div className="flex items-center gap-3">
            <XCircle className="w-5 h-5 flex-shrink-0" />
            <span>{error}</span>
          </div>
          <button onClick={fetchBookings} className="px-3 py-1 bg-rose-100 hover:bg-rose-200 rounded-lg transition-colors">Retry</button>
        </motion.div>
      )}

      <div className="bg-white rounded-[32px] shadow-[0_8px_30px_rgb(0,0,0,0.04)] border border-slate-100 overflow-hidden">
        <div className="overflow-x-auto">
          <table className="w-full text-left border-collapse min-w-[1000px]">
            <thead>
              <tr className="bg-slate-50/50 border-b border-slate-100">
                <th className="px-6 py-5 font-black text-slate-400 text-[10px] uppercase tracking-widest italic opacity-70">ID & Status</th>
                <th className="px-6 py-5 font-black text-slate-400 text-[10px] uppercase tracking-widest">Customer Details</th>
                <th className="px-6 py-5 font-black text-slate-400 text-[10px] uppercase tracking-widest">Date & Time</th>
                <th className="px-6 py-5 font-black text-slate-400 text-[10px] uppercase tracking-widest">Occasion & Requests</th>
                <th className="px-6 py-5 font-black text-slate-400 text-[10px] text-right uppercase tracking-widest">Management Actions</th>
              </tr>
            </thead>
            <tbody>
              {isLoading ? (
                <tr>
                  <td colSpan="5" className="p-20 text-center">
                    <Loader2 className="w-10 h-10 animate-spin text-amber-500 mx-auto mb-4" />
                    <p className="text-slate-500 font-black uppercase text-[10px] tracking-widest">Compiling Reservation Data...</p>
                  </td>
                </tr>
              ) : bookings.length === 0 ? (
                <tr>
                  <td colSpan="5" className="p-24 text-center text-slate-400">
                    <div className="flex flex-col items-center gap-3">
                      <div className="w-16 h-16 bg-slate-50 rounded-[20px] border border-slate-100 flex items-center justify-center mb-2">
                        <CalendarDays className="w-8 h-8 opacity-20" />
                      </div>
                      <p className="font-black uppercase text-xs tracking-widest">Zero entries found</p>
                    </div>
                  </td>
                </tr>
              ) : (
                <AnimatePresence>
                  {bookings.map((b, idx) => (
                    <motion.tr 
                      key={b._id}
                      initial={{ opacity: 0, y: 10 }}
                      animate={{ opacity: 1, y: 0 }}
                      transition={{ delay: idx * 0.05 }}
                      className="border-b border-slate-50 last:border-0 hover:bg-slate-50/80 transition-all duration-300 group"
                    >
                      <td className="px-6 py-6">
                        <div className="flex flex-col gap-2">
                          <span className="text-[10px] font-black font-mono text-slate-300 uppercase tracking-tighter">REF: {b._id.slice(-6).toUpperCase()}</span>
                          <span className={clsx("px-3 py-1 rounded-full text-[9px] font-black uppercase tracking-widest border w-fit shadow-sm", getStatusColor(b.status))}>
                            {b.status}
                          </span>
                        </div>
                      </td>
                      <td className="px-6 py-6 font-bold">
                        <div className="flex items-center gap-4">
                          <div className="w-12 h-12 bg-white rounded-2xl flex items-center justify-center font-black text-slate-600 border border-slate-200 shadow-sm transition-transform group-hover:scale-110">
                            {b.userId?.name?.[0]?.toUpperCase() || 'U'}
                          </div>
                          <div className="flex flex-col">
                            <span className="text-sm font-black text-slate-800 tracking-tight">{b.userId?.name || 'Walk-in Guest'}</span>
                            <div className="flex items-center gap-2 mt-1">
                              <span className="text-[10px] text-slate-400 font-bold uppercase tracking-tighter">{b.userId?.mobile || 'NO CONTACT'}</span>
                              {b.userId?.mobile && (
                                <a 
                                  href={`tel:${b.userId.mobile}`}
                                  className="p-1.5 hover:bg-amber-100 text-amber-600 rounded-lg transition-colors"
                                  title="Call Customer"
                                >
                                  <Phone className="w-3 h-3" />
                                </a>
                              )}
                            </div>
                          </div>
                        </div>
                      </td>
                      <td className="px-6 py-6">
                        <div className="flex flex-col gap-1.5">
                          <div className="flex items-center gap-2 text-slate-800 font-black text-sm">
                            <Clock className="w-4 h-4 text-slate-400" />
                            {b.timeSlot}
                          </div>
                          <div className="flex items-center gap-2 text-slate-400 text-[10px] font-bold uppercase">
                            <CalendarDays className="w-3 h-3" />
                            {new Date(b.bookingDate).toLocaleDateString('en-GB', { day: '2-digit', month: 'short', year: 'numeric' })}
                          </div>
                        </div>
                      </td>
                      <td className="px-6 py-6">
                        <div className="flex flex-col gap-3 max-w-[250px]">
                          <div className="flex items-center gap-2">
                            <div className="flex items-center gap-1.5 px-2.5 py-1 bg-slate-900 text-white rounded-lg text-[10px] font-black">
                                <Users className="w-3 h-3 shadow-sm" />
                                {b.guestCount} SEATS
                            </div>
                            {b.occasion && (
                              <span className="px-2.5 py-1 bg-amber-50 text-amber-600 text-[10px] font-black uppercase tracking-widest rounded-lg border border-amber-100">
                                {b.occasion}
                              </span>
                            )}
                          </div>
                          {b.specialRequest ? (
                            <div className="flex items-start gap-2 p-3 bg-white rounded-xl border border-slate-100 shadow-inner">
                              <MessageSquare className="w-3 h-3 text-slate-300 mt-0.5 shrink-0" />
                              <span className="text-[10px] text-slate-500 font-medium italic leading-relaxed">"{b.specialRequest}"</span>
                            </div>
                          ) : (
                            <span className="text-[10px] text-slate-300 italic font-medium px-1">No special instructions provided</span>
                          )}
                        </div>
                      </td>
                      <td className="px-6 py-6 text-right">
                        <div className="flex gap-2 justify-end items-center">
                          {isUpdating === b._id ? (
                            <div className="w-10 h-10 flex items-center justify-center bg-slate-50 rounded-2xl border border-slate-100">
                                <Loader2 className="w-5 h-5 animate-spin text-slate-900" />
                            </div>
                          ) : (
                            <>
                              {b.status === 'PENDING' && (
                                <>
                                  <button 
                                    onClick={() => updateStatus(b._id, 'APPROVED')}
                                    className="px-5 py-2.5 bg-emerald-600 text-white rounded-xl text-[10px] font-black uppercase tracking-widest hover:bg-emerald-700 shadow-lg shadow-emerald-500/10 active:scale-95 transition-all font-bold"
                                  >
                                    Approve
                                  </button>
                                  <button 
                                    onClick={() => updateStatus(b._id, 'REJECTED')}
                                    className="px-5 py-2.5 bg-rose-50 text-rose-600 border border-rose-100 rounded-xl text-[10px] font-black uppercase tracking-widest hover:bg-rose-100 active:scale-95 transition-all font-bold"
                                  >
                                    Reject
                                  </button>
                                </>
                              )}
                              {b.status === 'APPROVED' && (
                                <button 
                                    onClick={() => updateStatus(b._id, 'COMPLETED')}
                                    className="px-6 py-2.5 bg-slate-900 text-white rounded-xl text-[10px] font-black uppercase tracking-widest hover:bg-slate-800 shadow-xl active:scale-95 transition-all font-bold"
                                >
                                    Complete Session
                                </button>
                              )}
                              {b.status === 'COMPLETED' && (
                                <div className="flex items-center gap-2 px-4 py-2 bg-emerald-50 text-emerald-600 rounded-xl text-[10px] font-black uppercase tracking-widest border border-emerald-100 shadow-inner">
                                    <CheckCircle className="w-3 h-3" />
                                    Completed
                                </div>
                              )}
                              {(b.status === 'REJECTED' || b.status === 'CANCELLED') && (
                                <div className="flex items-center gap-2 px-4 py-2 bg-slate-50 text-slate-400 rounded-xl text-[10px] font-black uppercase tracking-widest border border-slate-100 shadow-inner opacity-50">
                                    <XCircle className="w-3 h-3" />
                                    Closed
                                </div>
                              )}
                            </>
                          )}
                        </div>
                      </td>
                    </motion.tr>
                  ))}
                </AnimatePresence>
              )}
            </tbody>
          </table>
        </div>
      </div>
    </div>
  );
}
