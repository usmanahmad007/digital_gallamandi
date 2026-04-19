import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:zrai_mart/saller%20center/homeScreen/productFullView.dart';
import 'package:zrai_mart/UI/HomeScreen/SearchScreen.dart'; // Import your search screen
import '../../app_colors.dart';
import '../../models/Product.dart';

class SeeAllScreenRental extends StatefulWidget {
  const SeeAllScreenRental({super.key});

  @override
  State<SeeAllScreenRental> createState() => _SeeAllScreenRentalState();
}

class _SeeAllScreenRentalState extends State<SeeAllScreenRental> {
  final List<Product> _allProducts = [];
  bool _isLoading = false;
  DocumentSnapshot? _lastDocument;
  final ScrollController _scrollController = ScrollController();
  final FirebaseAuth _auth = FirebaseAuth.instance;

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
    setState(() => _isLoading = true);
    try {
      QuerySnapshot querySnapshot = await FirebaseFirestore.instance
          .collection('products')
          .where('category', isEqualTo: "Rental")
          .limit(12)
          .get();

      var fetched = querySnapshot.docs
          .map((doc) => Product.fromDocument(doc))
          .where((product) => product.sellerId != _auth.currentUser!.uid)
          .toList();

      setState(() {
        _allProducts.addAll(fetched);
        _lastDocument = querySnapshot.docs.isNotEmpty ? querySnapshot.docs.last : null;
      });
    } catch (e) {
      debugPrint("Error: $e");
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _loadMoreProducts() async {
    if (_lastDocument == null) return;
    setState(() => _isLoading = true);

    try {
      QuerySnapshot querySnapshot = await FirebaseFirestore.instance
          .collection('products')
          .where("category", isEqualTo: "Rental")
          .startAfterDocument(_lastDocument!)
          .limit(10)
          .get();

      var fetched = querySnapshot.docs
          .map((doc) => Product.fromDocument(doc))
          .where((product) => product.sellerId != _auth.currentUser!.uid)
          .toList();

      setState(() {
        _allProducts.addAll(fetched);
        _lastDocument = querySnapshot.docs.isNotEmpty ? querySnapshot.docs.last : null;
      });
    } catch (e) {
      debugPrint("Error: $e");
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const primaryColor = AppColors.primaryGreen;

    return Scaffold(
      backgroundColor: const Color(0xffF5F7FB),
      body: CustomScrollView(
        controller: _scrollController,
        slivers: [
          _buildSliverAppBar(primaryColor),

          // Fake Search Bar (Static UI that navigates on tap)
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 10),
              child: Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => const SearchScreen(isSeller: true,)),
                        );
                      },
                      child: Container(
                        height: 50,
                        padding: const EdgeInsets.symmetric(horizontal: 15),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(15),
                          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)],
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.search, color: Colors.grey),
                            const SizedBox(width: 10),
                            Text(
                              "Search machinery...",
                              style: TextStyle(color: Colors.grey[500], fontSize: 14),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  _buildFilterButton(primaryColor),
                ],
              ),
            ),
          ),

          // Dynamic Grid
          _allProducts.isEmpty && !_isLoading
              ? const SliverFillRemaining(child: Center(child: Text("No rental equipment found")))
              : SliverPadding(
            padding: const EdgeInsets.all(15),
            sliver: SliverGrid(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                childAspectRatio: 0.72,
                crossAxisSpacing: 15,
                mainAxisSpacing: 15,
              ),
              delegate: SliverChildBuilderDelegate(
                    (context, index) => _buildRentalCard(_allProducts[index], primaryColor),
                childCount: _allProducts.length,
              ),
            ),
          ),

          if (_isLoading)
            const SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.symmetric(vertical: 20),
                child: Center(child: CircularProgressIndicator(color: primaryColor)),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildSliverAppBar(Color primaryColor) {
    return SliverAppBar(
      expandedHeight: 150.0,
      pinned: true,
      elevation: 0,
      backgroundColor: primaryColor,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_ios, color: Colors.white, size: 20),
        onPressed: () => Navigator.pop(context),
      ),
      flexibleSpace: FlexibleSpaceBar(
        title: const Text("Rental Equipment", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
        background: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [primaryColor, const Color(0xFF4facfe)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFilterButton(Color primaryColor) {
    return GestureDetector(
      onTap: () {
        showModalBottomSheet(
          context: context,
          shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
          builder: (context) => Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 20),
              const Text("Sort By", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
              ListTile(
                leading: const Icon(Icons.sort_by_alpha),
                title: const Text("Name (A-Z)"),
                onTap: () {
                  setState(() => _allProducts.sort((a, b) => a.name.compareTo(b.name)));
                  Navigator.pop(context);
                },
              ),
              ListTile(
                leading: const Icon(Icons.attach_money),
                title: const Text("Price (Low to High)"),
                onTap: () {
                  setState(() => _allProducts.sort((a, b) => a.price.compareTo(b.price)));
                  Navigator.pop(context);
                },
              ),
              const SizedBox(height: 20),
            ],
          ),
        );
      },
      child: Container(
        height: 50,
        width: 50,
        decoration: BoxDecoration(color: primaryColor, borderRadius: BorderRadius.circular(15)),
        child: const Icon(Icons.tune, color: Colors.white),
      ),
    );
  }

  Widget _buildRentalCard(Product product, Color primary) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => HSProductfullview(
              imageUrls: product.imageUrl,
              productName: product.name,
              shortDescription: product.description,
              price: product.price,
              categoryName: product.category,
              isRental: product.isRental,
              rating: product.avgRate,
              productId: product.id,
              sellerId: product.sellerId,
            ),
          ),
        );
      },
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10, offset: const Offset(0, 4))],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: ClipRRect(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                child: Image.network(
                  product.imageUrl.isNotEmpty ? product.imageUrl.first : '',
                  fit: BoxFit.cover,
                  width: double.infinity,
                  errorBuilder: (c, e, s) => Container(color: Colors.grey[200], child: const Icon(Icons.image_not_supported)),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                      product.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontWeight: FontWeight.bold)
                  ),
                  const SizedBox(height: 4),
                  Text(
                      'Rs. ${product.price.toStringAsFixed(0)} /hr',
                      style: TextStyle(color: primary, fontWeight: FontWeight.bold)
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