import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../app_colors.dart';
import '../../../saller center/orderScreen/ProductDetailsScreen.dart';
import 'AdminProductDetailsScreen.dart';

class AdminOrdersScreen extends StatefulWidget {
  const AdminOrdersScreen({super.key});

  @override
  State<AdminOrdersScreen> createState() => _AdminOrdersScreenState();
}

class _AdminOrdersScreenState extends State<AdminOrdersScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = "";

  // Filter Constraints
  String _filterStatus = "All";
  RangeValues _priceRange = const RangeValues(0, 100000);
  final List<String> _statusOptions = ["All", "Pending", "In Process", "Shipped", "Completed", "Cancelled"];

  final List<String> _reasons = [
    'Item not needed anymore',
    'Wrong item ordered',
    'Found a better price',
    'Delivery is delayed',
    'Other',
    'Product out of stock',
    'Seller unable to fulfill',
    'Price mismatch/Update required',
    'Fake/Fraudulent Order',
    'Spam Product Listing',
    'Buyer unresponsiveness',
    'Duplicate Order',
    'Delivery area not covered',
    'Quality standards not met',
    'Weight/Quantity discrepancy'
  ];

  String? _selectedReason;

  // --- Logic Helpers ---

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'completed': return AppColors.primaryGreen;
      case 'pending': return Colors.orange;
      case 'in process': return Colors.blue;
      case 'shipped': return Colors.indigo;
      case 'cancelled': return Colors.red;
      default: return Colors.grey;
    }
  }

  bool _matchesSearch(Map<String, dynamic> data) {
    if (_searchQuery.isEmpty) return true;
    final query = _searchQuery.toLowerCase();
    final orderId = data['orderId']?.toString().toLowerCase() ?? "";
    final title = data['title']?.toString().toLowerCase() ?? "";
    final customerName = data['address']?.toString().toLowerCase() ?? "";
    return orderId.contains(query) || title.contains(query) || customerName.contains(query);
  }

  bool _matchesFilters(Map<String, dynamic> data) {
    final status = (data['status'] ?? "Pending").toString();
    final price = (data['totalPrice'] ?? 0).toDouble();
    bool statusMatch = _filterStatus == "All" || status.toLowerCase() == _filterStatus.toLowerCase();
    bool priceMatch = price >= _priceRange.start && price <= _priceRange.end;
    return statusMatch && priceMatch;
  }

  // --- Firebase Logic ---

  Future<void> _updateOrderStatus(String orderId, String newStatus, String reason) async {
    try {
      await FirebaseFirestore.instance.collection('orders').doc(orderId).update({
        'status': newStatus,
        'reason': reason
      });
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

  void handleNotificationUpload(Map<String, dynamic> product, String orderId, String reason) async {
    await uploadAdminNotification(
      orderId: orderId,
      productId: product['productId'],
      sellerId: product['sellerId'],
      userId: product['userId'],
      reason: reason,
      productName: product['title'] ?? "Product",
    );
  }

  Future<void> uploadAdminNotification({
    required String orderId,
    required String productId,
    required String sellerId,
    required String userId,
    required String reason,
    required String productName,
  }) async {
    try {
      await FirebaseFirestore.instance.collection('notifications').add({
        'orderId': orderId,
        'productId': productId,
        'sellerId': sellerId,
        'userId': userId,
        'senderId': 'admin',
        'title': 'Order Cancelled by Admin',
        'body': 'Order for "$productName" was cancelled. Reason: $reason',
        'type': 'cancelled',
        'userIsRead': false,
        'sellerIsRead': false,
        'timestamp': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      debugPrint('Error uploading notification: $e');
    }
  }

  // --- Dialogs & Sheets ---

  void _showFilterSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true, // Allows the sheet to expand beyond half the screen
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
      ),
      builder: (context) {
        return StatefulBuilder(builder: (context, setModalState) {
          return Container(
            // Limits height to 90% of screen to prevent full-screen takeover
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(context).size.height * 0.9,
            ),
            padding: EdgeInsets.only(
              left: 24,
              right: 24,
              top: 24,
              bottom: MediaQuery.of(context).viewInsets.bottom + 24, // Adjusts for keyboard
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min, // Still wraps content
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header - Fixed at top
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text("Filter Orders",
                        style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                    IconButton(onPressed: () => Navigator.pop(context),
                        icon: const Icon(Icons.close))
                  ],
                ),
                const Divider(), // Added a small divider for better UI

                // Scrollable Area
                Flexible(
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 10),
                        const Text("Order Status",
                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                        const SizedBox(height: 12),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: _statusOptions.map((s) {
                            final isSelected = _filterStatus == s;
                            return ChoiceChip(
                              label: Text(s),
                              selected: isSelected,
                              selectedColor: AppColors.primaryGreen.withOpacity(0.2),
                              labelStyle: TextStyle(
                                  color: isSelected ? AppColors.primaryGreen : Colors.black,
                                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal
                              ),
                              onSelected: (val) {
                                setModalState(() => _filterStatus = s);
                                setState(() {});
                              },
                            );
                          }).toList(),
                        ),
                        const SizedBox(height: 25),
                        Text("Price Range (PKR ${_priceRange.start.round()} - ${_priceRange.end.round()})",
                            style: const TextStyle(fontWeight: FontWeight.bold)),
                        RangeSlider(
                          values: _priceRange,
                          min: 0,
                          max: 100000,
                          divisions: 20,
                          activeColor: AppColors.primaryGreen,
                          inactiveColor: Colors.grey.shade200,
                          onChanged: (values) {
                            setModalState(() => _priceRange = values);
                            setState(() {});
                          },
                        ),
                        const SizedBox(height: 20),
                      ],
                    ),
                  ),
                ),

                // Button - Fixed at bottom
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(context),
                    style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primaryGreen,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))
                    ),
                    child: const Text("Apply Filters",
                        style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ),
          );
        });
      },
    );
  }

  void _showCancelConfirmationDialog(String orderId, Map<String, dynamic> product) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text("Cancel & Refund?", style: TextStyle(fontWeight: FontWeight.bold)),
        content: const Text("Since this is a paid order, canceling will require a refund process. Do you wish to proceed?"),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("No", style: TextStyle(color: Colors.grey))),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
            onPressed: () {
              Navigator.pop(context);
              _showCancelDialog(orderId, product);
            },
            child: const Text("Yes, Cancel", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _showCancelDialog(String orderId, Map<String, dynamic> product) {
    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(builder: (context, setDialogState) {
          return AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            title: const Text('Reason for Cancellation', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            content: DropdownButtonFormField<String>(
              decoration: InputDecoration(
                filled: true,
                fillColor: Colors.grey.shade50,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                contentPadding: const EdgeInsets.symmetric(horizontal: 12),
              ),
              hint: const Text("Select a reason"),
              value: _selectedReason,
              items: _reasons.map((r) => DropdownMenuItem(value: r, child: Text(r, style: const TextStyle(fontSize: 14)))).toList(),
              onChanged: (val) => setDialogState(() => _selectedReason = val),
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(context), child: const Text('Go Back', style: TextStyle(color: Colors.grey))),
              ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: AppColors.primaryGreen, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
                onPressed: () {
                  if (_selectedReason != null) {
                    _updateOrderStatus(orderId, 'cancelled', _selectedReason!);
                    handleNotificationUpload(product, orderId, _selectedReason!);
                    Navigator.pop(context);
                  }
                },
                child: const Text('Confirm', style: TextStyle(color: Colors.white)),
              ),
            ],
          );
        });
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        title: const Text('Order Management', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18, color: Colors.black)),
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 0,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(80),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Row(
              children: [
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(color: Colors.grey[100], borderRadius: BorderRadius.circular(15)),
                    child: TextField(
                      controller: _searchController,
                      onChanged: (val) => setState(() => _searchQuery = val),
                      decoration: const InputDecoration(
                        hintText: "Search ID, Product, or Customer...",
                        hintStyle: TextStyle(fontSize: 13),
                        prefixIcon: Icon(Icons.search, size: 20, color: Colors.grey),
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                InkWell(
                  onTap: _showFilterSheet,
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(color: AppColors.primaryGreen.withOpacity(0.1), borderRadius: BorderRadius.circular(15)),
                    child: const Icon(Icons.tune_rounded, color: AppColors.primaryGreen),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('orders').orderBy('timestamp', descending: true).snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator(color: AppColors.primaryGreen));

          final docs = snapshot.data?.docs ?? [];
          final filteredDocs = docs.where((doc) {
            final data = doc.data() as Map<String, dynamic>;
            return _matchesSearch(data) && _matchesFilters(data);
          }).toList();

          if (filteredDocs.isEmpty) return _buildEmptyState();

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: filteredDocs.length,
            itemBuilder: (context, index) {
              final doc = filteredDocs[index];
              final data = doc.data() as Map<String, dynamic>;
              final String status = (data['status'] ?? 'pending').toString().toLowerCase();
              final Timestamp? timestamp = data['timestamp'] as Timestamp?;
              final String formattedDate = timestamp != null ? DateFormat('dd MMM, hh:mm a').format(timestamp.toDate()) : "Date N/A";

              return _buildOrderCard(doc.id, data, status, formattedDate);
            },
          );
        },
      ),
    );
  }

  Widget _buildOrderCard(String docId, Map<String, dynamic> data, String status, String date) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10, offset: const Offset(0, 4))],
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
                    Text("ID: #${data['orderId'].toString().substring(0, 8).toUpperCase()}", style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 13)),
                    const SizedBox(height: 2),
                    Text(date, style: TextStyle(color: Colors.grey[500], fontSize: 11)),
                  ],
                ),
                _buildStatusBadge(status),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(color: const Color(0xFFF8FAF8), borderRadius: BorderRadius.circular(12)),
              child: Row(
                children: [
                  const Icon(Icons.person_outline, size: 14, color: AppColors.primaryGreen),
                  const SizedBox(width: 8),
                  Expanded(child: Text(data['address'] ?? "Customer", style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500), maxLines: 1, overflow: TextOverflow.ellipsis)),
                  // Changed from COD to PREPAID
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(color: Colors.blue.withOpacity(0.1), borderRadius: BorderRadius.circular(4)),
                    child: const Text("PAID", style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.blue)),
                  ),
                ],
              ),
            ),
          ),
          InkWell(
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => SellerProductDetailsScreen(product: data))),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.network(data['image'] ?? "", width: 60, height: 60, fit: BoxFit.cover, errorBuilder: (c, e, s) => Container(width: 60, height: 60, color: Colors.grey[100], child: const Icon(Icons.image))),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(data['title'] ?? "Product", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14), maxLines: 1),
                        const SizedBox(height: 4),
                        Text("Qty: ${data['quantity']} • PKR ${data['price']}", style: TextStyle(color: Colors.grey[600], fontSize: 12)),
                      ],
                    ),
                  ),
                  const Icon(Icons.chevron_right, color: Colors.grey, size: 18),
                ],
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(color: const Color(0xFFF9FAFB), borderRadius: const BorderRadius.vertical(bottom: Radius.circular(20))),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text("PAYMENT RECEIVED", style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: Colors.grey)),
                    Text("PKR ${data['totalPrice']}", style: const TextStyle(fontWeight: FontWeight.w900, color: AppColors.primaryGreen, fontSize: 16)),
                  ],
                ),
                if (status != 'completed' && status != 'cancelled')
                  OutlinedButton(
                    onPressed: () => _showCancelConfirmationDialog(docId, data),
                    style: OutlinedButton.styleFrom(side: const BorderSide(color: Colors.redAccent), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
                    child: const Text("Cancel Order", style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold, fontSize: 12)),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusBadge(String status) {
    Color color = _getStatusColor(status);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
      child: Text(status.toUpperCase(), style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.bold)),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.assignment_late_outlined, size: 60, color: Colors.grey[300]),
          const SizedBox(height: 16),
          const Text("No Orders Found", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey)),
          TextButton(onPressed: () => setState(() { _searchQuery = ""; _filterStatus = "All"; _priceRange = const RangeValues(0, 100000); _searchController.clear(); }), child: const Text("Reset All Filters")),
        ],
      ),
    );
  }
}