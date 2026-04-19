import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:zrai_mart/app_colors.dart';
import 'package:zrai_mart/saller%20center/product/EditProduct.dart';
import 'package:zrai_mart/saller%20center/product/seller_state_widget.dart';
import '../../UI/product/ProductReviewsWidget.dart';
import '../../UI/product/RelatedProductSlider.dart';
import '../storeView/StorePreviewScreen.dart';

class SallerProductFullView extends StatefulWidget {
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

  const SallerProductFullView({
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
  _SallerProductFullViewState createState() => _SallerProductFullViewState();
}

class _SallerProductFullViewState extends State<SallerProductFullView> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final PageController _pageController = PageController();


  Future<void> _deleteProduct(String productId) async {
    try {
      await _firestore.collection('products').doc(productId).delete();
      _showSnackbar('Product deleted successfully', Colors.green);
      Navigator.pop(context); // Close view after deletion
    } catch (e) {
      _showSnackbar('Error deleting product: $e', Colors.red);
    }
  }

  void _showDeleteConfirmationDialog(String productId) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Row(
            children: const [
              Icon(Icons.warning_amber_rounded, color: Colors.red),
              SizedBox(width: 10),
              Text('Delete Listing?'),
            ],
          ),
          content: const Text('This will permanently remove the product from the marketplace.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                _deleteProduct(productId);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              child: const Text('Delete', style: TextStyle(color: Colors.white)),
            ),
          ],
        );
      },
    );
  }

  void _showSnackbar(String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;

    print(widget.sellerId);
    return Scaffold(
      backgroundColor: Colors.white,
      body: CustomScrollView(
        slivers: [
          // 1. MODERN SLIVER APP BAR (IMMERSE IMAGES)
          SliverAppBar(
            expandedHeight: 350,
            pinned: true,
            flexibleSpace: FlexibleSpaceBar(
              background: Stack(
                children: [
                  PageView.builder(
                    controller: _pageController,
                    itemCount: widget.imageUrls.length,
                    itemBuilder: (context, index) {
                      return Image.network(
                        widget.imageUrls[index],
                        fit: BoxFit.cover,
                      );
                    },
                  ),
                  // Simple Indicator
                  Positioned(
                    bottom: 20,
                    left: 0,
                    right: 0,
                    child: Center(
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.3),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          "Swipe for more",
                          style: const TextStyle(color: Colors.white, fontSize: 10),
                        ),
                      ),
                    ),
                  )
                ],
              ),
            ),
          ),

          // 2. PRODUCT DETAILS SECTION
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Category & Rating Row
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.green.shade50,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          widget.categoryName.toUpperCase(),
                          style: TextStyle(color: Colors.green.shade700, fontWeight: FontWeight.bold, fontSize: 12),
                        ),
                      ),
                      if (widget.isRental == false)
                        Row(
                          children: [
                            Icon(Icons.star, color: Colors.amber, size: 20),
                            const SizedBox(width: 4),
                            Text(widget.rating, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                          ],
                        ),
                    ],
                  ),
                  const SizedBox(height: 15),

                  // Product Name
                  Text(
                    widget.productName,
                    style: const TextStyle(fontSize: 26, fontWeight: FontWeight.bold, letterSpacing: -0.5),
                  ),
                  const SizedBox(height: 8),

                  // Price
                  Text(
                    'PKR ${widget.price.toStringAsFixed(2)}',
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: Colors.green.shade800),
                  ),


                  const SizedBox(height: 20),
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
                  ),                  const Divider(),
                  const SizedBox(height: 10),

                  // Description

                  const Text("About this product", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Text(
                    widget.shortDescription,
                    style: TextStyle(fontSize: 15, color: Colors.grey.shade700, height: 1.5),
                  ),

                  const SizedBox(height: 30),

                  // Recommended / Related
                  if (widget.isRental == false) ...[
                    const Text("Recommended", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 16),
                    RelatedProductsSlider(
                      category: widget.categoryName,
                      currentProductId: widget.productId,
                    ),
                    const SizedBox(height: 30),
                    ProductReviewsWidget(productId: widget.productId),
                  ],

                  const SizedBox(height: 100), // Bottom padding for navigation bar
                ],
              ),
            ),
          )
        ],
      ),

      // 3. FIXED MODERN BOTTOM ACTION BAR
      bottomNavigationBar: Container(
        padding: const EdgeInsets.fromLTRB(20, 10, 20, 25),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, -5))
          ],
        ),
        child: Row(
          children: [
            // Delete Button
            Expanded(
              flex: widget.isAdmin == true ? 1 : 1,
              child: ElevatedButton.icon(
                onPressed: () => _showDeleteConfirmationDialog(widget.productId),
                icon: const Icon(Icons.delete_outline, color: Colors.white, size: 20),
                label: const Text("Delete", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ),

            if (widget.isAdmin == false) ...[
              const SizedBox(width: 15),
              // Edit Button
              Expanded(
                flex: 1,
                child: ElevatedButton.icon(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => EditProduct(productId: widget.productId)),
                    );
                  },
                  icon: const Icon(Icons.edit_note, color: Colors.white, size: 22),
                  label: const Text("Edit Listing", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryGreen,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}