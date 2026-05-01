"use client";

import { useState, useEffect } from "react";
import { 
  BarChart3, 
  TrendingUp, 
  ShoppingBag, 
  CreditCard, 
  PieChart, 
  Calendar,
  IndianRupee,
  Clock,
  ArrowUpRight,
  Loader2,
  CheckCircle,
  Activity,
} from "lucide-react";
import { 
  BarChart, 
  Bar, 
  XAxis, 
  YAxis, 
  CartesianGrid, 
  Tooltip, 
  ResponsiveContainer, 
  PieChart as RePieChart, 
  Pie, 
  Cell,
  AreaChart,
  Area,
} from "recharts";
import apiService from "@/services/apiService";

const COLORS = ['#F59E0B', '#10B981', '#3B82F6', '#8B5CF6', '#EC4899', '#64748B'];

const FILTERS = [
  { key: 'TODAY', label: 'Today', icon: Clock },
  { key: 'WEEK', label: 'This Week', icon: Calendar },
  { key: 'MONTH', label: 'This Month', icon: Calendar },
  { key: 'ALL', label: 'All Time', icon: Activity },
];

export default function ReportsPage() {
  const [data, setData] = useState(null);
  const [dashData, setDashData] = useState(null);
  const [loading, setLoading] = useState(true);
  const [activeFilter, setActiveFilter] = useState('ALL');

  const fetchReports = async (filter = activeFilter) => {
    try {
      setLoading(true);
      const [reportsRes, dashRes] = await Promise.all([
        apiService.get(`/admin/reports?filter=${filter}`),
        apiService.get(`/admin/dashboard?filter=${filter}`),
      ]);
      setData(reportsRes.data.data);
      setDashData(dashRes.data.data);
    } catch (err) {
      console.error("Failed to fetch reports:", err);
    } finally {
      setLoading(false);
    }
  };

  useEffect(() => {
    fetchReports();
  }, []);

  const handleFilterChange = (filter) => {
    setActiveFilter(filter);
    fetchReports(filter);
  };

  if (loading) return (
    <div className="flex-1 flex flex-col items-center justify-center text-slate-400">
        <Loader2 className="w-12 h-12 animate-spin text-amber-500 mb-6" />
        <p className="font-black uppercase tracking-widest text-xs">Aggregating Global Analytics...</p>
    </div>
  );

  const StatCard = ({ title, value, subtitle, icon: Icon, color }) => (
    <div className="bg-white p-8 rounded-[40px] shadow-sm border border-slate-100 relative overflow-hidden group hover:shadow-2xl transition-all h-full">
        <div className={`absolute top-0 right-0 w-32 h-32 ${color} opacity-5 blur-[40px] rounded-full -translate-y-1/2 translate-x-1/2`}></div>
        <div className="flex items-center gap-4 mb-6">
            <div className={`p-4 ${color.replace('bg-', 'bg-').replace('-500', '-100')} ${color.replace('bg-', 'text-').replace('-500', '-600')} rounded-[24px]`}>
                <Icon className="w-7 h-7" />
            </div>
            <h3 className="text-[10px] font-black uppercase tracking-widest text-slate-400">{title}</h3>
        </div>
        <div className="flex items-baseline gap-2">
            <span className="text-4xl font-black text-slate-900 tracking-tighter">{value}</span>
            {subtitle && (
              <span className="text-[10px] font-black text-emerald-500 uppercase flex items-center gap-1">
                  <ArrowUpRight className="w-3 h-3" />
                  {subtitle}
              </span>
            )}
        </div>
    </div>
  );

  return (
    <div className="flex flex-col gap-10 pb-20">
      {/* Header */}
      <div className="flex items-center justify-between bg-white p-10 rounded-[40px] shadow-sm border border-slate-100 relative overflow-hidden">
        <div className="absolute top-0 right-0 w-full h-full bg-amber-500/5 blur-[50px] skew-y-6"></div>
        <div className="relative z-10">
          <h1 className="text-5xl font-black text-slate-900 tracking-tighter uppercase">Revenue Analytics</h1>
          <p className="text-slate-500 mt-2 font-bold flex items-center gap-3 uppercase text-[10px] tracking-widest">
              <span className="w-2.5 h-2.5 bg-emerald-500 rounded-full animate-ping"></span>
              Real-time Business Performance Monitoring
          </p>
        </div>
        <button onClick={() => fetchReports()} className="relative z-10 px-8 py-4 bg-slate-900 text-white rounded-2xl font-black text-[10px] uppercase tracking-widest shadow-2xl flex items-center gap-3 hover:bg-slate-800 transition-all">
            <TrendingUp className="w-4 h-4" />
            Sync Intel
        </button>
      </div>

      {/* Time Filter Tabs */}
      <div className="flex gap-3 bg-white p-3 rounded-[28px] shadow-sm border border-slate-100">
        {FILTERS.map(({ key, label, icon: FIcon }) => (
          <button
            key={key}
            onClick={() => handleFilterChange(key)}
            className={`flex-1 flex items-center justify-center gap-2 py-4 rounded-[22px] font-black text-[10px] uppercase tracking-widest transition-all duration-300 ${
              activeFilter === key
                ? 'bg-slate-900 text-white shadow-lg'
                : 'bg-transparent text-slate-400 hover:bg-slate-50'
            }`}
          >
            <FIcon className="w-4 h-4" />
            {label}
          </button>
        ))}
      </div>

      {/* Stat Cards */}
      <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-8">
        <StatCard title="Total Orders" value={data.totalOrders} subtitle="Live" icon={ShoppingBag} color="bg-amber-500" />
        <StatCard title="Total Revenue" value={`₹${data.totalRevenue?.toLocaleString()}`} subtitle="Earned" icon={IndianRupee} color="bg-emerald-500" />
        <StatCard title="Successful Payments" value={data.paidOrders} subtitle="Paid" icon={CreditCard} color="bg-blue-500" />
        <StatCard title="Coupon Used" value={data.couponUsage} subtitle="Applied" icon={CheckCircle} color="bg-purple-500" />
      </div>

      {/* Revenue Breakdown by Order Type */}
      {dashData && (
        <div className="grid grid-cols-1 md:grid-cols-3 gap-6">
          <div className="bg-gradient-to-br from-amber-50 to-orange-50 border border-amber-100 p-8 rounded-[36px] flex flex-col gap-2">
            <p className="text-[10px] font-black text-amber-600 uppercase tracking-widest">Online Revenue</p>
            <p className="text-3xl font-black text-slate-900 tracking-tighter">₹{(dashData.revOnline || 0).toLocaleString()}</p>
            <p className="text-xs font-bold text-amber-500">{dashData.onlineOrders || 0} orders</p>
          </div>
          <div className="bg-gradient-to-br from-blue-50 to-indigo-50 border border-blue-100 p-8 rounded-[36px] flex flex-col gap-2">
            <p className="text-[10px] font-black text-blue-600 uppercase tracking-widest">Dining Revenue</p>
            <p className="text-3xl font-black text-slate-900 tracking-tighter">₹{(dashData.revDining || 0).toLocaleString()}</p>
            <p className="text-xs font-bold text-blue-500">{dashData.diningOrders || 0} orders</p>
          </div>
          <div className="bg-gradient-to-br from-emerald-50 to-teal-50 border border-emerald-100 p-8 rounded-[36px] flex flex-col gap-2">
            <p className="text-[10px] font-black text-emerald-600 uppercase tracking-widest">Takeaway Revenue</p>
            <p className="text-3xl font-black text-slate-900 tracking-tighter">₹{(dashData.revTakeaway || 0).toLocaleString()}</p>
            <p className="text-xs font-bold text-emerald-500">{dashData.takeawayOrders || 0} orders</p>
          </div>
        </div>
      )}

      {/* Revenue Trend Line Chart (7-day history) */}
      {dashData?.revenueHistory && dashData.revenueHistory.length > 0 && (
        <div className="bg-white p-10 rounded-[48px] shadow-sm border border-slate-100 flex flex-col gap-8">
          <div className="flex items-center gap-5">
            <div className="p-4 bg-amber-50 text-amber-500 rounded-[28px] shadow-inner">
              <TrendingUp className="w-8 h-8" />
            </div>
            <div>
              <h3 className="text-2xl font-black text-slate-900 uppercase tracking-tight">7-Day Revenue Trend</h3>
              <p className="text-[10px] font-black text-slate-400 uppercase tracking-widest mt-1">Daily revenue performance over the last week</p>
            </div>
          </div>
          <div className="h-[300px] w-full">
            <ResponsiveContainer width="100%" height={300}>
              <AreaChart data={dashData.revenueHistory}>
                <defs>
                  <linearGradient id="revGradient" x1="0" y1="0" x2="0" y2="1">
                    <stop offset="5%" stopColor="#F59E0B" stopOpacity={0.3}/>
                    <stop offset="95%" stopColor="#F59E0B" stopOpacity={0}/>
                  </linearGradient>
                </defs>
                <CartesianGrid strokeDasharray="3 3" vertical={false} stroke="#f1f5f9" />
                <XAxis 
                  dataKey="name" 
                  axisLine={false} 
                  tickLine={false} 
                  tick={{ fontSize: 11, fontWeight: 900, fill: '#94a3b8' }}
                />
                <YAxis 
                  axisLine={false} 
                  tickLine={false} 
                  tick={{ fontSize: 11, fontWeight: 900, fill: '#94a3b8' }}
                  tickFormatter={v => `₹${v >= 1000 ? (v/1000).toFixed(1) + 'k' : v}`}
                />
                <Tooltip 
                  contentStyle={{ borderRadius: '20px', border: 'none', boxShadow: '0 20px 50px rgba(0,0,0,0.12)', padding: '15px', fontWeight: 900 }}
                  formatter={v => [`₹${v.toLocaleString()}`, 'Revenue']}
                />
                <Area 
                  type="monotone" 
                  dataKey="revenue" 
                  stroke="#F59E0B" 
                  strokeWidth={3} 
                  fill="url(#revGradient)" 
                  dot={{ fill: '#F59E0B', strokeWidth: 2, r: 5 }}
                  activeDot={{ r: 8, fill: '#F59E0B', stroke: '#fff', strokeWidth: 3 }}
                />
              </AreaChart>
            </ResponsiveContainer>
          </div>
        </div>
      )}

      {/* Main Charts */}
      <div className="grid grid-cols-1 lg:grid-cols-2 gap-10">
        {/* Category Sales / Product Breakdown */}
        <div className="bg-white p-10 rounded-[48px] shadow-sm border border-slate-100 flex flex-col gap-10">
            <div className="flex items-center justify-between">
                <div className="flex items-center gap-5">
                    <div className="p-4 bg-amber-50 text-amber-500 rounded-[28px] shadow-inner">
                        <PieChart className="w-8 h-8" />
                    </div>
                    <div>
                        <h3 className="text-2xl font-black text-slate-900 uppercase tracking-tight">Category Distribution</h3>
                        <p className="text-[10px] font-black text-slate-400 uppercase tracking-widest mt-1">Sales volume by menu category</p>
                    </div>
                </div>
            </div>

            <div className="h-[400px] w-full">
                <ResponsiveContainer width="100%" height={400}>
                    <RePieChart>
                        <Pie
                            data={data.categorySales}
                            cx="50%"
                            cy="50%"
                            innerRadius={110}
                            outerRadius={160}
                            paddingAngle={8}
                            dataKey="quantity"
                            nameKey="_id"
                        >
                            {data.categorySales?.map((entry, index) => (
                                <Cell key={`cell-${index}`} fill={COLORS[index % COLORS.length]} cornerRadius={12} />
                            ))}
                        </Pie>
                        <Tooltip 
                            contentStyle={{ borderRadius: '24px', border: 'none', boxShadow: '0 20px 50px rgba(0,0,0,0.1)', padding: '15px' }}
                            itemStyle={{ fontWeight: 'black', textTransform: 'uppercase', fontSize: '10px' }}
                        />
                    </RePieChart>
                </ResponsiveContainer>
            </div>

            <div className="grid grid-cols-2 sm:grid-cols-3 gap-6">
                {data.categorySales?.map((cat, idx) => (
                    <div key={cat._id} className="flex items-center gap-3 p-4 bg-slate-50 rounded-[24px] border border-slate-100 transition-colors hover:bg-white">
                        <div className="w-3 h-3 rounded-full" style={{ backgroundColor: COLORS[idx % COLORS.length] }}></div>
                        <div className="flex flex-col">
                            <span className="text-[10px] font-black text-slate-400 uppercase tracking-widest">{cat._id}</span>
                            <span className="text-lg font-black text-slate-800 tracking-tighter">{cat.quantity} QTY</span>
                        </div>
                    </div>
                ))}
            </div>
        </div>

        {/* Revenue by Type */}
        <div className="bg-white p-10 rounded-[48px] shadow-sm border border-slate-100 flex flex-col gap-10">
            <div className="flex items-center justify-between">
                <div className="flex items-center gap-5">
                    <div className="p-4 bg-emerald-50 text-emerald-500 rounded-[28px] shadow-inner">
                        <BarChart3 className="w-8 h-8" />
                    </div>
                    <div>
                        <h3 className="text-2xl font-black text-slate-900 uppercase tracking-tight">Stream Revenue</h3>
                        <p className="text-[10px] font-black text-slate-400 uppercase tracking-widest mt-1">Fiscal contribution by order type</p>
                    </div>
                </div>
            </div>

            <div className="h-[400px] w-full">
                <ResponsiveContainer width="100%" height={400}>
                    <BarChart data={data.revenueByType}>
                        <CartesianGrid strokeDasharray="3 3" vertical={false} stroke="#f1f5f9" />
                        <XAxis 
                            dataKey="_id" 
                            axisLine={false} 
                            tickLine={false} 
                            tick={{ fontSize: 10, fontWeight: 900, textTransform: 'uppercase', fill: '#94a3b8' }}
                        />
                        <YAxis 
                            axisLine={false} 
                            tickLine={false} 
                            tick={{ fontSize: 10, fontWeight: 900, fill: '#94a3b8' }}
                        />
                        <Tooltip 
                            cursor={{ fill: '#f8fafc', radius: 10 }}
                            contentStyle={{ borderRadius: '24px', border: 'none', boxShadow: '0 20px 50px rgba(0,0,0,0.1)' }}
                        />
                        <Bar dataKey="total" radius={[15, 15, 4, 4]}>
                            {data.revenueByType?.map((entry, index) => (
                                <Cell key={`cell-${index}`} fill={COLORS[index % COLORS.length]} />
                            ))}
                        </Bar>
                    </BarChart>
                </ResponsiveContainer>
            </div>

            {/* Popular Items Mini Table */}
            <div className="flex flex-col gap-6">
                <h4 className="text-[10px] font-black uppercase tracking-[0.2em] text-slate-400 border-b border-slate-100 pb-4">Star Performers (Best Selling)</h4>
                <div className="space-y-4">
                    {data.topItems?.slice(0, 5).map((item, idx) => (
                        <div key={idx} className="flex items-center justify-between p-5 bg-slate-50 rounded-[24px] group hover:bg-slate-900 transition-all duration-500">
                            <div className="flex items-center gap-4">
                                <span className="text-sm font-black text-slate-400 group-hover:text-slate-500">0{idx + 1}</span>
                                <span className="font-black text-slate-800 text-sm tracking-tight group-hover:text-white transition-colors uppercase">{item.name}</span>
                            </div>
                            <div className="flex items-center gap-3">
                                <span className="px-3 py-1 bg-white text-slate-900 rounded-lg text-[10px] font-black group-hover:bg-slate-800 group-hover:text-emerald-400 duration-500">{item.count} SOLD</span>
                            </div>
                        </div>
                    ))}
                </div>
            </div>
        </div>
      </div>

      {/* Payment Methods Distribution */}
      {data.paymentMethods && data.paymentMethods.length > 0 && (
        <div className="bg-white p-10 rounded-[48px] shadow-sm border border-slate-100">
          <div className="flex items-center gap-5 mb-8">
            <div className="p-4 bg-blue-50 text-blue-500 rounded-[28px] shadow-inner">
              <CreditCard className="w-8 h-8" />
            </div>
            <div>
              <h3 className="text-2xl font-black text-slate-900 uppercase tracking-tight">Payment Methods</h3>
              <p className="text-[10px] font-black text-slate-400 uppercase tracking-widest mt-1">Distribution of payment types used</p>
            </div>
          </div>
          <div className="grid grid-cols-2 md:grid-cols-4 gap-6">
            {data.paymentMethods.map((pm, idx) => (
              <div key={pm._id || idx} className="bg-slate-50 p-6 rounded-[28px] border border-slate-100 text-center hover:bg-white hover:shadow-lg transition-all">
                <p className="text-3xl font-black text-slate-900 tracking-tighter">{pm.count}</p>
                <p className="text-[10px] font-black text-slate-400 uppercase tracking-widest mt-2">{pm._id || 'Unknown'}</p>
              </div>
            ))}
          </div>
        </div>
      )}
    </div>
  );
}
