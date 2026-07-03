import 'package:provider/provider.dart';

import '../../../themes/constant_colors.dart';
import '../../../utils/dark_theme_provider.dart';
import '../controller/marketplace_controller.dart';
import 'marketplace_cart_screen.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class MarketplaceProductDetailsScreen extends StatefulWidget {
  final Map<String, dynamic> product;
  const MarketplaceProductDetailsScreen({super.key, required this.product});

  @override
  State<MarketplaceProductDetailsScreen> createState() => _MarketplaceProductDetailsScreenState();
}

class _MarketplaceProductDetailsScreenState extends State<MarketplaceProductDetailsScreen> {
  int _currentImageIndex = 0;
  // final PageController _pageController = PageController(); // Removed as not used in new image section
  final MarketplaceController _controller = Get.find<MarketplaceController>();

  static Color accentGreen = AppThemeData.primary200;
  int _quantity = 1;

  @override
  Widget build(BuildContext context) {
    final themeChange = Provider.of<DarkThemeProvider>(context);
    final isDark = themeChange.getThem();
    final List<String> images = List<String>.from(widget.product['images'] ?? [widget.product['image']]);

    return Scaffold(
      backgroundColor: isDark ? AppThemeData.surface50Dark : Colors.white,
      body: Stack(
        children: [
          _buildMainContent(isDark, images),
          _buildHeaderActions(isDark),
          _buildBottomActionBar(isDark),
        ],
      ),
    );
  }

  Widget _buildHeaderActions(bool isDark) {
    return Positioned(
      top: MediaQuery.of(context).padding.top + 10,
      left: 16,
      right: 16,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            icon: Icon(Icons.arrow_back_ios_new, color: isDark ? Colors.white : Colors.black, size: 20),
            onPressed: () => Get.back(),
          ),
          Row(
            children: [
              _badgeIcon(Icons.shopping_bag_outlined, _controller.cartItems.length, isDark),
            ],
          ),
        ],
      ),
    );
  }

  Widget _badgeIcon(IconData icon, int count, bool isDark) {
    return GestureDetector(
      onTap: () => Get.to(() => const MarketplaceCartScreen()),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Icon(icon, color: isDark ? Colors.white : Colors.black, size: 24),
          if (count > 0)
            Positioned(
              top: -5,
              right: -5,
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: const BoxDecoration(color: Color(0xFFFA5075), shape: BoxShape.circle),
                child: Text(
                  count.toString(),
                  style: const TextStyle(color: Colors.white, fontSize: 8, fontWeight: FontWeight.bold),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildMainContent(bool isDark, List<String> images) {
    return SingleChildScrollView(
      padding: const EdgeInsets.only(bottom: 120),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 100),
          _buildImageSection(images),
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                   children: [
                     Icon(Icons.storefront, color: Colors.grey[400], size: 16),
                     const SizedBox(width: 5),
                     Text("tokobaju.id", style: TextStyle(color: Colors.grey[400], fontSize: 13)),
                   ],
                ),
                const SizedBox(height: 10),
                Text(
                  widget.product['title'],
                  style: TextStyle(
                    color: isDark ? Colors.white : Colors.black,
                    fontSize: 20,
                    fontFamily: AppThemeData.bold,
                    height: 1.3,
                  ),
                ),
                const SizedBox(height: 15),
                Row(
                  children: [
                    const Icon(Icons.star, color: Color(0xFFFFC003), size: 18),
                    const SizedBox(width: 5),
                    Text(
                      "${widget.product['rating'] ?? '4.5'} Ratings",
                      style: TextStyle(color: Colors.grey[500], fontSize: 13, fontFamily: AppThemeData.medium),
                    ),
                    const SizedBox(width: 15),
                    _dot(),
                    const SizedBox(width: 15),
                    Text(
                      "${widget.product['reviews'] ?? '1.2k'} Reviews",
                      style: TextStyle(color: Colors.grey[500], fontSize: 13, fontFamily: AppThemeData.medium),
                    ),
                    const SizedBox(width: 15),
                    _dot(),
                    const SizedBox(width: 15),
                    Text(
                      widget.product['sold'] ?? "2.9k + Sold",
                      style: TextStyle(color: Colors.grey[500], fontSize: 13, fontFamily: AppThemeData.medium),
                    ),
                  ],
                ),
                _buildTabs(isDark),
                _buildAttributes(isDark),
                const SizedBox(height: 20),
                Text(
                  "This premium ${widget.product['title']} is in excellent condition. It has been meticulously maintained and offers cutting-edge performance in its category.\n\nKey features include high durability, premium materials, and top-tier specifications. Perfect for those who value quality and reliability.",
                  style: TextStyle(
                      color: Colors.grey[500],
                      fontSize: 15,
                      fontFamily: AppThemeData.medium,
                      height: 1.6),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _dot() {
    return Container(width: 4, height: 4, decoration: const BoxDecoration(color: Colors.grey, shape: BoxShape.circle));
  }

  Widget _buildImageSection(List<String> images) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 80,
          padding: const EdgeInsets.only(left: 20),
          child: Column(
            children: List.generate(images.length, (index) => GestureDetector(
              onTap: () => setState(() => _currentImageIndex = index),
              child: Container(
                margin: const EdgeInsets.only(bottom: 12),
                height: 50,
                width: 50,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: _currentImageIndex == index ? accentGreen : Colors.grey[200]!,
                    width: 2,
                  ),
                  image: DecorationImage(image: NetworkImage(images[index]), fit: BoxFit.cover),
                ),
              ),
            )),
          ),
        ),
        Expanded(
          child: Container(
            height: 350,
            margin: const EdgeInsets.only(right: 20),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              image: DecorationImage(
                image: NetworkImage(images[_currentImageIndex]),
                fit: BoxFit.contain,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTabs(bool isDark) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 25),
      decoration: BoxDecoration(border: Border(bottom: BorderSide(color: Colors.grey[100]!))),
      child: Row(
        children: [
          _tabItem("About Item", true, isDark),
          const SizedBox(width: 30),
          _tabItem("Reviews", false, isDark),
        ],
      ),
    );
  }

  Widget _tabItem(String title, bool active, bool isDark) {
    return Container(
      padding: const EdgeInsets.only(bottom: 15),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: active ? accentGreen : Colors.transparent, width: 2)),
      ),
      child: Text(
        title,
        style: TextStyle(
          color: active ? accentGreen : Colors.grey[400],
          fontFamily: AppThemeData.bold,
          fontSize: 14,
        ),
      ),
    );
  }

  Widget _buildAttributes(bool isDark) {
    return Row(
      children: [
        _attrColumn("Brand:", widget.product['brand'] ?? "ChArmkpR", isDark),
        const SizedBox(width: 50),
        _attrColumn("Color:", widget.product['color'] ?? "Aprikot", isDark),
      ],
    );
  }

  Widget _attrColumn(String label, String value, bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: TextStyle(color: Colors.grey[400], fontSize: 12)),
        const SizedBox(height: 8),
        Text(value, style: TextStyle(color: isDark ? Colors.white : Colors.black, fontSize: 14, fontFamily: AppThemeData.bold)),
      ],
    );
  }

  Widget _buildBottomActionBar(bool isDark) {
    return Positioned(
      bottom: 0,
      left: 0,
      right: 0,
      child: Container(
        padding: const EdgeInsets.fromLTRB(25, 20, 25, 40),
        decoration: BoxDecoration(
          color: isDark ? AppThemeData.surface50Dark : Colors.white,
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 20, offset: const Offset(0, -10))],
        ),
        child: Row(
          children: [
            Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("Total Price", style: TextStyle(color: Colors.grey[400], fontSize: 11)),
                const SizedBox(height: 5),
                Text(
                  widget.product['price'],
                  style:  TextStyle(color: accentGreen, fontSize: 22, fontFamily: AppThemeData.bold),
                ),
              ],
            ),
            const Spacer(),
            Container(
              decoration: BoxDecoration(
                color: accentGreen.withValues(alpha: 0.1),
                borderRadius: const BorderRadius.horizontal(left: Radius.circular(10)),
              ),
              child: Row(
                children: [
                  IconButton(
                    icon:  Icon(Icons.remove, color: accentGreen, size: 20),
                    onPressed: () {
                      setState(() {
                        if (_quantity > 1) _quantity--;
                      });
                    },
                  ),
                  Text(
                    "$_quantity",
                    style: const TextStyle(color: Colors.black, fontFamily: AppThemeData.bold),
                  ),
                  IconButton(
                    icon:  Icon(Icons.add, color: accentGreen, size: 20),
                    onPressed: () {
                      setState(() {
                        _quantity++;
                      });
                    },
                  ),
                ],
              ),
            ),
            GestureDetector(
              onTap: () {
                if (widget.product['condition'] == "Used") {
                  Get.bottomSheet(
                    Container(
                      padding: const EdgeInsets.all(25),
                      decoration: BoxDecoration(
                        color: isDark ? AppThemeData.grey900 : Colors.white,
                        borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(2))),
                          const SizedBox(height: 25),
                          const Text("Contact Seller", style: TextStyle(fontSize: 20, fontFamily: AppThemeData.bold)),
                          const SizedBox(height: 15),
                          const Text("Interested in this item? Connect with the seller directly to negotiate or ask questions.", textAlign: TextAlign.center, style: TextStyle(color: Colors.grey)),
                          const SizedBox(height: 30),
                          _contactBtn(Icons.chat_bubble_rounded, "Chat with Seller", Colors.blue),
                          const SizedBox(height: 12),
                          _contactBtn(Icons.phone_rounded, "Call Seller", accentGreen),
                          const SizedBox(height: 12),
                          _contactBtn(Icons.alternate_email_rounded, "Send Email", Colors.orange),
                          const SizedBox(height: 20),
                        ],
                      ),
                    )
                  );
                } else {
                  _controller.addToCart(widget.product, quantity: _quantity);
                  Get.snackbar("Success", "${widget.product['title']} added to Cart", 
                    backgroundColor: accentGreen, colorText: Colors.white, snackPosition: SnackPosition.TOP);
                }
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 25, vertical: 15),
                decoration: BoxDecoration(
                  color: widget.product['condition'] == "Used" ? Colors.blue : const Color(0xFF242B4E),
                  borderRadius: const BorderRadius.horizontal(right: Radius.circular(10)),
                ),
                child: Text(
                  widget.product['condition'] == "Used" ? "Contact Seller" : "Buy Now",
                  style: const TextStyle(color: Colors.white, fontFamily: AppThemeData.bold, fontSize: 14),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _contactBtn(IconData icon, String label, Color color) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 15),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: 12),
          Text(label, style: TextStyle(color: color, fontFamily: AppThemeData.bold)),
        ],
      ),
    );
  }
}
