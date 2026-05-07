import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/services.dart';
import 'package:zrai_mart/Admin/Admin%20Home/support/AdminChatListScreen.dart';

class NotificationDetailScreen extends StatelessWidget {
  final String type;
  final String actionId;
  final Map<String, dynamic> notificationData;

  const NotificationDetailScreen({
    super.key,
    required this.type,
    required this.actionId,
    required this.notificationData,
  });

  @override
  Widget build(BuildContext context) {
    final String cleanType = type.toLowerCase().trim();

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAF8),
      appBar: AppBar(
        title: Text("${cleanType.toUpperCase()} Details"),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeaderCard(),
            const SizedBox(height: 24),
            const Text("Detail Information",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const Divider(),
            const SizedBox(height: 10),

            // --- Updated Dynamic Content Logic ---
            if (cleanType == 'order' && actionId.isNotEmpty)
              _buildOrderDetails()
            else if (cleanType == 'store')
              _buildStoreDetails()
            else if (cleanType == 'product' && actionId.isNotEmpty)
                _buildProductDetails()
              else if (cleanType == 'payment') // New Payment Logic
                  _buildPaymentDetails()
                else if (cleanType == 'message' || cleanType == 'chat') // New Message Logic
                    _buildMessageDetails(context)
                  else
                    _buildDefaultDetails(cleanType),
          ],
        ),
      ),
    );
  }

  // --- NEW: Payment / Withdrawal Details ---
  Widget _buildPaymentDetails() {
    final String category = (notificationData['category'] ?? "").toString();
    final String sellerId = (notificationData['sellerId'] ?? "N/A").toString();

    return Column(
      children: [
        _buildDetailCard([
          _buildInfoRow("Transaction Type", category.toUpperCase()),
          _buildInfoRow("Reference ID", actionId, canCopy: true),
          _buildInfoRow("Seller ID", sellerId, canCopy: true),
          _buildInfoRow("Request Date", _formatTimestamp(notificationData['timestamp'])),
        ]),
        const SizedBox(height: 20),
        if (category == 'withdrawal')
          Container(
            padding: const EdgeInsets.all(15),
            decoration: BoxDecoration(
              color: Colors.blue.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.blue.withOpacity(0.3)),
            ),
            child: const Row(
              children: [
                Icon(Icons.info_outline, color: Colors.blue),
                SizedBox(width: 10),
                Expanded(
                  child: Text(
                    "Please navigate to the Withdrawal Management section to approve or reject this request.",
                    style: TextStyle(fontSize: 13, color: Colors.blue),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }

  // --- NEW: Message / Chat Quick Link ---
  Widget _buildMessageDetails(BuildContext context) {
    return Column(
      children: [
        _buildDetailCard([
          _buildInfoRow("From", notificationData['senderRole']?.toString().toUpperCase() ?? "USER"),
          _buildInfoRow("Sender ID", notificationData['senderId'] ?? "N/A", canCopy: true),
          _buildInfoRow("Received At", _formatTimestamp(notificationData['timestamp'])),
        ]),
        const SizedBox(height: 30),
        SizedBox(
          width: double.infinity,
          height: 55,
          child: ElevatedButton.icon(
            onPressed: () {
              Navigator.push(context, MaterialPageRoute(builder: (context) => const AdminChatListScreen()));
            },
            icon: const Icon(Icons.chat_bubble_outline),
            label: const Text("Open Chat Center", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
            ),
          ),
        ),
      ],
    );
  }

  // --- Existing Order Details ---
  Widget _buildOrderDetails() {
    return FutureBuilder<DocumentSnapshot>(
      future: FirebaseFirestore.instance.collection('orders').doc(actionId).get(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator(color: Colors.green));
        }

        if (!snapshot.hasData || !snapshot.data!.exists) {
          return _buildErrorState("Order #$actionId not found.");
        }

        var data = snapshot.data!.data() as Map<String, dynamic>;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 20, offset: const Offset(0, 4))
                ],
              ),
              child: Row(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.network(
                      data['image'] ?? "",
                      width: 80, height: 80, fit: BoxFit.cover,
                      errorBuilder: (c, e, s) => Container(width: 80, height: 80, color: Colors.grey[100], child: const Icon(Icons.image_not_supported)),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(data['title'] ?? "Product",
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18,),overflow: TextOverflow.ellipsis,),
                        const SizedBox(height: 4),
                        Text("PKR ${data['totalPrice']}",
                            style: const TextStyle(color: Colors.green, fontWeight: FontWeight.w900, fontSize: 18)),
                      ],
                    ),
                  ),
                  _statusSmallBadge(data['status'] ?? "pending"),
                ],
              ),
            ),
            const SizedBox(height: 24),
            _buildSectionTitle(Icons.local_shipping_outlined, "Delivery Details"),
            const SizedBox(height: 12),
            _buildDetailCard([
              _buildInfoRow("Customer", data['name'] ?? "N/A"),
              _buildInfoRow("Contact", data['phoneNumber'] ?? "N/A"),
              _buildInfoRow("Address", "${data['address']}, ${data['city']}"),
            ]),
            const SizedBox(height: 24),
            _buildSectionTitle(Icons.payments_outlined, "Payment Information"),
            const SizedBox(height: 12),
            _buildDetailCard([
              _buildInfoRow("Method", "Online Payment", isVerified: true),
              _buildInfoRow("Order ID", actionId, canCopy: true),
              _buildInfoRow("Date", _formatTimestamp(data['orderDate'])),
            ]),
            const SizedBox(height: 40),
          ],
        );
      },
    );
  }

  // --- Utility Widgets ---

  Widget _buildSectionTitle(IconData icon, String title) {
    return Row(
      children: [
        Icon(icon, size: 20, color: Colors.green),
        const SizedBox(width: 8),
        Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, letterSpacing: 0.5)),
      ],
    );
  }

  Widget _buildInfoRow(String label, String value, {bool isWarning = false, bool isVerified = false, bool canCopy = false}) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 0),
      title: Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey, fontWeight: FontWeight.w500)),
      subtitle: Row(
        children: [
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                  color: isWarning ? Colors.redAccent : Colors.black87
              ),
            ),
          ),
          if (isVerified) ...[
            const SizedBox(width: 6),
            const Icon(Icons.verified, color: Colors.blue, size: 16),
          ],
          if (canCopy) ...[
            const SizedBox(width: 6),
            InkWell(
              onTap: () {
                Clipboard.setData(ClipboardData(text: value));
              },
              child: const Icon(Icons.copy_rounded, color: Colors.grey, size: 16),
            ),
          ]
        ],
      ),
      dense: true,
    );
  }

  Widget _statusSmallBadge(String status) {
    final isCompleted = status.toLowerCase() == 'completed';
    final color = isCompleted ? Colors.green : Colors.orange;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Text(
        status.toUpperCase(),
        style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1),
      ),
    );
  }

  Widget _buildDetailCard(List<Widget> children) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 15, offset: const Offset(0, 6)),
        ],
        border: Border.all(color: Colors.grey.shade100, width: 1),
      ),
      child: Column(
        children: [
          const SizedBox(height: 10),
          ...children,
          const SizedBox(height: 10),
        ],
      ),
    );
  }

  String _formatTimestamp(dynamic timestamp) {
    if (timestamp == null) return "N/A";
    if (timestamp is Timestamp) {
      DateTime date = timestamp.toDate();
      return "${date.day}/${date.month}/${date.year} ${date.hour}:${date.minute}";
    }
    return timestamp.toString();
  }

  Widget _buildHeaderCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(notificationData['title'] ?? "Notification",
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.green)),
          const SizedBox(height: 8),
          Text(notificationData['body'] ?? "",
              style: TextStyle(color: Colors.grey[800], fontSize: 15)),
        ],
      ),
    );
  }

  Widget _buildStoreDetails() {
    final String rawCategory = (notificationData['category'] ?? "Update").toString();
    final String category = rawCategory.toUpperCase();

    Color primaryColor = Colors.orange.shade800;
    Color bgColor = Colors.orange.shade50;
    IconData statusIcon = Icons.storefront_rounded;

    if (category == 'APPROVED' || category == 'ACTIVE') {
      primaryColor = Colors.green.shade700;
      bgColor = Colors.green.shade50;
      statusIcon = Icons.check_circle_rounded;
    }

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: primaryColor.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Icon(statusIcon, size: 45, color: primaryColor),
          const SizedBox(height: 16),
          Text(category, style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: primaryColor)),
          const SizedBox(height: 8),
          Text(notificationData['body'] ?? "", textAlign: TextAlign.center),
        ],
      ),
    );
  }

  Widget _buildProductDetails() {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        leading: const Icon(Icons.inventory_2, color: Colors.teal),
        title: const Text("Affected Product ID"),
        subtitle: Text(actionId),
      ),
    );
  }

  Widget _buildErrorState(String msg) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Text(msg, style: const TextStyle(color: Colors.red, fontWeight: FontWeight.w500)),
      ),
    );
  }

  Widget _buildDefaultDetails(String cleanType) {
    return Center(
      child: Column(
        children: [
          const Icon(Icons.search_off, size: 50, color: Colors.grey),
          const SizedBox(height: 10),
          Text("No extra details for: '$cleanType'"),
        ],
      ),
    );
  }
}