import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:zrai_mart/UI/product/CustomerProductFullView.dart';
import 'DeliveryFormScreen.dart';

class Cartscreen extends StatefulWidget {
  const Cartscreen({super.key});

  @override
  State<Cartscreen> createState() => _CartscreenState();
}

class _CartscreenState extends State<Cartscreen> {
  final User? currentUser = FirebaseAuth.instance.currentUser;
  bool loading = false;

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;

    return Scaffold(
      backgroundColor: Colors.grey[50], // Light background for contrast
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.black),
        title: const Text(
          'My Cart',
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('users')
            .doc(currentUser?.uid)
            .collection('addToCart')
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: Colors.green));
          }
          if (snapshot.hasError) {
            return const Center(child: Text('Something went wrong'));
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.shopping_cart_outlined, size: 80, color: Colors.grey[300]),
                  const SizedBox(height: 16),
                  const Text('Your cart is empty', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500)),
                ],
              ),
            );
          }

          final cartItems = snapshot.data!.docs;
          double totalPrice = 0.0;

          for (var item in cartItems) {
            final double productPrice = (item['price'] as num).toDouble();
            final int productQuantity = (item['quantity'] as num?)?.toInt() ?? 1;
            totalPrice += productPrice * productQuantity;
          }

          return Column(
            children: [
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  itemCount: cartItems.length,
                  itemBuilder: (context, index) {
                    final cartItem = cartItems[index];
                    final productTitle = cartItem['title'];
                    final description = cartItem['description'];
                    final category = cartItem['category'];
                    final productImageUrl = List<String>.from(cartItem['imageUrl'] ?? []);
                    final double productPrice = (cartItem['price'] as num).toDouble();
                    final int productQuantity = (cartItem['quantity'] as num?)?.toInt() ?? 1;
                    final double productTotalPrice = productPrice * productQuantity;
                    final String sellerId = cartItem['sallerId'];
                    final bool isRental = cartItem['isRental'];
                    final id = cartItem['productId'];
                    final String rating = cartItem['averageRating'];
                    final String quantity = cartItem['aQuantity'].toString();

                    return Container(
                      margin: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(15),
                        boxShadow: [
                          BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4))
                        ],
                      ),
                      child: InkWell(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => customerProductfullview(
                                imageUrls: productImageUrl,
                                productName: productTitle,
                                shortDescription: description,
                                price: productPrice,
                                categoryName: category,
                                sellerId: sellerId,
                                isRental: isRental,
                                id: id,
                                rating: rating,
                                quantity: quantity,
                              ),
                            ),
                          );
                        },
                        child: Padding(
                          padding: const EdgeInsets.all(12.0),
                          child: Row(
                            children: [
                              ClipRRect(
                                borderRadius: BorderRadius.circular(12),
                                child: Image.network(
                                  productImageUrl[0],
                                  width: 85,
                                  height: 85,
                                  fit: BoxFit.cover,
                                ),
                              ),
                              const SizedBox(width: 15),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      productTitle,
                                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      'PKR ${productPrice.toStringAsFixed(2)}',
                                      style: TextStyle(color: Colors.grey[600], fontSize: 13),
                                    ),
                                    const SizedBox(height: 8),
                                    QuantityControl(
                                      availableQuantity: int.parse(quantity),
                                      initialQuantity: productQuantity,
                                      onQuantityChanged: (newQuantity) {
                                        _updateQuantity(cartItem.id, newQuantity);
                                      },
                                      onRemove: () {
                                        showProductBottomSheet(context, cartItem);
                                      },
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),

              // --- Checkout Summary Section ---
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
                  boxShadow: [
                    BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, -5))
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Subtotal', style: TextStyle(fontSize: 16, color: Colors.grey)),
                        Text('PKR ${totalPrice.toStringAsFixed(2)}', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                      ],
                    ),
                    const SizedBox(height: 20),
                    if (!loading)
                      SizedBox(
                        width: double.infinity,
                        height: 55,
                        child: ElevatedButton(
                          onPressed: () => _showOrderDialog(cartItems, totalPrice.toString()),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                            elevation: 0,
                          ),
                          child: const Text(
                            "CHECKOUT",
                            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16, letterSpacing: 1),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  void showProductBottomSheet(BuildContext context, final cartItem) {
    final double productPrice = (cartItem['price'] as num).toDouble();
    final int productQuantity = (cartItem['quantity'] as num?)?.toInt() ?? 1;
    final double productTotalPrice = productPrice * productQuantity;
    final productImageUrl = List<String>.from(cartItem['imageUrl'] ?? []);

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
          ),
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(10))),
              const SizedBox(height: 20),
              const Text("Remove Item?", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              const SizedBox(height: 20),
              Row(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.network(productImageUrl[0], width: 80, height: 80, fit: BoxFit.cover),
                  ),
                  const SizedBox(width: 15),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(cartItem['title'], style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                        const SizedBox(height: 5),
                        Text('PKR ${productTotalPrice.toStringAsFixed(2)}', style: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 25),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 15),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Keep it', style: TextStyle(color: Colors.black)),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.redAccent,
                        padding: const EdgeInsets.symmetric(vertical: 15),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      onPressed: () {
                        _removeFromCart(cartItem.id);
                        Navigator.pop(context);
                      },
                      child: const Text('Remove', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
            ],
          ),
        );
      },
    );
  }

  Future<void> _showOrderDialog(List<QueryDocumentSnapshot> cartItems, String total) async {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Text('Confirm Order'),
          content: const Text('Ready to proceed with your order details?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Not yet', style: TextStyle(color: Colors.grey)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              onPressed: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => DeliveryFormScreen(cartItems: cartItems, totalAmount: total),
                  ),
                );
              },
              child: const Text('Proceed', style: TextStyle(color: Colors.white)),
            ),
          ],
        );
      },
    );
  }

  void _updateQuantity(String docId, int newQuantity) {
    FirebaseFirestore.instance
        .collection('users')
        .doc(currentUser?.uid)
        .collection('addToCart')
        .doc(docId)
        .update({'quantity': newQuantity});
  }

  void _removeFromCart(String docId) {
    FirebaseFirestore.instance
        .collection('users')
        .doc(currentUser?.uid)
        .collection('addToCart')
        .doc(docId)
        .delete();
  }
}

class QuantityControl extends StatefulWidget {
  final int availableQuantity;
  final int initialQuantity;
  final Function(int) onQuantityChanged;
  final Function() onRemove;

  const QuantityControl({
    super.key,
    required this.availableQuantity,
    required this.initialQuantity,
    required this.onQuantityChanged,
    required this.onRemove,
  });

  @override
  _QuantityControlState createState() => _QuantityControlState();
}

class _QuantityControlState extends State<QuantityControl> {
  late int productQuantity;
  Timer? _continuousTimer;

  @override
  void initState() {
    super.initState();
    productQuantity = widget.initialQuantity;
  }

  // Logic to handle the mathematical change
  void _changeQuantity(bool isIncreasing) {
    setState(() {
      if (isIncreasing && productQuantity < widget.availableQuantity) {
        productQuantity++;
      } else if (!isIncreasing && productQuantity > 1) {
        productQuantity--;
      }
    });
    widget.onQuantityChanged(productQuantity);
  }

  // Logic for continuous increment/decrement
  void _startContinuousChange(bool isIncreasing) {
    _stopContinuousChange(); // Safety clear
    _continuousTimer = Timer.periodic(const Duration(milliseconds: 100), (timer) {
      if (isIncreasing && productQuantity < widget.availableQuantity) {
        _changeQuantity(true);
      } else if (!isIncreasing && productQuantity > 1) {
        _changeQuantity(false);
      } else {
        _stopContinuousChange(); // Stop if limit reached
      }
    });
  }

  void _stopContinuousChange() {
    _continuousTimer?.cancel();
    _continuousTimer = null;
  }

  @override
  void dispose() {
    _stopContinuousChange();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(10)
          ),
          child: Row(
            children: [
              // DECREMENT BUTTON
              GestureDetector(
                onTap: () => _changeQuantity(false), // Single tap
                onLongPressStart: (_) => _startContinuousChange(false), // Hold start
                onLongPressEnd: (_) => _stopContinuousChange(), // Hold end
                child: const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  child: Icon(Icons.remove, size: 20, color: Colors.black54),
                ),
              ),

              Text(
                '$productQuantity',
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),

              // INCREMENT BUTTON
              GestureDetector(
                onTap: () => _changeQuantity(true), // Single tap
                onLongPressStart: (_) => _startContinuousChange(true), // Hold start
                onLongPressEnd: (_) => _stopContinuousChange(), // Hold end
                child: const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  child: Icon(Icons.add, size: 20, color: Colors.black54),
                ),
              ),
            ],
          ),
        ),
        const Spacer(),
        IconButton(
          icon: const Icon(Icons.delete_outline, color: Colors.redAccent, size: 22),
          onPressed: widget.onRemove,
        ),
      ],
    );
  }
}