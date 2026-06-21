import 'package:flutter/material.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:get/get.dart';

class ShowToastDialog {
  static showToast(
      String? message, {
        bool isError = false,
        bool isWarning = false,
      }) {
    if (message == null) return;
    String msg = message.trim();
    if (msg.isEmpty || msg.toLowerCase() == "null") return;

    // Block internal dev exceptions from reaching users
    String lowerMsg = msg.toLowerCase();
    if (lowerMsg.contains("failed to load album") ||
        lowerMsg.contains("null check operator") ||
        lowerMsg.contains("exception:") ||
        lowerMsg.contains("is not a subtype") ||
        lowerMsg.contains("bad state") ||
        lowerMsg.contains("no element") ||
        lowerMsg.contains("nosuchmethoderror") ||
        lowerMsg.contains("rangeerror") ||
        lowerMsg.contains("formatexception") ||
        lowerMsg.contains("index out of range") ||
        lowerMsg.contains("unexpected character") ||
        lowerMsg.contains("type 'null'")) {
      debugPrint("Silent Toast Blocked: $msg");
      return;
    }

    Get.snackbar(
      isError
          ? "Error"
          : isWarning
          ? "Warning"
          : "Success",
      msg,
      snackPosition: SnackPosition.TOP,
      backgroundColor: isError
          ? Colors.redAccent
          : isWarning
          ? Colors.amber
          : Colors.green,
      colorText: Colors.white,
      margin: const EdgeInsets.all(12),
      borderRadius: 8,
      duration: const Duration(seconds: 2),
    );
  }

  static showLoader(String message) {
    EasyLoading.show(
      status: message.tr,
      dismissOnTap: false,
      maskType: EasyLoadingMaskType.clear,
    );
  }

  static closeLoader() {
    EasyLoading.dismiss();
  }
}
