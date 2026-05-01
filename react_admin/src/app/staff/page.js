"use client";

import { useState, useEffect } from "react";
import { motion, AnimatePresence } from "framer-motion";
import { 
  ShieldCheck, 
  Users, 
  Plus, 
  MoreVertical, 
  Lock, 
  Unlock,
  Key,
  ShieldAlert,
  Edit2,
  Trash2
} from "lucide-react";
import apiService from "@/services/apiService";
import clsx from "clsx";

const ROLES = [
  { id: 'admin', label: 'Super Admin', color: 'bg-indigo-500', icon: ShieldCheck },
  { id: 'manager', label: 'Store Manager', color: 'bg-emerald-500', icon: ShieldCheck },
  { id: 'kitchen', label: 'Chef/Kitchen', color: 'bg-amber-500', icon: ShieldCheck },
  { id: 'delivery', label: 'Delivery Boy', color: 'bg-blue-500', icon: ShieldCheck },
];

export default function StaffManagementPage() {
  const [staff, setStaff] = useState([]);
  const [loading, setLoading] = useState(true);

  // Note: For now we use the main profile endpoint or a mock as we need a specific staff endpoint
  const [showAddModal, setShowAddModal] = useState(false);
  const [newStaff, setNewStaff] = useState({ name: '', email: '', password: '', role: 'kitchen' });

  useEffect(() => {
    fetchStaff();
  }, []);

  const fetchStaff = async () => {
    try {
      setLoading(true);
      const res = await apiService.get("/admin/staff");
      if (res.data.success) {
        setStaff(res.data.data);
      }
    } catch (err) {
      console.error("Failed to fetch staff");
    } finally {
      setLoading(false);
    }
  };

  const handleAddStaff = async (e) => {
    e.preventDefault();
    try {
      const res = await apiService.post("/admin/staff", newStaff);
      if (res.data.success) {
        setShowAddModal(false);
        setNewStaff({ name: '', email: '', password: '', role: 'kitchen' });
        fetchStaff();
      }
    } catch (err) {
      alert(err.response?.data?.message || "Failed to add staff");
    }
  };

  const handleDeleteStaff = async (id) => {
      if(window.confirm("Are you sure you want to revoke this operative's access?")) {
          try {
              const res = await apiService.delete(`/admin/staff/${id}`);
              if(res.data.success) fetchStaff();
          } catch(err) {
              alert(err.response?.data?.message || "Failed to delete staff");
          }
      }
  };

  return (
    <div className="flex flex-col gap-10 h-full pb-20 relative">
      {/* Add Staff Modal */}
      <AnimatePresence>
        {showAddModal && (
          <motion.div 
            initial={{ opacity: 0 }} animate={{ opacity: 1 }} exit={{ opacity: 0 }}
            className="fixed inset-0 z-50 flex items-center justify-center p-4 bg-slate-900/40 backdrop-blur-sm"
          >
            <motion.div 
              initial={{ scale: 0.9, y: 20 }} animate={{ scale: 1, y: 0 }} exit={{ scale: 0.9, y: 20 }}
              className="bg-white rounded-[32px] p-8 w-full max-w-md shadow-2xl"
            >
              <h2 className="text-2xl font-black text-slate-900 uppercase tracking-tighter mb-6">Recruit Staff</h2>
              <form onSubmit={handleAddStaff} className="space-y-4">
                <div>
                  <label className="text-[10px] font-black uppercase text-slate-400">Full Name</label>
                  <input required value={newStaff.name} onChange={e=>setNewStaff({...newStaff, name: e.target.value})} className="w-full mt-1 px-4 py-3 bg-slate-50 border border-slate-100 rounded-xl text-sm font-bold focus:outline-none focus:ring-2 focus:ring-indigo-500" placeholder="John Doe" />
                </div>
                <div>
                  <label className="text-[10px] font-black uppercase text-slate-400">Email Address</label>
                  <input type="email" required value={newStaff.email} onChange={e=>setNewStaff({...newStaff, email: e.target.value})} className="w-full mt-1 px-4 py-3 bg-slate-50 border border-slate-100 rounded-xl text-sm font-bold focus:outline-none focus:ring-2 focus:ring-indigo-500" placeholder="john@govardhan.com" />
                </div>
                <div>
                  <label className="text-[10px] font-black uppercase text-slate-400">Secure Password</label>
                  <input type="password" required value={newStaff.password} onChange={e=>setNewStaff({...newStaff, password: e.target.value})} className="w-full mt-1 px-4 py-3 bg-slate-50 border border-slate-100 rounded-xl text-sm font-bold focus:outline-none focus:ring-2 focus:ring-indigo-500" placeholder="••••••••" />
                </div>
                <div>
                  <label className="text-[10px] font-black uppercase text-slate-400">Assigned Role</label>
                  <select required value={newStaff.role} onChange={e=>setNewStaff({...newStaff, role: e.target.value})} className="w-full mt-1 px-4 py-3 bg-slate-50 border border-slate-100 rounded-xl text-sm font-bold focus:outline-none focus:ring-2 focus:ring-indigo-500">
                    {ROLES.map(r => <option key={r.id} value={r.id}>{r.label}</option>)}
                  </select>
                </div>
                <div className="flex gap-3 pt-4">
                  <button type="button" onClick={() => setShowAddModal(false)} className="flex-1 py-3 bg-slate-100 text-slate-500 rounded-xl text-[10px] font-black uppercase tracking-widest hover:bg-slate-200">Cancel</button>
                  <button type="submit" className="flex-1 py-3 bg-indigo-600 text-white rounded-xl text-[10px] font-black uppercase tracking-widest hover:bg-indigo-700 shadow-lg">Confirm</button>
                </div>
              </form>
            </motion.div>
          </motion.div>
        )}
      </AnimatePresence>

      {/* Header */}
      <div className="flex items-center justify-between bg-white p-10 rounded-[48px] shadow-sm border border-slate-100 relative overflow-hidden">
        <div className="absolute top-0 left-0 w-full h-full bg-indigo-500/5 blur-[100px] skew-x-12"></div>
        <div className="relative z-10 flex items-center gap-8">
           <div className="w-20 h-20 bg-slate-900 text-amber-500 rounded-[32px] flex items-center justify-center shadow-2xl flex-shrink-0">
              <ShieldCheck className="w-10 h-10" />
           </div>
           <div>
              <h1 className="text-4xl font-black text-slate-900 tracking-tighter uppercase">Staff Forge</h1>
              <p className="text-xs font-black text-slate-400 uppercase tracking-widest mt-2 flex items-center gap-2">
                 <span className="w-2 h-2 bg-emerald-500 rounded-full"></span>
                 Access Control & Identity Management
              </p>
           </div>
        </div>
        <button onClick={() => setShowAddModal(true)} className="relative z-10 px-8 py-4 bg-slate-900 text-white rounded-2xl font-black text-[10px] uppercase tracking-widest shadow-2xl flex items-center gap-3 hover:bg-slate-800 transition-all">
            <Plus className="w-4 h-4" />
            Recruit Staff
        </button>
      </div>

      {/* Role Definitions */}
      <div className="grid grid-cols-1 md:grid-cols-4 gap-6">
        {ROLES.map(role => (
          <div key={role.id} className="bg-white p-6 rounded-[32px] border border-slate-100 shadow-sm flex flex-col gap-4 group hover:border-indigo-200 transition-all">
             <div className={clsx("w-12 h-12 rounded-2xl flex items-center justify-center text-white shadow-lg", role.color)}>
                <role.icon className="w-6 h-6" />
             </div>
             <div>
                <h4 className="font-black text-slate-800 uppercase text-xs tracking-widest">{role.label}</h4>
                <p className="text-[10px] font-bold text-slate-400 mt-1 uppercase">Full Access Permissions</p>
             </div>
          </div>
        ))}
      </div>

      {/* Staff List Table */}
      <div className="bg-white rounded-[48px] border border-slate-100 shadow-sm overflow-hidden h-full flex flex-col">
        <div className="p-10 border-b border-slate-50 flex items-center justify-between">
            <h3 className="text-xs font-black uppercase tracking-widest text-slate-400">Personnel Directory</h3>
            <div className="px-5 py-2 bg-slate-50 border border-slate-100 rounded-full text-[10px] font-black uppercase text-slate-400 flex items-center gap-3">
               <Users className="w-3 h-3" />
               {staff.length} ACTIVE OPERATIVES
            </div>
        </div>

        <div className="flex-1 overflow-y-auto">
           {loading ? (
             <div className="p-20 flex flex-col items-center justify-center gap-4">
                <div className="w-10 h-10 border-4 border-slate-100 border-t-indigo-500 rounded-full animate-spin"></div>
                <p className="text-[10px] font-black uppercase tracking-widest text-slate-300">Authenticating Directory...</p>
             </div>
           ) : (
             <table className="w-full text-left">
                <thead>
                   <tr className="bg-slate-50/50">
                      <th className="px-10 py-6 text-[10px] font-black text-slate-400 uppercase tracking-widest">Employee</th>
                      <th className="px-10 py-6 text-[10px] font-black text-slate-400 uppercase tracking-widest">Permission Role</th>
                      <th className="px-10 py-6 text-[10px] font-black text-slate-400 uppercase tracking-widest">Status</th>
                      <th className="px-10 py-6 text-[10px] font-black text-slate-400 uppercase tracking-widest text-right">Actions</th>
                   </tr>
                </thead>
                <tbody className="divide-y divide-slate-50 italic font-medium">
                   {staff.map((person, idx) => (
                      <tr key={person._id || idx} className="group hover:bg-slate-50/50 transition-all cursor-pointer">
                         <td className="px-10 py-8">
                            <div className="flex items-center gap-4">
                               <div className="w-12 h-12 bg-slate-100 rounded-2xl flex items-center justify-center text-slate-300 font-black text-lg border border-slate-200 uppercase">
                                  {person.name?.[0]}
                               </div>
                               <div>
                                  <h4 className="font-black text-slate-900 uppercase not-italic">{person.name}</h4>
                                  <p className="text-[10px] text-slate-400 font-bold not-italic">{person.email}</p>
                               </div>
                            </div>
                         </td>
                         <td className="px-10 py-8">
                            <div className="flex items-center gap-2 px-4 py-2 bg-slate-100 w-max rounded-xl border border-slate-200/50">
                               <ShieldAlert className="w-3 h-3 text-indigo-500" />
                               <span className="text-[10px] font-black uppercase tracking-widest text-slate-800 not-italic">{person.role || 'admin'}</span>
                            </div>
                         </td>
                         <td className="px-10 py-8">
                            <div className="flex items-center gap-2">
                               <div className="w-2 h-2 bg-emerald-500 rounded-full animate-pulse shadow-[0_0_8px_#10B981]"></div>
                               <span className="text-[10px] font-black text-emerald-600 uppercase not-italic">Encrypted Active</span>
                            </div>
                         </td>
                         <td className="px-10 py-8 text-right">
                            <div className="flex items-center justify-end gap-2 opacity-0 group-hover:opacity-100 transition-opacity">
                               <button className="p-3 bg-white border border-slate-200 rounded-xl text-slate-600 hover:bg-slate-900 hover:text-white transition-all"><Edit2 className="w-4 h-4" /></button>
                               <button className="p-3 bg-white border border-slate-200 rounded-xl text-slate-600 hover:bg-slate-900 hover:text-white transition-all"><Key className="w-4 h-4" /></button>
                               <button onClick={() => handleDeleteStaff(person._id)} className="p-3 bg-white border border-slate-200 rounded-xl text-rose-600 hover:bg-rose-600 hover:text-white transition-all"><Trash2 className="w-4 h-4" /></button>
                            </div>
                         </td>
                      </tr>
                   ))}
                </tbody>
             </table>
           )}
        </div>
      </div>
    </div>
  );
}
