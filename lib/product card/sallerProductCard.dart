import 'package:flutter/material.dart';
import '../saller center/product/sallerProductFullView.dart';

class SallerProductCard extends StatelessWidget {
  final List<String> imageUrls;
  final String categoryName;
  final String productName;
  final double price;
  final String currency;
  final VoidCallback onTap;
  final String shortDescription;
  final double? rating;
  final String productId;
  final bool isRental;
  final String quantity;
  final String sellerId;

  const SallerProductCard({
    super.key,
    required this.imageUrls,
    required this.categoryName,
    required this.productName,
    required this.price,
    this.currency = 'PKR',
    required this.onTap,
    required this.shortDescription,
    this.rating,
    required this.productId,
    required this.isRental,
    required this.quantity, required this.sellerId,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
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
                  productId: productId,
                  isRental: isRental,
                  rating: rating.toString(), sellerId: sellerId,
                ),
              ),
            );
          },
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Image Section
              Stack(
                children: [
                  SizedBox(
                    height: 200,
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
                  if (isRental)
                    Positioned(
                      top: 10,
                      right: 10,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.orange,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Text("Rental", style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
                      ),
                    ),
                ],
              ),
              Padding(
                padding: const EdgeInsets.all(12.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          categoryName.toUpperCase(),
                          style: TextStyle(fontSize: 10, letterSpacing: 1.2, fontWeight: FontWeight.bold, color: Colors.green.shade700),
                        ),
                        if (!isRental)
                          Text(
                            "Qty: $quantity",
                            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.grey),
                          ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      productName,
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87),
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Text(
                          '$currency ${price.toStringAsFixed(0)}',
                          style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w900, color: Colors.green),
                        ),
                        const Spacer(),
                        if (!isRental && rating != null)
                          Row(
                            children: [
                              const Icon(Icons.star, color: Colors.amber, size: 18),
                              Text(" $rating", style: const TextStyle(fontWeight: FontWeight.bold)),
                            ],
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}