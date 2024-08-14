import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:zrai_mart/Notification.dart';
import 'package:zrai_mart/UI/SearchScreen.dart';
import 'package:zrai_mart/UI/productFullView.dart';
import 'package:zrai_mart/UI/seeAllScreen.dart';
import 'package:zrai_mart/UI/weather.dart';
import 'package:zrai_mart/UI/wishListScreen.dart';
import '../models/Product.dart';
import 'CategoryList.dart';

class Homescreen extends StatefulWidget {
  const Homescreen({super.key});

  @override
  State<Homescreen> createState() => _HomescreenState();
}

class _HomescreenState extends State<Homescreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final List<Product> _products = [];
  bool _isLoading = false;
  DocumentSnapshot? _lastDocument;
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _loadProducts();
    _scrollController.addListener(() {
      if (_scrollController.position.pixels ==
              _scrollController.position.maxScrollExtent &&
          !_isLoading) {
        _loadMoreProducts();
      }
    });
  }

  Future<void> _loadProducts() async {
    setState(() {
      _isLoading = true;
    });

    QuerySnapshot querySnapshot =
        await FirebaseFirestore.instance.collection('products').get();

    _products.addAll(
        querySnapshot.docs.map((doc) => Product.fromDocument(doc)).toList());
    _lastDocument =
        querySnapshot.docs.isNotEmpty ? querySnapshot.docs.last : null;

    setState(() {
      _isLoading = false;
    });
  }

  Future<void> _loadMoreProducts() async {
    if (_lastDocument == null) return;

    setState(() {
      _isLoading = true;
    });

    QuerySnapshot querySnapshot = await FirebaseFirestore.instance
        .collection('products')
        .startAfterDocument(_lastDocument!)
        .limit(10)
        .get();

    _products.addAll(
        querySnapshot.docs.map((doc) => Product.fromDocument(doc)).toList());
    _lastDocument =
        querySnapshot.docs.isNotEmpty ? querySnapshot.docs.last : null;

    setState(() {
      _isLoading = false;
    });
  }

  Widget _buildProductItem(Product product) {
    return GestureDetector(
      onTap: (){
        Navigator.push(context, MaterialPageRoute(builder: (context)=>Productfullview(imageUrl: product.imageUrl, productName: product.name, shortDescription: product.description, price: product.price, categoryName: "")));

      },
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10.0),
          boxShadow: [
            BoxShadow(
              color: Colors.black26,
              blurRadius: 6,
              offset: Offset(0, 2),
            ),
          ],
          color: Colors.white,
        ),
        margin: EdgeInsets.all(8.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.vertical(top: Radius.circular(10.0)),
              child: Image.network(
                product.imageUrl,
                fit: BoxFit.cover,
                width: double.infinity,
                height: 150,
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Text(
                product.name,
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),maxLines: 2,
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8.0),
              child: Text(
                '\$${product.price.toStringAsFixed(2)}',
                style: TextStyle(fontSize: 16, color: Colors.green),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      body: CustomScrollView(
        controller: _scrollController,
        slivers: [
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  SizedBox(height: 30),
                  StreamBuilder<DocumentSnapshot>(
                    stream: FirebaseFirestore.instance
                        .collection('users')
                        .doc(user?.uid)
                        .snapshots(),
                    builder: (context, snapshot) {
                      if (!snapshot.hasData || !snapshot.data!.exists) {
                        return CircularProgressIndicator();
                      }

                      final userData = snapshot.data!;
                      final userName = userData['name'] ?? 'User';

                      return Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              CircleAvatar(
                                backgroundImage: AssetImage(
                                  'assets/img_2.png',
                                ),
                              ),
                              SizedBox(width: 10),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    _getGreetingMessage(),
                                    style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold),
                                  ),
                                  Text(
                                    userName,
                                    style: TextStyle(fontSize: 14),
                                  ),
                                ],
                              ),
                            ],
                          ),
                          Row(
                            children: [
                              GestureDetector(
                                  onTap:(){
                                    Navigator.push(context, MaterialPageRoute(builder: (context)=>WeatherScreen()));
                                  },
                                  child: Container(
                                    width:30,
                                    height:30,
                                    decoration:BoxDecoration(
                                      borderRadius: BorderRadius.circular(100),
                                      color: Colors.blue
                                    ),
                                    child: Image.asset(
                                      "assets/iconweather.png",
                                    ),
                                  )),
                              /*GestureDetector(
                                onTap:(){
                                  Navigator.push(context, MaterialPageRoute(builder: (context)=>WeatherScreen()));
                                },
                                  child: CircleAvatar(
                                child: Image.asset(
                                  "assets/iconweather.png",scale: 2,
                                ),
                                backgroundColor: Colors.blue,
                              )),*/
                              IconButton(
                                icon: Icon(Icons.notifications_active_outlined),
                                onPressed: () {
                                  Navigator.push(context, MaterialPageRoute(builder: (context)=>NotificationScreen()));
                                },
                              ),
                              IconButton(
                                icon: Icon(Icons.favorite_border),
                                onPressed: () {
                                  Navigator.push(context, MaterialPageRoute(builder: (context)=>wishListScreen()));
                                },
                              ),
                            ],
                          ),
                        ],
                      );
                    },
                  ),
                  SizedBox(height: 20),
                  GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => SearchScreen()),
                      );
                    },
                    child: Container(
                      height: 55,
                      padding:
                          EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      decoration: BoxDecoration(
                        color: Colors.grey[200],
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.search, color: Colors.grey),
                          SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Search...',
                              style: TextStyle(color: Colors.grey),
                            ),
                          ),
                          Icon(Icons.filter_list, color: Colors.grey),
                        ],
                      ),
                    ),
                  ),
                  SizedBox(height: 10),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        "Special Offers",
                        style: TextStyle(
                            color: Colors.black, fontWeight: FontWeight.bold),
                      ),
                      TextButton(onPressed: () {
                        Navigator.push(context, MaterialPageRoute(builder: (context)=>SeeAllScreen()));

                      }, child: Text("See All")),
                    ],
                  ),
                  SizedBox(height: 10),
                  if (_isLoading) CircularProgressIndicator(),
                  _buildProductSlider(),
                  SizedBox(height: 10),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        "Most Popular",
                        style: TextStyle(
                            color: Colors.black, fontWeight: FontWeight.bold),
                      ),
                      TextButton(onPressed: () {
                        Navigator.push(context, MaterialPageRoute(builder: (context)=>SeeAllScreen()));
                      }, child: Text("See All")),
                    ],
                  ),
                  SizedBox(height: 10),
                  CategoryList(),
                  SizedBox(height: 10),
                ],
              ),
            ),
          ),
          SliverGrid(
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              childAspectRatio: 1.3 / 2,
            ),
            delegate: SliverChildBuilderDelegate(
              (context, index) {
                return _buildProductItem(_products[index]);
              },
              childCount: _products.length,
            ),
          ),
          SliverToBoxAdapter(
            child: _isLoading
                ? Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Center(child: CircularProgressIndicator()),
                  )
                : SizedBox.shrink(),
          ),
        ],
      ),
    );
  }

  String _getGreetingMessage() {
    final hour = DateTime.now().hour;
    if (hour < 12) {
      return 'Good Morning';
    } else if (hour < 17) {
      return 'Good Afternoon';
    } else {
      return 'Good Evening';
    }
  }

  Widget _buildProductSlider() {
    return Container(
      height: 270,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: _products.length,
        itemBuilder: (context, index) {
          final product = _products[index];
          return GestureDetector(
            onTap: (){
              Navigator.push(context, MaterialPageRoute(builder: (context)=>Productfullview(imageUrl: product.imageUrl, productName: product.name, shortDescription: product.description, price: product.price, categoryName: "")));
            },
            child: Container(
              width: 200,
              margin: EdgeInsets.fromLTRB(0, 8, 8, 8),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(10.0),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black26,
                    blurRadius: 6,
                    offset: Offset(0, 2),
                  ),
                ],
                color: Colors.white,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ClipRRect(
                    borderRadius:
                        BorderRadius.vertical(top: Radius.circular(10.0)),
                    child: Image.network(
                      product.imageUrl,
                      fit: BoxFit.cover,
                      width: double.infinity,
                      height: 150,
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Text(
                      product.name,
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),maxLines: 2,
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8.0),
                    child: Text(
                      '\$${product.price.toStringAsFixed(2)}',
                      style: TextStyle(fontSize: 16, color: Colors.green),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
