

import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:gal/gal.dart';
import 'package:get/get.dart';
import 'package:path_provider/path_provider.dart';
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

  Future<Uint8List?> _captureQrPngBytes() async {
    await Future.delayed(const Duration(milliseconds: 100));

    final boundary = qrKey.currentContext?.findRenderObject() as RenderRepaintBoundary?;
    if (boundary == null) {
      _showErrorSnackbar('Unable to capture QR code');
      return null;
    }

    if (boundary.debugNeedsPaint) {
      await Future.delayed(const Duration(milliseconds: 50));
    }

    final image = await boundary.toImage(pixelRatio: 3.0);
    final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
    final pngBytes = byteData?.buffer.asUint8List();

    if (pngBytes == null) {
      _showErrorSnackbar('Failed to generate QR image');
      return null;
    }

    return pngBytes;
  }

  Future<bool> _ensureGalleryAccess() async {
    if (await Gal.hasAccess(toAlbum: true)) {
      return true;
    }

    final granted = await Gal.requestAccess(toAlbum: true);
    if (granted) {
      return true;
    }

    _showErrorSnackbar('Allow photo access to save QR code to gallery');
    return false;
  }

  // Share QR Code functionality
  Future<void> shareQR() async {
    try {
      isSharing.value = true;
      HapticFeedback.lightImpact();

      final pngBytes = await _captureQrPngBytes();
      if (pngBytes == null) {
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
      await Share.shareXFiles(
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


  Future<void> saveQR() async {
    try {
      isSaving.value = true;
      HapticFeedback.lightImpact();

      final pngBytes = await _captureQrPngBytes();
      if (pngBytes == null) {
        return;
      }

      if (!await _ensureGalleryAccess()) {
        return;
      }

      final fileName = 'Fiinway_QR_${DateTime.now().millisecondsSinceEpoch}';
      await Gal.putImageBytes(pngBytes, name: fileName);

      _showSuccessSnackbar(
        Platform.isIOS ? 'QR code saved to Photos' : 'QR code saved to gallery',
      );
    } on GalException catch (e) {
      print('Save error: $e');
      _showErrorSnackbar(_galleryErrorMessage(e));
    } catch (e) {
      print('Save error: $e');
      _showErrorSnackbar('Failed to save QR code. Please try again.');
    } finally {
      isSaving.value = false;
    }
  }

  String _galleryErrorMessage(GalException e) {
    switch (e.type) {
      case GalExceptionType.accessDenied:
        return 'Photo access denied. Enable it in settings to save QR code.';
      case GalExceptionType.notEnoughSpace:
        return 'Not enough storage space to save QR code.';
      case GalExceptionType.notSupportedFormat:
        return 'Unsupported image format while saving QR code.';
      case GalExceptionType.unexpected:
        return 'Could not save QR code. Please try again.';
    }
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
