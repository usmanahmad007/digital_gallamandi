import 'package:carousel_slider/carousel_slider.dart' as cs;
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:zrai_mart/saller%20center/product/EditProduct.dart';
import 'package:zrai_mart/saller%20center/product/addProduct.dart';
import 'package:zrai_mart/saller%20center/product/sallerProductListScreen.dart';
import '../../product card/sallerProductCard.dart';

class sallerProductScreen extends StatefulWidget {
  const sallerProductScreen({super.key});

  @override
  State<sallerProductScreen> createState() => _sallerProductScreenState();
}

class _sallerProductScreenState extends State<sallerProductScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final cs.CarouselSliderController _controller = cs.CarouselSliderController();

  List<String> imageSliders = [];
  bool isNew=false;
  int count=0;
  int stepcount=0;

  @override
  void initState() {
    super.initState();
    fetchDataFromFirebase();
    fetchNewMessages();
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

  Future<void> _deleteProduct(String productId) async {
    try {
      await _firestore.collection('products').doc(productId).delete();
      _showSnackbar('Product deleted successfully', Colors.green);
    } catch (e) {
      _showSnackbar('Error deleting product: $e', Colors.red);
    }
  }

  void _showDeleteConfirmationDialog(String productId) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Row(
            children: [
              Text('Delete Product'),
              Icon(Icons.delete, color: Colors.red, size: 30),
            ],
          ),
          content: const Text('Are you sure you want to delete this product?'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('No', style: TextStyle(color: Colors.black)),
            ),
            Container(
              decoration: BoxDecoration(
                color: Colors.green,
                borderRadius: BorderRadius.circular(15),
              ),
              child: TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  _deleteProduct(productId);
                },
                child: const Text('Yes', style: TextStyle(color: Colors.black)),
              ),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "Your Products",
          style: TextStyle(
              color: Colors.white, fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,

        actions: [
          IconButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) =>  const Addproduct()),
              );
            },
            icon: const Icon(Icons.add),
          ),

          GestureDetector(
            onTap: () {
              Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) =>
                      const SallerProductListScreen()));
            },
            child: const Padding(
              padding: EdgeInsets.all(8),
              child: Row(
                children: [
                  Text(
                    "see all",
                    style: TextStyle(color: Colors.white),
                  ),
                  Icon(
                    Icons.arrow_forward_ios_sharp,
                    color: Colors.white,
                    size: 12,
                  )
                ],
              ),
            ),
          ),
          /*GestureDetector(
            onTap: (){
              Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => SellerChatListScreen(
                          sellerId: FirebaseAuth.instance.currentUser!.uid)));
            },
            child: Stack(
              children: [

                const Positioned(

                    child: Icon(Icons.message_outlined)),

                if(isNew==true)
                  Positioned(top: 0,
                      right: 0,
                      child: Container(
                        width: 13,
                        height: 13,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(50)
                        ),
                          child: Center(child: Text(count<4?count.toString(): "4+",style: const TextStyle(color: Colors.green,fontWeight: FontWeight.bold,fontSize: 10)*//*,textAlign: TextAlign.center,*//*)))),
              ],
            )
            *//*Row(
              children: [
                Icon(Icons.message_outlined),
                if(isNew==true)
                Text(count.toString())
              ],
            ),*//*
          ),*/
         const SizedBox(width: 10,)

         /* IconButton(
              onPressed: () {
                Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) => SellerChatListScreen(
                            sellerId: FirebaseAuth.instance.currentUser!.uid)));
              },
              icon: isNew==false? Icon(Icons.message_outlined): Icon(Icons.message))*/
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            const SizedBox(height: 10),
           /* imageSliders.isNotEmpty
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
                  ),*/
            const SizedBox(height: 10),
            /*Container(
              height: 40,
              width: MediaQuery.of(context).size.width,
              decoration: BoxDecoration(
                color: Colors.green.withOpacity(0.7),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Padding(
                    padding: EdgeInsets.all(8.0),
                    child: Text(
                      "Your Products",
                      style: TextStyle(
                          color: Colors.white, fontWeight: FontWeight.bold),
                    ),
                  ),
                  GestureDetector(
                    onTap: () {
                      Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (context) =>
                                  const SallerProductListScreen()));
                    },
                    child: const Padding(
                      padding: EdgeInsets.all(8),
                      child: Row(
                        children: [
                          Text(
                            "see all",
                            style: TextStyle(color: Colors.white),
                          ),
                          Icon(
                            Icons.arrow_forward_ios_sharp,
                            color: Colors.white,
                            size: 12,
                          )
                        ],
                      ),
                    ),
                  )
                ],
              ),
            ),*/
            StreamBuilder<QuerySnapshot>(
              stream: _firestore
                  .collection('products')
                  .where('sellerId',
                      isEqualTo: FirebaseAuth.instance.currentUser?.uid)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
                }

                final products = snapshot.data!.docs;

                if (products.isEmpty) {
                  return const Center(child: Text('No products available'));
                }

                return ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: products.length,
                  itemBuilder: (context, index) {
                    final product =
                        products[index].data() as Map<String, dynamic>;
                    final productId = products[index].id;
                    final List<String> imageUrls =
                        List<String>.from(product['imageUrls'] ?? []);

                    return GestureDetector(
                      onDoubleTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) =>
                                EditProduct(productId: productId),
                          ),
                        );
                      },
                      onLongPress: () {
                        _showDeleteConfirmationDialog(productId);
                      },
                      child: SallerProductCard(
                          imageUrls: imageUrls,
                          categoryName: product['category'],
                          productName: product['title'],
                          price: double.parse(product['price']),
                          onTap: () {
                            //   Navigator.push(context, MaterialPageRoute(builder: (context)=>SallerProductFullView(imageUrls: product['imageUrls'], productName: product['title'], shortDescription: product['description'], price: product['price'], categoryName: product['category'], productId: productId,)));
                          },
                          shortDescription: product['description'],
                          productId: productId,rating: double.parse(product['averageRating'].toString()), isRental: product['isRental'], quantity: product['quantity'].toString(),),
                      /* child: Card(
                        margin: const EdgeInsets.all(8.0),
                        child: Row(
                          children: [
                            // Display product image
                            product['imageUrls'][0] != null
                                ? Image.network(
                              product['imageUrls'][0],
                              height: 100,
                              width: 100,
                              fit: BoxFit.cover,
                            )
                                : Container(
                              height: 100,
                              width: 100,
                              color: Colors.grey[300],
                              child: const Icon(Icons.image, color: Colors.grey),
                            ),
                            const SizedBox(width: 10),
                            // Display product details
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    product['title'] ?? 'Unnamed Product',
                                    style: const TextStyle(
                                        fontSize: 16, fontWeight: FontWeight.bold),
                                  ),
                                  Text(product['description'] ?? 'No description'),
                                  Text(
                                    '\$${product['price']?.toString() ?? '0.0'}',
                                    style: const TextStyle(color: Colors.green),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),*/
                    );
                  },
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showSnackbar(String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: color,
      ),
    );
  }
}
