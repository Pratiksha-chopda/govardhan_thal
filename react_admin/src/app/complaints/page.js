"use client";

import { useState, useEffect } from "react";
import { AlertCircle, FileText, CheckCircle, Clock, Loader2, X } from "lucide-react";
import apiService from "@/services/apiService";
import clsx from "clsx";

export default function ComplaintsPage() {
  const [complaints, setComplaints] = useState([]);
  const [loading, setLoading] = useState(true);
  const [showModal, setShowModal] = useState(false);
  const [selectedComplaint, setSelectedComplaint] = useState(null);
  const [adminNote, setAdminNote] = useState("");
  const [updateStatus, setUpdateStatus] = useState("RESOLVED");
  const [submitting, setSubmitting] = useState(false);

  const fetchComplaints = async () => {
    try {
      setLoading(true);
      const res = await apiService.get("/order-enhanced/admin/complaints");
      setComplaints(res.data.data?.complaints || []);
    } catch (err) {
      console.error("Failed to fetch complaints", err);
    } finally {
      setLoading(false);
    }
  };

  useEffect(() => {
    fetchComplaints();
  }, []);

  const openResolveModal = (c) => {
    setSelectedComplaint(c);
    setUpdateStatus(c.status === 'OPEN' ? 'IN_PROGRESS' : 'RESOLVED');
    setAdminNote(c.adminNote || "");
    setShowModal(true);
  };

  const handleUpdateComplaint = async (e) => {
    e.preventDefault();
    try {
      setSubmitting(true);
      await apiService.patch(`/order-enhanced/admin/complaints/${selectedComplaint._id}/status`, {
         status: updateStatus,
         adminNote
      });
      setShowModal(false);
      fetchComplaints();
    } catch (err) {
      alert("Failed to update complaint");
    } finally {
      setSubmitting(false);
    }
  };

  const StatusBadge = ({ status }) => {
    const colors = {
      OPEN:         "bg-rose-100 text-rose-700 border-rose-200",
      IN_PROGRESS:  "bg-amber-100 text-amber-700 border-amber-200",
      RESOLVED:     "bg-emerald-100 text-emerald-700 border-emerald-200",
      CLOSED:       "bg-slate-100 text-slate-700 border-slate-200",
    };
    return (
      <span className={clsx("px-3 py-1 text-[9px] font-black uppercase tracking-widest rounded-full border shadow-sm", colors[status] || 'bg-slate-100 text-slate-600')}>
        {status.replace('_', ' ')}
      </span>
    );
  };

  const TypeBadge = ({ type }) => {
      const displayType = type.replaceAll('_', ' ');
      return (
         <span className="px-2.5 py-1 bg-slate-900 text-white rounded-lg text-[9px] font-black uppercase tracking-widest">
            {displayType}
         </span>
      );
  };

  return (
    <div className="flex flex-col gap-6 h-full p-4 md:p-0">
      <div className="flex justify-between items-center bg-white p-8 rounded-[32px] shadow-sm border border-slate-100 relative overflow-hidden">
        <div className="absolute top-0 right-0 w-64 h-64 bg-rose-100/30 blur-[100px] rounded-full point-events-none"></div>
        <div className="relative z-10">
          <h1 className="text-4xl font-black text-rose-900 tracking-tighter uppercase">Support Tickets</h1>
          <p className="text-slate-500 font-bold mt-1 tracking-widest text-xs uppercase flex items-center gap-2">
             <span className="w-2 h-2 bg-rose-500 rounded-full animate-pulse"></span> Issue Resolution Center
          </p>
        </div>
      </div>

      <div className="bg-white rounded-[40px] shadow-sm border border-slate-100 overflow-hidden">
        <div className="overflow-x-auto">
          <table className="w-full text-left border-collapse min-w-[1000px]">
            <thead>
              <tr className="bg-slate-50/50 border-b border-slate-100">
                <th className="px-8 py-6 font-black text-slate-400 text-[10px] uppercase tracking-widest">Ticket INFO</th>
                <th className="px-8 py-6 font-black text-slate-400 text-[10px] uppercase tracking-widest">Customer Details</th>
                <th className="px-8 py-6 font-black text-slate-400 text-[10px] uppercase tracking-widest">Issue Reported</th>
                <th className="px-8 py-6 font-black text-slate-400 text-[10px] text-right uppercase tracking-widest">Action</th>
              </tr>
            </thead>
            <tbody>
              {loading ? (
                 <tr>
                    <td colSpan="4" className="p-24 text-center">
                       <div className="flex flex-col items-center gap-4">
                           <div className="w-12 h-12 border-4 border-slate-200 border-t-rose-500 rounded-full animate-spin"></div>
                           <p className="font-black uppercase text-xs text-slate-400 tracking-widest">Fetching Tickets...</p>
                       </div>
                    </td>
                 </tr>
              ) : complaints.length === 0 ? (
                 <tr>
                    <td colSpan="4" className="p-24 text-center">
                        <div className="flex flex-col items-center gap-3">
                            <div className="w-16 h-16 bg-slate-50 rounded-[20px] border border-slate-100 flex items-center justify-center mb-2">
                                <CheckCircle className="w-8 h-8 text-emerald-500 opacity-50" />
                            </div>
                            <p className="font-black uppercase text-xs text-slate-400 tracking-widest">Zero Active Complaints</p>
                        </div>
                    </td>
                 </tr>
              ) : complaints.map((c) => (
                 <tr key={c._id} className="border-b border-slate-50 last:border-0 hover:bg-slate-50/50 transition-all">
                    <td className="px-8 py-6">
                       <div className="flex flex-col gap-2 items-start">
                          <span className="text-[10px] font-black font-mono text-slate-400 tracking-tighter">ID: {c._id.slice(-6).toUpperCase()}</span>
                          <StatusBadge status={c.status} />
                          <div className="flex items-center gap-1.5 text-[9px] font-bold text-slate-400 uppercase mt-1">
                             <Clock className="w-3 h-3"/>
                             {new Date(c.createdAt).toLocaleDateString()}
                          </div>
                       </div>
                    </td>
                    <td className="px-8 py-6">
                       <div className="flex flex-col">
                          <span className="text-sm font-black text-slate-800 tracking-tight">{c.userId?.name || 'Guest'}</span>
                          <span className="text-[10px] font-bold text-slate-400 tracking-widest uppercase">{c.userId?.email || c.userId?.mobile}</span>
                          <span className="text-[9px] font-black text-slate-400 uppercase tracking-widest mt-2 border border-slate-200 px-2 py-0.5 rounded w-fit">
                             Order: {c.orderId?._id?.slice(-6).toUpperCase()}
                          </span>
                       </div>
                    </td>
                    <td className="px-8 py-6">
                       <div className="flex flex-col max-w-xs gap-3">
                          <div className="flex items-center gap-2">
                             <TypeBadge type={c.issueType} />
                          </div>
                          <div className="bg-white p-3 border border-slate-100 rounded-xl shadow-inner">
                             <p className="text-xs text-slate-600 font-medium italic">"{c.description || 'No description provided'}"</p>
                          </div>
                          {c.adminNote && (
                             <div className="bg-amber-50 p-2.5 rounded-lg border border-amber-100">
                                <p className="text-[9px] text-amber-700 font-black tracking-widest uppercase mb-1">Admin Response:</p>
                                <p className="text-[10px] font-medium text-amber-600">{c.adminNote}</p>
                             </div>
                          )}
                       </div>
                    </td>
                    <td className="px-8 py-6 text-right">
                       <button 
                          onClick={() => openResolveModal(c)}
                          className="px-5 py-2.5 bg-white border border-slate-200 text-slate-700 rounded-xl text-[10px] font-black uppercase tracking-widest hover:bg-slate-900 hover:text-white hover:border-slate-900 hover:shadow-xl transition-all active:scale-95 shadow-sm"
                       >
                          Resolve
                       </button>
                    </td>
                 </tr>
              ))}
            </tbody>
          </table>
        </div>
      </div>

      {showModal && selectedComplaint && (
        <div className="fixed inset-0 bg-slate-900/40 backdrop-blur-sm z-[100] flex items-center justify-center p-6">
          <div className="bg-white w-full max-w-lg rounded-[2rem] shadow-2xl overflow-hidden animate-in zoom-in-95 duration-200">
            <div className="p-8 border-b border-slate-100 flex items-center justify-between bg-slate-50">
               <div>
                 <h2 className="text-2xl font-black text-slate-900 tracking-tight">Resolve Ticket</h2>
                 <p className="text-slate-500 text-sm mt-1">ID: {selectedComplaint._id.slice(-6).toUpperCase()}</p>
               </div>
               <button onClick={() => setShowModal(false)} className="p-2.5 bg-white border border-slate-200 rounded-2xl hover:bg-slate-100 transition-colors">
                 <X className="w-5 h-5 text-slate-600" />
               </button>
            </div>

            <form onSubmit={handleUpdateComplaint} className="p-8 space-y-6">
               <div className="space-y-4">
                  <div>
                    <label className="text-xs font-black uppercase tracking-widest text-slate-400 mb-2 block">Ticket Status *</label>
                    <select 
                      value={updateStatus}
                      onChange={e => setUpdateStatus(e.target.value)}
                      className="w-full px-5 py-3.5 bg-slate-50 border border-slate-100 rounded-2xl font-bold text-slate-800 focus:outline-none focus:ring-4 focus:ring-rose-500/10 focus:border-rose-300"
                    >
                      <option value="OPEN">OPEN - Reviewing</option>
                      <option value="IN_PROGRESS">IN PROGRESS - Investigating</option>
                      <option value="RESOLVED">RESOLVED - Issue fixed</option>
                      <option value="CLOSED">CLOSED - No action needed</option>
                    </select>
                  </div>
                  <div>
                    <label className="text-xs font-black uppercase tracking-widest text-slate-400 mb-2 block">Internal Note / Resolution</label>
                    <textarea 
                      value={adminNote}
                      onChange={e => setAdminNote(e.target.value)}
                      placeholder="e.g., Refund issued to customer wallet..."
                      rows="3"
                      className="w-full px-5 py-3.5 bg-slate-50 border border-slate-100 rounded-2xl font-medium text-slate-800 focus:outline-none focus:ring-4 focus:ring-rose-500/10 focus:border-rose-300"
                    />
                  </div>
               </div>

               <div className="pt-4 flex gap-4">
                  <button 
                    disabled={submitting}
                    type="submit"
                    className="w-full py-4 bg-slate-900 text-white rounded-2xl font-black shadow-lg shadow-slate-900/20 hover:bg-black active:scale-95 transition-all uppercase tracking-widest flex items-center justify-center gap-2"
                  >
                    {submitting && <Loader2 className="w-4 h-4 animate-spin" />}
                    Update Ticket
                  </button>
               </div>
            </form>
          </div>
        </div>
      )}
    </div>
  );
}
