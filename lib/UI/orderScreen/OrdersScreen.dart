import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../Notification/send_notification.dart';
import 'OrderDetailsScreen.dart';

class Ordersscreen extends StatefulWidget {
  const Ordersscreen({super.key});

  @override
  State<Ordersscreen> createState() => _OrdersscreenState();
}

class _OrdersscreenState extends State<Ordersscreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  int selectedRating = 0;
  final List<String> _reasons = [
    // Product Related
    'Found a better price elsewhere',
    'Ordered the wrong item/variety',
    'Change in quantity needed',

    // Delivery Related
    'Delivery time is too long',
    'Expected delivery date changed',
    'Shipping costs are too high',

    // Personal/Miscellaneous
    'Item not needed anymore',
    'Order placed by mistake',
    'Changed my mind',
    'Planning to reorder later',

    // Payment/Process
    'Issues with payment method',
    'Applied wrong discount code',

    'Other' // Always keep this as a catch-all
  ];

  String? _selectedReason;




  // --- Logic Helpers ---

  String _getDeliveryDays(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return "Arriving in 7 Days";
      case 'in process':
        return "Arriving in 6 Days";
      case 'shipped':
        return "Arriving in 4 Days";
      default:
        return ""; // Don't show for completed or cancelled
    }
  }

  Widget _buildStatusChip(String status) {
    Color color;
    switch (status.toLowerCase()) {
      case 'completed':
        color = Colors.blue;
        break;
      case 'cancelled':
        color = Colors.red;
        break;
      case 'shipped':
        color = Colors.indigo;
        break;
      case 'in process':
        color = Colors.orange;
        break;
      default:
        color = Colors.green;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        status.toUpperCase(),
        style:
            TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.bold),
      ),
    );
  }

  // --- Firestore & Dialog Methods ---

  Future<void> _updateOrderStatus(
      String orderId, String newStatus, String reason) async {
    try {
      // 1. Update the order document
      await _firestore
          .collection('orders')
          .doc(orderId)
          .update({'status': newStatus, 'reason': reason});

      // 2. Fetch order details to notify the seller
      final orderDoc = await _firestore.collection('orders').doc(orderId).get();

      if (orderDoc.exists && newStatus == 'cancelled') {
        final data = orderDoc.data() as Map<String, dynamic>;
        String sellerId = data['sellerId'];
        debugPrint(sellerId);
        String productTitle = data['title'];
        String productId = data['productId'];
        // Build notification message
        String message =
            "Order Update: The order for '$productTitle' is now ${newStatus.toUpperCase()}.";

        if ((newStatus == 'cancelled' || newStatus == 'returned') &&
            reason != 'none') {
          message += " Reason: $reason.";
        }
        // 3. Send notification to the Seller
        await sendNotification(
          userId: FirebaseAuth.instance.currentUser!.uid, // Specifically targeting the customer
          senderId: FirebaseAuth.instance.currentUser!.uid,
          senderRole: 'customer',
          sellerId: sellerId,
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
          const SnackBar(content: Text('Failed to update order status.')),
        );
      }
    }
  }

// ... inside your _OrdersscreenState class

  void _showShippedCancelInfo(String orderId) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        child: Stack(
          clipBehavior:
              Clip.none, // Allows the icon to pop out slightly if needed
          children: [
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const SizedBox(height: 10),
                  // 1. Visual Icon
                  Container(
                    height: 70,
                    width: 70,
                    decoration: BoxDecoration(
                      color: Colors.indigo.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.local_shipping,
                        size: 35, color: Colors.indigo),
                  ),
                  const SizedBox(height: 20),
                  // 2. Title
                  const Text(
                    "Order Shipped",
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
                  // 3. Description
                  const Text(
                    "Your order is currently with our delivery partner and cannot be cancelled automatically. Please talk to our team for assistance.",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                        fontSize: 14, color: Colors.black54, height: 1.5),
                  ),
                  const SizedBox(height: 25),
                  // 4. Action Buttons
                  Row(
                    children: [
                      Expanded(
                        child: _buildSupportButton(
                          icon: Icons.chat,
                          label: "WhatsApp",
                          color: const Color(0xff25D366),
                          onTap: () => _launchWhatsApp(orderId),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildSupportButton(
                          icon: Icons.email_outlined,
                          label: "Email",
                          color: Colors.blueAccent,
                          onTap: () => _launchEmail(orderId),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            // 5. THE TOP RIGHT CLOSE ICON
            Positioned(
              right: 8,
              top: 8,
              child: IconButton(
                onPressed: () => Navigator.pop(context),
                icon: CircleAvatar(
                  radius: 14,
                  backgroundColor: Colors.grey[200],
                  child:
                      const Icon(Icons.close, size: 16, color: Colors.black54),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

// Helper Widget for the styled buttons
  Widget _buildSupportButton(
      {required IconData icon,
      required String label,
      required Color color,
      required VoidCallback onTap}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          border: Border.all(color: color.withOpacity(0.3)),
          borderRadius: BorderRadius.circular(12),
          color: color.withOpacity(0.05),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(height: 4),
            Text(label,
                style: TextStyle(
                    color: color, fontWeight: FontWeight.bold, fontSize: 12)),
          ],
        ),
      ),
    );
  }

// Helper to launch WhatsApp
  Future<void> _launchWhatsApp(String orderId) async {
    final String phone = "923257978023"; // Replace with your support number
    final String message =
        "Hello, I want to cancel my order. Order ID:${orderId}"; /*${ Pass your ID here }";*/
    final Uri url =
        Uri.parse("https://wa.me/$phone?text=${Uri.encodeComponent(message)}");

    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("WhatsApp is not installed")),
      );
    }
  }

// Helper to launch Email
  Future<void> _launchEmail(String orderId) async {
    final Uri emailLaunchUri = Uri(
      scheme: 'mailto',
      path: 'gallamandidigital@gmail.com', // Replace with your support email
      queryParameters: {
        'subject': 'Order Cancellation Request',
        'body': 'I would like to cancel my order #${orderId}',
      },
    );

    if (await canLaunchUrl(emailLaunchUri)) {
      await launchUrl(emailLaunchUri);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Could not open email app")),
      );
    }
  }

  Future<void> _showCancelConfirmationDialog(String orderId) async {
    return showDialog<void>(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          child: Stack(
            children: [
              Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const SizedBox(height: 10),
                    // 1. Warning Icon
                    Container(
                      height: 70,
                      width: 70,
                      decoration: BoxDecoration(
                        color: Colors.red.withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.remove_shopping_cart_outlined,
                          size: 35, color: Colors.redAccent),
                    ),
                    const SizedBox(height: 20),
                    // 2. Title
                    const Text(
                      "Cancel Order?",
                      style:
                          TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 12),
                    // 3. Subtitle
                    const Text(
                      "Are you sure you want to cancel this order? This action cannot be undone once confirmed.",
                      textAlign: TextAlign.center,
                      style: TextStyle(
                          fontSize: 14, color: Colors.black54, height: 1.5),
                    ),
                    const SizedBox(height: 30),
                    // 4. Buttons
                    Row(
                      children: [
                        // "No" Button
                        Expanded(
                          child: OutlinedButton(
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12)),
                              side: BorderSide(color: Colors.grey.shade300),
                            ),
                            onPressed: () => Navigator.of(context).pop(),
                            child: const Text("No, Keep it",
                                style: TextStyle(
                                    color: Colors.black87,
                                    fontWeight: FontWeight.w600)),
                          ),
                        ),
                        const SizedBox(width: 12),
                        // "Yes" Button
                        Expanded(
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.redAccent,
                              elevation: 0,
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12)),
                            ),
                            onPressed: () {
                              Navigator.of(context).pop();
                              _showCancelDialog(orderId);
                            },
                            child: const Text("Yes, Cancel",
                                style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold)),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              // 5. Consistent Close Icon
              Positioned(
                right: 8,
                top: 8,
                child: IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: CircleAvatar(
                    radius: 14,
                    backgroundColor: Colors.grey[100],
                    child: const Icon(Icons.close,
                        size: 16, color: Colors.black54),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _showCancelDialog(String orderId) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          child: Stack(
            children: [
              Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const SizedBox(height: 10),
                    // 1. Icon & Header
                    Container(
                      height: 60,
                      width: 60,
                      decoration: BoxDecoration(
                        color: Colors.orange.withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.assignment_late_outlined,
                          size: 30, color: Colors.orange),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      "Cancel Reason",
                      style:
                          TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      "Please let us know why you're cancelling so we can improve.",
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 13, color: Colors.black54),
                    ),
                    const SizedBox(height: 24),

                    // 2. The Styled Dropdown
                    DropdownButtonFormField<String>(
                      isExpanded: true,
                      icon: const Icon(Icons.keyboard_arrow_down_rounded,
                          color: Colors.grey),
                      decoration: InputDecoration(
                        filled: true,
                        fillColor: Colors.grey[50]!,
                        hintText: "Select a reason",
                        hintStyle:
                            const TextStyle(fontSize: 14, color: Colors.grey),
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 8),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: Colors.grey.shade300),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide:
                              const BorderSide(color: Colors.green, width: 1.5),
                        ),
                      ),
                      items: _reasons
                          .map((r) => DropdownMenuItem(
                                value: r,
                                child: Text(r,
                                    style: const TextStyle(fontSize: 14)),
                              ))
                          .toList(),
                      onChanged: (value) {
                        setState(() {
                          _selectedReason = value;
                        });
                      },
                    ),
                    const SizedBox(height: 30),

                    // 3. Action Buttons
                    Row(
                      children: [
                        Expanded(
                          child: TextButton(
                            onPressed: () => Navigator.pop(context),
                            child: const Text("Back",
                                style: TextStyle(
                                    color: Colors.grey,
                                    fontWeight: FontWeight.w600)),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.green,
                              elevation: 0,
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12)),
                            ),
                            onPressed: () {
                              if (_selectedReason != null) {
                                _updateOrderStatus(
                                    orderId, 'cancelled', _selectedReason!);
                                Navigator.pop(context);
                              } else {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                      content: Text("Please select a reason")),
                                );
                              }
                            },
                            child: const Text("Submit",
                                style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold)),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              // 4. Consistent Close Icon
              Positioned(
                right: 8,
                top: 8,
                child: IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: CircleAvatar(
                    radius: 14,
                    backgroundColor: Colors.grey[100],
                    child: const Icon(Icons.close,
                        size: 16, color: Colors.black54),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
  // --- UI Build ---

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xffF5F5F5),
      appBar: AppBar(
        title: const Text('Your Orders',
            style: TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: _firestore
            .collection('orders')
            .where('userId', isEqualTo: _auth.currentUser!.uid)
            .orderBy('timestamp', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting)
            return const Center(child: CircularProgressIndicator());
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty)
            return const Center(child: Text('No orders found.'));

          final orders = snapshot.data!.docs;

          return ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: orders.length,
            itemBuilder: (context, index) {
              final order = orders[index];
              final orderData = order.data() as Map<String, dynamic>;
              final status =
                  (orderData['status'] ?? 'pending').toString().toLowerCase();
              final date = (orderData['orderDate'] as Timestamp).toDate();
              final deliveryText = _getDeliveryDays(status);

              return GestureDetector(
                onLongPress: () => _showDeletelConfirmationDialog(order.id),
                child: Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(15),
                    boxShadow: [
                      BoxShadow(
                          color: Colors.black.withOpacity(0.05), blurRadius: 10)
                    ],
                  ),
                  child: Column(
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(12),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text("Order #${orderData['orderId']}",
                                    style: const TextStyle(
                                        fontWeight: FontWeight.bold)),
                                Text(
                                    DateFormat('dd MMM yyyy, hh:mm a')
                                        .format(date),
                                    style: const TextStyle(
                                        color: Colors.grey, fontSize: 12)),
                              ],
                            ),
                            _buildStatusChip(status),
                          ],
                        ),
                      ),
                      const Divider(height: 1),
                      ListTile(
                        contentPadding: const EdgeInsets.all(12),
                        leading: ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.network(orderData['image'],
                              width: 60, height: 60, fit: BoxFit.cover),
                        ),
                        title: Text(orderData['title'],
                            style:
                                const TextStyle(fontWeight: FontWeight.w600)),
                        subtitle: Text("Quantity: ${orderData['quantity']}"),
                        trailing: Text(
                            "PKR ${orderData['totalPrice'].toStringAsFixed(2)}",
                            style: const TextStyle(
                                color: Colors.green,
                                fontWeight: FontWeight.bold)),
                        onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (_) =>
                                    UserOrderDetailsScreen(product: orderData))),
                      ),
                      Padding(
                        padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
                        child: Row(
                          children: [
                            if (deliveryText.isNotEmpty) ...[
                              const Icon(Icons.timer_outlined,
                                  size: 14, color: Colors.grey),
                              const SizedBox(width: 4),
                              Text(deliveryText,
                                  style: const TextStyle(
                                      fontSize: 12, color: Colors.grey)),
                            ],
                            if (status == 'cancelled')
                              Text(
                                "Reason: ${orderData['reason']}",
                                style: const TextStyle(
                                    color: Colors.red,
                                    fontSize: 12,
                                    fontStyle: FontStyle.italic),
                              ),
                            const Spacer(),

                            // Cancellation Buttons Logic
                            if (status == 'pending' || status == 'in process')
                              TextButton(
                                onPressed: () =>
                                    _showCancelConfirmationDialog(order.id),
                                child: const Text("Cancel",
                                    style: TextStyle(color: Colors.red)),
                              ),

                            if (status == 'shipped')
                              TextButton.icon(
                                onPressed: () {
                                  _showShippedCancelInfo(order.id);
                                },
                                icon: const Icon(Icons.help_outline, size: 16),
                                label: const Text("Cancel?",
                                    style: TextStyle(color: Colors.indigo)),
                              ),

                            if (status == 'completed' &&
                                orderData['rated'] == false)
                              ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.green,
                                    shape: RoundedRectangleBorder(
                                        borderRadius:
                                            BorderRadius.circular(8))),
                                onPressed: () => _addRating(
                                    orderData['productId'], order.id),
                                child: const Text("Rate Now",
                                    style: TextStyle(color: Colors.white)),
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
        },
      ),
    );
  }

  // --- Original Logic Kept ---

  Future<void> _showDeletelConfirmationDialog(String orderId) async {
    return showDialog<void>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Delete Order'),
          content: const Text('Are you sure you want to delete this order?'),
          actions: <Widget>[
            TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('No')),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
              onPressed: () {
                deleteOrder(orderId);
                Navigator.pop(context);
              },
              child: const Text('Yes', style: TextStyle(color: Colors.white)),
            ),
          ],
        );
      },
    );
  }

  Future<void> _addRating(String productId, String orderId) async {
    TextEditingController reviewController = TextEditingController();
    return showDialog<void>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text("Rate this Product"),
          content: SingleChildScrollView(
            child: StatefulBuilder(
              builder: (BuildContext context, StateSetter setDialogState) {
                return Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text("Select a rating:"),
                    const SizedBox(height: 10),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(5, (index) {
                        return IconButton(
                          onPressed: () {
                            setDialogState(() => selectedRating = index + 1);
                          },
                          icon: Icon(Icons.star,
                              color: selectedRating > index
                                  ? Colors.amber
                                  : Colors.grey),
                        );
                      }),
                    ),
                    const SizedBox(height: 20),
                    TextField(
                      controller: reviewController,
                      maxLines: 3,
                      decoration: const InputDecoration(
                          labelText: "Review", border: OutlineInputBorder()),
                    ),
                  ],
                );
              },
            ),
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text("Cancel")),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                CallTheMethod(productId, orderId, reviewController.text.trim());
              },
              child: const Text("Submit"),
            ),
          ],
        );
      },
    );
  }

  Future<void> deleteOrder(String orderId) async {
    try {
      await _firestore.collection('orders').doc(orderId).delete();
    } catch (e) {
      print("Error: $e");
    }
  }

  Future<void> updateRated(String orderId) async {
    try {
      await _firestore
          .collection('orders')
          .doc(orderId)
          .update({'rated': true});
    } catch (e) {
      print("Error: $e");
    }
  }

  Future<void> uploadRatingWithReview(
      String productId, int rating, String review) async {
    try {
      final productRef = _firestore.collection('products').doc(productId);
      if (review.isNotEmpty) {
        await productRef.collection('reviews').add({
          'userId': _auth.currentUser!.uid,
          'rating': rating,
          'review': review,
          'timestamp': FieldValue.serverTimestamp(),
        });
      }
      final productDoc = await productRef.get();
      if (productDoc.exists) {
        List<dynamic> ratings = productDoc.data()?['rating'] ?? [];
        ratings.add(rating.toString());
        double averageRating = ratings
                .map((r) => double.tryParse(r.toString()) ?? 0.0)
                .reduce((a, b) => a + b) /
            ratings.length;
        await productRef.update({
          'rating': ratings,
          'averageRating': averageRating.toStringAsFixed(1)
        });
      }
    } catch (e) {
      print("Error: $e");
    }
  }

  Future<void> CallTheMethod(
      String productId, String orderId, String review) async {
    await uploadRatingWithReview(productId, selectedRating, review);
    await updateRated(orderId);
  }
}
