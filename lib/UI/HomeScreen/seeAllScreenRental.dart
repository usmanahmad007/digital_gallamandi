import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:zrai_mart/UI/product/CustomerProductFullView.dart';
import '../../models/Product.dart';
import 'SearchScreen.dart';

class SeeAllScreenRental extends StatefulWidget {
  const SeeAllScreenRental({super.key});

  @override
  State<SeeAllScreenRental> createState() => _SeeAllScreenRentalState();
}

class _SeeAllScreenRentalState extends State<SeeAllScreenRental> {
  final List<Product> _products = [];
  bool _isLoading = false;
  DocumentSnapshot? _lastDocument;
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _loadProducts();
    _scrollController.addListener(() {
      if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 200 &&
          !_isLoading) {
        _loadMoreProducts();
      }
    });
  }

  Future<void> _loadProducts() async {
    if (_isLoading) return;
    setState(() => _isLoading = true);
    _products.clear();

    try {
      // 1. Fetch valid Seller IDs (Approved, Not Restricted, Setup Complete)
      QuerySnapshot sellerSnapshot = await FirebaseFirestore.instance
          .collection('saller') // Using your collection name 'saller'
          .where('isAdminApproved', isEqualTo: true)
          .where('isSellerRestricted', isEqualTo: false)
          .where('hasSetupStore', isEqualTo: true)
          .get();

      List<String> validSellerIds = sellerSnapshot.docs.map((doc) => doc.id).toList();

      // If no sellers meet the criteria, stop here to avoid unnecessary product fetch
      if (validSellerIds.isEmpty) {
        setState(() => _isLoading = false);
        return;
      }

      // 2. Fetch Rental Products
      QuerySnapshot querySnapshot = await FirebaseFirestore.instance
          .collection('products')
          .where('category', isEqualTo: "Rental")
          .limit(30) // Increased limit to ensure we have enough after filtering
          .get();

      // 3. Filter products based on the valid seller list
      final filteredRentals = querySnapshot.docs
          .map((doc) => Product.fromDocument(doc))
          .where((product) => validSellerIds.contains(product.sellerId))
          .toList();

      if (mounted) {
        setState(() {
          _products.addAll(filteredRentals);
          _lastDocument = querySnapshot.docs.isNotEmpty ? querySnapshot.docs.last : null;
        });
      }
    } catch (e) {
      debugPrint("Rental Load Error: $e");
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _loadMoreProducts() async {
    if (_lastDocument == null || _isLoading) return;
    setState(() => _isLoading = true);
    try {
      QuerySnapshot querySnapshot = await FirebaseFirestore.instance
          .collection('products')
          .where("category", isEqualTo: "Rental")
          .startAfterDocument(_lastDocument!)
          .limit(10)
          .get();

      _products.addAll(querySnapshot.docs.map((doc) => Product.fromDocument(doc)).toList());
      _lastDocument = querySnapshot.docs.isNotEmpty ? querySnapshot.docs.last : null;
    } catch (e) {
      debugPrint("Error loading more: $e");
    }
    setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA), // Slightly off-white background
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.black, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          "Rental Equipment",
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.w800, fontSize: 18),
        ),
        centerTitle: true,
      ),
      body: CustomScrollView(
        controller: _scrollController,
        slivers: [
          // Modern Search Bar
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: GestureDetector(
                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const SearchScreen())),
                child: Container(
                  height: 50,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10, offset: const Offset(0, 4))],
                  ),
                  child: Row(
                    children: [
                      const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 15),
                        child: Icon(Icons.search, color: Colors.green),
                      ),
                      Text("Find machinery...", style: TextStyle(color: Colors.grey[400], fontSize: 14)),
                    ],
                  ),
                ),
              ),
            ),
          ),

          // Main Grid
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            sliver: SliverGrid(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                childAspectRatio: 0.68, // Lowering this increases the height of the card
                crossAxisSpacing: 14,
                mainAxisSpacing: 14,
              ),
              delegate: SliverChildBuilderDelegate(
                    (context, index) => _buildRentalCard(_products[index]),
                childCount: _products.length,
              ),
            ),
          ),

          if (_isLoading)
            const SliverToBoxAdapter(
              child: Padding(padding: EdgeInsets.all(20), child: Center(child: CircularProgressIndicator(color: Colors.green))),
            ),
          const SliverToBoxAdapter(child: SizedBox(height: 50)),
        ],
      ),
    );
  }

  Widget _buildRentalCard(Product product) {
    return GestureDetector(
      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => customerProductfullview(
        imageUrls: product.imageUrl,
        productName: product.name,
        shortDescription: product.description,
        price: product.price,
        categoryName: product.category,
        sellerId: product.sellerId,
        isRental: product.isRental,
        id: product.id,
        rating: product.avgRate,
        quantity: product.quantity,
      ))),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.grey.withOpacity(0.1)),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 8, offset: const Offset(0, 4))],
        ),
        child: Column(
          children: [
            // Image Section (Flex 55)
            Expanded(
              flex: 55,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  ClipRRect(
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                    child: Image.network(product.imageUrl.first, fit: BoxFit.cover),
                  ),
                  Positioned(
                    top: 8, left: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(color: Colors.green.withOpacity(0.9), borderRadius: BorderRadius.circular(6)),
                      child: const Text("VERIFIED", style: TextStyle(color: Colors.white, fontSize: 8, fontWeight: FontWeight.bold)),
                    ),
                  ),
                ],
              ),
            ),

            // Content Section (Flex 45)
            Expanded(
              flex: 45,
              child: Padding(
                padding: const EdgeInsets.all(10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween, // Distributes text and price
                  children: [
                    // Text Block
                    Flexible(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            product.name,
                            style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: Color(0xFF1A1A1A)),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 2),
                          Text(
                            product.description,
                            style: TextStyle(fontSize: 10, color: Colors.grey[500], height: 1.2),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),

                    // Price Block
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: FittedBox(
                                fit: BoxFit.scaleDown,
                                alignment: Alignment.centerLeft,
                                child: Text(
                                  "PKR ${product.price.toInt()}",
                                  style: const TextStyle(color: Colors.green, fontWeight: FontWeight.w900, fontSize: 15),
                                ),
                              ),
                            ),
                            Container(
                              height: 24, width: 24,
                              decoration: const BoxDecoration(color: Color(0xFFE8F5E9), shape: BoxShape.circle),
                              child: const Icon(Icons.arrow_forward_rounded, color: Colors.green, size: 14),
                            )
                          ],
                        ),
                        Text("/ hour", style: TextStyle(color: Colors.grey[400], fontSize: 9, fontWeight: FontWeight.w600)),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}