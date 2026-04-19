import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../../Admin/Admin Home/blogs/BlogPostDetailScreen.dart';
import '../../app_colors.dart';

class sallerBlogScreen extends StatefulWidget {
  const sallerBlogScreen({super.key});

  @override
  State<sallerBlogScreen> createState() => _sallerBlogScreenState();
}

class _sallerBlogScreenState extends State<sallerBlogScreen> {
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
        leading: _isSearching
            ? IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.textDark),
          onPressed: () {
            setState(() {
              _isSearching = false;
              _searchController.clear();
              _searchQuery = "";
            });
          },
        )
            : null,
        title: _isSearching
            ? TextField(
          controller: _searchController,
          autofocus: true,
          decoration: const InputDecoration(
            hintText: "Search updates...",
            border: InputBorder.none,
            hintStyle: TextStyle(color: AppColors.textGrey),
          ),
          style: const TextStyle(color: AppColors.textDark, fontSize: 16),
          onChanged: (value) {
            setState(() {
              _searchQuery = value.toLowerCase();
            });
          },
        )
            : const Text(
          "Agriculture News",
          style: TextStyle(color: AppColors.textDark, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: Icon(_isSearching ? Icons.close : Icons.search, color: AppColors.textDark),
            onPressed: () {
              setState(() {
                if (_isSearching) {
                  _searchController.clear();
                  _searchQuery = "";
                } else {
                  _isSearching = true;
                }
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

          // Filtering logic
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
                    _searchQuery.isEmpty ? 'No news posted yet.' : 'No results for "$_searchQuery"',
                    style: const TextStyle(color: AppColors.textGrey),
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

              // Featured look for first item only if NOT searching
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

  // Large Card for Latest News
  Widget _buildFeaturedBlog(String id, Map<String, dynamic> data, Color primary) {
    return GestureDetector(
      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => BlogPostDetailScreen(blogId: id))),
      child: Container(
        margin: const EdgeInsets.only(bottom: 24),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          color: Colors.white,
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 15, offset: const Offset(0, 5))],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
              child: data['imageUrl'].toString().isNotEmpty
                  ? Image.network(
                data['imageUrl'],
                height: 200,
                width: double.infinity,
                fit: BoxFit.cover,
              )
                  : Container(
                height: 200,
                color: primary.withOpacity(0.1),
                child: Icon(Icons.image, color: primary, size: 40),
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
                    child: Text("LATEST UPDATE", style: TextStyle(color: primary, fontWeight: FontWeight.bold, fontSize: 10)),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    data['title'] ?? 'Untitled',
                    style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.textDark),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    data['description'] ?? '',
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(color: AppColors.textGrey, fontSize: 14),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Compact Tile for List view
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
              child: data['imageUrl'].toString().isNotEmpty
                  ? Image.network(
                data['imageUrl'],
                width: 110,
                height: 110,
                fit: BoxFit.cover,
              )
                  : Container(
                width: 110,
                color: Colors.grey[100],
                child: const Icon(Icons.image, color: Colors.grey),
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
                      data['title'] ?? 'Untitled',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: AppColors.textDark),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      "Read More →",
                      style: TextStyle(color: primary, fontWeight: FontWeight.bold, fontSize: 12),
                    ),
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