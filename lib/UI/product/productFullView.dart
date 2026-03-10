import 'package:carousel_slider/carousel_slider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:zrai_mart/UI/product/ProductReviewsWidget.dart';
import 'package:zrai_mart/UI/product/RelatedProductSlider.dart';

import '../chatScreen/chatSCreen.dart';

class Productfullview extends StatefulWidget {
  final List<String> imageUrls; // List of image URLs
  final String productName;
  final String shortDescription;
  final double price;
  final String categoryName;
  final String sellerId;
  final bool isRental;
  final id;
  final String rating;
  final String quantity;

  const Productfullview({
    super.key,
    required this.imageUrls,
    required this.productName,
    required this.shortDescription,
    required this.price,
    required this.categoryName,
    required this.sellerId,
    required this.isRental,
    required this.id,
    required this.rating, required this.quantity,
  });

  @override
  _ProductfullviewState createState() => _ProductfullviewState();
}

class _ProductfullviewState extends State<Productfullview> {
  int _currentImageIndex = 0;

  int _quantity = 1;

  int ratings=0;
  void _incrementQuantity() {
    setState(() {
      _quantity++;
    });
  }

  void _decrementQuantity() {
    setState(() {
      if (_quantity > 1) {
        _quantity--;
      }
    });
  }
  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    calRatingsLength();
  }
  Future<void> calRatingsLength() async {
    ratings = await getRatingListLength(widget.id);
    --ratings;
  }

  void _startChat() {
    final currentUserId = FirebaseAuth.instance.currentUser?.uid ?? '';
    if (currentUserId.isNotEmpty) {
      // Navigate to the chat screen when the user presses the message button
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => ChatScreen(
            productId: widget.id,
            productName: widget.productName,
            currentUserId: currentUserId,
            sellerId: widget.sellerId,
          ),
        ),
      );
    }
  }



  void _buyNow() {
    // Handle the buy now action
    // You might want to navigate to another screen or show a confirmation dialog
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Buying ${widget.productName} x$_quantity'),
        backgroundColor: Colors.green,
      ),
    );
  }

  void _showSnackbar(String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: color,
      ),
    );
  }

  Future<int> getRatingListLength(String productId) async {
    try {
      DocumentSnapshot productDoc = await FirebaseFirestore.instance
          .collection('products')
          .doc(productId)
          .get();

      if (productDoc.exists) {
        List<dynamic> ratingList = productDoc['rating'] ?? [];
        return ratingList.length;
      } else {
        return 0;
      }
    } catch (e) {
      print("Error getting rating length: $e");
      return 0;
    }
  }

  void _uploadProduct() async {
    print(widget.sellerId);

    try {
      final userId = FirebaseAuth.instance.currentUser?.uid;
      final cartRef = FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .collection('addToCart');

      // Check if the product already exists in the cart
      final existingProductQuery = await cartRef
          .where('title', isEqualTo: widget.productName)
          .where('sallerId', isEqualTo: widget.sellerId)
          .get();

      if (existingProductQuery.docs.isNotEmpty) {
        // If the product exists, update the quantity
        final existingProductDoc = existingProductQuery.docs.first;
        final currentQuantity = existingProductDoc['quantity'] ?? 1;

        await cartRef.doc(existingProductDoc.id).update({
          'quantity': currentQuantity + 1,
        });

        _showSnackbar('Product quantity updated successfully', Colors.green);
      } else {
        // If the product doesn't exist, add it to the cart
        await cartRef.add({
          'productId': widget.id,
          'title': widget.productName,
          'description': widget.shortDescription,
          'price': widget.price,
          'imageUrl': widget.imageUrls.toList(),
          'category': widget.categoryName,
          'sallerId': widget.sellerId,
          'isRental': false,
          'quantity': 1,
          'aQuantity': widget.quantity,
          'averageRating': widget.rating,
        });

        _showSnackbar('Product added to cart successfully', Colors.green);
      }
    } catch (e) {
      _showSnackbar('Product add to cart failed: $e', Colors.red);
    }
  }

  /* void _rentProduct() async {
    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(FirebaseAuth.instance.currentUser?.uid)
          .collection('rentals')
          .add({
        'title': widget.productName,
        'description': widget.shortDescription,
        'price': widget.price,
        'imageUrl': widget.imageUrl,
        'category': widget.categoryName,
        'sellerId': widget.sellerId,
        'rentalDate': DateTime.now().toIso8601String(),
      });
      _showSnackbar('Product rented successfully', Colors.blue);
    } catch (e) {
      _showSnackbar('Failed to rent product', Colors.red);
    }
  }*/

  @override
  Widget build(BuildContext context) {
    double totalPrice = widget.price * _quantity;
    final width = MediaQuery.of(context).size.width;

    final cartRef = FirebaseFirestore.instance
        .collection('users')
        .doc(FirebaseAuth.instance.currentUser!.uid)
        .collection('wishList');
    return Scaffold(
      appBar: AppBar(
        title: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            SizedBox(width: 150, child: Text(widget.productName)),
            Row(
              children: [
                IconButton(onPressed: _startChat, icon: const Icon(Icons.message)),
                FutureBuilder<DocumentSnapshot>(
                  future: cartRef.doc(widget.id).get(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const IconButton(
                        onPressed: null,
                        icon: Icon(Icons.favorite_border, color: Colors.grey),
                      );
                    }

                    final isInWishlist =
                        snapshot.data != null && snapshot.data!.exists;

                    return IconButton(
                      onPressed: () async {
                        try {
                          if (isInWishlist) {
                            // Remove from wishlist
                            await cartRef.doc(widget.id).delete();
                            setState(() {

                            });
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Removed from wishlist'),
                              ),
                            );
                          } else {
                            // Add to wishlist
                            await cartRef.doc(widget.id).set({
                              'productId': widget.id,
                              'addedAt': Timestamp.now(),
                            });
                            setState(() {

                            });
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Added to wishlist'),
                              ),
                            );
                          }
                        } catch (e) {
                          print("Error: $e");
                        }
                      },
                      icon: Icon(
                        isInWishlist
                            ? Icons.favorite
                            : Icons.favorite_border,
                        color: isInWishlist ? Colors.green : Colors.grey,
                      ),
                    );
                  },
                )
              ],
            )


          ],
        ),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              // Image Carousel
              if (widget.imageUrls.isNotEmpty)
                Column(
                  children: [
                    CarouselSlider(
                      items: widget.imageUrls.map((url) {
                        return ClipRRect(
                          borderRadius: BorderRadius.circular(8.0),
                          child: Image.network(
                            url,
                            fit: BoxFit.cover,
                            width: double.infinity,
                            height: 300,
                            loadingBuilder: (context, child, loadingProgress) {
                              if (loadingProgress == null) return child;
                              return Center(
                                child: CircularProgressIndicator(
                                  value: loadingProgress.expectedTotalBytes !=
                                          null
                                      ? loadingProgress.cumulativeBytesLoaded /
                                          loadingProgress.expectedTotalBytes!
                                      : null,
                                ),
                              );
                            },
                            errorBuilder: (context, error, stackTrace) =>
                                const Center(
                              child: Icon(Icons.broken_image,
                                  size: 50, color: Colors.red),
                            ),
                          ),
                        );
                      }).toList(),
                      options: CarouselOptions(
                        height: 300,
                        autoPlay: true,
                        enlargeCenterPage: true,
                        onPageChanged: (index, reason) {
                          setState(() {
                            _currentImageIndex = index;
                          });
                        },
                      ),
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: widget.imageUrls.asMap().entries.map((entry) {
                        return GestureDetector(
                          onTap: () => setState(() {
                            _currentImageIndex = entry.key;
                          }),
                          child: Container(
                            width: 8.0,
                            height: 8.0,
                            margin: const EdgeInsets.symmetric(
                                horizontal: 4.0, vertical: 8.0),
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: (Theme.of(context).brightness ==
                                          Brightness.dark
                                      ? Colors.white
                                      : Colors.black)
                                  .withOpacity(_currentImageIndex == entry.key
                                      ? 0.9
                                      : 0.4),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ],
                )
              else
                const Center(
                  child: Icon(Icons.broken_image, size: 50, color: Colors.grey),
                ),
              const SizedBox(height: 16.0),
              Text(
                widget.productName,
                style: const TextStyle(
                  fontSize: 24.0,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8.0),

              widget.isRental == false
                  ? Row(
                                  children: [
                  Icon(
                    widget.rating == '5.0'
                        ? Icons.star
                        : widget.rating == '0.0'
                        ? Icons.star_border
                        : Icons.star_half_sharp,
                    color: Colors.green,
                  ),
                  Text(
                    widget.rating,
                    style: TextStyle(
                      fontSize: 22.0,
                      fontWeight: FontWeight.bold,
                      color: Colors.green[700],
                    ),
                  ),

                  Text(' (${ratings.toString()} reviews)',style: const TextStyle(fontWeight: FontWeight.bold),)
                                  ],
                                )
                  : Container(),
              const SizedBox(height: 12.0),
              Container(
                height: 1,
                color: Colors.grey[400],
              ),
              const SizedBox(height: 12.0),

              Row(
                children: [
                  const Text(
                    'Category: ',
                    style: TextStyle(
                      fontSize: 18.0,
                      color: Colors.black,
                    ),
                  ),
                  Text(
                    widget.categoryName,
                    style: TextStyle(
                      fontSize: 18.0,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8.0),
              Text(
                'Description',
                style: TextStyle(
                    fontSize: 16.0,
                    color: Colors.grey[800],
                    fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8.0),

              Text(
                widget.shortDescription,
                style: TextStyle(
                  fontSize: 14.0,
                  color: Colors.grey[800],
                ),
              ),

              const SizedBox(height: 12.0),
              Container(
                height: 1,
                color: Colors.grey[400],
              ),
              const SizedBox(height: 12.0),

              Text( widget.isRental==false?
                'PKR: ${widget.price.toStringAsFixed(2)}/kg':'PKR: ${widget.price.toStringAsFixed(2)}/hr',
                style: TextStyle(
                  fontSize: 20.0,
                  fontWeight: FontWeight.bold,
                  color: Colors.green[700],
                ),
              ),const SizedBox(height: 8.0),
              widget.quantity!="0"?
              Row(
                children: [
                  const Text(
                    'Available Quantity: ',
                    style: TextStyle(
                      fontSize: 20.0,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                  ),Text(
                    widget.quantity,
                    style: TextStyle(
                      fontSize: 20.0,
                      fontWeight: FontWeight.bold,
                      color: Colors.green[700],
                    ),
                  ),
                ],
              ): widget.isRental==false? const Text(
                'Product out of Stock',
                style: TextStyle(
                  fontSize: 20.0,
                  fontWeight: FontWeight.bold,
                  color: Colors.red,
                ),
              ): Container(),
              const SizedBox(height: 16.0),


              Container(
                height: 1,
                color: Colors.grey[400],
              ),
              const SizedBox(height: 20,),

              const Padding(
                padding: EdgeInsets.symmetric(vertical: 10.0),
                child: Text(
                  "Recommended",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ),
              const SizedBox(height: 20,),
              RelatedProductsSlider(
                  category: widget.categoryName.toString(),
                  currentProductId: widget.id.toString()),
              const SizedBox(height: 20,),
              widget.isRental==false?
              ProductReviewsWidget(productId: widget.id.toString()): Container()
            ],
          ),
        ),
      ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.all(10),
        width: width / 0.9,
        child: widget.isRental
            ? SizedBox(
                width: width / 2.2,
                child: ElevatedButton(
                  onPressed: _startChat,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    padding: const EdgeInsets.symmetric(vertical: 15.0),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20.0),
                    ),
                  ),
                  child: const Text(
                    'Rent Now',
                    style: TextStyle(color: Colors.black),
                  ),
                ),
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  SizedBox(
                    width: width / 2.2,
                    child: ElevatedButton(
                      onPressed: _startChat,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.black,
                        padding: const EdgeInsets.symmetric(vertical: 15.0),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20.0),
                        ),
                      ),
                      child: const Text(
                        'contact us',
                        style: TextStyle(color: Colors.green),
                      ),
                    ),
                  ),
                  widget.isRental == false
                      ? SizedBox(
                          width: width / 2.2,
                          child:  ElevatedButton(
                            onPressed: widget.quantity!="0"? _uploadProduct: null,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.green,
                              padding:
                                  const EdgeInsets.symmetric(vertical: 15.0),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(20.0),
                              ),
                            ),
                            child: const Text(
                              'Add to cart',
                              style: TextStyle(color: Colors.black),
                            ),
                          ),
                        )
                      : Container(),
                ],
              ),
      ),
    );
  }
}
