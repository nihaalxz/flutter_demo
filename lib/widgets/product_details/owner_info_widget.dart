import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:myfirstflutterapp/models/product_model.dart';
import 'package:myfirstflutterapp/environment/env.dart';

class OwnerInfoWidget extends StatelessWidget {
  final Product product;
  final String? currentUserId;
  final VoidCallback onMakeOffer;

  const OwnerInfoWidget({
    super.key,
    required this.product,
    required this.currentUserId,
    required this.onMakeOffer,
  });

  DateTime? _asDateTime(dynamic value) {
    if (value == null) return null;
    if (value is DateTime) return value;
    if (value is String) return DateTime.tryParse(value);
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final dateFmt = DateTime.now(); // You can format this as needed
    final createdAtDt = _asDateTime(product.createdAt);
    final createdAtLabel = createdAtDt != null
        ? "${createdAtDt.day}/${createdAtDt.month}/${createdAtDt.year}"
        : (product.createdAt.toString() ?? '');

    return Column(
      children: [
        ListTile(
          contentPadding: EdgeInsets.zero,
          leading: CircleAvatar(
            radius: 24,
            backgroundImage: (product.ownerProfileImage != null &&
                    product.ownerProfileImage!.isNotEmpty)
                ? CachedNetworkImageProvider(
                    "${AppConfig.imageBaseUrl}${product.ownerProfileImage!}",
                  )
                : const AssetImage(
                        "assets/icons/constant/empty-user-profilepic.webp")
                    as ImageProvider,
          ),
          title: Text(product.ownerName),
          subtitle: Text("Posted on $createdAtLabel"),
          trailing: (currentUserId != null &&
                  product.ownerId.toString() != currentUserId)
              ? OutlinedButton.icon(
                  onPressed: onMakeOffer,
                  icon: const Icon(Icons.currency_rupee),
                  label: const Text("Make an offer"),
                )
              : null,
        ),
        const Divider(height: 24),
      ],
    );
  }
}