import 'package:finway/themes/constant_colors.dart';
import 'package:finway/utils/dark_theme_provider.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../controller/marketplace_controller.dart';

class MarketplaceOrdersScreen extends StatefulWidget {
  const MarketplaceOrdersScreen({super.key});

  @override
  State<MarketplaceOrdersScreen> createState() => _MarketplaceOrdersScreenState();
}

class _MarketplaceOrdersScreenState extends State<MarketplaceOrdersScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final MarketplaceController _controller = Get.find<MarketplaceController>();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _controller.fetchBuyerOrders();
    _controller.fetchSellerOrders();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final themeChange = Provider.of<DarkThemeProvider>(context);
    final isDark = themeChange.getThem();

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
          "Marketplace Orders",
          style: TextStyle(color: isDark ? Colors.white : Colors.black, fontFamily: AppThemeData.bold, fontSize: 18),
        ),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: AppThemeData.primary200,
          labelColor: AppThemeData.primary200,
          unselectedLabelColor: Colors.grey,
          labelStyle: const TextStyle(fontFamily: AppThemeData.bold, fontSize: 14),
          tabs: const [
            Tab(text: "My Purchases"),
            Tab(text: "Incoming Orders"),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildBuyerTab(isDark),
          _buildSellerTab(isDark),
        ],
      ),
    );
  }

  Widget _buildBuyerTab(bool isDark) {
    return Obx(() {
      if (_controller.isBuyerOrdersLoading.value) {
        return const Center(child: CircularProgressIndicator());
      }
      if (_controller.buyerOrders.isEmpty) {
        return _buildEmptyState(
          isDark,
          icon: Icons.receipt_long_outlined,
          title: "No purchases yet",
          subtitle: "You haven't bought anything from the marketplace yet.",
        );
      }
      return RefreshIndicator(
        onRefresh: () => _controller.fetchBuyerOrders(),
        child: ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: _controller.buyerOrders.length,
          itemBuilder: (context, index) {
            final order = _controller.buyerOrders[index];
            return _buildBuyerOrderCard(order, isDark);
          },
        ),
      );
    });
  }

  Widget _buildSellerTab(bool isDark) {
    return Obx(() {
      if (_controller.isSellerOrdersLoading.value) {
        return const Center(child: CircularProgressIndicator());
      }
      if (_controller.sellerOrders.isEmpty) {
        return _buildEmptyState(
          isDark,
          icon: Icons.storefront_outlined,
          title: "No incoming orders",
          subtitle: "You haven't received any orders for your listed products yet.",
        );
      }
      return RefreshIndicator(
        onRefresh: () => _controller.fetchSellerOrders(),
        child: ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: _controller.sellerOrders.length,
          itemBuilder: (context, index) {
            final order = _controller.sellerOrders[index];
            return _buildSellerOrderCard(order, isDark);
          },
        ),
      );
    });
  }

  Widget _buildEmptyState(bool isDark, {required IconData icon, required String title, required String subtitle}) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: AppThemeData.primary200.withValues(alpha: 0.05),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 64, color: AppThemeData.primary200),
            ),
            const SizedBox(height: 24),
            Text(
              title,
              style: TextStyle(color: isDark ? Colors.white : Colors.black, fontSize: 18, fontFamily: AppThemeData.bold),
            ),
            const SizedBox(height: 8),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.grey, fontSize: 14),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBuyerOrderCard(Map<String, dynamic> order, bool isDark) {
    final status = order['status'] ?? 'placed';
    final totalAmount = order['total_amount'] ?? '0.00';
    final address = order['delivery_address'] ?? 'N/A';
    final dateStr = order['created_at'] != null 
        ? DateFormat('dd MMM yyyy, hh:mm a').format(DateTime.parse(order['created_at'])) 
        : 'N/A';
    final items = order['items'] as List<dynamic>? ?? [];

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppThemeData.grey800 : Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 10)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "Order #${order['id']}",
                style: TextStyle(color: isDark ? Colors.white : Colors.black, fontFamily: AppThemeData.bold, fontSize: 15),
              ),
              _buildStatusBadge(status),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            dateStr,
            style: const TextStyle(color: Colors.grey, fontSize: 12),
          ),
          const Divider(height: 24),
          
          // Order Status Tracing Timeline
          _buildStatusTracker(status, isDark, order['delivery_days'], order['status_notes']),
          const Divider(height: 24),

          // Items list
          ...items.map((item) {
            final product = item['product'];
            if (product == null) return const SizedBox();
            final title = product['title'] ?? 'Product';
            final price = item['price'] ?? '0';
            final qty = item['quantity'] ?? 1;
            final images = product['images'] as List<dynamic>? ?? [];
            final imageUrl = images.isNotEmpty ? images[0]['image_path'] : '';

            return Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Row(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: Container(
                      height: 45,
                      width: 45,
                      color: Colors.grey[200],
                      child: imageUrl.isNotEmpty
                          ? Image.network(imageUrl, fit: BoxFit.cover)
                          : const Icon(Icons.image, color: Colors.grey),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(color: isDark ? Colors.white : Colors.black87, fontFamily: AppThemeData.bold, fontSize: 13),
                        ),
                        Text(
                          "Quantity: $qty",
                          style: const TextStyle(color: Colors.grey, fontSize: 11),
                        ),
                      ],
                    ),
                  ),
                  Text(
                    "$price",
                    style: TextStyle(color: AppThemeData.primary200, fontFamily: AppThemeData.bold, fontSize: 13),
                  ),
                ],
              ),
            );
          }),
          
          const Divider(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text("Total Paid", style: TextStyle(color: Colors.grey, fontSize: 13)),
              Text(
                "$totalAmount",
                style: TextStyle(color: AppThemeData.primary200, fontFamily: AppThemeData.bold, fontSize: 16),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            "Deliver to: $address",
            style: TextStyle(color: isDark ? Colors.white70 : Colors.black54, fontSize: 12),
          ),
        ],
      ),
    );
  }

  Widget _buildSellerOrderCard(Map<String, dynamic> order, bool isDark) {
    final status = order['status'] ?? 'placed';
    final totalAmount = order['total_amount'] ?? '0.00';
    final address = order['delivery_address'] ?? 'N/A';
    final phone = order['phone'] ?? 'N/A';
    final buyer = order['buyer'];
    final buyerName = buyer != null ? "${buyer['prenom']} ${buyer['nom']}" : 'Buyer';
    final dateStr = order['created_at'] != null 
        ? DateFormat('dd MMM yyyy, hh:mm a').format(DateTime.parse(order['created_at'])) 
        : 'N/A';
    final items = order['items'] as List<dynamic>? ?? [];

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppThemeData.grey800 : Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 10)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "Order #${order['id']}",
                style: TextStyle(color: isDark ? Colors.white : Colors.black, fontFamily: AppThemeData.bold, fontSize: 15),
              ),
              _buildStatusBadge(status),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            dateStr,
            style: const TextStyle(color: Colors.grey, fontSize: 12),
          ),
          const Divider(height: 24),
          
          // Items list for this seller
          ...items.map((item) {
            final product = item['product'];
            if (product == null) return const SizedBox();
            final title = product['title'] ?? 'Product';
            final price = item['price'] ?? '0';
            final qty = item['quantity'] ?? 1;
            final images = product['images'] as List<dynamic>? ?? [];
            final imageUrl = images.isNotEmpty ? images[0]['image_path'] : '';

            return Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Row(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: Container(
                      height: 45,
                      width: 45,
                      color: Colors.grey[200],
                      child: imageUrl.isNotEmpty
                          ? Image.network(imageUrl, fit: BoxFit.cover)
                          : const Icon(Icons.image, color: Colors.grey),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(color: isDark ? Colors.white : Colors.black87, fontFamily: AppThemeData.bold, fontSize: 13),
                        ),
                        Text(
                          "Quantity: $qty",
                          style: const TextStyle(color: Colors.grey, fontSize: 11),
                        ),
                      ],
                    ),
                  ),
                  Text(
                    "$price",
                    style: TextStyle(color: AppThemeData.primary200, fontFamily: AppThemeData.bold, fontSize: 13),
                  ),
                ],
              ),
            );
          }),
          
          const Divider(height: 16),
          Text(
            "Customer Details:",
            style: TextStyle(color: isDark ? Colors.white : Colors.black, fontFamily: AppThemeData.bold, fontSize: 12),
          ),
          const SizedBox(height: 4),
          Text("Name: $buyerName", style: const TextStyle(color: Colors.grey, fontSize: 12)),
          Text("Phone: $phone", style: const TextStyle(color: Colors.grey, fontSize: 12)),
          Text("Address: $address", style: const TextStyle(color: Colors.grey, fontSize: 12)),

          if (order['delivery_days'] != null || order['status_notes'] != null) ...[
            const SizedBox(height: 8),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: isDark ? Colors.black26 : Colors.grey[100],
                borderRadius: BorderRadius.circular(10),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (order['delivery_days'] != null)
                    Text("Delivery timeline: ${order['delivery_days']} days", style: TextStyle(color: isDark ? Colors.white70 : Colors.black87, fontSize: 11, fontFamily: AppThemeData.bold)),
                  if (order['status_notes'] != null)
                    Text("Note: ${order['status_notes']}", style: TextStyle(color: Colors.grey[500], fontSize: 11)),
                ],
              ),
            ),
          ],
          
          const Divider(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              ElevatedButton(
                onPressed: (status == 'delivered' || status == 'cancelled')
                    ? null
                    : () => _showUpdateStatusBottomSheet(order['id'].toString(), status, isDark),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppThemeData.primary200,
                  elevation: 0,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                ),
                child: const Text("Update Status", style: TextStyle(color: Colors.white, fontSize: 12, fontFamily: AppThemeData.bold)),
              ),
              Text(
                "Earnings: $totalAmount",
                style: TextStyle(color: AppThemeData.success300, fontFamily: AppThemeData.bold, fontSize: 14),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatusBadge(String status) {
    String label = status;
    Color color = Colors.grey;
    if (status == 'placed') {
      label = 'Placed';
      color = Colors.blue;
    } else if (status == 'dispatched') {
      label = 'Dispatched';
      color = Colors.orange;
    } else if (status == 'out_for_delivery') {
      label = 'Out for Delivery';
      color = Colors.purple;
    } else if (status == 'delivered') {
      label = 'Delivered';
      color = Colors.green;
    } else if (status == 'cancelled') {
      label = 'Cancelled';
      color = Colors.red;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        label,
        style: TextStyle(color: color, fontSize: 11, fontFamily: AppThemeData.bold),
      ),
    );
  }

  Widget _buildStatusTracker(String currentStatus, bool isDark, int? deliveryDays, String? notes) {
    if (currentStatus == 'cancelled') {
      return Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.red.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            const Icon(Icons.cancel_outlined, color: Colors.red),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                "This order was cancelled.${notes != null ? ' Reason: $notes' : ''}",
                style: const TextStyle(color: Colors.red, fontSize: 12),
              ),
            ),
          ],
        ),
      );
    }

    final statuses = ['placed', 'dispatched', 'out_for_delivery', 'delivered'];
    final currentIndex = statuses.indexOf(currentStatus);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: List.generate(4, (index) {
            final stepStatus = statuses[index];
            final stepLabel = _getStatusLabel(stepStatus);
            final isCompleted = index <= currentIndex;
            final isActive = index == currentIndex;

            return Expanded(
              child: Column(
                children: [
                  Row(
                    children: [
                      // line before dot
                      Expanded(
                        child: Container(
                          height: 3,
                          color: index == 0
                              ? Colors.transparent
                              : (isCompleted ? AppThemeData.primary200 : Colors.grey[300]),
                        ),
                      ),
                      // Dot
                      Container(
                        width: 24,
                        height: 24,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: isCompleted ? AppThemeData.primary200 : (isDark ? Colors.grey[800] : Colors.grey[200]),
                          border: Border.all(
                            color: isActive ? AppThemeData.primary200 : Colors.transparent,
                            width: 3,
                          ),
                        ),
                        child: Icon(
                          isCompleted ? Icons.check : Icons.circle,
                          size: isCompleted ? 12 : 8,
                          color: isCompleted ? Colors.white : Colors.grey[400],
                        ),
                      ),
                      // line after dot
                      Expanded(
                        child: Container(
                          height: 3,
                          color: index == 3
                              ? Colors.transparent
                              : (index < currentIndex ? AppThemeData.primary200 : Colors.grey[300]),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    stepLabel,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 10,
                      fontFamily: isActive ? AppThemeData.bold : AppThemeData.medium,
                      color: isActive 
                          ? AppThemeData.primary200 
                          : (isCompleted 
                              ? (isDark ? Colors.white70 : Colors.black87) 
                              : Colors.grey),
                    ),
                  ),
                ],
              ),
            );
          }),
        ),
        if (deliveryDays != null || notes != null) ...[
          const SizedBox(height: 16),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: isDark ? Colors.black26 : Colors.grey[100],
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (deliveryDays != null && currentStatus != 'delivered')
                  Text(
                    "Expected delivery in $deliveryDays days",
                    style: TextStyle(color: isDark ? Colors.white70 : Colors.black87, fontSize: 12, fontFamily: AppThemeData.bold),
                  ),
                if (notes != null && notes.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 4.0),
                    child: Text(
                      "Update from seller: $notes",
                      style: const TextStyle(color: Colors.grey, fontSize: 11),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  String _getStatusLabel(String status) {
    switch (status) {
      case 'placed':
        return 'Placed';
      case 'dispatched':
        return 'Dispatched';
      case 'out_for_delivery':
        return 'Out for Delivery';
      case 'delivered':
        return 'Delivered';
      default:
        return '';
    }
  }

  void _showUpdateStatusBottomSheet(String orderId, String currentStatus, bool isDark) {
    String selectedStatus = currentStatus;
    final daysController = TextEditingController();
    final notesController = TextEditingController();

    Get.bottomSheet(
      StatefulBuilder(
        builder: (context, setState) {
          return Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: isDark ? AppThemeData.grey900 : Colors.white,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
            ),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        "Update Order State",
                        style: TextStyle(fontSize: 18, fontFamily: AppThemeData.bold, color: isDark ? Colors.white : Colors.black),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () => Get.back(),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  Text("Select Status", style: TextStyle(fontSize: 13, fontFamily: AppThemeData.bold, color: Colors.grey[500])),
                  const SizedBox(height: 8),
                  
                  // Status selection dropdown or segments
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                      color: isDark ? Colors.black26 : Colors.grey[100],
                      borderRadius: BorderRadius.circular(15),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: selectedStatus,
                        dropdownColor: isDark ? AppThemeData.grey900 : Colors.white,
                        isExpanded: true,
                        icon: const Icon(Icons.keyboard_arrow_down),
                        items: const [
                          DropdownMenuItem(value: 'placed', child: Text("Placed")),
                          DropdownMenuItem(value: 'dispatched', child: Text("Dispatched")),
                          DropdownMenuItem(value: 'out_for_delivery', child: Text("Out for Delivery")),
                          DropdownMenuItem(value: 'delivered', child: Text("Delivered")),
                          DropdownMenuItem(value: 'cancelled', child: Text("Cancelled")),
                        ],
                        onChanged: (val) {
                          if (val != null) {
                            setState(() {
                              selectedStatus = val;
                            });
                          }
                        },
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  
                  if (selectedStatus != 'delivered' && selectedStatus != 'cancelled') ...[
                    Text("Delivery in (Days) - Optional", style: TextStyle(fontSize: 13, fontFamily: AppThemeData.bold, color: Colors.grey[500])),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: daysController,
                      keyboardType: TextInputType.number,
                      style: TextStyle(color: isDark ? Colors.white : Colors.black),
                      decoration: InputDecoration(
                        hintText: "e.g., 3",
                        hintStyle: const TextStyle(color: Colors.grey),
                        filled: true,
                        fillColor: isDark ? Colors.black12 : Colors.grey[100],
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: BorderSide.none),
                      ),
                    ),
                    const SizedBox(height: 20),
                  ],
                  
                  Text("Notes / Message - Optional", style: TextStyle(fontSize: 13, fontFamily: AppThemeData.bold, color: Colors.grey[500])),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: notesController,
                    maxLines: 2,
                    style: TextStyle(color: isDark ? Colors.white : Colors.black),
                    decoration: InputDecoration(
                      hintText: "Add tracking number or courier message...",
                      hintStyle: const TextStyle(color: Colors.grey),
                      filled: true,
                      fillColor: isDark ? Colors.black12 : Colors.grey[100],
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: BorderSide.none),
                    ),
                  ),
                  const SizedBox(height: 30),
                  
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () async {
                        Get.back(); // close bottom sheet
                        int? days = int.tryParse(daysController.text);
                        String? notes = notesController.text.trim().isNotEmpty ? notesController.text.trim() : null;
                        
                        bool success = await _controller.updateOrderStatus(
                          orderId, 
                          selectedStatus, 
                          deliveryDays: days, 
                          notes: notes
                        );
                        if (success) {
                          Get.snackbar(
                            "Success", 
                            "Order status updated successfully",
                            backgroundColor: Colors.green,
                            colorText: Colors.white,
                            snackPosition: SnackPosition.BOTTOM
                          );
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppThemeData.primary200,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                      ),
                      child: const Text("SAVE STATUS", style: TextStyle(color: Colors.white, fontFamily: AppThemeData.bold)),
                    ),
                  ),
                  const SizedBox(height: 10),
                ],
              ),
            ),
          );
        }
      ),
      isScrollControlled: true,
    );
  }
}
