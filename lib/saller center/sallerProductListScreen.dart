import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../provider/ProductProvider.dart';


class sallerProductListScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final productProvider = Provider.of<ProductProvider>(context);
    final products = productProvider.products;
    return Scaffold(
      appBar: AppBar(
        title: Text('Products'),
      ),
      body: products.isEmpty
          ? Center(
        child: Text('Nothing to show'),
      )
          : ListView.builder(
        itemCount: products.length,
        itemBuilder: (context, index) {
          final product = products[index];
          return ListTile(
            title: Text(product.name),
            subtitle: Text(product.description),
            leading: Image.network(product.imageUrl),
          );
        },
      ),
    );
  }
}
