import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../themes/constant_colors.dart';
import 'package:provider/provider.dart';
import '../../../controller/login_conroller.dart';
import '../../../utils/dark_theme_provider.dart';
import '../../../widget/permission_dialog.dart';
import '../../in_progress_screen.dart';
import '../../features/SmartValue/ScanAndTransfer/view/scanner_and_transfer_screen.dart';
import '../widget/custom_app_bar.dart';
import '../widget/custom_bottom_navbar.dart';
import '../widget/custom_drawer.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../../utils/Preferences.dart';
import '../../../service/api.dart';
import '../../../model/ride_model.dart';
import '../../../constant/constant.dart';
import '../../new_ride_screens/searching_driver_screen.dart';
import '../../route_view_screen/route_view_screen.dart';
import '../../route_view_screen/route_osm_view_screen.dart';
import '../../home_screen/view/home_screen.dart';
import '../../wallet/wallet_screen.dart';

class MainDashboard extends StatefulWidget {
  const MainDashboard({super.key});

  @override
  State<MainDashboard> createState() => _MainDashboardState();
}

class _MainDashboardState extends State<MainDashboard> {
  int currentIndex = 0;

  final List<Widget> _screens =  [
    MainHomeScreen(),
    InProgressScreen(),
    InProgressScreen(),
    InProgressScreen(),
    InProgressScreen(),
    // Center(child: Text("Fingerprint Screen")),
    // Center(child: Text("Travel Screen")),
    // Center(child: Text("Receipt Screen")),
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkActiveRideAndRedirect();
    });
  }

  Future<void> _checkActiveRideAndRedirect() async {
    try {
      if (!Preferences.getBoolean(Preferences.isLogin)) return;
      final userId = Preferences.getInt(Preferences.userId);
      final response = await http.get(
        Uri.parse('${API.newRide}?id_user_app=$userId'),
        headers: API.header,
      ).timeout(const Duration(seconds: 10));
      if (response.statusCode == 200) {
        final body = json.decode(response.body);
        if (body['success'] == 'success' && body['data'] != null) {
          final rides = (body['data'] as List)
              .map((e) => RideData.fromJson(e as Map<String, dynamic>))
              .where((r) =>
                  r.statut == 'confirmed' ||
                  r.statut == 'on ride' ||
                  r.statut == 'new')
              .toList();

          if (rides.isNotEmpty && mounted) {
            final activeRide = rides.first;
            if (activeRide.statut == 'new') {
              Get.offAll(() => const SearchingDriverScreen(), arguments: {
                'rideData': activeRide,
              });
            } else {
              var argumentData = {'type': activeRide.statut, 'data': activeRide};
              if (Constant.selectedMapType == 'osm') {
                Get.offAll(() => RouteOsmViewScreen(), arguments: argumentData);
              } else {
                Get.offAll(() => RouteViewScreen(), arguments: argumentData);
              }
            }
          }
        }
      }
    } catch (e) {
      debugPrint('MainDashboard check active ride error: $e');
    }
  }

  void _onTabSelected(int index) {
    if (index == 4) {
      Get.to(() => WalletScreen());
      return;
    }
    setState(() => currentIndex = index);
  }

  void _onFingerprintTap() {
    Get.to(
      () =>  ScannerAndTransferScreen(),
      transition: Transition.rightToLeft,
      duration: const Duration(milliseconds: 500),
    );
  }

  @override
  Widget build(BuildContext context) {
    final themeChange = Provider.of<DarkThemeProvider>(context);
    bool isDarkMode = themeChange.getThem();
    return GetBuilder(
        init: LoginController(),
        initState: (state) async {
        },
        builder: (controller) {
          return Scaffold(
            backgroundColor: isDarkMode ? AppThemeData.surface50Dark : AppThemeData.surface50,
            appBar: CustomAppBar(),
            drawer:  CustomDrawer(
            ),
            body: Stack(
              children: [
                Positioned.fill(
                  child: IndexedStack(
                    index: currentIndex,
                    children: _screens,
                  ),
                ),
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: 0,
                  child: CustomBottomNavBar(
                    currentIndex: currentIndex,
                    onTabSelected: _onTabSelected,
                    onFingerprintTap: _onFingerprintTap,
                  ),
                ),
              ],
            ),
          );
        });
  }

  void showDialogPermission(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => const LocationPermissionDisclosureDialog(),
    );
  }
}
