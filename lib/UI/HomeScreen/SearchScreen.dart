import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:zrai_mart/UI/product/CustomerProductFullView.dart';
import 'package:zrai_mart/saller%20center/homeScreen/productFullView.dart';
import '../../models/Product.dart';
import 'dart:async';

class SearchScreen extends StatefulWidget {

  final bool? isSeller;
  // Constructor is now empty/standard
  const SearchScreen({super.key, this.isSeller});

  @override
  _SearchScreenState createState() => _SearchScreenState();
}
class _SearchScreenState extends State<SearchScreen> {
  // Define the nullable variable here
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();

  List<Product> _allProducts = [];
  List<Product> _filteredResults = [];
  bool _isLoading = true;
  String _sortBy = "Default";

  @override
  void initState() {
    super.initState();
    _loadInitialData();

  }

  Future<void> _loadInitialData() async {
    try {
      // 1. Fetch valid Seller IDs (Approved, Not Restricted, Setup Complete)
      final sellerSnapshot = await FirebaseFirestore.instance
          .collection('saller') // Matches your collection name
          .where('isAdminApproved', isEqualTo: true)
          .where('isSellerRestricted', isEqualTo: false)
          .where('hasSetupStore', isEqualTo: true)
          .get();

      final List<String> validSellerIds =
      sellerSnapshot.docs.map((doc) => doc.id).toList();

      // 2. Fetch all products
      final productSnapshot = await FirebaseFirestore.instance.collection('products').get();

      // 3. Filter products based on valid seller IDs
      final products = productSnapshot.docs
          .map((doc) => Product.fromDocument(doc))
          .where((product) => validSellerIds.contains(product.sellerId))
          .toList();

      setState(() {
        _allProducts = products;
        _isLoading = false;
      });
    } catch (e) {
      debugPrint("Search Data Load Error: $e");
      setState(() => _isLoading = false);
    }
  }

  void _runFilter(String query) {
    List<Product> results = [];
    if (query.isEmpty) {
      results = [];
    } else {
      results = _allProducts
          .where((product) =>
          product.name.toLowerCase().contains(query.toLowerCase()))
          .toList();
    }

    setState(() {
      _filteredResults = results;
    });
    _applySort();
  }

  void _applySort() {
    setState(() {
      if (_sortBy == "Low to High") {
        _filteredResults.sort((a, b) => a.price.compareTo(b.price));
      } else if (_sortBy == "High to Low") {
        _filteredResults.sort((a, b) => b.price.compareTo(a.price));
      }
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA), // Light grey background
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        automaticallyImplyLeading: false,
        titleSpacing: 0,
        title: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Row(
            children: [
              IconButton(
                icon: const Icon(Icons.arrow_back_ios_new, color: Colors.black, size: 20),
                onPressed: () => Navigator.pop(context),
              ),
              Expanded(
                child: Container(
                  height: 45,
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(15),
                    border: Border.all(
                      color: _searchFocusNode.hasFocus ? Colors.green : Colors.transparent,
                      width: 1.5,
                    ),
                  ),
                  child: TextField(
                    controller: _searchController,
                    focusNode: _searchFocusNode,
                    onChanged: _runFilter,
                    style: const TextStyle(fontSize: 15),
                    decoration: InputDecoration(
                      hintText: 'Search seeds, tools...',
                      prefixIcon: const Icon(Icons.search, color: Colors.green, size: 22),
                      suffixIcon: _searchController.text.isNotEmpty
                          ? IconButton(
                        icon: const Icon(Icons.clear, color: Colors.grey, size: 18),
                        onPressed: () {
                          _searchController.clear();
                          _runFilter("");
                        },
                      )
                          : null,
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(vertical: 10),
                    ),
                  ),
                ),
              ),
              _buildFilterMenu(),
            ],
          ),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Colors.green, strokeWidth: 2))
          : Column(
        children: [
          _buildSearchHeader(),
          Expanded(
            child: _filteredResults.isEmpty && _searchController.text.isNotEmpty
                ? _buildEmptyState()
                : ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: _filteredResults.length,
              physics: const BouncingScrollPhysics(),
              itemBuilder: (context, index) => _buildProductCard(_filteredResults[index]),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterMenu() {
    return PopupMenuButton<String>(
      offset: const Offset(0, 50),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      icon: const Icon(Icons.tune_rounded, color: Colors.green),
      onSelected: (val) {
        _sortBy = val;
        _applySort();
      },
      itemBuilder: (context) => [
        _buildPopupItem("Default", Icons.sort),
        _buildPopupItem("Low to High", Icons.trending_up),
        _buildPopupItem("High to Low", Icons.trending_down),
      ],
    );
  }

  PopupMenuItem<String> _buildPopupItem(String title, IconData icon) {
    return PopupMenuItem(
      value: title,
      child: Row(
        children: [
          Icon(icon, size: 18, color: Colors.grey[700]),
          const SizedBox(width: 10),
          Text(title, style: const TextStyle(fontSize: 14)),
        ],
      ),
    );
  }

  Widget _buildSearchHeader() {
    if (_searchController.text.isEmpty) return const SizedBox.shrink();
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 10, 20, 10),
      child: Row(
        children: [
          RichText(
            text: TextSpan(
              text: "Showing results for ",
              style: TextStyle(color: Colors.grey[600], fontSize: 13),
              children: [
                TextSpan(
                  text: '"${_searchController.text}"',
                  style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.black),
                ),
              ],
            ),
          ),
          const Spacer(),
          Text("${_filteredResults.length} items",
              style: const TextStyle(color: Colors.green, fontSize: 13, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  void _navigateToFullView(Product product) {
    if(widget.isSeller==true){
      debugPrint("seller = true");
    Navigator.push(context, MaterialPageRoute(builder: (_) => HSProductfullview(
      imageUrls: product.imageUrl,
      productName: product.name,
      shortDescription: product.description,
      price: product.price,
      categoryName: product.category,
      productId: product.id,
      isRental: product.isRental,
      rating: product.avgRate,
      sellerId: product.sellerId,
    )));
  } else {
      Navigator.push(context, MaterialPageRoute(builder: (_) => customerProductfullview(
        imageUrls: product.imageUrl,
        productName: product.name,
        shortDescription: product.description,
        price: product.price,
        categoryName: product.category,
        isRental: product.isRental,
        rating: product.avgRate,
        sellerId: product.sellerId, id:  product.id, quantity: product.quantity,
      )));
    }
  }

  Widget _buildProductCard(Product product) {
    final cartRef = FirebaseFirestore.instance
        .collection('users')
        .doc(FirebaseAuth.instance.currentUser!.uid)
        .collection('wishList');

    return GestureDetector(
      onTap: (){  _navigateToFullView(product);},
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        height: 120,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.03),
              blurRadius: 15,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Row(
          children: [
            // Image Section
            Padding(
              padding: const EdgeInsets.all(10),
              child: Stack(
                children: [
                  Hero(
                    tag: product.id,
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(15),
                      child: Image.network(
                        product.imageUrl.first,
                        width: 100,
                        height: 100,
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                  if (product.isRental)
                    Positioned(
                      top: 5,
                      left: 5,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.orange.withOpacity(0.9),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Text("RENT",
                            style: TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold)),
                      ),
                    ),
                ],
              ),
            ),
            // Details Section
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(5, 15, 15, 15),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          product.name,
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          product.description,
                          style: TextStyle(color: Colors.grey[500], fontSize: 12),
                          maxLines: 1,
                        ),
                      ],
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          "PKR ${product.price.toStringAsFixed(0)}${product.isRental ? '/hr' : ''}",
                          style: const TextStyle(color: Colors.green, fontWeight: FontWeight.w800, fontSize: 16),
                        ),
                        // Mini Wishlist Toggle
                        if(widget.isSeller==false)
                        _buildWishlistButton(cartRef, product.id),
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

  Widget _buildWishlistButton(CollectionReference cartRef, String productId) {
    return StreamBuilder<DocumentSnapshot>(
      stream: cartRef.doc(productId).snapshots(),
      builder: (context, snapshot) {
        final isInWishlist = snapshot.hasData && snapshot.data!.exists;
        return GestureDetector(
          onTap: () async {
            if (isInWishlist) {
              await cartRef.doc(productId).delete();
            } else {
              await cartRef.doc(productId).set({'productId': productId, 'addedAt': Timestamp.now()});
            }
          },
          child: Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: isInWishlist ? Colors.green.withOpacity(0.1) : Colors.grey[50],
              shape: BoxShape.circle,
            ),
            child: Icon(
              isInWishlist ? Icons.favorite : Icons.favorite_border,
              size: 18,
              color: isInWishlist ? Colors.green : Colors.grey,
            ),
          ),
        );
      },
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(30),
            decoration: BoxDecoration(color: Colors.green.withOpacity(0.05), shape: BoxShape.circle),
            child: Icon(Icons.search_off_rounded, size: 70, color: Colors.green.withOpacity(0.3)),
          ),
          const SizedBox(height: 20),
          const Text("No Items Found", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87)),
          const SizedBox(height: 8),
          Text("Try different keywords or check spelling", style: TextStyle(color: Colors.grey[500])),
        ],
      ),
    );
  }
}