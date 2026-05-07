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
    return Scaffold(
      backgroundColor: Colors.grey[50],
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
      // --- WRAP EVERYTHING IN USER STATUS CHECK ---
      body: StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance.collection('users').doc(currentUser?.uid).snapshots(),
        builder: (context, userSnapshot) {
          if (userSnapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: Colors.green));
          }

          final userData = userSnapshot.data?.data() as Map<String, dynamic>?;
          final String status = userData?['userStatus'] ?? 'pending';

          // 1. Check if user is approved
          if (status != 'approved') {
            return _buildRestrictedUI(status);
          }

          // 2. If approved, show the actual Cart Stream
          return StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('users')
                .doc(currentUser?.uid)
                .collection('addToCart')
                .snapshots(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator(color: Colors.green));
              }

              // ... keep your existing "empty cart" and "ListBuilder" logic here ...
              if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                return _buildEmptyCartUI();
              }

              final cartItems = snapshot.data!.docs;
              double totalPrice = 0.0;
              for (var item in cartItems) {
                totalPrice += (item['price'] as num).toDouble() * ((item['quantity'] as num?)?.toInt() ?? 1);
              }

              return Column(
                children: [
                  // ... keep your existing ListView and Checkout Summary Section ...
                ],
              );
            },
          );
        },
      ),
    );
  }

  // Helper widget to show when user is blocked/restricted
  Widget _buildRestrictedUI(String status) {
    bool isBlocked = status == 'blocked';
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(30.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              isBlocked ? Icons.block_flipped : Icons.lock_clock_rounded,
              size: 100,
              color: isBlocked ? Colors.red[300] : Colors.amber[400],
            ),
            const SizedBox(height: 24),
            Text(
              isBlocked ? "Cart Access Blocked" : "Access Restricted",
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Text(
              isBlocked
                  ? "Your account has been suspended. You cannot view your cart or place orders."
                  : "Your account is currently $status. Please wait for admin approval to use the cart.",
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey[600], fontSize: 15),
            ),
          ],
        ),
      ),
    );
  }

  // Extracted your empty cart UI for cleaner code
  Widget _buildEmptyCartUI() {
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