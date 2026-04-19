import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:zrai_mart/UI/orderScreen/reorderScreen.dart';

class UserOrderDetailsScreen extends StatefulWidget {
  final Map<String, dynamic> product;

  const UserOrderDetailsScreen({super.key, required this.product});

  @override
  State<UserOrderDetailsScreen> createState() => _UserOrderDetailsScreenState();
}

class _UserOrderDetailsScreenState extends State<UserOrderDetailsScreen> {
  // Helper to get color based on status
  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'completed':
        return Colors.blue;
      case 'cancelled':
        return Colors.red;
      case 'shipped':
        return Colors.indigo;
      case 'in process':
        return Colors.orange;
      default:
        return Colors.green;
    }
  }

/*  // Support Launchers
  Future<void> _contactSupport(String type) async {
    final orderId = widget.product['orderId'];
    if (type == 'whatsapp') {
      final url = Uri.parse("https://wa.me/923257978023?text=Support for Order: $orderId");
      if (await canLaunchUrl(url)) await launchUrl(url, mode: LaunchMode.externalApplication);
    } else {
      final Uri emailUri = Uri(scheme: 'mailto', path: 'gallamandidigital@gmail.com', queryParameters: {'subject': 'Order $orderId'});
      if (await canLaunchUrl(emailUri)) await launchUrl(emailUri);
    }
  }*/
  Future<void> _launchWhatsApp() async {
    final orderId = widget.product['orderId'];
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
  Future<void> _launchEmail() async {
    final orderId = widget.product['orderId'];
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

  @override
  Widget build(BuildContext context) {
    final status = widget.product['status'].toString().toLowerCase();
    final Color statusColor = _getStatusColor(status);

    return Scaffold(
      backgroundColor: const Color(0xffF8F9FA),
      appBar: AppBar(
        title: const Text('Order Details',
            style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. PRODUCT CARD
            GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => ReorderProductView(
                      productId:
                          widget.product['productId'], // ONLY pass the ID
                    ),
                  ),
                );
              },
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                        color: Colors.black.withOpacity(0.05), blurRadius: 10)
                  ],
                ),
                child: Column(
                  children: [
                    ClipRRect(
                      borderRadius:
                          const BorderRadius.vertical(top: Radius.circular(20)),
                      child: Image.network(
                        widget.product['image'],
                        height: 200,
                        width: double.infinity,
                        fit: BoxFit.cover,
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(widget.product['title'],
                                    style: const TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold)),
                                const SizedBox(height: 4),
                                Text("Order ID: ${widget.product['orderId']}",
                                    style: const TextStyle(
                                        color: Colors.grey, fontSize: 12)),
                              ],
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                                color: statusColor.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(8)),
                            child: Text(status.toUpperCase(),
                                style: TextStyle(
                                    color: statusColor,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 12)),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 20),

            // 2. ORDER SUMMARY TILES
            _buildSectionTitle("Order Summary"),
            _buildInfoCard([
              _buildDetailRow(
                  "Price per Unit", "PKR ${widget.product['price']}"),
              _buildDetailRow("Quantity", "x${widget.product['quantity']}"),
              const Divider(),
              _buildDetailRow(
                  "Total Amount", "PKR ${widget.product['totalPrice']}",
                  isBold: true),
            ]),

            const SizedBox(height: 20),

            // 3. SHIPPING & STATUS
            _buildSectionTitle("Shipping Information"),
            _buildInfoCard([
              _buildIconDetail(Icons.calendar_today_outlined,
                  "Delivery Estimate", "7 Days (Standard)"),
              _buildIconDetail(Icons.location_on_outlined, "Delivery Address",
                  "${widget.product['address']}, ${widget.product['city']}"),
              if (status == 'cancelled')
                _buildIconDetail(Icons.error_outline, "Cancellation Reason",
                    widget.product['reason'] ?? "N/A",
                    textColor: Colors.red),
            ]),

            const SizedBox(height: 30),

            // 4. ACTION BUTTONS
            if (status == 'shipped')
              Column(
                children: [
                  const Text("Need to cancel or change something?",
                      style: TextStyle(color: Colors.grey, fontSize: 13)),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: _buildActionButton(
                            Icons.chat,
                            "WhatsApp Support",
                            Colors.green,
                            () => _launchWhatsApp()),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _buildActionButton(Icons.email, "Email Support",
                            Colors.blue, () => _launchEmail()),
                      ),
                    ],
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }

  // --- UI BUILDING BLOCKS ---

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 8),
      child: Text(title,
          style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 15,
              color: Colors.black87)),
    );
  }

  Widget _buildInfoCard(List<Widget> children) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: Colors.grey.withOpacity(0.1)),
      ),
      child: Column(children: children),
    );
  }

  Widget _buildDetailRow(String label, String value, {bool isBold = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Colors.black54)),
          Text(value,
              style: TextStyle(
                  fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
                  fontSize: isBold ? 16 : 14)),
        ],
      ),
    );
  }

  Widget _buildIconDetail(IconData icon, String title, String value,
      {Color? textColor}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: Colors.green),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: const TextStyle(color: Colors.grey, fontSize: 11)),
                Text(value,
                    style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: textColor ?? Colors.black87)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton(
      IconData icon, String label, Color color, VoidCallback onTap) {
    return ElevatedButton.icon(
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(vertical: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        elevation: 0,
      ),
      onPressed: onTap,
      icon: Icon(icon, size: 18),
      label: Text(label,
          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
    );
  }
}
