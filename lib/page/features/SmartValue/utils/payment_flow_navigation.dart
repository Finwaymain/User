import 'package:flutter/widgets.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:get/get.dart';

import '../../../../constant/show_toast_dialog.dart';
import '../../../../controller/dash_board_controller.dart';
import '../../../MainDashBoard/screen/main_dashboard.dart';
import '../AmountEntryScreen/controller/amount_entry_controller.dart';
import '../PinEntryScreen/controller/pin_entry_controller.dart';
import '../ScanAndTransfer/controller/scanner_controller.dart';

class PaymentFlowNavigation {
  static void finishAndGoHome() {
    ShowToastDialog.closeLoader();
    EasyLoading.dismiss();

    final navigator = Get.key.currentState;
    if (navigator != null && navigator.canPop()) {
      Get.until((route) => route.isFirst);
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _cleanupPaymentControllers();
        _refreshDashboardData();
      });
      return;
    }

    _cleanupPaymentControllers();
    Get.offAll(() => const MainDashboard());
  }

  static void _refreshDashboardData() {
    if (Get.isRegistered<DashBoardController>()) {
      Get.find<DashBoardController>().getUsrData();
    }
  }

  static void _cleanupPaymentControllers() {
    _safeDelete<PinEntryController>();
    _safeDelete<AmountEntryController>();
    _safeDelete<ScannerController>();
  }

  static void _safeDelete<T>() {
    if (Get.isRegistered<T>()) {
      Get.delete<T>(force: true);
    }
  }
}
