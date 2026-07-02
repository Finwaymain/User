import 'package:finway/constant/constant.dart';
import 'package:finway/controller/dash_board_controller.dart';
import 'package:finway/themes/constant_colors.dart';
import 'package:finway/themes/responsive.dart';
import 'package:finway/utils/dark_theme_provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:get/get.dart';
import 'package:provider/provider.dart';
import 'package:finway/utils/Preferences.dart';
import '../../../constant/image_constant.dart';
import 'texi_home_screens/texi_home_osm_screen.dart';
import 'texi_home_screens/texi_home_screen.dart';

import 'package:finway/page/parcel_service_screen/parcel_category_screen.dart';
import 'package:finway/page/auth_screens/phone_entry_screen.dart';
import 'package:finway/page/new_ride_screens/new_ride_screen.dart';

class TexiDashboard extends StatefulWidget {
  const TexiDashboard({super.key});

  @override
  State<TexiDashboard> createState() => _TexiDashboardState();
}

class _TexiDashboardState extends State<TexiDashboard> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  DateTime backPress = DateTime.now();

  void _onServiceTap(String serviceName, int tabIndex) {
    if (!Preferences.getBoolean(Preferences.isLogin)) {
      Get.to(() => const PhoneEntryScreen(), transition: Transition.rightToLeftWithFade);
      return;
    }

    if (serviceName == "Parcel & Delivery Support") {
      Get.to(() => const ParcelCategoryScreen(), transition: Transition.rightToLeftWithFade);
    } else {
      // Navigate to TexiHomeScreen or TexiHomeOSMScreen with chosen category
      if (Constant.selectedMapType == 'osm') {
        Get.to(() => TexiHomeOSMScreen(
          initialVehicleCategory: serviceName,
          initialTab: tabIndex,
        ), transition: Transition.rightToLeftWithFade);
      } else {
        Get.to(() => TexiHomeScreen(
          initialVehicleCategory: serviceName,
          initialTab: tabIndex,
        ), transition: Transition.rightToLeftWithFade);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeChange = Provider.of<DarkThemeProvider>(context);
    final bool isDarkMode = themeChange.getThem();

    return GetBuilder<DashBoardController>(
      init: DashBoardController(),
      builder: (controller) {
        controller.getDrawerItems();
        return Scaffold(
          key: _scaffoldKey,
          drawer: buildAppDrawer(context, controller),
          body: SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Premium Custom Header
                  Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.arrow_back, size: 24),
                        onPressed: () => Get.back(),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        "Fiinway Ride".tr,
                        style: TextStyle(
                          fontFamily: AppThemeData.bold,
                          fontSize: 20,
                          color: isDarkMode ? AppThemeData.grey900Dark : AppThemeData.grey900,
                        ),
                      ),
                      const Spacer(),
                      IconButton(
                        icon: const Icon(Icons.history, size: 24),
                        onPressed: () {
                          if (!Preferences.getBoolean(Preferences.isLogin)) {
                            Get.to(() => const PhoneEntryScreen(), transition: Transition.rightToLeftWithFade);
                            return;
                          }
                          Get.to(() => const NewRideScreen(), transition: Transition.rightToLeftWithFade);
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // Promotional Travel & Transport Banner Card
                  Container(
                    width: double.infinity,
                    height: 145,
                    decoration: BoxDecoration(
                      color: isDarkMode ? const Color(0xFF1E293B) : const Color(0xFFEAF5FC),
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(isDarkMode ? 0.2 : 0.04),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        )
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(20),
                      child: Stack(
                        children: [
                          // Background design circle
                          Positioned(
                            right: -20,
                            bottom: -20,
                            child: Container(
                              width: 170,
                              height: 170,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: Colors.white.withOpacity(isDarkMode ? 0.05 : 0.4),
                              ),
                            ),
                          ),
                          // Content Row
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                            child: Row(
                              children: [
                                Expanded(
                                  flex: 6,
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Text(
                                        "Travel & Transport".tr,
                                        style: const TextStyle(
                                          fontFamily: AppThemeData.bold,
                                          fontSize: 20,
                                          color: Color(0xFF2E7D32),
                                        ),
                                      ),
                                      const SizedBox(height: 6),
                                      Text(
                                        "Book rides, deliver parcels\nand more".tr,
                                        style: TextStyle(
                                          fontFamily: AppThemeData.medium,
                                          fontSize: 13,
                                          color: isDarkMode ? Colors.white70 : const Color(0xFF37474F),
                                          height: 1.3,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Expanded(
                                  flex: 4,
                                  child: Stack(
                                    alignment: Alignment.center,
                                    clipBehavior: Clip.none,
                                    children: [
                                      // Faint Road Line
                                      Positioned(
                                        bottom: 12,
                                        left: 0,
                                        right: 0,
                                        child: Container(
                                          height: 3,
                                          color: Colors.grey.withOpacity(0.3),
                                        ),
                                      ),
                                      // Car (white sedan/mini asset or icon)
                                      Positioned(
                                        left: -15,
                                        bottom: 0,
                                        child: Image.asset(
                                          'assets/images/sedan.png',
                                          width: 85,
                                          fit: BoxFit.contain,
                                          errorBuilder: (context, error, stackTrace) {
                                            return const Icon(Icons.directions_car_rounded, color: Colors.white, size: 48);
                                          },
                                        ),
                                      ),
                                      // Scooter/Bike
                                      Positioned(
                                        right: -5,
                                        bottom: 2,
                                        child: const Icon(
                                          Icons.two_wheeler_rounded,
                                          color: Color(0xFF2E7D32),
                                          size: 40,
                                        ),
                                      ),
                                      // Location Pin Icon
                                      Positioned(
                                        right: 28,
                                        top: 12,
                                        child: const Icon(
                                          Icons.location_on_rounded,
                                          color: Color(0xFF2E7D32),
                                          size: 28,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 28),

                  // Ride Services Section
                  Text(
                    "Ride Services".tr,
                    style: TextStyle(
                      fontFamily: AppThemeData.bold,
                      fontSize: 18,
                      color: isDarkMode ? AppThemeData.grey900Dark : AppThemeData.grey900,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: _buildRideServiceItem(
                          title: "Cab Ride".tr,
                          subtitle: "Local & Outstation".tr,
                          icon: Icons.directions_car_rounded,
                          iconColor: const Color(0xFF2E7D32),
                          onTap: () => _onServiceTap("Cab", 0),
                          isDarkMode: isDarkMode,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _buildRideServiceItem(
                          title: "Bike Ride".tr,
                          subtitle: "Quick & Affordable".tr,
                          icon: Icons.two_wheeler_rounded,
                          iconColor: const Color(0xFF2E7D32),
                          onTap: () => _onServiceTap("Bike", 0),
                          isDarkMode: isDarkMode,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _buildRideServiceItem(
                          title: "Sharing Cab".tr,
                          subtitle: "Local".tr,
                          icon: Icons.people_rounded,
                          iconColor: const Color(0xFF2E7D32),
                          onTap: () => _onServiceTap("Sharing", 0),
                          isDarkMode: isDarkMode,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _buildRideServiceItem(
                          title: "Sharing Cab".tr,
                          subtitle: "Outstation".tr,
                          icon: Icons.work_rounded,
                          iconColor: const Color(0xFF2E7D32),
                          onTap: () => _onServiceTap("Sharing Outstation", 0),
                          isDarkMode: isDarkMode,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 28),

                  // Logistics & Delivery Section
                  Text(
                    "Logistics & Delivery".tr,
                    style: TextStyle(
                      fontFamily: AppThemeData.bold,
                      fontSize: 18,
                      color: isDarkMode ? AppThemeData.grey900Dark : AppThemeData.grey900,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: _buildLogisticsServiceItem(
                          title: "Transport Pick & Drop".tr,
                          subtitle: "Goods Transport".tr,
                          iconWidget: const Icon(Icons.local_shipping_rounded, color: Color(0xFF2E7D32), size: 32),
                          onTap: () => _onServiceTap("Logistics", 1),
                          isDarkMode: isDarkMode,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildLogisticsServiceItem(
                          title: "Parcel & Delivery Support".tr,
                          subtitle: "Fast & Reliable".tr,
                          iconWidget: const Icon(Icons.inventory_2_rounded, color: Color(0xFFE67E22), size: 32),
                          onTap: () => _onServiceTap("Parcel & Delivery Support", 1),
                          isDarkMode: isDarkMode,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildRideServiceItem({
    required String title,
    required String subtitle,
    required IconData icon,
    required Color iconColor,
    required VoidCallback onTap,
    required bool isDarkMode,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        height: 115,
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 4),
        decoration: BoxDecoration(
          color: isDarkMode ? AppThemeData.grey800Dark : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isDarkMode ? AppThemeData.grey200Dark : const Color(0xFFEEEEEE),
            width: 1.0,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(isDarkMode ? 0.15 : 0.03),
              blurRadius: 8,
              offset: const Offset(0, 3),
            )
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Icon(icon, color: iconColor, size: 28),
            const SizedBox(height: 10),
            Text(
              title,
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontFamily: AppThemeData.bold,
                fontSize: 11,
                color: isDarkMode ? AppThemeData.grey900Dark : AppThemeData.grey900,
              ),
            ),
            const SizedBox(height: 3),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontFamily: AppThemeData.regular,
                fontSize: 8.5,
                color: isDarkMode ? AppThemeData.grey500Dark : AppThemeData.grey500,
                height: 1.1,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLogisticsServiceItem({
    required String title,
    required String subtitle,
    required Widget iconWidget,
    required VoidCallback onTap,
    required bool isDarkMode,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        decoration: BoxDecoration(
          color: isDarkMode ? AppThemeData.grey800Dark : const Color(0xFFF5F5F7),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isDarkMode ? AppThemeData.grey200Dark : const Color(0xFFEEEEEE),
            width: 1.0,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(isDarkMode ? 0.1 : 0.02),
              blurRadius: 6,
              offset: const Offset(0, 2),
            )
          ],
        ),
        child: Row(
          children: [
            iconWidget,
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontFamily: AppThemeData.bold,
                      fontSize: 13,
                      color: isDarkMode ? AppThemeData.grey900Dark : AppThemeData.grey900,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    subtitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontFamily: AppThemeData.medium,
                      fontSize: 10.5,
                      color: isDarkMode ? AppThemeData.grey500Dark : AppThemeData.grey500,
                    ),
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

buildAppDrawer(BuildContext context, DashBoardController controller) {
  final themeChange = Provider.of<DarkThemeProvider>(context);
  final bool isLogin = Preferences.getBoolean(Preferences.isLogin) ?? false;

  var drawerOptions = <Widget>[];
  for (var i = 0; i < controller.drawerTexiItems.length; i++) {
    var d = controller.drawerTexiItems[i];
    drawerOptions.add(InkWell(
      onTap: () {
        controller.onTexiSelectItem(i);
      },
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Visibility(
            visible: d.section != null,
            child: Padding(
              padding: const EdgeInsets.only(top: 30, bottom: 10, left: 16),
              child: Text(
                d.section ?? '',
                style: TextStyle(
                  color: themeChange.getThem()
                      ? AppThemeData.grey500Dark
                      : AppThemeData.grey300Dark,
                  fontSize: 14,
                  fontFamily: AppThemeData.regular,
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(mainAxisAlignment: MainAxisAlignment.start, children: [
                  SvgPicture.asset(
                    d.icon,
                    width: 24,
                    height: 24,
                    colorFilter: ColorFilter.mode(
                      controller.selectedDrawerIndex.value == i
                          ? AppThemeData.primary200
                          : themeChange.getThem()
                              ? AppThemeData.grey900Dark
                              : AppThemeData.grey900,
                      BlendMode.srcIn,
                    ),
                  ),
                  const SizedBox(
                    width: 16,
                  ),
                  Text(
                    d.title,
                    style: TextStyle(
                      color: controller.selectedDrawerIndex.value == i
                          ? AppThemeData.primary200
                          : themeChange.getThem()
                              ? AppThemeData.grey900Dark
                              : AppThemeData.grey900,
                      fontSize: 16,
                      fontFamily: AppThemeData.medium,
                    ),
                  ),
                ]),
                d.isSwitch == null
                    ? SvgPicture.asset(
                        'assets/icons/ic_right_arrow.svg',
                        width: 20,
                        height: 20,
                        colorFilter: ColorFilter.mode(
                          themeChange.getThem()
                              ? AppThemeData.grey400Dark
                              : AppThemeData.grey400,
                          BlendMode.srcIn,
                        ),
                      )
                    : SizedBox(
                        height: 25,
                        child: Switch(
                          trackOutlineColor:
                              WidgetStateProperty.resolveWith<Color>(
                                  (Set<WidgetState> states) {
                            return Colors.transparent;
                          }),
                          inactiveTrackColor: themeChange.getThem()
                              ? AppThemeData.grey300Dark
                              : AppThemeData.grey300,
                          activeTrackColor: AppThemeData.primary200,
                          thumbColor: WidgetStateProperty.resolveWith<Color>(
                              (Set<WidgetState> states) {
                            return themeChange.getThem()
                                ? AppThemeData.grey50
                                : AppThemeData.grey50Dark;
                          }),
                          value: themeChange.getThem(),
                          onChanged: (value) =>
                              (themeChange.darkTheme = value == true ? 0 : 1),
                        ),
                      ),
              ],
            ),
          ),
          if ((controller.drawerTexiItems.length - 1) > i)
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16),
              height: 0.5,
              color: themeChange.getThem()
                  ? AppThemeData.grey200Dark
                  : AppThemeData.grey200,
            )
        ],
      ),
    ));
  }
  return Drawer(
    width: Responsive.width(85, context),
    backgroundColor: themeChange.getThem()
        ? AppThemeData.surface50Dark
        : AppThemeData.surface50,
    child: ListView(
      children: [
        const SizedBox(height: 40),
        Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Align(
              alignment: Alignment.center,
              child: InkWell(
                onTap: () {},
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(80.0),
                  child: isLogin && controller.userModel?.data?.photoPath?.isNotEmpty == true
                      ? CachedNetworkImage(
                          imageUrl: controller.userModel!.data!.photoPath!,
                          height: 120,
                          width: 120,
                          fit: BoxFit.cover,
                          progressIndicatorBuilder:
                              (context, url, downloadProgress) => Center(
                            child: CircularProgressIndicator(
                                value: downloadProgress.progress),
                          ),
                          errorWidget: (context, url, error) => Image.asset(
                            ImageConstant.logo,
                          ),
                        )
                      : CachedNetworkImage(
                          imageUrl: Constant.placeholderUrl,
                          height: 120,
                          width: 120,
                          fit: BoxFit.cover,
                          progressIndicatorBuilder:
                              (context, url, downloadProgress) => Center(
                            child: CircularProgressIndicator(
                                value: downloadProgress.progress),
                          ),
                          errorWidget: (context, url, error) => Image.asset(
                            ImageConstant.logo,
                          ),
                        ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(top: 20),
              child: Text(
                isLogin && controller.userModel?.data != null
                    ? "${controller.userModel!.data!.prenom} ${controller.userModel!.data!.nom}"
                    : "Guest User",
                style: TextStyle(
                  color: themeChange.getThem()
                      ? AppThemeData.grey900Dark
                      : AppThemeData.grey900,
                  fontSize: 22,
                  fontFamily: AppThemeData.regular,
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(
                isLogin && controller.userModel?.data != null
                    ? '${controller.userModel!.data!.email}'
                    : 'guest@${Constant.appName}.tr',
                style: TextStyle(
                  color: themeChange.getThem()
                      ? AppThemeData.grey500Dark
                      : AppThemeData.grey500,
                  fontSize: 14,
                  fontFamily: AppThemeData.regular,
                ),
              ),
            )
          ],
        ),
        const SizedBox(height: 30),
        Column(children: drawerOptions),
      ],
    ),
  );
}

class DrawerItem {
  String? title;
  String? description;
  String? icon;
  String? section;
  bool? isSwitch;

  DrawerItem({required this.title,required this.description,required this.icon, this.section, this.isSwitch});
}
