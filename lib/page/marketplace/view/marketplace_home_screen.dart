import 'dart:ui';
import 'package:provider/provider.dart';

import '../../../themes/constant_colors.dart';
import '../../../utils/dark_theme_provider.dart';
import '../controller/marketplace_controller.dart';
import 'add_product_screen.dart';
import 'marketplace_cart_screen.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'marketplace_category_screen.dart';
import 'marketplace_product_details.dart';
import 'marketplace_profile_screen.dart';

class MarketplaceHomeScreen extends StatefulWidget {
  const MarketplaceHomeScreen({Key? key}) : super(key: key);

  @override
  State<MarketplaceHomeScreen> createState() => _MarketplaceHomeScreenState();
}

class _MarketplaceHomeScreenState extends State<MarketplaceHomeScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _searchController = TextEditingController();
  final MarketplaceController _controller = Get.put(MarketplaceController());
  final ScrollController _scrollController = ScrollController();
  var _appBarOpacity = 0.0.obs;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _controller.tabs.length, vsync: this);
    _tabController.addListener(() {
      _controller.selectedTab.value = _tabController.index;
    });
    _scrollController.addListener(() {
      double offset = _scrollController.offset;
      _appBarOpacity.value = (offset / 150).clamp(0.0, 1.0);
    });
  }

  static Color accentGreen = AppThemeData.primary200;

  @override
  Widget build(BuildContext context) {
    final themeChange = Provider.of<DarkThemeProvider>(context);
    final isDark = themeChange.getThem();

    return Scaffold(
      backgroundColor: isDark ? AppThemeData.surface50Dark : const Color(0xFFF9FAFB),
      bottomNavigationBar: Obx(() {
        int currentIndex = _controller.selectedTab.value;
        
        return Container(
          height: 80,
          color: Colors.transparent,
          child: Stack(
            alignment: Alignment.topCenter,
            children: [
              Container(
                height: 70,
                child: Container(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _buildNavItem(
                        icon: Icons.arrow_back_rounded,
                        label: 'Back'.tr,
                        isSelected: false,
                        onTap: () => Get.back(),
                        isDarkMode: isDark,
                        isCircular: true,
                      ),
                      Container(
                        height: 30,
                        width: 1.5,
                        color: (isDark ? Colors.white : Colors.black).withOpacity(0.1),
                      ),
                      _buildNavItem(
                        icon: Icons.grid_view_rounded,
                        label: 'All'.tr,
                        isSelected: currentIndex == 0,
                        onTap: () => _controller.selectedTab.value = 0,
                        isDarkMode: isDark,
                      ),
                      _buildNavItem(
                        icon: Icons.new_releases_outlined,
                        label: 'New'.tr,
                        isSelected: currentIndex == 1,
                        onTap: () => _controller.selectedTab.value = 1,
                        isDarkMode: isDark,
                      ),
                      _buildNavItem(
                        icon: Icons.history_rounded,
                        label: 'Old'.tr,
                        isSelected: currentIndex == 2,
                        onTap: () => _controller.selectedTab.value = 2,
                        isDarkMode: isDark,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      }),
      body: Material(
        color: Colors.transparent,
        child: Stack(
          children: [
            Positioned.fill(child: _buildMainScroll(isDark)),
            Obx(() => _buildGlassAppBar(isDark)),
          ],
        ),
      ),
    );
  }

  Widget _buildNavItem({
    required IconData icon,
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
    required bool isDarkMode,
    bool isCircular = false,
  }) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            padding: EdgeInsets.all(isCircular ? 8 : (isSelected ? 10 : 8)),
            decoration: BoxDecoration(
              color: isSelected ? AppThemeData.primary200.withOpacity(0.12) : Colors.transparent,
              borderRadius: isCircular ? null : BorderRadius.circular(20),
              border: isCircular
                  ? Border.all(
                      color: (isDarkMode ? Colors.white : Colors.black).withOpacity(0.2),
                      width: 1.5,
                    )
                  : null,
              shape: isCircular ? BoxShape.circle : BoxShape.rectangle,
            ),
            child: AnimatedScale(
              duration: const Duration(milliseconds: 300),
              scale: isSelected ? 1.1 : 1.0,
              child: Icon(
                icon,
                size: 20,
                color: isSelected ? AppThemeData.primary200 : (isDarkMode ? AppThemeData.grey500Dark : AppThemeData.grey500),
              ),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
              color: isSelected ? AppThemeData.primary200 : (isDarkMode ? AppThemeData.grey500Dark : AppThemeData.grey500),
              letterSpacing: 0.2,
            ),
          ),
        ],
      ),
    );
  }



  Widget _buildGlassAppBar(bool isDark) {
    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      child: IgnorePointer(
        ignoring: _appBarOpacity.value == 0.0,
        child: Opacity(
          opacity: _appBarOpacity.value,
          child: ClipRRect(
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: Container(
              height: 100,
              padding: EdgeInsets.only(top: MediaQuery.of(context).padding.top, left: 20, right: 20),
              decoration: BoxDecoration(
                color: (isDark ? Colors.black : Colors.white).withOpacity(0.7),
                border: Border(bottom: BorderSide(color: isDark ? Colors.white10 : Colors.black12, width: 0.5)),
              ),
              child: Row(
                children: [
                  const Text("Marketplace", style: TextStyle(fontSize: 20, fontFamily: AppThemeData.bold)),
                  const Spacer(),
                  GestureDetector(
                    onTap: () => Get.to(() => const AddProductScreen()),
                    child: Icon(Icons.add_box_outlined, color: isDark ? Colors.white : Colors.black, size: 26),
                  ),
                  const SizedBox(width: 15),
                  GestureDetector(
                    onTap: () => Get.to(() => const MarketplaceProfileScreen()),
                    child: Icon(Icons.storefront_outlined, color: isDark ? Colors.white : Colors.black, size: 26),
                  ),
                  const SizedBox(width: 15),
                  GestureDetector(
                    onTap: () => Get.to(() => const MarketplaceCartScreen()),
                    child: _badgeIcon(Icons.shopping_bag_outlined, _controller.cartItems.length, isDark)
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    ),
    );
  }

  Widget _buildMainScroll(bool isDark) {
    return RefreshIndicator(
      onRefresh: () => _controller.fetchMarketplaceData(),
      child: Obx(() {
        return CustomScrollView(
          controller: _scrollController,
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            _buildSliverHeader(isDark),
            SliverToBoxAdapter(child: _buildBannerSlider()),
            SliverToBoxAdapter(child: _buildCategoryGrid(isDark)),
            SliverToBoxAdapter(child: _buildSubCategoryBar(isDark)),
            SliverToBoxAdapter(child: _buildSectionTitle(isDark, "Recommended For You")),
            _buildProductGrid(isDark),
            const SliverToBoxAdapter(child: SizedBox(height: 100)),
          ],
        );
      }),
    );
  }

  Widget _buildSliverHeader(bool isDark) {
    return SliverPadding(
      padding: EdgeInsets.only(top: MediaQuery.of(context).padding.top + 10, left: 20, right: 20, bottom: 10),
      sliver: SliverToBoxAdapter(
        child: Row(
          children: [
            Expanded(
              child: Container(
                height: 50,
                padding: const EdgeInsets.symmetric(horizontal: 15),
                decoration: BoxDecoration(
                  color: isDark ? AppThemeData.grey800 : Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey[200]!),
                ),
                child: Row(
                  children: [
                    Icon(Icons.search, color: Colors.grey[400], size: 22),
                    const SizedBox(width: 10),
                    Expanded(child: Text("Search..", overflow: TextOverflow.ellipsis, style: TextStyle(color: Colors.grey[400], fontSize: 14))),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 15),
            GestureDetector(
              onTap: () => Get.to(() => const AddProductScreen()),
              child: Icon(Icons.add_box_outlined, color: isDark ? Colors.white : Colors.black, size: 26),
            ),
            const SizedBox(width: 15),
            GestureDetector(
              onTap: () => Get.to(() => const MarketplaceProfileScreen()),
              child: Icon(Icons.storefront_outlined, color: isDark ? Colors.white : Colors.black, size: 26),
            ),
            const SizedBox(width: 15),
            GestureDetector(
              onTap: () => Get.to(() => const MarketplaceCartScreen()),
              child: _badgeIcon(Icons.shopping_bag_outlined, _controller.cartItems.length, isDark)
            ),
          ],
        ),
      ),
    );
  }
  Widget _badgeIcon(IconData icon, int count, bool isDark) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Icon(icon, color: isDark ? Colors.white : Colors.black, size: 26),
        if (count > 0)
          Positioned(
            top: -5,
            right: -5,
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: const BoxDecoration(color: Color(0xFFFA5075), shape: BoxShape.circle),
              child: Text(
                count > 9 ? "9+" : count.toString(),
                style: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildBannerSlider() {
    return SizedBox(
      height: 220,
      child: PageView.builder(
        itemCount: _controller.banners.length,
        itemBuilder: (context, index) {
          final banner = _controller.banners[index];
          final String title = (banner['title'] ?? "").toString();
          final String discount = (banner['discount'] ?? "").toString();
          final String subtitle = (banner['subtitle'] ?? "").toString();
          final String imageUrl = (banner['image'] ?? "https://via.placeholder.com/400x200?text=Banner").toString();

          return Container(
            margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            padding: const EdgeInsets.symmetric(horizontal: 25, vertical: 20),
            decoration: BoxDecoration(
              color: const Color(0xFFF2F2F2),
              borderRadius: BorderRadius.circular(15),
              image: DecorationImage(
                image: NetworkImage(imageUrl),
                fit: BoxFit.cover,
                alignment: Alignment.centerRight,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(title, style: const TextStyle(fontSize: 10, fontFamily: AppThemeData.bold, letterSpacing: 1.5)),
                const SizedBox(height: 5),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(discount, style: const TextStyle(fontSize: 40, fontFamily: AppThemeData.bold, height: 1.0)),
                ),
                const SizedBox(height: 5),
                SizedBox(
                  width: 140,
                  child: Text(subtitle, style: const TextStyle(fontSize: 11, color: Colors.grey, height: 1.3, fontWeight: FontWeight.w500)),
                ),
                const SizedBox(height: 15),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: const Color(0xFF242424),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Text("Check this out", style: TextStyle(color: Colors.white, fontSize: 11, fontFamily: AppThemeData.bold)),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildCategoryGrid(bool isDark) {
    return Column(
      children: [
        SizedBox(
          height: 110,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 10),
            itemCount: _controller.categories.length,
            itemBuilder: (context, index) {
              final cat = _controller.categories[index];
              final isSelected = _controller.selectedCategory.value == cat['name'];
              return GestureDetector(
                onTap: () {
                  Get.to(() => MarketplaceSubCategoryScreen(
                    categoryName: cat['name'] as String,
                    subCategories: List<String>.from(cat['subCategories'] ?? []),
                    icon: cat['icon'] as String,
                  ));
                },
                child: Container(
                  width: 85,
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  child: Column(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: isSelected
                            ? accentGreen.withOpacity(0.1)
                            : (isDark ? AppThemeData.grey800 : Colors.grey[100]),
                          borderRadius: BorderRadius.circular(15),
                          border: Border.all(
                            color: isSelected ? accentGreen : Colors.transparent,
                            width: 1.5
                          ),
                        ),
                        child: Icon(
                          _getIconData(cat['icon']),
                          color: isSelected ? accentGreen : Colors.grey[600],
                          size: 24
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(cat['name'] ?? "", maxLines: 1, overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 11,
                          color: isDark ? Colors.white70 : Colors.grey[800],
                          fontFamily: AppThemeData.medium
                        )
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildSubCategoryBar(bool isDark) {
    if (_controller.selectedCategory.value.isEmpty) return const SizedBox.shrink();

    final currentCat = _controller.categories.firstWhereOrNull((c) => c['name'] == _controller.selectedCategory.value);
    if (currentCat == null) return const SizedBox.shrink();

    final list = List<String>.from(currentCat['subCategories'] ?? []);

    return Padding(
      padding: const EdgeInsets.only(top: 10, bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              children: [
                Text(_controller.selectedCategory.value, style: const TextStyle(fontFamily: AppThemeData.bold, fontSize: 16)),
                const Spacer(),
                GestureDetector(
                  onTap: () {
                    _controller.selectedCategory.value = "";
                    _controller.selectedSubCategory.value = "";
                  },
                  child: const Text("Clear", style: TextStyle(color: Colors.redAccent, fontSize: 12)),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 38,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 15),
              itemCount: list.length,
              itemBuilder: (context, index) {
                final sub = list[index];
                final isSubSelected = _controller.selectedSubCategory.value == sub;
                return GestureDetector(
                  onTap: () => _controller.selectedSubCategory.value = sub,
                    child: Container(
                      margin: const EdgeInsets.symmetric(horizontal: 5),
                      padding: const EdgeInsets.symmetric(horizontal: 18),
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: isSubSelected ? accentGreen : (isDark ? AppThemeData.grey800 : Colors.white),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: isSubSelected ? accentGreen : Colors.grey[200]!),
                      ),
                      child: Text(sub, style: TextStyle(
                        color: isSubSelected ? Colors.white : (isDark ? Colors.white70 : Colors.grey[600]),
                        fontSize: 13,
                        fontFamily: AppThemeData.bold
                      )),
                    ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(bool isDark, String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 30, 20, 10),
      child: Text(
        title, 
        style: TextStyle(
          color: isDark ? Colors.white : Colors.black, 
          fontSize: 18, 
          fontFamily: AppThemeData.bold
        )
      ),
    );
  }

  Widget _buildProductGrid(bool isDark) {
    if (_controller.isLoading.value) {
      return const SliverToBoxAdapter(child: SizedBox(height: 200, child: Center(child: CircularProgressIndicator())));
    }

    final filtered = List<Map<String, dynamic>>.from(_controller.filteredProducts);
    if (filtered.isEmpty) {
      return const SliverToBoxAdapter(child: SizedBox(height: 200, child: Center(child: Text("No products found"))));
    }

    return SliverPadding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      sliver: SliverGrid(
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          childAspectRatio: 0.72,
          mainAxisSpacing: 20,
          crossAxisSpacing: 15,
        ),
        delegate: SliverChildBuilderDelegate(
          (context, index) {
            final product = filtered[index];
            return _buildPremiumCard(isDark, product, index);
          },
          childCount: filtered.length,
        ),
      ),
    );
  }

  Widget _buildPremiumCard(bool isDark, Map<String, dynamic> product, int index) {
    final String title = (product['title'] ?? "Product").toString();
    final String price = (product['price'] ?? "₹0.00").toString();
    final String condition = (product['condition'] ?? "New").toString();
    final String imageUrl = (product['image'] ?? "https://via.placeholder.com/300").toString();
    final String subtitle = (product['subtitle'] ?? "Marketplace").toString();
    final String rating = (product['rating'] ?? "0.0").toString();
    final String reviews = (product['reviews'] ?? "0").toString();

    return GestureDetector(
      onTap: () => Get.to(() => MarketplaceProductDetailsScreen(product: product)),
      child: Container(
        decoration: BoxDecoration(
          color: isDark ? AppThemeData.grey800 : Colors.white,
          borderRadius: BorderRadius.circular(15),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10, offset: const Offset(0, 5))],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Stack(
                children: [
                  Hero(
                    tag: 'prod_${product['id'] ?? index}',
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.network(
                        imageUrl, 
                        fit: BoxFit.cover, 
                        width: double.infinity, 
                        height: double.infinity,
                        errorBuilder: (context, error, stackTrace) => Container(
                          color: Colors.grey[200],
                          child: const Icon(Icons.image_not_supported, color: Colors.grey),
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    top: 10,
                    right: 10,
                    child: Icon(Icons.favorite_border, color: Colors.grey[400], size: 20),
                  ),
                  Positioned(
                    top: 10,
                    left: 10,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: (condition == "New" ? accentGreen : Colors.orangeAccent).withOpacity(0.9),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        condition,
                        style: const TextStyle(color: Colors.white, fontSize: 9, fontFamily: AppThemeData.bold)
                      ),
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
                  Text(subtitle, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(color: Colors.grey[400], fontSize: 11)),
                  const SizedBox(height: 4),
                  Text(title, maxLines: 2, overflow: TextOverflow.ellipsis, 
                    style: TextStyle(color: isDark ? Colors.white : Colors.black, fontSize: 13, fontFamily: AppThemeData.bold, height: 1.2)),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      if (condition == "Used")
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.blue.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: const Text("Contact", style: TextStyle(color: Colors.blue, fontSize: 10, fontFamily: AppThemeData.bold)),
                        )
                      else ...[
                        const Icon(Icons.star, color: Color(0xFFFFC003), size: 14),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text("$rating | $reviews", style: TextStyle(color: Colors.grey[400], fontSize: 11)),
                        ),
                      ],
                      const Spacer(),
                      Text(price, style:  TextStyle(color: accentGreen, fontSize: 14, fontFamily: AppThemeData.bold)),
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

  IconData _getIconData(dynamic iconName) {
    if (iconName == null || iconName is! String) return Icons.category_rounded;
    switch (iconName) {
      case 'devices': return Icons.devices_rounded;
      case 'checkroom': return Icons.checkroom_rounded;
      case 'face': return Icons.face_rounded;
      case 'chair': return Icons.chair_rounded;
      case 'menu_book': return Icons.menu_book_rounded;
      case 'grid_view': return Icons.grid_view_rounded;
      case 'flight': return Icons.flight_rounded;
      case 'receipt_long': return Icons.receipt_long_rounded;
      case 'language': return Icons.language_rounded;
      case 'vibration': return Icons.vibration_rounded;
      default: return Icons.category_rounded;
    }
  }
}


class _TabDelegate extends SliverPersistentHeaderDelegate {
  final bool isDark;
  final TabController tabController;
  final MarketplaceController controller;

  _TabDelegate(this.isDark, this.tabController, this.controller);

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    return SizedBox.expand(
      child: Container(
        color: isDark ? AppThemeData.surface50Dark : const Color(0xFFF9FAFB),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
        child: Row(
          children: controller.tabs.asMap().entries.map((entry) {
            int idx = entry.key;
            String label = entry.value;
            bool isSelected = tabController.index == idx;
            
            return Padding(
              padding: const EdgeInsets.only(right: 12),
              child: GestureDetector(
                onTap: () {
                  tabController.animateTo(idx);
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  decoration: BoxDecoration(
                    color: isSelected ? AppThemeData.primary200 : Colors.transparent,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    label,
                    style: TextStyle(
                      color: isSelected ? Colors.white : Colors.grey[400],
                      fontSize: 15,
                      fontFamily: AppThemeData.bold,
                    ),
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  @override
  double get maxExtent => 70;
  @override
  double get minExtent => 70;
  @override
  bool shouldRebuild(covariant SliverPersistentHeaderDelegate oldDelegate) => true;
}
