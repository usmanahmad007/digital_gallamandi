import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:zrai_mart/app_colors.dart'; // Using your AppColors
import '../../../Notification/send_notification.dart';
import 'AdminUserOrdersScreen.dart';

class AdminUsersScreen extends StatefulWidget {
  const AdminUsersScreen({super.key});

  @override
  State<AdminUsersScreen> createState() => _AdminUsersScreenState();
}

class _AdminUsersScreenState extends State<AdminUsersScreen> {
  String searchQuery = "";
  final TextEditingController _searchController = TextEditingController();

  // --- Logic Methods ---

  Future<Map<String, dynamic>> getGlobalStats() async {
    final query = await FirebaseFirestore.instance.collection('orders').get();
    double totalRevenue = 0;
    for (var doc in query.docs) {
      totalRevenue += (doc['totalPrice'] ?? 0).toDouble();
    }
    return {"revenue": totalRevenue, "orders": query.docs.length};
  }

  Future<void> updateUserStatus(String userId, String status) async {
    // 1. Update the status in Firestore
    await FirebaseFirestore.instance.collection('users').doc(userId).update({
      'userStatus': status,
      'updatedAt': FieldValue.serverTimestamp(),
    });

    // 2. Define the notification content based on status
    String title;
    String message;

    switch (status) {
      case 'approved':
        title = "Account Approved! 🎉";
        message = "Great news! Your account has been verified. You can now access all features and place orders.";
        break;
      case 'restricted':
        title = "Account Restricted ⚠️";
        message = "Your account has been restricted. Some actions like 'Add to Cart' may be disabled. Please check your email for details.";
        break;
      case 'blocked':
        title = "Account Blocked 🚫";
        message = "Your account access has been suspended due to a violation of our policies. Contact support if you believe this is an error.";
        break;
      default:
        title = "Account Update";
        message = "Your account status has been updated to $status.";
    }

    // 3. Send the notification
    await sendNotification(
      senderRole: "admin",
      senderId: "admin",
      userId: userId,
      title: title,
      body: message,
      type: "store",
      category: status, // This helps your notification UI pick the right icon/color
      actionId: userId,
    );
  }

  Color getStatusColor(String status) {
    switch (status) {
      case "approved": return AppColors.primaryGreen;
      case "restricted": return Colors.amber.shade700;
      case "blocked": return Colors.redAccent;
      default: return Colors.grey;
    }
  }

  Future<Map<String, dynamic>> getUserStats(String userId) async {
    final query = await FirebaseFirestore.instance
        .collection('orders')
        .where('userId', isEqualTo: userId)
        .get();
    double spent = query.docs.fold(0.0, (sum, doc) => sum + (doc['totalPrice'] ?? 0));
    return {"orders": query.docs.length, "spent": spent};
  }

  Map<String, dynamic> getUserBadge(double spent) {
    if (spent >= 300000) return {"title": "PREMIUM", "color": const Color(0xff6A1B9A), "icon": Icons.auto_awesome};
    if (spent >= 100000) return {"title": "DIAMOND", "color": const Color(0xff1565C0), "icon": Icons.diamond};
    if (spent >= 50000) return {"title": "SILVER", "color": const Color(0xff455A64), "icon": Icons.shield};
    return {"title": "NORMAL", "color": Colors.blueGrey.shade400, "icon": Icons.person_outline};
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xffF8FAFC), // Fresh light background

      body: NestedScrollView(
        headerSliverBuilder: (context, innerBoxIsScrolled) => [
          SliverAppBar(
            expandedHeight: 180,
            floating: true,
            pinned: true,
            stretch: true,
            elevation: 0,
            backgroundColor: Colors.white,
            systemOverlayStyle: SystemUiOverlayStyle.dark,
            flexibleSpace: FlexibleSpaceBar(
              centerTitle: false,
              // Reduced bottom padding to give the Column more breathing room
              titlePadding: const EdgeInsets.only(left: 20, bottom: 85),
              title: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Text(
                    "User Directory".toUpperCase(),
                    style: TextStyle(
                      fontWeight: FontWeight.w900,
                      fontSize: 16, // Slightly reduced to fit mobile screens better
                      letterSpacing: 1.2,
                      color: AppColors.primaryGreen.withOpacity(0.9),
                    ),
                  ),
                  // Wrapping in Flexible prevents the "Overflow by 14 pixels" error
                  Flexible(
                    child: Text(
                      "Admin Panel", // Shortened slightly for safety
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontWeight: FontWeight.w500,
                        fontSize: 9,
                        color: AppColors.primaryGreen.withOpacity(0.5),
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                ],
              ),
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      AppColors.primaryGreen.withOpacity(0.15),
                      AppColors.mintFrost.withOpacity(0.4),
                      AppColors.slate100,
                      Colors.white,
                    ],
                  ),
                ),
                child: Stack(
                  children: [
                    Positioned(
                      right: -30,
                      top: -30,
                      child: CircleAvatar(
                        radius: 100,
                        backgroundColor: AppColors.primaryGreen.withOpacity(0.05),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            bottom: PreferredSize(
              preferredSize: const Size.fromHeight(80),
              child: Container(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 15, offset: const Offset(0, 8))
                    ],
                  ),
                  child: TextField(
                    controller: _searchController,
                    onChanged: (v) => setState(() => searchQuery = v.toLowerCase()),
                    style: TextStyle(color: AppColors.primaryGreen, fontSize: 15),
                    decoration: InputDecoration(
                      hintText: "Search name, email, or ID...",
                      hintStyle: TextStyle(color: Colors.blueGrey.shade300),
                      prefixIcon: Icon(Icons.manage_search_rounded, color: AppColors.primaryGreen, size: 24),
                      filled: true,
                      fillColor: Colors.white,
                      contentPadding: const EdgeInsets.symmetric(vertical: 18),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide(color: Colors.grey.shade100),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide(color: AppColors.primaryGreen, width: 1.5),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          )
        ],
        body: StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance.collection('users').snapshots(),
          builder: (context, snapshot) {
            if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());

            final users = snapshot.data!.docs;
            final filtered = users.where((u) {
              final n = (u['name'] ?? '').toString().toLowerCase();
              final e = (u['email'] ?? '').toString().toLowerCase();
              return n.contains(searchQuery) || e.contains(searchQuery) || u.id.contains(searchQuery);
            }).toList();

            return ListView(
              padding: EdgeInsets.zero,
              children: [
                FutureBuilder<Map<String, dynamic>>(
                  future: getGlobalStats(),
                  builder: (context, gSnap) => _buildGlobalStats(
                    users.length,
                    gSnap.data?['revenue'] ?? 0,
                    gSnap.data?['orders'] ?? 0,
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Column(
                    children: filtered.map((u) => _buildUserCard(u)).toList(),
                  ),
                ),
                const SizedBox(height: 100),
              ],
            );
          },
        ),
      ),
    );
  }

  // --- UI Components ---

  Widget _buildGlobalStats(int totalUsers, double revenue, int orders) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(child: _buildMainStatCard("Revenue", "PKR ${revenue.toStringAsFixed(0)}", Icons.payments, AppColors.primaryGreen)),
              const SizedBox(width: 12),
              Expanded(child: _buildMainStatCard("Total Orders", "$orders", Icons.shopping_bag, Colors.blueGrey.shade800)),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.grey.shade100),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildSmallStat("TOTAL USERS", "$totalUsers"),
                Container(width: 1, height: 20, color: Colors.grey.shade200),
                _buildSmallStat("GROWTH", "+12%"),
                Container(width: 1, height: 20, color: Colors.grey.shade200),
                _buildSmallStat("ACTIVE", "88%"),
              ],
            ),
          )
        ],
      ),
    );
  }

  Widget _buildMainStatCard(String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: color.withOpacity(0.2), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: Colors.white.withOpacity(0.9), size: 20),
          const SizedBox(height: 12),
          Text(label, style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 11, fontWeight: FontWeight.w600)),
          Text(value, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
        ],
      ),
    );
  }

  Widget _buildSmallStat(String label, String value) {
    return Column(
      children: [
        Text(label, style: TextStyle(color: Colors.grey.shade500, fontSize: 9, fontWeight: FontWeight.bold, letterSpacing: 0.5)),
        const SizedBox(height: 4),
        Text(value, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 14, color: Color(0xff1E293B))),
      ],
    );
  }

  Widget _buildUserCard(DocumentSnapshot doc) {
    final status = doc['userStatus'] ?? 'approved';
    return FutureBuilder<Map<String, dynamic>>(
      future: getUserStats(doc.id),
      builder: (context, snap) {
        final spent = snap.data?['spent'] ?? 0.0;
        final orders = snap.data?['orders'] ?? 0;
        final badge = getUserBadge(spent);

        return Container(
          margin: const EdgeInsets.only(bottom: 16),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 12, offset: const Offset(0, 4))],
          ),
          child: Column(
            children: [
              Row(
                children: [
                  Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: AppColors.primaryGreen.withOpacity(0.1), width: 2),
                    ),
                    child: CircleAvatar(
                      radius: 24,
                      backgroundColor: AppColors.primaryGreen.withOpacity(0.05),
                      backgroundImage: doc['profileImage'] != null ? NetworkImage(doc['profileImage']) : null,
                      child: doc['profileImage'] == null ? Icon(Icons.person, color: AppColors.primaryGreen) : null,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(doc['name'] ?? 'User', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Color(0xff1E293B))),
                        Text(doc['email'] ?? '', style: TextStyle(color: Colors.grey.shade500, fontSize: 12)),
                      ],
                    ),
                  ),
                  _buildBadgeChip(badge),
                ],
              ),
              const Padding(padding: EdgeInsets.symmetric(vertical: 14), child: Divider(height: 1, thickness: 0.5)),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _buildUserStat("ORDERS", "$orders"),
                  _buildUserStat("SPENT", "PKR ${spent.toStringAsFixed(0)}"),
                  _buildStatusDropdown(doc.id, status),
                ],
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                height: 45,
                child: TextButton.icon(
                  onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => AdminUserOrdersScreen(userId: doc.id, userName: doc['name']))),
                  icon: const Icon(Icons.history_rounded, size: 18),
                  label: const Text("View Transactions", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                  style: TextButton.styleFrom(
                    backgroundColor: const Color(0xffF1F5F9),
                    foregroundColor: const Color(0xff475569),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              )
            ],
          ),
        );
      },
    );
  }

  Widget _buildUserStat(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: TextStyle(color: Colors.grey.shade400, fontSize: 9, fontWeight: FontWeight.w800)),
        Text(value, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 13, color: Color(0xff334155))),
      ],
    );
  }

  Widget _buildBadgeChip(Map<String, dynamic> badge) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: badge['color'].withOpacity(0.1),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(badge['icon'], size: 14, color: badge['color']),
          const SizedBox(width: 5),
          Text(badge['title'], style: TextStyle(color: badge['color'], fontSize: 10, fontWeight: FontWeight.w900)),
        ],
      ),
    );
  }

  Widget _buildStatusDropdown(String id, String status) {
    final color = getStatusColor(status);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withOpacity(0.1)),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: status,
          icon: Icon(Icons.keyboard_arrow_down_rounded, color: color, size: 16),
          style: TextStyle(color: color, fontWeight: FontWeight.w900, fontSize: 11),
          items: ["approved", "restricted", "blocked"]
              .map((s) => DropdownMenuItem(value: s, child: Text(s.toUpperCase())))
              .toList(),
          onChanged: (v) => v != null ? updateUserStatus(id, v) : null,
        ),
      ),
    );
  }
}