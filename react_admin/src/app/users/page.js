"use client";

import { useState, useEffect } from "react";
import { Users, Mail, ShoppingBag, Eye, Calendar, Phone, Search, X } from "lucide-react";
import apiService from "@/services/apiService";
import { motion, AnimatePresence } from "framer-motion";
import clsx from "clsx";

export default function UsersPage() {
  const [users, setUsers] = useState([]);
  const [loading, setLoading] = useState(true);
  const [searchTerm, setSearchTerm] = useState("");
  const [selectedUser, setSelectedUser] = useState(null);

  const fetchUsers = async () => {
    try {
      setLoading(true);
      const res = await apiService.get("/admin/users?limit=100");
      setUsers(res.data.data?.users || []);
    } catch (err) {
      console.error("Failed to fetch users:", err);
    } finally {
      setLoading(false);
    }
  };

  useEffect(() => {
    fetchUsers();
  }, []);

  const filteredUsers = users.filter(user => 
    user.name?.toLowerCase().includes(searchTerm.toLowerCase()) ||
    user.email?.toLowerCase().includes(searchTerm.toLowerCase()) ||
    user.mobile?.includes(searchTerm)
  );

  return (
    <div className="flex flex-col gap-8 h-full pb-10">
      <div className="flex flex-col md:flex-row md:items-center justify-between gap-4 bg-white p-8 rounded-[32px] shadow-sm border border-slate-100">
        <div>
          <h1 className="text-4xl font-black text-slate-900 tracking-tighter uppercase">Customer Directory</h1>
          <p className="text-slate-500 mt-2 font-bold flex items-center gap-2">
              <span className="w-2 h-2 bg-blue-500 rounded-full animate-pulse"></span>
              Live User Insights
          </p>
        </div>
        
        <div className="relative group w-full md:w-96">
            <Search className="absolute left-4 top-1/2 -translate-y-1/2 w-5 h-5 text-slate-400 group-focus-within:text-blue-500 transition-colors" />
            <input 
                type="text" 
                placeholder="Search name, email or phone..." 
                value={searchTerm}
                onChange={(e) => setSearchTerm(e.target.value)}
                className="w-full pl-12 pr-4 py-4 bg-slate-50 border border-slate-100 rounded-[20px] text-sm font-bold focus:bg-white focus:outline-none focus:ring-4 focus:ring-blue-500/5 focus:border-blue-200 transition-all shadow-inner"
            />
        </div>
      </div>

      <div className="bg-white rounded-[40px] shadow-sm border border-slate-100 overflow-hidden">
        <div className="overflow-x-auto">
          <table className="w-full text-left border-collapse min-w-[1000px]">
            <thead>
              <tr className="bg-slate-50/50 border-b border-slate-100">
                <th className="px-8 py-6 font-black text-slate-400 text-[10px] uppercase tracking-widest">User Profile</th>
                <th className="px-8 py-6 font-black text-slate-400 text-[10px] uppercase tracking-widest">Contact Information</th>
                <th className="px-8 py-6 text-center font-black text-slate-400 text-[10px] uppercase tracking-widest">Order Frequency</th>
                <th className="px-8 py-6 text-center font-black text-slate-400 text-[10px] uppercase tracking-widest">Last Interaction</th>
                <th className="px-8 py-6 font-black text-slate-400 text-[10px] text-right uppercase tracking-widest">Account Hub</th>
              </tr>
            </thead>
            <tbody>
              {loading ? (
                <tr>
                  <td colSpan="5" className="p-24 text-center">
                    <div className="flex flex-col items-center gap-4">
                        <div className="w-12 h-12 border-4 border-slate-200 border-t-blue-500 rounded-full animate-spin"></div>
                        <p className="font-black uppercase text-xs text-slate-400 tracking-widest">Retrieving User Database...</p>
                    </div>
                  </td>
                </tr>
              ) : filteredUsers.length === 0 ? (
                <tr>
                    <td colSpan="5" className="p-24 text-center">
                        <div className="flex flex-col items-center gap-3">
                            <div className="w-16 h-16 bg-slate-50 rounded-[20px] border border-slate-100 flex items-center justify-center mb-2">
                                <Users className="w-8 h-8 opacity-20" />
                            </div>
                            <p className="font-black uppercase text-xs text-slate-400 tracking-widest">No users match your criteria</p>
                        </div>
                    </td>
                </tr>
              ) : (
                <AnimatePresence>
                  {filteredUsers.map((user, idx) => (
                    <motion.tr 
                      key={user._id}
                      initial={{ opacity: 0, y: 10 }}
                      animate={{ opacity: 1, y: 0 }}
                      transition={{ delay: idx * 0.05 }}
                      className="border-b border-slate-50 last:border-0 hover:bg-slate-50/50 transition-all duration-300 group"
                    >
                      <td className="px-8 py-6">
                        <div className="flex items-center gap-4">
                          <div className={clsx(
                              "w-12 h-12 rounded-[18px] flex items-center justify-center font-black text-white shadow-lg transition-transform group-hover:scale-110",
                              idx % 3 === 0 ? "bg-amber-500 shadow-amber-500/20" : idx % 3 === 1 ? "bg-blue-500 shadow-blue-500/20" : "bg-purple-500 shadow-purple-500/20"
                          )}>
                            {user.name?.charAt(0).toUpperCase()}
                          </div>
                          <div className="flex flex-col">
                            <span className="text-sm font-black text-slate-800 tracking-tight">{user.name}</span>
                            <span className="text-[10px] font-black uppercase text-slate-400 tracking-widest">ID: {user._id.slice(-6).toUpperCase()}</span>
                          </div>
                        </div>
                      </td>
                      <td className="px-8 py-6">
                        <div className="flex flex-col gap-2">
                          <div className="flex items-center gap-2.5 text-slate-600">
                             <Mail className="w-3.5 h-3.5 text-slate-300" />
                             <span className="text-[11px] font-bold tracking-tight">{user.email || 'NO EMAIL'}</span>
                          </div>
                          <div className="flex items-center gap-2.5 text-slate-600">
                             <Phone className="w-3.5 h-3.5 text-slate-300" />
                             <span className="text-[11px] font-bold tracking-tight">{user.mobile || 'NO PHONE'}</span>
                          </div>
                        </div>
                      </td>
                      <td className="px-8 py-6 text-center">
                        <div className="inline-flex flex-col items-center">
                            <span className="text-xl font-black text-slate-900 tracking-tighter">{user.orderCount || 0}</span>
                            <span className="text-[9px] font-black uppercase text-slate-300 tracking-[0.2em] mt-1">Orders Completed</span>
                        </div>
                      </td>
                      <td className="px-8 py-6 text-center">
                        <div className="inline-flex flex-col items-center bg-slate-50 px-4 py-2.5 rounded-2xl border border-slate-100 min-w-[140px] shadow-inner group-hover:bg-white transition-colors">
                           <Calendar className="w-4 h-4 text-slate-400 mb-1" />
                           <span className="text-[10px] font-black text-slate-700 uppercase">
                               {user.lastOrderDate ? new Date(user.lastOrderDate).toLocaleDateString('en-GB', { day: '2-digit', month: 'short' }) : 'NEVER'}
                           </span>
                           <span className="text-[8px] font-black text-slate-400 uppercase tracking-widest mt-0.5">Last Order</span>
                        </div>
                      </td>
                      <td className="px-8 py-6 text-right">
                        <button 
                          onClick={() => setSelectedUser(user)}
                          className="px-5 py-2.5 bg-white border border-slate-200 text-slate-600 rounded-xl text-[10px] font-black uppercase tracking-widest hover:bg-slate-900 hover:text-white hover:border-slate-900 hover:shadow-xl transition-all active:scale-95 flex items-center gap-2 ml-auto shadow-sm"
                        >
                          <Eye className="w-3.5 h-3.5"/> Detail logs
                        </button>
                      </td>
                    </motion.tr>
                  ))}
                </AnimatePresence>
              )}
            </tbody>
          </table>
        </div>
      </div>

      {/* User Details Modal */}
      {selectedUser && (
        <div className="fixed inset-0 bg-slate-900/40 backdrop-blur-sm z-[100] flex items-center justify-center p-6">
          <div className="bg-white w-full max-w-lg rounded-[2rem] shadow-2xl overflow-hidden animate-in zoom-in-95 duration-200">
            <div className="p-8 border-b border-slate-100 flex items-center justify-between bg-slate-50">
               <div>
                 <h2 className="text-2xl font-black text-slate-900 tracking-tight">User Details</h2>
                 <p className="text-slate-500 text-sm mt-1">ID: {selectedUser._id}</p>
               </div>
               <button onClick={() => setSelectedUser(null)} className="p-2.5 bg-white border border-slate-200 rounded-2xl hover:bg-slate-100 transition-colors">
                 <X className="w-5 h-5 text-slate-600" />
               </button>
            </div>
            
            <div className="p-8 space-y-6">
               <div className="flex items-center gap-6 pb-6 border-b border-slate-100">
                  <div className="w-20 h-20 bg-blue-500 text-white rounded-[24px] flex items-center justify-center text-3xl font-black shadow-lg shadow-blue-500/20">
                    {selectedUser.name?.charAt(0).toUpperCase()}
                  </div>
                  <div>
                    <h3 className="text-2xl font-black text-slate-800">{selectedUser.name}</h3>
                    <div className="flex items-center gap-2 mt-2 text-slate-500 font-bold">
                       <Mail className="w-4 h-4"/> {selectedUser.email || 'No email provided'}
                    </div>
                    <div className="flex items-center gap-2 mt-1 text-slate-500 font-bold">
                       <Phone className="w-4 h-4"/> {selectedUser.mobile || 'No mobile provided'}
                    </div>
                  </div>
               </div>

               <div className="grid grid-cols-2 gap-4">
                  <div className="bg-slate-50 p-5 rounded-[20px] border border-slate-100 flex flex-col items-center justify-center text-center">
                     <ShoppingBag className="w-6 h-6 text-emerald-500 mb-2"/>
                     <span className="text-2xl font-black text-slate-800">{selectedUser.orderCount || 0}</span>
                     <span className="text-[10px] font-black uppercase text-slate-400 tracking-widest mt-1">Total Orders</span>
                  </div>
                  <div className="bg-slate-50 p-5 rounded-[20px] border border-slate-100 flex flex-col items-center justify-center text-center">
                     <Calendar className="w-6 h-6 text-amber-500 mb-2"/>
                     <span className="text-sm font-black text-slate-800 uppercase">
                         {selectedUser.lastOrderDate ? new Date(selectedUser.lastOrderDate).toLocaleDateString() : 'N/A'}
                     </span>
                     <span className="text-[10px] font-black uppercase text-slate-400 tracking-widest mt-1">Last Order</span>
                  </div>
               </div>

               <div className="pt-4">
                  <p className="text-xs font-bold text-center text-slate-400 bg-slate-50 py-3 rounded-xl border border-slate-100">
                     Detailed historical order breakdown module is currently pending integration.
                  </p>
               </div>
            </div>
          </div>
        </div>
      )}
    </div>
  );
}
