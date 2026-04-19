import 'package:carousel_slider/carousel_slider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:zrai_mart/UI/cartScreen/CartScreen.dart';
import 'package:zrai_mart/UI/product/ProductReviewsWidget.dart';
import 'package:zrai_mart/UI/product/RelatedProductSlider.dart';
import '../../saller center/product/seller_state_widget.dart';
import '../../saller center/storeView/StorePreviewScreen.dart';
import '../chatScreen/chatSCreen.dart';

class customerProductfullview extends StatefulWidget {
  final List<String> imageUrls;
  final String productName;
  final String shortDescription;
  final double price;
  final String categoryName;
  final String sellerId;
  final bool isRental;
  final dynamic id;
  final String rating;
  final String quantity;

  const customerProductfullview({
    super.key,
    required this.imageUrls,
    required this.productName,
    required this.shortDescription,
    required this.price,
    required this.categoryName,
    required this.sellerId,
    required this.isRental,
    required this.id,
    required this.rating,
    required this.quantity,
  });

  @override
  _customerProductfullviewState createState() => _customerProductfullviewState();
}

class _customerProductfullviewState extends State<customerProductfullview> {
  int _currentImageIndex = 0;
  int ratings = 0;

  @override
  void initState() {
    super.initState();
    calRatingsLength();
  }

  Future<void> calRatingsLength() async {
    int count = await getRatingListLength(widget.id);
    if (mounted) {
      setState(() {
        ratings = count > 0 ? count - 1 : 0;
      });
    }
  }

  void _showModernToast(String message, bool isSuccess, {bool showCartButton = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        elevation: 0,
        behavior: SnackBarBehavior.floating,
        backgroundColor: Colors.transparent, // Keeps the custom container shape visible
        duration: const Duration(seconds: 3),
        content: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            // Premium Gradient Background
            gradient: LinearGradient(
              colors: isSuccess
                  ? [const Color(0xFF1B5E20), const Color(0xFF43A047)]
                  : [const Color(0xFFB71C1C), const Color(0xFFEF5350)],
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
            ),
            borderRadius: BorderRadius.circular(16),
            // Subtle border for "Glass" effect
            border: Border.all(color: Colors.white.withOpacity(0.2), width: 1.5),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.3),
                blurRadius: 12,
                offset: const Offset(0, 6),
              )
            ],
          ),
          child: Row(
            children: [
              // Icon with a soft background circle
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  isSuccess ? Icons.done_all_rounded : Icons.priority_high_rounded,
                  color: Colors.white,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  message,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                    letterSpacing: 0.3,
                  ),
                ),
              ),
             /* if (showCartButton)
                Padding(
                  padding: const EdgeInsets.only(left: 8.0),
                  child: InkWell(
                    onTap: () {
                      ScaffoldMessenger.of(context).hideCurrentSnackBar();
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const Cartscreen()),
                      );
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        "VIEW CART",
                        style: TextStyle(
                          color: isSuccess ? const Color(0xFF1B5E20) : const Color(0xFFB71C1C),
                          fontWeight: FontWeight.w800,
                          fontSize: 11,
                        ),
                      ),
                    ),
                  ),
                ),*/
            ],
          ),
        ),
      ),
    );
  }

  Future<int> getRatingListLength(String productId) async {
    try {
      DocumentSnapshot productDoc = await FirebaseFirestore.instance.collection('products').doc(productId).get();
      if (productDoc.exists) {
        List<dynamic> ratingList = productDoc['rating'] ?? [];
        return ratingList.length;
      }
      return 0;
    } catch (e) {
      return 0;
    }
  }

  void _uploadProduct() async {
    try {
      final userId = FirebaseAuth.instance.currentUser?.uid;
      final cartRef = FirebaseFirestore.instance.collection('users').doc(userId).collection('addToCart');

      final existingProductQuery = await cartRef
          .where('title', isEqualTo: widget.productName)
          .where('sallerId', isEqualTo: widget.sellerId)
          .get();

      if (existingProductQuery.docs.isNotEmpty) {
        final existingProductDoc = existingProductQuery.docs.first;
        final currentQuantity = existingProductDoc['quantity'] ?? 1;
        await cartRef.doc(existingProductDoc.id).update({'quantity': currentQuantity + 1});
        _showModernToast('Quantity updated in cart', true, showCartButton: true);
      } else {
        await cartRef.add({
          'productId': widget.id,
          'title': widget.productName,
          'description': widget.shortDescription,
          'price': widget.price,
          'imageUrl': widget.imageUrls.toSet().toList(),
          'category': widget.categoryName,
          'sallerId': widget.sellerId,
          'isRental': false,
          'quantity': 1,
          'aQuantity': widget.quantity,
          'averageRating': widget.rating,
        });
        _showModernToast('Added to cart successfully', true, showCartButton: true);
      }
    } catch (e) {
      _showModernToast('Failed to add to cart', false);
    }
  }

  void _startChat() {
    final currentUserId = FirebaseAuth.instance.currentUser?.uid ?? '';
    if (currentUserId.isNotEmpty) {
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

  @override
  Widget build(BuildContext context) {
    final wishListRef = FirebaseFirestore.instance
        .collection('users')
        .doc(FirebaseAuth.instance.currentUser!.uid)
        .collection('wishList');

    final List<String> uniqueImages = widget.imageUrls.toSet().toList();
    final bool isAvailable = widget.quantity != "0";

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        iconTheme: const IconThemeData(color: Colors.black),
        title: Text(widget.productName, style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
        centerTitle: true,
        actions: [
          IconButton(onPressed: _startChat, icon: const Icon(Icons.chat_bubble_outline)),
          StreamBuilder<DocumentSnapshot>(
            stream: wishListRef.doc(widget.id).snapshots(),
            builder: (context, snapshot) {
              final isInWishlist = snapshot.hasData && snapshot.data!.exists;
              return IconButton(
                onPressed: () async {
                  if (isInWishlist) {
                    await wishListRef.doc(widget.id).delete();
                    _showModernToast('Removed from wishlist', true);
                  } else {
                    await wishListRef.doc(widget.id).set({'productId': widget.id, 'addedAt': Timestamp.now()});
                    _showModernToast('Added to wishlist', true);
                  }
                },
                icon: Icon(
                  isInWishlist ? Icons.favorite : Icons.favorite_border,
                  color: isInWishlist ? Colors.green : Colors.grey,
                ),
              );
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Stack(
              children: [
                CarouselSlider(
                  items: uniqueImages.map((url) => Image.network(url, fit: BoxFit.cover, width: double.infinity)).toList(),
                  options: CarouselOptions(
                    height: 350,
                    viewportFraction: 1.0,
                    autoPlay: uniqueImages.length > 1,
                    onPageChanged: (index, _) => setState(() => _currentImageIndex = index),
                  ),
                ),
                if (uniqueImages.length > 1)
                  Positioned(
                    bottom: 20,
                    left: 0,
                    right: 0,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: uniqueImages.asMap().entries.map((entry) {
                        return Container(
                          width: _currentImageIndex == entry.key ? 24 : 8,
                          height: 8,
                          margin: const EdgeInsets.symmetric(horizontal: 4),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(4),
                            color: _currentImageIndex == entry.key ? Colors.green : Colors.white70,
                          ),
                        );
                      }).toList(),
                    ),
                  ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(color: Colors.green.withOpacity(0.1), borderRadius: BorderRadius.circular(20)),
                        child: Text(
                          widget.isRental
                              ? "PKR ${widget.price.toStringAsFixed(2)}/hr"
                              : "PKR ${widget.price.toStringAsFixed(2)}/kg",
                          style: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold, fontSize: 18),
                        ),
                      ),
                      if (!widget.isRental)
                        Row(
                          children: [
                            const Icon(Icons.star_rounded, color: Colors.orange, size: 28),
                            Text(widget.rating, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                            Text(" ($ratings)", style: const TextStyle(color: Colors.grey)),
                          ],
                        ),
                    ],
                  ),
                  const SizedBox(height: 15),
                  Text(widget.productName, style: const TextStyle(fontSize: 26, fontWeight: FontWeight.bold, letterSpacing: 0.5)),
                  const SizedBox(height: 8),

                  // --- RENTAL CONDITION ---
                  // Only show stock availability if it's NOT a rental product
                  if (!widget.isRental)
                    Row(
                      children: [
                        Icon(isAvailable ? Icons.check_circle : Icons.cancel, color: isAvailable ? Colors.green : Colors.red, size: 18),
                        const SizedBox(width: 5),
                        Text(
                          isAvailable ? "Available Stock: ${widget.quantity}" : "Out of Stock",
                          style: TextStyle(color: isAvailable ? Colors.green : Colors.red, fontWeight: FontWeight.w500),
                        ),
                      ],
                    ),

                  const SizedBox(height: 10),
                  Text("Category: ${widget.categoryName}", style: TextStyle(color: Colors.grey.shade600, fontSize: 14)),
                  const SizedBox(height: 25),
                  SellerStatsWidget(
                    sellerId: widget.sellerId, // Pass the seller ID from your product data
                    onTap: () {
                      // Navigate to the Store Preview screen
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => StorePreviewScreen(
                            sellerId: widget.sellerId,
                          ),
                        ),
                      );
                    },
                  ),
                  const Text("Description", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 10),
                  Text(widget.shortDescription, style: TextStyle(color: Colors.grey.shade700, height: 1.6, fontSize: 15)),
                  const SizedBox(height: 30),
                  RelatedProductsSlider(category: widget.categoryName, currentProductId: widget.id.toString()),
                  if (!widget.isRental) ProductReviewsWidget(productId: widget.id.toString()),
                ],
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.fromLTRB(20, 10, 20, 30),
        decoration: BoxDecoration(color: Colors.white, boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, -5))]),
        child: widget.isRental
            ? ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.green,
            padding: const EdgeInsets.symmetric(vertical: 15),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
          ),
          onPressed: _startChat,
          child: const Text('RENT NOW', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
        )
            : Row(
          children: [
            Expanded(
              flex: 2,
              child: OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 15),
                  side: const BorderSide(color: Colors.black),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                ),
                onPressed: _startChat,
                icon: const Icon(Icons.chat_bubble_outline, color: Colors.black),
                label: const Text("Chat", style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
              ),
            ),
            const SizedBox(width: 15),
            Expanded(
              flex: 3,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: isAvailable ? Colors.green : Colors.grey,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(vertical: 15),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                ),
                onPressed: isAvailable ? _uploadProduct : null,
                child: const Text("ADD TO CART", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}