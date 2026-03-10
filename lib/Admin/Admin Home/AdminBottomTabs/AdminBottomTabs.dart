import 'package:flutter/material.dart';
import 'package:zrai_mart/Admin/Admin%20Home/AdminPanelScreen.dart';
import 'package:zrai_mart/Admin/Admin%20Home/orderScreen/AdminOrdersScreen.dart';
import 'package:zrai_mart/Admin/Admin%20Home/product/AdminProductScreen.dart';

class AdminBottomTabs extends StatefulWidget {
  const AdminBottomTabs({super.key});

  @override
  _BottomTabsDemoState createState() => _BottomTabsDemoState();
}

class _BottomTabsDemoState extends State<AdminBottomTabs> {
  int _currentIndex = 0;

  // Screens corresponding to each tab
  final List<Widget> _screens = [
    const AdminPanelScreen(),
    const AdminOrdersScreen(),
    const AdminProductsScreen(),

  ];

  void _onTabTapped(int index) {
    setState(() {
      _currentIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _screens[_currentIndex], // Display the selected screen
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex, // Highlight the current tab
        onTap: _onTabTapped, // Handle tab selection
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.article),
            label: 'blogs',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.library_add_check),
            label: 'orders',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.list_alt),
            label: 'products',
          ),

        ],
      ),
    );
  }
}