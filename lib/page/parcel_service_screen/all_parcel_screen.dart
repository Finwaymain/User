import 'dart:developer';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:finway/constant/constant.dart';
import 'package:finway/constant/image_constant.dart';
import 'package:finway/constant/show_toast_dialog.dart';
import 'package:finway/controller/parcel_order_controller.dart';
import 'package:finway/model/parcel_model.dart';
import 'package:finway/page/features/Texi/texi_dash_board.dart';
import 'package:finway/page/parcel_service_screen/parcel_details_screen.dart';
import 'package:finway/themes/appbar_cust.dart';
import 'package:finway/themes/constant_colors.dart';
import 'package:finway/utils/dark_theme_provider.dart';
import 'package:finway/widget/StarRating.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:location/location.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';

class AllParcelScreen extends StatelessWidget {
  const AllParcelScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final themeChange = Provider.of<DarkThemeProvider>(context);
    final isDark = themeChange.getThem();

    return GetX<ParcelOrderController>(
      init: ParcelOrderController(),
      builder: (controller) {
        return Scaffold(
          backgroundColor: isDark ? AppThemeData.surface50Dark : AppThemeData.surface50,
          appBar: CustomAppbar(
            bgColor: AppThemeData.primary200,
            title: 'All Parcels'.tr,
            isLeadingIcon: false,
            onClick: () {
              log("::::::All Parcels::::::");
              if (Navigator.of(context).canPop()) {
                Get.back();
              } else {
                Get.offAll(() => TexiDashboard());
              }
            },
          ),
          body: Stack(
            alignment: AlignmentDirectional.topStart,
            children: [
              Container(
                height: 80,
                color: AppThemeData.primary200,
              ),
              SafeArea(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 12),
                    Expanded(
                      child: Container(
                        margin: const EdgeInsets.symmetric(horizontal: 16),
                        color: isDark ? AppThemeData.surface50Dark : AppThemeData.surface50,
                        child: DefaultTabController(
                          length: 3,
                          child: Column(
                            children: [
                              // Modern Pill Tab Bar
                              Container(
                                decoration: BoxDecoration(
                                  color: isDark ? const Color(0xFF1E2620) : Colors.white,
                                  borderRadius: BorderRadius.circular(14),
                                  border: Border.all(
                                    color: isDark ? Colors.grey[800]! : Colors.grey[200]!,
                                  ),
                                ),
                                padding: const EdgeInsets.all(4),
                                child: TabBar(
                                  isScrollable: false,
                                  indicatorSize: TabBarIndicatorSize.tab,
                                  indicator: BoxDecoration(
                                    color: AppThemeData.primary200,
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  labelColor: Colors.white,
                                  unselectedLabelColor: isDark ? Colors.grey[400] : Colors.grey[600],
                                  dividerColor: Colors.transparent,
                                  labelStyle: const TextStyle(
                                    fontFamily: AppThemeData.semiBold,
                                    fontSize: 14,
                                  ),
                                  unselectedLabelStyle: const TextStyle(
                                    fontFamily: AppThemeData.regular,
                                    fontSize: 14,
                                  ),
                                  tabs: [
                                    Tab(text: 'Active'.tr),
                                    Tab(text: 'Completed'.tr),
                                    Tab(text: 'Rejected'.tr),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 12),

                              Expanded(
                                child: TabBarView(
                                  children: [
                                    // 1. Active / New Tab
                                    RefreshIndicator(
                                      onRefresh: () => controller.getParcel(),
                                      child: controller.isLoading.value
                                          ? const Center(child: CircularProgressIndicator())
                                          : controller.newParcelList.isEmpty
                                              ? Constant.emptyView(context, "No active parcel bookings.".tr, false)
                                              : ListView.builder(
                                                  padding: const EdgeInsets.only(bottom: 20),
                                                  physics: const BouncingScrollPhysics(),
                                                  itemCount: controller.newParcelList.length,
                                                  itemBuilder: (context, index) {
                                                    return buildHistory(context, controller, controller.newParcelList[index]);
                                                  },
                                                ),
                                    ),

                                    // 2. Completed Tab
                                    RefreshIndicator(
                                      onRefresh: () => controller.getParcel(),
                                      child: controller.isLoading.value
                                          ? const Center(child: CircularProgressIndicator())
                                          : controller.completedParcelList.isEmpty
                                              ? Constant.emptyView(context, "You have not completed any parcel.".tr, false)
                                              : ListView.builder(
                                                  padding: const EdgeInsets.only(bottom: 20),
                                                  physics: const BouncingScrollPhysics(),
                                                  itemCount: controller.completedParcelList.length,
                                                  itemBuilder: (context, index) {
                                                    return buildHistory(context, controller, controller.completedParcelList[index]);
                                                  },
                                                ),
                                    ),

                                    // 3. Rejected / Cancelled Tab
                                    RefreshIndicator(
                                      onRefresh: () => controller.getParcel(),
                                      child: controller.isLoading.value
                                          ? const Center(child: CircularProgressIndicator())
                                          : controller.rejectedParcelList.isEmpty
                                              ? Constant.emptyView(context, "No rejected parcels.".tr, false)
                                              : ListView.builder(
                                                  padding: const EdgeInsets.only(bottom: 20),
                                                  physics: const BouncingScrollPhysics(),
                                                  itemCount: controller.rejectedParcelList.length,
                                                  itemBuilder: (context, index) {
                                                    return buildHistory(context, controller, controller.rejectedParcelList[index]);
                                                  },
                                                ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget buildHistory(BuildContext context, ParcelOrderController controller, ParcelData data) {
    final themeChange = Provider.of<DarkThemeProvider>(context);
    final isDark = themeChange.getThem();
    final status = data.status?.toString().toLowerCase() ?? '';
    final otp = data.otp?.toString() ?? '';
    final hasDriver = data.idConducteur != null && data.idConducteur.toString() != "null" && data.idConducteur.toString().isNotEmpty && data.idConducteur.toString() != "0";
    final showOtp = otp.isNotEmpty && status != 'onride' && status != 'completed' && status != 'rejected' && status != 'canceled';
    final needsPayment = (status == 'onride' || status == 'on ride') && data.paymentStatus != 'yes';

    return GestureDetector(
      onTap: () async {
        log("Parcel Click :: ${data.toJson().toString()}");
        await Get.to(() => ParcelDetailsScreen(), arguments: {
          "parcelData": data,
        })?.then((v) {
          controller.getParcel();
        });
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 14),
        decoration: BoxDecoration(
          color: isDark ? AppThemeData.surface50Dark : Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
          border: Border.all(
            color: isDark ? AppThemeData.grey200Dark.withValues(alpha: 0.5) : AppThemeData.grey200,
            width: 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Top Row: Order ID + Status Badge
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: AppThemeData.primary200.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              "#${data.id ?? ''}",
                              style: TextStyle(
                                fontFamily: AppThemeData.semiBold,
                                fontSize: 13,
                                color: AppThemeData.primary200,
                              ),
                            ),
                          ),
                          if (data.title != null && data.title.toString().isNotEmpty) ...[
                            const SizedBox(width: 8),
                            Text(
                              data.title.toString(),
                              style: TextStyle(
                                fontFamily: AppThemeData.medium,
                                fontSize: 13,
                                color: isDark ? Colors.grey[400] : Colors.grey[600],
                              ),
                            ),
                          ],
                        ],
                      ),
                      _buildStatusBadge(status),
                    ],
                  ),
                  const SizedBox(height: 14),

                  // Route Addresses
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Column(
                        children: [
                          Container(
                            width: 12,
                            height: 12,
                            decoration: BoxDecoration(
                              color: AppThemeData.success300,
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.white, width: 2),
                            ),
                          ),
                          Container(
                            width: 2,
                            height: 38,
                            margin: const EdgeInsets.symmetric(vertical: 2),
                            color: isDark ? Colors.grey[700] : Colors.grey[300],
                          ),
                          Container(
                            width: 12,
                            height: 12,
                            decoration: BoxDecoration(
                              color: AppThemeData.warning200,
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.white, width: 2),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Sender Address
                            Text(
                              data.source?.toString() ?? '',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 14,
                                fontFamily: AppThemeData.medium,
                                color: isDark ? Colors.white : Colors.black87,
                              ),
                            ),
                            const SizedBox(height: 24),
                            // Destination Address
                            Text(
                              data.destination?.toString() ?? '',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 14,
                                fontFamily: AppThemeData.medium,
                                color: isDark ? Colors.white : Colors.black87,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // ⭐ PROMINENT PICKUP OTP BANNER ⭐
            if (showOtp) ...[
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 16),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: isDark
                        ? [const Color(0xFF102E20), const Color(0xFF183D2C)]
                        : [const Color(0xFFE6F8EF), const Color(0xFFD3F4E3)],
                  ),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: AppThemeData.success300.withValues(alpha: 0.4),
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: AppThemeData.success300,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.lock, size: 14, color: Colors.white),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "Pickup Verification OTP".tr,
                            style: TextStyle(
                              fontSize: 11,
                              fontFamily: AppThemeData.medium,
                              color: isDark ? Colors.green[300] : const Color(0xFF0B6634),
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            otp,
                            style: TextStyle(
                              fontSize: 18,
                              letterSpacing: 2,
                              fontFamily: AppThemeData.bold,
                              color: isDark ? Colors.white : const Color(0xFF0B6634),
                            ),
                          ),
                          Text(
                            "Share with driver at pickup".tr,
                            style: TextStyle(
                              fontSize: 10,
                              fontFamily: AppThemeData.regular,
                              color: isDark ? Colors.grey[400] : const Color(0xFF2E6545),
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Copy Button
                    InkWell(
                      onTap: () {
                        Clipboard.setData(ClipboardData(text: otp));
                        HapticFeedback.lightImpact();
                        ShowToastDialog.showToast("OTP $otp copied to clipboard".tr);
                      },
                      borderRadius: BorderRadius.circular(8),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: isDark ? Colors.white.withValues(alpha: 0.12) : Colors.white,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: AppThemeData.success300.withValues(alpha: 0.5),
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.copy_rounded, size: 14, color: AppThemeData.success300),
                            const SizedBox(width: 4),
                            Text(
                              "Copy".tr,
                              style: TextStyle(
                                fontSize: 12,
                                fontFamily: AppThemeData.semiBold,
                                color: isDark ? Colors.white : const Color(0xFF0B6634),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
            ],

            // ⭐ PAYMENT REQUIRED BANNER (Post-OTP) ⭐
            if (needsPayment) ...[
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 16),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: isDark
                        ? [const Color(0xFF2C2205), const Color(0xFF382C07)]
                        : [const Color(0xFFFFF9E6), const Color(0xFFFFF3CC)],
                  ),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: AppThemeData.warning200.withValues(alpha: 0.6),
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: AppThemeData.warning200,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.payment_rounded, size: 14, color: Colors.white),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "Payment Required".tr,
                            style: TextStyle(
                              fontSize: 12,
                              fontFamily: AppThemeData.semiBold,
                              color: isDark ? Colors.amber[300] : const Color(0xFF8A5800),
                            ),
                          ),
                          Text(
                            "Parcel picked up! Pay ${Constant().amountShow(amount: data.amount?.toString() ?? '0')} to start delivery".tr,
                            style: TextStyle(
                              fontSize: 10,
                              fontFamily: AppThemeData.regular,
                              color: isDark ? Colors.grey[300] : const Color(0xFF6B4A08),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: AppThemeData.primary200,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        "Pay Now".tr,
                        style: const TextStyle(
                          fontSize: 12,
                          fontFamily: AppThemeData.semiBold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
            ],

            // 3-Stat Summary Container
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: isDark ? AppThemeData.surface50Dark.withValues(alpha: 0.7) : AppThemeData.surface50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isDark ? Colors.grey[800]! : Colors.grey[200]!,
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildStatItem("Distance".tr, "${data.distance ?? '0'} ${data.distanceUnit ?? 'KM'}", isDark),
                  Container(width: 1, height: 22, color: isDark ? Colors.grey[800] : Colors.grey[300]),
                  _buildStatItem("Duration".tr, data.duration?.toString() ?? '--', isDark),
                  Container(width: 1, height: 22, color: isDark ? Colors.grey[800] : Colors.grey[300]),
                  _buildStatItem("Amount".tr, Constant().amountShow(amount: data.amount?.toString() ?? '0'), isDark),
                ],
              ),
            ),

            // Driver strip (when assigned)
            if (hasDriver) ...[
              const SizedBox(height: 12),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(20),
                      child: data.driverPhoto != null &&
                              data.driverPhoto.toString().isNotEmpty &&
                              (data.driverPhoto.toString().startsWith("http://") || data.driverPhoto.toString().startsWith("https://"))
                          ? CachedNetworkImage(
                              imageUrl: data.driverPhoto.toString(),
                              width: 40,
                              height: 40,
                              fit: BoxFit.cover,
                              placeholder: (context, url) => Container(width: 40, height: 40, color: Colors.grey[200]),
                              errorWidget: (context, url, error) => Image.asset(ImageConstant.logo, width: 40, height: 40),
                            )
                          : Image.asset(ImageConstant.logo, width: 40, height: 40),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            data.driverName?.toString().isNotEmpty == true
                                ? data.driverName.toString()
                                : "${data.prenomConducteur ?? ''} ${data.nomConducteur ?? ''}".trim(),
                            style: TextStyle(
                              fontFamily: AppThemeData.semiBold,
                              fontSize: 14,
                              color: isDark ? Colors.white : Colors.black87,
                            ),
                          ),
                          Row(
                            children: [
                              StarRating(
                                size: 13,
                                rating: double.tryParse(data.moyenneDriver?.toString() ?? data.moyenne?.toString() ?? '5.0') ?? 5.0,
                                color: AppThemeData.warning200,
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),

                    // Share Location
                    InkWell(
                      onTap: () async {
                        ShowToastDialog.showLoader("Please wait");
                        final Location currentLocation = Location();
                        LocationData location = await currentLocation.getLocation();
                        ShowToastDialog.closeLoader();
                        await Share.share(
                          'https://www.google.com/maps/search/?api=1&query=${location.latitude},${location.longitude}',
                          subject: "Fiinway Parcel".tr,
                        );
                      },
                      borderRadius: BorderRadius.circular(20),
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AppThemeData.secondary200.withValues(alpha: 0.12),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(Icons.share_rounded, color: AppThemeData.secondary200, size: 18),
                      ),
                    ),
                    const SizedBox(width: 8),

                    // Call Driver
                    if (data.driverPhone?.toString().isNotEmpty == true)
                      InkWell(
                        onTap: () => Constant.makePhoneCall(data.driverPhone.toString()),
                        borderRadius: BorderRadius.circular(20),
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: AppThemeData.success300.withValues(alpha: 0.14),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(Icons.phone_in_talk_rounded, color: AppThemeData.success300, size: 18),
                        ),
                      ),
                  ],
                ),
              ),
            ],

            const SizedBox(height: 14),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusBadge(String status) {
    Color bg;
    Color fg;
    String label;

    switch (status) {
      case 'confirmed':
        bg = AppThemeData.success300.withValues(alpha: 0.14);
        fg = AppThemeData.success300;
        label = "Confirmed".tr;
        break;
      case 'onride':
      case 'on ride':
        bg = AppThemeData.warning200.withValues(alpha: 0.18);
        fg = AppThemeData.warning200;
        label = "In Transit".tr;
        break;
      case 'completed':
        bg = AppThemeData.primary200.withValues(alpha: 0.15);
        fg = AppThemeData.primary200;
        label = "Completed".tr;
        break;
      case 'canceled':
      case 'rejected':
        bg = Colors.red.withValues(alpha: 0.12);
        fg = Colors.red;
        label = "Cancelled".tr;
        break;
      case 'new':
      default:
        bg = Colors.blue.withValues(alpha: 0.12);
        fg = Colors.blue;
        label = "Pending Driver".tr;
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11,
          fontFamily: AppThemeData.semiBold,
          color: fg,
        ),
      ),
    );
  }

  Widget _buildStatItem(String label, String value, bool isDark) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 13,
            fontFamily: AppThemeData.semiBold,
            color: AppThemeData.primary200,
          ),
        ),
        const SizedBox(height: 1),
        Text(
          label,
          style: TextStyle(
            fontSize: 10,
            fontFamily: AppThemeData.regular,
            color: isDark ? Colors.grey[400] : Colors.grey[600],
          ),
        ),
      ],
    );
  }
}
