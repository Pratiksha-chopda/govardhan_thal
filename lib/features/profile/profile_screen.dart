import 'package:flutter/material.dart';
import 'package:restaurant/core/globals.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../services/api_service.dart';
import '../../services/token_manager.dart';
import '../login/login.dart';
import '../home/my_reservations_screen.dart';
import '../address/add_address_screen.dart';
import '../wishlist/wishlist_screen.dart';
import '../../services/fcm_service.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  String _userName = "Loading...";
  String _userPhone = "";
  String _userEmail = "";
  String _userRole = "user";
  bool _isLoading = true;
  bool _notificationsEnabled = true;
  bool _orderUpdates = true;
  bool _promotions = false;
  String? _userId;

  @override
  void initState() {
    super.initState();
    _loadProfileData();
    _loadSettings();
  }

  Future<void> _loadProfileData() async {
    _userId = await TokenManager.getUserId();
    _userName = await TokenManager.getUserName();
    _userEmail = await TokenManager.getUserEmail();
    _userRole = await TokenManager.getUserRole();
    
    setState(() => _isLoading = false);

    if (_userId != null) {
      final result = await ApiService.getProfile();
      if ((result['status'] == 'success' || result['success'] == true) && mounted) {
        final data = result['data'];
        await TokenManager.saveUserInfo(
          userId: _userId!,
          name: data['name'] ?? '',
          email: data['email'] ?? '',
          role: data['role'] ?? 'user',
        );

        setState(() {
          _userName = data['name'] ?? _userName;
          _userPhone = data['mobile'] ?? '';
          _userEmail = data['email'] ?? '';
          _userRole = data['role'] ?? 'user';
        });
      }
    }
  }

  Future<void> _loadSettings() async {
    final uid = await TokenManager.getUserId();
    if (uid == null) return;

    final result = await ApiService.getSettings(int.tryParse(uid) ?? 0);
    if ((result['status'] == 'success' || result['success'] == true) && mounted) {
      final data = result['data'];
      setState(() {
        _notificationsEnabled = data['notifications_enabled'] == 1 || data['notifications_enabled'] == true;
        _orderUpdates = data['order_updates'] == 1 || data['order_updates'] == true;
        _promotions = data['promotions'] == 1 || data['promotions'] == true;
      });
    }
  }

  Future<void> _saveSettings() async {
    if (_userId == null) return;
    await ApiService.updateSettings(int.tryParse(_userId!) ?? 0, _notificationsEnabled, _orderUpdates, _promotions);
  }

  Future<void> _handleLogout() async {
    // Remove FCM token from server before logging out
    try {
      final fcmService = FcmService();
      await fcmService.removeTokenFromServer();
    } catch (_) {}
    await TokenManager.clearAll();
    if (mounted) {
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const LoginScreen()),
        (route) => false,
      );
    }
  }

  void _showEditProfileDialog() {
    final nameCtrl = TextEditingController(text: _userName);
    final emailCtrl = TextEditingController(text: _userEmail);
    final phoneCtrl = TextEditingController(text: _userPhone);

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
        title: Text("Edit Profile", style: GoogleFonts.poppins(fontWeight: FontWeight.w900, fontSize: 20)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _dialogField(nameCtrl, "Name", Icons.person_rounded),
            const SizedBox(height: 16),
            _dialogField(emailCtrl, "Email", Icons.alternate_email_rounded),
            const SizedBox(height: 16),
            _dialogField(phoneCtrl, "Mobile", Icons.phone_iphone_rounded),
          ],
        ),
        actionsPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: Text("Cancel", style: GoogleFonts.poppins(color: Colors.grey, fontWeight: FontWeight.w700))),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFFF6A00),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              elevation: 0,
            ),
            onPressed: () async {
              Navigator.pop(context);
              if (_userId != null) {
                final result = await ApiService.updateProfile(nameCtrl.text.trim(), emailCtrl.text.trim(), phoneCtrl.text.trim());
                if (!mounted) return;
                
                if ((result['status'] == 'success' || result['success'] == true)) {
                  await TokenManager.saveUserInfo(userId: _userId!, name: nameCtrl.text.trim(), email: emailCtrl.text.trim(), role: _userRole);
                  if (!mounted) return;
                  
                  setState(() {
                    _userName = nameCtrl.text.trim();
                    _userPhone = phoneCtrl.text.trim();
                    _userEmail = emailCtrl.text.trim();
                  });
                  scaffoldMessengerKey.currentState!.showSnackBar(
                    SnackBar(
                      content: Text("Profile updated successfully!", style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
                      backgroundColor: Colors.green.shade600,
                      behavior: SnackBarBehavior.floating,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  );
                }
              }
            },
            child: Text("Save Changes", style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 13)),
          ),
        ],
      ),
    );
  }

  Widget _dialogField(TextEditingController ctrl, String hint, IconData icon) {
    return TextField(
      controller: ctrl,
      style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w600),
      decoration: InputDecoration(
        hintText: hint,
        prefixIcon: Icon(icon, color: const Color(0xFFFF6A00), size: 20),
        filled: true,
        fillColor: Colors.grey.shade50,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(18), borderSide: BorderSide.none),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(18), borderSide: BorderSide(color: Colors.grey.shade100)),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(18), borderSide: const BorderSide(color: Color(0xFFFF6A00), width: 1.5)),
      ),
    );
  }

  void _showNotificationsDialog() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(30))),
      backgroundColor: Colors.white,
      builder: (_) => StatefulBuilder(
        builder: (ctx, setModalState) => Padding(
          padding: const EdgeInsets.fromLTRB(28, 20, 28, 40),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey.shade200, borderRadius: BorderRadius.circular(2)))),
              const SizedBox(height: 24),
              Text("Notification Preferences", style: GoogleFonts.poppins(fontSize: 20, fontWeight: FontWeight.w900, color: Colors.black)),
              const SizedBox(height: 24),
              _buildSwitchItem("Global Notifications", "Receive all restaurant updates", _notificationsEnabled, (v) {
                setModalState(() => _notificationsEnabled = v); setState(() {}); _saveSettings();
              }),
              _buildSwitchItem("Order Status Updates", "Live updates on your food", _orderUpdates, (v) {
                setModalState(() => _orderUpdates = v); setState(() {}); _saveSettings();
              }),
              _buildSwitchItem("Deals & Promotions", "Exclusive offers and discounts", _promotions, (v) {
                setModalState(() => _promotions = v); setState(() {}); _saveSettings();
              }),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSwitchItem(String title, String subtitle, bool value, Function(bool) onChanged) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: GoogleFonts.poppins(fontWeight: FontWeight.w800, fontSize: 15, color: Colors.black87)),
                Text(subtitle, style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey.shade500, fontWeight: FontWeight.w500)),
              ],
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeColor: const Color(0xFFFF6A00),
            activeTrackColor: const Color(0xFFFF6A00).withValues(alpha: 0.2),
            inactiveTrackColor: Colors.grey.shade100,
            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
        ],
      ),
    );
  }

  Future<void> _handleDeleteAccount() async {
    final TextEditingController confirmController = TextEditingController();
    
    final confirmed = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (_) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.warning_amber_rounded, color: Colors.red.shade600, size: 48),
              ),
              const SizedBox(height: 20),
              Text("Delete Account?",
                  textAlign: TextAlign.center,
                  style: GoogleFonts.poppins(fontSize: 20, fontWeight: FontWeight.w900, color: Colors.red.shade700)),
              const SizedBox(height: 12),
              Text(
                "This action is permanent and cannot be undone. All your orders, addresses, favourites, and personal data will be permanently erased.",
                textAlign: TextAlign.center,
                style: GoogleFonts.poppins(fontSize: 13, color: Colors.grey.shade600, height: 1.5),
              ),
              const SizedBox(height: 20),
              Text("Type DELETE to confirm:",
                  style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.w700, color: Colors.grey.shade700)),
              const SizedBox(height: 8),
              TextField(
                controller: confirmController,
                textAlign: TextAlign.center,
                style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w900, color: Colors.red.shade700, letterSpacing: 2),
                decoration: InputDecoration(
                  hintText: "DELETE",
                  hintStyle: GoogleFonts.poppins(fontSize: 16, color: Colors.grey.shade300, letterSpacing: 2),
                  filled: true,
                  fillColor: Colors.red.shade50,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide(color: Colors.red.shade200),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide(color: Colors.red.shade400, width: 2),
                  ),
                ),
                onChanged: (_) => setDialogState(() {}),
              ),
            ],
          ),
          actionsPadding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
          actions: [
            Row(
              children: [
                Expanded(
                  child: TextButton(
                    onPressed: () => Navigator.pop(context, false),
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                    child: Text("Cancel", style: GoogleFonts.poppins(fontWeight: FontWeight.w700, color: Colors.grey)),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: confirmController.text == "DELETE"
                        ? () => Navigator.pop(context, true)
                        : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red.shade600,
                      disabledBackgroundColor: Colors.grey.shade200,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      elevation: 0,
                    ),
                    child: Text("Delete",
                        style: GoogleFonts.poppins(
                          fontWeight: FontWeight.w900,
                          fontSize: 14,
                          color: confirmController.text == "DELETE" ? Colors.white : Colors.grey.shade400,
                        )),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );

    if (confirmed != true || !mounted) return;

    // Show loading indicator
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 16),
            const CircularProgressIndicator(color: Color(0xFFFF6A00)),
            const SizedBox(height: 20),
            Text("Deleting your account...",
                style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );

    // Remove FCM token before deleting
    try {
      final fcmService = FcmService();
      await fcmService.removeTokenFromServer();
    } catch (_) {}

    final result = await ApiService.deleteAccount();

    if (!mounted) return;
    Navigator.pop(context); // close loading dialog

    if (result['success'] == true) {
      await TokenManager.clearAll();
      if (!mounted) return;

      scaffoldMessengerKey.currentState?.showSnackBar(
        SnackBar(
          content: Text("Account deleted successfully.", style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
          backgroundColor: Colors.green.shade600,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );

      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const LoginScreen()),
        (route) => false,
      );
    } else {
      scaffoldMessengerKey.currentState?.showSnackBar(
        SnackBar(
          content: Text(result['message'] ?? "Failed to delete account", style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
          backgroundColor: Colors.red.shade600,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
    }
  }

  void _showAddressesScreen() {
    Navigator.push(context, MaterialPageRoute(builder: (_) => const _AddressesScreen()));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFBFBFB),
      appBar: AppBar(
        title: Text("Profile Settings", style: GoogleFonts.poppins(fontWeight: FontWeight.w900, fontSize: 18, color: Colors.black)),
        centerTitle: false,
        backgroundColor: Colors.white,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFFFF6A00)))
          : SingleChildScrollView(
              padding: const EdgeInsets.symmetric(vertical: 24),
              physics: const BouncingScrollPhysics(),
              child: Column(
                children: [
                  // PROFILE HEADER
                  Container(
                    margin: const EdgeInsets.symmetric(horizontal: 24),
                    padding: const EdgeInsets.all(28),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(30),
                      boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 20, offset: const Offset(0, 10))],
                    ),
                    child: Row(
                      children: [
                        Stack(
                          alignment: Alignment.bottomRight,
                          children: [
                            Container(
                              width: 80, height: 80,
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(colors: [Color(0xFFFF6A00), Color(0xFFEE0979)]),
                                borderRadius: BorderRadius.circular(24),
                                boxShadow: [BoxShadow(color: const Color(0xFFFF6A00).withValues(alpha: 0.3), blurRadius: 15, offset: const Offset(0, 8))],
                              ),
                              child: const Icon(Icons.person_rounded, size: 44, color: Colors.white),
                            ),
                            Transform.translate(
                              offset: const Offset(6, 6),
                              child: GestureDetector(
                                onTap: _showEditProfileDialog,
                                child: Container(
                                  padding: const EdgeInsets.all(6),
                                  decoration: const BoxDecoration(color: Colors.black, shape: BoxShape.circle),
                                  child: const Icon(Icons.edit_rounded, size: 14, color: Colors.white),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(width: 24),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(_userName, style: GoogleFonts.poppins(fontSize: 22, fontWeight: FontWeight.w900, color: Colors.black, letterSpacing: -0.5)),
                              const SizedBox(height: 4),
                              Text(_userPhone.isNotEmpty ? _userPhone : _userEmail,
                                  style: GoogleFonts.poppins(fontSize: 13, color: Colors.grey.shade500, fontWeight: FontWeight.w600)),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 40),

                  // SETTINGS LIST
                  Container(
                    margin: const EdgeInsets.symmetric(horizontal: 24),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(30),
                      boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 20, offset: const Offset(0, 10))],
                    ),
                    child: Column(
                      children: [
                        _buildSettingsTile(Icons.person_outline_rounded, "Account Details", "Manage your personal info", onTap: _showEditProfileDialog),
                        _buildDivider(),
                        _buildSettingsTile(Icons.event_note_rounded, "My Reservations", "Track your table bookings", onTap: () {
                          Navigator.push(context, MaterialPageRoute(builder: (_) => const MyReservationsScreen()));
                        }),
                        _buildDivider(),
                        _buildSettingsTile(Icons.favorite_outline_rounded, "My Favourites", "Your saved favourite dishes", onTap: () {
                          Navigator.push(context, MaterialPageRoute(builder: (_) => const WishlistScreen()));
                        }),
                        _buildDivider(),
                        _buildSettingsTile(Icons.location_on_outlined, "Delivery Addresses", "Manage where you want food", onTap: _showAddressesScreen),
                        _buildDivider(),
                        _buildSettingsTile(Icons.notifications_none_rounded, "Notifications", "Customize alerts & updates", onTap: _showNotificationsDialog),
                        _buildDivider(),
                        _buildSettingsTile(Icons.support_agent_rounded, "Help & Support", "Get help from our team", onTap: () {
                          scaffoldMessengerKey.currentState!.showSnackBar(
                            SnackBar(content: Text("Support: +91-9999-0000 | help@govardhan.com", style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
                            behavior: SnackBarBehavior.floating, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                          );
                        }),
                        _buildDivider(),
                        _buildSettingsTile(Icons.power_settings_new_rounded, "Sign Out", "Safely logout of your account", onTap: _handleLogout, isLogout: true),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),

                  // DELETE ACCOUNT — Visually separated danger zone
                  Container(
                    margin: const EdgeInsets.symmetric(horizontal: 24),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(30),
                      border: Border.all(color: Colors.red.shade100, width: 1),
                      boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 10, offset: const Offset(0, 4))],
                    ),
                    child: _buildSettingsTile(
                      Icons.delete_forever_rounded,
                      "Delete Account",
                      "Permanently erase all your data",
                      onTap: _handleDeleteAccount,
                      isLogout: true,
                    ),
                  ),

                  const SizedBox(height: 40),
                ],
              ),
            ),
    );
  }

  Widget _buildSettingsTile(IconData icon, String title, String subtitle, {VoidCallback? onTap, bool isLogout = false}) {
    final themeColor = isLogout ? Colors.red.shade600 : const Color(0xFFFF6A00);
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(color: themeColor.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(16)),
        child: Icon(icon, color: themeColor, size: 22),
      ),
      title: Text(title, style: GoogleFonts.poppins(fontWeight: FontWeight.w800, fontSize: 15, color: isLogout ? Colors.red.shade600 : Colors.black87)),
      subtitle: Text(subtitle, style: GoogleFonts.poppins(fontSize: 11, color: Colors.grey.shade500, fontWeight: FontWeight.w500)),
      trailing: Icon(Icons.chevron_right_rounded, size: 20, color: Colors.grey.shade300),
      contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      onTap: onTap,
    );
  }

  Widget _buildDivider() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Divider(color: Colors.grey.shade50, height: 1, thickness: 1),
    );
  }
}

class _AddressesScreen extends StatefulWidget {
  const _AddressesScreen();
  @override
  State<_AddressesScreen> createState() => _AddressesScreenState();
}

class _AddressesScreenState extends State<_AddressesScreen> {
  List<dynamic> _addresses = [];
  bool _isLoading = true;
  String? _userId;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    _userId = await TokenManager.getUserId();
    if (_userId == null) {
      if (mounted) setState(() => _isLoading = false);
      return;
    }
    final addresses = await ApiService.getAddresses(_userId!);
    if (mounted) {
      setState(() {
        _addresses = addresses;
        _isLoading = false;
      });
    }
  }

  void _showAddDialog() {
    Navigator.push(context, MaterialPageRoute(builder: (_) => const AddAddressScreen())).then((_) => _load());
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFBFBFB),
      appBar: AppBar(
        title: Text("Saved Addresses", style: GoogleFonts.poppins(fontWeight: FontWeight.w900, fontSize: 18, color: Colors.black)),
        centerTitle: false,
        backgroundColor: Colors.white,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        leading: IconButton(icon: const Icon(Icons.arrow_back_rounded, color: Colors.black), onPressed: () => Navigator.pop(context)),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showAddDialog,
        backgroundColor: Colors.black,
        elevation: 8,
        icon: const Icon(Icons.add_location_alt_rounded, color: Colors.white, size: 20),
        label: Text("NEW ADDRESS", style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 12, letterSpacing: 0.5)),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFFFF6A00)))
          : _addresses.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(color: Colors.grey.shade100, shape: BoxShape.circle),
                        child: Icon(Icons.map_rounded, size: 64, color: Colors.grey.shade400),
                      ),
                      const SizedBox(height: 24),
                      Text("No addresses found", style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.w800, color: Colors.black87)),
                      const SizedBox(height: 8),
                      Text("Add an address for faster checkout!", style: GoogleFonts.poppins(fontSize: 13, color: Colors.grey.shade500, fontWeight: FontWeight.w500)),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.fromLTRB(24, 20, 24, 100),
                  physics: const BouncingScrollPhysics(),
                  itemCount: _addresses.length,
                  itemBuilder: (_, i) {
                    final a = _addresses[i];
                    final isDefault = a['is_default'] == 1 || a['is_default'] == true;
                    return Container(
                      margin: const EdgeInsets.only(bottom: 16),
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(24),
                        border: isDefault ? Border.all(color: const Color(0xFFFF6A00), width: 1.5) : Border.all(color: Colors.transparent),
                        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 15, offset: const Offset(0, 8))],
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(color: const Color(0xFFFF6A00).withValues(alpha: 0.12), borderRadius: BorderRadius.circular(16)),
                            child: Icon(a['label'] == 'Work' ? Icons.work_rounded : (a['label'] == 'Home' ? Icons.home_rounded : Icons.location_on_rounded), color: const Color(0xFFFF6A00), size: 24),
                          ),
                          const SizedBox(width: 20),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Text(a['label'] ?? 'Home', style: GoogleFonts.poppins(fontWeight: FontWeight.w900, fontSize: 16, color: Colors.black87)),
                                    if (isDefault) ...[
                                      const SizedBox(width: 10),
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                        decoration: BoxDecoration(color: const Color(0xFFFF6A00), borderRadius: BorderRadius.circular(8)),
                                        child: Text("DEFAULT", style: GoogleFonts.poppins(color: Colors.white, fontSize: 9, fontWeight: FontWeight.w900, letterSpacing: 0.5)),
                                      ),
                                    ]
                                  ],
                                ),
                                const SizedBox(height: 6),
                                Text("${a['house_no']}, ${a['street']}, ${a['area']}, ${a['city']} - ${a['pincode'] ?? ''}",
                                    style: GoogleFonts.poppins(color: Colors.grey.shade500, fontSize: 13, fontWeight: FontWeight.w500, height: 1.4)),
                              ],
                            ),
                          ),
                          IconButton(
                            icon: Icon(Icons.delete_outline_rounded, color: Colors.red.shade300, size: 22),
                            onPressed: () async {
                              final confirmed = await showDialog<bool>(
                                context: context,
                                builder: (_) => AlertDialog(
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                                  title: Text("Delete Address?", style: GoogleFonts.poppins(fontWeight: FontWeight.w900)),
                                  content: Text("Are you sure you want to remove this address?", style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w500)),
                                  actions: [
                                    TextButton(onPressed: () => Navigator.pop(context, false), child: Text("Cancel", style: GoogleFonts.poppins(fontWeight: FontWeight.bold, color: Colors.grey))),
                                    TextButton(onPressed: () => Navigator.pop(context, true), child: Text("Delete", style: GoogleFonts.poppins(fontWeight: FontWeight.w900, color: Colors.red))),
                                  ],
                                ),
                              );
                              if (confirmed == true) {
                                await ApiService.deleteAddress(a['address_id']);
                                _load();
                              }
                            },
                          )
                        ],
                      ),
                    );
                  },
                ),
    );
  }
}
