import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:zrai_mart/UI/product/productFullView.dart';

class Cartscreen extends StatefulWidget {
  const Cartscreen({super.key});

  @override
  State<Cartscreen> createState() => _CartscreenState();
}

class _CartscreenState extends State<Cartscreen> {
  final User? currentUser = FirebaseAuth.instance.currentUser;

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Cart'),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('users')
            .doc(currentUser?.uid)
            .collection('addToCart')
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return const Center(child: Text('Something went wrong'));
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text('Your cart is empty'));
          }

          final cartItems = snapshot.data!.docs;
          double totalPrice = 0.0;

          // Calculate total price
          for (var item in cartItems) {
            final double productPrice = (item['price'] as num).toDouble();
            final int productQuantity = (item['quantity'] as num?)?.toInt() ?? 1;
            totalPrice += productPrice * productQuantity;
          }

          return Column(
            children: [
              Expanded(
                child: ListView.builder(
                  itemCount: cartItems.length,
                  itemBuilder: (context, index) {
                    final cartItem = cartItems[index];
                    final productTitle = cartItem['title'];
                    final description = cartItem['description'];
                    final category = cartItem['category'];
                    final productImageUrl = cartItem['imageUrl'];
                    final double productPrice = (cartItem['price'] as num).toDouble();
                    final int productQuantity = (cartItem['quantity'] as num?)?.toInt() ?? 1;
                    final double productTotalPrice = productPrice * productQuantity;

                    return GestureDetector(
                      onTap: (){
                        Navigator.push(context, MaterialPageRoute(builder: (context)=>Productfullview(imageUrl: productImageUrl, productName: productTitle, shortDescription: description, price: productPrice, categoryName: category,)));

                      },
                      child: Card(
                        color: Colors.green,
                        margin: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
                        child: ListTile(
                          leading: Image.network(
                            productImageUrl,
                            width: 50,
                            height: 50,
                            fit: BoxFit.cover,
                          ),
                          title: Text(productTitle),

                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  IconButton(
                                    icon: const Icon(Icons.remove),
                                    onPressed: () {
                                      if (productQuantity > 1) {
                                        _updateQuantity(cartItem.id, productQuantity - 1);
                                      }
                                    },
                                  ),
                                  Text('$productQuantity'),
                                  IconButton(
                                    icon: const Icon(Icons.add),
                                    onPressed: () {
                                      _updateQuantity(cartItem.id, productQuantity + 1);
                                    },
                                  ),
                                  const Spacer(),
                                  IconButton(
                                    icon: const Icon(Icons.delete),
                                    onPressed: () {
                                      _removeFromCart(cartItem.id);
                                    },
                                  ),
                                ],
                              ),
                              Text(
                                'Total: \$${productTotalPrice.toStringAsFixed(2)}',
                                style: const TextStyle(fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),

                        ),
                      ),
                    );
                  },
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Total:',
                      style: TextStyle(fontSize: 18.0, fontWeight: FontWeight.bold),
                    ),
                    Text(
                      '\$${totalPrice.toStringAsFixed(2)}',
                      style: const TextStyle(fontSize: 18.0, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),
              GestureDetector(
                onTap: () {
                  _showPaymentDialog(context);
                },
                child: Center(
                  child: Container(
                    width: width,
                    height: 50,
                    decoration: BoxDecoration(
                      color: Colors.green,
                      borderRadius: BorderRadius.circular(25),
                    ),
                    child: const Center(
                      child: Text(
                        "Buy now",
                        style: TextStyle(
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
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

  void _showPaymentDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Payment'),
          content: const Text('Proceed to payment?'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                // Implement payment logic here
                Navigator.of(context).pop();
              },
              child: const Text('Pay'),
            ),
          ],
        );
      },
    );
  }
}
