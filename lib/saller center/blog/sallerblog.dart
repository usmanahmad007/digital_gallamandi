import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';

import '../../Admin/Admin Home/blogs/BlogPostDetailScreen.dart';

class sallerBlogScreen extends StatefulWidget {
  const sallerBlogScreen({super.key});

  @override
  State<sallerBlogScreen> createState() => _sallerBlogScreenState();
}

class _sallerBlogScreenState extends State<sallerBlogScreen> {

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;

  // Fetch the blog data from Firestore
  Stream<QuerySnapshot> _fetchBlogs() {
    return _firestore.collection('blogs').orderBy('timestamp', descending: true).snapshots();
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Blogs'),
        actions: const [

        ],
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: _fetchBlogs(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          final blogs = snapshot.data!.docs;

          if (blogs.isEmpty) {
            return const Center(child: Text('No blogs available.'));
          }

          return ListView.builder(
            itemCount: blogs.length,
            itemBuilder: (context, index) {
              final blogData = blogs[index].data() as Map<String, dynamic>;
              final blogId = blogs[index].id;
              final title = blogData['title'];
              final description = blogData['description'];
              final imageUrl = blogData['imageUrl'];

              return GestureDetector(
                onTap: () {
                  // Example navigation to BlogPostDetailScreen
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => BlogPostDetailScreen(blogId: blogId),
                    ),
                  );
                },
                child: Container(
                  margin: const EdgeInsets.all(10),

                  decoration: BoxDecoration(
                    border: Border.all(
                      color: Colors.green, // Border color
                      width: 1.0,         // Border width
                    ),
                    borderRadius: BorderRadius.circular(8.0), // Optional: Rounded corners
                    color: Colors.green.shade300,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.2), // Shadow color
                        blurRadius: 6.0, // Blur radius
                        offset: const Offset(2, 4), // Shadow offset
                      ),
                    ],
                  ),
                  child: ListTile(
                    leading: imageUrl.isEmpty
                        ? const Icon(Icons.image)
                        : Image.network(imageUrl, width: 50, height: 50, fit: BoxFit.cover),
                    title: Text(title,maxLines: 1,overflow: TextOverflow.ellipsis,),
                    subtitle: Text(description,maxLines: 1,overflow: TextOverflow.ellipsis,),
                  ),
                ),
              );

            },
          );
        },
      ),
    );
  }
}
