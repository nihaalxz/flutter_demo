import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:myfirstflutterapp/models/category_model.dart';
import 'package:myfirstflutterapp/environment/env.dart';
import 'package:myfirstflutterapp/pages/CategoryProductsPage.dart';

class CategoriesSection extends StatelessWidget {
  final List<CategoryModel> categories;

  const CategoriesSection({super.key, required this.categories});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 20),
          child: Text(
            'Categories',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: theme.colorScheme.onBackground,
            ),
          ),
        ),
        const SizedBox(height: 15),
        SizedBox(
          height: 90,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.only(left: 20, right: 10),
            itemCount: categories.length,
            itemBuilder: (context, index) {
              final category = categories[index];
              return CategoryItem(category: category);
            },
          ),
        ),
      ],
    );
  }
}

class CategoryItem extends StatefulWidget {
  final CategoryModel category;

  const CategoryItem({super.key, required this.category});

  @override
  State<CategoryItem> createState() => _CategoryItemState();
}

class _CategoryItemState extends State<CategoryItem> {
  bool _isSvg(String? url) {
    if (url == null || url.isEmpty) return false;
    return url.toLowerCase().endsWith('.svg');
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    
    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => CategoryProductsPage(
              categoryId: widget.category.id,
              categoryName: widget.category.name,
            ),
          ),
        );
      },
      child: Container(
        width: 80,
        margin: const EdgeInsets.only(right: 10),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              height: 60,
              width: 60,
              decoration: BoxDecoration(
                color: isDark ? const Color.fromARGB(255, 29, 30, 33) : Colors.grey[200],
                borderRadius: BorderRadius.circular(14),
                boxShadow: [
                  BoxShadow(
                    color: const Color.fromARGB(255, 120, 111, 111).withOpacity(isDark ? 0.3 : 0.1),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(14),
                child: _buildCategoryIcon(context),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              widget.category.name,
              style: TextStyle(
                fontSize: 12, 
                fontWeight: FontWeight.w500,
                color: theme.colorScheme.onBackground.withOpacity(0.8),
              ),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryIcon(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final iconUrl = widget.category.iconImage;
    
    if (iconUrl == null || iconUrl.isEmpty) {
      return _buildFallbackIcon(context);
    }

    final fullUrl = "${AppConfig.imageBaseUrl}$iconUrl";

    try {
      if (_isSvg(iconUrl)) {
        return SvgPicture.network(
          fullUrl,
          fit: BoxFit.contain,
          width: 30,
          height: 30,
          colorFilter: ColorFilter.mode(
            isDark ? Colors.white : Colors.black87, // SVG color adapts to theme
            BlendMode.srcIn,
          ),
          placeholderBuilder: (context) => _buildLoadingState(context),
        );
      } else {
        // For regular images, we can't change color, so we rely on the background contrast
        return CachedNetworkImage(
          imageUrl: fullUrl,
          fit: BoxFit.contain,
          placeholder: (context, url) => _buildLoadingState(context),
          errorWidget: (context, url, error) => _buildFallbackIcon(context),
        );
      }
    } catch (e) {
      return _buildFallbackIcon(context);
    }
  }

  Widget _buildLoadingState(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    
    return Container(
      color: isDark ? Colors.grey[800] : Colors.grey[200],
      child: Center(
        child: SizedBox(
          width: 20,
          height: 20,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            color: theme.colorScheme.primary,
          ),
        ),
      ),
    );
  }

  Widget _buildFallbackIcon(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    
    return Container(
      color: isDark ? Colors.grey[700] : Colors.grey[300],
      child: Center(
        child: Icon(
          Icons.category, 
          color: isDark ? Colors.grey[400] : Colors.grey[600],
          size: 24,
        ),
      ),
    );
  }
}