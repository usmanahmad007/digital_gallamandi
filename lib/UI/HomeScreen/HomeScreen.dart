import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:zrai_mart/Notification/Notification.dart';
import 'package:zrai_mart/UI/HomeScreen/SearchScreen.dart';
import 'package:zrai_mart/UI/HomeScreen/seeAllScreenRental.dart';
import 'package:zrai_mart/UI/chatScreen/userChatListScreen.dart';
import 'package:zrai_mart/UI/product/productFullView.dart';
import 'package:zrai_mart/UI/HomeScreen/seeAllScreen.dart';
import 'package:zrai_mart/UI/HomeScreen/weather.dart';
import 'package:zrai_mart/UI/HomeScreen/wishListScreen.dart';
import '../../models/Product.dart';
import '../Categories/CategoryList.dart';

class Homescreen extends StatefulWidget {
  const Homescreen({super.key});

  @override
  State<Homescreen> createState() => _HomescreenState();
}

class _HomescreenState extends State<Homescreen> {
  final List<Product> _products = [];
  List<Product> _filteredProducts = [];
  bool _isLoading = false;
  DocumentSnapshot? _lastDocument;
  final ScrollController _scrollController = ScrollController();
  String _selectedCategory = "All";
  bool isNew = false;
  int count = 0;
  int stepcount = 0;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  String? profileImageUrl;
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
  }
bool fav=false;
  void fetchNewMessages() {
    FirebaseFirestore.instance
        .collection('chats')
        .where('userId', isEqualTo: FirebaseAuth.instance.currentUser!.uid)
        .snapshots()
        .listen((querySnapshot) {
      for (var doc in querySnapshot.docs) {
        final data = doc.data();
        List<Map<String, dynamic>> messages = fetchMessagesFromData(data);
        stepcount = 0;
        /* int lastIndex=messages.length-1;
        if(messages[lastIndex]['isRead']==false && messages[lastIndex]['userId']!=FirebaseAuth.instance.currentUser!.uid){
          ++count;
          isNew=true;
        }*/
        for (var message in messages) {
          if (message['isRead'] == false &&
              message['sender'] != FirebaseAuth.instance.currentUser!.uid) {
            // Handle the new message here
            stepcount = 1;
            isNew = true;
            if (mounted) {
              setState(() {});
            }
            break;

            /*if (mounted) {
              setState(() {});
            }*/
          }
        }
        count = count + stepcount;
        print("$count//");
      }
    });
  }

  List<Map<String, dynamic>> fetchMessagesFromData(Map<String, dynamic> data) {
    if (data.containsKey('messages') && data['messages'] is List) {
      // Cast the 'messages' field to a list of Map<String, dynamic>
      List<Map<String, dynamic>> messages =
          List<Map<String, dynamic>>.from(data['messages']);
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

    final fetchedProducts =
        querySnapshot.docs.map((doc) => Product.fromDocument(doc)).toList();

    setState(() {
      _products.addAll(fetchedProducts);
      _filteredProducts = _products
          .where((product) => product.category != "Rental")
          .take(10)
          .toList(); // Initially display all products
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

    final fetchedProducts =
        querySnapshot.docs.map((doc) => Product.fromDocument(doc)).toList();

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
        _filteredProducts = _products
            .where((product) => product.category != "Rental")
            .take(10) // Limit the number of products to 10
            .toList();
      } else {
        _filteredProducts = _products
            .where((product) =>
                product.category == _selectedCategory &&
                product.category != "Rental")
            .take(10) // Limit the number of products to 10
            .toList();
      }
    });
  }

  /*Future<void> _fetchProfileImage() async {
    try {
      final user = _auth.currentUser;
      if (user != null) {
        DocumentSnapshot userDoc =
        await _firestore.collection('users').doc(user.uid).get();
        if (userDoc.exists) {
          setState(() {
            profileImageUrl = userDoc['profileImage'];
          });
        }
      }
    } catch (e) {
      print('Error fetching profile image: $e');
    }
  }*/

  Widget _buildProductItem(Product product,BuildContext context) {
    double rating = double.parse(product.avgRate);
    String formattedRating = rating.toStringAsFixed(1);
    double ratingToDouble = double.parse(formattedRating); // Convert to double

    final width = MediaQuery.of(context).size.width;
    final List<String> imageUrls = List<String>.from(product.imageUrl ?? []);

    final cartRef = FirebaseFirestore.instance
        .collection('users')
        .doc(_auth.currentUser!.uid)
        .collection('wishList');

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => Productfullview(
              imageUrls: product.imageUrl,
              productName: product.name,
              shortDescription: product.description,
              price: product.price,
              categoryName: product.category,
              sellerId: product.sellerId,
              isRental: product.isRental,
              id: product.id,
              rating: product.avgRate,
              quantity: product.quantity,
            ),
          ),
        );
      },
      child: Container(
        width: width / 0.6,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(25.0),
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
            Stack(
              children: [
                ClipRRect(
                  borderRadius:
                 BorderRadius.circular(25),
                  child: Image.network(
                    imageUrls[0],
                    fit: BoxFit.cover,
                    width: double.infinity,
                    height: 130,
                  ),
                ),
                Positioned(
                  right: 0,
                  child: FutureBuilder<DocumentSnapshot>(
                    future: cartRef.doc(product.id).get(),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const IconButton(
                          onPressed: null,
                          icon: Icon(Icons.favorite_border, color: Colors.grey),
                        );
                      }

                      final isInWishlist =
                          snapshot.data != null && snapshot.data!.exists;

                      return IconButton(
                        onPressed: () async {
                          try {
                            if (isInWishlist) {
                              // Remove from wishlist
                              await cartRef.doc(product.id).delete();
                              setState(() {

                              });
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Removed from wishlist'),
                                ),
                              );
                            } else {
                              // Add to wishlist
                              await cartRef.doc(product.id).set({
                                'productId': product.id,
                                'addedAt': Timestamp.now(),
                              });
                              setState(() {

                              });
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Added to wishlist'),
                                ),
                              );
                            }
                          } catch (e) {
                            print("Error: $e");
                          }
                        },
                        icon: Icon(
                          isInWishlist
                              ? Icons.favorite
                              : Icons.favorite_border,
                          color: isInWishlist ? Colors.green : Colors.grey,
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 8, 8, 8),
              child: Text(
                product.name,
                style:
                const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8.0),
              child: Row(
                children: [
                  Icon(
                    ratingToDouble == 5.0
                        ? Icons.star
                        : ratingToDouble == 0.0
                        ? Icons.star_border
                        : Icons.star_half,
                    color: Colors.green,
                  ),
                  Text(
                    formattedRating.toString(),
                    style: const TextStyle(
                        fontSize: 16,
                        color: Colors.green,
                        fontWeight: FontWeight.bold),
                  )
                ],
              ),
            ),
            const SizedBox(height: 4,),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8.0),
              child: Text(
                'PKR${product.price}/Kg',
                style: const TextStyle(fontSize: 20, color: Colors.green,fontWeight: FontWeight.bold),
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
                  const SizedBox(height: 30),
                  StreamBuilder<DocumentSnapshot>(
                    stream: FirebaseFirestore.instance
                        .collection('users')
                        .doc(user?.uid)
                        .snapshots(),
                    builder: (context, snapshot) {
                      if (!snapshot.hasData || !snapshot.data!.exists) {
                        return const CircularProgressIndicator();
                      }

                      final userData = snapshot.data!;
                      final userName = userData['name'] ?? 'User';
                      final profileImageUrl = userData['profileImage'];

                      return Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              CircleAvatar(
                                radius: 23,
                                backgroundImage: profileImageUrl != null
                                    ? NetworkImage(profileImageUrl!)
                                    : const AssetImage('assets/img_2.png')
                                        as ImageProvider,
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
                                  onTap: () {
                                    Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                            builder: (context) =>
                                                const WeatherScreen()));
                                  },
                                  child: Container(
                                    width: 25,
                                    height: 25,
                                    decoration: BoxDecoration(
                                        borderRadius:
                                            BorderRadius.circular(100),
                                        color: Colors.blue),
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
                              /*IconButton(
                                icon: Icon(Icons.notifications_active_outlined),
                                onPressed: () {
                                  Navigator.push(context, MaterialPageRoute(builder: (context)=>NotificationScreen()));
                                },
                              ),*/
                              IconButton(
                                icon: const Icon(Icons.notifications_active_outlined),
                                onPressed: () {
                                  Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                          builder: (context) =>
                                              NotificationScreen(
                                                userId: FirebaseAuth
                                                    .instance.currentUser!.uid,
                                                isSeller: false,
                                              )));
                                },
                              ),
                              GestureDetector(
                                onTap: () {
                                  Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                          builder: (context) =>
                                              UserChatListScreen(
                                                currentUserId: FirebaseAuth
                                                    .instance.currentUser!.uid,
                                              )));
                                },
                                child: Stack(
                                  children: [
                                    const Positioned(
                                        child: Icon(
                                      Icons.message_outlined,
                                      size: 25,
                                    )),
                                    if (isNew == true)
                                      Positioned(
                                          top: 0,
                                          right: 0,
                                          child: Container(
                                              width: 15,
                                              height: 15,
                                              decoration: BoxDecoration(
                                                  color: Colors.white,
                                                  borderRadius:
                                                      BorderRadius.circular(
                                                          50)),
                                              child: Center(
                                                  child: Text(
                                                      count < 4
                                                          ? count.toString()
                                                          : "4+",
                                                      style: const TextStyle(
                                                          color: Colors.green,
                                                          fontWeight:
                                                              FontWeight.bold,
                                                          fontSize:
                                                              10) /*,textAlign: TextAlign.center,*/)))),
                                  ],
                                ),
                              ),
                              IconButton(
                                icon: const Icon(Icons.favorite_border),
                                onPressed: () {
                                  Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                          builder: (context) =>
                                               WishListScreen(userId: _auth.currentUser!.uid,)));
                                },
                              ),
                            ],
                          ),
                        ],
                      );
                    },
                  ),
                  const SizedBox(height: 20),
                  GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) => const SearchScreen()),
                      );
                    },
                    child: Container(
                      height: 55,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 10),
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
                  ),
                  const SizedBox(height: 10),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        "Rental Products",
                        style: TextStyle(
                            color: Colors.black, fontWeight: FontWeight.bold),
                      ),
                      TextButton(
                          onPressed: () {
                            Navigator.push(
                                context,
                                MaterialPageRoute(
                                    builder: (context) =>
                                        const SeeAllScreenRental()));
                          },
                          child: const Text(
                            "See All",
                            style: TextStyle(color: Colors.green),
                          )),
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
                      TextButton(
                          onPressed: () {
                            Navigator.push(
                                context,
                                MaterialPageRoute(
                                    builder: (context) =>
                                        const SeeAllScreen()));
                          },
                          child: const Text(
                            "See All",
                            style: TextStyle(color: Colors.green),
                          )),
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
                  ),
                  const SizedBox(height: 10),
                ],
              ),
            ),
          ),
          SliverGrid(
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              childAspectRatio: 1.4 / 2,
            ),
            delegate: SliverChildBuilderDelegate(
              (context, index) {
                if (_filteredProducts.isEmpty) {
                  return const Center(child: Text('No products available'));
                }

                return _buildProductItem(_filteredProducts[index],context);
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
                : const SizedBox.shrink(),
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
      height: 250,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: _products.length,
        itemBuilder: (context, index) {
          final product = _products[index];
          final List<String> imageUrls =
              List<String>.from(product.imageUrl ?? []);
          return product.category == "Rental"
              ? GestureDetector(
                  onTap: () {
                    Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) => Productfullview(
                                  imageUrls: product.imageUrl,
                                  productName: product.name,
                                  shortDescription: product.description,
                                  price: product.price,
                                  categoryName: product.category,
                                  sellerId: product.sellerId,
                                  isRental: product.isRental,
                                  id: product.id,
                                  rating: product.avgRate,
                              quantity: product.quantity.toString(),
                                )));
                  },
                  child: Container(
                    width: 180,
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
                          borderRadius: const BorderRadius.vertical(
                              top: Radius.circular(10.0)),
                          child: Image.network(
                            imageUrls[0],
                            fit: BoxFit.cover,
                            width: double.infinity,
                            height: 150,
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.fromLTRB(8, 4, 8, 0),
                          child: Text(
                            product.name,
                            style: const TextStyle(
                                fontSize: 18, fontWeight: FontWeight.bold),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.fromLTRB(8, 0, 8, 5),
                          child: Text(
                            product.description,
                            style: const TextStyle(
                                fontSize: 14, color: Colors.grey),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 8.0),
                          child: Text(
                            'PKR${product.price.toStringAsFixed(2)}/hr',
                            style: const TextStyle(
                                fontSize: 16, color: Colors.green,fontWeight: FontWeight.bold),
                          ),
                        ),
                      ],
                    ),
                  ),
                )
              : Container();
        },
      ),
    );
  }
}
