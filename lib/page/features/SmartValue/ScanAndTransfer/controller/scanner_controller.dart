import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:qr_code_scanner_plus/qr_code_scanner_plus.dart';
import 'dart:async';
import 'dart:convert';

import '../../../../../constant/show_toast_dialog.dart';
import '../../AmountEntryScreen/view/amount_entry_screen.dart';

class ScannerController extends GetxController
    with SingleGetTickerProviderMixin {
  // Observable variables
  RxBool isScanning = true.obs;
  RxBool isFlashOn = false.obs;
  RxBool isLoading = false.obs;
  RxString scannedData = ''.obs;
  RxString manualInput = ''.obs;

  // QR Controller
  QRViewController? qrController;
  Barcode? result;

  // Animation Controller
  late AnimationController animationController;
  late Animation<double> animation;

  // Text Controller for manual input
  final TextEditingController textController = TextEditingController();

  @override
  void onInit() {
    super.onInit();
    setupAnimation();

    // Listen to text changes
    textController.addListener(() {
      manualInput.value = textController.text;
    });
  }

  void setupAnimation() {
    animationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
    animation =
        Tween<double>(begin: 0.0, end: 1.0).animate(animationController);
  }

  @override
  void onClose() {
    qrController?.dispose();
    animationController.dispose();
    textController.dispose();
    super.onClose();
  }

  void onQRViewCreated(QRViewController controller) {
    qrController = controller;
    controller.scannedDataStream.listen((scanData) async {
      if (result == null && isScanning.value) {
        result = scanData;
        scannedData.value = scanData.code ?? '';
        isScanning.value = false;
        await controller.pauseCamera();

        // Navigate to amount entry screen with scanned data
        await processToAmountEntry(isQRScanned: true);
      }
    });
  }

  Future<void> toggleFlash() async {
    await qrController?.toggleFlash();
    isFlashOn.toggle();
  }

  Future<void> flipCamera() async {
    await qrController?.flipCamera();
  }

  Future<void> resumeCamera() async {
    await qrController?.resumeCamera();
    isScanning.value = true;
    result = null;
    scannedData.value = '';
  }

  Future<void> pauseCamera() async {
    await qrController?.pauseCamera();
  }

  // Navigate to amount entry with payment data
  Future<void> processToAmountEntry({bool isQRScanned = false}) async {
    String paymentData = isQRScanned ? scannedData.value : manualInput.value.trim();
    String? amountValue;

    try {
      var decoded = jsonDecode(paymentData);
      if (decoded is Map) {
        paymentData = decoded['ac_no']?.toString() ?? paymentData;
        amountValue = decoded['amount']?.toString();
      }
    } catch (e) {
      // Not JSON, leave as is
    }

    if (paymentData.isEmpty) {
      ShowToastDialog.showToast('Please enter a valid number or scan QR code');
      return;
    }

    // Navigate to amount entry screen
    // The API call will be handled in AmountEntryController
    Get.back(); // Go back from scanner screen
    Get.to(() => AmountEntryScreen(isQRPayment: true),
        arguments: {'paymentData': paymentData, 'amount': amountValue});
  }
}