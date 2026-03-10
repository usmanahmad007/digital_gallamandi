import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:zrai_mart/UI/product/productFullView.dart';

import 'DeliveryFormScreen.dart';

class Cartscreen extends StatefulWidget {
  const Cartscreen({super.key});

  @override
  State<Cartscreen> createState() => _CartscreenState();
}

class _CartscreenState extends State<Cartscreen> {
  final User? currentUser = FirebaseAuth.instance.currentUser;
  bool loading=false;

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
                    final productImageUrl = List<String>.from(cartItem['imageUrl'] ?? []);
                    final double productPrice = (cartItem['price'] as num).toDouble();
                    final int productQuantity = (cartItem['quantity'] as num?)?.toInt() ?? 1;
                    final double productTotalPrice = productPrice * productQuantity;
                    final String sellerId = cartItem['sallerId'];
                    final bool isRental = cartItem['isRental'];
                    final id = cartItem['productId'];
                    final String rating=cartItem['averageRating'];
                    final String quantity=cartItem['aQuantity'].toString();

                    return GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => Productfullview(
                              imageUrls: productImageUrl,
                              productName: productTitle,
                              shortDescription: description,
                              price: productPrice,
                              categoryName: category,
                              sellerId: sellerId,
                              isRental: isRental,
                              id: id,
                              rating: rating,
                              quantity: quantity.toString(),
                            ),
                          ),
                        );
                      },
                      child: Card(
                        color: Colors.green,
                        margin: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
                        child: ListTile(
                          leading: Image.network(
                            productImageUrl[0],
                            width: 50,
                            height: 50,
                            fit: BoxFit.cover,
                          ),
                          title: Text(productTitle),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              QuantityControl(
                                availableQuantity: int.parse(quantity), // Maximum allowed quantity
                                initialQuantity: productQuantity, // Initial quantity
                                onQuantityChanged: (newQuantity) {
                                  _updateQuantity(cartItem.id, newQuantity); // Update function
                                },
                                onRemove: () {
                                  showProductBottomSheet(context,cartItem);
                                  //_removeFromCart(cartItem.id); // Remove from cart function
                                },
                              ),


                              /*Row(
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
                              ),*/
                              Text(
                                'Total: PKR${productTotalPrice.toStringAsFixed(2)}',
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
                      'PKR${totalPrice.toStringAsFixed(2)}',
                      style: const TextStyle(fontSize: 18.0, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),
              loading==false? GestureDetector(
                onTap: () async {
                  _showOrderDialog(cartItems,totalPrice.toString());
                  /*await _uploadOrder(cartItems);*/
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
              ):Container(),
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
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Center(
                child: Text("Remove From Cart?",style: TextStyle(color: Colors.black,fontSize: 22,fontWeight: FontWeight.bold),),
              ),
              const SizedBox(height: 10,),

              Container(
                height: 1,
                color: Colors.grey[300],
              ),
              const SizedBox(height: 10,),
              
              Row(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8), // Optional: Rounded corners
                    child: Image.network(
                      productImageUrl[0],
                      width: 100,
                      height: 100,
                      fit: BoxFit.cover,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded( // Ensures text fits dynamically
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.start,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          cartItem['title'],
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis, // Shows '...' for long text
                        ),
                        Text(
                          'PKR${productTotalPrice.toStringAsFixed(2)}/kg',
                          style: const TextStyle(fontSize: 16, color: Colors.green,fontWeight: FontWeight.bold),
                        ),Text(
                          'Qty: ${productQuantity.toString()}',
                          style: const TextStyle(fontSize: 16, color: Colors.green,fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ),
                ],
              ),



              const SizedBox(height: 16),
              const SizedBox(height: 10,),

              Container(
                height: 1,
                color: Colors.grey[300],
              ),
              const SizedBox(height: 10,),

              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  Expanded(
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.green[100]),
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Close',style: TextStyle(color: Colors.black),),
                    ),
                  ),
                  const SizedBox(width: 5,),
                  Expanded(
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                      onPressed: (){

                        _removeFromCart(cartItem.id);
                        Navigator.pop(context);
                      },
                      child: const Text('Remove',style: TextStyle(color: Colors.white),),
                    ),
                  ),
                ],
              )

            ],
          ),
        );
      },
    );
  }
  Future<void> _showOrderDialog(List<QueryDocumentSnapshot> cartItems, String stringAsFixed) async {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Confirm Order'),
          content: const Text('Do you want to proceed with the order?'),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                // Cancel the order
                Navigator.pop(context);

              },
              child: const Text('Cancel',style: TextStyle(color: Colors.black),),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
              onPressed: () {
                Navigator.pop(context); // Close the dialog
                // Navigate to the delivery form screen
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => DeliveryFormScreen(cartItems: cartItems,totalAmount: stringAsFixed,),
                  ),
                );
              },
              child: const Text('Complete',style: TextStyle(color: Colors.black),),
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
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    productQuantity = widget.initialQuantity;
  }

  void _startHolding(bool isIncreasing) {
    _timer?.cancel(); // Ensure no previous timer is running
    _timer = Timer.periodic(const Duration(milliseconds: 100), (timer) {
      setState(() {
        if (isIncreasing && productQuantity < widget.availableQuantity) {
          productQuantity++;
        } else if (!isIncreasing && productQuantity > 1) {
          productQuantity--;
        } else {
          _stopHolding(); // Stop if at limit
        }
      });
      widget.onQuantityChanged(productQuantity);
    });
  }

  void _stopHolding() {
    _timer?.cancel();
    _timer = null;
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        GestureDetector(
          onTapDown: (_) => _startHolding(false), // Decrease
          onTapUp: (_) => _stopHolding(),
          onTapCancel: () => _stopHolding(),
          child: const IconButton(
            icon: Icon(Icons.remove),
            onPressed: null, // GestureDetector handles the press
          ),
        ),
        Text('$productQuantity'),
        GestureDetector(
          onTapDown: (_) => _startHolding(true), // Increase
          onTapUp: (_) => _stopHolding(),
          onTapCancel: () => _stopHolding(),
          child: const IconButton(
            icon: Icon(Icons.add),
            onPressed: null, // GestureDetector handles the press
          ),
        ),
        const Spacer(),
        IconButton(
          icon: const Icon(Icons.delete),
          onPressed: widget.onRemove,
        ),
      ],
    );
  }
}
