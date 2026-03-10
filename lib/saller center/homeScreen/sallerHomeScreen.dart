

import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:zrai_mart/Notification/Notification.dart';
import 'package:zrai_mart/saller%20center/homeScreen/productFullView.dart';
import 'package:zrai_mart/saller%20center/homeScreen/seeAllScreen.dart';
import 'package:zrai_mart/saller%20center/homeScreen/seeAllScreenRental.dart';
import 'package:carousel_slider/carousel_slider.dart' as cs;

import '../../UI/Categories/CategoryList.dart';
import '../../UI/HomeScreen/weather.dart';
import '../../models/Product.dart';
import '../chatScreen/sellerChatListScreen.dart';

class sallerHomescreen extends StatefulWidget {
  const sallerHomescreen({super.key});

  @override
  State<sallerHomescreen> createState() => _sallerHomescreenState();
}

class _sallerHomescreenState extends State<sallerHomescreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth firebaseAuth=FirebaseAuth.instance;
  final List<Product> _products = [];
  List<Product> _filteredProducts = [];
  bool _isLoading = false;
  DocumentSnapshot? _lastDocument;
  final ScrollController _scrollController = ScrollController();
  String _selectedCategory = "All";
  bool isNew=false;
  int count=0;
  int stepcount=0;
  List<String> imageSliders = [];
  Timer? _timer;

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
    fetchNewMessages();
    fetchDataFromFirebase();
    loadingData();
  }
  void loadingData(){
    _timer = Timer.periodic(const Duration(seconds: 10), (timer) async {
      fetchNewMessages();
    });
  }

  Future<void> fetchDataFromFirebase() async {
    try {
      // Fetch slider images from Firestore
      CollectionReference collectionRef =
      FirebaseFirestore.instance.collection('slider');
      QuerySnapshot querySnapshot = await collectionRef.get();
      if(mounted){
        setState(() {
          imageSliders =
              querySnapshot.docs.map((doc) => doc['image1'] as String).toList();
        });
      }

    } catch (e) {
      print('Error fetching data: $e');
    }
  }

  void fetchNewMessages() {
    FirebaseFirestore.instance
        .collection('chats')
        .where('sellerId', isEqualTo: FirebaseAuth.instance.currentUser!.uid)
        .snapshots()
        .listen((querySnapshot) {
      for (var doc in querySnapshot.docs) {
        final data = doc.data();
        List<Map<String, dynamic>> messages = fetchMessagesFromData(data);
        stepcount=0;
        for (var message in messages) {
          if (message['isRead'] == false && message['sender']!=FirebaseAuth.instance.currentUser!.uid) {
            // Handle the new message here
            stepcount=1;
            isNew = true;
            break;

            // Check if the widget is still mounted before calling setState
            /*if (mounted) {
              setState(() {});
            }*/
          }
        }
        count=count+stepcount;
      }
    });
  }

  List<Map<String, dynamic>> fetchMessagesFromData(Map<String, dynamic> data) {
    if (data.containsKey('messages') && data['messages'] is List) {
      // Cast the 'messages' field to a list of Map<String, dynamic>
      List<Map<String, dynamic>> messages = List<Map<String, dynamic>>.from(data['messages']);
      return messages;
    } else {
      // Return an empty list if 'messages' doesn't exist or is not a list
      return [];
    }
  }

  Future<void> _loadProducts() async {
    setState(() {
      _isLoading = true;
    });

    QuerySnapshot querySnapshot =
    await FirebaseFirestore.instance.collection('products').get();

    final fetchedProducts = querySnapshot.docs
        .map((doc) => Product.fromDocument(doc))
        .toList();

    setState(() {
      _products.addAll(fetchedProducts);
      _filteredProducts = _products.where((product) => product.sellerId!=firebaseAuth.currentUser!.uid && product.category != "Rental").toList(); // Initially display all products
      _isLoading = false;

    });

    _lastDocument =
    querySnapshot.docs.isNotEmpty ? querySnapshot.docs.last : null;

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

    final fetchedProducts = querySnapshot.docs
        .map((doc) => Product.fromDocument(doc))
        .toList();

    setState(() {
      _products.addAll(fetchedProducts);
      _applyCategoryFilter(); // Apply filter on newly fetched products
      _isLoading = false;
    });

    _lastDocument =
    querySnapshot.docs.isNotEmpty ? querySnapshot.docs.last : null;
  }

  void _applyCategoryFilter() {
    setState(() {
      if (_selectedCategory == "All") {
        _filteredProducts = _products.where((product) => product.sellerId!=firebaseAuth.currentUser!.uid && product.category != "Rental")
            .toList();
      } else {
        _filteredProducts = _products
            .where((product) => product.category == _selectedCategory && product.sellerId!=firebaseAuth.currentUser!.uid && product.category != "Rental")
            .toList();
      }
    });
  }
  Widget _buildProductItem(Product product) {
    final width=MediaQuery.of(context).size.width;
    final List<String> imageUrls =
    List<String>.from(product.imageUrl ?? []);

    return GestureDetector(
      onTap: (){
        Navigator.push(context, MaterialPageRoute(builder: (context)=>Productfullview(imageUrls: product.imageUrl, productName: product.name, shortDescription: product.description, price: product.price, categoryName: product.category, isRental: product.isRental,rating: product.avgRate,  productId: product.id,)));

      },
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10.0),
          boxShadow: const [
            BoxShadow(
              color: Colors.black26,
              blurRadius: 6,
              offset: Offset(0, 2),
            ),
          ],
          color: Colors.white,
        ),
        margin: const EdgeInsets.all(8.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(10.0)),
              child: Image.network(
                imageUrls[0],
                fit: BoxFit.cover,
                width: double.infinity,
                height: 130,
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Text(
                product.name,
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),maxLines: 2,
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8.0),
              child: Text(
                'PKR${product.price.toStringAsFixed(2)}',
                style: const TextStyle(fontSize: 16, color: Colors.green),
              ),
            ),
            product.isRental==false?Row(
              children: [
                Icon(product.rating==5.0? Icons.star: product.rating==0.0? Icons.star_border:Icons.star_half_sharp,color: Colors.green,),
                Text(
                  product.avgRate,
                  style: TextStyle(
                    fontSize: 22.0,
                    fontWeight: FontWeight.bold,
                    color: Colors.green[700],
                  ),
                ),
              ],
            ): Container()
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

                  const SizedBox(height: 30),
                  StreamBuilder<DocumentSnapshot>(
                    stream: FirebaseFirestore.instance
                        .collection('saller')
                        .doc(user?.uid)
                        .snapshots(),
                    builder: (context, snapshot) {
                      if (!snapshot.hasData || !snapshot.data!.exists) {
                        return const CircularProgressIndicator();
                      }

                      final userData = snapshot.data!;
                      final userName = userData['name'] ?? 'User';
                      final profileImageUrl=userData['profileImage'];

                      return Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              CircleAvatar(
                                radius: 25,
                                backgroundImage: profileImageUrl != null
                                    ? NetworkImage(profileImageUrl!)
                                    : const AssetImage('assets/img_2.png') as ImageProvider,
                              ),
                              const SizedBox(width: 10),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    _getGreetingMessage(),
                                    style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold),
                                  ),
                                  Text(
                                    userName,
                                    style: const TextStyle(fontSize: 14),
                                  ),
                                ],
                              ),
                            ],
                          ),
                          Row(
                            children: [
                              GestureDetector(
                                  onTap:(){
                                    Navigator.push(context, MaterialPageRoute(builder: (context)=>const WeatherScreen()));
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
                                icon: const Icon(Icons.notifications_active_outlined),
                                onPressed: () {
                                  Navigator.push(context, MaterialPageRoute(builder: (context)=>NotificationScreen( userId: FirebaseAuth.instance.currentUser!.uid, isSeller: true,)));
                                },
                              ),
                              const SizedBox(width: 10,),
                              GestureDetector(
                                onTap: (){
                                  Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                          builder: (context) => SellerChatListScreen(

                                            sellerId: FirebaseAuth.instance.currentUser!.uid,)));
                                },
                                child: Stack(
                                  children: [

                                    const Positioned(

                                        child: Icon(Icons.message_outlined,size: 25,)),

                                    if(isNew==true)
                                      Positioned(top: 0,
                                          right: 0,
                                          child: Container(
                                              width: 15,
                                              height: 15,
                                              decoration: BoxDecoration(
                                                  color: Colors.white,
                                                  borderRadius: BorderRadius.circular(50)
                                              ),
                                              child: Center(child: Text(count<4? count.toString():"4+",style: const TextStyle(color: Colors.green,fontWeight: FontWeight.bold,fontSize: 10)/*,textAlign: TextAlign.center,*/)))),
                                  ],
                                ),
                              ),
                           /*   IconButton(
                                icon: const Icon(Icons.favorite_border),
                                onPressed: () {
                                  Navigator.push(context, MaterialPageRoute(builder: (context)=>const wishListScreen()));
                                },
                              ),*/
                            ],
                          ),
                        ],
                      );
                    },
                  ),
                  const SizedBox(height: 20),
                  /*GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const SearchScreen()),
                      );
                    },
                    child: Container(
                      height: 55,
                      padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      decoration: BoxDecoration(
                        color: Colors.grey[200],
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Row(
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
                  ),*/
                  const Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        "What's New",
                        style: TextStyle(
                            color: Colors.black, fontWeight: FontWeight.bold),
                      ),

                    ],
                  ),
                  const SizedBox(height: 10),
                  imageSliders.isNotEmpty
                      ? cs.CarouselSlider(
                    options: cs.CarouselOptions(
                      aspectRatio: 2.0,
                      enlargeCenterPage: true,
                      scrollDirection: Axis.horizontal,
                      autoPlay: true,
                    ),
                    items: imageSliders.map((item) {
                      return Container(
                        child: Center(
                          child: Image.network(
                            item,
                            fit: BoxFit.cover,
                            width: 1000,
                          ),
                        ),
                      );
                    }).toList(),
                  )
                      : const SizedBox(
                    height: 200,
                    child: Center(
                      child: CircularProgressIndicator(),
                    ),
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        "Rental Products",
                        style: TextStyle(
                            color: Colors.black, fontWeight: FontWeight.bold),
                      ),
                      TextButton(onPressed: () {
                        Navigator.push(context, MaterialPageRoute(builder: (context)=>const SeeAllScreenRental()));

                      }, child: const Text("See All",style: TextStyle(color: Colors.black),)),
                    ],
                  ),
                  const SizedBox(height: 10),
                  if (_isLoading) const CircularProgressIndicator(),
                  _buildProductSlider(),
                  const SizedBox(height: 10),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        "Most Popular",
                        style: TextStyle(
                            color: Colors.black, fontWeight: FontWeight.bold),
                      ),
                      TextButton(onPressed: () {
                        Navigator.push(context, MaterialPageRoute(builder: (context)=>const SeeAllScreen()));
                      }, child: const Text("See All",style: TextStyle(color: Colors.black),)),
                    ],
                  ),
                  const SizedBox(height: 10),
                  CategoryList(
                    onCategorySelected: (category) {
                      setState(() {
                        _selectedCategory = category;
                        _applyCategoryFilter();
                      });
                    },
                  ),                  const SizedBox(height: 10),
                ],
              ),
            ),
          ),
          SliverGrid(
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              childAspectRatio: 1.3 / 2,
            ),
            delegate: SliverChildBuilderDelegate(
                  (context, index) {
                if (_filteredProducts.isEmpty) {
                  return const Center(child: Text('No products available'));

                }
                print(_filteredProducts.length.toString());


                return _buildProductItem(_filteredProducts[index]);
              },
              childCount: _filteredProducts.length,
            ),
          ),
          SliverToBoxAdapter(
            child: _isLoading
                ? const Padding(
              padding: EdgeInsets.all(16.0),
              child: Center(child: CircularProgressIndicator()),
            )
                : const Center(
              child: Text("No Product Available"),
            ),
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
    if (_products.isEmpty) {
      return const Center(child: Text('No products to show'));
    }
    return SizedBox(
      height: 270,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: _products.length,
        itemBuilder: (context, index) {
          final product = _products[index];
          final List<String> imageUrls =
          List<String>.from(product.imageUrl ?? []);
          return product.category=="Rental" && product.sellerId!=firebaseAuth.currentUser!.uid? GestureDetector(
            onTap: (){
              Navigator.push(context, MaterialPageRoute(builder: (context)=>Productfullview(imageUrls: product.imageUrl, productName: product.name, shortDescription: product.description, price: product.price, categoryName: product.category, isRental: product.isRental,rating: product.avgRate, productId: product.id, )));
            },
            child: Container(
              width: 200,
              margin: const EdgeInsets.fromLTRB(0, 8, 8, 8),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(10.0),
                boxShadow: const [
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
                    const BorderRadius.vertical(top: Radius.circular(10.0)),
                    child: Image.network(
                      imageUrls[0],
                      fit: BoxFit.cover,
                      width: double.infinity,
                      height: 150,
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Text(
                      product.name,
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),maxLines: 2,
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8.0),
                    child: Text(
                      'PKR${product.price.toStringAsFixed(2)}',
                      style: const TextStyle(fontSize: 16, color: Colors.green),
                    ),
                  ),
                  product.isRental==false?Row(
                    children: [
                      Icon(product.rating=='5.0'? Icons.star: product.rating=='0.0'? Icons.star_border:Icons.star_half_sharp,color: Colors.green,),
                      Text(
                        product.avgRate,
                        style: TextStyle(
                          fontSize: 22.0,
                          fontWeight: FontWeight.bold,
                          color: Colors.green[700],
                        ),
                      ),
                    ],
                  ): Container(),
                ],
              ),
            ),
          ): Container();
        },
      ),
    );
  }
}
