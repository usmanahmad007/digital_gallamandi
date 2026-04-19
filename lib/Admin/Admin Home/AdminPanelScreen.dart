import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../app_colors.dart';
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

  Stream<QuerySnapshot> _fetchBlogs() {
    return _firestore.collection('blogs').orderBy('timestamp', descending: true).snapshots();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB), // Very light grey/white
      appBar: AppBar(
        title: const Text('Blog Management',
            style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18, color: Colors.black)),
        centerTitle: false, // Left aligned title for SaaS look
        backgroundColor: Colors.white,
        elevation: 0,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: TextButton.icon(
              onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const UploadBlogPostScreen())),
              icon: const Icon(Icons.add_circle_outline, size: 20, color: AppColors.primaryGreen),
              label: const Text("New Post", style: TextStyle(color: AppColors.primaryGreen, fontWeight: FontWeight.bold)),
              style: TextButton.styleFrom(backgroundColor: AppColors.primaryGreen.withOpacity(0.1)),
            ),
          ),
        ],
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: _fetchBlogs(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(strokeWidth: 2));
          }
          final blogs = snapshot.data?.docs ?? [];
          if (blogs.isEmpty) return _buildEmptyState();

          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: blogs.length,
            separatorBuilder: (context, index) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final blog = blogs[index].data() as Map<String, dynamic>;
              final blogId = blogs[index].id;
              final String title = blog['title'] ?? "";
              final String desc = blog['description'] ?? "";
              final String img = blog['imageUrl'] ?? "";
              final Timestamp? time = blog['timestamp'];
              final String date = time != null ? DateFormat('MMM dd, yyyy').format(time.toDate()) : "Draft";

              return _buildSaaSCard(blogId, title, desc, img, date);
            },
          );
        },
      ),
    );
  }

  Widget _buildSaaSCard(String id, String title, String desc, String img, String date) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: InkWell(
        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => BlogPostDetailScreen(blogId: id))),
        child: Row(
          children: [
            // 1. Squared Image with Rounded Corners
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: img.isNotEmpty
                  ? Image.network(img, width: 85, height: 85, fit: BoxFit.cover)
                  : Container(width: 85, height: 85, color: Colors.grey[100], child: const Icon(Icons.article_outlined)),
            ),
            const SizedBox(width: 16),

            // 2. Info Section
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(date, style: TextStyle(fontSize: 10, color: Colors.grey.shade500, fontWeight: FontWeight.w600, letterSpacing: 0.5)),
                  const SizedBox(height: 4),
                  Text(title,
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Color(0xFF1F2937)),
                      maxLines: 1, overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 4),
                  Text(desc,
                      style: TextStyle(color: Colors.grey.shade600, fontSize: 12, height: 1.3),
                      maxLines: 2, overflow: TextOverflow.ellipsis),
                ],
              ),
            ),

            // 3. Simple Action Menu
            PopupMenuButton<String>(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              icon: Icon(Icons.more_vert, color: Colors.grey.shade400),
              onSelected: (val) {
                if (val == 'edit') {
                  Navigator.push(context, MaterialPageRoute(builder: (context)=>UpdateBlogScreen(blogId: id, currentTitle: title, currentDescription: desc, currentImageUrl: img)));
                } else if (val == 'delete') {
                  _confirmDelete(id, img);
                }
              },
              itemBuilder: (context) => [
                const PopupMenuItem(value: 'edit', child: Text("Edit")),
                const PopupMenuItem(value: 'delete', child: Text("Delete", style: TextStyle(color: Colors.red))),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _confirmDelete(String id, String img) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        title: const Text("Delete Post?"),
        content: const Text("This action cannot be undone."),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel")),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              if (img.isNotEmpty) await _storage.refFromURL(img).delete();
              await _firestore.collection('blogs').doc(id).delete();
            },
            child: const Text("Delete", style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.post_add, size: 48, color: Colors.grey),
          const SizedBox(height: 12),
          Text("No Content Yet", style: TextStyle(color: Colors.grey.shade600, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}