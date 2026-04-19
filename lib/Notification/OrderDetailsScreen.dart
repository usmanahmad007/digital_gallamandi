import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class OrderDetailsScreen extends StatelessWidget {
  final String orderId;
  final String productId;

  const OrderDetailsScreen({super.key, required this.orderId, required this.productId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        title: const Text('Order Summary', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black87)),
        backgroundColor: Colors.white,
        elevation: 0.5,
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.black87),
      ),
      body: FutureBuilder<DocumentSnapshot>(
        future: FirebaseFirestore.instance.collection('orders').doc(orderId).get(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: Colors.green));
          }
          if (!snapshot.hasData || !snapshot.data!.exists) {
            return const Center(child: Text("Order details not found."));
          }

          final data = snapshot.data!.data() as Map<String, dynamic>;
          final status = data['status'].toString().toLowerCase();
          final DateTime orderDate = (data['orderDate'] as Timestamp).toDate();

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 1. Status & ID Header
                _buildHeader(data['orderId'], status, orderDate),
                const SizedBox(height: 20),

                // 2. Product Card
                _buildProductCard(data),
                const SizedBox(height: 20),

                // 3. Reason for Cancellation/Return (Conditional)
                if (status == 'cancelled' || status == 'returned')
                  _buildReasonCard(data['reason']),

                // 4. Shipment Receipt (Conditional)
                if (data['receiptImage'] != null && data['receiptImage'] != "pending")
                  _buildReceiptCard(data['receiptImage']),

                // 5. Shipping Address Card
                _buildAddressCard(data),
                const SizedBox(height: 20),

                // 6. Payment Summary
                _buildPriceSummary(data),
                const SizedBox(height: 30),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildHeader(String id, String status, DateTime date) {
    Color statusColor = _getStatusColor(status);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(15)),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          Text("Order #$id", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          const SizedBox(height: 4),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(DateFormat('dd MMM yyyy, hh:mm a').format(date), style: const TextStyle(color: Colors.grey, fontSize: 12,),textAlign: TextAlign.left,),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(color: statusColor.withOpacity(0.1), borderRadius: BorderRadius.circular(20)),
                child: Text(status.toUpperCase(), style: TextStyle(color: statusColor, fontWeight: FontWeight.bold, fontSize: 12)),
              ),
            ],
          ),

        ],
      ),
    );
  }

  Widget _buildProductCard(Map<String, dynamic> data) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(15)),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: Image.network(data['image'], width: 80, height: 80, fit: BoxFit.cover),
          ),
          const SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(data['title'], style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                const SizedBox(height: 4),
                Text("Quantity: ${data['quantity']}", style: const TextStyle(color: Colors.grey)),
                Text("Price: PKR ${data['price']}", style: const TextStyle(fontWeight: FontWeight.w500, color: Colors.green)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReasonCard(String reason) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 20),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colors.red.shade50, borderRadius: BorderRadius.circular(15), border: Border.all(color: Colors.red.shade100)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("Note for Seller", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.red)),
          const SizedBox(height: 4),
          Text(reason, style: TextStyle(color: Colors.red.shade900)),
        ],
      ),
    );
  }

  Widget _buildReceiptCard(String imageUrl) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 20),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(15)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("Shipment Receipt", style: TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: Image.network(imageUrl, height: 150, width: double.infinity, fit: BoxFit.cover),
          ),
        ],
      ),
    );
  }

  Widget _buildAddressCard(Map<String, dynamic> data) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(15)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.location_on, color: Colors.green, size: 20),
              SizedBox(width: 8),
              Text("Delivery Address", style: TextStyle(fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 10),
          Text(data['name'], style: const TextStyle(fontWeight: FontWeight.w500)),
          Text(data['address']),
          Text("${data['city']}, ${data['postalCode']}"),
          Text("Phone: ${data['phoneNumber']}", style: const TextStyle(color: Colors.grey)),
        ],
      ),
    );
  }

  Widget _buildPriceSummary(Map<String, dynamic> data) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(15)),
      child: Column(
        children: [
          _priceRow("Subtotal", "PKR ${data['totalPrice']}"),
          const Divider(height: 20),
          _priceRow("Total Amount", "PKR ${data['totalPrice']}", isBold: true),
        ],
      ),
    );
  }

  Widget _priceRow(String label, String value, {bool isBold = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: TextStyle(fontWeight: isBold ? FontWeight.bold : FontWeight.normal, fontSize: isBold ? 16 : 14)),
        Text(value, style: TextStyle(fontWeight: isBold ? FontWeight.bold : FontWeight.normal, color: isBold ? Colors.green : Colors.black, fontSize: isBold ? 16 : 14)),
      ],
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'completed': return Colors.green;
      case 'shipped': return Colors.purple;
      case 'cancelled': return Colors.red;
      case 'returned': return Colors.orange;
      case 'in process': return Colors.blue;
      default: return Colors.grey;
    }
  }
}