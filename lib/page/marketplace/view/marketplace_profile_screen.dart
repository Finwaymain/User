import 'package:finway/themes/constant_colors.dart';
import 'package:finway/utils/dark_theme_provider.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:provider/provider.dart';

import '../controller/marketplace_controller.dart';
import 'marketplace_orders_screen.dart';

class MarketplaceProfileScreen extends StatelessWidget {
  const MarketplaceProfileScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final themeChange = Provider.of<DarkThemeProvider>(context);
    final isDark = themeChange.getThem();
    final MarketplaceController controller = Get.find<MarketplaceController>();

    // Fetch user products when viewing profile
    controller.fetchMyMarketplaceProducts();

    return Scaffold(
      backgroundColor: isDark ? AppThemeData.surface50Dark : AppThemeData.surface50,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new, color: isDark ? Colors.white : Colors.black, size: 20),
          onPressed: () => Get.back(),
        ),
        title: Text(
          "Marketplace Profile",
          style: TextStyle(color: isDark ? Colors.white : Colors.black, fontFamily: AppThemeData.bold, fontSize: 18),
        ),
      ),
      body: Obx(() {
        if (controller.isMyProductsLoading.value) {
          return const Center(child: CircularProgressIndicator());
        }
        return RefreshIndicator(
          onRefresh: () => controller.fetchMyMarketplaceProducts(),
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            child: Column(
              children: [
                _buildProfileCard(isDark),
                _buildStatsRow(isDark, controller),
                _buildOrdersButton(context, isDark),
                const SizedBox(height: 10),
                _buildListingsSection(isDark, controller),
                _buildSavedSection(isDark),
              ],
            ),
          ),
        );
      }),
    );
  }

  Widget _buildProfileCard(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(20),
      child: Row(
        children: [
          CircleAvatar(
            radius: 40,
            backgroundColor: AppThemeData.primary200.withOpacity(0.1),
            child: Icon(Icons.person, size: 40, color: AppThemeData.primary200),
          ),
          const SizedBox(width: 20),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "Firoz Mohammad",
                style: TextStyle(
                    color: isDark ? Colors.white : Colors.black87,
                    fontSize: 20,
                    fontFamily: AppThemeData.bold),
              ),
              const SizedBox(height: 4),
              Text(
                "firoz@example.com",
                style: TextStyle(color: Colors.grey[400], fontSize: 14),
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                  color: AppThemeData.primary200,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Text("Edit Profile", style: TextStyle(color: Colors.white, fontSize: 12)),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatsRow(bool isDark, MarketplaceController controller) {
    final activeCount = controller.myProducts.where((p) => p['status'] == 'active').length;
    final pendingCount = controller.myProducts.where((p) => p['status'] == 'pending_verification').length;
    final soldCount = controller.myProducts.where((p) => p['status'] == 'sold').length;

    return Padding(
      padding: const EdgeInsets.all(20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _statItem(activeCount.toString(), "Active", isDark),
          _statItem(pendingCount.toString(), "Pending", isDark),
          _statItem(soldCount.toString(), "Sold", isDark),
        ],
      ),
    );
  }

  Widget _statItem(String value, String label, bool isDark) {
    return Column(
      children: [
        Text(value, style: TextStyle(color: isDark ? Colors.white : Colors.black, fontSize: 18, fontFamily: AppThemeData.bold)),
        Text(label, style: TextStyle(color: Colors.grey[400], fontSize: 12)),
      ],
    );
  }

  Widget _buildListingsSection(bool isDark, MarketplaceController controller) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("My Listings", style: TextStyle(color: isDark ? Colors.white : Colors.black, fontSize: 18, fontFamily: AppThemeData.bold)),
          const SizedBox(height: 16),
          if (controller.myProducts.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 20),
              child: Center(
                child: Text(
                  "No product listings yet",
                  style: TextStyle(color: Colors.grey[400], fontSize: 14),
                ),
              ),
            )
          else
            ...controller.myProducts.map((prod) {
              return _listingItem(
                prod['title'] ?? '',
                prod['price'] ?? '',
                prod['status'] ?? 'pending_verification',
                prod['image'] ?? '',
                prod['progress'] ?? 0,
                isDark,
              );
            }).toList(),
        ],
      ),
    );
  }

  Widget _listingItem(String title, String price, String status, String imagePath, int progress, bool isDark) {
    String displayStatus = status;
    Color statusColor = Colors.grey;
    if (status == 'active') {
      displayStatus = "Active";
      statusColor = AppThemeData.success300;
    } else if (status == 'pending_verification') {
      displayStatus = "Verifying ($progress%)";
      statusColor = Colors.orange;
    } else if (status == 'rejected') {
      displayStatus = "Rejected";
      statusColor = Colors.red;
    } else if (status == 'sold') {
      displayStatus = "Sold";
      statusColor = Colors.grey;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark ? AppThemeData.grey800 : Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10)],
      ),
      child: Row(
        children: [
          Container(
            height: 50,
            width: 50,
            decoration: BoxDecoration(color: Colors.grey[200], borderRadius: BorderRadius.circular(10)),
            child: imagePath.isNotEmpty
                ? ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: Image.network(imagePath, fit: BoxFit.cover),
                  )
                : Icon(Icons.image, color: Colors.grey[400]),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: TextStyle(color: isDark ? Colors.white : Colors.black, fontFamily: AppThemeData.bold)),
                Text(price, style: TextStyle(color: AppThemeData.primary200, fontSize: 13)),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: statusColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              displayStatus,
              style: TextStyle(color: statusColor, fontSize: 10, fontFamily: AppThemeData.bold),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSavedSection(bool isDark) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("Saved Products", style: TextStyle(color: isDark ? Colors.white : Colors.black, fontSize: 18, fontFamily: AppThemeData.bold)),
          const SizedBox(height: 16),
          const Text("You have 5 saved items.", style: TextStyle(color: Colors.grey, fontSize: 13)),
        ],
      ),
    );
  }

  Widget _buildOrdersButton(BuildContext context, bool isDark) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: GestureDetector(
        onTap: () => Get.to(() => const MarketplaceOrdersScreen()),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          decoration: BoxDecoration(
            color: isDark ? AppThemeData.grey800 : Colors.white,
            borderRadius: BorderRadius.circular(15),
            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10)],
          ),
          child: Row(
            children: [
              Icon(Icons.receipt_long, color: AppThemeData.primary200),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Marketplace Orders",
                      style: TextStyle(
                        color: isDark ? Colors.white : Colors.black87,
                        fontSize: 15,
                        fontFamily: AppThemeData.bold,
                      ),
                    ),
                    const SizedBox(height: 2),
                    const Text(
                      "Track your purchases & incoming orders",
                      style: TextStyle(color: Colors.grey, fontSize: 12),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
            ],
          ),
        ),
      ),
    );
  }
}
