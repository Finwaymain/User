import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../page/MainDashBoard/screen/main_dashboard.dart';

class SignSuccessController extends GetxController {
  @override
  void onInit() {
    super.onInit();
    WidgetsBinding.instance.addPostFrameCallback((_) => redirectScreen());
  }

  redirectScreen() async {
    await Future.delayed(const Duration(seconds: 3));
    Get.offAll(MainDashboard());
    // Get.offAll(TexiDashboard());
  }
}
