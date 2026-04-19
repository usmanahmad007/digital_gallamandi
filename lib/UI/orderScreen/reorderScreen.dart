import 'package:carousel_slider/carousel_slider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:zrai_mart/UI/cartScreen/CartScreen.dart';
import 'package:zrai_mart/UI/product/ProductReviewsWidget.dart';
import 'package:zrai_mart/UI/product/RelatedProductSlider.dart';
import '../chatScreen/chatSCreen.dart';

class ReorderProductView extends StatefulWidget {
  final String productId;

  const ReorderProductView({super.key, required this.productId});

  @override
  _ReorderProductViewState createState() => _ReorderProductViewState();
}

class _ReorderProductViewState extends State<ReorderProductView> {
  int _currentImageIndex = 0;
  int ratings = 0;
  late Future<DocumentSnapshot> _productFuture;

  @override
  void initState() {
    super.initState();
    _productFuture = FirebaseFirestore.instance.collection('products').doc(widget.productId).get();
    _loadRatings();
  }

  Future<void> _loadRatings() async {
    int r = await getRatingListLength(widget.productId);
    if (mounted) setState(() => ratings = r > 0 ? r - 1 : 0);
  }

  Future<int> getRatingListLength(String productId) async {
    try {
      DocumentSnapshot doc = await FirebaseFirestore.instance.collection('products').doc(productId).get();
      return (doc.data() as Map<String, dynamic>?)?['rating']?.length ?? 0;
    } catch (e) { return 0; }
  }

  void _showModernToast(String message, bool isSuccess, {bool showCartButton = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        elevation: 0,
        behavior: SnackBarBehavior.floating,
        backgroundColor: Colors.transparent,
        content: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: isSuccess ? const Color(0xFF2E7D32) : Colors.redAccent,
            borderRadius: BorderRadius.circular(20),
            boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 10, offset: Offset(0, 4))],
          ),
          child: Row(
            children: [
              Icon(isSuccess ? Icons.check_circle_outline : Icons.error_outline, color: Colors.white),
              const SizedBox(width: 12),
              Expanded(
                child: Text(message, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
              ),
              if (showCartButton)
                TextButton(
                  onPressed: () {
                    ScaffoldMessenger.of(context).hideCurrentSnackBar();
                    Navigator.push(context, MaterialPageRoute(builder: (context) => const Cartscreen()));
                  },
                  child: const Text("VIEW CART", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, decoration: TextDecoration.underline)),
                ),
            ],
          ),
        ),
      ),
    );
  }

  void _confirmReorder(Map<String, dynamic> data, List<String> images) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text("Confirm Reorder"),
        content: const Text("This product will be added to your cart with current pricing."),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel", style: TextStyle(color: Colors.grey))),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
            onPressed: () {
              Navigator.pop(context);
              _uploadProduct(data, images);
            },
            child: const Text("Yes, Proceed"),
          ),
        ],
      ),
    );
  }

  void _uploadProduct(Map<String, dynamic> data, List<String> images) async {
    try {
      final userId = FirebaseAuth.instance.currentUser?.uid;
      final cartRef = FirebaseFirestore.instance.collection('users').doc(userId).collection('addToCart');
      final existing = await cartRef.where('productId', isEqualTo: widget.productId).get();

      if (existing.docs.isNotEmpty) {
        await cartRef.doc(existing.docs.first.id).update({'quantity': (existing.docs.first['quantity'] ?? 1) + 1});
      } else {
        await cartRef.add({
          'productId': widget.productId,
          'title': data['title'],
          'description': data['description'],
          'price': double.tryParse(data['price'].toString()) ?? 0.0,
          'imageUrl': images,
          'category': data['category'],
          'sallerId': data['sellerId'] ?? data['sallerId'],
          'isRental': false,
          'quantity': 1,
          'aQuantity': data['quantity'].toString(),
          'averageRating': data['averageRating'] ?? "0.0",
        });
      }
      _showModernToast('Added to your cart!', true, showCartButton: true);
    } catch (e) {
      _showModernToast('Something went wrong', false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final wishListRef = FirebaseFirestore.instance
        .collection('users')
        .doc(FirebaseAuth.instance.currentUser!.uid)
        .collection('wishList');

    return FutureBuilder<DocumentSnapshot>(
      future: _productFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(body: Center(child: CircularProgressIndicator(color: Colors.green)));
        }
        if (!snapshot.hasData || !snapshot.data!.exists) return const Scaffold(body: Center(child: Text("Product not found")));

        var data = snapshot.data!.data() as Map<String, dynamic>;
        var imgData = data['imageUrls'] ?? data['image'];

        // --- UNIQUE IMAGE LOGIC ---
        List<String> imageUrls = [];
        if (imgData is List) {
          imageUrls = List<String>.from(imgData).toSet().toList(); // Removes duplicates
        } else if (imgData != null) {
          imageUrls = [imgData.toString()];
        }

        bool isAvailable = (data['quantity'] ?? 0).toString() != "0";

        return Scaffold(
          backgroundColor: Colors.white,
          appBar: AppBar(
            elevation: 0,
            backgroundColor: Colors.white,
            iconTheme: const IconThemeData(color: Colors.black),
            title: Text(data['title'] ?? "Product", style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
            centerTitle: true,
            actions: [
              StreamBuilder<DocumentSnapshot>(
                stream: wishListRef.doc(widget.productId).snapshots(),
                builder: (context, wishSnapshot) {
                  bool isInWishlist = wishSnapshot.hasData && wishSnapshot.data!.exists;
                  return IconButton(
                    onPressed: () async {
                      if (isInWishlist) {
                        await wishListRef.doc(widget.productId).delete();
                        _showModernToast('Removed from wishlist', true);
                      } else {
                        await wishListRef.doc(widget.productId).set({
                          'productId': widget.productId,
                          'addedAt': Timestamp.now(),
                        });
                        _showModernToast('Added to wishlist', true);
                      }
                    },
                    icon: Icon(
                      isInWishlist ? Icons.favorite : Icons.favorite_border,
                      color: isInWishlist ? Colors.green : Colors.grey,
                    ),
                  );
                },
              )
            ],
          ),
          body: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Stack(
                  children: [
                    CarouselSlider(
                      items: imageUrls.map((url) => Image.network(url, fit: BoxFit.cover, width: double.infinity)).toList(),
                      options: CarouselOptions(
                        height: 350,
                        viewportFraction: 1.0,
                        // Only enable autoplay and infinite scroll if there is more than 1 UNIQUE image
                        autoPlay: imageUrls.length > 1,
                        enableInfiniteScroll: imageUrls.length > 1,
                        onPageChanged: (index, _) => setState(() => _currentImageIndex = index),
                      ),
                    ),
                    if (imageUrls.length > 1)
                      Positioned(
                        bottom: 20,
                        left: 0,
                        right: 0,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: imageUrls.asMap().entries.map((entry) {
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
                            child: Text("PKR ${data['price']}/kg", style: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold, fontSize: 18)),
                          ),
                          Row(
                            children: [
                              const Icon(Icons.star_rounded, color: Colors.orange, size: 28),
                              Text(data['averageRating']?.toString() ?? "0.0", style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 15),
                      Text(data['title'] ?? "", style: const TextStyle(fontSize: 26, fontWeight: FontWeight.bold, letterSpacing: 0.5)),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Icon(isAvailable ? Icons.check_circle : Icons.cancel, color: isAvailable ? Colors.green : Colors.red, size: 18),
                          const SizedBox(width: 5),
                          Text(isAvailable ? "Available in stock (${data['quantity']})" : "Out of stock", style: TextStyle(color: isAvailable ? Colors.green : Colors.red, fontWeight: FontWeight.w500)),
                        ],
                      ),
                      const SizedBox(height: 25),
                      const Text("Product Description", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 10),
                      Text(data['description'] ?? "", style: TextStyle(color: Colors.grey.shade700, height: 1.6, fontSize: 15)),
                      const SizedBox(height: 30),
                      RelatedProductsSlider(category: data['category'] ?? "", currentProductId: widget.productId),
                      ProductReviewsWidget(productId: widget.productId),
                    ],
                  ),
                ),
              ],
            ),
          ),
          bottomNavigationBar: Container(
            padding: const EdgeInsets.fromLTRB(20, 10, 20, 30),
            decoration: BoxDecoration(color: Colors.white, boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, -5))]),
            child: Row(
              children: [
                Expanded(
                  flex: 2,
                  child: OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 15), side: const BorderSide(color: Colors.black), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15))),
                    onPressed: () => _startChat(data['title'], data['sallerId']),
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
                    onPressed: isAvailable ? () => _confirmReorder(data, imageUrls) : null,
                    child: const Text("REORDER NOW", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _startChat(String pName, String sId) {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid != null) Navigator.push(context, MaterialPageRoute(builder: (context) => ChatScreen(productId: widget.productId, productName: pName, currentUserId: uid, sellerId: sId)));
  }
}