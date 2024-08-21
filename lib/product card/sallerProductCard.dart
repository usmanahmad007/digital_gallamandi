import 'package:flutter/material.dart';
import 'package:flutter_product_card/flutter_product_card.dart';

import '../saller center/sallerProductFullView.dart';

class sallerProductCard extends StatelessWidget {
  final String imageUrl;
  final String categoryName;
  final String productName;
  final double price;
  final String currency;
  final VoidCallback onTap;
  //final VoidCallback onFavoritePressed;
  final String shortDescription;
  final double? rating; // Optional rating
  final double? discountPercentage; // Optional discount percentage
  final bool isAvailable; // Optional availability status
  final Color cardColor;
  final Color textColor;
  final double borderRadius;
  final String productId;

  const sallerProductCard({
    Key? key,
    required this.imageUrl,
    required this.categoryName,
    required this.productName,
    required this.price,
    this.currency = 'PKR',
    required this.onTap,
    // required this.onFavoritePressed,
    required this.shortDescription,
    this.rating,
    this.discountPercentage,
    this.isAvailable = true,
    this.cardColor = Colors.white,
    this.textColor = Colors.black,
    this.borderRadius = 8.0, required this.productId,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.all(10),
      child: SizedBox(
          height: 400,
          child: ProductCard(
            imageUrl: imageUrl,
            categoryName: categoryName,
            productName: productName,
            price: price,
            currency: 'PKR',
            shortDescription: shortDescription,
            onTap: (){
              Navigator.push(context, MaterialPageRoute(builder: (context)=>SallerProductFullView(imageUrl: imageUrl, productName: productName, shortDescription: shortDescription, price: price, categoryName: categoryName,productId: productId,)));
            },
          )
      ),
    );
  }
}
