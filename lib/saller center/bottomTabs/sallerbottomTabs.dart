import 'package:flutter/material.dart';
import 'package:zrai_mart/UI/chatBot/chat.dart';
import 'package:zrai_mart/saller center/product/sallerProductScreen.dart';
import 'package:zrai_mart/saller center/blog/sallerblog.dart';
import 'package:zrai_mart/saller center/dashboard/seller_dashboard.dart';
import '../../app_colors.dart';
import '../homeScreen/sallerHomeScreen.dart';
import '../orderScreen/sallerOrdersScreen.dart';
import '../profile/sallerProfileScreen.dart';

class sallerBottomTabs extends StatefulWidget {
  const sallerBottomTabs({super.key});

  @override
  _sallerBottomTabsState createState() => _sallerBottomTabsState();
}

class _sallerBottomTabsState extends State<sallerBottomTabs> {
  int _currentIndex = 0;

  final List<Widget> _pages = [
    const SellerDashboard(),
    const sallerHomescreen(),
    const sallerProductScreen(),
    const SellerOrderScreen(),
    const sallerBlogScreen(),
    const sallerProfilescreen(),
  ];


  @override
  Widget build(BuildContext context) {
    // Using your green and a sky blue for consistency
    const Color primaryColor = AppColors.primaryGreen;
    const Color unselectedColor = Color(0xFF94A3B8);

    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: _pages,
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.06),
              blurRadius: 10,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: SafeArea(
          child: Container(
            height: 65,
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildNavItem(0, Icons.dashboard_outlined, Icons.dashboard, "Dash", primaryColor, unselectedColor),
                _buildNavItem(1, Icons.home_outlined, Icons.home, "Home", primaryColor, unselectedColor),
                _buildNavItem(2, Icons.inventory_2_outlined, Icons.inventory_2, "Items", primaryColor, unselectedColor),
                _buildNavItem(3, Icons.receipt_long_outlined, Icons.receipt_long, "Orders", primaryColor, unselectedColor),
                _buildNavItem(4, Icons.auto_stories_outlined, Icons.auto_stories, "Blogs", primaryColor, unselectedColor),
                _buildNavItem(5, Icons.person_outline, Icons.person, "Profile", primaryColor, unselectedColor),
              ],
            ),
          ),
        ),
      ),
      floatingActionButton: Container(
        // The outer container handles the gradient and the "glow" shadow
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: LinearGradient(
            colors: [
              AppColors.primaryGreen,
              AppColors.primaryGreen.withOpacity(0.7),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          boxShadow: [
            BoxShadow(
              color: AppColors.primaryGreen.withOpacity(0.4),
              blurRadius: 15,
              offset: const Offset(0, 8), // A deeper offset makes it look like it's floating higher
            ),
          ],
        ),
        child: FloatingActionButton(
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const ChatPage()),
            );
          },
          backgroundColor: Colors.transparent, // Required to see the gradient
          elevation: 0,
          highlightElevation: 0,
          shape: const CircleBorder(),
          // Stack used to add a subtle "AI pulse" or secondary glow if desired
          child: const Icon(
            Icons.auto_awesome, // This is the standard Material icon for AI/Magic
            color: Colors.white,
            size: 30, // Slightly larger for better visibility
          ),
        ),
      )
    );
  }

  Widget _buildNavItem(int index, IconData icon, IconData activeIcon, String label, Color activeColor, Color inactiveColor) {
    bool isSelected = _currentIndex == index;

    return Expanded(
      child: InkWell(
        onTap: () => setState(() => _currentIndex = index),
        splashColor: Colors.transparent,
        highlightColor: Colors.transparent,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Active Top Indicator Bar (The "Not Rounded" sleek look)
            AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              height: 3,
              width: isSelected ? 30 : 0,
              decoration: BoxDecoration(
                color: activeColor,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const Spacer(),
            Icon(
              isSelected ? activeIcon : icon,
              color: isSelected ? activeColor : inactiveColor,
              size: 24,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                color: isSelected ? activeColor : inactiveColor,
                fontSize: 10,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}