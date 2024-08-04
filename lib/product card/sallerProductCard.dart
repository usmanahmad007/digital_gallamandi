import 'package:flutter/material.dart';
import 'package:flutter_product_card/flutter_product_card.dart';

class sallerProductCard extends StatelessWidget {
  final String imageUrl;
  final String categoryName;
  final String productName;
  final double price;
  final String currency;
  final VoidCallback onTap;
  //final VoidCallback onFavoritePressed;
  final String? shortDescription;
  final double? rating; // Optional rating
  final double? discountPercentage; // Optional discount percentage
  final bool isAvailable; // Optional availability status
  final Color cardColor;
  final Color textColor;
  final double borderRadius;

  const sallerProductCard({
    Key? key,
    required this.imageUrl,
    required this.categoryName,
    required this.productName,
    required this.price,
    this.currency = '\$',
    required this.onTap,
    // required this.onFavoritePressed,
    this.shortDescription,
    this.rating,
    this.discountPercentage,
    this.isAvailable = true,
    this.cardColor = Colors.white,
    this.textColor = Colors.black,
    this.borderRadius = 8.0,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.all(10),
      child: SizedBox(
          height: 320,
          child: ProductCard(
            imageUrl: imageUrl,
            categoryName: categoryName,
            productName: productName,
            price: price,
            currency: '\$',
            shortDescription: shortDescription,
          )),
    );
  }
}
