import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class SellerProductDetailsScreen extends StatefulWidget {
  final Map<String, dynamic> product;

  const SellerProductDetailsScreen({super.key, required this.product});

  @override
  State<SellerProductDetailsScreen> createState() =>
      _SellerProductDetailsScreenState();
}

class _SellerProductDetailsScreenState
    extends State<SellerProductDetailsScreen> {
  Widget _buildReadOnlyField(String label, String value) {
    return TextFormField(
      initialValue: value,
      readOnly: true,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: Colors.grey),
        filled: true,
        fillColor: Colors.green.withOpacity(0.1),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(25),
          borderSide: const BorderSide(color: Colors.green),
        ),
        focusedBorder: OutlineInputBorder(
          borderSide: const BorderSide(color: Colors.green),
          borderRadius: BorderRadius.circular(25),
        ),
        contentPadding: const EdgeInsets.symmetric(vertical: 15, horizontal: 20),
      ),
    );
  }

  void _copyToClipboard() {
    final data = '''
Title: ${widget.product['title']}
Price: PKR${widget.product['price'].toStringAsFixed(2)}
Quantity: ${widget.product['quantity']}
Total Price: ${widget.product['quantity'] * widget.product['price']}
Address: ${widget.product['address']}
City: ${widget.product['city']}
Postal Code: ${widget.product['postalCode']}
''';
    Clipboard.setData(ClipboardData(text: data)).then((_) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Data copied to clipboard!')),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.product['title']),
        actions: [
          IconButton(onPressed: _copyToClipboard, icon: const Icon(
            Icons.copy
          ))
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              decoration: BoxDecoration(
                color: Colors.green.withOpacity(0.1),
                borderRadius: BorderRadius.circular(25),
                border: Border.all(color: Colors.black),
              ),
              child: widget.product['image'] != null
                  ? Center(
                child: Image.network(
                  widget.product['image'],
                  height: 200,
                  fit: BoxFit.cover,
                ),
              )
                  : const Center(
                child: Icon(
                  Icons.image_not_supported,
                  size: 100,
                ),
              ),
            ),
            const SizedBox(height: 20),

            widget.product['receiptImage']!="pending"?Container(
              decoration: BoxDecoration(
                color: Colors.green.withOpacity(0.1),
                borderRadius: BorderRadius.circular(25),
                border: Border.all(color: Colors.black),
              ),
              child: widget.product['receiptImage'] != null
                  ? Center(
                child: Image.network(
                  widget.product['receiptImage'],
                  height: 200,
                  fit: BoxFit.cover,
                ),
              )
                  : const Center(
                child: Icon(
                  Icons.image_not_supported,
                  size: 100,
                ),
              ),
            ): Container(),
            const SizedBox(height: 20),
            _buildReadOnlyField('Title', widget.product['title']),
            const SizedBox(height: 20),
            _buildReadOnlyField(
                'Price', 'PKR: ${widget.product['price'].toStringAsFixed(2)}'),
            const SizedBox(height: 20),
            _buildReadOnlyField('Quantity', widget.product['quantity'].toString()),
            const SizedBox(height: 20),
            _buildReadOnlyField(
                'Total Price',
                (widget.product['quantity'] * widget.product['price'])
                    .toString()),
            const SizedBox(height: 20),
            _buildReadOnlyField('Status', widget.product['status']),
            if(widget.product['status'].toString()=='cancelled')
            const SizedBox(height: 20),
            if(widget.product['status'].toString()=='cancelled')
              _buildReadOnlyField('Reason', widget.product['reason']),
            const SizedBox(height: 20),
            _buildReadOnlyField('Address', widget.product['address']),
            const SizedBox(height: 20),
            _buildReadOnlyField('City', widget.product['city']),
            const SizedBox(height: 20),
            _buildReadOnlyField('Postal Code', widget.product['postalCode']),
            const SizedBox(height: 20),

          ],
        ),
      ),
    );
  }
}
