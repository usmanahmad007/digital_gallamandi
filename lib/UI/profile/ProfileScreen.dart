import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:zrai_mart/ChatWithAdmin/ChatWithAdminScreen.dart';
import 'package:zrai_mart/Notification/Notification.dart';
import 'package:zrai_mart/UI/profile/EditProfileScreen.dart';
import 'package:zrai_mart/UI/auth/signInScreen.dart';
import 'package:zrai_mart/saller center/profile/HelpCenterScreen.dart';
import 'package:zrai_mart/saller center/profile/LanguageSelectionScreen.dart';
import '../../app_colors.dart';
import '../../saller center/profile/PrivacyPolicyScreen.dart';

class Profilescreen extends StatefulWidget {
  const Profilescreen({super.key});

  @override
  State<Profilescreen> createState() => _ProfilescreenState();
}

class _ProfilescreenState extends State<Profilescreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  String _name = '...';
  String _email = '...';
  String? profileImageUrl;
  String _status = 'approved';

  @override
  void initState() {
    super.initState();
    _fetchUserData();
  }

  Future<void> _fetchUserData() async {
    User? user = _auth.currentUser;
    if (user != null) {
      try {
        DocumentSnapshot userDoc = await _firestore.collection('users').doc(user.uid).get();
        if (userDoc.exists) {
          setState(() {
            _name = userDoc['name'] ?? 'User';
            _email = userDoc['email'] ?? '';
            _status = userDoc['userStatus'] ?? 'approved';
            profileImageUrl = userDoc['profileImage'];
          });
        }
      } catch (e) {
        debugPrint('Error: $e');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    const primaryColor = AppColors.primaryGreen;

    return Scaffold(
      backgroundColor: const Color(0xffF8F9FD),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // 1. Modern Header & Profile Card
            Stack(
              clipBehavior: Clip.none,
              alignment: Alignment.center,
              children: [
                _buildHeaderGradient(primaryColor),
                Positioned(
                  top: 100,
                  child: _buildProfileCard(primaryColor),
                ),
              ],
            ),
            const SizedBox(height: 120), // Spacer for the floating card
            // 2. Settings Sections
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildStatusWarning(),

                  _buildSectionLabel("Account Settings"),
                  _buildSettingsGroup([
                    _buildSettingsTile(Icons.person_outline, "Edit Profile", () {
                      Navigator.push(context, MaterialPageRoute(builder: (_) => const EditProfileScreen()));
                    }),
                    _buildSettingsTile(Icons.notifications_none_outlined, "Notifications", () {
                      Navigator.push(context, MaterialPageRoute(builder: (_) => UniversalNotificationScreen(currentUserId: _auth.currentUser!.uid, userRole: 'customer',)));
                    }),
                  ]),

                  const SizedBox(height: 25),
                  _buildSectionLabel("General"),
                  _buildSettingsGroup([
                    _buildSettingsTile(Icons.language_outlined, "Language", () {
                      Navigator.push(context, MaterialPageRoute(builder: (_) => const LanguageSelectionScreen()));
                    }),
                    _buildSettingsTile(Icons.shield_outlined, "Privacy Policy", () {
                      Navigator.push(context, MaterialPageRoute(builder: (_) => const PrivacyPolicyScreen()));
                    }),
                    _buildSettingsTile(Icons.help_outline, "Help Center", () {
                      Navigator.push(context, MaterialPageRoute(builder: (_) => const HelpCenterScreen()));
                    }),
                  ]),

                  const SizedBox(height: 25),
                  _buildSectionLabel("Support"),

                  _buildSettingsGroup([
                    _buildSettingsTile(Icons.support_agent, "Customer Support 24/7", () {
                      Navigator.push(context, MaterialPageRoute(builder: (_) => const ChatWithAdminScreen()));
                    }),

                  ]),

                  const SizedBox(height: 30),
                  // 3. Logout Button
                  _buildLogoutButton(),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusWarning() {
    if (_status == 'approved') return const SizedBox.shrink();

    bool isBlocked = _status == 'blocked';

    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: isBlocked ? Colors.red[50] : Colors.amber[50],
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: isBlocked ? Colors.red.shade100 : Colors.amber.shade200),
      ),
      child: Row(
        children: [
          Icon(
            isBlocked ? Icons.block_flipped : Icons.warning_amber_rounded,
            color: isBlocked ? Colors.red : Colors.amber[800],
          ),
          const SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isBlocked ? "Account Blocked" : "Account Restricted",
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: isBlocked ? Colors.red[900] : Colors.amber[900],
                  ),
                ),
                Text(
                  isBlocked
                      ? "You cannot place orders or use the cart."
                      : "Some features may be limited. Contact support.",
                  style: TextStyle(fontSize: 12, color: Colors.grey[800]),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
  Widget _buildHeaderGradient(Color primary) {
    return Container(
      height: 200,
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [primary, const Color(0xFF4facfe)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(40)),
      ),
      child: const SafeArea(
        child: Padding(
          padding: EdgeInsets.only(top: 20),
          child: Text(
            "My Profile",
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold),
          ),
        ),
      ),
    );
  }

  Widget _buildProfileCard(Color primary) {
    return Container(
      width: MediaQuery.of(context).size.width * 0.85,
      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 15),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(25),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.08), blurRadius: 20, offset: const Offset(0, 10)),
        ],
      ),
      child: Column(
        children: [
          CircleAvatar(
            radius: 45,
            backgroundColor: primary.withOpacity(0.1),
            backgroundImage: profileImageUrl != null
                ? NetworkImage(profileImageUrl!)
                : const AssetImage('assets/img_2.png') as ImageProvider,
          ),
          const SizedBox(height: 12),
          Text(_name, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          Text(_email, style: const TextStyle(color: Colors.grey, fontSize: 13)),
        ],
      ),
    );
  }

  Widget _buildSectionLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(left: 5, bottom: 10),
      child: Text(text, style: TextStyle(color: Colors.grey[800], fontWeight: FontWeight.bold, fontSize: 16)),
    );
  }

  Widget _buildSettingsGroup(List<Widget> children) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10)],
      ),
      child: Column(children: children),
    );
  }

  Widget _buildSettingsTile(IconData icon, String title, VoidCallback onTap) {
    return ListTile(
      onTap: onTap,
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(color: const Color(0xffF0F3F6), borderRadius: BorderRadius.circular(10)),
        child: Icon(icon, color: AppColors.primaryGreen, size: 20),
      ),
      title: Text(title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
      trailing: const Icon(Icons.chevron_right, color: Colors.grey, size: 20),
    );
  }

  Widget _buildLogoutButton() {
    return InkWell(
      onTap: () => _signOut(),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 15),
        width: double.infinity,
        decoration: BoxDecoration(
          color: Colors.red.withOpacity(0.08),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.red.withOpacity(0.1)),
        ),
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.logout_rounded, color: Colors.red, size: 20),
            SizedBox(width: 10),
            Text("Logout", style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold, fontSize: 16)),
          ],
        ),
      ),
    );
  }

  Future<void> _signOut() async {
    try {
      await _auth.signOut();
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => const Signinscreen()),
            (route) => false,
      );
    } catch (e) {
      debugPrint("Error signing out: $e");
    }
  }
}