"use client";

import { useState, useEffect } from "react";
import { User, Mail, Lock, Shield, CheckCircle, AlertCircle, Save, Loader2 } from "lucide-react";
import apiService from "@/services/apiService";
import { motion } from "framer-motion";

export default function ProfilePage() {
  const [profile, setProfile] = useState({ name: "", email: "" });
  const [passwords, setPasswords] = useState({ newPassword: "", confirmPassword: "" });
  const [loading, setLoading] = useState(true);
  const [saving, setSaving] = useState(false);
  const [message, setMessage] = useState({ type: "", text: "" });

  const fetchProfile = async () => {
    try {
      setLoading(true);
      const res = await apiService.get("/admin/profile");
      setProfile(res.data.data);
    } catch (err) {
      console.error("Failed to fetch profile:", err);
    } finally {
      setLoading(false);
    }
  };

  useEffect(() => {
    fetchProfile();
  }, []);

  const handleUpdateProfile = async (e) => {
    e.preventDefault();
    try {
      setSaving(true);
      await apiService.put("/admin/profile", { name: profile.name });
      setMessage({ type: "success", text: "Profile name updated successfully!" });
    } catch (err) {
      setMessage({ type: "error", text: "Failed to update profile." });
    } finally {
      setSaving(false);
    }
  };

  const handleChangePassword = async (e) => {
    e.preventDefault();
    if (passwords.newPassword !== passwords.confirmPassword) {
      setMessage({ type: "error", text: "Passwords do not match." });
      return;
    }
    try {
      setSaving(true);
      await apiService.put("/admin/profile", { password: passwords.newPassword });
      setMessage({ type: "success", text: "Password changed successfully!" });
      setPasswords({ newPassword: "", confirmPassword: "" });
    } catch (err) {
      setMessage({ type: "error", text: "Failed to change password." });
    } finally {
      setSaving(false);
    }
  };

  if (loading) return (
    <div className="flex-1 flex flex-col items-center justify-center text-slate-400">
        <Loader2 className="w-10 h-10 animate-spin text-amber-500 mb-4" />
        <p className="font-black uppercase tracking-widest text-[10px]">Accessing Secure Vault...</p>
    </div>
  );

  return (
    <div className="max-w-4xl mx-auto flex flex-col gap-10 pb-20">
      <div className="flex items-center justify-between bg-white p-10 rounded-[40px] shadow-sm border border-slate-100 relative overflow-hidden">
        <div className="absolute top-0 right-0 w-64 h-64 bg-slate-900/5 blur-[80px] rounded-full"></div>
        <div className="relative z-10">
          <h1 className="text-4xl font-black text-slate-900 tracking-tighter uppercase">Admin Integrity</h1>
          <p className="text-slate-500 mt-2 font-bold flex items-center gap-2 uppercase text-[10px] tracking-widest">
              <Shield className="w-3.5 h-3.5 text-blue-500" />
              Secure Administrative Access
          </p>
        </div>
        <div className="hidden md:flex w-20 h-20 bg-slate-900 text-white rounded-[24px] items-center justify-center font-black text-3xl shadow-2xl rotate-3">
            {profile.name?.charAt(0).toUpperCase()}
        </div>
      </div>

      {message.text && (
        <motion.div 
            initial={{ opacity: 0, scale: 0.95 }}
            animate={{ opacity: 1, scale: 1 }}
            className={`p-5 rounded-2xl flex items-center gap-3 border shadow-sm ${
                message.type === 'success' ? 'bg-emerald-50 border-emerald-100 text-emerald-700' : 'bg-rose-50 border-rose-100 text-rose-700'
            }`}
        >
            {message.type === 'success' ? <CheckCircle className="w-5 h-5" /> : <AlertCircle className="w-5 h-5" />}
            <span className="text-sm font-bold">{message.text}</span>
        </motion.div>
      )}

      <div className="grid grid-cols-1 md:grid-cols-2 gap-10">
        {/* Personal Details */}
        <div className="bg-white p-10 rounded-[40px] shadow-sm border border-slate-100 flex flex-col gap-8">
            <div className="flex items-center gap-4">
                <div className="p-3 bg-amber-50 text-amber-500 rounded-2xl">
                    <User className="w-6 h-6" />
                </div>
                <h3 className="text-xl font-black text-slate-900 uppercase tracking-tight">Identity Settings</h3>
            </div>
            
            <form onSubmit={handleUpdateProfile} className="flex flex-col gap-6">
                <div className="flex flex-col gap-2">
                    <label className="text-[10px] font-black uppercase tracking-widest text-slate-400 px-1">Display Name</label>
                    <div className="relative">
                        <User className="absolute left-4 top-1/2 -translate-y-1/2 w-4 h-4 text-slate-300" />
                        <input 
                            type="text" 
                            className="w-full pl-12 pr-4 py-4 bg-slate-50 border border-slate-100 rounded-2xl text-sm font-bold focus:bg-white focus:outline-none focus:ring-4 focus:ring-slate-500/5 transition-all outline-none"
                            value={profile.name}
                            onChange={(e) => setProfile({...profile, name: e.target.value})}
                        />
                    </div>
                </div>
                
                <div className="flex flex-col gap-2 opacity-60 grayscale cursor-not-allowed">
                    <label className="text-[10px] font-black uppercase tracking-widest text-slate-400 px-1">Root Email (Locked)</label>
                    <div className="relative">
                        <Mail className="absolute left-4 top-1/2 -translate-y-1/2 w-4 h-4 text-slate-300" />
                        <input 
                            type="email" 
                            disabled
                            className="w-full pl-12 pr-4 py-4 bg-slate-100 border border-slate-200 rounded-2xl text-sm font-bold text-slate-400 italic cursor-not-allowed"
                            value={profile.email}
                        />
                    </div>
                </div>

                <button 
                    type="submit"
                    disabled={saving}
                    className="w-full py-4 bg-slate-900 text-white rounded-2xl text-[10px] font-black uppercase tracking-widest shadow-xl shadow-slate-900/20 active:scale-95 transition-all flex items-center justify-center gap-2 hover:bg-slate-800 disabled:opacity-50"
                >
                    {saving ? <Loader2 className="w-4 h-4 animate-spin" /> : <Save className="w-4 h-4" />}
                    Commit Changes
                </button>
            </form>
        </div>

        {/* Security / Password */}
        <div className="bg-white p-10 rounded-[40px] shadow-sm border border-slate-100 flex flex-col gap-8">
            <div className="flex items-center gap-4">
                <div className="p-3 bg-blue-50 text-blue-500 rounded-2xl">
                    <Lock className="w-6 h-6" />
                </div>
                <h3 className="text-xl font-black text-slate-900 uppercase tracking-tight">Access Control</h3>
            </div>
            
            <form onSubmit={handleChangePassword} className="flex flex-col gap-6">
                <div className="flex flex-col gap-2">
                    <label className="text-[10px] font-black uppercase tracking-widest text-slate-400 px-1">New Password</label>
                    <div className="relative">
                        <Lock className="absolute left-4 top-1/2 -translate-y-1/2 w-4 h-4 text-slate-300" />
                        <input 
                            type="password" 
                            placeholder="••••••••"
                            className="w-full pl-12 pr-4 py-4 bg-slate-50 border border-slate-100 rounded-2xl text-sm font-bold focus:bg-white focus:outline-none focus:ring-4 focus:ring-blue-500/5 transition-all outline-none"
                            value={passwords.newPassword}
                            onChange={(e) => setPasswords({...passwords, newPassword: e.target.value})}
                        />
                    </div>
                </div>
                
                <div className="flex flex-col gap-2">
                    <label className="text-[10px] font-black uppercase tracking-widest text-slate-400 px-1">Confirm Access Key</label>
                    <div className="relative">
                        <Lock className="absolute left-4 top-1/2 -translate-y-1/2 w-4 h-4 text-slate-300" />
                        <input 
                            type="password" 
                            placeholder="••••••••"
                            className="w-full pl-12 pr-4 py-4 bg-slate-50 border border-slate-100 rounded-2xl text-sm font-bold focus:bg-white focus:outline-none focus:ring-4 focus:ring-blue-500/5 transition-all outline-none"
                            value={passwords.confirmPassword}
                            onChange={(e) => setPasswords({...passwords, confirmPassword: e.target.value})}
                        />
                    </div>
                </div>

                <button 
                    type="submit"
                    disabled={saving}
                    className="w-full py-4 bg-blue-600 text-white rounded-2xl text-[10px] font-black uppercase tracking-widest shadow-xl shadow-blue-500/20 active:scale-95 transition-all flex items-center justify-center gap-2 hover:bg-blue-700 disabled:opacity-50"
                >
                    {saving ? <Loader2 className="w-4 h-4 animate-spin" /> : <Lock className="w-4 h-4" />}
                    Update Security
                </button>
            </form>
        </div>
      </div>
    </div>
  );
}
