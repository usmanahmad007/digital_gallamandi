import 'package:flutter/material.dart';

class ProductCard extends StatelessWidget {
  final String imageUrl;
  final String categoryName;
  final String productName;
  final double price;
  final String currency;
  final VoidCallback onTap;
  final VoidCallback onFavoritePressed;
  final String? shortDescription;
  final double? rating; // Optional rating
  final double? discountPercentage; // Optional discount percentage
  final bool isAvailable; // Optional availability status
  final bool isRental; // Indicates if the product is for rental
  final Color cardColor;
  final Color textColor;
  final double borderRadius;

  const ProductCard({
    super.key,
    required this.imageUrl,
    required this.categoryName,
    required this.productName,
    required this.price,
    this.currency = '\$',
    required this.onTap,
    required this.onFavoritePressed,
    this.shortDescription,
    this.rating,
    this.discountPercentage,
    this.isAvailable = true,
    this.isRental = false, // Default to false
    this.cardColor = Colors.white,
    this.textColor = Colors.black,
    this.borderRadius = 8.0,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(10),
      child: Stack(
        children: [
          Container(
            decoration: BoxDecoration(
              color: cardColor,
              borderRadius: BorderRadius.circular(borderRadius),
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.3),
                  blurRadius: 6,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.vertical(
                    top: Radius.circular(borderRadius),
                  ),
                  child: Image.network(
                    imageUrl,
                    height: 180,
                    width: double.infinity,
                    fit: BoxFit.cover,
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        categoryName,
                        style: TextStyle(
                          fontSize: 14,
                          color: textColor.withOpacity(0.6),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        productName,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: textColor,
                        ),
                      ),
                      if (shortDescription != null) ...[
                        const SizedBox(height: 4),
                        Text(
                          shortDescription!,
                          style: TextStyle(
                            fontSize: 12,
                            color: textColor.withOpacity(0.6),
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                      const SizedBox(height: 8),
                      Text(
                        '$currency$price',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: textColor,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          if (isRental) // Display "Rental" badge if the product is for rental
            Positioned(
              top: 10,
              left: 10,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  vertical: 4,
                  horizontal: 8,
                ),
                decoration: BoxDecoration(
                  color: Colors.orange,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: const Text(
                  'Rental',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ),
            ),
          if (!isAvailable)
            Positioned(
              top: 10,
              right: 10,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  vertical: 4,
                  horizontal: 8,
                ),
                decoration: BoxDecoration(
                  color: Colors.red,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: const Text(
                  'Unavailable',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
