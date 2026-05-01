"use client";

import { useState, useEffect } from "react";
import { PlusCircle, Edit, Trash2, Star, Image as ImageIcon, X, Loader2 } from "lucide-react";
import apiService from "@/services/apiService";
import socketService from "@/services/socketService";

export default function MenuManagementPage() {
  const [activeCategory, setActiveCategory] = useState("Sabji");
  const [categories, setCategories] = useState(["Sabji", "Thali", "Farsan", "Sweets", "Beverages", "Roti"]);
  const [menuItems, setMenuItems] = useState([]);
  const [loading, setLoading] = useState(true);
  const [showModal, setShowModal] = useState(false);
  const [editingItem, setEditingItem] = useState(null);
  const [submitting, setSubmitting] = useState(false);
  const [formData, setFormData] = useState({
    name: "",
    description: "",
    price: "",
    category: "Sabji",
    isVeg: true,
    imageUrl: "",
    imageKeyword: "",
    gstRate: 5,
  });

  const fetchMenu = async () => {
    try {
      setLoading(true);
      // Accessing the public route to get all menus.
      const res = await apiService.get("/menu?limit=500");
      const items = res.data.data?.data || res.data.data || [];
      setMenuItems(items);
      
      // Auto-extract distinct categories if needed over time
      const distinctCats = [...new Set(items.map(i => i.category))];
      if (distinctCats.length > 0) {
        setCategories(prev => {
          const merged = [...new Set([...prev, ...distinctCats])];
          return merged;
        });
        if (!distinctCats.includes(activeCategory) && distinctCats.length > 0) {
          setActiveCategory(distinctCats[0]);
        }
      }
    } catch (err) {
      console.error("Failed to fetch menu:", err);
    } finally {
      setLoading(false);
    }
  };

  useEffect(() => {
    fetchMenu();
    
    socketService.connect();
    socketService.on("menu:created", fetchMenu);
    socketService.on("menu:updated", fetchMenu);
    socketService.on("menu:deleted", fetchMenu);

    return () => {
      socketService.off("menu:created", fetchMenu);
      socketService.off("menu:updated", fetchMenu);
      socketService.off("menu:deleted", fetchMenu);
    };
  }, []);

  const toggleStatus = async (id, field, currentValue) => {
    try {
      // Endpoint map from adminRoutes
      const endpointMap = {
        isAvailable: 'available',
        isPopular: 'popular',
        isTodaySpecial: 'today-special',
      };
      const endpoint = endpointMap[field];
      if (!endpoint) return;

      // Optimistic update
      setMenuItems(prev => prev.map(item => item._id === id ? { ...item, [field]: !currentValue } : item));

      await apiService.patch(`/admin/menu/${id}/${endpoint}`, { [field]: !currentValue });
    } catch (err) {
      console.error(`Error updating ${field}:`, err);
      fetchMenu(); // Revert on failure
    }
  };

  const deleteMenu = async (id) => {
    if (!window.confirm("Are you sure you want to delete this item?")) return;
    try {
      await apiService.delete(`/admin/menu/${id}`);
      setMenuItems(prev => prev.filter(i => i._id !== id));
    } catch (err) {
      console.error("Failed to delete menu", err);
    }
  };

  const handleOpenModal = (item = null) => {
    if (item) {
      setEditingItem(item._id);
      setFormData({
        name: item.name || "",
        description: item.description || "",
        price: item.price || "",
        category: item.category || "Sabji",
        isVeg: item.isVeg ?? true,
        imageUrl: item.imageUrl || "",
        imageKeyword: item.imageKeyword || "",
        gstRate: item.gstRate ?? 5,
      });
    } else {
      setEditingItem(null);
      setFormData({ name: "", description: "", price: "", category: activeCategory, isVeg: true, imageUrl: "", imageKeyword: "", gstRate: 5 });
    }
    setShowModal(true);
  };

  const handleSaveMenu = async (e) => {
    e.preventDefault();
    try {
      setSubmitting(true);
      const dataToSave = { ...formData, price: Number(formData.price), gstRate: Number(formData.gstRate) };
      if (editingItem) {
        await apiService.put(`/admin/menu/${editingItem}`, dataToSave);
      } else {
        await apiService.post("/admin/menu", dataToSave);
      }
      setShowModal(false);
      fetchMenu();
    } catch (err) {
      alert(err.response?.data?.message || "Failed to save menu item");
    } finally {
      setSubmitting(false);
    }
  };


  const filteredItems = menuItems.filter(item => item.category === activeCategory);

  return (
    <div className="flex flex-col gap-6 h-full">
      <div className="flex items-center justify-between">
        <div>
          <h1 className="text-3xl font-bold text-slate-900 tracking-tight">Menu Management</h1>
          <p className="text-slate-500 mt-1">Control visibility, pricing, and special tags for all dishes.</p>
        </div>
        <button 
          onClick={() => handleOpenModal()}
          className="flex items-center gap-2 bg-slate-900 text-white px-5 py-2.5 rounded-xl font-medium shadow-lg hover:shadow-xl hover:-translate-y-0.5 transition-all"
        >
          <PlusCircle className="w-5 h-5"/>
          Add Menu Item
        </button>
      </div>

      {/* Categories Horizontal Scroll */}
      <div className="flex gap-3 overflow-x-auto pb-2 scrollbar-hide">
        {categories.map(cat => (
          <button
            key={cat}
            onClick={() => setActiveCategory(cat)}
            className={`px-5 py-2.5 rounded-full font-semibold whitespace-nowrap transition-colors ${
              activeCategory === cat ? 'bg-amber-500 text-white shadow-md shadow-amber-500/20' : 'bg-white text-slate-600 border border-slate-200 hover:bg-slate-50'
            }`}
          >
            {cat}
          </button>
        ))}
      </div>

      <div className="bg-white rounded-2xl shadow-sm border border-slate-100 overflow-hidden flex-1 flex flex-col">
        {loading ? (
          <div className="flex-1 flex flex-col items-center justify-center text-slate-400">
            <div className="w-8 h-8 border-4 border-slate-300 border-t-amber-500 rounded-full animate-spin mb-3"></div>
            <p>Loading menu...</p>
          </div>
        ) : filteredItems.length === 0 ? (
          <div className="flex-1 flex items-center justify-center text-slate-400 p-8">
            <p>No items found in {activeCategory}.</p>
          </div>
        ) : (
          <div className="overflow-y-auto w-full block h-[600px]">
            <table className="w-full text-left border-collapse">
              <thead className="sticky top-0 bg-slate-50 border-b border-slate-200 z-10 shadow-sm">
                <tr className="text-sm">
                  <th className="p-4 font-semibold text-slate-600">Image</th>
                  <th className="p-4 font-semibold text-slate-600">Item Name</th>
                  <th className="p-4 font-semibold text-slate-600">Price</th>
                  <th className="p-4 font-semibold text-slate-600">Tags</th>
                  <th className="p-4 font-semibold text-slate-600 text-center">Available</th>
                  <th className="p-4 font-semibold text-slate-600 text-right">Actions</th>
                </tr>
              </thead>
              <tbody>
                {filteredItems.map(item => (
                  <tr key={item._id} className="border-b border-slate-100 last:border-0 hover:bg-slate-50 transition-colors">
                    <td className="p-4">
                      {item.imageUrl && item.imageUrl.trim() !== '' ? (
                        <div className="w-12 h-12 rounded-lg bg-slate-100 overflow-hidden relative shadow-sm">
                          <img src={item.imageUrl} alt={item.name} className="w-full h-full object-cover" />
                        </div>
                      ) : (
                        <div className="w-12 h-12 bg-slate-100 rounded-lg flex items-center justify-center text-slate-400 border border-slate-200 shadow-inner">
                          <ImageIcon className="w-5 h-5" />
                        </div>
                      )}
                    </td>
                    <td className="p-4">
                      <p className="font-bold text-slate-800">{item.name}</p>
                      {item.description && <p className="text-xs text-slate-500 line-clamp-1 truncate w-48">{item.description}</p>}
                    </td>
                    <td className="p-4 font-black tracking-tight text-slate-800 text-lg">₹{item.price}</td>
                    <td className="p-4 flex flex-col gap-1.5 justify-center items-start">
                      <button 
                        onClick={() => toggleStatus(item._id, 'isPopular', item.isPopular)}
                        className={`flex items-center gap-1 text-xs font-bold px-2 py-1 rounded-md transition-colors ${item.isPopular ? 'bg-amber-100 text-amber-700 hover:bg-amber-200' : 'bg-slate-100 text-slate-400 hover:bg-slate-200'}`}
                      >
                        <Star className="w-3 h-3"/> Popular
                      </button>
                      <button 
                        onClick={() => toggleStatus(item._id, 'isTodaySpecial', item.isTodaySpecial)}
                        className={`flex items-center gap-1 text-xs font-bold px-2 py-1 rounded-md transition-colors ${item.isTodaySpecial ? 'bg-purple-100 text-purple-700 hover:bg-purple-200' : 'bg-slate-100 text-slate-400 hover:bg-slate-200'}`}
                      >
                        Today's Special
                      </button>
                    </td>
                    <td className="p-4 text-center">
                      <label className="relative inline-flex items-center cursor-pointer">
                        <input type="checkbox" className="sr-only peer" checked={!!item.isAvailable} onChange={() => toggleStatus(item._id, 'isAvailable', !!item.isAvailable)} />
                        <div className="w-11 h-6 bg-slate-200 peer-focus:outline-none rounded-full peer peer-checked:after:translate-x-full peer-checked:after:border-white after:content-[''] after:absolute after:top-[2px] after:left-[2px] after:bg-white after:border-gray-300 after:border after:rounded-full after:h-5 after:w-5 after:transition-all peer-checked:bg-emerald-500"></div>
                      </label>
                    </td>
                    <td className="p-4 text-right">
                      <button 
                        onClick={() => handleOpenModal(item)}
                        className="p-2 text-slate-400 hover:text-blue-600 hover:bg-blue-50 rounded-lg transition-colors shadow-sm bg-white border border-slate-100 mr-2"
                      >
                        <Edit className="w-4 h-4"/>
                      </button>
                      <button onClick={() => deleteMenu(item._id)} className="p-2 text-slate-400 hover:text-red-600 hover:bg-red-50 rounded-lg transition-colors shadow-sm bg-white border border-slate-100">
                        <Trash2 className="w-4 h-4"/>
                      </button>
                    </td>
                  </tr>
                ))}
              </tbody>
            </table>
          </div>
        )}
      </div>

      {showModal && (
        <div className="fixed inset-0 bg-slate-900/40 backdrop-blur-sm z-[100] flex items-center justify-center p-6">
          <div className="bg-white w-full max-w-xl rounded-[2rem] shadow-2xl overflow-hidden animate-in zoom-in-95 duration-200">
            <div className="p-8 border-b border-slate-100 flex items-center justify-between bg-slate-50">
               <div>
                 <h2 className="text-2xl font-black text-slate-900 tracking-tight">{editingItem ? "Edit Item" : "Add Menu Item"}</h2>
                 <p className="text-slate-500 text-sm mt-1">{editingItem ? "Update dish details." : "Create a new dish for the menu."}</p>
               </div>
               <button onClick={() => setShowModal(false)} className="p-2.5 bg-white border border-slate-200 rounded-2xl hover:bg-slate-100 transition-colors">
                 <X className="w-5 h-5 text-slate-600" />
               </button>
            </div>

            <form onSubmit={handleSaveMenu} className="p-8 space-y-6">
               <div className="grid grid-cols-2 gap-6">
                  <div className="col-span-2">
                    <label className="text-xs font-black uppercase tracking-widest text-slate-400 mb-2 block">Item Name *</label>
                    <input 
                      required
                      type="text" 
                      value={formData.name}
                      onChange={e => setFormData({...formData, name: e.target.value})}
                      className="w-full px-5 py-3.5 bg-slate-50 border border-slate-100 rounded-2xl font-black text-slate-800 focus:ring-4 focus:ring-amber-500/10 focus:border-amber-500 focus:outline-none transition-all"
                    />
                  </div>
                  <div className="col-span-2">
                    <label className="text-xs font-black uppercase tracking-widest text-slate-400 mb-2 block">Description</label>
                    <input 
                      type="text" 
                      value={formData.description}
                      onChange={e => setFormData({...formData, description: e.target.value})}
                      className="w-full px-5 py-3.5 bg-slate-50 border border-slate-100 rounded-2xl font-medium text-slate-800 focus:outline-none"
                    />
                  </div>
                  <div>
                    <label className="text-xs font-black uppercase tracking-widest text-slate-400 mb-2 block">Price (₹) *</label>
                    <input 
                      required
                      type="number" 
                      value={formData.price}
                      onChange={e => setFormData({...formData, price: e.target.value})}
                      className="w-full px-5 py-3.5 bg-slate-50 border border-slate-100 rounded-2xl font-bold text-slate-800 focus:outline-none"
                    />
                  </div>
                  <div>
                    <label className="text-xs font-black uppercase tracking-widest text-slate-400 mb-2 block">Category *</label>
                    <input 
                      required
                      type="text" 
                      list="cat-list"
                      value={formData.category}
                      onChange={e => setFormData({...formData, category: e.target.value})}
                      className="w-full px-5 py-3.5 bg-slate-50 border border-slate-100 rounded-2xl font-bold text-slate-800 focus:outline-none"
                    />
                    <datalist id="cat-list">
                       {categories.map(c => <option key={c} value={c} />)}
                    </datalist>
                  </div>
                  <div className="col-span-1">
                    <label className="text-xs font-black uppercase tracking-widest text-slate-400 mb-2 block">GST Rate (%) *</label>
                    <select 
                      required
                      value={formData.gstRate}
                      onChange={e => setFormData({...formData, gstRate: Number(e.target.value)})}
                      className="w-full px-5 py-3.5 bg-slate-50 border border-slate-100 rounded-2xl font-bold text-slate-800 focus:outline-none"
                    >
                      <option value="0">0% (Nil)</option>
                      <option value="5">5% (Restaurant)</option>
                      <option value="12">12%</option>
                      <option value="18">18%</option>
                    </select>
                  </div>
                  <div className="col-span-1">
                    <label className="text-xs font-black uppercase tracking-widest text-slate-400 mb-2 block">Image URL (Optional)</label>
                    <input 
                      type="url" 
                      value={formData.imageUrl}
                      onChange={e => setFormData({...formData, imageUrl: e.target.value})}
                      placeholder="https://..."
                      className="w-full px-5 py-3.5 bg-slate-50 border border-slate-100 rounded-2xl font-medium text-slate-500 focus:outline-none"
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
                    disabled={submitting}
                    type="submit"
                    className="flex-1 py-4 bg-amber-500 text-white rounded-2xl font-black shadow-lg shadow-amber-500/20 hover:bg-amber-600 active:scale-95 transition-all uppercase tracking-widest flex items-center justify-center gap-2"
                  >
                    {submitting && <Loader2 className="w-4 h-4 animate-spin" />}
                    {editingItem ? "Update Item" : "Create Item"}
                  </button>
               </div>
            </form>
          </div>
        </div>
      )}
    </div>
  );
}
