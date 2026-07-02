import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:provider/provider.dart';
import 'package:finway/constant/constant.dart';
import 'package:finway/controller/searching_driver_controller.dart';
import 'package:finway/themes/constant_colors.dart';
import 'package:finway/utils/dark_theme_provider.dart';
import 'package:finway/page/MainDashBoard/screen/main_dashboard.dart';



class SearchingDriverScreen extends StatefulWidget {
  const SearchingDriverScreen({super.key});

  @override
  State<SearchingDriverScreen> createState() => _SearchingDriverScreenState();
}

class _SearchingDriverScreenState extends State<SearchingDriverScreen> with TickerProviderStateMixin {
  late AnimationController _pulseController;
  late AnimationController _carController;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat();

    _carController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat();
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _carController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final themeChange = Provider.of<DarkThemeProvider>(context);
    final bool isDarkMode = themeChange.getThem();

    return GetBuilder<SearchingDriverController>(
      init: SearchingDriverController(),
      builder: (controller) {
        return Scaffold(
          backgroundColor: isDarkMode ? AppThemeData.surface50Dark : AppThemeData.surface50,
          body: SafeArea(
            child: Obx(() {
              if (controller.statut.value == "driver_rejected") {
                return _buildNoDriverState(context, controller, isDarkMode);
              }
              if (controller.statut.value == "confirmed") {
                return _buildSuccessState(context, controller, isDarkMode);
              }
              return _buildSearchingState(context, controller, isDarkMode);
            }),
          ),
        );
      },
    );
  }

  Widget _buildSearchingState(BuildContext context, SearchingDriverController controller, bool isDarkMode) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 20),
          // Dynamic visual header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Requesting Ride".tr,
                    style: TextStyle(
                      fontFamily: AppThemeData.semiBold,
                      fontSize: 26,
                      letterSpacing: -0.5,
                      color: isDarkMode ? Colors.white : AppThemeData.grey900,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    controller.statusText.value.tr,
                    style: TextStyle(
                      fontFamily: AppThemeData.medium,
                      fontSize: 14,
                      color: AppThemeData.primary200,
                    ),
                  ),
                ],
              ),
              // Beautiful circular progress with countdown inside
              Stack(
                alignment: Alignment.center,
                children: [
                  SizedBox(
                    width: 54,
                    height: 54,
                    child: CircularProgressIndicator(
                      value: controller.remainingSeconds.value / 60,
                      strokeWidth: 3.5,
                      backgroundColor: isDarkMode ? AppThemeData.grey300Dark : AppThemeData.grey300,
                      valueColor: AlwaysStoppedAnimation<Color>(AppThemeData.primary200),
                    ),
                  ),
                  Text(
                    "${controller.remainingSeconds.value}s",
                    style: TextStyle(
                      fontFamily: AppThemeData.bold,
                      fontSize: 13,
                      color: isDarkMode ? Colors.white : AppThemeData.grey900,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const Spacer(),
          // Central radar search visualization
          Center(
            child: Stack(
              alignment: Alignment.center,
              children: [
                ...List.generate(3, (index) {
                  return AnimatedBuilder(
                    animation: _pulseController,
                    builder: (context, child) {
                      double progress = (_pulseController.value + index / 3) % 1.0;
                      double size = 120 + (progress * 180);
                      double opacity = 1.0 - progress;
                      return Container(
                        width: size,
                        height: size,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: AppThemeData.primary200.withValues(alpha: opacity * 0.15),
                        ),
                      );
                    },
                  );
                }),
                // Pulsing central hub
                Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: isDarkMode ? AppThemeData.grey800 : Colors.white,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.08),
                        blurRadius: 20,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                  child: Center(
                    child: AnimatedBuilder(
                      animation: _carController,
                      builder: (context, child) {
                        return Transform.rotate(
                          angle: _carController.value * 2 * math.pi,
                          child: Icon(
                            Icons.directions_car_filled_outlined,
                            size: 40,
                            color: AppThemeData.primary200,
                          ),
                        );
                      },
                    ),
                  ),
                ),
              ],
            ),
          ),
          const Spacer(),
          // Ride summary card
          if (controller.rideData.value != null)
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                color: isDarkMode ? AppThemeData.grey800 : AppThemeData.grey200.withValues(alpha: 0.4),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.my_location, size: 16, color: AppThemeData.primary200),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          controller.rideData.value!.departName ?? "Pickup Location",
                          style: TextStyle(
                            fontFamily: AppThemeData.medium,
                            fontSize: 14,
                            color: isDarkMode ? Colors.white70 : AppThemeData.grey800,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  Padding(
                    padding: const EdgeInsets.only(left: 7.0, top: 4.0, bottom: 4.0),
                    child: Container(
                      width: 2,
                      height: 20,
                      color: isDarkMode ? AppThemeData.grey300Dark : AppThemeData.grey300,
                    ),
                  ),
                  Row(
                    children: [
                      Icon(Icons.location_on, size: 16, color: AppThemeData.secondary200),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          controller.rideData.value!.destinationName ?? "Destination Location",
                          style: TextStyle(
                            fontFamily: AppThemeData.medium,
                            fontSize: 14,
                            color: isDarkMode ? Colors.white70 : AppThemeData.grey800,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const Divider(height: 24, thickness: 1),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        "Estimated Fare".tr,
                        style: TextStyle(
                          fontFamily: AppThemeData.regular,
                          fontSize: 14,
                          color: isDarkMode ? Colors.white60 : AppThemeData.grey500,
                        ),
                      ),
                      Text(
                        Constant().amountShow(amount: controller.rideData.value!.montant ?? "0.0"),
                        style: TextStyle(
                          fontFamily: AppThemeData.bold,
                          fontSize: 18,
                          color: isDarkMode ? Colors.white : AppThemeData.grey900,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          const SizedBox(height: 24),
          // Cancel Search Button
          TextButton(
            onPressed: () async {
              bool success = await controller.cancelSearch();
              if (success) {
                Get.offAll(() => const MainDashboard());
              }
            },
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: BorderSide(
                  color: isDarkMode ? AppThemeData.grey300Dark : AppThemeData.grey300,
                  width: 1,
                ),
              ),
            ),
            child: Text(
              "Cancel Request".tr,
              style: TextStyle(
                fontFamily: AppThemeData.semiBold,
                fontSize: 15,
                color: isDarkMode ? Colors.white70 : AppThemeData.grey800,
              ),
            ),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _buildNoDriverState(BuildContext context, SearchingDriverController controller, bool isDarkMode) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Spacer(),
          Center(
            child: Container(
              width: 140,
              height: 140,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppThemeData.secondary200.withValues(alpha: 0.12),
              ),
              child: Icon(
                Icons.person_search_outlined,
                size: 70,
                color: AppThemeData.secondary200,
              ),
            ),
          ),
          const SizedBox(height: 40),
          Text(
            "Captains are Busy".tr,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: AppThemeData.bold,
              fontSize: 24,
              color: isDarkMode ? Colors.white : AppThemeData.grey900,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            "All nearby drivers are currently completed or rejected their requests. Would you like to try searching again?".tr,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: AppThemeData.regular,
              fontSize: 14,
              height: 1.5,
              color: isDarkMode ? Colors.white70 : AppThemeData.grey500,
            ),
          ),
          const Spacer(),
          // Retry button
          ElevatedButton(
            onPressed: () => controller.retryDispatch(),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppThemeData.primary200,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              elevation: 0,
            ),
            child: Text(
              "Retry Search".tr,
              style: TextStyle(
                fontFamily: AppThemeData.semiBold,
                fontSize: 16,
              ),
            ),
          ),
          const SizedBox(height: 12),
          // Cancel button
          TextButton(
            onPressed: () {
              Get.offAll(() => const MainDashboard());
            },
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: BorderSide(
                  color: isDarkMode ? AppThemeData.grey300Dark : AppThemeData.grey300,
                ),
              ),
            ),
            child: Text(
              "Cancel Request".tr,
              style: TextStyle(
                fontFamily: AppThemeData.semiBold,
                fontSize: 15,
                color: isDarkMode ? Colors.white70 : AppThemeData.grey800,
              ),
            ),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _buildSuccessState(BuildContext context, SearchingDriverController controller, bool isDarkMode) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Center(
          child: Container(
            width: 140,
            height: 140,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.green.withValues(alpha: 0.12),
            ),
            child: const Icon(
              Icons.check_circle_outline_rounded,
              size: 80,
              color: Colors.green,
            ),
          ),
        ),
        const SizedBox(height: 32),
        Text(
          "Captain Found!".tr,
          style: TextStyle(
            fontFamily: AppThemeData.bold,
            fontSize: 24,
            color: isDarkMode ? Colors.white : AppThemeData.grey900,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          "Your request was accepted. Redirecting...".tr,
          style: TextStyle(
            fontFamily: AppThemeData.regular,
            fontSize: 14,
            color: isDarkMode ? Colors.white70 : AppThemeData.grey500,
          ),
        ),
      ],
    );
  }
}
