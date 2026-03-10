import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:zrai_mart/UI/product/productFullView.dart';

class RelatedProductsSlider extends StatefulWidget {
  final String category;
  final String currentProductId;

  const RelatedProductsSlider({
    super.key,
    required this.category,
    required this.currentProductId,
  });

  @override
  _RelatedProductsSliderState createState() => _RelatedProductsSliderState();
}

class _RelatedProductsSliderState extends State<RelatedProductsSlider> {
  late Future<List<Map<String, dynamic>>> _relatedProductsFuture;

  @override
  void initState() {
    super.initState();
    _relatedProductsFuture = _fetchRelatedProducts();
  }

  Future<List<Map<String, dynamic>>> _fetchRelatedProducts() async {
    final snapshot = await FirebaseFirestore.instance
        .collection('products')
        .where('category', isEqualTo: widget.category)
        .orderBy('averageRating', descending: true)
        .limit(10)
        .get();

    return snapshot.docs
        .where((doc) => doc.id != widget.currentProductId)
        .map((doc) => {'id': doc.id, ...doc.data()})
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    final width=MediaQuery.of(context).size.width;
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: _relatedProductsFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError || !snapshot.hasData || snapshot.data!.isEmpty) {
          return const Center(
            child: Text('No related products found.'),
          );
        }

        final relatedProducts = snapshot.data!;

        return SizedBox(
          height: 250.0,

          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: relatedProducts.length,
            itemBuilder: (context, index) {
              final product = relatedProducts[index];
              return GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => Productfullview(
                        id: product['id'],
                        imageUrls: List<String>.from(product['imageUrls']),
                        productName: product['title'],
                        shortDescription: product['description'],
                        price: double.parse(product['price'].toString()),
                        categoryName: product['category'],
                        sellerId: product['sellerId'],
                        isRental: product['isRental'] ?? false,
                        rating: product['averageRating'].toString(),
                        quantity: product['quantity'].toString(),
                      ),
                    ),
                  );
                },
                child: SizedBox(
                  height: 250.0,
                  width: 180,
                  child: Card(
                    margin: const EdgeInsets.symmetric(horizontal: 8.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(12.0), // Adjust the radius as needed
                          child: Image.network(
                            product['imageUrls'][0],
                            height: 150.0,
                            width: 170.0,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) =>
                            const Icon(Icons.broken_image, size: 50),
                          ),
                        ),
                        const SizedBox(height: 4.0),
                        Padding(
                          padding: const EdgeInsets.fromLTRB(4,0,4,0),
                          child: Text(
                            product['title'],
                            style: const TextStyle(
                              fontSize: 16.0,
                              fontWeight: FontWeight.bold,
                            ),
                            overflow: TextOverflow.ellipsis,
                            maxLines: 1,
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.fromLTRB(4,4,4,4),
                          child: product['isRental'] == false
                              ? Row(
                            children: [
                              Icon(
                                product['averageRating'] == '5.0'
                                    ? Icons.star
                                    : product['averageRating'] == '0.0'
                                    ? Icons.star_border
                                    : Icons.star_half_sharp,
                                color: Colors.green,
                                size: 20,
                              ),
                              Text(
                                '${product['averageRating']}',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.green[700],
                                  fontSize: 18
                                ),
                              ),
                            ],
                          )
                              : Container(),
                        ),
                        Padding(
                          padding: const EdgeInsets.fromLTRB(4,0,4,0),
                          child: Text( product['isRental']==false?
                            'PKR ${product['price']}/kg':'PKR ${product['price']}/hr',
                            style: TextStyle(
                              fontSize: 20.0,
                              color: Colors.green[700],fontWeight: FontWeight.bold
                            ),
                          ),
                        ),

                        const SizedBox(height: 4.0),


                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }
}
