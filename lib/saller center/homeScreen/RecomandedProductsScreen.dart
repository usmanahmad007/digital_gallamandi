import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:intl/intl.dart';
import '../../app_colors.dart';
import '../../crop_ai_models/crop_recommendation/UI_crop_reco.dart';
import 'ProductReco.dart';

class RecommandedProductsScreen extends StatefulWidget {
  const RecommandedProductsScreen({super.key});

  @override
  _RecommandedProductsScreenState createState() => _RecommandedProductsScreenState();
}

class _RecommandedProductsScreenState extends State<RecommandedProductsScreen> {
  List<ProductReco> allProducts = [];
  List<ProductReco> filteredProducts = [];

  final List<String> seasons = ["Recommended", "All-Season", "Summer", "Winter", "Autumn", "Spring"];
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
        '{"Season":"Spring", "Crops":"Corn, Barley, Spinach, Lettuce, Radish, Cauliflower", "Fruits":"Loquat, Mulberries, Cherries, Almonds", "Vegetables":"Cauliflower, Radish, Lettuce, Spinach"},'
        '{"Season":"All-Season", "Crops":"Tomatoes, Spinach, Okra, Cucumbers", "Fruits":"Bananas, Guava", "Vegetables":"Tomatoes, Okra, Cucumbers, Spinach"}]';

    List<dynamic> jsonData = json.decode(csvData);
    allProducts = jsonData.map((e) => ProductReco.fromJson(e)).toList();
    filterProducts();
  }

  void filterProducts() {
    if (selectedSeason == "Recommended") {
      // Logic for AI Model Screen
      Future.delayed(Duration.zero, () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const CropReccommendation()),
        );
      });
      // We don't want to stay on "Recommended" since it's a button, reset to All-Season
      setState(() {
        selectedSeason = "All-Season";
        filteredProducts = allProducts.where((p) => p.season == "All-Season").toList();
      });
    } else {
      setState(() {
        filteredProducts = allProducts.where((p) => p.season == selectedSeason).toList();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    const primaryColor = AppColors.primaryGreen;

    return Scaffold(
      backgroundColor: const Color(0xffF4F7F6),
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          _buildSliverHeader(primaryColor),
          _buildSliverSeasonSelector(primaryColor),
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            sliver: filteredProducts.isEmpty
                ? const SliverFillRemaining(child: Center(child: CircularProgressIndicator()))
                : SliverList(
              delegate: SliverChildBuilderDelegate(
                    (context, index) {
                  final product = filteredProducts[index];
                  // Using unique key to force rebuild when data changes
                  return Column(
                    key: ValueKey(selectedSeason),
                    children: [
                      _buildSectionGrid("🌱 Primary Crops", product.crops, primaryColor),
                      _buildSectionGrid("🍏 Seasonal Fruits", product.fruits, primaryColor),
                      _buildSectionGrid("🥕 Fresh Vegetables", product.vegetables, primaryColor),
                      const SizedBox(height: 100),
                    ],
                  );
                },
                childCount: filteredProducts.length,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSliverHeader(Color primary) {
    return SliverAppBar(
      expandedHeight: 160.0,
      floating: false,
      pinned: true,
      elevation: 0,
      backgroundColor: primary,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white, size: 20),
        onPressed: () => Navigator.pop(context),
      ),
      flexibleSpace: FlexibleSpaceBar(
        centerTitle: false,
        titlePadding: const EdgeInsets.only(left: 20, bottom: 16),
        title: const Text("Seasonal Market",
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18)),
        background: Stack(
          fit: StackFit.expand,
          children: [
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [primary, primary.withBlue(100)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
            ),
            Positioned(
              right: -20,
              top: -20,
              child: Icon(Icons.eco, size: 150, color: Colors.white.withOpacity(0.1)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSliverSeasonSelector(Color primary) {
    return SliverPersistentHeader(
      pinned: true,
      // CRITICAL: We pass selectedSeason to the delegate so it knows to update
      delegate: _PinnedHeaderDelegate(
        selectedSeason: selectedSeason,
        child: Container(
          color: const Color(0xffF4F7F6),
          height: 70,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            itemCount: seasons.length,
            itemBuilder: (context, index) {
              final seasonName = seasons[index];
              bool isSelected = selectedSeason == seasonName;
              bool isAi = seasonName == "Recommended";

              return Padding(
                padding: const EdgeInsets.only(right: 10),
                child: InkWell(
                  onTap: () {
                    selectedSeason = seasonName;
                    filterProducts();
                  },
                  borderRadius: BorderRadius.circular(15),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    decoration: BoxDecoration(
                      color: isSelected ? primary : (isAi ? Colors.orange.shade50 : Colors.white),
                      borderRadius: BorderRadius.circular(15),
                      border: Border.all(
                          color: isSelected ? primary : (isAi ? Colors.orange : Colors.black12),
                          width: 1.5
                      ),
                      boxShadow: isSelected ? [BoxShadow(color: primary.withOpacity(0.3), blurRadius: 8, offset: const Offset(0, 4))] : [],
                    ),
                    child: Center(
                      child: Row(
                        children: [
                          if (isAi) Icon(Icons.auto_awesome, size: 14, color: isSelected ? Colors.white : Colors.orange),
                          if (isAi) const SizedBox(width: 6),
                          Text(
                            seasonName,
                            style: TextStyle(
                              color: isSelected ? Colors.white : (isAi ? Colors.orange.shade900 : Colors.black87),
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  // ... [Keep _buildSectionGrid, _buildItemCard, and _buildImageWithFallback the same]

  Widget _buildSectionGrid(String title, List<String> items, Color primary) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 25, bottom: 15),
          child: Row(
            children: [
              Container(width: 4, height: 20, decoration: BoxDecoration(color: primary, borderRadius: BorderRadius.circular(10))),
              const SizedBox(width: 10),
              Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87)),
            ],
          ),
        ),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: items.length,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            childAspectRatio: 0.85,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
          ),
          itemBuilder: (context, index) => _buildItemCard(items[index], primary),
        ),
      ],
    );
  }

  Widget _buildItemCard(String name, Color primary) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(25),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 15, offset: const Offset(0, 5))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(4),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(22),
                child: _buildImageWithFallback(name, primary),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 4, 12, 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14, color: Color(0xFF2D3436))),
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(color: Colors.green.shade50, borderRadius: BorderRadius.circular(8)),
                  child: Text("Organic", style: TextStyle(color: primary, fontWeight: FontWeight.bold, fontSize: 10)),
                ),
              ],
            ),
          )
        ],
      ),
    );
  }

  Widget _buildImageWithFallback(String item, Color primary) {
    final List<String> paths = ['assets/Images/Seasonal Crops/', 'assets/Images/RecomendationCrops/'];
    final List<String> extensions = ['.jpg', '.jfif', '.jpeg'];

    return Image.asset(
      '${paths[0]}$item${extensions[0]}',
      fit: BoxFit.cover,
      errorBuilder: (context, error, stackTrace) => Image.asset(
        '${paths[0]}$item${extensions[1]}',
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) => Container(
          color: primary.withOpacity(0.05),
          child: Center(child: Icon(Icons.eco_outlined, color: primary.withOpacity(0.3), size: 30)),
        ),
      ),
    );
  }
}

// FIXED DELEGATE: Added 'selectedSeason' comparison to force rebuild
class _PinnedHeaderDelegate extends SliverPersistentHeaderDelegate {
  final Widget child;
  final String selectedSeason;

  _PinnedHeaderDelegate({required this.child, required this.selectedSeason});

  @override
  double get minExtent => 70;
  @override
  double get maxExtent => 70;

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) => child;

  @override
  bool shouldRebuild(_PinnedHeaderDelegate oldDelegate) {
    // If the selected season changed, we MUST rebuild this header
    return oldDelegate.selectedSeason != selectedSeason;
  }
}