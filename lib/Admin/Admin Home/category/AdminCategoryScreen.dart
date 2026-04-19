import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../../../app_colors.dart';

class AdminCategoryScreen extends StatefulWidget {
  const AdminCategoryScreen({super.key});

  @override
  State<AdminCategoryScreen> createState() => _AdminCategoryScreenState();
}

class _AdminCategoryScreenState extends State<AdminCategoryScreen> {
  final TextEditingController _categoryController = TextEditingController();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // --- Logic Helpers ---

  Future<void> _addCategory() async {
    String name = _categoryController.text.trim();
    if (name.isEmpty) return;

    try {
      await _firestore.collection('category').add({
        'category': name,
      });
      _categoryController.clear();
      if (mounted) Navigator.pop(context);
      _showToast("Category created", Colors.green);
    } catch (e) {
      _showToast("Error: $e", Colors.red);
    }
  }

  Future<void> _updateCategory(String docId) async {
    String newName = _categoryController.text.trim();
    if (newName.isEmpty) return;

    try {
      await _firestore.collection('category').doc(docId).update({
        'category': newName,
      });
      _categoryController.clear();
      if (mounted) Navigator.pop(context);
      _showToast("Category updated", Colors.blue);
    } catch (e) {
      _showToast("Update failed", Colors.red);
    }
  }

  Future<void> _deleteCategory(String docId) async {
    await _firestore.collection('category').doc(docId).delete();
    _showToast("Category removed", Colors.black87);
  }

  void _showToast(String msg, Color bg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg, style: const TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: bg,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        margin: const EdgeInsets.all(15),
      ),
    );
  }

  // --- Redesigned Dialog ---

  void _showCategoryDialog({String? docId, String? currentName}) {
    if (currentName != null) _categoryController.text = currentName;
    else _categoryController.clear();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Text(docId == null ? "New Category" : "Edit Name",
            style: const TextStyle(fontWeight: FontWeight.w900)),
        content: TextField(
          controller: _categoryController,
          autofocus: true,
          decoration: InputDecoration(
            hintText: "Category Name",
            prefixIcon: const Icon(Icons.label_important_outline, color: AppColors.primaryGreen),
            filled: true,
            fillColor: Colors.grey[50],
            enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(15),
                borderSide: BorderSide(color: Colors.grey.shade200)),
            focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(15),
                borderSide: const BorderSide(color: AppColors.primaryGreen, width: 2)),
          ),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Cancel", style: TextStyle(color: Colors.grey))
          ),
          ElevatedButton(
            onPressed: () => docId == null ? _addCategory() : _updateCategory(docId),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryGreen,
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            ),
            child: Text(docId == null ? "Create" : "Save",
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFBFBFD),
      appBar: AppBar(
        title: const Text('Manage Categories',
            style: TextStyle(color: Colors.black, fontWeight: FontWeight.w800)),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.black, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: _firestore.collection('category').snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: AppColors.primaryGreen));
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.category_outlined, size: 100, color: Colors.grey[300]),
                  const SizedBox(height: 16),
                  const Text("No categories listed yet",
                      style: TextStyle(color: Colors.grey, fontSize: 16)),
                ],
              ),
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.all(20),
            itemCount: snapshot.data!.docs.length,
            separatorBuilder: (context, index) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              var doc = snapshot.data!.docs[index];
              String name = doc['category'] ?? "";

              return Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.grey.shade100),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.02),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    )
                  ],
                ),
                child: ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                  leading: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppColors.primaryGreen.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.grid_view_rounded,
                        color: AppColors.primaryGreen, size: 20),
                  ),
                  title: Text(name,
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _actionButton(
                          icon: Icons.edit_rounded,
                          color: Colors.blueAccent,
                          onTap: () => _showCategoryDialog(docId: doc.id, currentName: name)
                      ),
                      const SizedBox(width: 8),
                      _actionButton(
                          icon: Icons.delete_outline_rounded,
                          color: Colors.redAccent,
                          onTap: () => _confirmDeletion(doc.id)
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showCategoryDialog(),
        backgroundColor: AppColors.primaryGreen,
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text("Add Category", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      ),
    );
  }

  Widget _actionButton({required IconData icon, required Color color, required VoidCallback onTap}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, color: color, size: 20),
      ),
    );
  }

  void _confirmDeletion(String id) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Delete Category?"),
        content: const Text("Are you sure? This cannot be undone."),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Back")),
          TextButton(
              onPressed: () { Navigator.pop(context); _deleteCategory(id); },
              child: const Text("Delete", style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold))
          ),
        ],
      ),
    );
  }
}