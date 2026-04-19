import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../app_colors.dart';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
/*import 'package:share_plus/share_plus.dart';*/

class BlogPostDetailScreen extends StatelessWidget {
  final String blogId;
  late String imageUrls;
  late String titles;
  late String descriptions;

  BlogPostDetailScreen({super.key, required this.blogId});

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<DocumentSnapshot> _fetchBlogPost() {
    return _firestore.collection('blogs').doc(blogId).get();
  }

  @override
  Widget build(BuildContext context) {
    const primaryColor = AppColors.primaryGreen;

    return Scaffold(
      backgroundColor: Colors.white,
      body: FutureBuilder<DocumentSnapshot>(
        future: _fetchBlogPost(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: primaryColor));
          }

          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          if (!snapshot.hasData || !snapshot.data!.exists) {
            return const Center(child: Text('Blog not found.'));
          }

          final blogData = snapshot.data!.data() as Map<String, dynamic>;
          final title = blogData['title'] ?? 'No Title';

          final description = blogData['description'] ?? '';
          final imageUrl = blogData['imageUrl'] ?? '';
          final timestamp = blogData['timestamp'] as Timestamp?;
          this.imageUrls=imageUrl;
          this.titles=title;
          this.descriptions=description;
          final dateStr = timestamp != null
              ? DateFormat('MMM dd, yyyy').format(timestamp.toDate())
              : "Recently";

          return CustomScrollView(
            slivers: [
              // 1. Interactive Top Bar with Image
              SliverAppBar(
                expandedHeight: 300.0,
                pinned: true,
                elevation: 0,
                backgroundColor: primaryColor,
                leading: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: CircleAvatar(
                    backgroundColor: Colors.black26,
                    child: IconButton(
                      icon: const Icon(Icons.arrow_back, color: Colors.white),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ),
                ),
                flexibleSpace: FlexibleSpaceBar(
                  background: imageUrl.isNotEmpty
                      ? Image.network(imageUrl, fit: BoxFit.cover)
                      : Container(
                    color: Colors.grey[200],
                    child: const Icon(Icons.image, size: 50, color: Colors.grey),
                  ),
                ),
              ),

              // 2. Blog Content
              SliverToBoxAdapter(
                child: Container(
                  padding: const EdgeInsets.all(24.0),
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Category / Date Badge
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: primaryColor.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(5),
                            ),
                            child: const Text(
                              "AGRI-NEWS",
                              style: TextStyle(
                                color: primaryColor,
                                fontWeight: FontWeight.bold,
                                fontSize: 10,
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Text(
                            dateStr,
                            style: TextStyle(color: Colors.grey[500], fontSize: 12),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // Title
                      Text(
                        title,
                        style: const TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          height: 1.2,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 20),

                      const Divider(height: 40),

                      // Description / Body Text
                      Text(
                        description,
                        style: TextStyle(
                          fontSize: 16,
                          height: 1.8, // Increased line height for readability
                          color: Colors.grey[800],
                          letterSpacing: 0.2,
                        ),
                      ),
                      const SizedBox(height: 100), // Bottom padding for FAB
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
     /* floatingActionButton: FloatingActionButton(
        onPressed: () {

          // Implement Share functionality here
          _shareContent(titles, descriptions, imageUrls);
        },
        backgroundColor: primaryColor,
        child: const Icon(Icons.share, color: Colors.white),
      ),*/
    );
  }

 /* // Inside your BlogPostDetailScreen class
  Future<void> _shareContent(String title, String description, String imageUrl) async {
    try {
      // 1. Download the image
      final response = await http.get(Uri.parse(imageUrl));
      final bytes = response.bodyBytes;

      // 2. Get temporary directory to store the image
      final temp = await getTemporaryDirectory();
      final path = '${temp.path}/shared_image.jpg';
      File(path).writeAsBytesSync(bytes);

      // 3. Share the image and the text (Title + Description)
      await Share.shareXFiles(
        [XFile(path)],
        text: "*$title*\n\n$description",
      );
    } catch (e) {
      debugPrint("Error sharing: $e");
    }
  }*/
}