"use client";

import { useState } from "react";
import { useRouter } from "next/navigation";
import { Utensils } from "lucide-react";
import apiService from "@/services/apiService";

export default function LoginPage() {
  const [email, setEmail] = useState("");
  const [password, setPassword] = useState("");
  const [error, setError] = useState("");
  const [loading, setLoading] = useState(false);
  const router = useRouter();

  const handleLogin = async (e) => {
    e.preventDefault();
    setLoading(true);
    setError("");

    try {
      // Hit actual Node.js endpoint:
      const response = await apiService.post("/auth/admin-login", { email, password });
      const result = response.data;
      
      // Handle the nested 'data' structure from sendSuccess
      const authData = result.data || result;
      const token = authData.accessToken || authData.token;

      if (token) {
        localStorage.setItem("adminToken", token);
        const adminInfo = authData.user || authData.admin;
        if (adminInfo) {
          localStorage.setItem("adminUser", JSON.stringify(adminInfo));
        }
        router.push("/");
      } else {
        throw new Error("Invalid response from server");
      }
    } catch (err) {
      console.error("Login Error:", err);
      setError(err.response?.data?.message || "Invalid Email or Password");
      setLoading(false);
    }
  };

  return (
    <div className="fixed inset-0 bg-slate-900 flex items-center justify-center p-4">
      <div className="w-full max-w-md bg-white rounded-3xl shadow-2xl overflow-hidden">
        <div className="p-8 pb-6 text-center border-b border-slate-100">
          <div className="w-16 h-16 bg-amber-500 rounded-full flex items-center justify-center mx-auto mb-4 shadow-lg shadow-amber-500/30">
            <Utensils className="w-8 h-8 text-white" />
          </div>
          <h2 className="text-2xl font-bold text-slate-800 tracking-tight">Govardhan Admin</h2>
          <p className="text-slate-500 mt-1">Sign in to the POS Dashboard</p>
        </div>

        <form onSubmit={handleLogin} className="p-8 pt-6 flex flex-col gap-5">
          {error && <div className="p-3 bg-red-50 text-red-600 rounded-lg text-sm text-center border border-red-100">{error}</div>}
          
          <div>
            <label className="block text-sm font-medium text-slate-700 mb-1.5 ml-1">Email</label>
            <input
              type="text"
              value={email}
              onChange={(e) => setEmail(e.target.value)}
              className="w-full px-4 py-3 bg-slate-50 border border-slate-200 rounded-xl focus:outline-none focus:ring-2 focus:ring-amber-500/50 transition-colors"
              placeholder="admin@govardhanthal.com"
              required
            />
          </div>

          <div>
            <label className="block text-sm font-medium text-slate-700 mb-1.5 ml-1">Password</label>
            <input
              type="password"
              value={password}
              onChange={(e) => setPassword(e.target.value)}
              className="w-full px-4 py-3 bg-slate-50 border border-slate-200 rounded-xl focus:outline-none focus:ring-2 focus:ring-amber-500/50 transition-colors"
              placeholder="••••••••"
              required
            />
          </div>

          <button
            type="submit"
            disabled={loading}
            className="w-full mt-2 py-3.5 bg-slate-900 text-white rounded-xl font-bold tracking-wide hover:bg-slate-800 focus:ring-4 focus:ring-slate-900/20 transition-all shadow-lg flex items-center justify-center disabled:opacity-70"
          >
            {loading ? (
              <span className="w-6 h-6 border-2 border-white/20 border-t-white rounded-full animate-spin"></span>
            ) : "Sign In"}
          </button>
        </form>
      </div>
    </div>
  );
}
