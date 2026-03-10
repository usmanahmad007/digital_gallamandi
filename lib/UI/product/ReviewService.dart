import 'package:cloud_firestore/cloud_firestore.dart';

class ReviewService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Fetch all reviews for a specific product
  Future<List<Map<String, dynamic>>> fetchProductReviews(String productId) async {
    try {
      final reviewsSnapshot = await _firestore
          .collection('products')
          .doc(productId)
          .collection('reviews')
          .orderBy('timestamp', descending: true)
          .get();

      return reviewsSnapshot.docs.map((doc) => doc.data()).toList();
    } catch (e) {
      throw Exception('Error fetching product reviews: $e');
    }
  }

  /// Fetch user details for a specific user ID
  Future<Map<String, dynamic>> fetchUserData(String userId) async {
    try {
      final userDoc = await _firestore.collection('users').doc(userId).get();

      if (userDoc.exists) {
        return userDoc.data()!;
      } else {
        throw Exception('User not found.');
      }
    } catch (e) {
      throw Exception('Error fetching user data: $e');
    }
  }

  /// Fetch reviews along with user details
  Future<List<Map<String, dynamic>>> fetchReviewsWithUserData(
      String productId) async {
    try {
      final reviews = await fetchProductReviews(productId);

      List<Map<String, dynamic>> reviewsWithUserData = [];
      for (var review in reviews) {
        final userId = review['userId'] ?? '';
        if (userId.isNotEmpty) {
          final userData = await fetchUserData(userId);
          reviewsWithUserData.add({
            'review': review,
            'user': userData,
          });
        }
      }

      return reviewsWithUserData;
    } catch (e) {
      throw Exception('Error fetching reviews with user data: $e');
    }
  }
}
