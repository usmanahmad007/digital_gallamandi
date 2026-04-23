import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../Notification/send_notification.dart';
import 'ProductDetailsScreen.dart';

class SellerOrderScreen extends StatefulWidget {
  const SellerOrderScreen({super.key});

  @override
  State<SellerOrderScreen> createState() => _SellerOrderScreenState();
}

class _SellerOrderScreenState extends State<SellerOrderScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final List<String> _reasons = [
    // --- Inventory & Pricing ---
    'Product out of stock',
    'Stock mismatch / Inventory error',
    'Pricing or listing error',
    'Product discontinued',

    // --- Shipping & Logistics ---
    'Unable to ship to customer location',
    'Delivery partner unavailable',
    'Logistics / Courier delay',
    'Shipping address unreachable',
    'Package damaged during transit',

    // --- Quality & Condition ---
    'Defective or damaged product',
    'Wrong item sent to customer',
    'Product quality not as described',
    'Expired or near-expiry product',

    // --- Customer / External ---
    'Customer requested cancellation',
    'Customer requested return',
    'Customer unreachable for verification',
    'Duplicate order placed by customer',

    // --- Other ---
    'Technical system error',
    'Fraudulent order suspected',
    'Other (Specify in notes)',
  ];
  String? _selectedReason;

  // --- LOGIC & FIREBASE FUNCTIONS ---

  void _showLoader() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: CircularProgressIndicator(color: Colors.green),
      ),
    );
  }

  Future<bool> _uploadAndSaveReceipt(String orderId) async {
    try {
      final picker = ImagePicker();
      final pickedFile = await picker.pickImage(source: ImageSource.gallery);
      if (pickedFile == null) return false;

      _showLoader();
      File file = File(pickedFile.path);
      String fileName = "receipt_${DateTime.now().millisecondsSinceEpoch}.jpg";
      Reference storageRef = FirebaseStorage.instance.ref().child("receipts/$fileName");

      UploadTask uploadTask = storageRef.putFile(file);
      TaskSnapshot snapshot = await uploadTask;
      String downloadUrl = await snapshot.ref.getDownloadURL();

      await FirebaseFirestore.instance
          .collection('orders')
          .doc(orderId)
          .update({'receiptImage': downloadUrl});

      Navigator.pop(context);
      return true;
    } catch (e) {
      if (Navigator.canPop(context)) Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Upload failed. Please check your connection.')),
      );
      return false;
    }
  }


  Future<void> _updateOrderStatus(String orderId, String newStatus, String reason) async {
    try {
      await FirebaseFirestore.instance
          .collection('orders')
          .doc(orderId)
          .update({'status': newStatus, 'reason': reason});

      // Fetch order details to notify the customer
      final orderDoc = await FirebaseFirestore.instance.collection('orders').doc(orderId).get();

      if (orderDoc.exists) {
        final data = orderDoc.data() as Map<String, dynamic>;
        String customerId = data['userId']; // Ensure this matches your field name in 'orders'
        String productTitle = data['title'];
        String productId = data['productId']; // Needed for notification navigation

        // Build notification message
        String message =
            "Order Update: The order for '$productTitle' is now ${newStatus.toUpperCase()}.";

        if ((newStatus == 'cancelled' || newStatus == 'returned') &&
            reason != 'none') {
          message += " Reason: $reason.";
        }

        // Using the updated notification function
        await sendNotification(
          userId: customerId, // Specifically targeting the customer
          senderId: FirebaseAuth.instance.currentUser!.uid,
          senderRole: 'seller',
          sellerId: FirebaseAuth.instance.currentUser!.uid,
          title: "Order Update: ${newStatus.toUpperCase()}",
          body: message,
          type: 'order',
          actionId: orderId,
          category: newStatus,
        );
      }



      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Order status updated to $newStatus.')),
        );
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to update status.')),
        );
      }
    }
  }

  Future<void> updateSellerBalance(String productId, int soldQuantity) async {
    try {
      final firestore = FirebaseFirestore.instance;
      final productSnapshot = await firestore.collection('products').doc(productId).get();
      if (productSnapshot.exists) {
        final String sellerId = productSnapshot['sellerId'];
        final double pricePerUnit = double.parse(productSnapshot['price']);
        final double revenue = pricePerUnit * soldQuantity;

        final sellerRef = firestore.collection('saller').doc(sellerId);
        final sellerSnapshot = await sellerRef.get();
        if (sellerSnapshot.exists) {
          final double currentBalance = double.parse(sellerSnapshot['balance'].toString());
          await sellerRef.update({'balance': currentBalance + revenue});
        }
      }
    } catch (e) {
      debugPrint('Balance Error: $e');
    }
  }

  // Updated to handle both Shipped and Completion
  Future<void> handleOrderProgression(String productId, int soldQuantity, String orderId, String targetStatus) async {
    try {
      final productRef = FirebaseFirestore.instance.collection('products').doc(productId);
      DocumentSnapshot productSnapshot = await productRef.get();

      if (productSnapshot.exists) {
        if (targetStatus == 'shipped') {
          int currentQuantity = int.parse(productSnapshot['quantity']);
          if (currentQuantity < soldQuantity) {
            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Insufficient stock!')));
            return;
          }
          await updateSellerBalance(productId, soldQuantity);
          await productRef.update({'quantity': (currentQuantity - soldQuantity).toString()});
        }
        await _updateOrderStatus(orderId, targetStatus, 'none');
      }
    } catch (e) {
      debugPrint('Progression Error: $e');
    }
  }

  // --- DIALOGS ---

  void _showStatusUpdateDialog(String orderId, String currentStatus, String productId, int quantity, String receiptImage) {
    String newStatus = '';
    if (currentStatus == 'pending') newStatus = 'in process';
    else if (currentStatus == 'in process') newStatus = 'shipped';
    else if (currentStatus == 'shipped') newStatus = 'completed';

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Update Status'),
        content: Text('Mark this order as $newStatus?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('No', style: TextStyle(color: Colors.grey))),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
            onPressed: () async {
              Navigator.pop(context);
              if (newStatus == 'shipped' && receiptImage == "pending") {
                _showUploadRequirementDialog(orderId, productId, quantity, 'shipped');
              } else {
                handleOrderProgression(productId, quantity, orderId, newStatus);
              }
            },
            child: const Text('Confirm', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _showUploadRequirementDialog(String orderId, String productId, int quantity, String targetStatus) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text("Upload Receipt"),
        content: const Text("A shipment receipt is required to mark as Shipped."),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
            onPressed: () async {
              Navigator.pop(context);
              bool success = await _uploadAndSaveReceipt(orderId);
              if (success) {
                handleOrderProgression(productId, quantity, orderId, targetStatus);
              }
            },
            child: const Text('Upload & Continue', style: TextStyle(color: Colors.white)),
          )
        ],
      ),
    );
  }

  void _showCancelDialog(String orderId) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Cancel Order'),
        content: DropdownButtonFormField<String>(
          decoration: InputDecoration(labelText: 'Reason', border: OutlineInputBorder(borderRadius: BorderRadius.circular(15))),
          items: _reasons.map((r) => DropdownMenuItem(value: r, child: Text(r))).toList(),
          onChanged: (v) => setState(() => _selectedReason = v),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Back')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () {
              if (_selectedReason != null) {
                _updateOrderStatus(orderId, 'cancelled', _selectedReason!);
                Navigator.pop(context);
              }
            },
            child: const Text('Cancel Order', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _showReturnDialog(String orderId) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Mark as Returned'),
        // --- ADD THESE TWO LINES ---
        actionsOverflowDirection: VerticalDirection.down,
        actionsAlignment: MainAxisAlignment.end,
        // ---------------------------
        content: DropdownButtonFormField<String>(
          decoration: InputDecoration(
              labelText: 'Reason for Return',
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(15))
          ),
          // Use a scrollable list if reasons are very long
          isExpanded: true,
          items: _reasons.map((r) => DropdownMenuItem(
              value: r,
              child: Text(r, overflow: TextOverflow.ellipsis)
          )).toList(),
          onChanged: (v) => setState(() => _selectedReason = v),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Back', style: TextStyle(color: Colors.grey))
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))
            ),
            onPressed: () {
              if (_selectedReason != null) {
                _updateOrderStatus(orderId, 'returned', _selectedReason!);
                Navigator.pop(context);
              }
            },
            child: const Text('Mark Returned', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        title: const Text('Orders Management', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black87)),
        backgroundColor: Colors.white, elevation: 0, centerTitle: true,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('orders').where('sellerId', isEqualTo: _auth.currentUser!.uid).snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) return _buildEmptyState();

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: snapshot.data!.docs.length,
            itemBuilder: (context, index) {
              final doc = snapshot.data!.docs[index];
              final data = doc.data() as Map<String, dynamic>;
              return _buildOrderCard(data, doc.id);
            },
          );
        },
      ),
    );
  }

  Widget _buildEmptyState() {
    return const Center(child: Text("No orders found", style: TextStyle(color: Colors.grey)));
  }

  Widget _buildOrderCard(Map<String, dynamic> data, String docId) {
    final status = data['status'].toString().toLowerCase();
    final orderDate = (data['orderDate'] as Timestamp).toDate();

    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 10)]),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("Order #${data['orderId'].toString().toUpperCase()}", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                const SizedBox(height: 6),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text("${orderDate.day}/${orderDate.month}/${orderDate.year}", style: TextStyle(color: Colors.grey.shade500, fontSize: 12)),
                    _buildStatusChip(status),
                  ],
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          ListTile(
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => SellerProductDetailsScreen(product: data))),
            leading: ClipRRect(borderRadius: BorderRadius.circular(8), child: Image.network(data['image'], width: 60, height: 60, fit: BoxFit.cover)),
            title: Text(data['title'], style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
            subtitle: Text("Qty: ${data['quantity']} | PKR ${data['totalPrice']}"),
            trailing: const Icon(Icons.arrow_forward_ios, size: 14),
          ),

          if (status == 'cancelled' || status == 'returned')
            Container(
                width: double.infinity,
                padding: const EdgeInsets.all(8),
                color: status == 'cancelled' ? Colors.red.shade50 : Colors.orange.shade50,
                child: Text("Reason: ${data['reason']}", style: TextStyle(color: status == 'cancelled' ? Colors.red.shade700 : Colors.orange.shade900, fontSize: 12))
            ),

          // --- LOGIC UPDATE: ACTIONS SECTION ---
          // Hide all actions if status is 'completed', 'cancelled', or 'returned'
          if (status != 'completed' && status != 'cancelled' && status != 'returned')
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  // Left Button Logic
                  if (status == 'pending' || status == 'in process')
                    Expanded(
                      child: OutlinedButton(
                        style: OutlinedButton.styleFrom(foregroundColor: Colors.red, side: const BorderSide(color: Colors.red), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
                        onPressed: () => _showCancelDialog(docId),
                        child: const Text("Cancel"),
                      ),
                    )
                  else if (status == 'shipped')
                    Expanded(
                      child: OutlinedButton(
                        style: OutlinedButton.styleFrom(foregroundColor: Colors.orange, side: const BorderSide(color: Colors.orange), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
                        onPressed: () => _showReturnDialog(docId),
                        child: const Text("Return Order"),
                      ),
                    ),

                  const SizedBox(width: 12),

                  // Right Button (Next Step Logic)
                  Expanded(
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.green, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
                      onPressed: () => _showStatusUpdateDialog(docId, status, data['productId'], data['quantity'], data['receiptImage'] ?? "pending"),
                      child: Text(
                          status == 'pending' ? "Start Process" :
                          status == 'in process' ? "Mark Shipped" : "Complete Order",
                          style: const TextStyle(color: Colors.white,fontSize: 13)
                      ),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildStatusChip(String status) {
    Color color;
    switch (status) {
      case 'completed': color = Colors.green; break;
      case 'shipped': color = Colors.purple; break;
      case 'cancelled': color = Colors.red; break;
      case 'in process': color = Colors.orange; break;
      case 'returned': color = Colors.orange.shade900; break;
      default: color = Colors.blue;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(20), border: Border.all(color: color.withOpacity(0.5))),
      child: Text(status.toUpperCase(), style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 10)),
    );
  }
}