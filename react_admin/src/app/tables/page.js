"use client";

import { useState, useEffect } from "react";
import { PlusCircle, MoreVertical, Grid2X2, X, Check, Loader2, Trash2 } from "lucide-react";
import apiService from "@/services/apiService";
import socketService from "@/services/socketService";
import clsx from "clsx";

export default function TableManagementPage() {
  const [tables, setTables] = useState([]);
  const [activeSessions, setActiveSessions] = useState({});
  const [loading, setLoading] = useState(true);
  const [showModal, setShowModal] = useState(false);
  const [newTableNumber, setNewTableNumber] = useState("");
  const [newCapacity, setNewCapacity] = useState("4");
  const [submitting, setSubmitting] = useState(false);

  // Fetch all tables
  const fetchTables = async (isBackground = false) => {
    try {
      if (!isBackground) setLoading(true);
      const res = await apiService.get("/admin/tables");
      const tablesList = res.data.data?.data || res.data.data || [];
      setTables(tablesList);

      // Fetch active sessions for occupied tables
      const sessionsRes = await apiService.get("/admin/active-tables");
      const sessions = sessionsRes.data.data || [];
      const sessionMap = {};
      sessions.forEach(s => {
        if (s.activeSession) {
            sessionMap[s._id] = s.activeSession;
        }
      });
      setActiveSessions(sessionMap);
    } catch (err) {
      console.error("Failed to fetch tables", err);
    } finally {
      if (!isBackground) setLoading(false);
    }
  };

  useEffect(() => {
    fetchTables();
    
    // Connect to sockets for real-time table status flip
    socketService.connect();
    socketService.on("table:statusUpdated", fetchTables);
    socketService.on("dining:sessionStarted", fetchTables);
    socketService.on("dining:sessionClosed", fetchTables);
    socketService.on("dining:paymentUpdate", fetchTables);

    // Requirement 13: 5-second polling fallback
    const interval = setInterval(() => fetchTables(true), 5000);

    return () => {
      socketService.off("table:statusUpdated", fetchTables);
      socketService.off("dining:sessionStarted", fetchTables);
      socketService.off("dining:sessionClosed", fetchTables);
      socketService.off("dining:paymentUpdate", fetchTables);
      clearInterval(interval);
    };
  }, []);


  const closeSession = async (sessionId) => {
    if (!confirm("Are you sure you want to close this session? This will finalize the bill and free the table.")) return;
    try {
        await apiService.post("/admin/dining/close-session", { sessionId });
        fetchTables();
    } catch (err) {
        alert(err.response?.data?.message || "Failed to close session");
    }
  };

  const verifyPayment = async (sessionId, method) => {
    if (!confirm(`Confirm receipt of payment via ${method}?`)) return;
    try {
        await apiService.post("/admin/dining/verify-payment", { 
            sessionId,
            paymentMethod: method 
        });
        fetchTables();
    } catch (err) {
        alert(err.response?.data?.message || "Failed to verify payment");
    }
  };

  const handleRegisterTable = async (e) => {
    e.preventDefault();
    if (!newTableNumber || !newCapacity) return;
    try {
        setSubmitting(true);
        await apiService.post("/admin/tables", {
            tableNumber: parseInt(newTableNumber),
            capacity: parseInt(newCapacity)
        });
        setShowModal(false);
        setNewTableNumber("");
        fetchTables();
    } catch (err) {
        alert(err.response?.data?.message || "Failed to register table");
    } finally {
        setSubmitting(false);
    }
  };

  const updateTableStatus = async (tableId, status) => {
    try {
        await apiService.put(`/admin/tables/${tableId}`, { status });
        fetchTables();
    } catch (err) {
        alert(err.response?.data?.message || "Failed to update table status");
    }
  };

  const deleteTable = async (id) => {
    if (!window.confirm("Are you sure you want to delete this table?")) return;
    try {
        await apiService.delete(`/admin/tables/${id}`);
        fetchTables();
    } catch (err) {
        alert(err.response?.data?.message || "Failed to delete table");
    }
  };


  const StatusBadge = ({ status }) => {
    const colors = {
      AVAILABLE:         "bg-emerald-100 text-emerald-700 border-emerald-200",
      OCCUPIED:          "bg-red-100 text-red-700 border-red-200",
      RESERVED:          "bg-amber-100 text-amber-700 border-amber-200",
      CLEANING:          "bg-slate-100 text-slate-700 border-slate-200",
      PREPARING:         "bg-orange-100 text-orange-700 border-orange-200",
      BILL_REQUESTED:    "bg-purple-100 text-purple-700 border-purple-200",
      PAID_WAITING_EXIT: "bg-blue-100 text-blue-700 border-blue-200",
    };

    return (
      <span className={clsx(
        "px-4 py-1.5 text-[10px] font-black uppercase tracking-widest rounded-full shadow-sm mt-3 border border-white/50",
        colors[status] || 'bg-slate-100 text-slate-600'
      )}>
        {status}
      </span>
    );
  };

  return (
    <div className="flex flex-col gap-8 h-full pb-10">
      <div className="flex items-center justify-between bg-white p-8 rounded-[32px] shadow-sm border border-slate-100 relative overflow-hidden">
        <div className="absolute top-0 right-0 w-64 h-64 bg-amber-100/30 blur-[100px] rounded-full"></div>
        <div className="relative z-10">
          <h1 className="text-4xl font-black text-slate-900 tracking-tighter uppercase">Floor Intelligence</h1>
          <p className="text-slate-500 mt-2 font-bold flex items-center gap-2">
              <span className="w-2 h-2 bg-emerald-500 rounded-full animate-pulse"></span>
              Live Floor Tracking
          </p>
        </div>
        <button 
          onClick={() => setShowModal(true)}
          className="relative z-10 flex items-center gap-3 bg-slate-900 text-white px-8 py-4 rounded-2xl font-black text-sm uppercase tracking-widest shadow-xl shadow-slate-900/20 hover:shadow-2xl hover:scale-[1.02] active:scale-95 transition-all"
        >
          <PlusCircle className="w-5 h-5"/>
          Register Table
        </button>
      </div>

      <div className="flex-1 overflow-y-auto pr-2 pb-6 grid grid-cols-1 sm:grid-cols-2 md:grid-cols-2 lg:grid-cols-3 xl:grid-cols-4 gap-8">
        {loading ? (
          <div className="col-span-full h-80 flex flex-col items-center justify-center text-slate-400">
             <div className="w-12 h-12 border-4 border-slate-200 border-t-amber-500 rounded-full animate-spin mb-4"></div>
             <p className="font-bold tracking-widest uppercase text-xs">Mapping Floor Plan...</p>
          </div>
        ) : tables.length === 0 ? (
           <div className="col-span-full h-80 flex flex-col items-center justify-center text-slate-400 bg-white rounded-[40px] border border-dashed border-slate-200">
             <Grid2X2 className="w-20 h-20 text-slate-100 mb-6" />
             <p className="font-black uppercase tracking-widest text-sm">No floor map detected</p>
           </div>
        ) : tables.map(table => {
          const session = activeSessions[table._id];
          return (
            <div key={table._id} className={clsx(
                "bg-white p-8 rounded-[40px] shadow-sm border-2 flex flex-col items-center hover:shadow-2xl transition-all relative overflow-hidden group",
                table.status === 'OCCUPIED' ? 'border-red-100 ring-4 ring-red-500/5' : 
                table.status === 'BILL_REQUESTED' ? 'border-purple-100 ring-4 ring-purple-500/5' :
                table.status === 'PAID_WAITING_EXIT' ? 'border-blue-100 ring-4 ring-blue-500/5' :
                'border-slate-50'
            )}>

              <div className="absolute top-6 right-6 flex flex-col gap-2 opacity-0 group-hover:opacity-100 transition-opacity">
                <button 
                  onClick={() => deleteTable(table._id)}
                  className="p-3 bg-slate-50 border border-slate-100 rounded-2xl text-slate-400 hover:text-red-600 hover:bg-white hover:shadow-xl transition-all"
                  title="Delete Table"
                >
                    <Trash2 className="w-5 h-5"/>
                </button>
              </div>

              <div className={`w-28 h-28 rounded-[38px] flex items-center justify-center mb-6 transition-all shadow-inner border-4 relative ${
                table.status === 'AVAILABLE' ? 'bg-emerald-50 text-emerald-500 border-emerald-100 shadow-emerald-500/10' :
                table.status === 'OCCUPIED' ? 'bg-red-50 text-red-500 border-red-100 shadow-red-500/10' :
                table.status === 'RESERVED' ? 'bg-amber-50 text-amber-500 border-amber-100 shadow-amber-500/10' :
                table.status === 'PREPARING' ? 'bg-orange-50 text-orange-500 border-orange-100 shadow-orange-500/10' :
                table.status === 'BILL_REQUESTED' ? 'bg-purple-50 text-purple-500 border-purple-100 shadow-purple-500/10' :
                table.status === 'PAID_WAITING_EXIT' ? 'bg-blue-50 text-blue-500 border-blue-100 shadow-blue-500/10' :
                'bg-slate-50 text-slate-500 border-slate-100'

              }`}>
                <Grid2X2 className="w-12 h-12 drop-shadow-sm"/>
                {table.status === 'OCCUPIED' && (
                    <div className="absolute -top-2 -right-2 w-8 h-8 bg-red-500 text-white rounded-full flex items-center justify-center text-[10px] font-black border-4 border-white animate-bounce">
                        {session?.orders?.length || 0}
                    </div>
                )}
              </div>
              
              <h3 className="text-4xl font-black text-slate-900 tracking-tighter mb-1">Table {table.tableNumber}</h3>
              <p className="text-slate-400 text-[10px] font-black uppercase tracking-[0.2em]">{table.capacity} Person Capacity</p>
              
              <StatusBadge status={table.status} />

              {/* Manual Management Controls */}
              <div className="flex gap-2 mt-4 opacity-0 group-hover:opacity-100 transition-opacity">
                {table.status !== 'AVAILABLE' && (
                    <button 
                        onClick={() => updateTableStatus(table._id, 'AVAILABLE')}
                        className="px-3 py-1 bg-emerald-50 text-emerald-600 text-[9px] font-black uppercase rounded-lg border border-emerald-100 hover:bg-emerald-500 hover:text-white transition-all"
                        title="Mark Available"
                    >
                        Available
                    </button>
                )}
                {table.status !== 'CLEANING' && table.status !== 'OCCUPIED' && (
                    <button 
                        onClick={() => updateTableStatus(table._id, 'CLEANING')}
                        className="px-3 py-1 bg-blue-50 text-blue-600 text-[9px] font-black uppercase rounded-lg border border-blue-100 hover:bg-blue-500 hover:text-white transition-all"
                        title="Mark Cleaning"
                    >
                        Clean
                    </button>
                )}
              </div>

              {/* Session Details for Non-available tables */}
              {table.status !== 'AVAILABLE' && table.status !== 'CLEANING' && session && (

                <div className="w-full mt-8 p-6 bg-slate-50 rounded-[32px] border border-slate-100 space-y-4 shadow-inner">
                    <div className="flex justify-between items-center text-[10px] font-black text-slate-400 uppercase tracking-widest">
                        <span>Active Session</span>
                        {session.status === 'PAID_WAITING_EXIT' ? (
                            <span className="text-blue-500 animate-pulse font-black">PAID - WAITING EXIT</span>
                        ) : session.status === 'BILL_REQUESTED' ? (
                            <span className="text-purple-500 animate-pulse flex items-center gap-1 font-black">
                                <PlusCircle className="w-3 h-3 animate-spin" /> BILL REQUESTED
                            </span>
                        ) : (
                            <span className="text-red-500 animate-pulse">Live Session</span>
                        )}
                    </div>

                    <div className="flex flex-col gap-1">
                        <div className="flex items-center justify-between">
                            <p className="text-sm font-black text-slate-800">{session.userId?.name || 'Walk-in Guest'}</p>
                            <span className={clsx(
                                "text-[9px] font-black px-2 py-0.5 rounded border border-slate-200",
                                session.paymentStatus === 'SUCCESS' || session.paymentStatus === 'PAID' ? "bg-emerald-50 text-emerald-600 border-emerald-100" :
                                session.paymentStatus === 'PENDING_VERIFICATION' ? "bg-amber-50 text-amber-600 border-amber-100" :
                                "bg-white text-slate-400"
                            )}>
                                {session.paymentStatus.replaceAll('_', ' ')}
                            </span>
                        </div>
                        <div className="flex justify-between items-center">
                            <p className="text-[10px] font-bold text-slate-400 uppercase tracking-tight">Current Total: ₹{session.totalAmount || 0}</p>
                            {session.users?.length > 1 && (
                                <span className="text-[10px] font-black text-indigo-500 uppercase">+{session.users.length - 1} Guests Joined</span>
                            )}
                        </div>
                    </div>
                    
                    <div className="flex flex-col gap-2 pt-2">
                        {session.status !== 'PAID_WAITING_EXIT' && (
                            <div className="grid grid-cols-3 gap-2">
                                <button 
                                    onClick={() => verifyPayment(session._id, 'UPI')}
                                    className="py-2 bg-emerald-50 text-emerald-600 border border-emerald-100 rounded-xl text-[9px] font-black uppercase hover:bg-emerald-500 hover:text-white transition-all"
                                >
                                    UPI
                                </button>
                                <button 
                                    onClick={() => verifyPayment(session._id, 'CASH')}
                                    className="py-2 bg-emerald-50 text-emerald-600 border border-emerald-100 rounded-xl text-[9px] font-black uppercase hover:bg-emerald-500 hover:text-white transition-all"
                                >
                                    CASH
                                </button>
                                <button 
                                    onClick={() => verifyPayment(session._id, 'CARD')}
                                    className="py-2 bg-emerald-50 text-emerald-600 border border-emerald-100 rounded-xl text-[9px] font-black uppercase hover:bg-emerald-500 hover:text-white transition-all"
                                >
                                    CARD
                                </button>
                            </div>
                        )}
                        <button 
                            onClick={() => closeSession(session._id)}
                            className="w-full py-3 bg-white border-2 border-slate-200 text-slate-500 rounded-2xl text-[10px] font-black uppercase tracking-widest hover:bg-slate-50 active:scale-95 transition-all"
                        >
                            {session.status === 'PAID_WAITING_EXIT' ? "Complete & Free Table" : "Force Close Table"}
                        </button>
                    </div>
                </div>
              )}
            </div>
          );
        })}
      </div>

      {/* Register Table Modal */}
      {showModal && (
        <div className="fixed inset-0 z-[100] flex items-center justify-center p-4">
          <div className="absolute inset-0 bg-slate-900/60 backdrop-blur-md transition-opacity" onClick={() => !submitting && setShowModal(false)}></div>
          
          <div className="relative bg-white w-full max-w-md rounded-[40px] shadow-2xl overflow-hidden border border-white/20 animate-in zoom-in-95 duration-200">
            <div className="p-8">
              <div className="flex items-center justify-between mb-8">
                <div>
                  <h2 className="text-3xl font-black text-slate-900 tracking-tighter uppercase">New Table</h2>
                  <p className="text-slate-500 text-xs font-bold uppercase tracking-widest mt-1">Register Floor Asset</p>
                </div>
                <button 
                  onClick={() => setShowModal(false)}
                  disabled={submitting}
                  className="p-3 hover:bg-slate-100 rounded-2xl text-slate-400 transition-colors"
                >
                  <X className="w-6 h-6" />
                </button>
              </div>

              <form onSubmit={handleRegisterTable} className="space-y-6">
                <div className="space-y-2">
                  <label className="text-[10px] font-black text-slate-400 uppercase tracking-[0.2em] ml-2">Table Number</label>
                  <input 
                    autoFocus
                    required
                    type="number"
                    value={newTableNumber}
                    onChange={(e) => setNewTableNumber(e.target.value)}
                    placeholder="e.g. 7"
                    className="w-full bg-slate-50 border-2 border-slate-100 rounded-2xl px-6 py-4 font-bold text-lg focus:outline-none focus:border-amber-500 focus:ring-4 focus:ring-amber-500/5 transition-all text-slate-900"
                  />
                </div>

                <div className="space-y-2">
                  <label className="text-[10px] font-black text-slate-400 uppercase tracking-[0.2em] ml-2">Guest Capacity</label>
                  <select 
                    value={newCapacity}
                    onChange={(e) => setNewCapacity(e.target.value)}
                    className="w-full bg-slate-50 border-2 border-slate-100 rounded-2xl px-6 py-4 font-bold text-lg focus:outline-none focus:border-amber-500 focus:ring-4 focus:ring-amber-500/5 transition-all text-slate-900 appearance-none"
                  >
                    {[2, 4, 6, 8, 10, 12].map(num => (
                        <option key={num} value={num}>{num} Persons</option>
                    ))}
                  </select>
                </div>

                <div className="pt-4">
                  <button 
                    disabled={submitting}
                    type="submit"
                    className="w-full bg-slate-900 text-white py-5 rounded-[24px] font-black uppercase tracking-widest text-sm shadow-xl shadow-slate-900/20 hover:shadow-2xl hover:scale-[1.02] active:scale-95 disabled:opacity-50 disabled:scale-100 transition-all flex items-center justify-center gap-3"
                  >
                    {submitting ? (
                        <>
                            <Loader2 className="w-5 h-5 animate-spin" />
                            Registering...
                        </>
                    ) : (
                        <>
                            <Check className="w-5 h-5" />
                            Complete Registration
                        </>
                    )}
                  </button>
                </div>
              </form>
            </div>
          </div>
        </div>
      )}
    </div>
  );
}
