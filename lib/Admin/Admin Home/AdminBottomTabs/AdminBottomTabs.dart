import 'package:flutter/material.dart';
import 'package:zrai_mart/Admin/Admin%20Home/AdminPanelScreen.dart';
import 'package:zrai_mart/Admin/Admin%20Home/dashboard/AdminDashboard.dart';
import 'package:zrai_mart/Admin/Admin%20Home/orderScreen/AdminOrdersScreen.dart';
import 'package:zrai_mart/Admin/Admin%20Home/product/AdminProductScreen.dart';
import 'package:flutter/material.dart';
import '../../../app_colors.dart'; // Ensure this path is correct

class AdminBottomTabs extends StatefulWidget {
  const AdminBottomTabs({super.key});

  @override
  State<AdminBottomTabs> createState() => _AdminBottomTabsState();
}

class _AdminBottomTabsState extends State<AdminBottomTabs> {
  int _currentIndex = 0;

  final List<Widget> _screens = [
    AdminDashboard(),
    const AdminPanelScreen(),
    const AdminOrdersScreen(),
    const AdminProductsScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack( // Use IndexedStack to maintain scroll state of each page
        index: _currentIndex,
        children: _screens,
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 20,
              offset: const Offset(0, -5),
            ),
          ],
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
            child: BottomNavigationBar(
              currentIndex: _currentIndex,
              onTap: (index) => setState(() => _currentIndex = index),

              // --- Styling ---
              type: BottomNavigationBarType.fixed, // Necessary for 4+ items
              backgroundColor: Colors.transparent,
              elevation: 0,
              selectedItemColor: AppColors.primaryGreen,
              unselectedItemColor: Colors.grey.shade400,
              selectedFontSize: 12,
              unselectedFontSize: 12,
              selectedLabelStyle: const TextStyle(fontWeight: FontWeight.bold),
              showUnselectedLabels: true,

              items: [
                _buildNavItem(Icons.grid_view_rounded, Icons.grid_view_outlined, "Dashboard"),
                _buildNavItem(Icons.article_rounded, Icons.article_outlined, "Blogs"),
                _buildNavItem(Icons.local_shipping_rounded, Icons.local_shipping_outlined, "Orders"),
                _buildNavItem(Icons.inventory_2_rounded, Icons.inventory_2_outlined, "Products"),
              ],
            ),
          ),
        ),
      ),
    );
  }

  BottomNavigationBarItem _buildNavItem(IconData activeIcon, IconData inactiveIcon, String label) {
    return BottomNavigationBarItem(
      icon: Padding(
        padding: const EdgeInsets.only(bottom: 4),
        child: Icon(inactiveIcon),
      ),
      activeIcon: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: AppColors.primaryGreen.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(activeIcon, color: AppColors.primaryGreen),
      ),
      label: label,
    );
  }
}