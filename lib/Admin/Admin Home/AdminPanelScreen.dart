import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';

import 'blogs/BlogPostDetailScreen.dart';
import 'blogs/UpdateBlogScreen.dart';
import 'blogs/UploadBlogPostScreen.dart';

class AdminPanelScreen extends StatefulWidget {
  const AdminPanelScreen({super.key});

  @override
  _AdminPanelScreenState createState() => _AdminPanelScreenState();
}

class _AdminPanelScreenState extends State<AdminPanelScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;

  // Fetch the blog data from Firestore
  Stream<QuerySnapshot> _fetchBlogs() {
    return _firestore.collection('blogs').orderBy('timestamp', descending: true).snapshots();
  }

  // Delete a blog post
  Future<void> _deleteBlog(String blogId, String imageUrl) async {
    try {
      // Delete the image from Firebase Storage
      await _storage.refFromURL(imageUrl).delete();

      // Delete the blog post document from Firestore
      await _firestore.collection('blogs').doc(blogId).delete();

      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Blog deleted successfully')));
    } catch (e) {
      print('Error deleting blog: $e');
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Error deleting blog')));
    }
  }

  // Navigate to the update screen with blog data
  void _navigateToUpdateBlogScreen(String blogId, String title, String description, String imageUrl) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => UpdateBlogScreen(
          blogId: blogId,
          currentTitle: title,
          currentDescription: description,
          currentImageUrl: imageUrl,
        ),
      ),
    );
  }

  // Navigate to the add blog screen
  void _navigateToAddBlogScreen() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const UploadBlogPostScreen(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin Panel'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: _navigateToAddBlogScreen,
          ),
          /*IconButton(onPressed: (){
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => AdminOrdersScreen(),
              ),
            );
          }, icon: Icon(Icons.list_alt))*/
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
                onTap: (){
                  // Example navigation to BlogPostDetailScreen
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => BlogPostDetailScreen(blogId: blogId),
                    ),
                  );

                },
                child: Container(
                  margin: const EdgeInsets.all(8),
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
                    trailing: PopupMenuButton<String>(
                      onSelected: (value) {
                        if (value == 'edit') {
                          _navigateToUpdateBlogScreen(blogId, title, description, imageUrl);
                        } else if (value == 'delete') {
                          _deleteBlog(blogId, imageUrl);
                        }
                      },
                      itemBuilder: (context) => [
                        const PopupMenuItem<String>(
                          value: 'edit',
                          child: Text('Edit'),
                        ),
                        const PopupMenuItem<String>(
                          value: 'delete',
                          child: Text('Delete'),
                        ),
                      ],
                    ),
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
