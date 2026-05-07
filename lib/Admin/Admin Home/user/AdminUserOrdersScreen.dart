import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../app_colors.dart';
import '../../../saller center/orderScreen/ProductDetailsScreen.dart';

class AdminUserOrdersScreen extends StatefulWidget {
  final String userId;
  final String userName;

  const AdminUserOrdersScreen({
    super.key,
    required this.userId,
    required this.userName,
  });

  @override
  State<AdminUserOrdersScreen> createState() => _AdminUserOrdersScreenState();
}

class _AdminUserOrdersScreenState extends State<AdminUserOrdersScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = "";

  String formatDate(Timestamp? timestamp) {
    if (timestamp == null) return "N/A";
    final date = timestamp.toDate();
    return DateFormat('dd MMM yyyy, hh:mm a').format(date);
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case "pending":
        return Colors.orange;
      case "completed":
        return Colors.green;
      case "cancelled":
        return Colors.red;
      case "shipped":
        return Colors.blue;
      default:
        return Colors.grey;
    }
  }

  bool _matchesSearch(Map<String, dynamic> data) {
    if (_searchQuery.isEmpty) return true;

    final query = _searchQuery.toLowerCase();

    final orderId = (data['orderId'] ?? "").toString().toLowerCase();
    final title = (data['title'] ?? "").toString().toLowerCase();
    final city = (data['city'] ?? "").toString().toLowerCase();
    final address = (data['address'] ?? "").toString().toLowerCase();

    return orderId.contains(query) ||
        title.contains(query) ||
        city.contains(query) ||
        address.contains(query);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),

      appBar: AppBar(
        title: Text(
          "${widget.userName} Orders",
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 0,

        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(80),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(15),
              ),
              child: TextField(
                controller: _searchController,
                onChanged: (val) {
                  setState(() {
                    _searchQuery = val;
                  });
                },
                decoration: const InputDecoration(
                  hintText: "Search Order ID, Product, City...",
                  prefixIcon: Icon(Icons.search, color: Colors.grey),
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.symmetric(vertical: 14),
                ),
              ),
            ),
          ),
        ),
      ),

      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('orders')
            .where('userId', isEqualTo: widget.userId)
            .orderBy('timestamp', descending: true)
            .snapshots(),

        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final docs = snapshot.data?.docs ?? [];

          final filtered = docs.where((doc) {
            final data = doc.data() as Map<String, dynamic>;
            return _matchesSearch(data);
          }).toList();

          if (filtered.isEmpty) {
            return const Center(child: Text("No Orders Found"));
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: filtered.length,
            itemBuilder: (context, index) {
              final doc = filtered[index];
              final data = doc.data() as Map<String, dynamic>;

              final status = (data['status'] ?? "pending").toString();

              return _buildOrderCard(context, doc.id, data, status);
            },
          );
        },
      ),
    );
  }

  Widget _buildOrderCard(
      BuildContext context,
      String orderId,
      Map<String, dynamic> data,
      String status,
      ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "ID: #${data['orderId'].toString().substring(0, 8).toUpperCase()}",
                      style: const TextStyle(
                        fontWeight: FontWeight.w900,
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      formatDate(data['timestamp']),
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: _getStatusColor(status).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    status.toUpperCase(),
                    style: TextStyle(
                      color: _getStatusColor(status),
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),

          InkWell(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) =>
                      SellerProductDetailsScreen(product: data),
                ),
              );
            },
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.network(
                      data['image'] ?? "",
                      width: 60,
                      height: 60,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Container(
                        width: 60,
                        height: 60,
                        color: Colors.grey.shade200,
                        child: const Icon(Icons.image),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          data['title'] ?? "Product",
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          "Qty: ${data['quantity']} • Rs ${data['totalPrice']}",
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 12,
                          ),
                        ),
                        Text(
                          data['city'] ?? "",
                          style: TextStyle(
                            color: Colors.grey[500],
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Icon(Icons.arrow_forward_ios, size: 14),
                ],
              ),
            ),
          ),

          const SizedBox(height: 10),

          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFF9FAFB),
              borderRadius: const BorderRadius.vertical(
                bottom: Radius.circular(20),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  "Total: Rs ${data['totalPrice']}",
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.green,
                  ),
                ),
                Text(
                  data['paymentStatus'] ?? "PAID",
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: Colors.blue,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
