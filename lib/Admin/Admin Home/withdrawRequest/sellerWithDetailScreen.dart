import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class SellerWithdrawDetailScreen extends StatelessWidget {
  final String sellerId;
  final String requestId;
  final double amount;
  final String status;

  const SellerWithdrawDetailScreen({
    super.key,
    required this.sellerId,
    required this.requestId,
    required this.amount,
    required this.status,
  });

  Future<void> updateStatus(BuildContext context, String newStatus) async {
    final firestore = FirebaseFirestore.instance;

    await firestore.runTransaction((transaction) async {
      final requestRef =
      firestore.collection('withdrawRequests').doc(requestId);
      final sellerRef =
      firestore.collection('saller').doc(sellerId);

      final requestSnap = await transaction.get(requestRef);
      final sellerSnap = await transaction.get(sellerRef);

      if (!requestSnap.exists || !sellerSnap.exists) {
        throw Exception("Data not found");
      }

      if (requestSnap['status'] != 'pending') {
        throw Exception("Already processed");
      }

      double pending =
      (sellerSnap['pendingWithdrawal'] ?? 0).toDouble();
      double balance = (sellerSnap['balance'] ?? 0).toDouble();
      double withdrawn =
      (sellerSnap['totalWithdrawn'] ?? 0).toDouble();

      if (newStatus == 'approved') {
        transaction.update(requestRef, {
          'status': 'approved',
          'processedAt': Timestamp.now(),
        });

        transaction.update(sellerRef, {
          'pendingWithdrawal': pending - amount,
          'totalWithdrawn': withdrawn + amount,
        });
      } else {
        transaction.update(requestRef, {
          'status': 'rejected',
          'processedAt': Timestamp.now(),
        });

        transaction.update(sellerRef, {
          'pendingWithdrawal': pending - amount,
          'balance': balance + amount,
        });
      }
    });

    Navigator.pop(context);
  }

  Widget infoTile(String title, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(title,
              style: const TextStyle(color: Colors.grey, fontSize: 12)),
          Text(value,
              style: const TextStyle(fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Seller Detail")),
      body: FutureBuilder<DocumentSnapshot>(
        future: FirebaseFirestore.instance
            .collection('saller')
            .doc(sellerId)
            .get(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final data = snapshot.data!;

          return Padding(
            padding: const EdgeInsets.all(16),
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 🔥 STORE HEADER
                  Center(
                    child: Column(
                      children: [
                        CircleAvatar(
                          radius: 40,
                          backgroundImage:
                          NetworkImage(data['storeLogo'] ?? ''),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          data['storeName'] ?? '',
                          style: const TextStyle(
                              fontSize: 20, fontWeight: FontWeight.bold),
                        ),
                        Text(data['name'] ?? ''),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),

                  // 🔥 WALLET INFO
                  const Text("Wallet",
                      style:
                      TextStyle(fontWeight: FontWeight.bold)),
                  const Divider(),

                  infoTile("Balance",
                      "Rs ${data['balance'] ?? 0}"),
                  infoTile("Pending",
                      "Rs ${data['pendingWithdrawal'] ?? 0}"),
                  infoTile("On Hold",
                      "Rs ${data['onHold'] ?? 0}"),
                  infoTile("Total Earned",
                      "Rs ${data['totalEarnings'] ?? 0}"),
                  infoTile("Total Withdrawn",
                      "Rs ${data['totalWithdrawn'] ?? 0}"),

                  const SizedBox(height: 20),

                  // 🔥 STORE INFO
                  const Text("Store Info",
                      style:
                      TextStyle(fontWeight: FontWeight.bold)),
                  const Divider(),

                  infoTile("Email", data['email'] ?? ''),
                  infoTile("Address", data['address'] ?? ''),
                  infoTile("Status", data['storeStatus'] ?? ''),

                  const SizedBox(height: 30),

                  // 🔥 REQUEST INFO
                  const Text("Withdraw Request",
                      style:
                      TextStyle(fontWeight: FontWeight.bold)),
                  const Divider(),

                  infoTile("Amount", "Rs $amount"),
                  infoTile("Status", status),

                  const SizedBox(height: 30),

                  // 🔥 ACTION BUTTONS
                  if (status == 'pending')
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () =>
                                updateStatus(context, 'rejected'),
                            child: const Text("Reject"),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: () =>
                                updateStatus(context, 'approved'),
                            child: const Text("Approve"),
                          ),
                        ),
                      ],
                    ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}