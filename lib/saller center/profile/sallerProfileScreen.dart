import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:zrai_mart/ChatWithAdmin/ChatWithAdminScreen.dart';
import 'package:zrai_mart/Notification/Notification.dart';
import 'package:zrai_mart/UI/auth/signInScreen.dart';
import 'package:zrai_mart/saller%20center/profile/sallerEditProfileScreen.dart';
import 'package:zrai_mart/saller%20center/profile/withdrawRequest.dart';
import 'package:zrai_mart/saller%20center/storeView/StooreSettingcreen.dart';
import 'package:zrai_mart/saller%20center/storeView/StorePreviewScreen.dart';

import '../../app_colors.dart';
import '../CouponCode/coupon_code_list_screen.dart';
import '../customGestureDetector/sallerCustomGestureDetector.dart';
import 'HelpCenterScreen.dart';
import 'LanguageSelectionScreen.dart';
import 'PrivacyPolicyScreen.dart';
// import 'package:zrai_mart/utils/app_colors.dart';

class sallerProfilescreen extends StatefulWidget {
  const sallerProfilescreen({super.key});

  @override
  State<sallerProfilescreen> createState() => _sallerProfilescreenState();
}

class _sallerProfilescreenState extends State<sallerProfilescreen> {
  // --- BACKEND LOGIC PRESERVED ---
  bool light = false;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  String _name = 'Loading...';
  String _email = 'Loading...';
  var profileImageUrl;
  double balance = 0;
  double onHold = 0;
  double totalEarning = 0;
  double totalWithdrawn = 0;
  double pendingWithdrawal = 0;

  @override
  void initState() {
    super.initState();
    _fetchUserData();
  }

  Future<void> _fetchUserData() async {
    User? user = _auth.currentUser;
    if (user == null) return;

    try {
      DocumentSnapshot userDoc =
      await _firestore.collection('saller').doc(user.uid).get();

      if (userDoc.exists) {
        final data = userDoc.data() as Map<String, dynamic>;

        setState(() {
          _name = data['name'] ?? 'No name';
          _email = data['email'] ?? 'No email';
          profileImageUrl = data['profileImage'];

          /// MONEY FIELDS (DOUBLE SAFE)
          balance = (data['balance'] ?? 0).toDouble();

          totalEarning = (data['totalEarnings'] ?? 0).toDouble();
          onHold = (data['onHold'] ?? 0).toDouble();
          totalWithdrawn = (data['totalWithdrawn'] ?? 0).toDouble();
          pendingWithdrawal = (data['pendingWithdrawal'] ?? 0).toDouble();
        });
      }
    } catch (e) {
      print("Error fetching seller data: $e");
    }
  }

  // --- NAVIGATION HANDLERS (UNTOUCHED) ---
  void handleNotificationTap() {
    Navigator.push(context, MaterialPageRoute(builder: (context) => UniversalNotificationScreen(currentUserId: _auth.currentUser!.uid, userRole: 'seller')));
  }  void handleCouponCodeTap() {
    Navigator.push(context, MaterialPageRoute(builder: (context) => const CouponListScreen()));
  }void handleStoreTap() {
    Navigator.push(context, MaterialPageRoute(builder: (context) => const StoreSettingsScreen()));
  }
  void handleStoreCustomerViewTap() {
    Navigator.push(context, MaterialPageRoute(builder: (context) => StorePreviewScreen(sellerId: _auth.currentUser!.uid,)));
  }
  void handleWithdrawTap() {
    Navigator.push(context, MaterialPageRoute(builder: (context) => WithdrawScreen(sellerId: _auth.currentUser!.uid,)));
  }
  void handleLanguageTap() => Navigator.push(context, MaterialPageRoute(builder: (context) => const LanguageSelectionScreen()));
  void handlePrivacyPolicyTap() => Navigator.push(context, MaterialPageRoute(builder: (context) => const PrivacyPolicyScreen()));
  void handleHelpCenterTap() => Navigator.push(context, MaterialPageRoute(builder: (context) => const HelpCenterScreen()));

  void handleLogoutTap() {
    _signOut();
    Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (context) => const Signinscreen()), (route) => false);
  }
  void handleAdminChatTap()=> Navigator.push(context, MaterialPageRoute(builder: (context)=>const ChatWithAdminScreen()));

  Future<void> _signOut() async {
    try {
      await _auth.signOut();
      _showSnackBar('Signed out successfully', AppColors.primaryGreen);
    } catch (e) {
      _showSnackBar('Error: $e', AppColors.errorRed);
    }
  }

  void _showSnackBar(String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: color, behavior: SnackBarBehavior.floating),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text("My Account", style: TextStyle(color: AppColors.textDark, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            const SizedBox(height: 20),

            // 1. Profile Header Section
            Center(
              child: Stack(
                children: [
                  CircleAvatar(
                    radius: 55,
                    backgroundColor: AppColors.primaryGreen.withOpacity(0.1),
                    backgroundImage: profileImageUrl != null
                        ? NetworkImage(profileImageUrl!)
                        : const AssetImage('assets/img_2.png') as ImageProvider,
                  ),
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: CircleAvatar(
                      radius: 18,
                      backgroundColor: AppColors.primaryGreen,
                      child: IconButton(
                        icon: const Icon(Icons.edit, size: 15, color: Colors.white),
                        onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const sallerEditProfileScreen())),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 15),
            Text(_name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 20, color: AppColors.textDark)),
            Text(_email, style: const TextStyle(color: AppColors.textGrey, fontSize: 14)),

            const SizedBox(height: 25),

            // 2. Balance Card
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [AppColors.primaryGreen, Color(0xFF1B5E20)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primaryGreen.withOpacity(0.3),
                      blurRadius: 10,
                      offset: const Offset(0, 5),
                    )
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "Wallet Overview",
                      style: TextStyle(color: Colors.white70, fontSize: 14),
                    ),
                    const SizedBox(height: 15),

                    /// GRID
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        _walletItem("Earnings", totalEarning),
                        _walletItem("Balance", balance),
                      ],
                    ),
                    const SizedBox(height: 15),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        _walletItem("On Hold", onHold),
                        _walletItem("Withdrawn", totalWithdrawn),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 30),

            // 3. Settings List
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 20),
              padding: const EdgeInsets.symmetric(vertical: 10),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10)],
              ),
              child: Column(
                children: [
                  _buildProfileTile(Icons.person_outline, "Edit Profile", () {
                    Navigator.push(context, MaterialPageRoute(builder: (context) => const sallerEditProfileScreen()));
                  }),
                  _buildProfileTile(Icons.discount, "Coupon Codes", handleCouponCodeTap),

                  _buildProfileTile(Icons.store, "Store Settings", handleStoreTap),
                  _buildProfileTile(Icons.store, "Store Customer View", handleStoreCustomerViewTap),
                  _buildProfileTile(Icons.payment, "Withdraw Request", handleWithdrawTap),
                  _buildProfileTile(Icons.notifications_none_outlined, "Notifications", handleNotificationTap),
                  _buildProfileTile(Icons.translate, "Language", handleLanguageTap),
                  _buildProfileTile(Icons.security_outlined, "Privacy Policy", handlePrivacyPolicyTap),
                  _buildProfileTile(Icons.help_outline, "Help Center", handleHelpCenterTap),
                  const Divider(indent: 20, endIndent: 20),

                  _buildProfileTile(Icons.support_agent, "Customer Support 24/7", handleAdminChatTap,),

                  const Divider(indent: 20, endIndent: 20),
                  _buildProfileTile(Icons.logout, "Logout", handleLogoutTap, isLogout: true),
                ],
              ),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileTile(IconData icon, String title, VoidCallback onTap, {bool isLogout = false}) {
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: isLogout ? Colors.red.withOpacity(0.1) : AppColors.primaryGreen.withOpacity(0.1),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, color: isLogout ? Colors.red : AppColors.primaryGreen, size: 22),
      ),
      title: Text(title, style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: isLogout ? Colors.red : AppColors.textDark)),
      trailing: const Icon(Icons.arrow_forward_ios, size: 16, color: AppColors.textGrey),
      onTap: onTap,
    );
  }
  Widget _walletItem(String title, double value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(color: Colors.white70, fontSize: 12),
        ),
        const SizedBox(height: 5),
        Text(
          "PKR ${value.toStringAsFixed(2)}",
          style: const TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
}