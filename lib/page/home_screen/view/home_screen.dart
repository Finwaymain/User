import 'package:flutter_osm_plugin/flutter_osm_plugin.dart';
import 'package:geolocator/geolocator.dart';
import 'package:finway/controller/home_osm_controller.dart';
import 'package:finway/controller/home_controller.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:finway/page/features/Texi/texi_dash_board.dart';
import 'package:finway/page/features/AllServices/all_services_screen.dart';
import 'package:finway/page/features/AllServices/service_history_screen.dart';
import 'package:finway/page/search_location_screen.dart';
import 'package:finway/controller/new_ride_controller.dart';
import 'dart:io';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'dart:developer';

import 'package:finway/page/referral_screen/referral_screen.dart';
import 'package:finway/page/referral/submit_aadhar_screen.dart';
import 'package:finway/themes/custom_base_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:provider/provider.dart';
import '../../../constant/constant.dart';
import '../../../controller/dash_board_controller.dart';
import '../../../controller/wallet_controller.dart';
import '../../../model/payment_setting_model.dart';
import '../../../model/xenditModel.dart';
import '../../../themes/constant_colors.dart';
import '../../../utils/Preferences.dart';
import '../../../utils/dark_theme_provider.dart';
import '../../MainDashBoard/widget/animated_feature_card.dart';
import '../../MainDashBoard/widget/service_card.dart';
import '../../auth_screens/phone_entry_screen.dart';
import '../../features/SmartValue/MPinChange/view/mpin_change_screen.dart';
import '../../features/SmartValue/Medical/view/medical_screen.dart';
import '../../features/SmartValue/MyQR/view/my_qr_view.dart';
import '../../features/SmartValue/Payout/view/payout_screen.dart';
import '../../features/SmartValue/ScanAndTransfer/view/scanner_and_transfer_screen.dart';
import '../../in_progress_screen.dart';
import '../../contact_us/customer_support_screen.dart';
import '../../features/SmartValue/AccountDetails/view/account_details.dart';
import '../../features/SmartValue/AddPerson/view/add_user_screen.dart';
import '../../wallet/MercadoPagoScreen.dart';
import '../../wallet/PayFastScreen.dart';
import '../../wallet/paystack_url_genrater.dart';
import '../../../utils/onboarding_url.dart';
import '../../web_view_screen/web_view_screen.dart';
import '../../wallet/wallet_screen.dart';
import '../controller/main_home_controller.dart';
import '../widget/vertical_icon_with_text.dart';
import '../widget/vertical_line_section.dart';
import 'dart:math' as maths;
import 'package:finway/constant/show_toast_dialog.dart';
import 'package:finway/model/payStackURLModel.dart';
import 'package:finway/model/razorpay_gen_orderid_model.dart';
import 'package:finway/model/stripe_failed_model.dart';
import 'package:finway/model/user_model.dart';
import 'package:finway/page/wallet/midtrans_screen.dart';
import 'package:finway/page/wallet/orangePayScreen.dart';
import 'package:finway/page/wallet/payStackScreen.dart';
import 'package:finway/page/wallet/wallet_sucess_screen.dart';
import 'package:finway/page/wallet/xenditScreen.dart';
import 'package:finway/service/api.dart';
import 'package:finway/themes/text_field_them.dart';
import 'package:flutter_paypal/flutter_paypal.dart';
import 'package:flutter_stripe/flutter_stripe.dart' hide Address;
import '../../new_ride_screens/new_ride_screen.dart';

import '../../parcel_service_screen/parcel_category_screen.dart';
import '../../marketplace/view/marketplace_home_screen.dart';
import 'package:razorpay_flutter/razorpay_flutter.dart';

class MainHomeScreen extends StatefulWidget {
  const MainHomeScreen({super.key});

  @override
  State<MainHomeScreen> createState() => _MainHomeScreenState();
}

class _MainHomeScreenState extends State<MainHomeScreen> {
  DateTime backPress = DateTime.now();

  // Local map variables
  MapController? mainMapController;
  String currentAddress = "Locating your position...";
  String etaText = "4 min away";
  bool isMapReady = false;

  // Selected ride index matching design.html options
  int selectedRideIndex = 1; // Default to "Mini"

  final List<Map<String, dynamic>> rideOptions = [
    {"icon": "🛵", "title": "Bike", "eta": "3 min away", "price": "62"},
    {"icon": "🚗", "title": "Mini", "eta": "5 min away", "price": "118"},
    {"icon": "🚙", "title": "Sedan", "eta": "4 min away", "price": "164"},
    {"icon": "🚐", "title": "XL", "eta": "6 min away", "price": "239"},
  ];

  @override
  void initState() {
    super.initState();
    mainMapController = MapController(
      initPosition: GeoPoint(latitude: 28.6139, longitude: 77.2090),
    );
    _initUserLocation();
  }

  Future<void> _initUserLocation() async {
    try {
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.whileInUse || permission == LocationPermission.always) {
        Position position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high,
        );
        final userGeoPoint = GeoPoint(
          latitude: position.latitude,
          longitude: position.longitude,
        );
        if (mainMapController != null) {
          await mainMapController!.goToLocation(userGeoPoint);
        }

        // Nominatim reverse geocoding API
        String url = 'https://nominatim.openstreetmap.org/reverse?format=json&lat=${position.latitude}&lon=${position.longitude}&zoom=18&addressdetails=1';
        var package = Platform.isAndroid ? 'com.cabme' : 'com.cabme.ios';
        http.Response response = await http.get(
          Uri.parse(url),
          headers: {'User-Agent': package},
        );
        if (response.statusCode == 200) {
          Map<String, dynamic> data = json.decode(response.body);
          if (mounted) {
            setState(() {
              currentAddress = data['display_name'] ?? 'Current Location';
              if (data['address'] != null) {
                var addr = data['address'];
                currentAddress = addr['suburb'] ?? addr['city'] ?? addr['county'] ?? addr['state'] ?? data['display_name'];
              }
              isMapReady = true;
            });
          }
        }
      }
    } catch (e) {
      log("Error getting user location: $e");
    }
  }

  void _startBookingFlow({SearchInfo? destinationResult}) async {
    if (!Preferences.getBoolean(Preferences.isLogin)) {
      Get.to(() => const PhoneEntryScreen(), transition: Transition.rightToLeftWithFade);
      return;
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    if (permission == LocationPermission.deniedForever || permission == LocationPermission.denied) {
      ShowToastDialog.showToast("Location permission is required to book a ride.");
      return;
    }

    ShowToastDialog.showLoader("Preparing route...");
    try {
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      if (Constant.selectedMapType == 'google' || Constant.selectedMapType == 'google-map') {
        final googleController = Get.put(HomeController());
        LatLng departurePoint = LatLng(
          position.latitude,
          position.longitude,
        );
        await googleController.setDepartureMarker(departurePoint);
        googleController.departureController.text = currentAddress;

        ShowToastDialog.closeLoader();

        if (destinationResult != null) {
          LatLng destLatLng = LatLng(destinationResult.point!.latitude, destinationResult.point!.longitude);
          await googleController.setDestinationMarker(destLatLng);
          googleController.destinationController.text = destinationResult.address.toString();
          Get.to(() => TexiDashboard());
        } else {
          final result = await Get.to(() => AddressSearchScreen());
          if (result != null && result is SearchInfo) {
            LatLng destLatLng = LatLng(result.point!.latitude, result.point!.longitude);
            await googleController.setDestinationMarker(destLatLng);
            googleController.destinationController.text = result.address.toString();
            Get.to(() => TexiDashboard());
          }
        }
      } else {
        final osmController = Get.put(HomeOsmController());
        GeoPoint departurePoint = GeoPoint(
          latitude: position.latitude,
          longitude: position.longitude,
        );
        await osmController.setDepartureMarker(departurePoint);
        osmController.departureController.text = currentAddress;

        ShowToastDialog.closeLoader();

        if (destinationResult != null) {
          await osmController.setDestinationMarker(destinationResult.point!);
          osmController.destinationController.text = destinationResult.address.toString();
          Get.to(() => TexiDashboard());
        } else {
          final result = await Get.to(() => AddressSearchScreen());
          if (result != null && result is SearchInfo) {
            await osmController.setDestinationMarker(result.point!);
            osmController.destinationController.text = result.address.toString();
            Get.to(() => TexiDashboard());
          }
        }
      }
    } catch (e) {
      ShowToastDialog.closeLoader();
      ShowToastDialog.showToast("Could not determine location");
    }
  }

  void _handleQuickDestinationTap(String type) {
    GeoPoint targetPoint;
    String addressName;
    if (type == 'Home') {
      targetPoint = GeoPoint(latitude: 28.6284, longitude: 77.3769);
      addressName = "Noida Sector 62, Uttar Pradesh";
    } else if (type == 'Work') {
      targetPoint = GeoPoint(latitude: 28.6304, longitude: 77.2177);
      addressName = "Connaught Place, New Delhi";
    } else if (type == 'Airport') {
      targetPoint = GeoPoint(latitude: 28.5562, longitude: 77.1000);
      addressName = "Indira Gandhi International Airport, New Delhi";
    } else {
      targetPoint = GeoPoint(latitude: 28.5450, longitude: 77.1926);
      addressName = "IIT Delhi, Hauz Khas, New Delhi";
    }

    SearchInfo mockSearch = SearchInfo(
      point: targetPoint,
      address: Address(
        city: addressName,
        street: addressName,
        name: addressName,
      ),
    );

    _startBookingFlow(destinationResult: mockSearch);
  }

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) {
      return "Good morning";
    } else if (hour < 17) {
      return "Good afternoon";
    } else {
      return "Good evening";
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeChange = Provider.of<DarkThemeProvider>(context);
    final isDark = themeChange.getThem();

    final Color bgColor = isDark ? AppThemeData.surface50Dark : AppThemeData.surface50;
    final Color cardBg = isDark ? AppThemeData.grey800 : Colors.white;
    final Color borderColor = isDark ? AppThemeData.grey300Dark.withValues(alpha: 0.4) : AppThemeData.grey300.withValues(alpha: 0.5);
    final Color textColor = isDark ? AppThemeData.grey50Dark : AppThemeData.grey900;
    final Color mutedColor = isDark ? AppThemeData.grey500Dark : AppThemeData.grey400;
    final Color blueSoft = isDark ? AppThemeData.primary200.withValues(alpha: 0.15) : const Color(0xFFE7ECFC);
    final Color coralColor = const Color(0xFFFF6B4A);

    return GetBuilder<DashBoardController>(
      init: DashBoardController(),
      builder: (dashboardController) {
        dashboardController.getDrawerItems();

        return GetBuilder<MainHomeController>(
          init: MainHomeController(),
          builder: (mainHomeController) {
            final activeFeatureEntries = mainHomeController.featureCards
                .asMap()
                .entries
                .where((entry) => entry.value['status'] == 1)
                .toList();

            final activeServiceEntries = mainHomeController.serviceCards
                .asMap()
                .entries
                .where((entry) => entry.value['status'] == 1)
                .toList();

            String greetingName = "Guest";
            if (dashboardController.userModel.value != null && dashboardController.userModel.value!.data != null) {
              greetingName = dashboardController.userModel.value!.data!.prenom ?? dashboardController.userModel.value!.data!.nom ?? "User";
            }

            final newRideController = Get.put(NewRideController());
            String rideRouteText = "Connaught Place → Noida Sec 62";
            String rideSubText = "Demo • Ready for your first ride";
            String ridePriceText = "342";

            if (newRideController.newRideList.isNotEmpty) {
              final ride = newRideController.newRideList.first;
              rideRouteText = "${ride.departName} → ${ride.destinationName}";
              rideSubText = "Active • ${ride.dateRetour ?? 'Today'}";
              ridePriceText = "${ride.montant}";
            } else if (newRideController.completedRideList.isNotEmpty) {
              final ride = newRideController.completedRideList.first;
              rideRouteText = "${ride.departName} → ${ride.destinationName}";
              rideSubText = "Completed • ${ride.dateRetour ?? 'Recently'}";
              ridePriceText = "${ride.montant}";
            }

            return WillPopScope(
              onWillPop: () async {
                final timeGap = DateTime.now().difference(backPress);
                final cantExit = timeGap >= const Duration(seconds: 2);
                backPress = DateTime.now();
                if (cantExit) {
                  var snack = SnackBar(
                    content: Text(
                      'Press Back button again to Exit'.tr,
                      style: const TextStyle(color: Colors.white),
                    ),
                    duration: const Duration(seconds: 2),
                    backgroundColor: Colors.black,
                  );
                  ScaffoldMessenger.of(context).showSnackBar(snack);
                  return false;
                } else {
                  return true;
                }
              },
              child: Scaffold(
                backgroundColor: bgColor,
                body: SafeArea(
                  child: SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 14),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _getGreeting().toUpperCase(),
                                style: TextStyle(
                                  fontFamily: AppThemeData.medium,
                                  fontSize: 10.5,
                                  letterSpacing: 1.2,
                                  color: mutedColor,
                                ),
                              ),
                              const SizedBox(height: 3),
                              Text(
                                greetingName,
                                style: TextStyle(
                                  fontFamily: AppThemeData.bold,
                                  fontSize: 18,
                                  color: textColor,
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ],
                          ),
                        ),

                        

                        // Header Row with fixed height to prevent vertical misalignment
                        Row(
                          children: [
                            Expanded(
                              child: Container(
                                height: 38,
                                alignment: Alignment.bottomLeft,
                                padding: const EdgeInsets.only(left: 22, bottom: 4),
                                child: Text(
                                  "Features",
                                  style: TextStyle(
                                    fontFamily: AppThemeData.bold,
                                    fontSize: 13.5,
                                    color: textColor,
                                    height: 1.2,
                                  ),
                                ),
                              ),
                            ),
                            Expanded(
                              child: Container(
                                height: 38,
                                alignment: Alignment.bottomLeft,
                                padding: const EdgeInsets.only(left: 8, bottom: 4),
                                child: Text(
                                  "Services",
                                  style: TextStyle(
                                    fontFamily: AppThemeData.bold,
                                    fontSize: 13.5,
                                    color: textColor,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 8),

                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Left Column: Features & Wallet Cards
                            Expanded(
                              child: Column(
                                children: activeFeatureEntries.map<Widget>((entry) {
                                  return Padding(
                                    padding: const EdgeInsets.only(left: 22, right: 8, bottom: 12),
                                    child: GestureDetector(
                                      onTap: () => mainHomeController.onFeatureTap(entry.key),
                                      child: AnimatedFeatureCard(
                                        icon: entry.value['icon'] as IconData,
                                        title: entry.value['title'] as String,
                                      ),
                                    ),
                                  );
                                }).toList(),
                              ),
                            ),
                            // Right Column: Services Cards
                            Expanded(
                              child: Column(
                                children: activeServiceEntries.map<Widget>((entry) {
                                  return Padding(
                                    padding: const EdgeInsets.only(left: 8, right: 22, bottom: 12),
                                    child: GestureDetector(
                                      onTap: () => mainHomeController.onServiceTap(entry.key),
                                      child: ServiceCard(
                                        title: entry.value['title'] as String,
                                        subtitle: entry.value['subtitle'] as String,
                                      ),
                                    ),
                                  );
                                }).toList(),
                              ),
                            ),
                          ],
                        ),

                        VerticalLineSection(
                          text: "Quick Access",
                          margin: const EdgeInsets.only(top: 25),
                          cardChildren: [
                            VerticalIconWithText(
                              icon: Icons.directions_car_outlined,
                              text: 'Ride Booking',
                              onTap: () {
                                if (!Preferences.getBoolean(Preferences.isLogin)) {
                                  Get.to(() => const PhoneEntryScreen(), transition: Transition.rightToLeftWithFade);
                                  return;
                                }
                                Get.to(() => TexiDashboard(), transition: Transition.rightToLeftWithFade);
                              },
                            ),
                            VerticalIconWithText(
                              icon: Icons.home_repair_service_outlined,
                              text: 'Service History',
                              onTap: () {
                                if (!Preferences.getBoolean(Preferences.isLogin)) {
                                  Get.to(() => const PhoneEntryScreen(), transition: Transition.rightToLeftWithFade);
                                  return;
                                }
                                Get.to(() => const ServiceHistoryScreen(), transition: Transition.rightToLeftWithFade);
                              },
                            ),

                            VerticalIconWithText(
                              icon: Icons.local_post_office_outlined,
                              text: 'Parcel Service',
                              onTap: () {
                                if (!Preferences.getBoolean(Preferences.isLogin)) {
                                  Get.to(() => const PhoneEntryScreen(), transition: Transition.rightToLeftWithFade);
                                  return;
                                }
                                Get.to(() => const ParcelCategoryScreen(), transition: Transition.rightToLeftWithFade);
                              },
                            ),
                            VerticalIconWithText(
                              icon: Icons.share_location_outlined,
                              text: 'Shared Ride',
                              onTap: () {
                                if (!Preferences.getBoolean(Preferences.isLogin)) {
                                  Get.to(() => const PhoneEntryScreen(), transition: Transition.rightToLeftWithFade);
                                  return;
                                }
                                Get.to(() => const InProgressScreen(), transition: Transition.rightToLeftWithFade);
                              },
                            ),
                            VerticalIconWithText(
                              icon: Icons.storefront_outlined,
                              text: 'Marketplace',
                              onTap: () {
                                final url = OnboardingUrl.build('/onboarding/marketplace.html');
                                Get.to(
                                  () => WebViewScreen(url: url, title: 'Marketplace'.tr),
                                  transition: Transition.rightToLeftWithFade,
                                );
                              },
                            ),
                            VerticalIconWithText(
                              icon: Icons.fastfood_outlined,
                              text: 'Food Order',
                              onTap: () {
                                final url = OnboardingUrl.build('/onboarding/food.html');
                                Get.to(
                                  () => WebViewScreen(url: url, title: 'Food Ordering'.tr),
                                  transition: Transition.rightToLeftWithFade,
                                );
                              },
                            ),
                            VerticalIconWithText(
                              icon: Icons.headset_mic_outlined,
                              text: 'Support',
                              onTap: () {
                                Get.to(() => const CustomerSupportScreen(), transition: Transition.rightToLeftWithFade);
                              },
                            ),
                            VerticalIconWithText(
                              icon: Icons.more_horiz_outlined,
                              text: 'More',
                              onTap: () {
                                if (!Preferences.getBoolean(Preferences.isLogin)) {
                                  Get.to(() => const PhoneEntryScreen(), transition: Transition.rightToLeftWithFade);
                                  return;
                                }
                                Get.to(() => const AllServicesScreen(), transition: Transition.rightToLeftWithFade);
                              },
                            ),
                          ],
                        ),

                        VerticalLineSection(
                          text: "Smart Value",
                          margin: const EdgeInsets.only(top: 25),
                          cardChildren: [
                            VerticalIconWithText(
                              icon: Icons.info_outline,
                              text: 'Account Details',
                              onTap: () {
                                if (!Preferences.getBoolean(Preferences.isLogin)) {
                                  Get.to(() => const PhoneEntryScreen(), transition: Transition.rightToLeftWithFade);
                                  return;
                                }
                                Get.to(() => AccountDetails(), transition: Transition.rightToLeftWithFade);
                              },
                            ),
                            VerticalIconWithText(
                              icon: Icons.person_add_alt_1_outlined,
                              text: 'Add Person',
                              onTap: () {
                                if (!Preferences.getBoolean(Preferences.isLogin)) {
                                  Get.to(() => const PhoneEntryScreen(), transition: Transition.rightToLeftWithFade);
                                  return;
                                }
                                Get.to(() => AddUserScreen(), transition: Transition.rightToLeftWithFade);
                              },
                            ),
                            VerticalIconWithText(
                              icon: Icons.swap_horiz_outlined,
                              text: 'Transfer Money',
                              onTap: () {
                                if (!Preferences.getBoolean(Preferences.isLogin)) {
                                  Get.to(() => const PhoneEntryScreen(), transition: Transition.rightToLeftWithFade);
                                  return;
                                }
                                Get.to(() => ScannerAndTransferScreen(), transition: Transition.rightToLeftWithFade);
                              },
                            ),
                            VerticalIconWithText(
                              icon: Icons.qr_code_2_outlined,
                              text: 'My QR Code',
                              onTap: () {
                                if (!Preferences.getBoolean(Preferences.isLogin)) {
                                  Get.to(() => const PhoneEntryScreen(), transition: Transition.rightToLeftWithFade);
                                  return;
                                }
                                Get.to(() => MyQRScreen(), transition: Transition.rightToLeftWithFade);
                              },
                            ),
                            VerticalIconWithText(
                              icon: Icons.pin_outlined,
                              text: 'Set M-PIN',
                              onTap: () {
                                if (!Preferences.getBoolean(Preferences.isLogin)) {
                                  Get.to(() => const PhoneEntryScreen(), transition: Transition.rightToLeftWithFade);
                                  return;
                                }
                                Get.to(() => MPinChangeScreen(), transition: Transition.rightToLeftWithFade);
                              },
                            ),
                            VerticalIconWithText(
                              icon: Icons.account_balance_outlined,
                              text: 'Payouts',
                              onTap: () {
                                if (!Preferences.getBoolean(Preferences.isLogin)) {
                                  Get.to(() => const PhoneEntryScreen(), transition: Transition.rightToLeftWithFade);
                                  return;
                                }
                                Get.to(() => WalletScreen(), transition: Transition.rightToLeftWithFade);
                              },
                            ),
                            VerticalIconWithText(
                              icon: Icons.group_add_outlined,
                              text: 'Partner Dashboard',
                              onTap: () {
                                if (!Preferences.getBoolean(Preferences.isLogin)) {
                                  Get.to(() => const PhoneEntryScreen(), transition: Transition.rightToLeftWithFade);
                                  return;
                                }
                                Get.to(() => const ReferralScreen(), transition: Transition.rightToLeftWithFade);
                              },
                            ),
                          ],
                        ),

                        VerticalLineSection(
                          text: "Medical Cashback",
                          margin: const EdgeInsets.only(top: 25),
                          cardChildren: [
                            VerticalIconWithText(
                              icon: Icons.medical_services_outlined,
                              text: 'Medical Cards',
                              onTap: () {
                                if (!Preferences.getBoolean(Preferences.isLogin)) {
                                  Get.to(() => const PhoneEntryScreen(), transition: Transition.rightToLeftWithFade);
                                  return;
                                }
                                final finalUrl = OnboardingUrl.build('/onboarding/medical-cashback');
                                Get.to(() => WebViewScreen(url: finalUrl, title: 'Medical Cashback'), transition: Transition.rightToLeftWithFade);
                              },
                            ),
                          ],
                        ),

                        const SizedBox(height: 250),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildQuickChip(String emoji, String title, VoidCallback onTap) {
    final themeChange = Provider.of<DarkThemeProvider>(context);
    final isDark = themeChange.getThem();
    final Color cardBg = isDark ? AppThemeData.grey800 : Colors.white;
    final Color borderColor = isDark ? AppThemeData.grey300Dark.withValues(alpha: 0.4) : AppThemeData.grey300.withValues(alpha: 0.5);
    final Color textColor = isDark ? AppThemeData.grey50Dark : AppThemeData.grey900;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(right: 10),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: cardBg,
          border: Border.all(color: borderColor),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Column(
          children: [
            Text(emoji, style: const TextStyle(fontSize: 15)),
            const SizedBox(height: 6),
            Text(
              title,
              style: TextStyle(
                fontSize: 11.5,
                fontWeight: FontWeight.w600,
                color: textColor,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class PulseDot extends StatefulWidget {
  const PulseDot({super.key});

  @override
  _PulseDotState createState() => _PulseDotState();
}

class _PulseDotState extends State<PulseDot> with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    )..repeat(reverse: false);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.center,
      children: [
        AnimatedBuilder(
          animation: _controller,
          builder: (context, child) {
            return Container(
              width: 7 + 10 * _controller.value,
              height: 7 + 10 * _controller.value,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFF22C55E).withValues(alpha: 0.4 * (1.0 - _controller.value)),
              ),
            );
          },
        ),
        Container(
          width: 7,
          height: 7,
          decoration: const BoxDecoration(
            shape: BoxShape.circle,
            color: Color(0xFF22C55E),
          ),
        ),
      ],
    );
  }
}

class TicketPainter extends CustomPainter {
  final Color backgroundColor;
  final Color borderColor;
  final Color stubColor;
  final double punchRadius;
  final double dashLeftRatio;

  TicketPainter({
    required this.backgroundColor,
    required this.borderColor,
    required this.stubColor,
    this.punchRadius = 8.0,
    this.dashLeftRatio = 0.72,
  });

  @override
  void paint(Canvas canvas, Size size) {
    double w = size.width;
    double h = size.height;
    double punchX = w * dashLeftRatio;

    Path path = Path();
    path.moveTo(0, 18);
    path.quadraticBezierTo(0, 0, 18, 0);
    path.lineTo(punchX - punchRadius, 0);
    path.arcToPoint(
      Offset(punchX + punchRadius, 0),
      radius: Radius.circular(punchRadius),
      clockwise: false,
    );
    path.lineTo(w - 18, 0);
    path.quadraticBezierTo(w, 0, w, 18);
    path.lineTo(w, h - 18);
    path.quadraticBezierTo(w, h, w - 18, h);
    path.lineTo(punchX + punchRadius, h);
    path.arcToPoint(
      Offset(punchX - punchRadius, h),
      radius: Radius.circular(punchRadius),
      clockwise: false,
    );
    path.lineTo(18, h);
    path.quadraticBezierTo(0, h, 0, h - 18);
    path.close();

    final bgPaint = Paint()..color = backgroundColor..style = PaintingStyle.fill;
    canvas.drawPath(path, bgPaint);

    canvas.save();
    Path stubPath = Path();
    stubPath.moveTo(punchX, 0);
    stubPath.lineTo(w - 18, 0);
    stubPath.quadraticBezierTo(w, 0, w, 18);
    stubPath.lineTo(w, h - 18);
    stubPath.quadraticBezierTo(w, h, w - 18, h);
    stubPath.lineTo(punchX, h);
    stubPath.lineTo(punchX + punchRadius, h);
    stubPath.arcToPoint(
      Offset(punchX, h),
      radius: Radius.circular(punchRadius),
      clockwise: true,
    );
    stubPath.lineTo(punchX, 0);
    stubPath.lineTo(punchX + punchRadius, 0);
    stubPath.arcToPoint(
      Offset(punchX, 0),
      radius: Radius.circular(punchRadius),
      clockwise: true,
    );
    stubPath.close();

    final stubPaint = Paint()..color = stubColor..style = PaintingStyle.fill;
    canvas.drawPath(stubPath, stubPaint);
    canvas.restore();

    final borderPaint = Paint()
      ..color = borderColor
      ..strokeWidth = 1.0
      ..style = PaintingStyle.stroke;
    canvas.drawPath(path, borderPaint);

    final dashPaint = Paint()
      ..color = borderColor
      ..strokeWidth = 1.2
      ..style = PaintingStyle.stroke;
    double startY = punchRadius;
    double dashHeight = 5.0;
    double dashSpace = 4.0;
    while (startY < h - punchRadius) {
      canvas.drawLine(Offset(punchX, startY), Offset(punchX, startY + dashHeight), dashPaint);
      startY += dashHeight + dashSpace;
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
class AddFundScreen extends StatelessWidget {
  AddFundScreen({super.key});

  final walletController = Get.put(WalletController());
  final Razorpay razorPayController = Razorpay();

  static final GlobalKey<FormState> _walletFormKey = GlobalKey<FormState>();
  static final amountController = TextEditingController();

  Future<void> _refreshAPI() async {
    walletController.getAmount();
    walletController.getTransaction();
    amountController.clear();
    setRef();
  }

  @override
  Widget build(BuildContext context) {
    final themeChange = Provider.of<DarkThemeProvider>(context);
    final isDark = themeChange.getThem();

    return CustomBaseWidget(
      showAppBar: true,
      appBarTitle: 'Add Fund',
      body: Column(
        children: [
          // Main Content
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(15.0),
              child: Column(
                children: [
                  // Balance Card
                  _buildBalanceCard(context, isDark),

                  const SizedBox(height: 32),

                  // Amount Input Section
                  _buildAmountInputSection(context, isDark),

                  const SizedBox(height: 20),

                  // Quick Amount Selection
                  _buildQuickAmountSelection(context, isDark),

                  const SizedBox(height: 40),

                  // Add Button
                  _buildAddButton(context, isDark),

                  const SizedBox(height: 140),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBalanceCard(BuildContext context, bool isDark) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isDark
              ? [
                  AppThemeData.primary200.withValues(alpha: 0.8),
                  AppThemeData.primary200.withValues(alpha: 0.6),
                ]
              : [
                  AppThemeData.primary200,
                  AppThemeData.primary200.withValues(alpha: 0.8),
                ],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppThemeData.primary200.withValues(alpha: 0.3),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          Text(
            "Current Balance".tr,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.9),
              fontFamily: AppThemeData.medium,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 8),
          Obx(() => Text(
                "${Constant.currency}${walletController.userModel.value.data?.amount ?? '0'}",
                style: const TextStyle(
                  color: Colors.white,
                  fontFamily: AppThemeData.bold,
                  fontSize: 32,
                ),
              )),
        ],
      ),
    );
  }

  Widget _buildAmountInputSection(BuildContext context, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: isDark ? AppThemeData.grey800 : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDark
              ? AppThemeData.grey800.withValues(alpha: 0.3)
              : Colors.grey.withValues(alpha: 0.1),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.05),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppThemeData.primary200.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  Icons.account_balance_wallet_rounded,
                  color: AppThemeData.primary200,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                "Enter Amount".tr,
                style: TextStyle(
                  color:
                      isDark ? AppThemeData.grey900Dark : AppThemeData.grey900,
                  fontFamily: AppThemeData.semiBold,
                  fontSize: 18,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Form(
            key: _walletFormKey,
            child: Container(
              decoration: BoxDecoration(
                color: isDark
                    ? AppThemeData.grey800.withValues(alpha: 0.5)
                    : AppThemeData.grey100,
                borderRadius: BorderRadius.circular(16),
              ),
              child: TextFieldWidget(
                inputFormatters: <TextInputFormatter>[
                  FilteringTextInputFormatter.digitsOnly
                ],
                hintText: '0',
                controller: amountController,
                textInputType: TextInputType.number,
                prefix: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  child: Icon(
                    Icons.payments_rounded,
                    color: AppThemeData.primary200,
                    size: 24,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickAmountSelection(BuildContext context, bool isDark) {
    final amounts = ["100", "500", "1000", "2000", "5000"];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Quick Select".tr,
          style: TextStyle(
            color: isDark ? AppThemeData.grey900Dark : AppThemeData.grey900,
            fontFamily: AppThemeData.semiBold,
            fontSize: 18,
          ),
        ),
        const SizedBox(height: 16),
        Wrap(
          spacing: 15,
          runSpacing: 12,
          children: amounts
              .map((amount) => _buildQuickAmountChip(context, amount, isDark))
              .toList(),
        ),
      ],
    );
  }

  Widget _buildQuickAmountChip(
      BuildContext context, String amount, bool isDark) {
    return ValueListenableBuilder<TextEditingValue>(
      valueListenable: amountController,
      builder: (context, value, child) {
        final isSelected = value.text == amount;

        return GestureDetector(
          onTap: () {
            amountController.text = amount;
          },
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            decoration: BoxDecoration(
              gradient: isSelected
                  ? LinearGradient(
                      colors: [
                        AppThemeData.primary200,
                        AppThemeData.primary200.withValues(alpha: 0.8),
                      ],
                    )
                  : null,
              color: isSelected
                  ? null
                  : isDark
                      ? AppThemeData.grey800
                      : Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isSelected
                    ? AppThemeData.primary200
                    : isDark
                        ? AppThemeData.grey800.withValues(alpha: 0.3)
                        : Colors.grey.withValues(alpha: 0.2),
                width: isSelected ? 2 : 1,
              ),
              boxShadow: isSelected
                  ? [
                      BoxShadow(
                        color: AppThemeData.primary200.withValues(alpha: 0.3),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ]
                  : [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.05),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
            ),
            child: Text(
              "${Constant.currency}$amount",
              style: TextStyle(
                color: isSelected
                    ? Colors.white
                    : isDark
                        ? AppThemeData.grey900Dark
                        : AppThemeData.grey900,
                fontFamily: AppThemeData.semiBold,
                fontSize: 16,
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildAddButton(BuildContext context, bool isDark) {
    return Container(
      width: double.infinity,
      height: 56,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
          colors: [
            AppThemeData.primary200,
            AppThemeData.primary200.withValues(alpha: 0.8),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppThemeData.primary200.withValues(alpha: 0.4),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: ElevatedButton(
        onPressed: () {
          if (_walletFormKey.currentState!.validate()) {
            _showPaymentOptions(context, isDark);
          }
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Stack(
              clipBehavior: Clip.none,
              children: [
                const Icon(
                  Icons.account_balance_wallet_outlined,
                  color: Colors.white,
                  size: 24,
                ),
                Positioned(
                  top: -4,
                  right: -4,
                  child: Container(
                    padding: const EdgeInsets.all(2),
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.add,
                      color: AppThemeData.primary200,
                      size: 10,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(width: 12),
            Text(
              'Add Amount'.tr,
              style: const TextStyle(
                color: Colors.white,
                fontFamily: AppThemeData.bold,
                fontSize: 18,
              ),
            ),
          ],
        ),
      ),
    );
  }

  _showPaymentOptions(BuildContext context, bool isDarkMode) {
    return showModalBottomSheet(
      isDismissible: true,
      isScrollControlled: true,
      elevation: 0,
      backgroundColor: Colors.transparent,
      context: context,
      builder: (context) {
        return Container(
          height: Get.height * 0.75,
          decoration: BoxDecoration(
            color: isDarkMode ? AppThemeData.surface50Dark : Colors.white,
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(24),
              topRight: Radius.circular(24),
            ),
          ),
          child: GetX<WalletController>(
            init: WalletController(),
            initState: (controller) {
              razorPayController.on(
                  Razorpay.EVENT_PAYMENT_SUCCESS, _handlePaymentSuccess);
              razorPayController.on(
                  Razorpay.EVENT_EXTERNAL_WALLET, _handleExternalWaller);
              razorPayController.on(
                  Razorpay.EVENT_PAYMENT_ERROR, _handlePaymentError);
            },
            builder: (controller) {
              return Column(
                children: [
                  // Handle bar
                  Container(
                    margin: const EdgeInsets.symmetric(vertical: 12),
                    height: 4,
                    width: 40,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(2),
                      color: isDarkMode
                          ? AppThemeData.grey800
                          : Colors.grey.withValues(alpha: 0.4),
                    ),
                  ),

                  // Header
                  Padding(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: isDarkMode
                                ? AppThemeData.grey800.withValues(alpha: 0.5)
                                : AppThemeData.grey100,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(
                            Icons.payment_rounded,
                            color: AppThemeData.primary200,
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Text(
                            "Select Payment Method".tr,
                            style: TextStyle(
                              color: isDarkMode
                                  ? AppThemeData.grey900Dark
                                  : AppThemeData.grey900,
                              fontFamily: AppThemeData.bold,
                              fontSize: 20,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Amount Display
                  Container(
                    margin: const EdgeInsets.symmetric(horizontal: 24),
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          AppThemeData.primary200.withValues(alpha: 0.1),
                          AppThemeData.primary200.withValues(alpha: 0.05),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: AppThemeData.primary200.withValues(alpha: 0.2),
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.account_balance_wallet_outlined,
                          color: AppThemeData.primary200,
                          size: 24,
                        ),
                        const SizedBox(width: 12),
                        Text(
                          "Amount: ",
                          style: TextStyle(
                            color: isDarkMode
                                ? AppThemeData.grey900Dark
                                : AppThemeData.grey900,
                            fontFamily: AppThemeData.medium,
                            fontSize: 16,
                          ),
                        ),
                        Text(
                          "${Constant.currency}${amountController.text}",
                          style: TextStyle(
                            color: AppThemeData.primary200,
                            fontFamily: AppThemeData.bold,
                            fontSize: 20,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Payment Options List
                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: Column(
                        children: [
                          // Payment options grid
                          _buildPaymentMethodsGrid(
                              context, isDarkMode, controller),
                        ],
                      ),
                    ),
                  ),

                  // Proceed Button
                  Container(
                    padding: const EdgeInsets.all(24),
                    child: Container(
                      width: double.infinity,
                      height: 56,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            AppThemeData.primary200,
                            AppThemeData.primary200.withValues(alpha: 0.8),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: AppThemeData.primary200.withValues(alpha: 0.3),
                            blurRadius: 12,
                            offset: const Offset(0, 6),
                          ),
                        ],
                      ),
                      child: ElevatedButton(
                        onPressed: () async {
                          if (walletController.selectedRadioTile?.value == '' ||
                              walletController
                                      .selectedRadioTile?.value.isEmpty ==
                                  true) {
                            ShowToastDialog.showToast(
                                "Please select payment method");
                          } else {
                            Get.back();
                            showLoadingAlert(context);
                            await _processPayment(context);
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.transparent,
                          shadowColor: Colors.transparent,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(
                              Icons.arrow_forward_rounded,
                              color: Colors.white,
                              size: 24,
                            ),
                            const SizedBox(width: 12),
                            Text(
                              'Proceed to Pay'.tr,
                              style: const TextStyle(
                                color: Colors.white,
                                fontFamily: AppThemeData.bold,
                                fontSize: 18,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildPaymentMethodsGrid(
      BuildContext context, bool isDarkMode, WalletController controller) {
    final paymentMethods = [
      {
        'value': 'Stripe',
        'title': 'Stripe',
        'icon': 'assets/icons/stripe.png',
        'isVisible':
            walletController.paymentSettingModel.value.strip?.isEnabled ==
                "true",
      },
      {
        'value': 'PayStack',
        'title': 'PayStack',
        'icon': 'assets/icons/paystack.png',
        'isVisible':
            walletController.paymentSettingModel.value.payStack?.isEnabled ==
                "true",
      },
      {
        'value': 'FlutterWave',
        'title': 'FlutterWave',
        'icon': 'assets/icons/flutterwave.png',
        'isVisible':
            walletController.paymentSettingModel.value.flutterWave?.isEnabled ==
                "true",
      },
      {
        'value': 'RazorPay',
        'title': 'RazorPay',
        'icon': 'assets/icons/razorpay_@3x.png',
        'isVisible':
            walletController.paymentSettingModel.value.razorpay?.isEnabled ==
                "true",
      },
      {
        'value': 'PayFast',
        'title': 'Pay Fast',
        'icon': 'assets/icons/payfast.png',
        'isVisible':
            walletController.paymentSettingModel.value.payFast?.isEnabled ==
                "true",
      },
      {
        'value': 'MercadoPago',
        'title': 'Mercado Pago',
        'icon': 'assets/icons/mercadopago.png',
        'isVisible':
            walletController.paymentSettingModel.value.mercadopago?.isEnabled ==
                "true",
      },
      {
        'value': 'PayPal',
        'title': 'PayPal',
        'icon': 'assets/icons/paypal_@3x.png',
        'isVisible':
            walletController.paymentSettingModel.value.payPal?.isEnabled ==
                "true",
      },
      {
        'value': 'Xendit',
        'title': 'Xendit',
        'icon': 'assets/icons/xendit.png',
        'isVisible': walletController
                .paymentSettingModel.value.xendit?.isEnabled
                ?.toString() ==
            "true",
      },
    ];

    final visibleMethods =
        paymentMethods.where((method) => method['isVisible'] as bool).toList();

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
        childAspectRatio: 1.5,
      ),
      itemCount: visibleMethods.length,
      itemBuilder: (context, index) {
        final method = visibleMethods[index];
        return _buildPaymentMethodCard(
          context: context,
          isDarkMode: isDarkMode,
          controller: controller,
          value: method['value'] as String,
          title: method['title'] as String,
          iconPath: method['icon'] as String,
          onChanged: () =>
              _setPaymentMethod(controller, method['value'] as String),
        );
      },
    );
  }

  Widget _buildPaymentMethodCard({
    required BuildContext context,
    required bool isDarkMode,
    required WalletController controller,
    required String value,
    required String title,
    required String iconPath,
    required VoidCallback onChanged,
  }) {
    return Obx(() {
      final isSelected = walletController.selectedRadioTile?.value == value;

      return GestureDetector(
        onTap: () {
          onChanged();
          walletController.selectedRadioTile?.value = value;
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isSelected
                ? AppThemeData.primary200.withValues(alpha: 0.1)
                : isDarkMode
                    ? AppThemeData.grey800
                    : Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isSelected
                  ? AppThemeData.primary200
                  : isDarkMode
                      ? AppThemeData.grey800.withValues(alpha: 0.3)
                      : Colors.grey.withValues(alpha: 0.2),
              width: isSelected ? 2 : 1,
            ),
            boxShadow: [
              BoxShadow(
                color: isSelected
                    ? AppThemeData.primary200.withValues(alpha: 0.2)
                    : Colors.black.withValues(alpha: isDarkMode ? 0.2 : 0.05),
                blurRadius: isSelected ? 12 : 8,
                offset: Offset(0, isSelected ? 4 : 2),
              ),
            ],
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Image.asset(
                iconPath,
                height: 32,
                width: 32,
                fit: BoxFit.contain,
              ),
              const SizedBox(height: 8),
              Text(
                title.tr,
                style: TextStyle(
                  color: isSelected
                      ? AppThemeData.primary200
                      : isDarkMode
                          ? AppThemeData.grey900Dark
                          : AppThemeData.grey900,
                  fontSize: 14,
                  fontFamily: AppThemeData.semiBold,
                ),
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      );
    });
  }

  // Keep all existing payment processing methods unchanged
  void _setPaymentMethod(WalletController controller, String method) {
    // Reset all payment methods
    controller.stripe = false.obs;
    controller.razorPay = false.obs;
    controller.paypal = false.obs;
    controller.payStack = false.obs;
    controller.flutterWave = false.obs;
    controller.mercadoPago = false.obs;
    controller.payFast = false.obs;
    controller.xendit = false.obs;
    controller.orangePay = false.obs;
    controller.midtrans = false.obs;

    // Set the selected method
    switch (method) {
      case "Stripe":
        controller.stripe = true.obs;
        break;
      case "PayStack":
        controller.payStack = true.obs;
        break;
      case "FlutterWave":
        controller.flutterWave = true.obs;
        break;
      case "RazorPay":
        controller.razorPay = true.obs;
        break;
      case "PayFast":
        controller.payFast = true.obs;
        break;
      case "MercadoPago":
        controller.mercadoPago = true.obs;
        break;
      case "PayPal":
        controller.paypal = true.obs;
        break;
      case "Xendit":
        controller.xendit = true.obs;
        break;
      case "Orange Pay":
        controller.orangePay = true.obs;
        break;
      case "Midtrans":
        controller.midtrans = true.obs;
        break;
    }
  }

  Future<void> _processPayment(BuildContext context) async {
    if (walletController.selectedRadioTile!.value == "Stripe") {
      Stripe.publishableKey =
          walletController.paymentSettingModel.value.strip?.key ?? '';
      Stripe.merchantIdentifier = 'Cabme';
      await Stripe.instance.applySettings();
      log("Stripe :: publishableKey :: ${walletController.paymentSettingModel.value.strip?.clientpublishableKey ?? ''}");
      log("Stripe :: Secret Key ${walletController.paymentSettingModel.value.strip!.secretKey ?? ''}");
      stripeMakePayment(amount: amountController.text);
    } else if (walletController.selectedRadioTile!.value == "RazorPay") {
      startRazorpayPayment();
    } else if (walletController.selectedRadioTile!.value == "PayPal") {
      paypalPaymentSheet(
          double.parse(amountController.text).toString(), context);
    } else if (walletController.selectedRadioTile!.value == "PayStack") {
      payStackPayment(context);
    } else if (walletController.selectedRadioTile!.value == "FlutterWave") {
      flutterWaveInitiatePayment(
        context: context,
        amount: double.parse(amountController.text).toString(),
        user: walletController.userModel.value,
      );
    } else if (walletController.selectedRadioTile!.value == "PayFast") {
      payFastPayment(context);
    } else if (walletController.selectedRadioTile!.value == "MercadoPago") {
      mercadoPagoMakePayment(
        context: context,
        amount: double.parse(amountController.text).toString(),
        user: walletController.userModel.value,
        controller: walletController,
      );
    } else if (walletController.selectedRadioTile!.value == "Xendit") {
      xenditPayment(
          context, double.parse(amountController.text), walletController);
    } else if (walletController.selectedRadioTile!.value == "Orange Pay") {
      orangeMakePayment(
        amount: double.parse(amountController.text).toStringAsFixed(2),
        context: context,
        controller: walletController,
      );
    } else if (walletController.selectedRadioTile!.value == "Midtrans") {
      midtransMakePayment(
        amount: amountController.text.toString(),
        context: context,
        controller: walletController,
      );
    } else {
      ShowToastDialog.showToast("Please select payment method");
    }
  }

  // ... [Keep all existing payment method implementations exactly as they were]

  ///paypal
  paypalPaymentSheet(String amount, context) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (BuildContext context) => UsePaypal(
            sandboxMode:
                walletController.paymentSettingModel.value.payPal!.isLive ==
                        "true"
                    ? false
                    : true,
            clientId:
                walletController.paymentSettingModel.value.payPal!.appId ?? '',
            secretKey:
                walletController.paymentSettingModel.value.payPal!.secretKey ??
                    '',
            returnURL: "com.parkme://paypalpay",
            cancelURL: "com.parkme://paypalpay",
            transactions: [
              {
                "amount": {
                  "total": amount,
                  "currency": "USD",
                  "details": {"subtotal": amount}
                },
              }
            ],
            note: "Contact us for any questions on your order.",
            onSuccess: (Map params) async {
              walletController.setAmount(amountController.text).then((value) {
                if (value != null) {
                  _refreshAPI();
                  Get.to(const WalletSuccessScreen());
                }
              });
              ShowToastDialog.showToast("Payment Successful!!");
            },
            onError: (error) {
              Get.back();
              Get.back();
              ShowToastDialog.showToast("Payment UnSuccessful!!");
            },
            onCancel: (params) {
              Get.back();
              Get.back();
              ShowToastDialog.showToast("Payment UnSuccessful!!");
            }),
      ),
    );
  }

  /// RazorPay Payment Gateway
  startRazorpayPayment() {
    try {
      walletController
          .createOrderRazorPay(
              amount: double.parse(amountController.text).round())
          .then((value) {
        if (value != null) {
          CreateRazorPayOrderModel result = value;
          openCheckout(
            amount: amountController.text,
            orderId: result.id,
          );
        } else {
          Get.back();
          showSnackBarAlert(
            message: "Something went wrong, please contact admin.".tr,
            color: Colors.red.shade400,
          );
        }
      });
    } catch (e) {
      Get.back();
      showSnackBarAlert(
        message: e.toString(),
        color: Colors.red.shade400,
      );
    }
  }

  void openCheckout({required amount, required orderId}) async {
    var options = {
      'key': walletController.paymentSettingModel.value.razorpay!.key,
      'amount': amount * 100,
      'name': 'Foodies',
      'order_id': orderId,
      "currency": "INR",
      'description': 'wallet Topup',
      'retry': {'enabled': true, 'max_count': 1},
      'send_sms_hash': true,
      'prefill': {'contact': "8888888888", 'email': "demo@demo.com"},
      'external': {
        'wallets': ['paytm']
      }
    };

    try {
      razorPayController.open(options);
    } catch (e) {
      log('Error: $e');
    }
  }

  void _handlePaymentSuccess(PaymentSuccessResponse response) {
    Get.back();
    walletController.setAmount(amountController.text).then((value) {
      if (value != null) {
        _refreshAPI();
        Get.to(const WalletSuccessScreen());
      }
    });
  }

  void _handleExternalWaller(ExternalWalletResponse response) {
    Get.back();
    showSnackBarAlert(
      message: "${"Payment Processing Via".tr}\n${response.walletName!}",
      color: Colors.blue.shade400,
    );
  }

  void _handlePaymentError(PaymentFailureResponse response) {
    Get.back();
    showSnackBarAlert(
      message:
          "${"Payment Failed!!".tr}\n${jsonDecode(response.message!)['error']['description']}",
      color: Colors.red.shade400,
    );
  }

  /// Stripe Payment Gateway
  Map<String, dynamic>? paymentIntentData;

  Future<void> stripeMakePayment({required String amount}) async {
    try {
      paymentIntentData =
          await walletController.createStripeIntent(amount: amount);
      if (paymentIntentData!.containsKey("error")) {
        Get.back();
        showSnackBarAlert(
          message: "Something went wrong, please contact admin.".tr,
          color: Colors.red.shade400,
        );
      } else {
        await Stripe.instance
            .initPaymentSheet(
                paymentSheetParameters: SetupPaymentSheetParameters(
              paymentIntentClientSecret: paymentIntentData!['client_secret'],
              allowsDelayedPaymentMethods: false,
              googlePay: const PaymentSheetGooglePay(
                merchantCountryCode: 'US',
                testEnv: true,
                currencyCode: "USD",
              ),
              customFlow: true,
              style: ThemeMode.system,
              appearance: PaymentSheetAppearance(
                colors: PaymentSheetAppearanceColors(
                  primary: AppThemeData.primary200,
                ),
              ),
              merchantDisplayName: 'Cabme',
            ))
            .then((value) {});
        displayStripePaymentSheet();
      }
    } catch (e, s) {
      showSnackBarAlert(
        message: 'exception:$e \n$s',
        color: Colors.red,
      );
    }
  }

  displayStripePaymentSheet() async {
    try {
      await Stripe.instance.presentPaymentSheet().then((value) {
        Get.back();
        walletController.setAmount(amountController.text).then((value) {
          if (value != null) {
            _refreshAPI();
          }
        });
        paymentIntentData = null;
      });
    } on StripeException catch (e) {
      Get.back();
      var lo1 = jsonEncode(e);
      var lo2 = jsonDecode(lo1);
      StripePayFailedModel lom = StripePayFailedModel.fromJson(lo2);
      showSnackBarAlert(
        message: lom.error.message,
        color: Colors.green,
      );
    } catch (e) {
      Get.back();
      showSnackBarAlert(
        message: e.toString(),
        color: Colors.green,
      );
    }
  }

  ///PayStack Payment Method
  payStackPayment(BuildContext context) async {
    var secretKey = walletController
        .paymentSettingModel.value.payStack!.secretKey
        .toString();
    await walletController
        .payStackURLGen(
      amount: amountController.text,
      secretKey: secretKey,
    )
        .then((value) async {
      if (value != null) {
        PayStackUrlModel payStackModel = value;
        bool isDone = await Get.to(() => PayStackScreen(
              walletController: walletController,
              secretKey: secretKey,
              initialURl: payStackModel.data.authorizationUrl,
              amount: amountController.text,
              reference: payStackModel.data.reference,
              callBackUrl: walletController
                  .paymentSettingModel.value.payStack!.callbackUrl
                  .toString(),
            ));
        Get.back();

        if (isDone) {
          walletController.setAmount(amountController.text).then((value) async {
            if (value != null) {
              await _refreshAPI();
              Get.to(const WalletSuccessScreen());
            }
          });
        } else {
          showSnackBarAlert(
              message: "Payment UnSuccessful!!".tr, color: Colors.red);
        }
      } else {
        showSnackBarAlert(
            message: "Error while transaction!".tr, color: Colors.red);
      }
    });
  }

  showSnackBarAlert({required String message, Color color = Colors.green}) {
    return Get.showSnackbar(GetSnackBar(
      isDismissible: true,
      message: message,
      backgroundColor: color,
      duration: const Duration(seconds: 8),
    ));
  }

  String? _ref;

  setRef() {
    maths.Random numRef = maths.Random();
    int year = DateTime.now().year;
    int refNumber = numRef.nextInt(20000);
    if (Platform.isAndroid) {
      _ref = "AndroidRef$year$refNumber";
    } else if (Platform.isIOS) {
      _ref = "IOSRef$year$refNumber";
    }
  }

  ///FlutterWave Payment Method
  flutterWaveInitiatePayment(
      {required BuildContext context,
      required String amount,
      required UserModel user}) async {
    final url = Uri.parse('https://api.flutterwave.com/v3/payments');
    final headers = {
      'Authorization':
          'Bearer ${walletController.paymentSettingModel.value.flutterWave?.secretKey}',
      'Content-Type': 'application/json',
    };

    final body = jsonEncode({
      "tx_ref": walletController.ref.value,
      "amount": amount,
      "currency": "NGN",
      "redirect_url": "${API.baseUrl}payment/success",
      "payment_options": "ussd, card, barter, payattitude",
      "customer": {
        "email": user.data?.email.toString(),
        "phonenumber": user.data?.phone,
        "name": '${user.data?.prenom} ${user.data?.nom}',
      },
      "customizations": {
        "title": "Payment for Services",
        "description": "Payment for XYZ services",
      }
    });

    final response = await http.post(url, headers: headers, body: body);

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      Get.to(MercadoPagoScreen(initialURl: data['data']['link']))!
          .then((value) async {
        if (value) {
          ShowToastDialog.showToast("Payment Successful!!");
          Get.back();
          await _refreshAPI();
          Get.to(const WalletSuccessScreen());
        } else {
          ShowToastDialog.showToast("Payment UnSuccessful!!");
          Get.back();
        }
      });
    } else {
      print('Payment initialization failed: ${response.body}');
      return null;
    }
  }

  ///payFast
  payFastPayment(context) {
    PayFast? payfast = walletController.paymentSettingModel.value.payFast;
    PayStackURLGen.getPayHTML(
            payFastSettingData: payfast!,
            amount: double.parse(amountController.text.toString())
                .round()
                .toString())
        .then((String? value) async {
      bool isDone = await Get.to(PayFastScreen(
        htmlData: value!,
        payFastSettingData: payfast,
      ));
      if (isDone) {
        Get.back();
        walletController.setAmount(amountController.text).then((value) async {
          if (value != null) {
            await _refreshAPI();
            Get.to(const WalletSuccessScreen());
          }
        });
      } else {
        Get.back();
        showSnackBarAlert(
          message: "Payment UnSuccessful!!".tr,
          color: Colors.red,
        );
      }
    });
  }

  mercadoPagoMakePayment(
      {required BuildContext context,
      required String amount,
      required UserModel user,
      required WalletController controller}) async {
    final headers = {
      'Authorization':
          'Bearer ${controller.paymentSettingModel.value.mercadopago?.accesstoken ?? ''}',
      'Content-Type': 'application/json',
    };

    final body = jsonEncode({
      "items": [
        {
          "title": "Test",
          "description": "Test Payment",
          "quantity": 1,
          "currency_id": "BRL",
          "unit_price": double.parse(amount),
        }
      ],
      "payer": {"email": user.data?.email ?? ''},
      "back_urls": {
        "failure": "${API.baseUrl}payment/failure",
        "pending": "${API.baseUrl}payment/pending",
        "success": "${API.baseUrl}payment/success",
      },
      "auto_return": "approved"
    });

    final response = await http.post(
      Uri.parse("https://api.mercadopago.com/checkout/preferences"),
      headers: headers,
      body: body,
    );

    if (response.statusCode == 200 || response.statusCode == 201) {
      final data = jsonDecode(response.body);
      Get.to(MercadoPagoScreen(
        initialURl: controller
                    .paymentSettingModel.value.mercadopago?.isSandboxEnabled ==
                "false"
            ? data['init_point']
            : data['sandbox_init_point'],
      ))!
          .then((value) async {
        if (value) {
          Get.back();
          ShowToastDialog.showToast("Payment Successful!!");
          await _refreshAPI();
          Get.to(const WalletSuccessScreen());
        } else {
          Get.back();
          ShowToastDialog.showToast("Payment UnSuccessful!!");
        }
      });
    } else {
      log('Error creating preference: ${response.body}');
      return null;
    }
  }

  showLoadingAlert(BuildContext context) {
    return showDialog<void>(
      context: context,
      useRootNavigator: true,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return Container(
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.5),
          ),
          child: Center(
            child: Container(
              margin: const EdgeInsets.all(24),
              padding: const EdgeInsets.all(32),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.2),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          AppThemeData.primary200,
                          AppThemeData.primary200.withValues(alpha: 0.8),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(50),
                    ),
                    child: const CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      strokeWidth: 3,
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'Processing Payment'.tr,
                    style: const TextStyle(
                      fontSize: 20,
                      fontFamily: AppThemeData.bold,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Please wait while we complete your transaction'.tr,
                    style: TextStyle(
                      fontSize: 14,
                      fontFamily: AppThemeData.medium,
                      color: Colors.grey[600],
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  //XenditPayment
  xenditPayment(context, amount, WalletController controller) async {
    await createXenditInvoice(amount: amount, controller: controller)
        .then((model) {
      if (model.id != null) {
        Get.to(() => XenditScreen(
                  initialURl: model.invoiceUrl ?? '',
                  transId: model.id ?? '',
                  apiKey: controller.paymentSettingModel.value.xendit!.key!
                      .toString(),
                ))!
            .then((value) {
          if (value == true) {
            Get.back();
            walletController
                .setAmount(amountController.text)
                .then((value) async {
              if (value != null) {
                await _refreshAPI();
                Get.to(const WalletSuccessScreen());
              }
            });
          } else {
            Get.back();
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(
              content: Text("Payment Unsuccessful!!".tr),
              backgroundColor: Colors.red,
            ));
          }
        });
      }
    });
  }

  Future<XenditModel> createXenditInvoice(
      {required var amount, required WalletController controller}) async {
    const url = 'https://api.xendit.co/v2/invoices';
    var headers = {
      'Content-Type': 'application/json',
      'Authorization': generateBasicAuthHeader(
          controller.paymentSettingModel.value.xendit!.key!.toString()),
    };

    final body = jsonEncode({
      'external_id': DateTime.now().millisecondsSinceEpoch.toString(),
      'amount': amount,
      'payer_email': 'customer@domain.com',
      'description': 'Test - VA Successful invoice payment',
      'currency': 'IDR',
    });

    try {
      final response =
          await http.post(Uri.parse(url), headers: headers, body: body);

      if (response.statusCode == 200 || response.statusCode == 201) {
        XenditModel model = XenditModel.fromJson(jsonDecode(response.body));
        Get.back();
        return model;
      } else {
        Get.back();
        return XenditModel();
      }
    } catch (e) {
      Get.back();
      return XenditModel();
    }
  }

  String generateBasicAuthHeader(String apiKey) {
    String credentials = '$apiKey:';
    String base64Encoded = base64Encode(utf8.encode(credentials));
    return 'Basic $base64Encoded';
  }

  //Orangepay payment
  static String accessToken = '';
  static String payToken = '';
  static String orderId = '';
  static String amount = '';

  orangeMakePayment(
      {required String amount,
      required BuildContext context,
      required WalletController controller}) async {
    reset();

    var paymentURL = await fetchToken(
        context: context,
        orderId: DateTime.now().millisecondsSinceEpoch.toString(),
        amount: amount,
        currency: 'USD',
        controller: controller);

    if (paymentURL.toString() != '') {
      Get.to(() => OrangeMoneyScreen(
                initialURl: paymentURL,
                accessToken: accessToken,
                amount: amount,
                orangePay: controller.paymentSettingModel.value.orangePay!,
                orderId: orderId,
                payToken: payToken,
              ))!
          .then((value) {
        if (value == true) {
          Get.back();
          walletController.setAmount(amountController.text).then((value) async {
            if (value != null) {
              await _refreshAPI();
              Get.to(const WalletSuccessScreen());
            }
          });
        }
      });
    } else {
      Get.back();
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text("Payment Unsuccessful!!".tr),
        backgroundColor: Colors.red,
      ));
    }
  }

  Future fetchToken(
      {required String orderId,
      required String currency,
      required BuildContext context,
      required String amount,
      required WalletController controller}) async {
    String apiUrl = 'https://api.orange.com/oauth/v3/token';
    Map<String, String> requestBody = {
      'grant_type': 'client_credentials',
    };

    var response = await http.post(Uri.parse(apiUrl),
        headers: <String, String>{
          'Authorization':
              "Basic ${controller.paymentSettingModel.value.orangePay!.key!}",
          'Content-Type': 'application/x-www-form-urlencoded',
          'Accept': 'application/json',
        },
        body: requestBody);

    if (response.statusCode == 200) {
      Map<String, dynamic> responseData = jsonDecode(response.body);
      accessToken = responseData['access_token'];
      return await webpayment(
          context: context,
          amountData: amount,
          currency: currency,
          orderIdData: orderId,
          controller: controller);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          backgroundColor: Color(0xff635bff),
          content: Text(
            "Something went wrong, please contact admin.".tr,
            style: TextStyle(fontSize: 17),
          )));
      return '';
    }
  }

  Future webpayment(
      {required String orderIdData,
      required BuildContext context,
      required String currency,
      required String amountData,
      required WalletController controller}) async {
    orderId = orderIdData;
    amount = amountData;
    String apiUrl =
        controller.paymentSettingModel.value.orangePay!.isSandboxEnabled! ==
                "true"
            ? 'https://api.orange.com/orange-money-webpay/dev/v1/webpayment'
            : 'https://api.orange.com/orange-money-webpay/cm/v1/webpayment';
    Map<String, String> requestBody = {
      "merchant_key":
          controller.paymentSettingModel.value.orangePay!.merchantKey ?? '',
      "currency":
          controller.paymentSettingModel.value.orangePay!.isSandboxEnabled ==
                  "true"
              ? "OUV"
              : currency,
      "order_id": orderId,
      "amount": amount,
      "reference": 'Y-Note Test',
      "lang": "en",
      "return_url":
          controller.paymentSettingModel.value.orangePay!.returnUrl!.toString(),
      "cancel_url":
          controller.paymentSettingModel.value.orangePay!.cancelUrl!.toString(),
      "notif_url":
          controller.paymentSettingModel.value.orangePay!.notifUrl!.toString(),
    };

    var response = await http.post(
      Uri.parse(apiUrl),
      headers: <String, String>{
        'Authorization': 'Bearer $accessToken',
        'Content-Type': 'application/json',
        'Accept': 'application/json'
      },
      body: json.encode(requestBody),
    );

    if (response.statusCode == 201) {
      Get.back();
      Map<String, dynamic> responseData = jsonDecode(response.body);
      if (responseData['message'] == 'OK') {
        payToken = responseData['pay_token'];
        return responseData['payment_url'];
      } else {
        return '';
      }
    } else {
      Get.back();
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          backgroundColor: Color(0xff635bff),
          content: Text(
            "Something went wrong, please contact admin.".tr,
            style: TextStyle(fontSize: 17),
          )));
      return '';
    }
  }

  static reset() {
    accessToken = '';
    payToken = '';
    orderId = '';
    amount = '';
  }

  //Midtrans payment
  midtransMakePayment(
      {required String amount,
      required BuildContext context,
      required WalletController controller}) async {
    await createPaymentLink(amount: amount, controller: controller).then((url) {
      if (url != '') {
        Get.to(() => MidtransScreen(
                  initialURl: url,
                ))!
            .then((value) {
          if (value == true) {
            walletController
                .setAmount(amountController.text)
                .then((value) async {
              if (value != null) {
                Get.back();
                await _refreshAPI();
                Get.to(const WalletSuccessScreen());
              }
            });
          } else {
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(
              content: Text("Payment Unsuccessful".tr),
              backgroundColor: Colors.red,
            ));
          }
        });
      }
    });
  }

  Future<String> createPaymentLink(
      {required var amount, required WalletController controller}) async {
    var ordersId = DateTime.now().millisecondsSinceEpoch.toString();
    final url = Uri.parse(controller
                .paymentSettingModel.value.midtrans!.isSandboxEnabled!
                .toString() ==
            "true"
        ? 'https://api.sandbox.midtrans.com/v1/payment-links'
        : 'https://api.midtrans.com/v1/payment-links');

    final response = await http.post(
      url,
      headers: {
        'Accept': 'application/json',
        'Content-Type': 'application/json',
        'Authorization': generateBasicAuthHeader(
            controller.paymentSettingModel.value.midtrans!.key!),
      },
      body: jsonEncode({
        'transaction_details': {
          'order_id': ordersId,
          'gross_amount': double.parse(amount.toString()).toInt(),
        },
        'usage_limit': 2,
        "callbacks": {
          "finish": "https://www.google.com?merchant_order_id=$ordersId"
        },
      }),
    );

    if (response.statusCode == 200 || response.statusCode == 201) {
      final responseData = jsonDecode(response.body);
      Get.back();
      print('Payment link created: ${responseData['payment_url']}');
      return responseData['payment_url'];
    } else {
      Get.back();
      return '';
    }
  }
}
