import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class BlogPostDetailScreen extends StatelessWidget {
  final String blogId;

  BlogPostDetailScreen({super.key, required this.blogId});

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<DocumentSnapshot> _fetchBlogPost() {
    return _firestore.collection('blogs').doc(blogId).get();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Blog Post Detail'),
      ),
      body: FutureBuilder<DocumentSnapshot>(
        future: _fetchBlogPost(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          if (!snapshot.hasData || !snapshot.data!.exists) {
            return const Center(child: Text('Blog not found.'));
          }

          final blogData = snapshot.data!.data() as Map<String, dynamic>;
          final title = blogData['title'];
          final description = blogData['description'];
          final imageUrl = blogData['imageUrl'];

          return Padding(
            padding: const EdgeInsets.all(16.0),
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  imageUrl.isEmpty
                      ? const Icon(Icons.image, size: 100)
                      : Image.network(imageUrl, fit: BoxFit.cover),
                  const SizedBox(height: 16),
                  Text(
                    title,
                    style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    description,
                    style: const TextStyle(fontSize: 16),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
