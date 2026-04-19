import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import 'AddCouponCode.dart';
import 'EditCouponCode.dart';

class CouponListScreen extends StatefulWidget {
  const CouponListScreen({super.key});

  @override
  State<CouponListScreen> createState() => _CouponListScreenState();
}

class _CouponListScreenState extends State<CouponListScreen> {
  @override
  Widget build(BuildContext context) {
    final String sellerId = FirebaseAuth.instance.currentUser?.uid ?? "";

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        title: const Text("My Coupons", style: TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
      ),
      body: StreamBuilder<QuerySnapshot>(
        // Only show coupons created by this specific seller
        stream: FirebaseFirestore.instance
            .collection('coupons')
            .where('sellerId', isEqualTo: sellerId)
            .orderBy('createdAt', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: Colors.green));
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return _buildEmptyState(context);
          }

          final coupons = snapshot.data!.docs;

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: coupons.length,
            itemBuilder: (context, index) {
              final data = coupons[index].data() as Map<String, dynamic>;
              final String docId = coupons[index].id;
              return _buildCouponCard(context, data, docId);
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.green[700],
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const AddCouponScreen()),
        ),
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.confirmation_number_outlined, size: 80, color: Colors.grey[300]),
          const SizedBox(height: 16),
          const Text(
            "No coupons added yet",
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.grey),
          ),
          const SizedBox(height: 8),
          const Text("Tap the + button to create your first discount"),
        ],
      ),
    );
  }

  Widget _buildCouponCard(BuildContext context, Map<String, dynamic> data, String docId) {
    final DateTime expiry = (data['expireDate'] as Timestamp).toDate();
    final bool isExpired = DateTime.now().isAfter(expiry);
    final bool useLimit = data['useLimit'] ?? false;
    final double limit = (data['limit'] as num).toDouble();

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10, offset: const Offset(0, 5))
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildStatusChip(isExpired, data['isEnabled'] ?? false),
              Switch(
                value: data['isEnabled'] ?? true,
                activeColor: Colors.green,
                onChanged: (bool value) async {
                  await FirebaseFirestore.instance
                      .collection('coupons')
                      .doc(docId)
                      .update({'isEnabled': value});
                },
              ),
            ],
          ),
          ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            title: Row(
              children: [
                Text(
                  data['couponCode'] ?? "CODE",
                  style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 18, letterSpacing: 1.2),
                ),
                const SizedBox(width: 10),
                _buildStatusChip(isExpired,data['isEnabled'] ?? false),
              ],
            ),
            subtitle: Padding(
              padding: const EdgeInsets.only(top: 8.0),
              child: Text(
                "${data['discount']}% OFF • Exp: ${DateFormat('dd MMM yyyy').format(expiry)}",
                style: TextStyle(color: Colors.grey[600]),
              ),
            ),
            // Update the trailing section inside _buildCouponCard
            trailing: Wrap(
              spacing: -8, // Tighten the space between icons
              children: [
                IconButton(
                  icon: const Icon(Icons.edit_outlined, color: Colors.blueAccent),
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => EditCouponScreen(data: data, docId: docId),
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
                  onPressed: () => _confirmDelete(context, docId),
                ),
              ],
            ),
          ),
          if (useLimit)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.green[50],
                borderRadius: const BorderRadius.vertical(bottom: Radius.circular(20)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.people_outline, size: 16, color: Colors.green),
                  const SizedBox(width: 8),
                  Text(
                    "Remaining uses: ${limit.toInt()}",
                    style: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold, fontSize: 12),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildStatusChip(bool isExpired, bool isEnabled) {
    String text = "ACTIVE";
    Color color = Colors.green;

    if (!isEnabled) {
      text = "DISABLED";
      color = Colors.grey;
    } else if (isExpired) {
      text = "EXPIRED";
      color = Colors.red;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        text,
        style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.bold),
      ),
    );
  }
  void _confirmDelete(BuildContext context, String docId) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Delete Coupon?"),
        content: const Text("This cannot be undone. Customers will no longer be able to use this code."),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel")),
          TextButton(
            onPressed: () async {
              await FirebaseFirestore.instance.collection('coupons').doc(docId).delete();
              Navigator.pop(context);
            },
            child: const Text("Delete", style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}