import 'package:finway/themes/constant_colors.dart';
import 'package:finway/utils/dark_theme_provider.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:provider/provider.dart';

class MarketplaceProfileScreen extends StatelessWidget {
  const MarketplaceProfileScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final themeChange = Provider.of<DarkThemeProvider>(context);
    final isDark = themeChange.getThem();

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
      body: SingleChildScrollView(
        child: Column(
          children: [
            _buildProfileCard(isDark),
            _buildStatsRow(isDark),
            _buildListingsSection(isDark),
            _buildSavedSection(isDark),
          ],
        ),
      ),
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

  Widget _buildStatsRow(bool isDark) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _statItem("12", "Active", isDark),
          _statItem("45", "Sold", isDark),
          _statItem("128", "Saved", isDark),
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

  Widget _buildListingsSection(bool isDark) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("My Listings", style: TextStyle(color: isDark ? Colors.white : Colors.black, fontSize: 18, fontFamily: AppThemeData.bold)),
          const SizedBox(height: 16),
          _listingItem("Tesla Model S", "\$68,000", "Active", isDark),
          _listingItem("Gaming Laptop", "\$1,200", "Sold", isDark),
        ],
      ),
    );
  }

  Widget _listingItem(String title, String price, String status, bool isDark) {
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
            child: Icon(Icons.image, color: Colors.grey[400]),
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
              color: status == "Active" ? AppThemeData.success300.withOpacity(0.1) : Colors.grey.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(status, style: TextStyle(color: status == "Active" ? AppThemeData.success300 : Colors.grey, fontSize: 10, fontFamily: AppThemeData.bold)),
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
}
