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
                        icon: const Icon(Icons.arrow_back_ios_new, size: 20),
                        onPressed: () => Get.back(),
                      ),
                      IconButton(
                        icon: const Icon(Icons.menu, size: 24),
                        onPressed: () => _scaffoldKey.currentState?.openDrawer(),
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
                    height: 150,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          isDarkMode ? const Color(0xFF1E3A8A) : AppThemeData.primary200,
                          isDarkMode ? const Color(0xFF1E293B) : const Color(0xFF1E40AF),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [
                        BoxShadow(
                          color: AppThemeData.primary200.withOpacity(0.2),
                          blurRadius: 16,
                          offset: const Offset(0, 8),
                        )
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(24),
                      child: Stack(
                        children: [
                          // Decorative shapes
                          Positioned(
                            right: -20,
                            top: -20,
                            child: Container(
                              width: 140,
                              height: 140,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: Colors.white.withOpacity(0.04),
                              ),
                            ),
                          ),
                          Positioned(
                            left: -40,
                            bottom: -40,
                            child: Container(
                              width: 120,
                              height: 120,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: Colors.white.withOpacity(0.03),
                              ),
                            ),
                          ),
                          // Content Row
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
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
                                          fontSize: 22,
                                          color: Colors.white,
                                        ),
                                      ),
                                      const SizedBox(height: 8),
                                      Text(
                                        "Book rides, deliver parcels and more".tr,
                                        style: TextStyle(
                                          fontFamily: AppThemeData.regular,
                                          fontSize: 13,
                                          color: Colors.white.withOpacity(0.85),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                // Overlapping Car and Scooter Graphics
                                Expanded(
                                  flex: 4,
                                  child: Stack(
                                    clipBehavior: Clip.none,
                                    children: [
                                      // Secondary background circle
                                      Positioned(
                                        right: 15,
                                        top: 10,
                                        child: Container(
                                          width: 70,
                                          height: 70,
                                          decoration: BoxDecoration(
                                            color: Colors.white.withOpacity(0.15),
                                            shape: BoxShape.circle,
                                          ),
                                        ),
                                      ),
                                      // Car container
                                      Positioned(
                                        right: 30,
                                        bottom: 5,
                                        child: Transform.rotate(
                                          angle: -0.1,
                                          child: Container(
                                            padding: const EdgeInsets.all(10),
                                            decoration: BoxDecoration(
                                              color: Colors.white,
                                              borderRadius: BorderRadius.circular(16),
                                              boxShadow: [
                                                BoxShadow(
                                                  color: Colors.black.withOpacity(0.15),
                                                  blurRadius: 10,
                                                  offset: const Offset(0, 4),
                                                )
                                              ],
                                            ),
                                            child: Icon(Icons.directions_car_rounded, size: 36, color: AppThemeData.primary200),
                                          ),
                                        ),
                                      ),
                                      // Scooter/Bike container
                                      Positioned(
                                        right: 0,
                                        bottom: 25,
                                        child: Transform.rotate(
                                          angle: 0.15,
                                          child: Container(
                                            padding: const EdgeInsets.all(8),
                                            decoration: BoxDecoration(
                                              color: const Color(0xFF10B981), // Emerald green
                                              borderRadius: BorderRadius.circular(12),
                                              boxShadow: [
                                                BoxShadow(
                                                  color: Colors.black.withOpacity(0.2),
                                                  blurRadius: 8,
                                                  offset: const Offset(2, 4),
                                                )
                                              ],
                                            ),
                                            child: const Icon(Icons.two_wheeler_rounded, size: 24, color: Colors.white),
                                          ),
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
                  GridView.count(
                    crossAxisCount: 2,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    mainAxisSpacing: 16,
                    crossAxisSpacing: 16,
                    childAspectRatio: 1.25,
                    children: [
                      _buildServiceItem(
                        title: "Cab Ride".tr,
                        subtitle: "Local & Outstation".tr,
                        icon: Icons.directions_car_rounded,
                        iconColor: AppThemeData.primary200,
                        bgColor: AppThemeData.primary200.withOpacity(0.08),
                        onTap: () => _onServiceTap("Cab", 0),
                        isDarkMode: isDarkMode,
                      ),
                      _buildServiceItem(
                        title: "Bike Ride".tr,
                        subtitle: "Quick & Affordable".tr,
                        icon: Icons.two_wheeler_rounded,
                        iconColor: AppThemeData.warning200,
                        bgColor: AppThemeData.warning200.withOpacity(0.08),
                        onTap: () => _onServiceTap("Bike", 0),
                        isDarkMode: isDarkMode,
                      ),
                      _buildServiceItem(
                        title: "Sharing Cab".tr,
                        subtitle: "Local Ride".tr,
                        icon: Icons.people_rounded,
                        iconColor: const Color(0xFF0D9488),
                        bgColor: const Color(0xFF0D9488).withOpacity(0.08),
                        onTap: () => _onServiceTap("Sharing", 0),
                        isDarkMode: isDarkMode,
                      ),
                      _buildServiceItem(
                        title: "Sharing Cab".tr,
                        subtitle: "Outstation".tr,
                        icon: Icons.add_road_rounded,
                        iconColor: const Color(0xFF7C3AED),
                        bgColor: const Color(0xFF7C3AED).withOpacity(0.08),
                        onTap: () => _onServiceTap("Sharing Outstation", 0),
                        isDarkMode: isDarkMode,
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
                        child: _buildServiceItem(
                          title: "Transport Pick & Drop".tr,
                          subtitle: "Goods Transport".tr,
                          icon: Icons.local_shipping_rounded,
                          iconColor: const Color(0xFFE11D48),
                          bgColor: const Color(0xFFE11D48).withOpacity(0.08),
                          onTap: () => _onServiceTap("Logistics", 1),
                          isDarkMode: isDarkMode,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: _buildServiceItem(
                          title: "Parcel & Delivery Support".tr,
                          subtitle: "Fast & Reliable".tr,
                          icon: Icons.local_post_office_outlined,
                          iconColor: const Color(0xFFEA580C),
                          bgColor: const Color(0xFFEA580C).withOpacity(0.08),
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

  Widget _buildServiceItem({
    required String title,
    required String subtitle,
    required IconData icon,
    required Color iconColor,
    required Color bgColor,
    required VoidCallback onTap,
    required bool isDarkMode,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isDarkMode ? AppThemeData.grey100Dark : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isDarkMode ? AppThemeData.grey200Dark : Colors.grey.shade100,
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.03),
              blurRadius: 8,
              offset: const Offset(0, 4),
            )
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: bgColor,
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: iconColor, size: 24),
            ),
            const SizedBox(height: 12),
            Text(
              title,
              style: TextStyle(
                fontFamily: AppThemeData.semiBold,
                fontSize: 14,
                color: isDarkMode ? AppThemeData.grey900Dark : AppThemeData.grey900,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              subtitle,
              style: TextStyle(
                fontFamily: AppThemeData.regular,
                fontSize: 11,
                color: isDarkMode ? AppThemeData.grey500Dark : AppThemeData.grey500,
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
