import 'dart:ui';
import 'package:finway/themes/constant_colors.dart';
import 'package:finway/utils/dark_theme_provider.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:provider/provider.dart';
import '../controller/marketplace_controller.dart';

class MarketplaceCartScreen extends StatelessWidget {
  const MarketplaceCartScreen({super.key});

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
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new, color: isDark ? Colors.white : Colors.black, size: 20),
          onPressed: () => Get.back(),
        ),
        centerTitle: true,
        title: Text(
          "Shopping Cart",
          style: TextStyle(color: isDark ? Colors.white : Colors.black, fontFamily: AppThemeData.bold, fontSize: 20),
        ),
      ),
      body: Obx(() => controller.cartItems.isEmpty ? _buildEmptyCart(context, isDark) : _buildCartContent(context, isDark, controller)),
    );
  }

  Widget _buildEmptyCart(BuildContext context, bool isDark) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(40),
            decoration: BoxDecoration(color: AppThemeData.primary200.withValues(alpha: 0.05), shape: BoxShape.circle),
            child: Icon(Icons.shopping_bag_outlined, size: 100, color: AppThemeData.primary200),
          ),
          const SizedBox(height: 32),
          Text(
            "Your cart is solitary",
            style: TextStyle(color: isDark ? Colors.white : Colors.black, fontSize: 22, fontFamily: AppThemeData.bold),
          ),
          const SizedBox(height: 12),
          Text(
            "Looks like you haven't added\nanything to your cart yet.",
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey, fontSize: 16, fontFamily: AppThemeData.medium),
          ),
          const SizedBox(height: 48),
          ElevatedButton(
            onPressed: () => Get.back(),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppThemeData.primary200,
              padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 18),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              elevation: 0,
            ),
            child: const Text("Start Exploring", style: TextStyle(color: Colors.white, fontFamily: AppThemeData.bold, fontSize: 16)),
          ),
        ],
      ),
    );
  }

  Widget _buildCartContent(BuildContext context, bool isDark, MarketplaceController controller) {
    return Stack(
      children: [
        ListView.builder(
          padding: const EdgeInsets.fromLTRB(20, 10, 20, 320),
          itemCount: controller.cartItems.length,
          itemBuilder: (context, index) {
            final item = controller.cartItems[index];
            return _buildCartItem(item, isDark, controller);
          },
        ),
        Positioned(
          bottom: 0,
          left: 0,
          right: 0,
          child: _buildCheckoutSummary(context, isDark, controller),
        ),
      ],
    );
  }

  Widget _buildCartItem(Map<String, dynamic> item, bool isDark, MarketplaceController controller) {
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: isDark ? AppThemeData.grey800 : Colors.white,
        borderRadius: BorderRadius.circular(25),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 20, offset: const Offset(0, 10))],
      ),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(15),
            child: Image.network(
              item['image'],
              height: 80,
              width: 80,
              fit: BoxFit.cover,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item['title'],
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(color: isDark ? Colors.white : Colors.black, fontFamily: AppThemeData.bold, fontSize: 14),
                ),
                const SizedBox(height: 2),
                Text(
                  item['mainCategory'] ?? "Product",
                  style: TextStyle(color: Colors.grey[400], fontSize: 11, fontFamily: AppThemeData.medium),
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      item['price'],
                      style: TextStyle(color: AppThemeData.primary200, fontFamily: AppThemeData.bold, fontSize: 15),
                    ),
                    _buildQtyButtons(isDark, item, controller),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          IconButton(
            icon: CircleAvatar(
              radius: 15,
              backgroundColor: Colors.redAccent.withValues(alpha: 0.1),
              child: const Icon(Icons.close_rounded, color: Colors.redAccent, size: 16),
            ),
            onPressed: () => controller.removeFromCart(item['id']),
          ),
        ],
      ),
    );
  }

  Widget _buildQtyButtons(bool isDark, Map<String, dynamic> item, MarketplaceController controller) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: isDark ? Colors.black26 : Colors.grey[100],
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => controller.updateQuantity(item['id'], -1),
            child: Icon(Icons.remove, size: 16, color: isDark ? Colors.white38 : Colors.grey)
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Text("${item['quantity'] ?? 1}", style: TextStyle(color: isDark ? Colors.white : Colors.black, fontFamily: AppThemeData.bold, fontSize: 14)),
          ),
          GestureDetector(
            onTap: () => controller.updateQuantity(item['id'], 1),
            child: Icon(Icons.add, size: 16, color: AppThemeData.primary200)
          ),
        ],
      ),
    );
  }

  Widget _buildCheckoutSummary(BuildContext context, bool isDark, MarketplaceController controller) {
    return ClipRRect(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(40)),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
        child: Container(
          padding: const EdgeInsets.fromLTRB(30, 30, 30, 40),
          decoration: BoxDecoration(
            color: (isDark ? AppThemeData.grey800 : Colors.white).withValues(alpha: 0.85),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(40)),
            border: Border.all(color: isDark ? Colors.white10 : Colors.black.withValues(alpha: 0.05)),
          ),
          child: SafeArea(
            bottom: true,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _summaryRow("Subtotal", "₹${controller.cartSubtotal.toStringAsFixed(2)}", isDark),
                const SizedBox(height: 10),
                _summaryRow("Delivery Charge", "Free", isDark, isGreen: true),
                const SizedBox(height: 10),
                _summaryRow("Payment Method", "Fiinway Wallet", isDark),
                const SizedBox(height: 18),
                const Divider(),
                const SizedBox(height: 18),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text("Total Amount", style: TextStyle(color: isDark ? Colors.white : Colors.black, fontSize: 15, fontFamily: AppThemeData.bold)),
                    Text(
                      "₹${controller.cartSubtotal.toStringAsFixed(2)}",
                      style: TextStyle(color: AppThemeData.primary200, fontSize: 22, fontFamily: AppThemeData.bold),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(22),
                      gradient: LinearGradient(colors: [AppThemeData.primary200, AppThemeData.primary200.withValues(alpha: 0.8)]),
                      boxShadow: [BoxShadow(color: AppThemeData.primary200.withValues(alpha: 0.4), blurRadius: 15, offset: const Offset(0, 8))],
                    ),
                    child: ElevatedButton(
                      onPressed: () => _showDeliveryDetailsBottomSheet(context, isDark, controller),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.transparent,
                        shadowColor: Colors.transparent,
                        padding: const EdgeInsets.symmetric(vertical: 15),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
                      ),
                      child: const Text("PAY NOW & PLACE ORDER", style: TextStyle(color: Colors.white, fontFamily: AppThemeData.bold, fontSize: 14, letterSpacing: 0.5)),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showDeliveryDetailsBottomSheet(BuildContext context, bool isDark, MarketplaceController controller) {
    final addressController = TextEditingController();
    final phoneController = TextEditingController();
    final formKey = GlobalKey<FormState>();

    Get.bottomSheet(
      Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: isDark ? AppThemeData.grey900 : Colors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
        ),
        child: SingleChildScrollView(
          child: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      "Delivery Details",
                      style: TextStyle(
                        fontSize: 20,
                        fontFamily: AppThemeData.bold,
                        color: isDark ? Colors.white : Colors.black,
                      ),
                    ),
                    IconButton(
                      icon: Icon(Icons.close, color: isDark ? Colors.white : Colors.black),
                      onPressed: () => Get.back(),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                Text(
                  "Delivery Address",
                  style: TextStyle(
                    fontSize: 14,
                    fontFamily: AppThemeData.bold,
                    color: isDark ? Colors.white70 : Colors.black87,
                  ),
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: addressController,
                  maxLines: 3,
                  style: TextStyle(color: isDark ? Colors.white : Colors.black),
                  decoration: InputDecoration(
                    hintText: "Enter full delivery address...",
                    hintStyle: const TextStyle(color: Colors.grey),
                    filled: true,
                    fillColor: isDark ? Colors.black12 : Colors.grey[100],
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(15),
                      borderSide: BorderSide.none,
                    ),
                  ),
                  validator: (value) => value == null || value.isEmpty ? "Please enter address" : null,
                ),
                const SizedBox(height: 20),
                Text(
                  "Phone Number",
                  style: TextStyle(
                    fontSize: 14,
                    fontFamily: AppThemeData.bold,
                    color: isDark ? Colors.white70 : Colors.black87,
                  ),
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: phoneController,
                  keyboardType: TextInputType.phone,
                  style: TextStyle(color: isDark ? Colors.white : Colors.black),
                  decoration: InputDecoration(
                    hintText: "Enter contact number...",
                    hintStyle: const TextStyle(color: Colors.grey),
                    filled: true,
                    fillColor: isDark ? Colors.black12 : Colors.grey[100],
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(15),
                      borderSide: BorderSide.none,
                    ),
                  ),
                  validator: (value) => value == null || value.isEmpty ? "Please enter phone number" : null,
                ),
                const SizedBox(height: 30),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () async {
                      if (formKey.currentState!.validate()) {
                        Get.back(); // close bottom sheet
                        bool success = await controller.placeOrder(
                          address: addressController.text,
                          phone: phoneController.text,
                        );
                        if (success) {
                          _showSuccessDialog(context, isDark);
                        }
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppThemeData.primary200,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                    ),
                    child: const Text(
                      "CONFIRM & PLACE ORDER",
                      style: TextStyle(color: Colors.white, fontFamily: AppThemeData.bold),
                    ),
                  ),
                ),
                const SizedBox(height: 10),
              ],
            ),
          ),
        ),
      ),
      isScrollControlled: true,
    );
  }

  void _showSuccessDialog(BuildContext context, bool isDark) {
    Get.dialog(
      barrierDismissible: false,
      Center(
        child: Container(
          margin: const EdgeInsets.all(30),
          padding: const EdgeInsets.all(30),
          decoration: BoxDecoration(
            color: isDark ? AppThemeData.grey900 : Colors.white,
            borderRadius: BorderRadius.circular(30),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.check_circle_rounded, color: AppThemeData.primary200, size: 100),
              const SizedBox(height: 30),
              const Text("Payment Success!", style: TextStyle(fontSize: 22, fontFamily: AppThemeData.bold)),
              const SizedBox(height: 15),
              const Text("Your order has been placed successfully. You can track your order in the marketplace section.", textAlign: TextAlign.center, style: TextStyle(color: Colors.grey)),
              const SizedBox(height: 40),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    Get.back(); // Close dialog
                    Get.back(); // Go back to home
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppThemeData.primary200,
                    padding: const EdgeInsets.symmetric(vertical: 18),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                  ),
                  child: const Text("BACK TO HOME", style: TextStyle(color: Colors.white, fontFamily: AppThemeData.bold)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _summaryRow(String label, String value, bool isDark, {bool isGreen = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: TextStyle(color: isDark ? Colors.white60 : Colors.black54, fontSize: 13, fontFamily: AppThemeData.medium)),
        Text(value, style: TextStyle(color: isGreen ? Colors.green : (isDark ? Colors.white : Colors.black), fontSize: 13, fontFamily: AppThemeData.bold)),
      ],
    );
  }
}

