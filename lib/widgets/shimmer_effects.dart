import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';
import 'home_search_bar.dart';

class ShimmerEffects extends StatelessWidget {
  final String message;
  const ShimmerEffects({super.key, this.message = "Loading..."});

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Background shimmer layout
        AbsorbPointer(
          child: CustomScrollView(
            physics: const NeverScrollableScrollPhysics(),
            slivers: [
              SliverList(
                delegate: SliverChildListDelegate([
                  Shimmer.fromColors(
                    baseColor: Colors.grey.shade300,
                    highlightColor: Colors.grey.shade100,
                    child: const HomeSearchBar(),
                  ),
                  const SizedBox(height: 20),
                  _buildShimmerCategories(),
                  const SizedBox(height: 20),
                  Padding(
                    padding: const EdgeInsets.only(left: 20),
                    child: Shimmer.fromColors(
                      baseColor: Colors.grey.shade300,
                      highlightColor: Colors.grey.shade100,
                      child: Container(
                        height: 24,
                        width: 150,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                ]),
              ),
              _buildShimmerProductsGrid(), // Updated to use grid
            ],
          ),
        ),
        // Centered loading message overlay
        Positioned.fill(
          child: Container(
            color: Colors.black.withOpacity(0.4),
            child: Center(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                decoration: BoxDecoration(
                  color: Theme.of(context).cardColor,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 10,
                      spreadRadius: 2,
                    )
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const CircularProgressIndicator(),
                    const SizedBox(height: 16),
                    Text(message, style: const TextStyle(fontSize: 16)),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildShimmerCategories() {
    return SizedBox(
      height: 90,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.only(left: 20, right: 10),
        itemCount: 6,
        itemBuilder: (context, index) {
          return Shimmer.fromColors(
            baseColor: Colors.grey.shade300,
            highlightColor: Colors.grey.shade100,
            child: Container(
              width: 80,
              margin: const EdgeInsets.only(right: 10),
              child: Column(
                children: [
                  Container(
                    height: 50,
                    width: 50,
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    height: 10,
                    width: 40,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(4),
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

  // NEW: Grid view for product shimmers
  Widget _buildShimmerProductsGrid() {
    return SliverPadding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      sliver: SliverGrid(
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2, // 2 columns like the actual grid
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          childAspectRatio: 0.85, // Match your ProductCard aspect ratio
        ),
        delegate: SliverChildBuilderDelegate(
          (context, index) {
            return Shimmer.fromColors(
              baseColor: Colors.grey.shade300,
              highlightColor: Colors.grey.shade100,
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Image placeholder
                    Container(
                      height: 100, // Match your compact ProductCard image height
                      width: double.infinity,
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.vertical(
                          top: Radius.circular(12),
                        ),
                      ),
                    ),
                    // Content placeholder
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Title placeholder
                          Container(
                            height: 14,
                            width: double.infinity,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(4),
                            ),
                          ),
                          const SizedBox(height: 6),
                          // Price placeholder
                          Container(
                            height: 14,
                            width: 80,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(4),
                            ),
                          ),
                          const SizedBox(height: 8),
                          // Owner info placeholder
                          Row(
                            children: [
                              Container(
                                height: 24,
                                width: 24,
                                decoration: const BoxDecoration(
                                  color: Colors.white,
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Container(
                                      height: 10,
                                      width: 60,
                                      decoration: BoxDecoration(
                                        color: Colors.white,
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Container(
                                      height: 10,
                                      width: 80,
                                      decoration: BoxDecoration(
                                        color: Colors.white,
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
          childCount: 6, // Show 6 product placeholders (3 rows of 2)
        ),
      ),
    );
  }

  // OLD: Keep this method for reference or remove it
  // Widget _buildShimmerProducts() {
  //   return SliverList(
  //     delegate: SliverChildBuilderDelegate(
  //       (context, index) {
  //         return Shimmer.fromColors(
  //           baseColor: Colors.grey.shade300,
  //           highlightColor: Colors.grey.shade100,
  //           child: Container(
  //             margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
  //             height: 156,
  //             decoration: BoxDecoration(
  //               color: Colors.white,
  //               borderRadius: BorderRadius.circular(20),
  //             ),
  //           ),
  //         );
  //       },
  //       childCount: 5,
  //     ),
  //   );
  // }
}