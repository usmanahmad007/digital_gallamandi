import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../../Admin/Admin Home/blogs/BlogPostDetailScreen.dart';
import '../../app_colors.dart';

class BlogScreen extends StatefulWidget {
  const BlogScreen({super.key});

  @override
  State<BlogScreen> createState() => _BlogScreenState();
}

class _BlogScreenState extends State<BlogScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Search state variables
  bool _isSearching = false;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = "";

  Stream<QuerySnapshot> _fetchBlogs() {
    return _firestore.collection('blogs').orderBy('timestamp', descending: true).snapshots();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const primaryColor = AppColors.primaryGreen;

    return Scaffold(
      backgroundColor: const Color(0xffF9FBFF),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        leading: _isSearching ? IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () {
            setState(() {
              _isSearching = false;
              _searchController.clear();
              _searchQuery = "";
            });
          },
        ) : null,
        title: _isSearching
            ? TextField(
          controller: _searchController,
          autofocus: true,
          decoration: const InputDecoration(
            hintText: "Search titles or descriptions...",
            border: InputBorder.none,
            hintStyle: TextStyle(color: Colors.grey),
          ),
          style: const TextStyle(color: Colors.black, fontSize: 16),
          onChanged: (value) {
            setState(() {
              _searchQuery = value.toLowerCase();
            });
          },
        )
            : const Text(
          "Agri Insights",
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        actions: [
          _isSearching
              ? IconButton(
            icon: const Icon(Icons.close, color: Colors.black),
            onPressed: () {
              setState(() {
                _searchController.clear();
                _searchQuery = "";
              });
            },
          )
              : IconButton(
            icon: const Icon(Icons.search, color: Colors.black),
            onPressed: () {
              setState(() {
                _isSearching = true;
              });
            },
          )
        ],
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: _fetchBlogs(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: primaryColor));
          }
          if (snapshot.hasError) return Center(child: Text('Error: ${snapshot.error}'));

          // Filter blogs based on search query
          final allBlogs = snapshot.data!.docs;
          final filteredBlogs = allBlogs.where((doc) {
            final data = doc.data() as Map<String, dynamic>;
            final title = (data['title'] ?? "").toString().toLowerCase();
            final desc = (data['description'] ?? "").toString().toLowerCase();
            return title.contains(_searchQuery) || desc.contains(_searchQuery);
          }).toList();

          if (filteredBlogs.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.search_off, size: 80, color: Colors.grey[300]),
                  const SizedBox(height: 16),
                  Text(
                    _searchQuery.isEmpty ? 'No insights available yet.' : 'No results found for "$_searchQuery"',
                    style: TextStyle(color: Colors.grey[600]),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: filteredBlogs.length,
            itemBuilder: (context, index) {
              final blogData = filteredBlogs[index].data() as Map<String, dynamic>;
              final blogId = filteredBlogs[index].id;

              // Design choice: Only show featured style if not searching
              if (index == 0 && !_isSearching) {
                return _buildFeaturedBlog(blogId, blogData, primaryColor);
              }

              return _buildStandardBlogTile(blogId, blogData, primaryColor);
            },
          );
        },
      ),
    );
  }

  // Helper methods (_buildFeaturedBlog & _buildStandardBlogTile) remain the same as your provided code
  Widget _buildFeaturedBlog(String id, Map<String, dynamic> data, Color primary) {
    return GestureDetector(
      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => BlogPostDetailScreen(blogId: id))),
      child: Container(
        margin: const EdgeInsets.only(bottom: 24),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          color: Colors.white,
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 15)],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
              child: Image.network(
                data['imageUrl'],
                height: 200,
                width: double.infinity,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => Container(color: Colors.grey[200], height: 200, child: const Icon(Icons.image_not_supported)),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(color: primary.withOpacity(0.1), borderRadius: BorderRadius.circular(5)),
                    child: Text("LATEST", style: TextStyle(color: primary, fontWeight: FontWeight.bold, fontSize: 10)),
                  ),
                  const SizedBox(height: 10),
                  Text(data['title'], style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Text(
                    data['description'],
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(color: Colors.grey[600], fontSize: 14),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStandardBlogTile(String id, Map<String, dynamic> data, Color primary) {
    return GestureDetector(
      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => BlogPostDetailScreen(blogId: id))),
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        height: 110,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10)],
        ),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: const BorderRadius.horizontal(left: Radius.circular(16)),
              child: Image.network(
                data['imageUrl'],
                width: 110,
                height: 110,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => Container(color: Colors.grey[100], width: 110, child: const Icon(Icons.image)),
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      data['title'],
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                    ),
                    const SizedBox(height: 5),
                    Text("Read More →", style: TextStyle(color: primary, fontWeight: FontWeight.bold, fontSize: 12)),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}