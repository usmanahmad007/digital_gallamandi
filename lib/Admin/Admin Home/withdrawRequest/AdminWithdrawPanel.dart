import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:zrai_mart/Admin/Admin%20Home/withdrawRequest/sellerWithDetailScreen.dart';

import '../../../Notification/send_notification.dart';

class AdminWithdrawPanel extends StatefulWidget {
  const AdminWithdrawPanel({super.key});

  @override
  State<AdminWithdrawPanel> createState() => _AdminWithdrawPanelState();
}

class _AdminWithdrawPanelState extends State<AdminWithdrawPanel>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  // --- Logic Layer ---

  Future<void> updateWithdrawStatus({
    required String requestId,
    required String sellerId,
    required double amount,
    required String status,
  }) async {
    final firestore = FirebaseFirestore.instance;

    await firestore.runTransaction((transaction) async {
      final requestRef =
          firestore.collection('withdrawRequests').doc(requestId);
      final sellerRef = firestore.collection('saller').doc(sellerId);

      final requestSnap = await transaction.get(requestRef);
      final sellerSnap = await transaction.get(sellerRef);

      if (!requestSnap.exists || !sellerSnap.exists) throw "Data mismatch";
      if (requestSnap['status'] != 'pending') throw "Already processed";

      double pending = (sellerSnap['pendingWithdrawal'] ?? 0).toDouble();
      double withdrawn = (sellerSnap['totalWithdrawn'] ?? 0).toDouble();
      double balance = (sellerSnap['balance'] ?? 0).toDouble();

      if (status == 'approved') {
        transaction.update(requestRef, {
          'status': 'approved',
          'processedAt': FieldValue.serverTimestamp(),
        });
        transaction.update(sellerRef, {
          'pendingWithdrawal': pending - amount,
          'totalWithdrawn': withdrawn + amount,
        });
      } else {
        transaction.update(requestRef, {
          'status': 'rejected',
          'processedAt': FieldValue.serverTimestamp(),
        });
        transaction.update(sellerRef, {
          'pendingWithdrawal': pending - amount,
          'balance': balance + amount,
        });
      }
      await sendNotification(
        senderRole: "admin",
        senderId: "admin", // The sender is the admin
        sellerId: sellerId,
        title: status == 'approved'
            ? "Withdrawal Approved ✅"
            : "Withdrawal Request Declined ❌",
        body: status == 'approved'
            ? "Great news! Your withdrawal of PKR ${amount.toStringAsFixed(2)} has been successfully processed and transferred."
            : "Your withdrawal request for PKR ${amount.toStringAsFixed(2)} could not be processed at this time. Please check your email for details.",
        type: "payment",
        category: "withdrawal",
        actionId: requestId,
      );
    });
  }

  // --- UI Components ---

  Widget _buildStatusChip(String status) {
    Color color = Colors.orange;
    if (status == 'approved') color = Colors.green;
    if (status == 'rejected') color = Colors.red;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color),
      ),
      child: Text(
        status.toUpperCase(),
        style:
            TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.bold),
      ),
    );
  }

  Widget buildRequestItem(DocumentSnapshot item) {
    String sellerId = item['sellerId'] ?? item['sellerId']; // Handle both keys
    double amount = (item['amount'] ?? 0).toDouble();
    String status = item['status'];
    Timestamp? time = item['createdAt'] as Timestamp?;

    return FutureBuilder<DocumentSnapshot>(
      future:
          FirebaseFirestore.instance.collection('saller').doc(sellerId).get(),
      builder: (context, sellerSnap) {
        // Fetching seller name and financial health
        String sellerName =
            sellerSnap.data?.get('storeName') ?? "Unknown Seller";
        double totalEarned =
            (sellerSnap.data?.get('totalEarnings') ?? 0).toDouble();

        return GestureDetector(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => SellerWithdrawDetailScreen(
                  sellerId: sellerId,
                  requestId: item.id,
                  amount: amount,
                  status: status,
                ),
              ),
            );
          },
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)
              ],
            ),
            child: Column(
              children: [
                ListTile(
                  contentPadding: const EdgeInsets.all(16),
                  title: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text("Rs ${amount.toStringAsFixed(0)}",
                          style: const TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              color: Colors.green)),
                      _buildStatusChip(status),
                    ],
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 8),
                      Text("Seller: $sellerName",
                          style: const TextStyle(
                              fontWeight: FontWeight.w600,
                              color: Colors.black87)),
                      Text("ID: $sellerId",
                          style: const TextStyle(
                              fontSize: 11, color: Colors.grey)),
                      if (time != null)
                        Text(
                            DateFormat('dd MMM yyyy, hh:mm a')
                                .format(time.toDate()),
                            style: const TextStyle(fontSize: 11)),
                      const Divider(height: 24),
                      // Financial Health Row
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          _miniStat("Total Earned", "Rs $totalEarned"),
                          _miniStat("Request ID", item.id.substring(0, 8)),
                        ],
                      ),
                    ],
                  ),
                ),
                if (status == 'pending')
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                    child: Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            style: OutlinedButton.styleFrom(
                                foregroundColor: Colors.red,
                                side: const BorderSide(color: Colors.red)),
                            onPressed: () {

                              updateWithdrawStatus(
                                  requestId: item.id,
                                  sellerId: sellerId,
                                  amount: amount,
                                  status: 'rejected');
                            },
                            icon: const Icon(Icons.close, size: 18),
                            label: const Text("Reject"),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.green,
                                foregroundColor: Colors.white),
                            onPressed: () => updateWithdrawStatus(
                                requestId: item.id,
                                sellerId: sellerId,
                                amount: amount,
                                status: 'approved'),
                            icon: const Icon(Icons.check, size: 18),
                            label: const Text("Approve"),
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _miniStat(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 10, color: Colors.grey)),
        Text(value,
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        title: const Text("Finance Control",
            style: TextStyle(fontWeight: FontWeight.bold)),
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.green,
          labelColor: Colors.green,
          unselectedLabelColor: Colors.grey,
          tabs: const [
            Tab(text: "PENDING"),
            Tab(text: "ALL HISTORY"),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildListStream(FirebaseFirestore.instance
              .collection('withdrawRequests')
              .where('status', isEqualTo: 'pending')
              .orderBy('createdAt', descending: true)),
          _buildListStream(FirebaseFirestore.instance
              .collection('withdrawRequests')
              .orderBy('createdAt', descending: true)),
        ],
      ),
    );
  }

  Widget _buildListStream(Query query) {
    return StreamBuilder<QuerySnapshot>(
      stream: query.snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError)
          return Center(child: Text("Error: ${snapshot.error}"));
        if (!snapshot.hasData)
          return const Center(child: CircularProgressIndicator());
        final data = snapshot.data!.docs;
        if (data.isEmpty) return const Center(child: Text("No records found"));

        return ListView.builder(
          itemCount: data.length,
          itemBuilder: (context, index) => buildRequestItem(data[index]),
        );
      },
    );
  }
}
