import 'package:flutter/material.dart';
import 'package:myfirstflutterapp/models/product_model.dart';
import 'package:myfirstflutterapp/widgets/product_card.dart';

class ProductsSection extends StatelessWidget {
  final List<Product> products;
  final Function(Product) onProductTap;
  final Function(int, bool) onWishlistChanged;

  const ProductsSection({
    super.key,
    required this.products,
    required this.onProductTap,
    required this.onWishlistChanged,
  });

  @override
  Widget build(BuildContext context) {
    return products.isEmpty
        ? const SliverToBoxAdapter(child: SizedBox.shrink())
        : SliverList(
            delegate: SliverChildBuilderDelegate(
              (context, index) {
                final product = products[index];
                return InkWell(
                  onTap: () => onProductTap(product),
                  child: ProductCard(
                    product: product,
                    onWishlistChanged: onWishlistChanged,
                  ),
                );
              },
              childCount: products.length,
            ),
          );
  }
}

class OtherProductsSection extends StatelessWidget {
  const OtherProductsSection({super.key});

  @override
  Widget build(BuildContext context) {
    return SliverToBoxAdapter(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: const [
          Divider(thickness: 1, height: 32),
          Padding(
            padding: EdgeInsets.only(left: 20, bottom: 10),
            child: Text(
              "Other items",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }
}
