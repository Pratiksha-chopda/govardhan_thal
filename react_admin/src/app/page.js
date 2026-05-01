"use client";

import { useEffect, useState } from "react";
import { motion } from "framer-motion";
import {
  TrendingUp,
  ShoppingCart,
  Grid3X3,
  CalendarDays,
  UtensilsCrossed,
  Package,
  Activity,
  ArrowUpRight,
  Clock,
  Users
} from "lucide-react";
import {
  LineChart,
  Line,
  XAxis,
  YAxis,
  CartesianGrid,
  Tooltip as ChartTooltip,
  ResponsiveContainer,
  BarChart,
  Bar
} from "recharts";
import apiService from "@/services/apiService";

const DUMMY_REVENUE_DATA = [
  { name: "Mon", revenue: 4000 },
  { name: "Tue", revenue: 3000 },
  { name: "Wed", revenue: 2000 },
  { name: "Thu", revenue: 2780 },
  { name: "Fri", revenue: 6890 },
  { name: "Sat", revenue: 10390 },
  { name: "Sun", revenue: 8490 },
];

export default function Dashboard() {
  const [mounted, setMounted] = useState(false);
  const [stats, setStats] = useState({
    totalOrdersToday: 0,
    onlineOrders: 0,
    diningOrders: 0,
    takeawayOrders: 0,
    revenueToday: 0,
    activeTables: 0,
    pendingBookings: 0,
    pendingOrders: 0,
    newUsersToday: 0,
  });

  useEffect(() => {
    setMounted(true);
    const fetchDashboardStats = async () => {
      try {
        const res = await apiService.get("/admin/dashboard");
        if (res.data.status === "success" || res.data.success) {
          setStats(res.data.data);
        }
      } catch (err) {
        if (err.response?.status !== 401) {
          console.error("Dashboard stats fetch failed:", err);
        }
      }
    };
    fetchDashboardStats();
    
    // Refresh every minute
    const interval = setInterval(fetchDashboardStats, 60000);
    return () => clearInterval(interval);
  }, []);

  // Soft Glassmorphic Card Container Component
  const MetricCard = ({ title, value, icon: Icon, gradient, textValueClass, delayIndex }) => (
    <motion.div 
      initial={{ opacity: 0, y: 20 }}
      animate={{ opacity: 1, y: 0 }}
      transition={{ delay: delayIndex * 0.1, duration: 0.5, ease: "easeOut" }}
      className="p-6 rounded-3xl bg-white/60 backdrop-blur-3xl border border-slate-100 shadow-[0_8px_30px_rgb(0,0,0,0.04)] hover:shadow-[0_8px_30px_rgb(0,0,0,0.08)] transition-all duration-300 relative overflow-hidden group"
    >
      <div className={`absolute top-0 right-0 w-32 h-32 blur-3xl rounded-full opacity-20 transition-transform duration-700 group-hover:scale-150 ${gradient}`}></div>
      
      <div className="flex justify-between items-start relative z-10">
        <div>
          <h3 className="text-slate-500 font-bold text-[11px] tracking-[0.2em] uppercase mb-3 opacity-80">{title}</h3>
          <div className="flex items-end gap-2">
            <p className={`text-4xl font-extrabold tracking-tighter ${textValueClass}`}>{value}</p>
          </div>
        </div>
        
        <div className={`w-12 h-12 rounded-2xl flex items-center justify-center border bg-white/50 backdrop-blur-md shadow-sm ${textValueClass} border-current/20`}>
          <Icon className="w-5 h-5 stroke-[2.5]" />
        </div>
      </div>
    </motion.div>
  );

  return (
    <div className="flex flex-col gap-8 h-full pr-1 pb-10">
      
      {/* Header Section */}
      <motion.div 
        initial={{ opacity: 0, filter: 'blur(10px)' }}
        animate={{ opacity: 1, filter: 'blur(0px)' }}
        transition={{ duration: 0.8 }}
        className="flex items-center justify-between"
      >
        <div>
          <h1 className="text-4xl font-black text-slate-900 tracking-tighter">Overview</h1>
          <p className="text-sm font-medium text-slate-500 mt-2 flex items-center gap-2">
            <span className="w-2 h-2 rounded-full bg-emerald-500 animate-pulse shadow-[0_0_10px_rgb(16,185,129)]"></span>
            Live Performance Metrics
          </p>
        </div>
        <div className="text-xs font-bold text-slate-500 bg-white/80 backdrop-blur-md border border-slate-200 px-5 py-2.5 rounded-full shadow-sm tracking-wider uppercase">
          {new Date().toLocaleDateString('en-US', { weekday: 'short', month: 'short', day: 'numeric' })}
        </div>
      </motion.div>

      {/* Primary KPI Row */}
      <div className="grid grid-cols-1 md:grid-cols-2 xl:grid-cols-4 gap-5">
        <MetricCard
          delayIndex={1}
          title="Today's Sales"
          value={`₹${stats.revenueToday.toLocaleString()}`}
          icon={TrendingUp}
          textValueClass="text-emerald-600"
          gradient="bg-emerald-400"
        />
        <MetricCard
          delayIndex={2}
          title="Live Tables"
          value={stats.activeTables || 0}
          icon={UtensilsCrossed}
          textValueClass="text-orange-600"
          gradient="bg-orange-400"
        />
        <MetricCard
          delayIndex={3}
          title="Pending Delivery"
          value={stats.pendingDeliveries || 0}
          icon={Package}
          textValueClass="text-rose-600"
          gradient="bg-rose-400"
        />
        <MetricCard
          delayIndex={4}
          title="Total Orders"
          value={stats.totalOrders || 0}
          icon={ShoppingCart}
          textValueClass="text-indigo-600"
          gradient="bg-indigo-400"
        />
      </div>

      {/* Distribution Quick Stats */}
      <div className="grid grid-cols-1 md:grid-cols-2 xl:grid-cols-4 gap-5">
        <MetricCard
          delayIndex={5}
          title="New Users Today"
          value={stats.newUsersToday || 0}
          icon={Users}
          textValueClass="text-cyan-600"
          gradient="bg-cyan-400"
        />
        <MetricCard
          delayIndex={6}
          title="Pending Bookings"
          value={stats.pendingBookings || 0}
          icon={CalendarDays}
          textValueClass="text-blue-600"
          gradient="bg-blue-400"
        />
        <MetricCard
          delayIndex={7}
          title="Takeaway Orders"
          value={stats.takeawayOrders || 0}
          icon={Activity}
          textValueClass="text-teal-600"
          gradient="bg-teal-400"
        />
        <MetricCard
          delayIndex={8}
          title="Unpaid Amount"
          value={stats.pendingPayments || 0}
          icon={Clock}
          textValueClass="text-slate-600"
          gradient="bg-slate-400"
        />
      </div>

      {/* Distribution & Charts */}
      <div className="grid grid-cols-1 xl:grid-cols-3 gap-6">
        
        {/* Orders Pipeline Vertical Stats */}
        <motion.div 
          initial={{ opacity: 0, x: -20 }}
          animate={{ opacity: 1, x: 0 }}
          transition={{ delay: 0.6, duration: 0.5 }}
          className="xl:col-span-1 bg-white/60 backdrop-blur-xl rounded-3xl p-8 border border-slate-100 shadow-[0_8px_30px_rgb(0,0,0,0.04)] flex flex-col gap-6"
        >
          <div className="flex items-center justify-between mb-4">
            <h2 className="text-sm font-bold tracking-[0.1em] text-slate-900 uppercase">Order Pipeline</h2>
            <button className="text-xs font-bold text-amber-500 hover:text-amber-600 transition-colors flex items-center gap-1">View Full <ArrowUpRight className="w-3 h-3"/></button>
          </div>

          {[
            { label: "Online Delivery", value: stats.onlineOrders, icon: Package, color: "text-indigo-600", bg: "bg-indigo-50/50", border: 'border-indigo-100' },
            { label: "Dining In", value: stats.diningOrders, icon: UtensilsCrossed, color: "text-orange-600", bg: "bg-orange-50/50", border: 'border-orange-100' },
            { label: "Fast Takeaway", value: stats.takeawayOrders, icon: Activity, color: "text-teal-600", bg: "bg-teal-50/50", border: 'border-teal-100' }
          ].map((stat, i) => (
            <div key={i} className={`flex items-center justify-between p-4 rounded-2xl border ${stat.border} ${stat.bg} hover:shadow-sm transition-all duration-300 group`}>
              <div className="flex items-center gap-4">
                <div className={`p-3 rounded-xl bg-white shadow-sm border border-slate-100 ${stat.color} group-hover:scale-110 transition-transform`}>
                  <stat.icon className="w-5 h-5 stroke-[2]"/>
                </div>
                <p className="font-bold text-slate-700">{stat.label}</p>
              </div>
              <p className={`text-2xl font-black ${stat.color}`}>{stat.value}</p>
            </div>
          ))}
        </motion.div>

        {/* Charts Container */}
        <motion.div 
          initial={{ opacity: 0, x: 20 }}
          animate={{ opacity: 1, x: 0 }}
          transition={{ delay: 0.8, duration: 0.5 }}
          className="xl:col-span-2 bg-white/60 backdrop-blur-xl rounded-3xl p-8 border border-slate-100 shadow-[0_8px_30px_rgb(0,0,0,0.04)] flex flex-col"
        >
          <div className="flex items-center justify-between mb-8">
            <div>
               <h2 className="text-sm font-bold tracking-[0.1em] text-slate-900 uppercase">Revenue Flow</h2>
               <p className="text-sm font-medium text-slate-400 mt-1">7-Day Trailing Overview</p>
            </div>
            <div className="flex gap-2 bg-slate-100/50 p-1 rounded-lg border border-slate-200/50">
              <button className="px-3 py-1 text-xs font-bold rounded bg-white shadow-sm text-slate-800">Sales</button>
              <button className="px-3 py-1 text-xs font-bold rounded text-slate-500 hover:text-slate-700 transition">Volume</button>
            </div>
          </div>

          <div className="flex-1 h-[300px] w-full min-h-[300px] min-w-0 overflow-hidden">
            {mounted && (
              <ResponsiveContainer width="100%" height={300}>
                <LineChart data={stats.revenueHistory?.length > 0 ? stats.revenueHistory : DUMMY_REVENUE_DATA} margin={{ top: 5, right: 10, left: 10, bottom: 0 }}>
                  <defs>
                    <linearGradient id="colorRevenue" x1="0" y1="0" x2="0" y2="1">
                      <stop offset="5%" stopColor="#f59e0b" stopOpacity={0.3}/>
                      <stop offset="95%" stopColor="#f59e0b" stopOpacity={0}/>
                    </linearGradient>
                  </defs>
                  <CartesianGrid strokeDasharray="4 4" vertical={false} stroke="#E2E8F0" />
                  <XAxis dataKey="name" axisLine={false} tickLine={false} tick={{fill: '#94a3b8', fontSize: 12, fontWeight: 600}} dy={15} />
                  <YAxis axisLine={false} tickLine={false} tick={{fill: '#94a3b8', fontSize: 12, fontWeight: 600}} dx={-10} tickFormatter={(val) => val >= 1000 ? `₹${(val / 1000).toFixed(1)}k` : `₹${val}`} />
                  <ChartTooltip 
                    cursor={{stroke: '#cbd5e1', strokeWidth: 1, strokeDasharray: '4 4'}}
                    contentStyle={{ 
                      borderRadius: '16px', 
                      border: '1px solid #f1f5f9', 
                      boxShadow: '0 10px 40px -10px rgba(0,0,0,0.1)',
                      backgroundColor: 'rgba(255, 255, 255, 0.9)',
                      backdropFilter: 'blur(10px)',
                      fontWeight: 'bold',
                      padding: '12px 20px'
                    }}
                    itemStyle={{ color: '#0f172a', fontWeight: '900' }}
                  />
                  <Line 
                    type="monotone" 
                    dataKey="revenue" 
                    stroke="#f59e0b" 
                    strokeWidth={4} 
                    dot={{ r: 4, strokeWidth: 2, fill: '#fff', stroke: '#f59e0b' }} 
                    activeDot={{ r: 8, strokeWidth: 0, fill: '#f59e0b', stroke: 'rgba(245, 158, 11, 0.3)' }} 
                  />
                </LineChart>
              </ResponsiveContainer>
            )}
          </div>
        </motion.div>

      </div>
    </div>
  );
}
