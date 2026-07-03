

import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:share_plus/share_plus.dart';

import '../../../../../constant/constant.dart';
import '../../../../../themes/constant_colors.dart';

class QRController extends GetxController with GetTickerProviderStateMixin {
  // Animation Controllers
  late AnimationController scaleController;
  late AnimationController pulseController;
  late AnimationController fadeController;

  // Animations
  late Animation<double> scaleAnimation;
  late Animation<double> pulseAnimation;
  late Animation<double> fadeAnimation;

  // Loading states
  var isSharing = false.obs;
  var isSaving = false.obs;

  // Global key for capturing QR widget
  GlobalKey qrKey = GlobalKey();

  // QR Data
  String qrData = '';

  @override
  void onInit() {
    super.onInit();
    qrData = "${Constant.getUserData().data?.acNo}";

    // Get QR data from arguments with better handling
    final args = Get.arguments;
    if (args != null && args is Map) {
      qrData = args['qrData']?.toString() ?? '';
    }

    // Debug print to check QR data
    print('QR Data received: "$qrData"'); // Debug print

    if (qrData.isEmpty) {
      print('Warning: QR data is empty!'); // Debug print

    }

    _initializeAnimations();
    _startAnimations();
  }

  void _initializeAnimations() {
    scaleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );

    pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    );

    fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );

    scaleAnimation = CurvedAnimation(
      parent: scaleController,
      curve: Curves.elasticOut,
    );

    pulseAnimation = CurvedAnimation(
      parent: pulseController,
      curve: Curves.easeInOut,
    );

    fadeAnimation = CurvedAnimation(
      parent: fadeController,
      curve: Curves.easeOut,
    );
  }

  void _startAnimations() {
    scaleController.forward();
    Future.delayed(const Duration(milliseconds: 300), () {
      fadeController.forward();
    });
    Future.delayed(const Duration(milliseconds: 1000), () {
      pulseController.repeat(reverse: true);
    });
  }

  // Share QR Code functionality
  Future<void> shareQR() async {
    try {
      isSharing.value = true;
      HapticFeedback.lightImpact();

      // Wait a frame to ensure UI is updated
      await Future.delayed(const Duration(milliseconds: 100));

      // Capture QR widget as image
      final boundary = qrKey.currentContext?.findRenderObject() as RenderRepaintBoundary?;
      if (boundary == null) {
        _showErrorSnackbar('Unable to capture QR code');
        return;
      }

      final image = await boundary.toImage(pixelRatio: 3.0);
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      final pngBytes = byteData?.buffer.asUint8List();

      if (pngBytes == null) {
        _showErrorSnackbar('Failed to generate QR image');
        return;
      }

      // Save to temporary directory
      final tempDir = await getTemporaryDirectory();
      final fileName = 'qr_code_${DateTime.now().millisecondsSinceEpoch}.png';
      final file = File('${tempDir.path}/$fileName');
      await file.writeAsBytes(pngBytes);

      // Verify file was created
      if (!await file.exists()) {
        _showErrorSnackbar('Failed to create temporary file');
        return;
      }

      // Share the file
      final result = await Share.shareXFiles(
        [XFile(file.path)],
        text: 'Scan this QR code to connect with me!',
        subject: 'My QR Code',
      );

      _showSuccessSnackbar('QR code shared successfully!');
    } catch (e) {
      print('Share error: $e'); // Debug print
      _showErrorSnackbar('Failed to share QR code: ${e.toString()}');
    } finally {
      isSharing.value = false;
    }
  }

  // Copy QR data to clipboard
  Future<void> copyQRData() async {
    try {
      HapticFeedback.lightImpact();

      // Check if QR data is available
      if (qrData.isEmpty) {
        _showErrorSnackbar('No QR data available to copy');
        return;
      }

      // Copy to clipboard
      await Clipboard.setData(ClipboardData(text: qrData));

      // Verify clipboard data
      final clipboardData = await Clipboard.getData(Clipboard.kTextPlain);
      if (clipboardData?.text == qrData) {
        _showSuccessSnackbar('QR data copied to clipboard!\n"${qrData.length > 50 ? '${qrData.substring(0, 50)}...' : qrData}"');
      } else {
        _showErrorSnackbar('Failed to verify clipboard data');
      }

    } catch (e) {
      print('Clipboard error: $e'); // Debug print
      _showErrorSnackbar('Failed to copy QR data: ${e.toString()}');
    }
  }


  // Replace your saveQR() method with this simpler version
  Future<void> saveQR() async {
    try {
      isSaving.value = true;
      HapticFeedback.lightImpact();

      await Future.delayed(const Duration(milliseconds: 100));

      // Capture QR widget as image
      final boundary = qrKey.currentContext?.findRenderObject() as RenderRepaintBoundary?;
      if (boundary == null) {
        _showErrorSnackbar('Unable to capture QR code');
        return;
      }

      final image = await boundary.toImage(pixelRatio: 3.0);
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      final pngBytes = byteData?.buffer.asUint8List();

      if (pngBytes == null) {
        _showErrorSnackbar('Failed to generate QR image');
        return;
      }

      // Request permission first
      final hasPermission = await _requestBasicStoragePermission();
      if (!hasPermission) {
        _showErrorSnackbar('Storage permission required to save QR code');
        return;
      }

      // Save to Downloads folder (Android) or Documents (iOS)
      Directory? directory;
      String folderName = '';

      if (Platform.isAndroid) {
        // Try to save to Downloads folder
        directory = Directory('/storage/emulated/0/Download');
        folderName = 'Downloads';

        // If Downloads doesn't exist or is not accessible, use app directory
        if (!await directory.exists()) {
          directory = await getExternalStorageDirectory();
          folderName = 'App Storage';
        }
      } else {
        // iOS - use Documents directory
        directory = await getApplicationDocumentsDirectory();
        folderName = 'Documents';
      }

      if (directory == null) {
        _showErrorSnackbar('Unable to access storage directory');
        return;
      }

      // Create QR_Codes subfolder
      final qrCodesDir = Directory('${directory.path}/QR_Codes');
      await qrCodesDir.create(recursive: true);

      // Save file
      final fileName = 'QR_Code_${DateTime.now().millisecondsSinceEpoch}.png';
      final file = File('${qrCodesDir.path}/$fileName');

      await file.writeAsBytes(pngBytes);

      // Verify file was saved
      if (await file.exists()) {
        final fileSize = await file.length();
        _showSuccessSnackbar(
            'QR saved successfully!\n'
                'Location: $folderName/QR_Codes/\n'
                'Size: ${(fileSize / 1024).toStringAsFixed(1)} KB'
        );
      } else {
        _showErrorSnackbar('Failed to save QR code');
      }

    } catch (e) {
      print('Save error: $e');
      _showErrorSnackbar('Error saving QR: ${e.toString()}');
    } finally {
      isSaving.value = false;
    }
  }

// Simplified permission request
  Future<bool> _requestBasicStoragePermission() async {
    if (Platform.isAndroid) {
      try {
        final status = await Permission.storage.request();
        return status.isGranted;
      } catch (e) {
        print('Permission error: $e');
        return false;
      }
    }
    return true; // iOS doesn't need permission for app documents
  }




  // Navigate back
  void goBack() {
    HapticFeedback.lightImpact();
    Get.back();
  }

  // Show success snackbar
  void _showSuccessSnackbar(String message) {
    Get.snackbar(
      'Success',
      message,
      backgroundColor: AppThemeData.primary200.withValues(alpha: 0.9),
      colorText: Colors.white,
      snackPosition: SnackPosition.BOTTOM,
      duration: const Duration(seconds: 2),
      margin: const EdgeInsets.all(16),
      borderRadius: 12,
      icon: const Icon(Icons.check_circle, color: Colors.white),
    );
  }

  // Show error snackbar
  void _showErrorSnackbar(String message) {
    Get.snackbar(
      'Error',
      message,
      backgroundColor: Colors.red.withValues(alpha: 0.9),
      colorText: Colors.white,
      snackPosition: SnackPosition.BOTTOM,
      duration: const Duration(seconds: 3),
      margin: const EdgeInsets.all(16),
      borderRadius: 12,
      icon: const Icon(Icons.error, color: Colors.white),
    );
  }

  @override
  void onClose() {
    scaleController.dispose();
    pulseController.dispose();
    fadeController.dispose();
    super.onClose();
  }
}
