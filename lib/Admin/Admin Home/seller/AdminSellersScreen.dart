import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../../../Notification/send_notification.dart';
import '../../../app_colors.dart';
import '../StoreView/AdminStoreViewScreen.dart';

class AdminSellersScreen extends StatefulWidget {
  const AdminSellersScreen({super.key});

  @override
  State<AdminSellersScreen> createState() => _AdminSellersScreenState();
}

class _AdminSellersScreenState extends State<AdminSellersScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;



  // --- Logic: Update Seller Status ---
  Future<void> _updateSellerStatus(
      String sellerId,
      Map<String, dynamic> data,
      String storeName,
      String title,
      String body,
      String type,
      String category) async {
    try {
      await _firestore.collection('saller').doc(sellerId).update(data);

      await sendStoreUpdateNotification(
        sellerId: sellerId,
        newStatus: category,
        storeName:storeName,
        title: title
      );
      _showSnackBar("Seller status updated", AppColors.primaryGreen);
    } catch (e) {
      _showSnackBar("Error: $e", Colors.red);
    }
  }
  Future<void> sendStoreUpdateNotification({
    required String sellerId,
    required String newStatus, // approved | restricted | pending | active
    required String storeName,
    required String title,
  }) async {

    String message = "Your store $storeName status has been updated to ${newStatus.toUpperCase()}.";

    if (newStatus == "approved" || newStatus == "active") {
      message =
      "Great news! The store $storeName is now ${newStatus.toUpperCase()} and customers can start viewing your products.";
    }
    else if (newStatus == "restricted") {
      message =
      "Store $storeName has been RESTRICTED due to policy issues. Please review your store details.";
    }
    else if (newStatus == "pending") {
      message =
      "Store $storeName is currently under review. We will notify you once it is approved.";
    }

    await sendNotification(
      senderRole: "admin", // store updates normally come from admin
      senderId: "admin",   // you can also use actual admin UID

      sellerId: sellerId,  // target seller
      userId: null,

      title: title,
      body: message,

      type: "store",
      category: newStatus, // used in UI for icon & color
      actionId: sellerId,  // optional (storeId if you have one)
    );
  }

  // --- Logic: Delete Seller and their Products ---
  Future<void> _deleteSeller(String sellerId) async {
    try {
      WriteBatch batch = _firestore.batch();
      batch.delete(_firestore.collection('saller').doc(sellerId));

      QuerySnapshot products = await _firestore
          .collection('products')
          .where('sellerId', isEqualTo: sellerId)
          .get();

      for (var doc in products.docs) {
        batch.delete(doc.reference);
      }

      await batch.commit();
      _showSnackBar("Seller and inventory deleted.", Colors.redAccent);
    } catch (e) {
      _showSnackBar("Delete failed", Colors.black);
    }
  }

  void _showSnackBar(String msg, Color bg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
          content: Text(msg),
          backgroundColor: bg,
          behavior: SnackBarBehavior.floating),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        title: const Text("Sellers Verification",
            style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 0.5,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: _firestore.collection('saller').snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
                child:
                    CircularProgressIndicator(color: AppColors.primaryGreen));
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text("No sellers found."));
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: snapshot.data!.docs.length,
            itemBuilder: (context, index) {
              final doc = snapshot.data!.docs[index];
              final data = doc.data() as Map<String, dynamic>;

              // 1. Get store name safely (Local variable)
              // Checks for: null, missing key, or empty string ""

              // 2. Boolean flags with default fallbacks
              final bool hasSetup = data['hasSetupStore'] ?? false;
              final bool isAdminApproved = data['isAdminApproved'] ?? false;
              final bool isRestricted = data['isSellerRestricted'] ?? false;

              // Pass the name directly into your card or data map
              return _buildSellerCard(
                doc.id,
                data,
                hasSetup,
                isAdminApproved,
                isRestricted,
                // Pass it explicitly if your widget accepts it
              );
            },
          );
        },
      ),
    );
  }

// ... existing imports

  Widget _buildSellerCard(String id, Map<String, dynamic> data, bool hasSetup,
      bool isApproved, bool isRestricted) {
    // 🔥 Get the storeStatus from data
    String storeStatus = (data['storeStatus'] ?? "").toString().toLowerCase();

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10)
        ],
      ),
      child: Column(
        children: [
          ListTile(
            onTap: () {
              Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) =>
                          AdminStoreReviewScreen(sellerId: id)));
            },
            contentPadding: const EdgeInsets.all(16),
            leading: CircleAvatar(
              radius: 30,
              backgroundColor: Colors.green[50],
              backgroundImage: NetworkImage(data['storeLogo'] ?? ""),
            ),
            title: Text(data['storeName'] ?? "Unnamed Store",
                style: const TextStyle(fontWeight: FontWeight.bold)),
            subtitle: Text(
                "Owner: ${data['name']}\nStatus: ${storeStatus.toUpperCase()}"),
            trailing: _buildStatusBadge(
                hasSetup, isApproved, isRestricted, storeStatus),
          ),
          const Divider(height: 0),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
            child: Row(
              children: [
                // CASE 1: Pending Updates (User modified info and is waiting)
                if (storeStatus == "pending")
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => _updateSellerStatus(
                          id,
                          {
                            'isAdminApproved': true,
                            'storeStatus': 'editable', // Unlock for user
                          },
                          data['storeName'],
                          "Updates Approved! ✅",
                          "Your recent changes to '${data['storeName']}' have been approved and are now visible to customers!",
                          "store",
                          "approved"),
                      icon: const Icon(Icons.check_circle_outline,
                          color: Colors.white),
                      label: const Text("Approve Updates",
                          style: TextStyle(color: Colors.white)),
                      style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green, elevation: 0),
                    ),
                  ),

                // CASE 2: New Store Request (Setup done, but not approved yet)
                if (hasSetup && !isApproved && storeStatus != "pending")
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => _updateSellerStatus(
                          id,
                          {
                            'isAdminApproved': true,
                            'storeStatus':
                                'editable', // Set to editable initially
                          },
                          data['storeName'],
                          "Store Approved! 🎉",
                          "Congratulations! Your store '${data['storeName']}' is now live. You can now add your products, start selling to thousands of customers, and grow your earnings today!",
                          "store",
                          "approved"),
                      icon:
                          const Icon(Icons.verified_user, color: Colors.white),
                      label: const Text("Approve Store",
                          style: TextStyle(color: Colors.white)),
                      style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue, elevation: 0),
                    ),
                  ),

                // CASE 3: Already Approved (Show Manage Options)
                if (isApproved && storeStatus != "pending") ...[
                  Expanded(
                    child: TextButton.icon(
                      onPressed: () {
                        // Define strings based on the NEXT state
                        // If currently restricted, we are about to APPROVE.
                        // If not restricted, we are about to RESTRICT.
                        final String newTitle = isRestricted ? "Store Approved! 🎉" : "Store Restricted ⚠️";

                        final String newBody = isRestricted
                            ? "Congratulations! Your store '${data['storeName']}' is now live. You can now add products and start selling today!"
                            : "Your store '${data['storeName']}' has been restricted. You cannot earn money or sell products until this is resolved.";

                        final String newCategory = "store";
                        final String newStatus = isRestricted ? "approved" : "restricted";

                        _updateSellerStatus(
                          id,
                          {
                            'isSellerRestricted': !isRestricted,
                            'category': newStatus, // Syncing category string with the bool
                          },
                          data['storeName'],
                          newTitle,
                          newBody,
                          newCategory,
                          newStatus,
                        );
                      },
                      icon: Icon(
                        isRestricted ? Icons.lock_open : Icons.block,
                        color: isRestricted ? Colors.green : Colors.orange,
                      ),
                      label: Text(
                        isRestricted ? "Unrestrict" : "Restrict",
                        style: TextStyle(
                          color: isRestricted ? Colors.green : Colors.orange,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextButton.icon(
                      onPressed: () => _confirmDelete(id),
                      icon: const Icon(Icons.delete_sweep,
                          color: Colors.redAccent),
                      label: const Text("Delete",
                          style: TextStyle(color: Colors.redAccent)),
                    ),
                  ),
                ],

                // CASE 4: Hasn't setup store yet
                if (!hasSetup)
                  const Expanded(
                    child: Padding(
                      padding: EdgeInsets.all(8.0),
                      child: Text("Incomplete Setup",
                          style: TextStyle(
                              color: Colors.grey,
                              fontSize: 12,
                              fontStyle: FontStyle.italic)),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // 🔥 Updated badge to show "Update Requested" if pending
  Widget _buildStatusBadge(
      bool hasSetup, bool isApproved, bool isRestricted, String status) {
    String text = "Pending";
    Color color = Colors.grey;

    if (isRestricted) {
      text = "Restricted";
      color = Colors.red;
    } else if (status == "pending") {
      text = "Review Needed";
      color = Colors.orange;
    } else if (isApproved) {
      text = "Approved";
      color = Colors.green;
    } else if (hasSetup) {
      text = "New Request";
      color = Colors.blue;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        text,
        style:
            TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.bold),
      ),
    );
  }

  void _confirmDelete(String sellerId) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Delete Everything?"),
        content: const Text(
            "This will delete the seller profile and all their products. This action is permanent."),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Cancel")),
          TextButton(
              onPressed: () {
                Navigator.pop(context);
                _deleteSeller(sellerId);
              },
              child: const Text("Confirm Delete",
                  style: TextStyle(color: Colors.red))),
        ],
      ),
    );
  }
}
