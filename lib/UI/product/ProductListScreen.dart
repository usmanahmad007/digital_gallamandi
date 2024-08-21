import 'package:flutter/material.dart';
import 'package:flutter_product_card/flutter_product_card.dart';
import 'package:provider/provider.dart';
import 'package:zrai_mart/UI/product/productFullView.dart';

import '../../provider/ProductProvider.dart';

class ProductListScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final productProvider = Provider.of<ProductProvider>(context);
    final products = productProvider.products;
    return Scaffold(
      appBar: AppBar(
        title: Text('Products'),
      ),
      body: Padding(
        padding: EdgeInsets.all(10),
        child: products.isEmpty
            ? Center(
                child: Text('Nothing to show'),
              )
            : ListView.builder(
                itemCount: products.length,
                itemBuilder: (context, index) {
                  final product = products[index];
                  return ProductCard(imageUrl: product.imageUrl, categoryName: product.category, productName: product.name, price: 0.0,shortDescription: product.description,onTap: (){
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => Productfullview(
                          imageUrl: product.imageUrl,
                          productName: product.name,
                          shortDescription: product.description,
                          price: 0.0,
                          categoryName: 'Electronics', // Set appropriate categoryName
                        ),
                      ),
                    );
                  },);
                },
              ),
      ),
    );
  }
}
