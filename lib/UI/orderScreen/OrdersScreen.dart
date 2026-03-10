import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import 'ProductDetailsScreen.dart';

class Ordersscreen extends StatefulWidget {
  const Ordersscreen({super.key});

  @override
  State<Ordersscreen> createState() => _OrdersscreenState();
}

class _OrdersscreenState extends State<Ordersscreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;


  int selectedRating = 0;
  final List<String> _reasons = [
    'Item not needed anymore',
    'Wrong item ordered',
    'Found a better price',
    'Delivery is delayed',
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

  Future<void> _showCancelConfirmationDialog(String orderId) async {
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
                _showCancelDialog(orderId);
              },
              child: const Text('Yes', style: TextStyle(color: Colors.white)),
            ),
          ],
        );
      },
    );
  }Future<void> _showDeletelConfirmationDialog(String orderId) async {
    return showDialog<void>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Delete Order'),
          content: const Text('Are you sure you want to delete this order?'),
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
                deleteOrder(orderId);
                Navigator.of(context).pop();
              },
              child: const Text('Yes', style: TextStyle(color: Colors.white)),
            ),
          ],
        );
      },
    );
  }

  Future<void> _addRating(String productId, String orderId) async {
    TextEditingController reviewController = TextEditingController();
    return showDialog<void>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text("Rate this Product"),
          content: SingleChildScrollView(
            child: StatefulBuilder(
              builder: (BuildContext context, StateSetter setDialogState) {
                return Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text("Select a rating:", style: TextStyle(fontSize: 16)),
                    const SizedBox(height: 10),
                    SizedBox(
                      height: 50, // Set the height to fit the stars properly
                      child: GridView.builder(
                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 5, // Display exactly 5 stars in one row
                          mainAxisSpacing: 0, // Vertical spacing (not needed here)
                          crossAxisSpacing: 4.0, // Horizontal spacing between stars
                          childAspectRatio: 1, // Keep the icons square
                        ),
                        physics: const NeverScrollableScrollPhysics(), // Disable scrolling
                        itemCount: 5,
                        itemBuilder: (context, index) {
                          return IconButton(
                            onPressed: () {
                              setDialogState(() {
                                selectedRating = index + 1; // Update the selected rating
                              });
                              Navigator.pop(context);
                              _addRating(productId,orderId);

                            },
                            icon: Icon(
                              Icons.star,
                              color: selectedRating > index
                                  ? Colors.amber
                                  : Colors.grey,
                              size: 30, // Star size
                            ),
                            padding: EdgeInsets.zero, // Remove default padding
                            constraints: const BoxConstraints(
                              minWidth: 20,
                              minHeight: 20,
                            ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 20),
                    TextField(
                      controller: reviewController,
                      maxLines: 3,
                      decoration: const InputDecoration(
                        labelText: "Write a review (optional)",
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context); // Close dialog without rating
              },
              child: const Text("Cancel"),
            ),
            ElevatedButton(
              onPressed: selectedRating == 0
                  ? null // Disable button if no rating is selected
                  : () {
                Navigator.pop(context); // Close dialog after submission
                // If rating is selected, submit the rating
                String review = reviewController.text.trim(); // Get review text
               // await uploadRating(productId, selectedRating);

               CallTheMethod(productId,orderId,review);
              },
              child: const Text("Submit"),
            ),
          ],
        );
      },
    );
  }
  Future<void> updateRated(String orderId)async {
    try {
      // Reference to the orders collection in Firestore
      CollectionReference orders = FirebaseFirestore.instance.collection('orders');

      // Update the rated field and store the rating in the order document
      await orders.doc(orderId).update({
        'rated': true, // Mark the order as rated
      });

      print("Order rating status updated successfully.");
    } catch (e) {
      print("Error updating order rating status: $e");
    }
  }
  Future<void> deleteOrder(String orderId)async {
    try {
      // Reference to the orders collection in Firestore
      CollectionReference orders = FirebaseFirestore.instance.collection('orders');

      // Update the rated field and store the rating in the order document
    await orders.doc(orderId).delete();

      print("Order Deleted successfully.");
    } catch (e) {
      print("Error Deleting: $e");
    }
  }




 /* Future<void> uploadRating(String productId, int rating) async {
    try {
      final productRef = _firestore.collection('products').doc(productId);

      // Get the product document
      final productDoc = await productRef.get();

      if (productDoc.exists) {
        // Update existing ratings
        List<dynamic> ratings = productDoc.data()?['rating'] ?? [];

        // Add the new rating (stored as a string)
        ratings.add(rating.toString());

        // Calculate the new average rating
        double averageRating = ratings
            .map((rating) => double.tryParse(rating.toString()) ?? 0.0)
            .fold<double>(0.0, (sum, rating) => sum + rating) / ratings.length;
        // Update Firestore document
        await productRef.update({
          'rating': ratings,
          'averageRating': averageRating.toString(),
        });
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error uploading rating')),
        );
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Rating submitted successfully!')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error uploading rating: $e')),
      );
    }
  }*/ 
  Future<void> uploadRatingWithReview(String productId, int rating, String review) async {
    try {
      final productRef = _firestore.collection('products').doc(productId);
      final reviewsRef = productRef.collection('reviews');
      if(review!="" && review!=" "){
        await reviewsRef.add({
          'userId': _auth.currentUser!.uid,
          'rating': rating,
          'review': review ?? '', // Add review or an empty string if null
          'timestamp': FieldValue.serverTimestamp(),
        });
      }

      // Get the product document
      final productDoc = await productRef.get();

      if (productDoc.exists) {
        // Update existing ratings
        List<dynamic> ratings = productDoc.data()?['rating'] ?? [];
        String avgRat=productDoc['averageRating'];

        // Add the new rating (stored as a string)
        ratings.add(rating.toString());

        // Calculate the new average rating
        print(ratings.length-1);
        if (ratings.isNotEmpty && ratings.length == 1 && avgRat=='0.0') {
          ratings.removeAt(0);
        }
        int rat=ratings.length-1;
        double averageRating = ratings
            .map((rating) => double.tryParse(rating.toString()) ?? 0.0)
            .fold<double>(0.0, (sum, rating) => sum + rating) / rat;
        // Update Firestore document
        await productRef.update({
          'rating': ratings,
          'averageRating': averageRating.toStringAsFixed(1),
        });
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Error uploading rating')),
        );
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Rating submitted successfully!')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error uploading rating: $e')),
      );
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
                Navigator.pop(context); // Close the dialog
              },
              child: const Text('Cancel',style: TextStyle(color: Colors.black),),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
              onPressed: () {
                if (_selectedReason != null) {
                  _updateOrderStatus(orderId, 'cancelled',_selectedReason.toString());
                  Navigator.pop(context);
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Your Orders'),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('orders')
            .where('userId', isEqualTo: _auth.currentUser!.uid)
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
              final rated= product['rated'];

              return GestureDetector(
                onLongPress: (){
                  _showDeletelConfirmationDialog(orderId);
                },
                child: Card(
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
                            'Total Price: PKR${totalPrice.toStringAsFixed(2)}',
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
                                  'PKR: ${product['totalPrice'].toStringAsFixed(2)}',
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
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                if (status != 'completed' && status != 'in process' && status != 'cancelled')
                                  Align(
                                  alignment: Alignment.centerRight,
                                  child: ElevatedButton(
                                    onPressed: () => _showCancelConfirmationDialog(order.id),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.green,
                                    ),
                                    child: const Text('Cancel Order', style: TextStyle(color: Colors.white)),
                                  ),
                                ),
                                if (status == 'completed' && rated==false)
                                  Align(
                                  alignment: Alignment.centerRight,
                                  child: ElevatedButton(
                                    onPressed: () => _addRating(product['productId'],orderId),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.green,
                                    ),
                                    child: const Text('Add Rating', style: TextStyle(color: Colors.white)),
                                  ),
                                ),
                              ],
                            ),
                        ],
                      ),
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

  Future<void> CallTheMethod(String productId,String orderId,String review) async {
    await uploadRatingWithReview(productId, selectedRating, review);
    await updateRated(orderId);
  }

}
