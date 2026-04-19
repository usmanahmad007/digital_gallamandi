import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../app_colors.dart';

class AdminCouponScreen extends StatefulWidget {
  const AdminCouponScreen({super.key});

  @override
  State<AdminCouponScreen> createState() => _AdminCouponScreenState();
}

class _AdminCouponScreenState extends State<AdminCouponScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // --- Logic: Delete Coupon (Admin Power to Moderate) ---
  Future<void> _deleteCoupon(String docId) async {
    try {
      await _firestore.collection('coupons').doc(docId).delete();
      _showSnackBar("Coupon removed by Admin", Colors.black87);
    } catch (e) {
      debugPrint("Error: $e");
    }
  }

  void _showSnackBar(String msg, Color bg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg, style: const TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: bg,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFBFBFD),
      appBar: AppBar(
        title: const Text("Monitor Coupons",
            style: TextStyle(color: Colors.black, fontWeight: FontWeight.w800)),
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 0,
        // Creation action removed here
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: _firestore.collection('coupons').orderBy('createdAt', descending: true).snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: AppColors.primaryGreen));
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return _buildEmptyState();
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: snapshot.data!.docs.length,
            itemBuilder: (context, index) {
              var doc = snapshot.data!.docs[index];
              var data = doc.data() as Map<String, dynamic>;

              return _buildCouponCard(doc.id, data);
            },
          );
        },
      ),
      // FloatingActionButton REMOVED: Admin cannot create coupons.
    );
  }

  Widget _buildCouponCard(String id, Map<String, dynamic> data) {
    final String code = data['couponCode'] ?? "N/A";
    final String title = data['title'] ?? "No Title";
    final double discount = (data['discount'] ?? 0).toDouble();
    final Timestamp? expireTs = data['expireDate'] as Timestamp?;
    final bool isEnabled = data['isEnabled'] ?? false;
    final String storeName = data['storeName'] ?? "Unknown Store";

    bool isExpired = expireTs != null && expireTs.toDate().isBefore(DateTime.now());
    String formattedExpiry = expireTs != null ? DateFormat('dd MMM, yyyy').format(expireTs.toDate()) : "No Expiry";

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey.shade100),
      ),
      child: Column(
        children: [
          ListTile(
            contentPadding: const EdgeInsets.all(16),
            leading: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: (isEnabled && !isExpired) ? Colors.green.withOpacity(0.1) : Colors.red.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                  Icons.local_offer_outlined,
                  color: (isEnabled && !isExpired) ? Colors.green : Colors.red
              ),
            ),
            title: Text(code, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 18, letterSpacing: 1.2)),
            subtitle: Text("Store: $storeName", style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.primaryGreen)),
            trailing: Text("$discount%", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 22, color: Colors.black87)),
          ),
          const Divider(height: 0),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text("Ends: $formattedExpiry",
                    style: TextStyle(fontSize: 12, color: isExpired ? Colors.red : Colors.grey)),
                IconButton(
                  icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
                  onPressed: () => _confirmDelete(id),
                )
              ],
            ),
          )
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.no_accounts_outlined, size: 80, color: Colors.grey[300]),
          const SizedBox(height: 16),
          const Text("No seller coupons to moderate", style: TextStyle(color: Colors.grey)),
        ],
      ),
    );
  }

  void _confirmDelete(String id) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Remove Coupon?"),
        content: const Text("As an admin, you are removing this seller's coupon from the platform."),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel")),
          TextButton(
            onPressed: () { Navigator.pop(context); _deleteCoupon(id); },
            child: const Text("Delete", style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }
}