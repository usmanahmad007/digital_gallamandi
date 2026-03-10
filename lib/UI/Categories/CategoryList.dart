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
      final List<String> fetchedCategories = snapshot.docs
          .map((doc) => doc['category'] as String)
          .toList();

      setState(() {
        _categories = ['All', ...fetchedCategories];
      });
    } catch (e) {
      print('Error fetching categories: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: _categories.map((category) {
          final isSelected = _selectedCategory == category;
          return GestureDetector(
            onTap: () {
              setState(() {
                _selectedCategory = category;
              });
              widget.onCategorySelected(category); // Notify parent
            },
            child: Container(
              margin: const EdgeInsets.fromLTRB(0, 0, 5, 0),
              padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 15),
              decoration: BoxDecoration(
                color: isSelected ? Colors.green : Colors.transparent,
                borderRadius: BorderRadius.circular(30),
                border: Border.all(
                  color: Colors.green,
                ),
              ),
              child: Text(
                category,
                style: TextStyle(
                  color: isSelected ? Colors.white : Colors.green,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

