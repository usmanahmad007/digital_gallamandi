import 'package:flutter/material.dart';
import '../../app_colors.dart'; // Ensure this path is correct
import 'package:zrai_mart/UI/cartScreen/CartScreen.dart';
import 'package:zrai_mart/UI/chatBot/chat.dart';
import '../HomeScreen/HomeScreen.dart';
import '../orderScreen/OrdersScreen.dart';
import '../profile/ProfileScreen.dart';
import '../blog/blog.dart';

class BottomTabs extends StatefulWidget {
  const BottomTabs({super.key});

  @override
  _BottomTabsState createState() => _BottomTabsState();
}

class _BottomTabsState extends State<BottomTabs> {
  int _currentIndex = 0;

  final List<Widget> _pages = [
    const Homescreen(),
    const Cartscreen(),
    const Ordersscreen(),
    const BlogScreen(),
    const Profilescreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _pages[_currentIndex],
      // Bottom Navigation Bar with custom styling
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, -5),
            ),
          ],
        ),
        child: BottomNavigationBar(
          type: BottomNavigationBarType.fixed,
          currentIndex: _currentIndex,
          backgroundColor: Colors.white,
          selectedItemColor: AppColors.primaryGreen,
          unselectedItemColor: AppColors.textGrey,
          selectedFontSize: 12,
          unselectedFontSize: 12,
          selectedLabelStyle: const TextStyle(fontWeight: FontWeight.bold),
          elevation: 0,
          onTap: (index) {
            setState(() {
              _currentIndex = index;
            });
          },
          items: [
            _buildNavItem(Icons.home_rounded, Icons.home_outlined, 'Home', 0),
            _buildNavItem(Icons.shopping_cart_rounded, Icons.shopping_cart_outlined, 'Cart', 1),
            _buildNavItem(Icons.receipt_long_rounded, Icons.receipt_long_outlined, 'Orders', 2),
            _buildNavItem(Icons.auto_stories_rounded, Icons.auto_stories_outlined, 'Blogs', 3),
            _buildNavItem(Icons.person_rounded, Icons.person_outline_rounded, 'Profile', 4),
          ],
        ),
      ),
      // Modern Chatbot FAB
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
      ),
      /*floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const ChatPage()),
          );
        },
        backgroundColor: Colors.white,
        elevation: 4,
        highlightElevation: 8,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: AppColors.primaryGreen.withOpacity(0.1),
          ),
          child: Icon(Icons.wechat_outlined),
          *//*child: Image.asset(
            "assets/chatbot.png",
            width: 28,
            height: 28,
            fit: BoxFit.contain,
          ),*//*
        ),
      ),*/
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
    );
  }

  // Helper to handle filled/outlined icon logic
  BottomNavigationBarItem _buildNavItem(IconData selectedIcon, IconData unselectedIcon, String label, int index) {
    return BottomNavigationBarItem(
      icon: Padding(
        padding: const EdgeInsets.only(bottom: 4.0),
        child: Icon(_currentIndex == index ? selectedIcon : unselectedIcon),
      ),
      label: label,
    );
  }
}