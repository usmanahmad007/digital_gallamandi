import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class SellerProductDetailsScreen extends StatefulWidget {
  final Map<String, dynamic> product;

  const SellerProductDetailsScreen({super.key, required this.product});

  @override
  State<SellerProductDetailsScreen> createState() =>
      _SellerProductDetailsScreenState();
}

class _SellerProductDetailsScreenState extends State<SellerProductDetailsScreen> {

  // --- UI COMPONENTS ---

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12.0, horizontal: 4.0),
      child: Text(
        title.toUpperCase(),
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: Colors.grey.shade600,
          letterSpacing: 1.1,
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value, {Color? valueColor, bool isBold = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(color: Colors.grey.shade600, fontSize: 14)),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.end,
              style: TextStyle(
                fontSize: 14,
                fontWeight: isBold ? FontWeight.bold : FontWeight.w500,
                color: valueColor ?? Colors.black87,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildImagePreview(String? url, String label) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
        const SizedBox(height: 8),
        Container(
          height: 180,
          width: 150,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(15),
            color: Colors.grey.shade100,
            border: Border.all(color: Colors.grey.shade300),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(15),
            child: url != null && url != "pending"
                ? Image.network(url, fit: BoxFit.cover)
                : const Center(child: Icon(Icons.image_search, color: Colors.grey)),
          ),
        ),
      ],
    );
  }

  void _copyToClipboard() {
    final data = '''
Title: ${widget.product['title']}
Price: PKR ${widget.product['price']}
Quantity: ${widget.product['quantity']}
Total: PKR ${widget.product['totalPrice']}
Customer Address: ${widget.product['address']}, ${widget.product['city']}
''';
    Clipboard.setData(ClipboardData(text: data)).then((_) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Order details copied!'), behavior: SnackBarBehavior.floating),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final status = widget.product['status'].toString().toLowerCase();
    final totalPrice = widget.product['totalPrice'] ?? (widget.product['quantity'] * widget.product['price']);

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        title: const Text("Order Details", style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.black),
        actions: [
          IconButton(
            onPressed: _copyToClipboard,
            icon: const Icon(Icons.content_copy_rounded, size: 20),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. IMAGE GALLERY SECTION
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _buildImagePreview(widget.product['image'], "Product Image"),
                  if (widget.product['receiptImage'] != "pending") ...[
                    const SizedBox(width: 16),
                    _buildImagePreview(widget.product['receiptImage'], "Shipping Receipt"),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 24),

            // 2. PRODUCT INFO CARD
            _buildSectionTitle("Items Info"),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(15),
                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10)],
              ),
              child: Column(
                children: [
                  _buildInfoRow("Product", widget.product['title'], isBold: true),
                  const Divider(),
                  _buildInfoRow("Unit Price", "PKR ${widget.product['price']}"),
                  _buildInfoRow("Quantity", "x${widget.product['quantity']}"),
                  _buildInfoRow("Status", status.toUpperCase(),
                      valueColor: status == 'completed' ? Colors.green : status == 'cancelled' ? Colors.red : Colors.orange),
                  if (status == 'cancelled' || status == 'returned')
                    _buildInfoRow("Reason", widget.product['reason'] ?? "N/A", valueColor: Colors.redAccent),
                  const Divider(),
                  _buildInfoRow("Total Amount", "PKR $totalPrice", valueColor: Colors.green, isBold: true),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // 3. SHIPPING INFO CARD
            _buildSectionTitle("Delivery Address"),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(15),
                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10)],
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      const Icon(Icons.location_on_outlined, color: Colors.green, size: 20),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          "${widget.product['address']}",
                          style: const TextStyle(fontSize: 14, height: 1.4),
                        ),
                      ),
                    ],
                  ),
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 12.0),
                    child: Divider(),
                  ),
                  _buildInfoRow("City", widget.product['city'] ?? "N/A"),
                  _buildInfoRow("Postal Code", widget.product['postalCode'] ?? "N/A"),
                ],
              ),
            ),
            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }
}