import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:provider/provider.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../../../../../themes/constant_colors.dart';
import '../../../../../utils/dark_theme_provider.dart';
import '../controller/qr_controller.dart';

class MyQRScreen extends StatelessWidget {
  const MyQRScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(QRController());
    final themeChange = Provider.of<DarkThemeProvider>(context);
    final isDark = themeChange.getThem();
    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text(
          "My QR Code",
          style: TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 20,
          ),
        ),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: Container(
          margin: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: isDark
                ? Colors.black.withValues(alpha: 0.3)
                : Colors.white.withValues(alpha: 0.3),
            borderRadius: BorderRadius.circular(12),
          ),
          child: IconButton(
            onPressed: controller.goBack,
            icon: const Icon(Icons.arrow_back_ios_new, size: 20),
            style: IconButton.styleFrom(
              padding: EdgeInsets.zero,
            ),
          ),
        ),
        actions: [
          // Copy QR data button
          Container(
            margin: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: isDark
                  ? Colors.black.withValues(alpha: 0.3)
                  : Colors.white.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(12),
            ),
            child: IconButton(
              onPressed: () async {
                // Show loading state briefly
                HapticFeedback.lightImpact();
                await controller.copyQRData();
              },
              icon: const Icon(Icons.copy, size: 20),
              style: IconButton.styleFrom(
                padding: EdgeInsets.zero,
              ),
              tooltip: 'Copy QR Data',
            ),
          ),
        ],
      ),
      body: Container(
        height: screenHeight,
        width: screenWidth,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: isDark
                ? [
                    const Color(0xFF0d2818),
                    const Color(0xFF1a3d2e),
                    const Color(0xFF2d5a3d),
                  ]
                : [
                    AppThemeData.primary200.withValues(alpha: 0.6),
                    AppThemeData.primary200.withValues(alpha: 0.8),
                    AppThemeData.primary200.withValues(alpha: 0.4),
                  ],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Main QR Container
                ScaleTransition(
                  scale: controller.scaleAnimation,
                  child: AnimatedBuilder(
                    animation: controller.pulseAnimation,
                    builder: (context, child) {
                      return RepaintBoundary(
                        key: controller.qrKey,
                        child: Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(32),
                            boxShadow: [
                              BoxShadow(
                                color: isDark
                                    ? AppThemeData.primary200.withValues(alpha: 0.3 +
                                        controller.pulseAnimation.value * 0.2)
                                    : Colors.white.withValues(alpha: 0.4 +
                                        controller.pulseAnimation.value * 0.3),
                                blurRadius:
                                    30 + controller.pulseAnimation.value * 10,
                                offset: const Offset(0, 10),
                              ),
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.1),
                                blurRadius: 20,
                                offset: const Offset(0, 5),
                              ),
                            ],
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(32),
                            child: BackdropFilter(
                              filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                              child: Container(
                                padding: const EdgeInsets.all(32),
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                    colors: isDark
                                        ? [
                                            Colors.white.withValues(alpha: 0.1),
                                            Colors.white.withValues(alpha: 0.05),
                                          ]
                                        : [
                                            Colors.white.withValues(alpha: 0.9),
                                            Colors.white.withValues(alpha: 0.7),
                                          ],
                                  ),
                                  border: Border.all(
                                    color: Colors.white.withValues(alpha: 0.2),
                                    width: 1.5,
                                  ),
                                  borderRadius: BorderRadius.circular(32),
                                ),
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    // QR Code with animated border
                                    Container(
                                      padding: const EdgeInsets.all(20),
                                      decoration: BoxDecoration(
                                        color: Colors.white,
                                        borderRadius: BorderRadius.circular(20),
                                        border: Border.all(
                                          color: AppThemeData.primary200,
                                          width: 2,
                                        ),
                                        boxShadow: [
                                          BoxShadow(
                                            color: AppThemeData.primary200
                                                .withValues(alpha: 0.3),
                                            blurRadius: 15,
                                            offset: const Offset(0, 5),
                                          ),
                                        ],
                                      ),
                                      child: controller.qrData.isNotEmpty
                                          ? QrImageView(
                                              data: controller.qrData,
                                              version: QrVersions.auto,
                                              size: 220,
                                              gapless: false,
                                              foregroundColor: Colors.black,
                                              backgroundColor: Colors.white,
                                              eyeStyle: const QrEyeStyle(
                                                eyeShape: QrEyeShape.circle,
                                                color: Colors.black,
                                              ),
                                              dataModuleStyle:
                                                  const QrDataModuleStyle(
                                                dataModuleShape:
                                                    QrDataModuleShape.circle,
                                                color: Colors.black,
                                              ),
                                            )
                                          : Container(
                                              width: 220,
                                              height: 220,
                                              decoration: BoxDecoration(
                                                color: Colors.grey[200],
                                                borderRadius:
                                                    BorderRadius.circular(12),
                                              ),
                                              child: const Center(
                                                child: Text(
                                                  'No QR Data',
                                                  style: TextStyle(
                                                    color: Colors.grey,
                                                    fontSize: 16,
                                                  ),
                                                ),
                                              ),
                                            ),
                                    ),

                                    const SizedBox(height: 24),

                                    // Title text
                                    Text(
                                      "Scan to Connect",
                                      style: TextStyle(
                                        fontSize: 22,
                                        fontWeight: FontWeight.bold,
                                        color: isDark
                                            ? Colors.white
                                            : Colors.black87,
                                        letterSpacing: 0.5,
                                      ),
                                    ),

                                    const SizedBox(height: 8),

                                    // Subtitle text
                                    Text(
                                      "Point your camera at this QR code\nto share your profile instantly",
                                      style: TextStyle(
                                        fontSize: 15,
                                        color: isDark
                                            ? Colors.white70
                                            : Colors.black54,
                                        height: 1.4,
                                      ),
                                      textAlign: TextAlign.center,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),

                const SizedBox(height: 50),

                // Action buttons with fade animation
                FadeTransition(
                  opacity: controller.fadeAnimation,
                  child: Row(
                    children: [
                      // Share button
                      Expanded(
                        child: Obx(() => Container(
                              height: 56,
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [
                                    AppThemeData.primary200,
                                    AppThemeData.primary200.withValues(alpha: 0.7)
                                  ],
                                ),
                                borderRadius: BorderRadius.circular(16),
                                boxShadow: [
                                  BoxShadow(
                                    color: AppThemeData.primary200
                                        .withValues(alpha: 0.3),
                                    blurRadius: 15,
                                    offset: const Offset(0, 8),
                                  ),
                                ],
                              ),
                              child: ElevatedButton.icon(
                                onPressed: controller.isSharing.value
                                    ? null
                                    : controller.shareQR,
                                icon: controller.isSharing.value
                                    ? const SizedBox(
                                        width: 20,
                                        height: 20,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          valueColor:
                                              AlwaysStoppedAnimation<Color>(
                                                  Colors.white),
                                        ),
                                      )
                                    : const Icon(Icons.share, size: 20),
                                label: Text(
                                  controller.isSharing.value
                                      ? "Sharing..."
                                      : "Share",
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.transparent,
                                  foregroundColor: Colors.white,
                                  shadowColor: Colors.transparent,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                ),
                              ),
                            )),
                      ),

                      const SizedBox(width: 16),

                      // Save button
                      Expanded(
                        child: Obx(() => Container(
                              height: 56,
                              decoration: BoxDecoration(
                                color: isDark
                                    ? Colors.white.withValues(alpha: 0.1)
                                    : Colors.white.withValues(alpha: 0.9),
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color: Colors.white.withValues(alpha: 0.3),
                                  width: 1.5,
                                ),
                              ),
                              child: ElevatedButton.icon(
                                onPressed: controller.isSaving.value
                                    ? null
                                    : controller.saveQR,
                                icon: controller.isSaving.value
                                    ? SizedBox(
                                        width: 20,
                                        height: 20,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          valueColor:
                                              AlwaysStoppedAnimation<Color>(
                                            isDark
                                                ? Colors.white
                                                : Colors.black87,
                                          ),
                                        ),
                                      )
                                    : Icon(
                                        Icons.download,
                                        size: 20,
                                        color: isDark
                                            ? Colors.white
                                            : Colors.black87,
                                      ),
                                label: Text(
                                  controller.isSaving.value
                                      ? "Saving..."
                                      : "Save",
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                    color:
                                        isDark ? Colors.white : Colors.black87,
                                  ),
                                ),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.transparent,
                                  shadowColor: Colors.transparent,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                ),
                              ),
                            )),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 20),

                // Back button with modern design
                FadeTransition(
                  opacity: controller.fadeAnimation,
                  child: TextButton(
                    onPressed: controller.goBack,
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 12,
                      ),
                    ),
                    child: Text(
                      "Back to Profile",
                      style: TextStyle(
                        fontSize: 16,
                        color: isDark ? Colors.white70 : Colors.white,
                        fontWeight: FontWeight.w500,
                      ),
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
