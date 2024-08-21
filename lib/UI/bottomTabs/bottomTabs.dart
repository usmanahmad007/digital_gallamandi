import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:zrai_mart/UI/cartScreen/CartScreen.dart';
import 'package:zrai_mart/UI/chatBot/ChatbotScreen.dart';
import '../HomeScreen/HomeScreen.dart';
import '../orderScreen/OrdersScreen.dart';
import '../profile/ProfileScreen.dart';
import '../walletScreen/WalletScreen.dart';
import '../blog/blog.dart';

class BottomTabs extends StatefulWidget {
  @override
  _BottomTabsState createState() => _BottomTabsState();
}

class _BottomTabsState extends State<BottomTabs> {
  int _currentIndex = 0;

  final List<Widget> _pages = [
    Homescreen(),
    Cartscreen(),
    Ordersscreen(),
    /*Walletscreen(),*/
    /*ProductScreen(),*/
    BlogScreen(),
    Profilescreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _pages[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        currentIndex: _currentIndex,
        selectedItemColor: Colors.green,
        unselectedItemColor: Colors.grey,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        items: [
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.shopping_cart),
            label: 'Cart',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.list),
            label: 'Orders',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.wallet_outlined),
            label: 'Blogs',
          ),/*BottomNavigationBarItem(
            icon: Icon(Icons.account_balance_wallet),
            label: 'Wallet',
          ),*/
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: 'Profile',
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(context, MaterialPageRoute(builder: (context)=>ChatbotScreen()));
          // Define what happens when the button is pressed
          print('Chatbot button pressed');
        },
        backgroundColor: Colors.grey[300],
        child: Image.asset("assets/chatbot.png",width: 30,height: 30,),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
    );
  }
}
