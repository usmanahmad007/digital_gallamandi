import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'ProductDetailsScreen.dart';

class SellerOrderScreen extends StatefulWidget {
  const SellerOrderScreen({super.key});

  @override
  State<SellerOrderScreen> createState() => _SellerOrderScreenState();
}

class _SellerOrderScreenState extends State<SellerOrderScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final List<String> _reasons = [
    'Product is not available',
    'Issue with delivery',
    'Pricing error',
    'Stock mismatch',
    'Other',
  ];
  String? _selectedReason;
  Future<String?> uploadReceiptImage() async {
    try{
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);

    if (pickedFile == null) return null; // No image selected

    File file = File(pickedFile.path);
    String fileName = "receipt_${DateTime.now().millisecondsSinceEpoch}.jpg";
    Reference storageRef = FirebaseStorage.instance.ref().child("receipts/$fileName");


      UploadTask uploadTask = storageRef.putFile(file);
      TaskSnapshot snapshot = await uploadTask;
      String downloadUrl = await snapshot.ref.getDownloadURL();
      return downloadUrl; // Return the uploaded image URL
    } catch (e) {
      print("Error uploading image: $e");
      return "pending";
    }
  }

  Future<void> _updateOrderImageStatus(
      String orderId,) async {
    try {
      String? imageUrl="pending";
       imageUrl= await uploadReceiptImage();

       if(imageUrl==null){
         setState(() {
           imageUrl="pending";
         });
       }

      await FirebaseFirestore.instance
          .collection('orders')
          .doc(orderId)
          .update({'receiptImage': imageUrl,});

    } catch (error) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to update image.')),
      );
    }
  }Future<void> _updateOrderStatus(
      String orderId, String newStatus, String reason) async {
    try {
      await FirebaseFirestore.instance
          .collection('orders')
          .doc(orderId)
          .update({'status': newStatus, 'reason': reason});
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Order status updated to $newStatus.')),
      );
    } catch (error) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to update order status.')),
      );
    }
  }

  Future<void> _showStatusUpdateDialog(
      String orderId, String currentStatus, productId, int quantity,String receiptImage) async {
    String newStatus;
    if (currentStatus == 'pending') {
      newStatus = 'in process';
    } else if (currentStatus == 'in process') {
      newStatus = 'completed';
    } else if (currentStatus == 'cancelled') {
      newStatus = 'cancelled';
    } else {
      return; // If status is already 'completed', no further updates are allowed
    }

    return showDialog<void>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Update Order Status'),
          content: Text('Do you want to mark this order as $newStatus?'),
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
                if (newStatus == 'cancelled') {
                  print("Cancelled");
                  Navigator.of(context).pop(); // Close the dialog
                  _showCancelDialog(orderId); // Update status to newStatus
                } else if (newStatus == 'completed') {

                  if(receiptImage=="pending"){
                    showDialog(
                        context: context,
                        builder: (BuildContext context) {
                          return AlertDialog(
                            title: const Text("Upload Shipment Receipt"),
                            content: const Text(
                                "Please upload the shipment receipt to mark the order as Complete"),
                            actions: [
                              TextButton(
                                onPressed: () {
                                  Navigator.of(context).pop(); // Close the dialog
                                  Navigator.of(context).pop();
                                },
                                child: const Text('Cancel',
                                    style: TextStyle(color: Colors.black)),
                              ),
                              ElevatedButton(
                                  style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.green),
                                  onPressed: () {
                                    Navigator.of(context).pop(); // Close the dialog
                                    Navigator.of(context).pop(); // Close the dialog

                                    _updateOrderImageStatus(orderId);
                                  },
                                  child: const Text('upload image',
                                      style:
                                      TextStyle(color: Colors.white)))
                            ],
                          );
                        });
                  } else {
                       Navigator.of(context).pop(); // Close the dialog
                       handleOrder(productId,quantity,orderId,newStatus);
                  }


                } else {
                  Navigator.of(context).pop(); // Close the dialog
                  _updateOrderStatus(orderId, newStatus, 'none');
                }
              },
              child: Text('Yes - $newStatus',
                  style: const TextStyle(color: Colors.white)),
            ),
          ],
        );
      },
    );
  }

  void handleOrderBalance(String productId, int soldQuantity) async {
    await updateSellerBalance(productId, soldQuantity);
  }

  Future<void> updateSellerBalance(String productId, int soldQuantity) async {
    try {
      final firestore = FirebaseFirestore.instance;

      // Fetch the product document
      final productRef = firestore.collection('products').doc(productId);
      final productSnapshot = await productRef.get();

      if (productSnapshot.exists) {
        print("GIFT1");
        // Get sellerId, price, and calculate total revenue for sold products
        final String sellerId = productSnapshot['sellerId'];
        final double pricePerUnit = double.parse(productSnapshot['price']);
        final double revenue = pricePerUnit * soldQuantity;

        // Reference to the seller's document
        final sellerRef = firestore.collection('saller').doc(sellerId);

        // Fetch the seller's current balance
        final sellerSnapshot = await sellerRef.get();

        if (sellerSnapshot.exists) {
          final double currentBalance =
              double.parse(sellerSnapshot['balance'].toString());

          // Update the seller's balance
          final double newBalance = currentBalance + revenue;
          await sellerRef.update({'balance': newBalance});

          print('Seller balance updated successfully!');
        } else {
          print('Seller with ID $sellerId does not exist!');
        }
      } else {
        print('Product with ID $productId does not exist!');
      }
    } catch (e) {
      print('Error updating seller balance: $e');
    }
  }

  void handleOrder(String productId, int soldQuantity, String orderId,
      String newStatus) async {
    await decrementProductQuantity(productId, soldQuantity, orderId, newStatus);
  }

  Future<void> decrementProductQuantity(String productId, int soldQuantity,
      String orderId, String newStatus) async {
    try {
      // Reference to the Firestore collection where the products are stored
      final productRef =
          FirebaseFirestore.instance.collection('products').doc(productId);

      // Fetch the current quantity of the product
      DocumentSnapshot productSnapshot = await productRef.get();

      if (productSnapshot.exists) {
        int currentQuantity = int.parse(productSnapshot['quantity']);

        // Ensure the quantity does not go below 0
        int newQuantity = currentQuantity - soldQuantity;
        if (newQuantity < 0) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('You do not have enough products quantity'),
            ),
          );
        } else {
          _updateOrderStatus(orderId, newStatus, 'none');

          handleOrderBalance(productId, soldQuantity);
        }

        // Update the product's quantity in Firestore
        await productRef.update({'quantity': newQuantity.toString()});

        print('Product quantity updated successfully!');
      } else {
        print('Product with ID $productId does not exist!');
      }
    } catch (e) {
      print('Error decrementing product quantity: $e');
    }
  }

  void _showCancelDialog(String orderId) {
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
                  contentPadding:
                      const EdgeInsets.symmetric(vertical: 15, horizontal: 5),
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
              child: const Text(
                'Cancel',
                style: TextStyle(color: Colors.black),
              ),
            ),
            Container(
              decoration: BoxDecoration(
                  color: Colors.green, borderRadius: BorderRadius.circular(25)),
              child: TextButton(
                onPressed: () {
                  if (_selectedReason != null) {
                    _updateOrderStatus(
                        orderId, 'cancelled', _selectedReason.toString());
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
                child: const Text(
                  'Submit',
                  style: TextStyle(color: Colors.black),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Seller Orders'),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('orders')
            .where('sellerId', isEqualTo: _auth.currentUser!.uid)
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
              final product =
                  orderData; // Assuming only one product per order as per your reference
              final totalPrice = orderData['totalPrice'];
              final orderDate = (orderData['orderDate'] as Timestamp).toDate();
              final status = orderData['status'];
              final productId = orderData['productId'];
              final orderId = orderData['orderId'];
              final receiptImage = orderData['receiptImage'];

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
                          style: const TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 16),
                        ),
                        const SizedBox(height: 5),
                        Text('Order Date: ${orderDate.toLocal()}',
                            style: const TextStyle(fontSize: 14)),
                        Text(
                          'Total Price: PKR${totalPrice.toStringAsFixed(2)}',
                          style: const TextStyle(fontSize: 14),
                        ),
                        Text(
                          'Status: $status',
                          style: TextStyle(
                            fontSize: 14,
                            color: status == 'completed'
                                ? Colors.green
                                : (status == 'cancelled'
                                    ? Colors.red
                                    : Colors.grey),
                          ),
                        ),
                        if (status == 'cancelled')
                          Text(
                            'Reason: ${orderData['reason']}',
                            style: TextStyle(
                              fontSize: 14,
                              color: status == 'cancelled'
                                  ? Colors.red
                                  : Colors.black,
                            ),
                          ),
                        const SizedBox(height: 10),
                        const Text(
                          'Product:',
                          style: TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 14),
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
                              contentPadding: EdgeInsets.zero,
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
                                'PKR${product['price'].toStringAsFixed(2)}',
                                style: const TextStyle(fontSize: 12),
                              ),
                              onTap: () {
                                // Navigate to ProductDetailsScreen
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) =>
                                        SellerProductDetailsScreen(
                                            product: product),
                                  ),
                                );
                              },
                            ),
                          ),
                        ),
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            if (status == 'pending' || status == 'in process')
                              Align(
                                alignment: Alignment.centerRight,
                                child: ElevatedButton(
                                  onPressed: () => _showStatusUpdateDialog(
                                      order.id,
                                      "cancelled",
                                      productId,
                                      product['quantity'],receiptImage),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.red,
                                  ),
                                  child: const Text(
                                    'Cancel Order',
                                    style: TextStyle(color: Colors.white),
                                  ),
                                ),
                              ),
                            const SizedBox(width: 10),
                            (status != 'completed' && status != 'cancelled')
                                ? Align(
                                    alignment: Alignment.centerRight,
                                    child: ElevatedButton(
                                      onPressed: () => _showStatusUpdateDialog(
                                          order.id,
                                          status,
                                          productId,
                                          product['quantity'],receiptImage),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: status != 'cancelled'
                                            ? Colors.green
                                            : Colors.grey,
                                      ),
                                      child: Text(
                                        status == 'pending'
                                            ? 'Start Processing'
                                            : 'Complete Order',
                                        style: const TextStyle(
                                            color: Colors.white),
                                      ),
                                    ),
                                  )
                                : Container(),
                          ],
                        )
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
