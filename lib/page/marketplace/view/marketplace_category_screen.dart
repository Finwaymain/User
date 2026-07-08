import 'package:finway/themes/constant_colors.dart';
import 'package:finway/utils/dark_theme_provider.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:provider/provider.dart';
import '../controller/marketplace_controller.dart';
import 'marketplace_category_screen.dart';
import 'marketplace_product_details.dart'; // Self-referential if needed, but I'll use direct screen names.

class MarketplaceCategoryScreen extends StatelessWidget {
  const MarketplaceCategoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final themeChange = Provider.of<DarkThemeProvider>(context);
    final isDark = themeChange.getThem();
    final MarketplaceController controller = Get.find<MarketplaceController>();

    return Scaffold(
      backgroundColor: isDark ? AppThemeData.surface50Dark : const Color(0xFFF9FAFB),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new, color: isDark ? Colors.white : Colors.black, size: 20),
          onPressed: () => Get.back(),
        ),
        title: Text(
          "Browse Categories",
          style: TextStyle(color: isDark ? Colors.white : Colors.black, fontFamily: AppThemeData.bold, fontSize: 20),
        ),
      ),
      body: Obx(() => GridView.builder(
        padding: const EdgeInsets.all(24),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          childAspectRatio: 0.85,
          mainAxisSpacing: 24,
          crossAxisSpacing: 24,
        ),
        itemCount: controller.categories.length,
        itemBuilder: (context, index) {
          final cat = controller.categories[index];
          return GestureDetector(
            onTap: () => Get.to(() => MarketplaceSubCategoryScreen(
              categoryName: cat['name'] as String,
              subCategories: List<String>.from(cat['subCategories'] ?? []),
              icon: cat['icon'] as String,
            )),
            child: Container(
              decoration: BoxDecoration(
                color: isDark ? AppThemeData.grey800 : Colors.white,
                borderRadius: BorderRadius.circular(25),
                boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 15, offset: const Offset(0, 8))],
              ),
              child: Stack(
                children: [
                   Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Expanded(
                        child: ClipRRect(
                          borderRadius: const BorderRadius.vertical(top: Radius.circular(25)),
                          child: Image.network(cat['image'], fit: BoxFit.cover),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        child: Text(
                          cat['name'] as String,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: isDark ? Colors.white : Colors.black,
                            fontSize: 15,
                            fontFamily: AppThemeData.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                  Positioned(
                    top: 12,
                    right: 12,
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.9), shape: BoxShape.circle),
                      child: Icon(_getIconData(cat['icon']), color: AppThemeData.primary200, size: 18),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      )),
    );
  }

  IconData _getIconData(String iconName) {
    switch (iconName) {
      case 'directions_car': return Icons.directions_car_rounded;
      case 'home_work': return Icons.home_work_rounded;
      case 'devices': return Icons.devices_rounded;
      case 'checkroom': return Icons.checkroom_rounded;
      default: return Icons.category_rounded;
    }
  }
}

class MarketplaceSubCategoryScreen extends StatelessWidget {
  final String categoryName;
  final List<String> subCategories;
  final String icon;
  const MarketplaceSubCategoryScreen({super.key, required this.categoryName, required this.subCategories, required this.icon});

  @override
  Widget build(BuildContext context) {
    final themeChange = Provider.of<DarkThemeProvider>(context);
    final isDark = themeChange.getThem();

    return Scaffold(
      backgroundColor: isDark ? AppThemeData.surface50Dark : const Color(0xFFF9FAFB),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new, color: isDark ? Colors.white : Colors.black, size: 20),
          onPressed: () => Get.back(),
        ),
        title: Text(categoryName, style: TextStyle(color: isDark ? Colors.white : Colors.black, fontFamily: AppThemeData.bold, fontSize: 20)),
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(24),
        itemCount: subCategories.length,
        itemBuilder: (context, index) {
          return Container(
            margin: const EdgeInsets.only(bottom: 16),
            decoration: BoxDecoration(
              color: isDark ? AppThemeData.grey800 : Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 10, offset: const Offset(0, 4))],
            ),
            child: ListTile(
              contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
              leading: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(color: AppThemeData.primary200.withValues(alpha: 0.1), shape: BoxShape.circle),
                child: Icon(_getIconData(icon), color: AppThemeData.primary200, size: 20),
              ),
              title: Text(
                subCategories[index],
                style: TextStyle(
                  color: isDark ? Colors.white : Colors.black,
                  fontSize: 16,
                  fontFamily: AppThemeData.medium,
                ),
              ),
              trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 14, color: Colors.grey),
              onTap: () {
                Get.to(() => MarketplaceProductListScreen(
                  category: categoryName,
                  subCategory: subCategories[index],
                ));
              },
            ),
          );
        },
      ),
    );
  }

  IconData _getIconData(String iconName) {
    switch (iconName) {
      case 'devices': return Icons.devices_rounded;
      case 'checkroom': return Icons.checkroom_rounded;
      case 'face': return Icons.face_rounded;
      case 'chair': return Icons.chair_rounded;
      case 'menu_book': return Icons.menu_book_rounded;
      default: return Icons.category_rounded;
    }
  }
}

class MarketplaceProductListScreen extends StatefulWidget {
  final String category;
  final String subCategory;
  const MarketplaceProductListScreen({super.key, required this.category, required this.subCategory});

  @override
  State<MarketplaceProductListScreen> createState() => _MarketplaceProductListScreenState();
}

class _MarketplaceProductListScreenState extends State<MarketplaceProductListScreen> {
  String _selectedFilter = "All"; // "All", "New", "Used"

  @override
  Widget build(BuildContext context) {
    final themeChange = Provider.of<DarkThemeProvider>(context);
    final isDark = themeChange.getThem();
    final MarketplaceController controller = Get.find<MarketplaceController>();

    final filtered = controller.products.where((p) {
      bool categoryMatch = p['mainCategory'] == widget.category && 
          (widget.subCategory == "All" || p['subCategory'] == widget.subCategory);
      
      bool filterMatch = _selectedFilter == "All" || p['condition'] == _selectedFilter;
      
      return categoryMatch && filterMatch;
    }).toList();

    return Scaffold(
      backgroundColor: isDark ? AppThemeData.surface50Dark : const Color(0xFFF9FAFB),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new, color: isDark ? Colors.white : Colors.black, size: 20),
          onPressed: () => Get.back(),
        ),
        title: Column(
          children: [
            Text(widget.subCategory, style: TextStyle(color: isDark ? Colors.white : Colors.black, fontFamily: AppThemeData.bold, fontSize: 18)),
            Text(widget.category, style: TextStyle(color: Colors.grey, fontSize: 12)),
          ],
        ),
      ),
      body: Column(
        children: [
          _buildFilterBar(isDark),
          Expanded(
            child: filtered.isEmpty 
              ? const Center(child: Text("No products found in this category"))
              : GridView.builder(
                  padding: const EdgeInsets.all(20),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    childAspectRatio: 0.72,
                    mainAxisSpacing: 20,
                    crossAxisSpacing: 15,
                  ),
                  itemCount: filtered.length,
                  itemBuilder: (context, index) => _buildCard(context, isDark, filtered[index], index),
                ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterBar(bool isDark) {
    final filters = ["All", "New", "Used"];
    return Container(
      height: 60,
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: filters.length,
        itemBuilder: (context, index) {
          final filter = filters[index];
          final isSelected = _selectedFilter == filter;
          return Padding(
            padding: const EdgeInsets.only(right: 12),
            child: ChoiceChip(
              label: Text(filter),
              selected: isSelected,
              onSelected: (selected) {
                if (selected) setState(() => _selectedFilter = filter);
              },
              backgroundColor: isDark ? AppThemeData.grey800 : Colors.white,
              selectedColor: AppThemeData.primary200,
              labelStyle: TextStyle(
                color: isSelected ? Colors.white : (isDark ? Colors.white70 : Colors.grey[600]),
                fontFamily: AppThemeData.bold,
                fontSize: 13,
              ),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
              side: BorderSide(color: isSelected ? AppThemeData.primary200 : (isDark ? Colors.white12 : Colors.grey[200]!)),
              showCheckmark: false,
              elevation: 0,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            ),
          );
        },
      ),
    );
  }

  Widget _buildCard(BuildContext context, bool isDark, Map<String, dynamic> product, int index) {
      final String title = (product['title'] ?? "Product").toString();
      final String price = (product['price'] ?? "0.00").toString();
      final String condition = (product['condition'] ?? "New").toString();
      final String imageUrl = (product['image'] ?? "https://via.placeholder.com/300").toString();
      final String rating = (product['rating'] ?? "0.0").toString();
      // final String reviews = (product['reviews'] ?? "0").toString();

      return GestureDetector(
        onTap: () => Get.to(() => MarketplaceProductDetailsScreen(product: product)),
        child: Container(
          decoration: BoxDecoration(
            color: isDark ? AppThemeData.grey800 : Colors.white,
            borderRadius: BorderRadius.circular(15),
            boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 10, offset: const Offset(0, 5))],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Stack(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.network(imageUrl, fit: BoxFit.cover, width: double.infinity, height: double.infinity),
                    ),
                    Positioned(
                      top: 10,
                      left: 10,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: (condition == "New" ? AppThemeData.primary200 : Colors.orangeAccent).withValues(alpha: 0.9),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(condition, style: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold)),
                      ),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, maxLines: 2, overflow: TextOverflow.ellipsis, 
                      style: TextStyle(color: isDark ? Colors.white : Colors.black, fontSize: 13, fontFamily: AppThemeData.bold)),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Text(price, style: TextStyle(color: AppThemeData.primary200, fontSize: 14, fontFamily: AppThemeData.bold)),
                        const Spacer(),
                        const Icon(Icons.star, color: Color(0xFFFFC003), size: 14),
                        Text(rating, style: const TextStyle(fontSize: 11, color: Colors.grey)),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      );
  }
}

