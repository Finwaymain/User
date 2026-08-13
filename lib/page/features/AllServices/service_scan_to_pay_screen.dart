import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:qr_code_scanner_plus/qr_code_scanner_plus.dart';
import 'package:finway/constant/constant.dart';
import 'package:finway/constant/show_toast_dialog.dart';
import 'package:finway/controller/service_booking_controller.dart';
import 'package:finway/themes/constant_colors.dart';

import 'package:finway/utils/mpin_dialog.dart';

class ServiceScanToPayScreen extends StatefulWidget {
  final int bookingId;
  final String expectedDriverId;
  final double amount;
  final ServiceBookingController controller;

  const ServiceScanToPayScreen({
    super.key,
    required this.bookingId,
    required this.expectedDriverId,
    required this.amount,
    required this.controller,
  });

  @override
  State<ServiceScanToPayScreen> createState() => _ServiceScanToPayScreenState();
}

class _ServiceScanToPayScreenState extends State<ServiceScanToPayScreen> {
  final GlobalKey qrKey = GlobalKey(debugLabel: 'QR');
  QRViewController? qrController;
  bool isScanning = true;
  bool isFlashOn = false;

  @override
  void reassemble() {
    super.reassemble();
    if (GetPlatform.isAndroid) {
      qrController?.pauseCamera();
    }
    qrController?.resumeCamera();
  }

  @override
  void dispose() {
    qrController?.dispose();
    super.dispose();
  }

  void _onQRViewCreated(QRViewController controller) {
    qrController = controller;
    controller.scannedDataStream.listen((scanData) async {
      if (!isScanning) return;
      final code = scanData.code;
      if (code == null || code.isEmpty) return;

      setState(() => isScanning = false);
      await qrController?.pauseCamera();

      try {
        final Map<String, dynamic> data = json.decode(code);
        if (data['type'] == 'service_payment' || data['booking_id'] != null) {
          final scannedBookingId = int.tryParse(data['booking_id']?.toString() ?? '');

          if (scannedBookingId == widget.bookingId) {
            // Require MPIN verification before processing wallet payment
            final verified = await showMpinVerificationBottomSheet(
              context,
              amount: widget.amount,
              title: 'Enter MPIN to Confirm Payment'.tr,
              userCat: 'customer',
            );

            if (!verified) {
              ShowToastDialog.showToast('Payment cancelled: MPIN verification failed.'.tr);
              if (mounted) {
                setState(() => isScanning = true);
                await qrController?.resumeCamera();
              }
              return;
            }

            ShowToastDialog.showLoader('Processing wallet payment...'.tr);
            final ok = await widget.controller.payBooking(
              bookingId: widget.bookingId,
              paymentMethod: 'wallet',
            );
            ShowToastDialog.closeLoader();

            if (ok) {
              Get.back(result: true); // return true representing successful payment
              return;
            }
          } else {
            ShowToastDialog.showToast('This QR code is for Booking #${scannedBookingId ?? ''}, but you are paying for Booking #${widget.bookingId}. Please scan the correct QR code.'.tr);
          }
        } else {
          ShowToastDialog.showToast('Invalid QR code format. Please scan the driver\'s wallet QR code.'.tr);
        }
      } catch (e) {
        ShowToastDialog.showToast('Invalid barcode or QR code scanned.'.tr);
      }

      // Resume scanning if payment failed/wrong QR
      if (mounted) {
        setState(() => isScanning = true);
        await qrController?.resumeCamera();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final scanArea = size.width * 0.7;

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close, color: Colors.white),
          onPressed: () => Get.back(result: false),
        ),
        title: Text(
          'Scan Driver QR'.tr,
          style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            icon: Icon(isFlashOn ? Icons.flash_on : Icons.flash_off, color: Colors.white),
            onPressed: () async {
              await qrController?.toggleFlash();
              setState(() {
                isFlashOn = !isFlashOn;
              });
            },
          ),
          IconButton(
            icon: const Icon(Icons.flip_camera_ios, color: Colors.white),
            onPressed: () async {
              await qrController?.flipCamera();
            },
          ),
        ],
      ),
      body: Stack(
        children: [
          QRView(
            key: qrKey,
            onQRViewCreated: _onQRViewCreated,
            overlay: QrScannerOverlayShape(
              borderColor: AppThemeData.primary200,
              borderRadius: 16,
              borderLength: 30,
              borderWidth: 8,
              cutOutSize: scanArea,
            ),
          ),
          Positioned(
            bottom: 40,
            left: 20,
            right: 20,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.75),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.white24),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '${'Pay'.tr} ${Constant.currency ?? ''}${widget.amount.toStringAsFixed(0)} ${'to Driver via Wallet'.tr}',
                    style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Point your camera at the driver\'s QR code displayed on their app screen.'.tr,
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Colors.white70, fontSize: 11),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
