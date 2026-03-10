import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import 'AdminProductDetailsScreen.dart';

class AdminOrdersScreen extends StatefulWidget {
  const AdminOrdersScreen({super.key});

  @override
  State<AdminOrdersScreen> createState() => _AdminOrdersScreenState();
}

class _AdminOrdersScreenState extends State<AdminOrdersScreen> {
  final List<String> _reasons = [
    'Item not needed anymore',
    'Wrong item ordered',
    'Found a better price',
    'Delivery is delayed',
    'Fake Order',
    'Spam Product',
    'Price is too high',
    'Other'
  ];

  String? _selectedReason;

  Future<void> _updateOrderStatus(String orderId, String newStatus,String reason) async {
    try {
      await FirebaseFirestore.instance.collection('orders').doc(orderId).update({
        'status': newStatus,
        'reason': reason
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Order status updated to $newStatus.')),
      );
    } catch (error) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to update order status.')),
      );
    }
  }

  Future<void> _showCancelConfirmationDialog(String orderId, Map<String, dynamic> product) async {
    return showDialog<void>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Cancel Order'),
          content: const Text('Are you sure you want to cancel this order?'),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // Close the dialog
              },
              child: const Text('No', style: TextStyle(color: Colors.black)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
              onPressed: () {
               /* _updateOrderStatus(orderId, 'cancelled'); // Update status to cancelled
                Navigator.of(context).pop();*/ // Close the dialog
                Navigator.of(context).pop(); // Close the dialog

                _showCancelDialog(orderId,product);

              },
              child: const Text('Yes', style: TextStyle(color: Colors.white)),
            ),
          ],
        );
      },
    );
  }
  void _showCancelDialog(String orderId, Map<String, dynamic> product) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Cancel Order'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButtonFormField<String>(
                decoration: InputDecoration(
                  labelText: 'Reason for Cancellation',
                  labelStyle: const TextStyle(color: Colors.grey),
                  filled: true,
                  fillColor: Colors.green.withOpacity(0.1),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(25),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderSide: const BorderSide(color: Colors.green),
                    borderRadius: BorderRadius.circular(25),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                      vertical: 5, horizontal: 5),
                ),
                initialValue: _selectedReason,
                items: _reasons.map((reason) {
                  return DropdownMenuItem<String>(
                    value: reason,
                    child: Text(reason),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    _selectedReason = value;
                  });
                },
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please select a reason';
                  }
                  return null;
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context); // Close the dialog
              },
              child: const Text('Cancel',style: TextStyle(color: Colors.black),),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
              onPressed: () {
                if (_selectedReason != null) {
                  _updateOrderStatus(orderId, 'cancelled',_selectedReason.toString());
                  handleNotificationUpload(orderId,product['productId'],product['sellerId'],product['userId']);
                  Navigator.pop(context);

                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Order canceled: $_selectedReason'),
                    ),
                  );
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Please select a reason'),
                    ),
                  );
                }
              },
              child: const Text('Submit',style: TextStyle(color: Colors.black),),
            ),
          ],
        );
      },
    );
  }
  void handleNotificationUpload(String orderId,String productId,String sellerId,String userId) async {
    await uploadNotification(
      orderId: orderId,
      productId: productId,
      sellerId: sellerId,
      userId: userId,
    );
  }


  Future<void> uploadNotification({
    required String orderId,
    required String productId,
    required String sellerId,
    required String userId,
  }) async {
    try {
      final firestore = FirebaseFirestore.instance;

      // Create a new notification document with an auto-generated ID
      final notificationRef = firestore.collection('notifications').doc();

      // Data to upload
      final notificationData = {
        'orderId': orderId,
        'productId': productId,
        'sellerId': sellerId,
        'userId': userId,
        'sellerIsRead': false, // Default read status for the seller
        'userIsRead': false,   // Default read status for the user
        'timestamp': FieldValue.serverTimestamp(), // Firestore server timestamp
      };

      // Upload the data
      await notificationRef.set(notificationData);

      print('Notification uploaded successfully!');
    } catch (e) {
      print('Error uploading notification: $e');
    }
  }



  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Orders List'),
        /*actions: [
          IconButton(onPressed: (){
            Navigator.push(context, MaterialPageRoute(builder: (context)=>const AdminPanelScreen()));
          }, icon: Icon(Icons.article))
          
        ],*/
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('orders')
            .orderBy('timestamp', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return const Center(child: Text('Error loading orders.'));
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text('No orders found.'));
          }

          final orders = snapshot.data!.docs;

          return ListView.builder(
            itemCount: orders.length,
            itemBuilder: (context, index) {
              final order = orders[index];
              final orderData = order.data() as Map<String, dynamic>;
              final product = orderData; // Assuming only one product per order as per your reference
              final totalPrice = orderData['totalPrice'];
              final orderDate = (orderData['orderDate'] as Timestamp).toDate();
              final status = orderData['status'];
              final orderId = orderData['orderId'];

              return Card(
                elevation: 3,
                margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Colors.green.shade100, Colors.yellow],
                      begin: Alignment.topLeft,

                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Order ID: $orderId',
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                        ),
                        const SizedBox(height: 5),
                        Text('Order Date: ${orderDate.toLocal()}',
                            style: const TextStyle(fontSize: 14)),
                        Text(
                          'Total Price: \$${totalPrice.toStringAsFixed(2)}',
                          style: const TextStyle(fontSize: 14),
                        ), const Text(
                          'Delivery Time: 7 Days',
                          style: TextStyle(fontSize: 14),
                        ),
                        Text(
                          'Status: $status',
                          style: TextStyle(
                            fontSize: 14,
                            color: status == 'cancelled' ? Colors.red : Colors.black,
                          ),
                        ),
                        if(status=='cancelled')
                        Text(
                          'Reason: ${orderData['reason']}',
                          style: TextStyle(
                            fontSize: 14,
                            color: status == 'cancelled' ? Colors.red : Colors.black,
                          ),
                        ),
                        const SizedBox(height: 10),
                        const Text(
                          'Product:',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                        ),
                        const SizedBox(height: 5),
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 5),
                          child: Container(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [Colors.green.shade400, Colors.yellow],
                                begin: Alignment.centerLeft,
                                end: Alignment.centerRight,
                              ),
                              borderRadius: BorderRadius.circular(25),
                            ),
                            child: ListTile(
                              contentPadding: const EdgeInsets.all(8),
                              leading: product['image'] != null
                                  ? ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: Image.network(
                                  product['image'],
                                  width: 50,
                                  height: 50,
                                  fit: BoxFit.cover,
                                ),
                              )
                                  : const Icon(Icons.image_not_supported),
                              title: Text(
                                product['title'],
                                style: const TextStyle(fontSize: 14),
                              ),
                              subtitle: Text(
                                'Quantity: ${product['quantity']}',
                                style: const TextStyle(fontSize: 12),
                              ),
                              trailing: Text(
                                '\$${product['price'].toStringAsFixed(2)}',
                                style: const TextStyle(fontSize: 12),
                              ),
                              onTap: () {
                                // Navigate to ProductDetailsScreen
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => ProductDetailsScreen(product: product),
                                  ),
                                );
                              },
                            ),
                          ),
                        ),
                        const SizedBox(height: 10),
                        if (status != 'completed' /*&& status != 'in process'*/ && status != 'cancelled')
                          Align(
                            alignment: Alignment.centerRight,
                            child: ElevatedButton(
                              onPressed: () => _showCancelConfirmationDialog(order.id,product),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.green,
                              ),
                              child: const Text('Cancel Order', style: TextStyle(color: Colors.white)),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
