import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:zrai_mart/UI/product/productFullView.dart';
import '../../models/Product.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  _SearchScreenState createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
  List<Product> _searchResults = [];
  List<Product> _selectedProducts = [];
  final CollectionReference _productCollection =
  FirebaseFirestore.instance.collection('products');
  bool tapFlag=false;

  void _performSearch(String query) async {
    if (query.isEmpty) {
      setState(() {
        _searchResults.clear();
        _selectedProducts.clear();
      });
      return;
    }

    final querySnapshot = await _productCollection
        .where('title', isGreaterThanOrEqualTo: query)
        .where('title', isLessThanOrEqualTo: '$query\uf8ff')
        .get();

    final fetchedProducts = querySnapshot.docs
        .map((doc) => Product.fromDocument(doc))
        .toList();

    setState(() {
      _searchResults = fetchedProducts;
      _selectedProducts.clear(); // Clear selected products on new search
    });
  }

  void _fetchProductsWithTitle(String title) async {
    final querySnapshot =
    await _productCollection.where('title', isEqualTo: title).get();

    final fetchedProducts = querySnapshot.docs
        .map((doc) => Product.fromDocument(doc))
        .toList();

    setState(() {
      _selectedProducts = fetchedProducts;
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
    final width = MediaQuery.of(context).size.width;
    final height = MediaQuery.of(context).size.height;

    return Scaffold(
      appBar: AppBar(
        title: Container(
          height: 40,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: _searchFocusNode.hasFocus
                ? Colors.greenAccent.withOpacity(0.2)
                : Colors.grey[200],
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: _searchFocusNode.hasFocus ? Colors.green : Colors.transparent,
            ),
          ),
          child: Row(
            children: [
              Icon(Icons.search,
                  color: _searchFocusNode.hasFocus ? Colors.green : Colors.grey),
              const SizedBox(width: 8),
              Expanded(
                child: TextField(
                  controller: _searchController,
                  focusNode: _searchFocusNode,
                  decoration: const InputDecoration(
                    hintText: 'Search...',
                    border: InputBorder.none,
                  ),
                  onChanged: (value) {
                    setState(() {
                      tapFlag=false;

                    });
                    _performSearch(value);
                  },
                ),
              ),
              Icon(Icons.filter_list,
                  color: _searchFocusNode.hasFocus ? Colors.green : Colors.grey),
            ],
          ),
        ),
        automaticallyImplyLeading: false,
      ),
      body: Column(
        children: [
          if (_searchResults.isEmpty && _searchController.text.isNotEmpty)
            _buildEmptyResults(height),
          if (_searchResults.isNotEmpty && tapFlag==false)
            Expanded(
              child: ListView.builder(
                itemCount: _searchResults.length,
                itemBuilder: (context, index) {
                  final product = _searchResults[index];
                  return ListTile(
                    title: Text(product.name),
                    onTap: () {
                      setState(() {
                        tapFlag=true;
                        _searchController.text=product.name;

                      });
                      _fetchProductsWithTitle(product.name);
                    },
                  );
                },
              ),
            ),
          if (_selectedProducts.isNotEmpty)
            Expanded(
              child: ListView.builder(
                itemCount: _selectedProducts.length,
                itemBuilder: (context, index) {
                  final product = _selectedProducts[index];
                  return _buildProductItem(product, context);
                },
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildEmptyResults(double height) {
    return Expanded(
      child: Center(  // Use a Center widget to avoid unnecessary Column nesting
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  RichText(
                    text: TextSpan(
                      text: 'Result for ',
                      style: const TextStyle(color: Colors.black, fontSize: 24),
                      children: <TextSpan>[
                        TextSpan(
                          text: '"${_searchController.text}"',
                          style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.green,
                              fontSize: 24),
                        ),
                      ],
                    ),
                  ),
                  const Text(
                    "0 found",
                    style: TextStyle(color: Colors.green),
                  ),
                ],
              ),
              Image.asset("assets/emptyResult.png"),
              const Text(
                "Not found",
                style: TextStyle(
                    fontSize: 18, color: Colors.black, fontWeight: FontWeight.bold),
              ),
              const Padding(
                padding: EdgeInsets.fromLTRB(20, 8, 20, 0),
                child: Text(
                  "Sorry, the keyword you entered cannot be found, please check again or search with another keyword",
                  textAlign: TextAlign.center,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }


  Widget _buildProductItem(Product product,BuildContext context) {
    double rating = double.parse(product.avgRate);
    String formattedRating = rating.toStringAsFixed(1);
    double ratingToDouble = double.parse(formattedRating); // Convert to double

    final width = MediaQuery.of(context).size.width;
    final List<String> imageUrls = List<String>.from(product.imageUrl ?? []);

    final cartRef = FirebaseFirestore.instance
        .collection('users')
        .doc(FirebaseAuth.instance.currentUser!.uid)
        .collection('wishList');

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => Productfullview(
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
            ),
          ),
        );
      },
      child: Container(
        width: width / 0.6,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10.0),
          boxShadow: const [
            BoxShadow(
              color: Colors.black26,
              blurRadius: 6,
              offset: Offset(0, 2),
            ),
          ],
          color: Colors.white,
        ),
        margin: const EdgeInsets.all(8.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Stack(
              children: [
                ClipRRect(
                  borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(10.0)),
                  child: Image.network(
                    imageUrls[0],
                    fit: BoxFit.cover,
                    width: double.infinity,
                    height: 130,
                  ),
                ),
               product.isRental==false? Positioned(
                  right: 0,
                  child: FutureBuilder<DocumentSnapshot>(
                    future: cartRef.doc(product.id).get(),
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
                              await cartRef.doc(product.id).delete();
                              setState(() {

                              });
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Removed from wishlist'),
                                ),
                              );
                            } else {
                              // Add to wishlist
                              await cartRef.doc(product.id).set({
                                'productId': product.id,
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
                  ),
                ):Container(),
              ],
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 8, 8, 0),
              child: Text(
                product.name,
                style:
                const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 0, 8, 0),
              child: Text(
                product.description,
                style: const TextStyle(fontSize: 14, color: Colors.grey),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8.0),
              child: Text(
                'PKR${product.price.toStringAsFixed(2)}',
                style: const TextStyle(fontSize: 16, color: Colors.green),
              ),
            ),
            product.isRental==false?Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8.0),
              child: Row(
                children: [
                  Icon(
                    ratingToDouble == 5.0
                        ? Icons.star
                        : ratingToDouble == 0.0
                        ? Icons.star_border
                        : Icons.star_half,
                    color: Colors.green,
                  ),
                  Text(
                    formattedRating.toString(),
                    style: const TextStyle(
                        fontSize: 16,
                        color: Colors.green,
                        fontWeight: FontWeight.bold),
                  )
                ],
              ),
            ) : Container(),
            const SizedBox(height: 10,)
          ],
        ),
      ),
    );
  }
}
