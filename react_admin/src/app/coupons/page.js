"use client";

import { useState, useEffect } from "react";
import { Ticket, Plus, Trash2, Calendar, Percent, IndianRupee, Activity, X } from "lucide-react";
import apiService from "@/services/apiService";
import clsx from "clsx";

export default function CouponsPage() {
  const [coupons, setCoupons] = useState([]);
  const [loading, setLoading] = useState(true);
  const [showModal, setShowModal] = useState(false);
  const [formData, setFormData] = useState({
    code: "",
    description: "",
    discountType: "percentage",
    discountValue: "",
    minOrderAmount: "",
    expiryDate: "",
    isActive: true,
    applicableFor: "BOTH"
  });

  const fetchCoupons = async () => {
    try {
      setLoading(true);
      const res = await apiService.get("/admin/coupons");
      setCoupons(res.data.data?.data || res.data.data || []);
    } catch (err) {
      console.error("Failed to fetch coupons", err);
    } finally {
      setLoading(false);
    }
  };

  useEffect(() => {
    fetchCoupons();
  }, []);

  const createCoupon = async (e) => {
    e.preventDefault();
    try {
      await apiService.post("/admin/coupons", formData);
      setShowModal(false);
      fetchCoupons();
      setFormData({
        code: "",
        description: "",
        discountType: "percentage",
        discountValue: "",
        minOrderAmount: "",
        expiryDate: "",
        isActive: true,
        applicableFor: "BOTH"
      });
    } catch (err) {
      alert("Failed to create coupon: " + (err.response?.data?.message || err.message));
    }
  };

  const deleteCoupon = async (id) => {
    if (!window.confirm("Are you sure?")) return;
    try {
      await apiService.delete(`/admin/coupons/${id}`);
      fetchCoupons();
    } catch (err) {
      console.error("Delete failed", err);
    }
  };

  return (
    <div className="flex flex-col gap-6 h-full">
      <div className="flex items-center justify-between">
        <div>
          <h1 className="text-3xl font-bold text-slate-900 tracking-tight">Offers & Coupons</h1>
          <p className="text-slate-500 mt-1">Manage promotional discounts and seasonal offers.</p>
        </div>
        <button 
          onClick={() => setShowModal(true)}
          className="flex items-center gap-2 bg-slate-900 text-white px-5 py-2.5 rounded-xl font-bold shadow-lg hover:shadow-xl hover:-translate-y-0.5 transition-all active:scale-95"
        >
          <Plus className="w-5 h-5"/>
          Create New Offer
        </button>
      </div>

      <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-6">
        {loading ? (
          <div className="col-span-full h-64 flex flex-col items-center justify-center text-slate-400">
            <div className="w-10 h-10 border-4 border-slate-200 border-t-amber-500 rounded-full animate-spin mb-4"></div>
            <p className="font-medium">Fetching active offers...</p>
          </div>
        ) : coupons.length === 0 ? (
          <div className="col-span-full h-64 flex flex-col items-center justify-center text-slate-400 bg-white rounded-3xl border border-dashed border-slate-200">
            <Ticket className="w-12 h-12 mb-4 opacity-20" />
            <p className="font-medium">No coupons active right now.</p>
            <button onClick={() => setShowModal(true)} className="mt-4 text-amber-600 font-bold hover:underline">Launch your first promotion</button>
          </div>
        ) : (
          coupons.map((coupon) => (
            <div key={coupon._id} className="bg-white rounded-3xl border border-slate-100 shadow-sm hover:shadow-xl hover:border-amber-200 transition-all p-6 relative overflow-hidden group">
              {/* Highlight Circle */}
              <div className="absolute top-[-20px] right-[-20px] w-24 h-24 bg-amber-50 rounded-full opacity-50 group-hover:scale-150 transition-transform duration-500"></div>
              
              <div className="flex justify-between items-start mb-6 relative">
                <div className="flex flex-col gap-2">
                  <div className="w-12 h-12 bg-amber-100 rounded-2xl flex items-center justify-center text-amber-600">
                    <Ticket className="w-6 h-6" />
                  </div>
                  <span className="text-[9px] font-black text-amber-600 bg-amber-50 px-2 py-0.5 rounded-md uppercase tracking-tighter">
                    {coupon.applicableFor || 'BOTH'}
                  </span>
                </div>
                <div className="flex items-center gap-2">
                   <span className={clsx(
                     "px-3 py-1 rounded-full text-[10px] font-black tracking-widest uppercase",
                     coupon.isActive ? "bg-emerald-50 text-emerald-600" : "bg-slate-100 text-slate-400"
                   )}>
                     {coupon.isActive ? "Active" : "Disabled"}
                   </span>
                   <button onClick={() => deleteCoupon(coupon._id)} className="p-2 text-slate-300 hover:text-red-500 transition-colors">
                     <Trash2 className="w-4 h-4" />
                   </button>
                </div>
              </div>

              <div className="mb-6">
                <h3 className="text-xl font-black text-slate-900 tracking-tight mb-1">{coupon.code}</h3>
                <p className="text-sm text-slate-500 font-medium">{coupon.description}</p>
              </div>

              <div className="grid grid-cols-2 gap-3 mb-6">
                <div className="p-3 bg-slate-50 rounded-2xl border border-slate-100 flex items-center gap-2">
                   {coupon.discountType === 'percentage' ? <Percent className="w-4 h-4 text-amber-500" /> : <IndianRupee className="w-4 h-4 text-amber-500" />}
                   <span className="font-black text-slate-800">{coupon.discountValue}{coupon.discountType === 'percentage' ? '%' : ' OFF'}</span>
                </div>
                <div className="p-3 bg-slate-50 rounded-2xl border border-slate-100 flex items-center gap-2">
                   <Activity className="w-4 h-4 text-blue-500" />
                   <span className="font-black text-slate-800">Min. ₹{coupon.minOrderAmount}</span>
                </div>
              </div>

              <div className="flex items-center justify-between pt-4 border-t border-slate-50">
                 <div className="flex items-center gap-2 text-slate-400">
                   <Calendar className="w-4 h-4" />
                   <span className="text-xs font-bold uppercase tracking-widest">{new Date(coupon.expiryDate).toLocaleDateString()}</span>
                 </div>
                 <div className="text-xs font-black text-amber-500 bg-amber-50 px-2 py-1 rounded-md uppercase">VALID {coupon.applicableFor || 'ALL'}</div>
              </div>
            </div>
          ))
        )}
      </div>

      {/* Create Modal */}
      {showModal && (
        <div className="fixed inset-0 bg-slate-900/40 backdrop-blur-sm z-[100] flex items-center justify-center p-6">
          <div className="bg-white w-full max-w-xl rounded-[2rem] shadow-2xl overflow-hidden animate-in zoom-in-95 duration-200">
            <div className="p-8 border-b border-slate-100 flex items-center justify-between bg-slate-50">
               <div>
                 <h2 className="text-2xl font-black text-slate-900 tracking-tight">Create Offer</h2>
                 <p className="text-slate-500 text-sm mt-1">Design a new coupon for your customers.</p>
               </div>
               <button onClick={() => setShowModal(false)} className="p-2.5 bg-white border border-slate-200 rounded-2xl hover:bg-slate-100 transition-colors">
                 <X className="w-5 h-5 text-slate-600" />
               </button>
            </div>

            <form onSubmit={createCoupon} className="p-8 space-y-6">
               <div className="grid grid-cols-2 gap-6">
                  <div className="col-span-2">
                    <label className="text-xs font-black uppercase tracking-widest text-slate-400 mb-2 block">Coupon Code</label>
                    <input 
                      required
                      type="text" 
                      placeholder="e.g. THALI50"
                      value={formData.code}
                      onChange={e => setFormData({...formData, code: e.target.value.toUpperCase()})}
                      className="w-full px-5 py-3.5 bg-slate-50 border border-slate-100 rounded-2xl font-black text-slate-800 focus:ring-4 focus:ring-amber-500/10 focus:border-amber-500 focus:outline-none transition-all placeholder:text-slate-300"
                    />
                  </div>
                  <div className="col-span-2">
                    <label className="text-xs font-black uppercase tracking-widest text-slate-400 mb-2 block">Description</label>
                    <input 
                      type="text" 
                      placeholder="e.g. Get 20% off on your first order"
                      value={formData.description}
                      onChange={e => setFormData({...formData, description: e.target.value})}
                      className="w-full px-5 py-3.5 bg-slate-50 border border-slate-100 rounded-2xl font-medium text-slate-800 placeholder:text-slate-300 focus:outline-none"
                    />
                  </div>
                  <div>
                    <label className="text-xs font-black uppercase tracking-widest text-slate-400 mb-2 block">Type</label>
                    <select 
                      value={formData.discountType}
                      onChange={e => setFormData({...formData, discountType: e.target.value})}
                      className="w-full px-5 py-3.5 bg-slate-50 border border-slate-100 rounded-2xl font-bold text-slate-800 appearance-none pointer-events-auto"
                    >
                      <option value="percentage">Percentage (%)</option>
                      <option value="fixed">Fixed (₹)</option>
                    </select>
                  </div>
                  <div>
                    <label className="text-xs font-black uppercase tracking-widest text-slate-400 mb-2 block">Applicable For</label>
                    <select 
                      value={formData.applicableFor}
                      onChange={e => setFormData({...formData, applicableFor: e.target.value})}
                      className="w-full px-5 py-3.5 bg-slate-50 border border-slate-100 rounded-2xl font-bold text-slate-800 appearance-none pointer-events-auto"
                    >
                      <option value="BOTH">Online & Dining</option>
                      <option value="ONLINE">Online Only</option>
                      <option value="DINING">Dining Only</option>
                    </select>
                  </div>
                  <div>
                    <label className="text-xs font-black uppercase tracking-widest text-slate-400 mb-2 block">Value</label>
                    <input 
                      required
                      type="number" 
                      value={formData.discountValue}
                      onChange={e => setFormData({...formData, discountValue: e.target.value})}
                      className="w-full px-5 py-3.5 bg-slate-50 border border-slate-100 rounded-2xl font-bold text-slate-800"
                    />
                  </div>
                  <div>
                    <label className="text-xs font-black uppercase tracking-widest text-slate-400 mb-2 block">Min Order (₹)</label>
                    <input 
                      type="number" 
                      value={formData.minOrderAmount}
                      onChange={e => setFormData({...formData, minOrderAmount: e.target.value})}
                      className="w-full px-5 py-3.5 bg-slate-50 border border-slate-100 rounded-2xl font-bold text-slate-800"
                    />
                  </div>
                  <div className="col-span-2">
                    <label className="text-xs font-black uppercase tracking-widest text-slate-400 mb-2 block">Expiry Date</label>
                    <input 
                      required
                      type="date" 
                      value={formData.expiryDate}
                      onChange={e => setFormData({...formData, expiryDate: e.target.value})}
                      className="w-full px-5 py-3.5 bg-slate-50 border border-slate-100 rounded-2xl font-bold text-slate-500"
                    />
                  </div>
               </div>

               <div className="pt-6 flex gap-4">
                  <button 
                    type="button"
                    onClick={() => setShowModal(false)}
                    className="flex-1 py-4 bg-slate-100 text-slate-600 rounded-2xl font-bold hover:bg-slate-200 transition-all"
                  >
                    Cancel
                  </button>
                  <button 
                    type="submit"
                    className="flex-1 py-4 bg-amber-500 text-white rounded-2xl font-black shadow-lg shadow-amber-500/20 hover:bg-amber-600 active:scale-95 transition-all uppercase tracking-widest"
                  >
                    Launch Coupon
                  </button>
               </div>
            </form>
          </div>
        </div>
      )}
    </div>
  );
}
