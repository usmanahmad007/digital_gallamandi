import 'package:flutter/material.dart';
import 'ReviewService.dart';

class ProductReviewsWidget extends StatefulWidget {
  final String productId;

  const ProductReviewsWidget({super.key, required this.productId});

  @override
  _ProductReviewsWidgetState createState() => _ProductReviewsWidgetState();
}

class _ProductReviewsWidgetState extends State<ProductReviewsWidget> {
  final ReviewService _reviewService = ReviewService();
  late Future<List<Map<String, dynamic>>> _reviewsFuture;

  @override
  void initState() {
    super.initState();
    _reviewsFuture = _reviewService.fetchReviewsWithUserData(widget.productId);
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: _reviewsFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        } else if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return const Column(
            children: [
              Padding(
                padding: EdgeInsets.symmetric(vertical: 10.0),
                child: Text(
                  "Customer Reviews",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ),
              Text('No reviews available.',textAlign: TextAlign.center,),
            ],
          );
        }

        final reviewsWithUserData = snapshot.data!;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 10.0),
              child: Text(
                "Customer Reviews",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: reviewsWithUserData.length,
              itemBuilder: (context, index) {
                final reviewData = reviewsWithUserData[index];
                final user = reviewData['user'];
                final review = reviewData['review'];

                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8.0),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      CircleAvatar(
                        radius: 25,
                        backgroundImage: user['profileImage'] != null
                            ? NetworkImage(user['profileImage'])
                            : const AssetImage('assets/img_2.png') // Default image
                        as ImageProvider,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Text(
                                  user['name'] ?? 'Anonymous',
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(width: 10,),
                                Icon(
                                  review['rating'] == 5.0
                                      ? Icons.star
                                      : review['rating'] == 0.0
                                      ? Icons.star_border
                                      : Icons.star_half_sharp,
                                  color: Colors.green,
                                ),
                                Text(
                                  '${review['rating'].toStringAsFixed(1)}',
                                  style: TextStyle(
                                    fontSize: 16.0,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.green[700],
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text(
                              review['review'] ?? '',
                              style: const TextStyle(fontSize: 14),
                            ),
                            const SizedBox(height: 4),

                          ],
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ],
        );
      },
    );
  }
}
