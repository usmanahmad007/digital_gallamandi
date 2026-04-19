import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class CategoryList extends StatefulWidget {
  final Function(String) onCategorySelected;

  const CategoryList({super.key, required this.onCategorySelected});

  @override
  _CategoryListState createState() => _CategoryListState();
}

class _CategoryListState extends State<CategoryList> {
  String? _selectedCategory = "All";
  List<String> _categories = ['All'];

  @override
  void initState() {
    super.initState();
    _fetchCategoriesFromFirestore();
  }

  Future<void> _fetchCategoriesFromFirestore() async {
    try {
      final snapshot = await FirebaseFirestore.instance.collection('category').get();

      // 1. Map the documents to a list of strings
      final List<String> fetchedCategories = snapshot.docs
          .map((doc) => doc['category'] as String)
          .toList();

      if (mounted) {
        setState(() {
          // 2. Reverse the fetched list and spread it after 'All'
          _categories = ['All', ...fetchedCategories.reversed];
        });
      }
    } catch (e) {
      debugPrint('Error fetching categories: $e');
    }
  }
  @override
  Widget build(BuildContext context) {
    return Container(
      height: 55,
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: _categories.length,
        itemBuilder: (context, index) {
          final category = _categories[index];
          final isSelected = _selectedCategory == category;

          return GestureDetector(
            onTap: () {
              setState(() => _selectedCategory = category);
              widget.onCategorySelected(category);
            },
            child: AnimatedScale(
              duration: const Duration(milliseconds: 200),
              scale: isSelected ? 1.05 : 1.0,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                margin: const EdgeInsets.only(right: 12),
                padding: const EdgeInsets.symmetric(horizontal: 24),
                decoration: BoxDecoration(
                  // Selected gets a lush green, unselected is a very soft mint
                  color: isSelected
                      ? Colors.green[700]
                      : Colors.green.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: isSelected
                      ? [
                    BoxShadow(
                      color: Colors.green.withOpacity(0.3),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    )
                  ]
                      : [],
                  border: Border.all(
                    color: isSelected
                        ? Colors.green[800]!
                        : Colors.green.withOpacity(0.2),
                    width: 1.5,
                  ),
                ),
                alignment: Alignment.center,
                child: Text(
                  category,
                  style: TextStyle(
                    color: isSelected ? Colors.white : Colors.green[900],
                    fontWeight: isSelected ? FontWeight.w900 : FontWeight.w600,
                    fontSize: 14,
                    letterSpacing: 0.3,
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}