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

    // Auto-detect error condition from message content or explicit flag
    bool actualError = isError ||
        lowerMsg.contains("error") ||
        lowerMsg.contains("fail") ||
        lowerMsg.contains("invalid") ||
        lowerMsg.contains("incorrect") ||
        lowerMsg.contains("not found") ||
        lowerMsg.contains("not match") ||
        lowerMsg.contains("denied") ||
        lowerMsg.contains("unauthorized") ||
        lowerMsg.contains("rejected") ||
        lowerMsg.contains("insufficient") ||
        lowerMsg.contains("declined") ||
        lowerMsg.contains("expire") ||
        lowerMsg.contains("cancel") ||
        lowerMsg.contains("already exist") ||
        lowerMsg.contains("wrong") ||
        lowerMsg.contains("blocked") ||
        lowerMsg.contains("unable") ||
        lowerMsg.contains("timeout") ||
        lowerMsg.contains("could not") ||
        lowerMsg.contains("required") ||
        lowerMsg.contains("please enter") ||
        lowerMsg.contains("please select") ||
        lowerMsg.contains("something went wrong") ||
        lowerMsg.contains("something want wrong");

    bool actualWarning = isWarning ||
        (!actualError && (lowerMsg.contains("warning") || lowerMsg.contains("caution") || lowerMsg.contains("alert") || lowerMsg.contains("attention") || lowerMsg.contains("pending")));

    Get.snackbar(
      actualError
          ? "Error".tr
          : actualWarning
          ? "Warning".tr
          : "Success".tr,
      msg.tr,
      snackPosition: SnackPosition.TOP,
      backgroundColor: actualError
          ? Colors.redAccent.shade700
          : actualWarning
          ? Colors.amber.shade700
          : Colors.green.shade600,
      colorText: Colors.white,
      icon: Icon(
        actualError
            ? Icons.error_outline_rounded
            : actualWarning
            ? Icons.warning_amber_rounded
            : Icons.check_circle_outline_rounded,
        color: Colors.white,
      ),
      margin: const EdgeInsets.all(12),
      borderRadius: 10,
      duration: const Duration(seconds: 3),
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
