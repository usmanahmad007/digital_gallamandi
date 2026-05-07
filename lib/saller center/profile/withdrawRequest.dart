import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../Notification/send_notification.dart'; // For currency formatting

class WithdrawScreen extends StatefulWidget {
  final String sellerId;
  const WithdrawScreen({super.key, required this.sellerId});

  @override
  State<WithdrawScreen> createState() => _WithdrawScreenState();
}

class _WithdrawScreenState extends State<WithdrawScreen> {
  double balance = 0;
  double pendingWithdrawal = 0;
  double onHold = 0;
  double totalEarnings = 0;
  double totalWithdrawn = 0;

  final TextEditingController amountController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    getWalletData();
  }

  Future<void> getWalletData() async {
    final doc = await FirebaseFirestore.instance
        .collection('saller')
        .doc(widget.sellerId)
        .get();

    if (doc.exists) {
      setState(() {
        balance = (doc['balance'] ?? 0).toDouble();
        pendingWithdrawal = (doc['pendingWithdrawal'] ?? 0).toDouble();
        onHold = (doc['onHold'] ?? 0).toDouble();
        totalEarnings = (doc['totalEarnings'] ?? 0).toDouble();
        totalWithdrawn = (doc['totalWithdrawn'] ?? 0).toDouble();
      });
    }
  }

  // --- UI Components ---

  Widget _buildStatTile(String label, double value, IconData icon, Color color) {
    return Column(
      children: [
        CircleAvatar(
          backgroundColor: color.withOpacity(0.1),
          child: Icon(icon, color: color, size: 20),
        ),
        const SizedBox(height: 8),
        Text(label, style: TextStyle(color: Colors.grey[600], fontSize: 12)),
        Text(
          "Rs ${value.toStringAsFixed(0)}",
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
        ),
      ],
    );
  }

  void _showConfirmationSheet() {
    double amount = double.tryParse(amountController.text) ?? 0;
    if (amount < 1000 || amount > balance) return;

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) => Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.security, size: 40, color: Colors.green),
            const SizedBox(height: 16),
            const Text("Confirm Withdrawal",
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text("You are requesting to withdraw Rs $amount to your registered account."),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green[700],
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: () {
                  Navigator.pop(context);
                  requestWithdraw();
                },
                child: const Text("Confirm & Request", style: TextStyle(color: Colors.white)),
              ),
            ),
            TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text("Cancel"))
          ],
        ),
      ),
    );
  }

  // --- Logic ---

  Future<void> requestWithdraw() async {
    double amount = double.tryParse(amountController.text) ?? 0;
    final firestore = FirebaseFirestore.instance;

    try {
      // 1. Define a variable to hold the new request ID for the notification
      String newRequestId = "";

      await firestore.runTransaction((transaction) async {
        final userRef = firestore.collection('saller').doc(widget.sellerId);
        final snapshot = await transaction.get(userRef);

        double currentBalance = (snapshot['balance'] ?? 0).toDouble();
        double currentPending = (snapshot['pendingWithdrawal'] ?? 0).toDouble();

        if (amount > currentBalance) throw Exception("Insufficient balance");

        final withdrawRef = firestore.collection('withdrawRequests').doc();
        newRequestId = withdrawRef.id; // Capture the ID for actionId

        transaction.set(withdrawRef, {
          'sellerId': widget.sellerId,
          'amount': amount,
          'status': 'pending',
          'createdAt': FieldValue.serverTimestamp(),
        });

        transaction.update(userRef, {
          'balance': currentBalance - amount,
          'pendingWithdrawal': currentPending + amount,
        });
      });

      // 2. 🔥 Trigger Notification for Admin
      // Using 'payment' or 'order' type so it gets the right icon in your AdminNotificationScreen
      await sendAdminNotification(
        senderRole: "seller",
        senderId: widget.sellerId,
        sellerId: widget.sellerId,
        title: "New Withdrawal Request",
        body: "A seller has requested a withdrawal of PKR ${amount.toStringAsFixed(2)}",
        type: "payment",      // Matches your 'payment' case in the icon builder
        category: "withdrawal",
        actionId: newRequestId, // Direct link to the specific request
      );

      amountController.clear();
      getWalletData();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Request sent successfully!"), backgroundColor: Colors.green),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error: ${e.toString()}"), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text("My Earnings", style: TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.black,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // --- Main Balance Card ---
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  gradient: LinearGradient(colors: [Colors.green[700]!, Colors.green[400]!]),
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [BoxShadow(color: Colors.green.withOpacity(0.3), blurRadius: 10, offset: const Offset(0, 5))],
                ),
                child: Column(
                  children: [
                    const Text("Available Balance", style: TextStyle(color: Colors.white70, fontSize: 16)),
                    const SizedBox(height: 8),
                    Text("Rs ${balance.toStringAsFixed(2)}",
                        style: const TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.bold)),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // --- Statistics Row ---
              Card(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 10),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildStatTile("Pending", pendingWithdrawal, Icons.history, Colors.orange),
                      _buildStatTile("On Hold", onHold, Icons.lock_clock, Colors.blue),
                      _buildStatTile("Withdrawn", totalWithdrawn, Icons.account_balance_wallet, Colors.red),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 24),

              // --- Withdraw Input Section ---
              const Text("Request Withdrawal", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              Form(
                key: _formKey,
                child: TextFormField(
                  controller: amountController,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    prefixIcon: const Icon(Icons.account_balance_wallet_outlined),
                    hintText: "Min 1,000 PKR",
                    filled: true,
                    fillColor: Colors.white,
                    suffixIcon: TextButton(
                      onPressed: () => amountController.text = balance.toString(),
                      child: const Text("MAX"),
                    ),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                height: 55,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.black87,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: _showConfirmationSheet,
                  child: const Text("Withdraw Funds", style: TextStyle(fontSize: 16, color: Colors.white)),
                ),
              ),

              const SizedBox(height: 30),

              // --- History Section ---
              const Text("Transaction History", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 10),
              StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('withdrawRequests')
                    .where('sellerId', isEqualTo: widget.sellerId)
                    .orderBy('createdAt', descending: true)
                    .snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
                  if (!snapshot.hasData || snapshot.data!.docs.isEmpty) return const Center(child: Text("No transactions yet"));

                  return ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: snapshot.data!.docs.length,
                    itemBuilder: (context, index) {
                      var item = snapshot.data!.docs[index];
                      String status = item['status'];
                      return Card(
                        margin: const EdgeInsets.only(bottom: 8),
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor: _getStatusColor(status).withOpacity(0.1),
                            child: Icon(_getStatusIcon(status), color: _getStatusColor(status), size: 20),
                          ),
                          title: Text("Rs ${item['amount']}", style: const TextStyle(fontWeight: FontWeight.bold)),
                          subtitle: Text(status.toUpperCase(), style: TextStyle(color: _getStatusColor(status), fontSize: 12, fontWeight: FontWeight.w600)),
                          trailing: const Icon(Icons.chevron_right, size: 16),
                        ),
                      );
                    },
                  );
                },
              )
            ],
          ),
        ),
      ),
    );
  }

  Color _getStatusColor(String status) {
    if (status == 'approved') return Colors.green;
    if (status == 'rejected') return Colors.red;
    return Colors.orange;
  }

  IconData _getStatusIcon(String status) {
    if (status == 'approved') return Icons.check;
    if (status == 'rejected') return Icons.close;
    return Icons.pending_outlined;
  }
}