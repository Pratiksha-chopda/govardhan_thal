"use client";

import { useState, useEffect } from "react";
import { motion } from "framer-motion";
import { 
  PackageSearch, 
  Plus, 
  AlertTriangle, 
  ChevronRight, 
  ArrowDown, 
  ArrowUp,
  Scale,
  BarChart2,
  Table
} from "lucide-react";
import apiService from "@/services/apiService";
import clsx from "clsx";

export default function InventoryPage() {
  const [ingredients, setIngredients] = useState([]);
  const [loading, setLoading] = useState(true);
  const [searchTerm, setSearchTerm] = useState("");
  const [selectedIngredient, setSelectedIngredient] = useState(null);

  useEffect(() => {
    fetchIngredients();
  }, []);

  const fetchIngredients = async () => {
    try {
      setLoading(true);
      const res = await apiService.get("/inventory/ingredients");
      if (res.data.success) {
        setIngredients(res.data.data);
      }
    } catch (err) {
      console.error("Failed to fetch ingredients");
    } finally {
      setLoading(false);
    }
  };

  const handleUpdateStock = async (id, amount, action) => {
    try {
      const res = await apiService.patch(`/inventory/ingredients/${id}/stock`, { amount, action });
      if (res.data.success) {
        fetchIngredients();
      }
    } catch (err) {
      alert("Failed to update stock");
    }
  };

  const filtered = ingredients.filter(i => 
    i.name.toLowerCase().includes(searchTerm.toLowerCase())
  );

  return (
    <div className="flex flex-col gap-8 h-full pb-20">
      {/* Header */}
      <div className="flex items-center justify-between">
        <div>
          <h1 className="text-4xl font-black text-slate-900 tracking-tighter uppercase">Inventory Hub</h1>
          <p className="text-sm font-medium text-slate-500 mt-2 flex items-center gap-2">
            <span className="w-2 h-2 rounded-full bg-amber-500 animate-pulse"></span>
            Raw Ingredient & Supply Chain Tracking
          </p>
        </div>
        <button className="px-8 py-4 bg-slate-900 text-white rounded-2xl font-black text-[10px] uppercase tracking-widest shadow-2xl flex items-center gap-3">
          <Plus className="w-4 h-4" />
          Onboard Material
        </button>
      </div>

      {/* Quick Stats */}
      <div className="grid grid-cols-1 md:grid-cols-3 gap-6">
        <div className="bg-white p-8 rounded-[40px] border border-slate-100 shadow-sm flex items-center gap-6">
          <div className="p-4 bg-amber-50 text-amber-500 rounded-3xl">
            <PackageSearch className="w-8 h-8" />
          </div>
          <div>
            <p className="text-[10px] font-black uppercase tracking-widest text-slate-400">Total Skus</p>
            <h4 className="text-3xl font-black text-slate-900 tracking-tighter">{ingredients.length}</h4>
          </div>
        </div>
        <div className="bg-white p-8 rounded-[40px] border border-slate-100 shadow-sm flex items-center gap-6">
          <div className="p-4 bg-rose-50 text-rose-500 rounded-3xl">
            <AlertTriangle className="w-8 h-8" />
          </div>
          <div>
            <p className="text-[10px] font-black uppercase tracking-widest text-slate-400">Low Stock</p>
            <h4 className="text-3xl font-black text-rose-600 tracking-tighter">
                {ingredients.filter(i => i.stock <= i.lowStockThreshold).length}
            </h4>
          </div>
        </div>
        <div className="bg-white p-8 rounded-[40px] border border-slate-100 shadow-sm flex items-center gap-6">
          <div className="p-4 bg-emerald-50 text-emerald-500 rounded-3xl">
            <Scale className="w-8 h-8" />
          </div>
          <div>
            <p className="text-[10px] font-black uppercase tracking-widest text-slate-400">Inventory Value</p>
            <h4 className="text-3xl font-black text-slate-900 tracking-tighter">₹84,200</h4>
          </div>
        </div>
      </div>

      {/* Search & Filter */}
      <div className="bg-white/60 backdrop-blur-xl p-4 rounded-[32px] border border-white/40 shadow-sm flex gap-4">
          <div className="flex-1 relative">
             <input 
               type="text" 
               placeholder="Search by ingredient name..." 
               value={searchTerm}
               onChange={(e) => setSearchTerm(e.target.value)}
               className="w-full pl-12 pr-4 py-4 bg-white border border-slate-100 rounded-2xl text-sm font-bold focus:outline-none focus:ring-4 focus:ring-slate-900/5 transition-all"
             />
             <PackageSearch className="w-5 h-5 absolute left-4 top-1/2 -translate-y-1/2 text-slate-400" />
          </div>
      </div>

      {/* Ingredient Table */}
      <div className="bg-white rounded-[40px] border border-slate-100 shadow-sm overflow-hidden h-full flex flex-col">
        <div className="p-8 border-b border-slate-50 flex items-center justify-between">
           <h3 className="text-xs font-black uppercase tracking-widest text-slate-400">Inventory Register</h3>
           <div className="flex gap-2">
              <button className="p-2 bg-slate-50 rounded-xl text-slate-400"><BarChart2 className="w-4 h-4"/></button>
              <button className="p-2 bg-slate-50 rounded-xl text-slate-400"><Table className="w-4 h-4"/></button>
           </div>
        </div>
        
        <div className="flex-1 overflow-y-auto">
          {loading ? (
             <div className="flex flex-col items-center justify-center p-20 gap-4">
                <div className="w-10 h-10 border-4 border-slate-100 border-t-amber-500 rounded-full animate-spin"></div>
                <p className="text-[10px] font-black uppercase tracking-widest text-slate-300">Scanning Stockpiles...</p>
             </div>
          ) : filtered.length === 0 ? (
             <div className="p-20 text-center text-slate-400">
                <p className="text-[10px] font-black uppercase tracking-widest">No Ingredients Found</p>
             </div>
          ) : (
            <div className="divide-y divide-slate-50">
               {filtered.map((item, idx) => (
                 <motion.div 
                   initial={{ opacity: 0, y: 10 }}
                   animate={{ opacity: 1, y: 0 }}
                   transition={{ delay: idx * 0.05 }}
                   key={item._id} 
                   className="p-6 flex items-center justify-between hover:bg-slate-50/50 transition-all group"
                 >
                   <div className="flex items-center gap-6">
                      <div className={clsx(
                        "w-12 h-12 rounded-2xl flex items-center justify-center shadow-sm border",
                        item.stock <= item.lowStockThreshold ? "bg-rose-50 text-rose-500 border-rose-100" : "bg-slate-50 text-slate-400 border-slate-100"
                      )}>
                         <PackageSearch className="w-6 h-6" />
                      </div>
                      <div>
                         <h4 className="font-black text-slate-800 text-lg uppercase tracking-tight">{item.name}</h4>
                         <div className="flex items-center gap-3">
                            <span className="text-[10px] font-black text-slate-400 uppercase tracking-widest">Category: Raw Material</span>
                            <span className="w-1 h-1 bg-slate-200 rounded-full"></span>
                            <span className="text-[10px] font-black text-slate-400 uppercase tracking-widest">Threshold: {item.lowStockThreshold}{item.unit}</span>
                         </div>
                      </div>
                   </div>

                   <div className="flex items-center gap-10">
                      <div className="text-right">
                         <p className={clsx(
                           "text-2xl font-black tracking-tighter",
                           item.stock <= item.lowStockThreshold ? "text-rose-600" : "text-slate-900"
                         )}>
                           {item.stock} <span className="text-xs uppercase font-bold text-slate-400">{item.unit}</span>
                         </p>
                         {item.stock <= item.lowStockThreshold && (
                           <p className="text-[9px] font-black text-rose-500 uppercase tracking-widest flex items-center justify-end gap-1">
                             <AlertTriangle className="w-2 h-2" /> Critical Low
                           </p>
                         )}
                      </div>

                      <div className="flex gap-2">
                         <button 
                           onClick={() => handleUpdateStock(item._id, 1, 'ADD')}
                           className="w-10 h-10 bg-white border border-slate-100 rounded-xl flex items-center justify-center text-slate-400 hover:bg-slate-900 hover:text-white hover:border-slate-900 transition-all shadow-sm"
                         >
                            <ArrowUp className="w-4 h-4" />
                         </button>
                         <button 
                           onClick={() => handleUpdateStock(item._id, 1, 'SUBTRACT')}
                           className="w-10 h-10 bg-white border border-slate-100 rounded-xl flex items-center justify-center text-slate-400 hover:bg-rose-600 hover:text-white hover:border-rose-600 transition-all shadow-sm"
                         >
                            <ArrowDown className="w-4 h-4" />
                         </button>
                         <button className="px-4 h-10 bg-slate-50 text-slate-400 rounded-xl text-[10px] font-black uppercase tracking-widest hover:bg-slate-200 transition-all border border-slate-100">
                            Configure
                         </button>
                      </div>

                      <ChevronRight className="w-5 h-5 text-slate-200 group-hover:text-slate-400 transition-colors" />
                   </div>
                 </motion.div>
               ))}
            </div>
          )}
        </div>
      </div>
    </div>
  );
}
