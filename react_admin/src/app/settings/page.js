"use client";

export default function SettingsPage() {
  return (
    <div className="flex flex-col gap-6 h-full max-w-4xl">
      <h1 className="text-3xl font-bold text-slate-900 tracking-tight">System Settings</h1>

      <div className="bg-white rounded-2xl shadow-sm border border-slate-100 p-8 space-y-8">
        <div>
          <h2 className="text-xl font-bold text-slate-800 mb-4">Restaurant Profile</h2>
          <div className="grid grid-cols-2 gap-4">
            <div>
              <label className="block text-sm font-semibold text-slate-600 mb-2">Restaurant Name</label>
              <input type="text" defaultValue="Govardhan Thal" className="w-full px-4 py-2 border rounded-xl" />
            </div>
            <div>
              <label className="block text-sm font-semibold text-slate-600 mb-2">Contact Number</label>
              <input type="text" defaultValue="+91 9876543210" className="w-full px-4 py-2 border rounded-xl" />
            </div>
          </div>
        </div>

        <div>
          <h2 className="text-xl font-bold text-slate-800 mb-4">Operations</h2>
          <div className="flex items-center justify-between p-4 border rounded-xl">
            <div>
              <h3 className="font-bold text-slate-800">Accept Online Orders</h3>
              <p className="text-sm text-slate-500">Toggle to pause online orders if kitchen is busy</p>
            </div>
            <label className="relative inline-flex items-center cursor-pointer">
              <input type="checkbox" className="sr-only peer" defaultChecked/>
              <div className="w-14 h-7 bg-slate-200 peer-focus:outline-none rounded-full peer peer-checked:after:translate-x-full peer-checked:after:border-white after:content-[''] after:absolute after:top-[2px] after:left-[2px] after:bg-white after:border-gray-300 after:border after:rounded-full after:h-6 after:w-6 after:transition-all peer-checked:bg-emerald-500"></div>
            </label>
          </div>
        </div>
        
        <button className="px-6 py-3 bg-amber-500 text-white font-bold rounded-xl shadow-lg hover:bg-amber-600 transition-colors">
          Save Settings
        </button>
      </div>
    </div>
  );
}
