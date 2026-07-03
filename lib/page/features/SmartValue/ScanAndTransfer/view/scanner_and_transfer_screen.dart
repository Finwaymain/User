// scanner_controller.dart
import 'package:get/get.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:qr_code_scanner_plus/qr_code_scanner_plus.dart';

import '../../../../../themes/constant_colors.dart';
import '../../../../../utils/dark_theme_provider.dart';
import '../../../../MainDashBoard/screen/main_dashboard.dart';
import '../controller/scanner_controller.dart';


class ScannerAndTransferScreen extends StatelessWidget {
  final GlobalKey qrKey = GlobalKey(debugLabel: 'QR');
  final ScannerController controller = Get.put(ScannerController());

  ScannerAndTransferScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final bottomCardHeight = size.height * 0.35; // 35% of screen height
    final scanArea = size.width * 0.65; // 65% of screen width
    final themeChange = Provider.of<DarkThemeProvider>(context);
    final isDark = themeChange.getThem();
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // Fullscreen Camera
          QRView(
            key: qrKey,
            onQRViewCreated: controller.onQRViewCreated,
            overlay: QrScannerOverlayShape(
              cutOutBottomOffset: bottomCardHeight / 3,
              borderColor: Colors.greenAccent,
              borderRadius: 12,
              borderLength: size.width * 0.08,
              // 8% of screen width
              borderWidth: size.width * 0.013,
              // 1.3% of screen width
              cutOutSize: scanArea,
            ),
            onPermissionSet: (ctrl, p) => _onPermissionSet(context, ctrl, p),
          ),

          // Top Bar
          _buildTopBar(context),

          // Animated scanning line
          Positioned(
            top: (size.height - bottomCardHeight - scanArea) / 1.55,
            left: (size.width - scanArea) / 2,
            child: SizedBox(
              width: scanArea,
              height: scanArea,
              child: AnimatedBuilder(
                animation: controller.animationController,
                builder: (_, __) {
                  final topOffset = controller.animation.value * scanArea;
                  return Stack(
                    children: [
                      Positioned(
                        top: topOffset,
                        child: Container(
                          width: scanArea,
                          height: size.height * 0.004, // 0.4% of screen height
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [
                                Colors.transparent,
                                Colors.greenAccent,
                                Colors.transparent
                              ],
                            ),
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
          ),

          // Scanning status
          _buildScanningStatus(context),

          // Camera controls
          _buildCameraControls(context, bottomCardHeight),

          // Bottom manual input card
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: _buildBottomCard(isDark),
          ),
        ],
      ),
    );
  }

  Widget _buildTopBar(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final topPadding = MediaQuery.of(context).padding.top;

    return Positioned(
      top: topPadding + size.height * 0.01, // 1% of screen height
      left: size.width * 0.04, // 4% of screen width
      right: size.width * 0.04,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Container(
            width: size.width * 0.12, // 12% of screen width
            height: size.width * 0.12,
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.5),
              shape: BoxShape.circle,
            ),
            child: IconButton(
              icon: Icon(
                Icons.arrow_back_ios,
                color: Colors.white,
                size: size.width * 0.05, // 5% of screen width
              ),
              onPressed: () => Get.back(),
            ),
          ),
          Container(
            padding: EdgeInsets.symmetric(
              horizontal: size.width * 0.03, // 3% of screen width
              vertical: size.height * 0.008, // 0.8% of screen height
            ),
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.7),
              borderRadius: BorderRadius.circular(size.width * 0.05),
            ),
            child: Text(
              "Scan to Pay",
              style: TextStyle(
                color: Colors.white,
                fontSize: size.width * 0.04, // 4% of screen width
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          SizedBox(width: size.width * 0.12), // Balance the layout
        ],
      ),
    );
  }

  Widget _buildScanningStatus(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Positioned(
      top: size.height * 0.21, // 21% from top
      left: 0,
      right: 0,
      child: Center(
        child: Obx(() => AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          padding: EdgeInsets.symmetric(
            vertical: size.height * 0.01, // 1% of screen height
            horizontal: size.width * 0.05, // 5% of screen width
          ),
          decoration: BoxDecoration(
            color: controller.isScanning.value
                ? Colors.orange.withValues(alpha: 0.9)
                : Colors.green.withValues(alpha: 0.9),
            borderRadius: BorderRadius.circular(size.width * 0.06),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.3),
                blurRadius: size.width * 0.02,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                controller.isScanning.value
                    ? Icons.qr_code_scanner
                    : Icons.check_circle,
                color: Colors.white,
                size: size.width * 0.05, // 5% of screen width
              ),
              SizedBox(width: size.width * 0.02),
              Text(
                controller.isScanning.value ? "Scanning..." : "Found!",
                style: TextStyle(
                  color: Colors.white,
                  fontSize: size.width * 0.04, // 4% of screen width
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        )),
      ),
    );
  }

  Widget _buildCameraControls(BuildContext context, double bottomCardHeight) {
    final size = MediaQuery.of(context).size;

    return Positioned(
      bottom: bottomCardHeight + size.height * 0.02, // 2% above bottom card
      left: 0,
      right: 0,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          Obx(() => _buildControlButton(
            context,
            icon: controller.isFlashOn.value
                ? Icons.flash_on
                : Icons.flash_off,
            onPressed: controller.toggleFlash,
            backgroundColor: controller.isFlashOn.value
                ? Colors.orange
                : Colors.grey.withValues(alpha: 0.8),
          )),
          _buildControlButton(
            context,
            icon: Icons.cameraswitch,
            onPressed: controller.flipCamera,
          ),
        ],
      ),
    );
  }

  Widget _buildControlButton(BuildContext context,
      {required IconData icon,
        required VoidCallback onPressed,
        Color? backgroundColor}) {
    final size = MediaQuery.of(context).size;

    return Container(
      width: size.width * 0.15, // 15% of screen width
      height: size.width * 0.15,
      decoration: BoxDecoration(
        color: backgroundColor ?? Colors.grey.withValues(alpha: 0.8),
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.3),
            blurRadius: size.width * 0.02,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: IconButton(
        icon: Icon(
          icon,
          color: Colors.white,
          size: size.width * 0.07, // 7% of screen width
        ),
        onPressed: onPressed,
      ),
    );
  }

  Widget _buildBottomCard(bool isDark) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppThemeData.grey800 : Colors.white,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(30),
          topRight: Radius.circular(30),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black26,
            blurRadius: 20,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Handle bar
          Center(
            child: Container(
              width: 50,
              height: 4,
              decoration: BoxDecoration(
                color: isDark ? Colors.grey[700] : Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 20),
          Text(
            "Or Pay Manually",
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : Colors.black87,
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: controller.textController,
            keyboardType: TextInputType.number,
            style: TextStyle(color: isDark ? Colors.white : Colors.black87),
            decoration: InputDecoration(
              floatingLabelBehavior: FloatingLabelBehavior.never,
              labelText: "Mobile Number / Smart Card Number",
              labelStyle: TextStyle(
                  color: isDark ? Colors.grey[400] : Colors.grey[700]),
              hintText: "mobile or card number",
              hintStyle: TextStyle(
                  color: isDark ? Colors.grey[500] : Colors.grey[500]),
              filled: true,
              fillColor: isDark ? Colors.grey[700] : Colors.grey[100],
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(18),
                borderSide: BorderSide.none,
              ),
              prefixIcon: Container(
                margin: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppThemeData.primary200.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(10),
                ),
                child:
                Icon(Icons.phone_android, color: AppThemeData.primary200),
              ),
              suffixIcon: Obx(() => controller.manualInput.value.isNotEmpty
                  ? IconButton(
                icon: const Icon(Icons.clear, color: Colors.grey),
                onPressed: () => controller.textController.clear(),
              )
                  : const SizedBox()),
            ),
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () => controller.processToAmountEntry(),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppThemeData.primary200,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 18),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(18),
                ),
                elevation: 5,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: const [
                  Icon(Icons.arrow_forward, size: 20),
                  SizedBox(width: 10),
                  Text("Continue",
                      style:
                      TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
        ],
      ),
    );
  }

  void _onPermissionSet(BuildContext context, QRViewController ctrl, bool p) {
    if (!p) {
      Get.snackbar(
        'Permission Required',
        'Camera permission is required to scan QR codes',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
        icon: const Icon(Icons.camera_alt, color: Colors.white),
        duration: const Duration(seconds: 3),
      );
    }
  }
}



class PaymentResultScreen extends StatelessWidget {
  final String paymentData;
  final String amount;
  final bool isQRPayment;
  final bool isSuccess;
  final String transactionId;

  const PaymentResultScreen({
    super.key,
    required this.paymentData,
    required this.amount,
    required this.isQRPayment,
    required this.isSuccess,
    required this.transactionId,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Provider.of<DarkThemeProvider>(context).getThem();

    return Scaffold(
      backgroundColor: isDark ? AppThemeData.grey800 : Colors.grey[50],
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Icon
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: isSuccess ? Colors.green[50] : Colors.red[50],
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    isSuccess ? Icons.check_circle : Icons.error,
                    color: isSuccess ? Colors.green : Colors.red,
                    size: 80,
                  ),
                ),

                const SizedBox(height: 30),

                // Status Text
                Text(
                  isSuccess ? 'Payment Successful' : 'Payment Failed',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: isSuccess ? Colors.green : Colors.red,
                  ),
                  textAlign: TextAlign.center,
                ),

                const SizedBox(height: 20),

                // Amount
                Text(
                  '₹ $amount',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w600,
                    color: AppThemeData.primary200,
                  ),
                ),

                const SizedBox(height: 20),

                // Transaction ID
                Column(
                  children: [
                    Text(
                      'Transaction ID:',
                      style: TextStyle(
                        fontSize: 16,
                        color: isDark ? Colors.grey[300] : Colors.grey[700],
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      transactionId,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white : Colors.black87,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),

                const SizedBox(height: 20),

                // Payment Method
                Text(
                  'Payment Type: ${isQRPayment ? "QR Payment" : "Other"}',
                  style: TextStyle(
                    fontSize: 16,
                    color: isDark ? Colors.grey[300] : Colors.grey[700],
                  ),
                  textAlign: TextAlign.center,
                ),

                const SizedBox(height: 40),

                // Back to Home Button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppThemeData.primary200,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 40, vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    onPressed: () {
                      Get.offAll(() => MainDashboard());
                    },
                    child: const Text(
                      'Back to Home',
                      style:
                          TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
