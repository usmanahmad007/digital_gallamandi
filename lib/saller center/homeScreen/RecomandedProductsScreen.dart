import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'dart:convert';


import '../../crop_recommendation/UI_crop_reco.dart';

class ProductReco {
  final String season;
  final List<String> crops;
  final List<String> fruits;
  final List<String> vegetables;


  ProductReco({
    required this.season,
    required this.crops,
    required this.fruits,
    required this.vegetables,

  });

  factory ProductReco.fromJson(Map<String, dynamic> json) {
    return ProductReco(
      season: json['Season'],
      crops: json['Crops'].split(', '),
      fruits: json['Fruits'].split(', '),
      vegetables: json['Vegetables'].split(', '),
    );
  }
}

class RecommandedProductsScreen extends StatefulWidget {
  final double temperature;
  final double humidity;

  final double rainfall;
  final Position currentPosition;
  const RecommandedProductsScreen({
      super.key,
      required this.temperature,
      required this.humidity,
    required this.currentPosition,
      required this.rainfall,});
  @override
  _RecommandedProductsScreenState createState() =>
      _RecommandedProductsScreenState();
}

class _RecommandedProductsScreenState
    extends State<RecommandedProductsScreen> {
  List<ProductReco> allProducts = [];
  List<ProductReco> filteredProducts = [];
  double n = 90.0;
  double p = 42.0;
  double k = 43.0;
  double ph = 6.5;
  List<String> seasons = [
    "Recommended",
    "All-Season",
    "Summer",
    "Winter",
    "Autumn",
    "Spring"
  ];
  String selectedSeason = "All-Season";

  @override
  void initState() {
    super.initState();
    loadProducts();
  }

  void loadProducts() {
    String csvData =
        '[{"Season":"Summer", "Crops":"Rice, Cotton, Maize, Millets (Bajra)", "Fruits":"Mango, Lychee, Peach, Plum, Melon, Guava, Papaya", "Vegetables":"Bitter Gourd, Brinjal (Eggplant), Cucumbers, Okra"},'
        '{"Season":"Winter", "Crops":"Wheat, Barley, Lentils, Mustard (Oilseed)", "Fruits":"Oranges, Dates, Pomegranate, Apples, Strawberries, Guava, Bananas", "Vegetables":"Carrots, Cauliflower, Turnips, Radish, Spinach"},'
        '{"Season":"Autumn", "Crops":"Potatoes, Onions, Garlic, Carrots, Turnips", "Fruits":"Persimmons (Amlok), Pears, Dates, Grapes", "Vegetables":"Cabbage, Spinach, Lettuce"},'
        '{"Season":"Spring", "Crops":"Corn (early cultivation for summer), Barley, Spinach, Lettuce, Radish, Cauliflower", "Fruits":"Loquat, Mulberries, Cherries, Almonds", "Vegetables":"Cauliflower, Radish, Lettuce, Spinach"},'
        '{"Season":"All-Season", "Crops":"Tomatoes, Spinach, Okra, Cucumbers", "Fruits":"Bananas, Guava", "Vegetables":"Tomatoes, Okra, Cucumbers, Spinach"}]';

    List<dynamic> jsonData = json.decode(csvData);
    allProducts = jsonData.map((e) => ProductReco.fromJson(e)).toList();
    filterProducts();
  }

  void filterProducts() {
    setState(() {
      if (selectedSeason == "Recommended") {
        selectedSeason = "All-Season";
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => CropReccommendation(p: p,ph: ph,k: k,n: n,temperature: widget.temperature,humidity: widget.humidity,rainfall: widget.rainfall,currentPosition: widget.currentPosition,),
          ),
        );
      } else if (selectedSeason == "All-Season") {
        filteredProducts = allProducts.where((p) => p.season == selectedSeason).toList();
      } else {
        filteredProducts =
            allProducts.where((p) => p.season == selectedSeason).toList();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Seasonal Products")),
      body: Column(
        children: [
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: seasons.map((season) {
                return GestureDetector(
                  onTap: () {
                    setState(() {
                      selectedSeason = season;
                      filterProducts();
                    });
                  },
                  child: Container(
                    margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
                    padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 8),
                    decoration: BoxDecoration(
                      color: selectedSeason == season
                          ? Colors.green
                          : Colors.grey[300],
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      season,
                      style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: selectedSeason == season
                              ? Colors.white
                              : Colors.black),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),

          Expanded(
            child: filteredProducts.isNotEmpty
                ? ListView.builder(
              itemCount: filteredProducts.length,
              itemBuilder: (context, index) {
                final product = filteredProducts[index];
                return Card(
                  margin:
                  const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  elevation: 3,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10)),
                  child: Padding(
                    padding: const EdgeInsets.all(10),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          product.season,
                          style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.green),
                        ),
                        const SizedBox(height: 10),
                        buildProductSection("🌱 Crops", product.crops),
                        buildProductSection("🍏 Fruits", product.fruits),
                        buildProductSection(
                            "🥕 Vegetables", product.vegetables),
                      ],
                    ),
                  ),
                );
              },
            )
                : const Center(
                child: Text("No products available",
                    style: TextStyle(fontSize: 16))),
          ),
        ],
      ),
    );
  }

  Widget buildProductSection(String title, List<String> items) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        const SizedBox(height: 10),
        Wrap(
          spacing: 8.0,
          children: items.map((item) {
            return Column(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: Image.asset(
                    'assets/Images/Seasonal Crops/$item.jpg',
                    width: 150,
                    height: 200,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) =>
                        Image.asset(
                          'assets/Images/Seasonal Crops/$item.jfif',
                          width: 150,
                          height: 200,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) =>
                              Image.asset(

                                'assets/Images/Seasonal Crops/$item.jpeg',
                                width: 150,
                                height: 200,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) =>
                                    Image.asset(
                                      'assets/Images/RecomendationCropss/$item.jpg',
                                      width: 150,
                                      height: 200,
                                      fit: BoxFit.cover,
                                      errorBuilder: (context, error, stackTrace) =>
                                          const Icon(Icons.image, size: 110, color: Colors.grey),
                                    ),
                              ),
                        ),
                  ),
                ),
                const SizedBox(height: 4),
                Text(item, style: const TextStyle(fontSize: 18,fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),

              ],
            );
          }).toList(),
        ),
        const SizedBox(height: 10),
      ],
    );
  }
  Widget _buildImage(String item) {
    List<String> extensions = ['jpg', 'jfif', 'jpeg'];
    List<String> paths = [
      'assets/Images/Seasonal Crops/',
      'assets/Images/RecomendationCropss/'
    ];

    return ClipRRect(
      borderRadius: BorderRadius.circular(10),
      child: Builder(
        builder: (context) {
          for (var path in paths) {
            for (var ext in extensions) {
              String assetPath = '$path$item.$ext';
              return Image.asset(
                assetPath,
                width: 50,
                height: 50,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => const Icon(
                  Icons.image,
                  size: 50,
                  color: Colors.grey,
                ),
              );
            }
          }
          return const Icon(Icons.image, size: 50, color: Colors.grey);
        },
      ),
    );
  }
}
