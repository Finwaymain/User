import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:provider/provider.dart';

import 'package:finway/page/completed_ride_screens/trip_history_screen.dart';
import 'package:finway/page/contact_us/contact_us_screen.dart';
import 'package:finway/page/parcel_service_screen/parcel_category_screen.dart';
import 'package:finway/themes/constant_colors.dart';
import 'package:finway/utils/dark_theme_provider.dart';
import 'transport_booking_screen.dart';

/// Landing/hub screen for the "Transport Pick & Drop" entry point — shown before
/// the actual booking form (TransportBookingScreen), matching the reference
/// "Logistics & Delivery" mockup screen.
class LogisticsDeliveryScreen extends StatelessWidget {
  const LogisticsDeliveryScreen({super.key});

  static const Color _accent = Color(0xFF2E7D32);

  static const List<Map<String, String>> _vehicles = [
    {'name': 'Mini Truck', 'capacity': 'Up to 500 kg'},
    {'name': 'Pickup', 'capacity': 'Up to 1 Ton'},
    {'name': 'Medium Truck', 'capacity': 'Up to 3 Ton'},
    {'name': 'Large Truck', 'capacity': '3 Ton & Above'},
  ];

  @override
  Widget build(BuildContext context) {
    final themeChange = Provider.of<DarkThemeProvider>(context);
    final bool isDarkMode = themeChange.getThem();

    return Scaffold(
      backgroundColor: isDarkMode ? AppThemeData.surface50Dark : const Color(0xFFF7F8FA),
      appBar: AppBar(
        backgroundColor: isDarkMode ? AppThemeData.surface50Dark : Colors.white,
        elevation: 0,
        iconTheme: IconThemeData(color: isDarkMode ? AppThemeData.grey900Dark : Colors.black),
        title: Text(
          "Logistics & Delivery".tr,
          style: TextStyle(
            fontFamily: AppThemeData.bold,
            fontSize: 18,
            color: isDarkMode ? AppThemeData.grey900Dark : Colors.black,
          ),
        ),
        actions: [
          IconButton(
            onPressed: () => Get.to(() => TripHistoryScreen()),
            icon: Icon(Icons.history_rounded, color: isDarkMode ? AppThemeData.grey900Dark : Colors.black),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeroBanner(isDarkMode),
            const SizedBox(height: 24),
            Text(
              "Transport Services".tr,
              style: TextStyle(
                fontFamily: AppThemeData.bold,
                fontSize: 16,
                color: isDarkMode ? AppThemeData.grey900Dark : AppThemeData.grey900,
              ),
            ),
            const SizedBox(height: 12),
            _buildVehicleRow(isDarkMode),
            const SizedBox(height: 16),
            _buildTrustBadges(isDarkMode),
            const SizedBox(height: 24),
            Text(
              "Parcel & Delivery".tr,
              style: TextStyle(
                fontFamily: AppThemeData.bold,
                fontSize: 16,
                color: isDarkMode ? AppThemeData.grey900Dark : AppThemeData.grey900,
              ),
            ),
            const SizedBox(height: 12),
            _buildParcelRow(isDarkMode),
            const SizedBox(height: 16),
            _buildInfoRow(isDarkMode, context),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildHeroBanner(bool isDarkMode) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: isDarkMode ? AppThemeData.grey100Dark : const Color(0xFFEFF8F0),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Stack(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "Logistics & Delivery".tr,
                style: const TextStyle(fontFamily: 'Switzer-Bold', fontSize: 19, color: _accent),
              ),
              const SizedBox(height: 8),
              Text(
                "Move goods, send parcels safely & on time".tr,
                style: TextStyle(
                  fontFamily: AppThemeData.regular,
                  fontSize: 13,
                  color: isDarkMode ? AppThemeData.grey500Dark : AppThemeData.grey500,
                ),
              ),
              const SizedBox(height: 24),
              Icon(Icons.local_shipping_rounded, size: 56, color: _accent.withValues(alpha: 0.85)),
            ],
          ),
          Positioned(
            top: 0,
            right: 0,
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: const BoxDecoration(shape: BoxShape.circle, color: _accent),
              child: const Icon(Icons.location_on, color: Colors.white, size: 18),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVehicleRow(bool isDarkMode) {
    return Row(
      children: _vehicles.asMap().entries.map((entry) {
        final index = entry.key;
        final v = entry.value;
        final isFirst = index == 0;
        return Expanded(
          child: Padding(
            padding: EdgeInsets.only(right: index == _vehicles.length - 1 ? 0 : 8),
            child: InkWell(
              borderRadius: BorderRadius.circular(12),
              onTap: () => Get.to(() => TransportBookingScreen(initialVehicleLibelle: v['name'])),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
                decoration: BoxDecoration(
                  color: isDarkMode ? AppThemeData.grey100Dark : Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: isFirst ? _accent : Colors.grey.withValues(alpha: 0.2), width: isFirst ? 1.5 : 1),
                ),
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Column(
                      children: [
                        Icon(Icons.local_shipping_outlined, size: 26, color: Colors.grey.shade700),
                        const SizedBox(height: 8),
                        Text(
                          v['name']!.tr,
                          textAlign: TextAlign.center,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontFamily: AppThemeData.semiBold,
                            fontSize: 11.5,
                            color: isDarkMode ? AppThemeData.grey900Dark : AppThemeData.grey900,
                          ),
                        ),
                        const SizedBox(height: 1),
                        Text(
                          v['capacity']!.tr,
                          textAlign: TextAlign.center,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontFamily: AppThemeData.regular,
                            fontSize: 9.5,
                            color: isDarkMode ? AppThemeData.grey500Dark : AppThemeData.grey500,
                          ),
                        ),
                      ],
                    ),
                    if (isFirst)
                      Positioned(
                        top: -4,
                        right: -4,
                        child: Container(
                          width: 16,
                          height: 16,
                          decoration: const BoxDecoration(shape: BoxShape.circle, color: _accent),
                          child: const Icon(Icons.check, size: 11, color: Colors.white),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildTrustBadges(bool isDarkMode) {
    Widget badge(String label) {
      return Expanded(
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 6),
          margin: const EdgeInsets.symmetric(horizontal: 3),
          decoration: BoxDecoration(
            color: const Color(0xFFEFF8F0),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.check_circle, color: _accent, size: 14),
              const SizedBox(width: 4),
              Flexible(
                child: Text(
                  label.tr,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontFamily: 'Switzer-Medium', fontSize: 10.5, color: _accent),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Row(
      children: [
        badge("Verified Partners"),
        badge("Safe & Secure"),
        badge("On-time Delivery"),
      ],
    );
  }

  Widget _buildParcelRow(bool isDarkMode) {
    Widget card(IconData icon, Color iconColor, String title, String subtitle) {
      return Expanded(
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () => Get.to(() => const ParcelCategoryScreen(), transition: Transition.rightToLeftWithFade),
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: isDarkMode ? AppThemeData.grey100Dark : Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey.withValues(alpha: 0.15)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(icon, color: iconColor, size: 26),
                const SizedBox(height: 10),
                Text(
                  title.tr,
                  style: TextStyle(fontFamily: AppThemeData.semiBold, fontSize: 12.5, color: isDarkMode ? AppThemeData.grey900Dark : AppThemeData.grey900),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle.tr,
                  style: TextStyle(fontFamily: AppThemeData.regular, fontSize: 10.5, color: isDarkMode ? AppThemeData.grey500Dark : AppThemeData.grey500),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Row(
      children: [
        card(Icons.inventory_2_rounded, const Color(0xFFE67E22), "Parcel Delivery", "Small & Medium"),
        const SizedBox(width: 12),
        card(Icons.mail_outline_rounded, const Color(0xFF5A6178), "Document Delivery", "Fast & Secure"),
      ],
    );
  }

  Widget _buildInfoRow(bool isDarkMode, BuildContext context) {
    Widget info(IconData icon, String title, String subtitle, VoidCallback? onTap) {
      return Expanded(
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFEFF8F0),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Icon(icon, color: _accent, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title.tr,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontFamily: 'Switzer-Semibold', fontSize: 11.5, color: _accent),
                      ),
                      Text(
                        subtitle.tr,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(fontFamily: AppThemeData.regular, fontSize: 9.5, color: _accent.withValues(alpha: 0.75)),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Row(
      children: [
        info(Icons.my_location_rounded, "Real-time Tracking", "Track your shipment live", null),
        const SizedBox(width: 12),
        info(Icons.headset_mic_rounded, "24/7 Support", "We're here to help", () => Get.to(() => const ContactUsScreen())),
      ],
    );
  }
}
