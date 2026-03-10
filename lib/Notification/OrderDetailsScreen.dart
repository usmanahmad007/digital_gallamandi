import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class OrderDetailsScreen extends StatelessWidget {
  final String orderId;
  final String productId;

  const OrderDetailsScreen({super.key, required this.orderId, required this.productId});

  @override
  Widget build(BuildContext context) {
    final firestore = FirebaseFirestore.instance;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Order Details'),
      ),
      body: FutureBuilder<DocumentSnapshot>(
        future: firestore.collection('orders').doc(orderId).get(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final orderData = snapshot.data!.data() as Map<String, dynamic>;

          return Padding(
            padding: const EdgeInsets.all(16.0),
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildReadOnlyField('Title', orderData['title']),
                  const SizedBox(height: 10),
                  _buildReadOnlyField('Price', '\$${orderData['price']}'),
                  const SizedBox(height: 10),
                  _buildReadOnlyField('Quantity', '${orderData['quantity']}'),
                  const SizedBox(height: 10),
                  _buildReadOnlyField(
                    'Total',
                    'PKR: ${(orderData['price'] * orderData['quantity']).toStringAsFixed(2)}',
                  ),
                  const SizedBox(height: 10),
                  _buildReadOnlyField('Reason', orderData['reason']),
                  const SizedBox(height: 10),
                  _buildReadOnlyField('Status', orderData['status']),
                  const SizedBox(height: 10),
                  _buildReadOnlyField('Address', orderData['address']),
                  const SizedBox(height: 10),
                  _buildReadOnlyField('City', orderData['city']),
                  const SizedBox(height: 10),
                  _buildReadOnlyField('Postal Code', orderData['postalCode']),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

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
}
