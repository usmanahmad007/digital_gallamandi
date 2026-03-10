import 'package:flutter/material.dart';

class ProductDetailsScreen extends StatefulWidget {
  final Map<String, dynamic> product;

  const ProductDetailsScreen({super.key, required this.product});

  @override
  State<ProductDetailsScreen> createState() => _ProductDetailsScreenState();
}

class _ProductDetailsScreenState extends State<ProductDetailsScreen> {
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
          borderSide: const BorderSide(color: Colors.green)
        ),
        focusedBorder: OutlineInputBorder(
          borderSide: const BorderSide(color: Colors.green),
          borderRadius: BorderRadius.circular(25),
        ),
        contentPadding: const EdgeInsets.symmetric(vertical: 15, horizontal: 20),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.product['title']),
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
                border: Border.all(
                  color: Colors.black
                )
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
            _buildReadOnlyField('Title', widget.product['title']),
            const SizedBox(height: 20),
            _buildReadOnlyField('Price', 'PKR${widget.product['price'].toStringAsFixed(2)}'),
            const SizedBox(height: 20),
            _buildReadOnlyField('Quantity', widget.product['quantity'].toString()),
            const SizedBox(height: 20),
            _buildReadOnlyField('Total Price', (widget.product['quantity'] * widget.product['price']).toString()),
            const SizedBox(height: 20),
            _buildReadOnlyField('Delivery Time', '7 Days'),
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
          ],
        ),
      ),
    );
  }
}
