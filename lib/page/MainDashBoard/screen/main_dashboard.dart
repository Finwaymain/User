import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import '../../../themes/constant_colors.dart';
import 'package:location/location.dart';
import 'package:provider/provider.dart';
import '../../../constant/show_toast_dialog.dart';
import '../../../controller/login_conroller.dart';
import '../../../utils/dark_theme_provider.dart';
import '../../../widget/permission_dialog.dart';
import '../../in_progress_screen.dart';
import '../../features/SmartValue/ScanAndTransfer/view/scanner_and_transfer_screen.dart';
import '../widget/custom_app_bar.dart';
import '../widget/custom_bottom_navbar.dart';
import '../widget/custom_drawer.dart';
import '../../home_screen/view/home_screen.dart';

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


    // Center(child: Text("Search Screen")),
    // Center(child: Text("Fingerprint Screen")),
    // Center(child: Text("Travel Screen")),
    // Center(child: Text("Receipt Screen")),
  ];

  void _onTabSelected(int index) {
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
