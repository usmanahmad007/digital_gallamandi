import 'package:flutter/material.dart';
import 'package:zrai_mart/UI/chatBot/chat.dart';
import 'package:zrai_mart/saller%20center/product/sallerProductScreen.dart';
import 'package:zrai_mart/saller%20center/blog/sallerblog.dart';
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
    const sallerHomescreen(),
    const sallerProductScreen(),
    const SellerOrderScreen(),
    const sallerBlogScreen(),

    /*sallerWalletscreen(),*/
    const sallerProfilescreen(),
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
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.add),
            label: 'My Product',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.list),
            label: 'Orders',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.wallet_outlined),
            label: 'Blogs',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: 'Profile',
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(context, MaterialPageRoute(builder: (context)=>const ChatPage()));
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
