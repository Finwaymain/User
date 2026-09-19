import 'dart:developer';
import 'dart:io';
import 'package:finway/constant/constant.dart';
import 'package:finway/constant/show_toast_dialog.dart';
import 'package:finway/controller/parcel_service_controller.dart';
import 'package:finway/page/parcel_service_screen/parcel_cart_screen.dart';
import 'package:finway/page/parcel_service_screen/place_picker_osm.dart';
import 'package:finway/page/parcel_service_screen/place_picker_google.dart';
import 'package:finway/themes/appbar_cust.dart';
import 'package:finway/themes/button_them.dart';
import 'package:finway/themes/constant_colors.dart';
import 'package:finway/themes/text_field_them.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import 'package:finway/utils/dark_theme_provider.dart';
import 'package:flutter_svg/svg.dart';
import 'package:provider/provider.dart';

class BookParcelScreen extends StatelessWidget {
  const BookParcelScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final themeChange = Provider.of<DarkThemeProvider>(context);
    bool isDarkMode = themeChange.getThem();
    final Color primary = isDarkMode ? AppThemeData.primary300Dark : AppThemeData.primary300;
    final Color surface = isDarkMode ? AppThemeData.surface50Dark : AppThemeData.surface50;
    final Color borderColor = isDarkMode ? AppThemeData.grey300Dark : AppThemeData.grey300;
    final Color textPrimary = isDarkMode ? AppThemeData.grey900Dark : AppThemeData.grey900;
    final Color textSecondary = isDarkMode ? AppThemeData.grey500Dark : AppThemeData.grey500;

    return GetX<ParcelServiceController>(
        init: ParcelServiceController(),
        builder: (controller) {
          return Scaffold(
            backgroundColor: isDarkMode ? const Color(0xFF121212) : const Color(0xFFF5F7FA),
            appBar: CustomAppbar(
              title: "${"Send".tr} ${controller.selectedParcelCategory.value.title}",
              bgColor: AppThemeData.primary200,
            ),
            body: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ─── Parcel Image Upload Card ───────────────────────────
                  _SectionCard(
                    isDarkMode: isDarkMode,
                    surface: surface,
                    borderColor: borderColor,
                    child: Column(
                      children: [
                        Container(
                          width: 64,
                          height: 64,
                          decoration: BoxDecoration(
                            color: primary.withValues(alpha: 0.12),
                            shape: BoxShape.circle,
                          ),
                          child: Center(
                            child: SvgPicture.asset(
                              'assets/icons/ic_upload_doc.svg',
                              width: 30,
                              height: 30,
                              colorFilter: ColorFilter.mode(primary, BlendMode.srcIn),
                            ),
                          ),
                        ),
                        const SizedBox(height: 14),
                        Text(
                          "Upload Parcel Image".tr,
                          style: TextStyle(
                            fontSize: 16,
                            fontFamily: AppThemeData.semiBold,
                            color: textPrimary,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          "Take a clear picture of your parcel for smooth delivery.".tr,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 12,
                            fontFamily: AppThemeData.regular,
                            color: textSecondary,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          "Max 5MB • JPG, PNG".tr,
                          style: TextStyle(
                            fontSize: 11,
                            fontFamily: AppThemeData.regular,
                            color: textSecondary.withValues(alpha: 0.7),
                          ),
                        ),
                        const SizedBox(height: 16),
                        SizedBox(
                          width: 160,
                          height: 44,
                          child: ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: primary,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                              elevation: 0,
                            ),
                            icon: const Icon(Icons.camera_alt_outlined, size: 18),
                            label: Text(
                              'Click to Upload'.tr,
                              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                            ),
                            onPressed: () => controller.onCameraClick(context),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // ─── Uploaded Images ─────────────────────────────────────
                  if (controller.parcelImages.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    SizedBox(
                      height: 90,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        itemCount: controller.parcelImages.length,
                        itemBuilder: (context, index) {
                          return Padding(
                            padding: const EdgeInsets.only(right: 10),
                            child: Stack(
                              children: [
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(10),
                                  child: Image.file(
                                    File(controller.parcelImages[index].path),
                                    width: 90,
                                    height: 90,
                                    fit: BoxFit.cover,
                                  ),
                                ),
                                Positioned(
                                  top: 4,
                                  right: 4,
                                  child: GestureDetector(
                                    onTap: () => controller.parcelImages.removeAt(index),
                                    child: Container(
                                      decoration: BoxDecoration(
                                        color: Colors.black54,
                                        shape: BoxShape.circle,
                                      ),
                                      padding: const EdgeInsets.all(3),
                                      child: const Icon(Icons.close, color: Colors.white, size: 14),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ),
                  ],

                  const SizedBox(height: 24),

                  // ─── Sender Information ──────────────────────────────────
                  _SectionHeader(
                    icon: Icons.send_rounded,
                    label: "Sender's Information".tr,
                    color: primary,
                    textPrimary: textPrimary,
                  ),
                  const SizedBox(height: 10),
                  _SectionCard(
                    isDarkMode: isDarkMode,
                    surface: surface,
                    borderColor: borderColor,
                    child: Column(
                      children: [
                        // Pickup Location
                        _LocationTile(
                          controller: controller,
                          isDarkMode: isDarkMode,
                          address: controller.senderAddress.toString(),
                          primary: primary,
                          textPrimary: textPrimary,
                          borderColor: borderColor,
                          surface: surface,
                          onTap: () async {
                            if (Constant.selectedMapType == 'osm') {
                              Get.to(() => const LocationPicker())?.then((value) {
                                if (value != null) {
                                  controller.senderAddress.value = value['address'];
                                  controller.senderLocation = LatLng(value['lat'], value['lng']);
                                  controller.senderAddressCity.value = value['city']!;
                                  log("Sender Address :: ${controller.senderAddressCity.value}");
                                }
                              });
                            } else {
                              Get.to(() => const GoogleLocationPicker())?.then((value) {
                                if (value != null) {
                                  controller.senderAddress.value = value['address'];
                                  controller.senderLocation = LatLng(value['lat'], value['lng']);
                                  controller.senderAddressCity.value = value['city']!;
                                  log("Sender Address :: ${controller.senderAddressCity.value}");
                                }
                              });
                            }
                          },
                        ),
                        const SizedBox(height: 10),
                        // Name
                        TextFieldWidget(
                          prefix: Padding(
                            padding: const EdgeInsets.all(12),
                            child: SvgPicture.asset(
                              'assets/icons/ic_user.svg',
                              width: 18,
                              height: 18,
                              colorFilter: ColorFilter.mode(
                                isDarkMode ? AppThemeData.grey500Dark : AppThemeData.grey300Dark,
                                BlendMode.srcIn,
                              ),
                            ),
                          ),
                          controller: controller.sNameController,
                          hintText: 'Full Name'.tr,
                        ),
                        const SizedBox(height: 10),
                        // Phone
                        MobileTextFieldWidget(
                          onChanged: (number) {
                            controller.sPhoneController.value.text = number.completeNumber;
                          },
                          hintText: 'Mobile number'.tr,
                          controller: controller.sPhoneController.value,
                          initialCountryCode: 'IN',
                          countries: const ['IN'],
                        ),
                        const SizedBox(height: 10),
                        // Weight & Dimension Row
                        Row(
                          children: [
                            Expanded(
                              child: TextFieldWidget(
                                textInputType: TextInputType.number,
                                controller: controller.parcelWeightController,
                                hintText: 'Weight'.tr,
                                suffix: Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 14),
                                  child: Text(
                                    'kg',
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontFamily: AppThemeData.semiBold,
                                      color: primary,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: TextFieldWidget(
                                textInputType: TextInputType.number,
                                controller: controller.parcelDimentionController,
                                hintText: 'Dimension'.tr,
                                suffix: Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 14),
                                  child: Text(
                                    'ft',
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontFamily: AppThemeData.semiBold,
                                      color: primary,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        // Note
                        TextFieldWidget(
                          prefix: Padding(
                            padding: const EdgeInsets.all(12),
                            child: Icon(
                              Icons.notes_rounded,
                              size: 18,
                              color: isDarkMode ? AppThemeData.grey500Dark : AppThemeData.grey500,
                            ),
                          ),
                          controller: controller.noteController,
                          hintText: 'Add a note (optional)'.tr,
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  // ─── Receiver Information ────────────────────────────────
                  _SectionHeader(
                    icon: Icons.location_on_rounded,
                    label: "Receiver's Information".tr,
                    color: primary,
                    textPrimary: textPrimary,
                  ),
                  const SizedBox(height: 10),
                  _SectionCard(
                    isDarkMode: isDarkMode,
                    surface: surface,
                    borderColor: borderColor,
                    child: Column(
                      children: [
                        // Drop Location
                        _LocationTile(
                          controller: controller,
                          isDarkMode: isDarkMode,
                          address: controller.receiverAddress.toString(),
                          primary: primary,
                          textPrimary: textPrimary,
                          borderColor: borderColor,
                          surface: surface,
                          onTap: () async {
                            if (Constant.selectedMapType == 'osm') {
                              Get.to(() => const LocationPicker())?.then((value) {
                                if (value != null) {
                                  log("value :: ${value.toString()}");
                                  controller.receiverAddress.value = value['address'];
                                  controller.receiverLocation = LatLng(value['lat'], value['lng']);
                                  controller.receiverAddressCity.value = value['city'];
                                }
                              });
                            } else {
                              Get.to(() => const GoogleLocationPicker())?.then((value) {
                                if (value != null) {
                                  log("value :: ${value.toString()}");
                                  controller.receiverAddress.value = value['address'];
                                  controller.receiverLocation = LatLng(value['lat'], value['lng']);
                                  controller.receiverAddressCity.value = value['city'];
                                }
                              });
                            }
                          },
                        ),
                        const SizedBox(height: 10),
                        // Name
                        TextFieldWidget(
                          prefix: Padding(
                            padding: const EdgeInsets.all(12),
                            child: SvgPicture.asset(
                              'assets/icons/ic_user.svg',
                              width: 18,
                              height: 18,
                              colorFilter: ColorFilter.mode(
                                isDarkMode ? AppThemeData.grey500Dark : AppThemeData.grey300Dark,
                                BlendMode.srcIn,
                              ),
                            ),
                          ),
                          controller: controller.rNameController,
                          hintText: 'Full Name'.tr,
                        ),
                        const SizedBox(height: 10),
                        // Phone
                        MobileTextFieldWidget(
                          onChanged: (number) {
                            controller.rPhoneController.value.text = number.completeNumber;
                          },
                          hintText: 'Mobile number'.tr,
                          controller: controller.rPhoneController.value,
                          initialCountryCode: 'IN',
                          countries: const ['IN'],
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 32),

                  // ─── Continue Button ─────────────────────────────────────
                  ButtonThem.buildButton(
                    context,
                    title: 'Continue'.tr,
                    onPress: () async {
                      final sDigits = controller.sPhoneController.value.text.replaceAll(RegExp(r'\D'), '');
                      final rDigits = controller.rPhoneController.value.text.replaceAll(RegExp(r'\D'), '');
                      bool isValidSender = (sDigits.length == 10) || (sDigits.length == 12 && sDigits.startsWith('91'));
                      bool isValidReceiver = (rDigits.length == 10) || (rDigits.length == 12 && rDigits.startsWith('91'));

                      if (controller.sNameController.value.text.isEmpty) {
                        ShowToastDialog.showToast("Please Enter Sender Name.");
                      } else if (controller.sPhoneController.value.text.isEmpty) {
                        ShowToastDialog.showToast("Please Enter Sender Phone number.");
                      } else if (!isValidSender) {
                        ShowToastDialog.showToast("Please Enter valid 10-digit Indian phone number for Sender.");
                      } else if (controller.parcelWeightController.value.text.isEmpty) {
                        ShowToastDialog.showToast("Please Enter Kg.");
                      } else if (controller.parcelDimentionController.value.text.isEmpty) {
                        ShowToastDialog.showToast("Please Enter ft.");
                      } else if (controller.rNameController.value.text.isEmpty) {
                        ShowToastDialog.showToast("Please Enter Receiver Name.");
                      } else if (controller.rPhoneController.value.text.isEmpty) {
                        ShowToastDialog.showToast("Please Enter Receiver Phone number.");
                      } else if (!isValidReceiver) {
                        ShowToastDialog.showToast("Please Enter valid 10-digit Indian phone number for Receiver.");
                      } else if (controller.parcelImages.isEmpty) {
                        ShowToastDialog.showToast("Select parcel image");
                      } else if (controller.senderLocation == null || controller.receiverLocation == null) {
                        ShowToastDialog.showToast("Please select valid pickup and delivery locations.");
                      } else {
                        final sLat = controller.senderLocation!.latitude;
                        final sLng = controller.senderLocation!.longitude;
                        final rLat = controller.receiverLocation!.latitude;
                        final rLng = controller.receiverLocation!.longitude;
                        final sAddr = controller.senderAddress.value.trim().toLowerCase();
                        final rAddr = controller.receiverAddress.value.trim().toLowerCase();

                        bool isSameLocation = (sLat != 0.0 && rLat != 0.0 && (sLat - rLat).abs() < 0.0001 && (sLng - rLng).abs() < 0.0001) ||
                                              (sAddr.isNotEmpty && rAddr.isNotEmpty && sAddr == rAddr);

                        if (isSameLocation) {
                          ShowToastDialog.showToast("Pickup and Drop location cannot be the same. Please select different locations.");
                          return;
                        }

                        if (Constant.selectedMapType == 'google') {
                          controller.getDurationDistance(controller.senderLocation!, controller.receiverLocation!);
                        } else {
                          controller.getDurationOSMDistance(controller.senderLocation!, controller.receiverLocation!);
                        }
                        Get.to(() => const CartParcelScreen());
                      }
                    },
                  ),

                  const SizedBox(height: 28),
                ],
              ),
            ),
          );
        });
  }
}

// ─── Reusable Section Header ─────────────────────────────────────────────────
class _SectionHeader extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final Color textPrimary;

  const _SectionHeader({
    required this.icon,
    required this.label,
    required this.color,
    required this.textPrimary,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(7),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, size: 18, color: color),
        ),
        const SizedBox(width: 10),
        Text(
          label,
          style: TextStyle(
            fontSize: 16,
            fontFamily: AppThemeData.semiBold,
            color: textPrimary,
          ),
        ),
      ],
    );
  }
}

// ─── Reusable Card Wrapper ────────────────────────────────────────────────────
class _SectionCard extends StatelessWidget {
  final Widget child;
  final bool isDarkMode;
  final Color surface;
  final Color borderColor;

  const _SectionCard({
    required this.child,
    required this.isDarkMode,
    required this.surface,
    required this.borderColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor.withValues(alpha: 0.5), width: 0.8),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDarkMode ? 0.2 : 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: child,
    );
  }
}

// ─── Reusable Location Tile ───────────────────────────────────────────────────
class _LocationTile extends StatelessWidget {
  final ParcelServiceController controller;
  final bool isDarkMode;
  final String address;
  final Color primary;
  final Color textPrimary;
  final Color borderColor;
  final Color surface;
  final VoidCallback onTap;

  const _LocationTile({
    required this.controller,
    required this.isDarkMode,
    required this.address,
    required this.primary,
    required this.textPrimary,
    required this.borderColor,
    required this.surface,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        decoration: BoxDecoration(
          color: primary.withValues(alpha: 0.06),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: primary.withValues(alpha: 0.25), width: 1),
        ),
        child: Row(
          children: [
            Icon(Icons.location_on_rounded, color: primary, size: 20),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                address,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 14,
                  color: textPrimary,
                  fontFamily: AppThemeData.regular,
                ),
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: primary,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                'Change'.tr,
                style: const TextStyle(
                  fontSize: 12,
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
