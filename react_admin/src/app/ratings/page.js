"use client";

import { useState, useEffect } from "react";
import { Star, Package, Clock, Utensils, MessageSquare } from "lucide-react";
import apiService from "@/services/apiService";
import clsx from "clsx";

export default function RatingsPage() {
  const [ratings, setRatings] = useState([]);
  const [loading, setLoading] = useState(true);

  const fetchRatings = async () => {
    try {
      setLoading(true);
      const res = await apiService.get("/order-enhanced/admin/ratings");
      setRatings(res.data.data?.ratings || []);
    } catch (err) {
      console.error("Failed to fetch ratings", err);
    } finally {
      setLoading(false);
    }
  };

  useEffect(() => {
    fetchRatings();
  }, []);

  return (
    <div className="flex flex-col gap-6 h-full p-4 md:p-0">
      <div className="flex justify-between items-center bg-white p-8 rounded-[32px] shadow-sm border border-slate-100">
        <div>
          <h1 className="text-4xl font-black text-slate-900 tracking-tighter uppercase">Customer Reviews</h1>
          <p className="text-slate-500 font-bold mt-1 tracking-widest text-xs uppercase">Feedback & Rating Registry</p>
        </div>
      </div>

      <div className="grid grid-cols-1 lg:grid-cols-2 xl:grid-cols-3 gap-6">
        {loading ? (
           <div className="col-span-full h-64 flex flex-col items-center justify-center text-slate-400">
             <div className="w-10 h-10 border-4 border-slate-200 border-t-amber-500 rounded-full animate-spin mb-4"></div>
             <p className="font-black uppercase tracking-widest text-xs">Loading Reviews...</p>
           </div>
        ) : ratings.length === 0 ? (
           <div className="col-span-full h-80 flex flex-col items-center justify-center text-slate-400 bg-white rounded-[40px] border border-dashed border-slate-200">
             <Star className="w-16 h-16 text-slate-200 mb-4" />
             <p className="font-black uppercase tracking-widest text-sm">No Ratings Received</p>
           </div>
        ) : ratings.map(r => (
           <div key={r._id} className="bg-white p-6 rounded-[32px] border border-slate-100 shadow-sm hover:shadow-xl transition-all flex flex-col justify-between">
              <div>
                 <div className="flex justify-between items-start mb-4">
                    <div className="flex items-center gap-3">
                       <div className="w-12 h-12 bg-indigo-50 text-indigo-500 rounded-[18px] flex items-center justify-center font-black shadow-inner">
                         {r.userId?.name?.charAt(0).toUpperCase()}
                       </div>
                       <div>
                          <p className="font-black text-slate-800">{r.userId?.name || 'Guest'}</p>
                          <p className="text-[10px] font-bold text-slate-400 uppercase tracking-widest">Order REF: {r.orderId?._id?.slice(-6).toUpperCase()}</p>
                       </div>
                    </div>
                    <div className="flex gap-1">
                       {[...Array(5)].map((_, i) => (
                          <Star key={i} className={clsx("w-4 h-4", i < r.rating ? "fill-amber-400 text-amber-400" : "fill-slate-100 text-slate-200")} />
                       ))}
                    </div>
                 </div>
                 
                 {r.review ? (
                    <div className="p-4 bg-slate-50 rounded-[20px] mb-4 border border-slate-100 flex items-start gap-3">
                       <MessageSquare className="w-4 h-4 text-slate-300 mt-0.5 shrink-0" />
                       <p className="text-sm font-medium text-slate-600 italic leading-relaxed">"{r.review}"</p>
                    </div>
                 ) : (
                    <div className="mb-4">
                       <p className="text-xs font-bold text-slate-300 italic">No written review provided.</p>
                    </div>
                 )}
              </div>
              
              <div className="flex items-center justify-between pt-4 border-t border-slate-50">
                 <div className="flex items-center gap-2">
                    <span className="px-3 py-1 bg-slate-100 text-slate-500 text-[9px] font-black uppercase rounded-lg">
                       {r.orderId?.order_type || 'UNKNOWN'}
                    </span>
                 </div>
                 <div className="flex items-center gap-2 text-[10px] font-bold text-slate-400 uppercase">
                    <Clock className="w-3 h-3" />
                    {new Date(r.createdAt).toLocaleDateString()}
                 </div>
              </div>
           </div>
        ))}
      </div>
    </div>
  );
}
