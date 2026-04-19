import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import '../../UI/product/ProductReviewsWidget.dart';
import '../../UI/product/RelatedProductSlider.dart';
import '../../app_colors.dart';
import '../product/seller_state_widget.dart';

class HSProductfullview extends StatefulWidget {
  final List<String> imageUrls;
  final String productName;
  final String shortDescription;
  final double price;
  final String categoryName;
  final String productId;
  final bool isRental;
  final String rating;
  final bool? isAdmin;
  final String sellerId;

  const HSProductfullview({
    super.key,
    required this.imageUrls,
    required this.productName,
    required this.shortDescription,
    required this.price,
    required this.categoryName,
    required this.productId,
    required this.isRental,
    required this.rating,
    this.isAdmin = false, required this.sellerId,
  });


  @override
  _HSProductfullviewState createState() => _HSProductfullviewState();
}

class _HSProductfullviewState extends State<HSProductfullview> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  int _currentPage = 0;

  Future<void> _deleteProduct(String productId) async {
    try {
      await _firestore.collection('products').doc(productId).delete();
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Product deleted successfully'), backgroundColor: Colors.green),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    const primaryColor = AppColors.primaryGreen;

    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          CustomScrollView(
            slivers: [
              // 1. Image Carousel Header
              SliverAppBar(
                expandedHeight: 400.0,
                elevation: 0,
                pinned: true,
                stretch: true,
                backgroundColor: primaryColor,
                leading: CircleAvatar(
                  backgroundColor: Colors.black26,
                  child: IconButton(
                    icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white, size: 18),
                    onPressed: () => Navigator.pop(context),
                  ),
                ),
                flexibleSpace: FlexibleSpaceBar(
                  background: Stack(
                    children: [
                      PageView.builder(
                        itemCount: widget.imageUrls.length,
                        onPageChanged: (index) => setState(() => _currentPage = index),
                        itemBuilder: (context, index) {
                          return Image.network(
                            widget.imageUrls[index],
                            fit: BoxFit.cover,
                          );
                        },
                      ),
                      // Dot Indicator
                      Positioned(
                        bottom: 20,
                        left: 0,
                        right: 0,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: List.generate(
                            widget.imageUrls.length,
                                (index) => AnimatedContainer(
                              duration: const Duration(milliseconds: 300),
                              margin: const EdgeInsets.symmetric(horizontal: 4),
                              height: 8,
                              width: _currentPage == index ? 24 : 8,
                              decoration: BoxDecoration(
                                color: _currentPage == index ? primaryColor : Colors.white70,
                                borderRadius: BorderRadius.circular(4),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // 2. Product Details
              SliverToBoxAdapter(
                child: Container(
                  padding: const EdgeInsets.all(20),
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: primaryColor.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              widget.categoryName,
                              style: const TextStyle(color: primaryColor, fontWeight: FontWeight.bold, fontSize: 12),
                            ),
                          ),
                          if (!widget.isRental)
                            Row(
                              children: [
                                const Icon(Icons.star, color: Colors.orange, size: 20),
                                const SizedBox(width: 4),
                                Text(widget.rating, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                              ],
                            ),
                        ],
                      ),
                      const SizedBox(height: 15),
                      Text(
                        widget.productName,
                        style: const TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: Colors.black87),
                      ),
                      const SizedBox(height: 10),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.baseline,
                        textBaseline: TextBaseline.alphabetic,
                        children: [
                          Text(
                            "Rs. ${widget.price.toStringAsFixed(0)}",
                            style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: primaryColor),
                          ),
                          if (widget.isRental)
                            const Text(" /day", style: TextStyle(color: Colors.grey, fontSize: 16)),
                        ],
                      ),
                      const SizedBox(height: 25),
                      SellerStatsWidget(sellerId: widget.sellerId,),
                      const Text("Description", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 10),
                      Text(
                        widget.shortDescription,
                        style: TextStyle(fontSize: 15, color: Colors.grey[700], height: 1.5),
                      ),
                      const SizedBox(height: 30),

                      // Extra Sections
                      if (!widget.isRental) ...[
                        const Divider(),
                        const SizedBox(height: 10),
                        const Text("Recommended Items", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 15),
                        RelatedProductsSlider(
                          category: widget.categoryName,
                          currentProductId: widget.productId,
                        ),
                        const SizedBox(height: 20),
                        ProductReviewsWidget(productId: widget.productId),
                        const SizedBox(height: 100), // Space for bottom bar
                      ],
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
      bottomNavigationBar: _buildBottomAction(primaryColor),
    );
  }

  Widget _buildBottomAction(Color primary) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, -5))],
      ),
      child: SafeArea(
        child: Row(
          children: [
            // Delete Action
            Expanded(
              flex: 2,
              child: ElevatedButton(

                onPressed: () => _showDeleteDialog(),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.grey[100],
                  foregroundColor: Colors.red,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                ),
                child: const Icon(Icons.delete_outline),
              ),
            ),
            const SizedBox(width: 15),
            // Primary Action (Buy or Edit)
            Expanded(
              flex: 5,
              child: ElevatedButton(
                onPressed: () {
                  // If admin, go to Edit. If user, process Order/Rental.
                  showDialog(
                    context: context,
                    builder: (context) => AlertDialog(
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                      title: const Text("Add to Cart?"),
                      content: const Text("Do you want to Add this item into cart. Are you sure?"),
                      actions: [
                        TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel")),

                        ElevatedButton(onPressed: (){
                          Fluttertoast.showToast(msg: "You are not allowed to Buy/Rent items");
                        },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: primary,
                            padding: const EdgeInsets.symmetric(vertical: 16,horizontal: 15),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                          ),
                          child: Text(
                            "Buy/Rent",
                            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                          ),)
                      ],
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: primary,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                ),
                child: Text(
                  widget.isAdmin == true ? 'Edit Product' : (widget.isRental ? 'Rent Now' : 'Buy Now'),
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showDeleteDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text("Delete Product?"),
        content: const Text("This action cannot be undone. Are you sure?"),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel")),
          TextButton(
            onPressed: /*() => _deleteProduct(widget.productId)*/(){
              Fluttertoast.showToast(msg: "You are not Allowed to Edit/Delete The items");
            },
            child: const Text("Delete", style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}