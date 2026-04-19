import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:zrai_mart/UI/product/CustomerProductFullView.dart';
import '../../models/Product.dart';
import '../Categories/CategoryList.dart';
import 'SearchScreen.dart';

class SeeAllScreen extends StatefulWidget {
  const SeeAllScreen({super.key});

  @override
  State<SeeAllScreen> createState() => _SeeAllScreenState();
}

class _SeeAllScreenState extends State<SeeAllScreen> {
  final List<Product> _products = [];
  bool _isLoading = false;
  DocumentSnapshot? _lastDocument;
  final ScrollController _scrollController = ScrollController();

  // Track the current filter state
  String _selectedCategory = "All";

  @override
  void initState() {
    super.initState();
    _loadProducts();

    // Pagination listener: triggers when user is 90% down the list
    _scrollController.addListener(() {
      if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent * 0.9 &&
          !_isLoading) {
        _loadMoreProducts();
      }
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  /// Initial load or reset when category changes
  Future<void> _loadProducts() async {
    if (_isLoading) return;
    setState(() => _isLoading = true);

    try {
      // 1. Get the list of IDs for Sellers who meet ALL criteria
      // Note: This requires an index in Firestore for these 3 fields
      QuerySnapshot sellerSnapshot = await FirebaseFirestore.instance
          .collection('saller')
          .where('isAdminApproved', isEqualTo: true)
          .where('isSellerRestricted', isEqualTo: false)
          .where('hasSetupStore', isEqualTo: true)
          .get();

      List<String> validSellerIds = sellerSnapshot.docs.map((doc) => doc.id).toList();

      // If no sellers are approved, don't bother fetching products
      if (validSellerIds.isEmpty) {
        setState(() {
          _products.clear();
          _lastDocument = null;
        });
        return;
      }

      // 2. Query Products
      Query query = FirebaseFirestore.instance.collection('products');

      if (_selectedCategory == "All") {
        query = query.where('category', isNotEqualTo: "Rental").orderBy('category');
      } else {
        query = query.where('category', isEqualTo: _selectedCategory);
      }

      // Note: limit(50) or higher is used here because we filter seller status client-side
      QuerySnapshot querySnapshot = await query.limit(40).get();

      if (mounted) {
        final allFetched = querySnapshot.docs.map((doc) => Product.fromDocument(doc)).toList();

        // 3. Client-side filter: Only keep products if their sellerId is in our valid list
        final filtered = allFetched.where((p) => validSellerIds.contains(p.sellerId)).toList();

        setState(() {
          _products.clear();
          _products.addAll(filtered);
          _lastDocument = querySnapshot.docs.isNotEmpty ? querySnapshot.docs.last : null;
        });
      }
    } catch (e) {
      debugPrint("Load Products Error: $e");
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  /// Load subsequent pages of data
  Future<void> _loadMoreProducts() async {
    if (_lastDocument == null || _isLoading) return;

    setState(() => _isLoading = true);

    try {
      Query query = FirebaseFirestore.instance.collection('products');

      if (_selectedCategory == "All") {
        query = query.where('category', isNotEqualTo: "Rental").orderBy('category');
      } else {
        query = query.where('category', isEqualTo: _selectedCategory);
      }

      QuerySnapshot querySnapshot = await query
          .startAfterDocument(_lastDocument!)
          .limit(10)
          .get();

      if (mounted) {
        setState(() {
          if (querySnapshot.docs.isNotEmpty) {
            _products.addAll(querySnapshot.docs.map((doc) => Product.fromDocument(doc)).toList());
            _lastDocument = querySnapshot.docs.last;
          } else {
            _lastDocument = null; // End of list reached
          }
        });
      }
    } catch (e) {
      debugPrint("Load More Error: $e");
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: CustomScrollView(
        controller: _scrollController,
        physics: const BouncingScrollPhysics(),
        slivers: [
          // Header Section
          SliverAppBar(
            expandedHeight: 190,
            floating: true,
            pinned: true,
            elevation: 0,
            backgroundColor: Colors.white,
            surfaceTintColor: Colors.white,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_ios_new, color: Colors.black, size: 20),
              onPressed: () => Navigator.pop(context),
            ),
            title: const Text(
              "Shop Products",
              style: TextStyle(color: Colors.black, fontWeight: FontWeight.w900, letterSpacing: -0.5),
            ),
            centerTitle: true,
            flexibleSpace: FlexibleSpaceBar(
              background: Column(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: _buildFakeSearchBar(),
                  ),
                  const SizedBox(height: 12),
                  // The Filter Row
                  CategoryList(
                    onCategorySelected: (category) {
                      if (_selectedCategory != category) {
                        setState(() {
                          _selectedCategory = category;
                          _lastDocument = null;
                        });
                        _loadProducts();
                      }
                    },
                  ),
                  const SizedBox(height: 12),
                ],
              ),
            ),
          ),

          // Main Product Grid
          _products.isEmpty && !_isLoading
              ? const SliverFillRemaining(child: Center(child: Text("No products found in this category.")))
              : SliverPadding(
            padding: const EdgeInsets.all(16),
            sliver: SliverGrid(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                childAspectRatio: 0.72,
                crossAxisSpacing: 15,
                mainAxisSpacing: 15,
              ),
              delegate: SliverChildBuilderDelegate(
                    (context, index) => _buildProductCard(_products[index]),
                childCount: _products.length,
              ),
            ),
          ),

          // Infinite Scroll Loader
          if (_isLoading)
            const SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.symmetric(vertical: 24),
                child: Center(
                  child: CircularProgressIndicator(
                    color: Colors.green,
                    strokeWidth: 2,
                  ),
                ),
              ),
            ),

          const SliverToBoxAdapter(child: SizedBox(height: 30)),
        ],
      ),
    );
  }

  Widget _buildFakeSearchBar() {
    return GestureDetector(
      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const SearchScreen())),
      child: Container(
        height: 48,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        decoration: BoxDecoration(
          color: Colors.grey[100],
          borderRadius: BorderRadius.circular(15),
          border: Border.all(color: Colors.grey[200]!),
        ),
        child: const Row(
          children: [
            Icon(Icons.search_rounded, color: Colors.green, size: 22),
            SizedBox(width: 12),
            Text(
              'Search seeds, fertilizers...',
              style: TextStyle(color: Colors.grey, fontSize: 14, fontWeight: FontWeight.w500),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProductCard(Product product) {
    double rating = double.tryParse(product.avgRate) ?? 0.0;

    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => customerProductfullview(
            imageUrls: product.imageUrl,
            productName: product.name,
            shortDescription: product.description,
            price: product.price,
            categoryName: product.category,
            sellerId: product.sellerId,
            isRental: product.isRental,
            id: product.id,
            rating: product.avgRate,
            quantity: product.quantity.toString(),
          ),
        ),
      ),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.03),
              blurRadius: 10,
              offset: const Offset(0, 4),
            )
          ],
          border: Border.all(color: Colors.grey[100]!),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image Stack
            Expanded(
              child: Stack(
                children: [
                  Positioned.fill(
                    child: ClipRRect(
                      borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                      child: Image.network(
                        product.imageUrl.isNotEmpty
                            ? product.imageUrl.first
                            : 'https://via.placeholder.com/150',
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                  // Category Tag
                  Positioned(
                    top: 10,
                    left: 10,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.9),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        product.category,
                        style: const TextStyle(
                          color: Colors.green,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Product Info
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    product.name,
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFF1B3D2F)),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(Icons.star_rounded, color: Colors.orange[400], size: 16),
                      const SizedBox(width: 4),
                      Text(
                        rating.toStringAsFixed(1),
                        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Flexible(
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Text(
                            'PKR ${product.price}',
                            style: const TextStyle(
                              color: Colors.green,
                              fontWeight: FontWeight.w900,
                              fontSize: 16,
                            ),
                          ),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: Colors.green[700],
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(Icons.add_rounded, color: Colors.white, size: 18),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}