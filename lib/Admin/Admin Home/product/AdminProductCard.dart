import 'package:flutter/material.dart';

import '../../../saller center/product/sallerProductFullView.dart';

class AdminProductCard extends StatelessWidget {
  final List<String> imageUrls; // Updated to accept multiple images
  final String categoryName;
  final String productName;
  final double price;
  final String currency;
  final VoidCallback onTap;
  final String shortDescription;
  final double? rating; // Optional rating
  final double? discountPercentage; // Optional discount percentage
  final bool isAvailable; // Optional availability status
  final Color cardColor;
  final Color textColor;
  final double borderRadius;
  final String productId;
  final bool isRental;
  final String sellerId;

  const AdminProductCard({
    super.key,
    required this.imageUrls, // Changed to List<String>
    required this.categoryName,
    required this.productName,
    required this.price,
    this.currency = 'PKR',
    required this.onTap,
    required this.shortDescription,
    this.rating,
    this.discountPercentage,
    this.isAvailable = true,
    this.cardColor = Colors.white,
    this.textColor = Colors.black,
    this.borderRadius = 8.0,
    required this.productId, required this.isRental, required this.sellerId,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(10),
      child: SizedBox(
        height: 400,
        child: Card(
          color: cardColor,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(borderRadius),
          ),
          child: InkWell(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => SallerProductFullView(
                    imageUrls: imageUrls,
                    productName: productName,
                    shortDescription: shortDescription,
                    price: price,
                    categoryName: categoryName,
                    productId: productId, isRental: isRental, rating: rating.toString(), sellerId: sellerId,
                  ),
                ),
              );
            },
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Image Carousel for multiple images
                Expanded(
                  child: PageView.builder(
                    itemCount: imageUrls.length,
                    itemBuilder: (context, index) {
                      return Image.network(
                        imageUrls[index],
                        fit: BoxFit.cover,
                        width: double.infinity,
                      );
                    },
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        productName,
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: textColor,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        categoryName,
                        style: TextStyle(
                          fontSize: 14,
                          color: textColor.withOpacity(0.7),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '$currency ${price.toStringAsFixed(2)}',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.green,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        shortDescription,
                        style: TextStyle(
                          fontSize: 12,
                          color: textColor.withOpacity(0.7),
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      isRental==false?Row(
                        children: [
                          Icon(rating==5.0? Icons.star: rating==0.0? Icons.star_border:Icons.star_half_sharp,color: Colors.green,),
                          Text(
                            '$rating',
                            style: TextStyle(
                              fontSize: 22.0,
                              fontWeight: FontWeight.bold,
                              color: Colors.green[700],
                            ),
                          ),
                        ],
                      ): Container(),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
