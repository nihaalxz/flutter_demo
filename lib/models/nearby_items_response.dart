// lib/models/Product_DTO/nearby_items_response.dart

import '../models/product_model.dart';

class NearbyItemsResponse {
  final List<Product> items;
  final PaginationMetadata pagination;

  NearbyItemsResponse({
    required this.items,
    required this.pagination,
  });

  factory NearbyItemsResponse.fromJson(Map<String, dynamic> json) {
    var itemsList = json['items'] as List;
    List<Product> products = itemsList.map((i) => Product.fromJson(i)).toList();
    
    return NearbyItemsResponse(
      items: products,
      pagination: PaginationMetadata.fromJson(json['pagination']),
    );
  }
}

class PaginationMetadata {
  final int currentPage;
  final int pageSize;
  final int totalCount;
  final int totalPages;
  final bool hasNext;
  final bool hasPrevious;

  PaginationMetadata({
    required this.currentPage,
    required this.pageSize,
    required this.totalCount,
    required this.totalPages,
    required this.hasNext,
    required this.hasPrevious,
  });

  factory PaginationMetadata.fromJson(Map<String, dynamic> json) {
    return PaginationMetadata(
      currentPage: json['currentPage'] ?? 1,
      pageSize: json['pageSize'] ?? 0,
      totalCount: json['totalCount'] ?? 0,
      totalPages: json['totalPages'] ?? 0,
      hasNext: json['hasNext'] ?? false,
      hasPrevious: json['hasPrevious'] ?? false,
    );
  }
}