import 'package:finway/constant/constant.dart';
import 'package:finway/constant/show_toast_dialog.dart';
import 'package:finway/controller/new_ride_controller.dart';
import 'package:finway/model/ride_model.dart';
import 'package:finway/page/complaint/add_complaint_screen.dart';
import 'package:finway/page/completed_ride_screens/payment_selection_screen.dart';
import 'package:finway/page/completed_ride_screens/trip_history_screen.dart';
import 'package:finway/page/route_view_screen/route_view_screen.dart';
import 'package:finway/page/route_view_screen/route_osm_view_screen.dart';
import 'package:finway/page/review_screens/add_review_screen.dart';
import 'package:finway/themes/button_them.dart';
import 'package:finway/themes/constant_colors.dart';
import 'package:finway/utils/dark_theme_provider.dart';
import 'package:finway/widget/StarRating.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:get/get.dart';
import 'package:location/location.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';

import '../../constant/image_constant.dart';

class NewRideScreen extends StatelessWidget {
  const NewRideScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final themeChange = Provider.of<DarkThemeProvider>(context);
    final isDark = themeChange.getThem();

    return GetBuilder<NewRideController>(
      init: NewRideController(),
      builder: (controller) {
        return Scaffold(
          backgroundColor: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
          appBar: AppBar(
            backgroundColor: AppThemeData.primary200,
            elevation: 0,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.white, size: 22),
              onPressed: () => Get.back(),
            ),
            title: Text(
              'All Rides'.tr,
              style: const TextStyle(
                fontFamily: AppThemeData.bold,
                fontSize: 18,
                color: Colors.white,
              ),
            ),
            centerTitle: true,
            actions: [
              IconButton(
                icon: const Icon(Icons.refresh_rounded, color: Colors.white, size: 22),
                tooltip: 'Refresh Rides'.tr,
                onPressed: () => controller.getNewRide(isinit: true),
              ),
            ],
          ),
          body: DefaultTabController(
            length: 3,
            child: Column(
              children: [
                // Modern Pill Tab Bar Container
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF1E293B) : Colors.white,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.04),
                        blurRadius: 8,
                        offset: const Offset(0, 3),
                      )
                    ],
                  ),
                  child: Container(
                    height: 44,
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF1F5F9),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: TabBar(
                      padding: EdgeInsets.zero,
                      labelPadding: const EdgeInsets.symmetric(horizontal: 2),
                      indicator: BoxDecoration(
                        color: AppThemeData.primary200,
                        borderRadius: BorderRadius.circular(10),
                        boxShadow: [
                          BoxShadow(
                            color: AppThemeData.primary200.withValues(alpha: 0.35),
                            blurRadius: 6,
                            offset: const Offset(0, 2),
                          )
                        ],
                      ),
                      indicatorSize: TabBarIndicatorSize.tab,
                      dividerColor: Colors.transparent,
                      labelColor: Colors.white,
                      unselectedLabelColor: isDark ? Colors.white60 : const Color(0xFF64748B),
                      labelStyle: const TextStyle(
                        fontFamily: AppThemeData.bold,
                        fontSize: 13,
                      ),
                      unselectedLabelStyle: const TextStyle(
                        fontFamily: AppThemeData.medium,
                        fontSize: 13,
                      ),
                      tabs: [
                        Tab(
                          child: Obx(() => FittedBox(
                            fit: BoxFit.scaleDown,
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text('New'.tr),
                                if (controller.newRideList.isNotEmpty) ...[
                                  const SizedBox(width: 4),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                                    decoration: BoxDecoration(
                                      color: Colors.amber.shade700,
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: Text(
                                      '${controller.newRideList.length}',
                                      style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                                    ),
                                  )
                                ]
                              ],
                            ),
                          )),
                        ),
                        Tab(
                          child: Obx(() => FittedBox(
                            fit: BoxFit.scaleDown,
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text('Pending'.tr),
                                if (controller.pendingRideList.isNotEmpty) ...[
                                  const SizedBox(width: 4),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                                    decoration: BoxDecoration(
                                      color: Colors.blue.shade600,
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: Text(
                                      '${controller.pendingRideList.length}',
                                      style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                                    ),
                                  )
                                ]
                              ],
                            ),
                          )),
                        ),
                        Tab(
                          child: Obx(() => FittedBox(
                            fit: BoxFit.scaleDown,
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text('Completed'.tr),
                                if (controller.completedRideList.isNotEmpty) ...[
                                  const SizedBox(width: 4),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                                    decoration: BoxDecoration(
                                      color: isDark ? Colors.white24 : Colors.grey.shade400,
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: Text(
                                      '${controller.completedRideList.length}',
                                      style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                                    ),
                                  )
                                ]
                              ],
                            ),
                          )),
                        ),
                      ],
                    ),
                  ),
                ),

                // TabBarView Content
                Expanded(
                  child: TabBarView(
                    children: [
                      // 1. NEW / AWAITING RIDES
                      _buildRideTabList(
                        controller: controller,
                        scrollController: controller.scrollControllerNew,
                        rides: controller.newRideList,
                        emptyMessage: "No awaiting ride requests.\nYour new bookings will appear here.",
                        isDark: isDark,
                        context: context,
                        showBookNow: true,
                      ),

                      // 2. PENDING / IN-PROGRESS RIDES
                      _buildRideTabList(
                        controller: controller,
                        scrollController: controller.scrollControllerPending,
                        rides: controller.pendingRideList,
                        emptyMessage: "No active or in-progress trips right now.",
                        isDark: isDark,
                        context: context,
                        showBookNow: false,
                      ),

                      // 3. COMPLETED & REJECTED RIDES
                      _buildRideTabList(
                        controller: controller,
                        scrollController: controller.scrollControllerCompleted,
                        rides: controller.completedRideList,
                        emptyMessage: "No completed or past trips found.",
                        isDark: isDark,
                        context: context,
                        showBookNow: false,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildRideTabList({
    required NewRideController controller,
    required ScrollController scrollController,
    required RxList<RideData> rides,
    required String emptyMessage,
    required bool isDark,
    required BuildContext context,
    required bool showBookNow,
  }) {
    return Obx(() {
      if (controller.isLoading.value && rides.isEmpty) {
        return Center(
          child: CircularProgressIndicator(color: AppThemeData.primary200),
        );
      }

      if (rides.isEmpty) {
        return Center(
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 40),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 90,
                    height: 90,
                    decoration: BoxDecoration(
                      color: AppThemeData.primary200.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.directions_car_filled_rounded,
                      size: 48,
                      color: AppThemeData.primary200,
                    ),
                  ),
                  const SizedBox(height: 18),
                  Text(
                    emptyMessage.tr,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontFamily: AppThemeData.medium,
                      fontSize: 14,
                      color: isDark ? Colors.white60 : const Color(0xFF64748B),
                      height: 1.4,
                    ),
                  ),
                  if (showBookNow) ...[
                    const SizedBox(height: 24),
                    SizedBox(
                      width: 180,
                      child: ElevatedButton.icon(
                        onPressed: () => Get.back(),
                        icon: const Icon(Icons.add_rounded, size: 20, color: Colors.white),
                        label: Text('Book a Cab'.tr, style: const TextStyle(fontFamily: AppThemeData.bold, fontSize: 14, color: Colors.white)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppThemeData.primary200,
                          elevation: 0,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                      ),
                    )
                  ]
                ],
              ),
            ),
          ),
        );
      }

      return RefreshIndicator(
        color: AppThemeData.primary200,
        backgroundColor: isDark ? const Color(0xFF1E293B) : Colors.white,
        onRefresh: () => controller.getNewRide(isinit: true),
        child: ListView.separated(
          controller: scrollController,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          itemCount: rides.length + (controller.isLoadMoreRunning.value ? 1 : 0),
          separatorBuilder: (context, index) => const SizedBox(height: 14),
          itemBuilder: (context, index) {
            if (index == rides.length) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: CircularProgressIndicator(color: AppThemeData.primary200, strokeWidth: 2.5),
                ),
              );
            }
            return _buildModernRideCard(controller, context, rides[index], isDark);
          },
        ),
      );
    });
  }

  Widget _buildModernRideCard(NewRideController controller, BuildContext context, RideData data, bool isDark) {
    final status = (data.statut ?? '').toLowerCase().trim();
    final isAwaiting = status == 'new';
    final isInProgress = status == 'confirmed' || status == 'on ride' || status == 'arrived' || status == 'in progress';
    final isCompleted = status == 'completed';
    final isRejected = status == 'rejected' || status == 'canceled' || status == 'cancelled';
    final isPaymentAwaited = isCompleted && data.statutPaiement != 'yes';

    // Status pill configurations
    Color statusBg;
    Color statusText;
    String statusLabel;
    IconData statusIcon;

    if (isAwaiting) {
      statusBg = const Color(0xFFFEF3C7);
      statusText = const Color(0xFFD97706);
      statusLabel = 'Awaiting Driver'.tr;
      statusIcon = Icons.hourglass_top_rounded;
    } else if (isInProgress) {
      statusBg = const Color(0xFFE0F2FE);
      statusText = const Color(0xFF0284C7);
      statusLabel = status == 'on ride' ? 'On Ride'.tr : 'In Progress'.tr;
      statusIcon = Icons.navigation_rounded;
    } else if (isCompleted) {
      if (isPaymentAwaited) {
        statusBg = const Color(0xFFFFFBEB);
        statusText = const Color(0xFFB45309);
        statusLabel = 'Payment Awaited'.tr;
        statusIcon = Icons.payment_rounded;
      } else {
        statusBg = const Color(0xFFDCFCE7);
        statusText = const Color(0xFF16A34A);
        statusLabel = 'Completed'.tr;
        statusIcon = Icons.check_circle_rounded;
      }
    } else {
      statusBg = const Color(0xFFFEE2E2);
      statusText = const Color(0xFFDC2626);
      statusLabel = 'Cancelled'.tr;
      statusIcon = Icons.cancel_rounded;
    }

    return InkWell(
      onTap: () async {
        if (isPaymentAwaited) {
          await Get.to(() => PaymentSelectionScreen(), arguments: {
            "rideData": data,
          })?.then((v) => controller.getNewRide());
        } else if (isInProgress) {
          var argumentData = {'type': data.statut.toString(), 'data': data};
          if (Constant.selectedMapType == 'osm') {
            await Get.to(() => const RouteOsmViewScreen(), arguments: argumentData)?.then((v) => controller.getNewRide());
          } else {
            await Get.to(() => const RouteViewScreen(), arguments: argumentData)?.then((v) => controller.getNewRide());
          }
        } else {
          await Get.to(() => TripHistoryScreen(), arguments: {
            "rideData": data,
          })?.then((v) => controller.getNewRide());
        }
      },
      borderRadius: BorderRadius.circular(18),
      child: Container(
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E293B) : Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: isDark ? Colors.white.withValues(alpha: 0.08) : const Color(0xFFE2E8F0),
            width: 1.2,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: isDark ? 0.25 : 0.04),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ── TOP BAR: Booking ID, Date, & Status Badge ─────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(7),
                    decoration: BoxDecoration(
                      color: AppThemeData.primary200.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      Icons.local_taxi_rounded,
                      color: AppThemeData.primary200,
                      size: 18,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Ride #${data.id ?? ""}',
                          style: TextStyle(
                            fontFamily: AppThemeData.bold,
                            fontSize: 14,
                            color: isDark ? Colors.white : const Color(0xFF0F172A),
                          ),
                        ),
                        if (data.creer != null)
                          Text(
                            data.creer.toString(),
                            style: TextStyle(
                              fontFamily: AppThemeData.regular,
                              fontSize: 11,
                              color: isDark ? Colors.white60 : const Color(0xFF64748B),
                            ),
                          ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4.5),
                    decoration: BoxDecoration(
                      color: statusBg,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(statusIcon, color: statusText, size: 13),
                          const SizedBox(width: 4),
                          Text(
                            statusLabel,
                            style: TextStyle(
                              fontFamily: AppThemeData.bold,
                              fontSize: 11,
                              color: statusText,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),

            Divider(color: isDark ? Colors.white10 : const Color(0xFFF1F5F9), height: 1),

            // ── ROUTE TIMELINE: Pickup & Drop Location ────────────────────────
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  // Pickup Row
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(top: 2),
                        child: Icon(Icons.radio_button_checked_rounded, color: AppThemeData.success300, size: 16),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          data.departName ?? 'Pickup location'.tr,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontFamily: AppThemeData.medium,
                            fontSize: 13,
                            color: isDark ? Colors.white : const Color(0xFF1E293B),
                            height: 1.3,
                          ),
                        ),
                      ),
                    ],
                  ),

                  // Dotted Connector & Stops
                  if (data.stops != null && data.stops!.isNotEmpty) ...[
                    ListView.builder(
                      padding: EdgeInsets.zero,
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: data.stops!.length,
                      itemBuilder: (context, int idx) {
                        return Padding(
                          padding: const EdgeInsets.only(left: 2, top: 4, bottom: 4),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                width: 12,
                                height: 12,
                                alignment: Alignment.center,
                                decoration: BoxDecoration(
                                  color: Colors.grey.shade400,
                                  shape: BoxShape.circle,
                                ),
                                child: Text(
                                  String.fromCharCode(idx + 65),
                                  style: const TextStyle(fontSize: 8, color: Colors.white, fontWeight: FontWeight.bold),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  data.stops![idx].location ?? '',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontFamily: AppThemeData.regular,
                                    fontSize: 12,
                                    color: isDark ? Colors.white70 : const Color(0xFF475569),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ] else ...[
                    Padding(
                      padding: const EdgeInsets.only(left: 7),
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: Container(
                          width: 2,
                          height: 16,
                          color: isDark ? Colors.white24 : const Color(0xFFCBD5E1),
                        ),
                      ),
                    ),
                  ],

                  // Destination Row
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(top: 2),
                        child: Icon(Icons.location_on_rounded, color: Colors.red.shade500, size: 16),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          data.destinationName ?? 'Destination'.tr,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontFamily: AppThemeData.medium,
                            fontSize: 13,
                            color: isDark ? Colors.white : const Color(0xFF1E293B),
                            height: 1.3,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // ── METRICS BAR: Distance, Duration, Passengers, Fare ─────────────
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 14),
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: _buildMetricCell(
                      label: 'Distance'.tr,
                      value: '${double.tryParse(data.distance?.toString() ?? "0")?.toStringAsFixed(1) ?? "0"} ${data.distanceUnit ?? "km"}',
                      isDark: isDark,
                    ),
                  ),
                  _buildMetricDivider(isDark),
                  Expanded(
                    child: _buildMetricCell(
                      label: 'Duration'.tr,
                      value: data.duree?.toString() ?? 'N/A',
                      isDark: isDark,
                    ),
                  ),
                  _buildMetricDivider(isDark),
                  Expanded(
                    child: _buildMetricCell(
                      label: 'Passengers'.tr,
                      value: '${data.numberPoeple ?? 1}',
                      isDark: isDark,
                    ),
                  ),
                  _buildMetricDivider(isDark),
                  Expanded(
                    child: _buildMetricCell(
                      label: 'Price'.tr,
                      value: Constant().amountShow(amount: data.montant?.toString() ?? "0"),
                      isDark: isDark,
                      isPrice: true,
                    ),
                  ),
                ],
              ),
            ),

            // ── OTP DISPLAY (if active & required) ────────────────────────────
            if (isInProgress && Constant.rideOtp.toString().toLowerCase() == 'yes' && (data.otp != null && data.otp.toString().isNotEmpty)) ...[
              const SizedBox(height: 10),
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 14),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: AppThemeData.primary200.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppThemeData.primary200.withValues(alpha: 0.3)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Start Ride OTP'.tr,
                      style: TextStyle(
                        fontFamily: AppThemeData.medium,
                        fontSize: 12,
                        color: isDark ? Colors.white70 : const Color(0xFF334155),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                      decoration: BoxDecoration(
                        color: AppThemeData.primary200,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        data.otp.toString(),
                        style: const TextStyle(
                          fontFamily: AppThemeData.bold,
                          fontSize: 14,
                          color: Colors.white,
                          letterSpacing: 2.0,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],

            const SizedBox(height: 12),

            // ── DRIVER INFO OR AWAITING LOADER ────────────────────────────────
            if (isAwaiting) ...[
              Padding(
                padding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
                child: Row(
                  children: [
                    SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.amber.shade700),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Searching for nearby drivers...'.tr,
                        style: TextStyle(
                          fontFamily: AppThemeData.medium,
                          fontSize: 12,
                          color: isDark ? Colors.white70 : const Color(0xFF64748B),
                        ),
                      ),
                    ),
                  ],
                ),
              )
            ] else if (data.nomConducteur != null && data.nomConducteur.toString().isNotEmpty) ...[
              Padding(
                padding: const EdgeInsets.fromLTRB(14, 0, 14, 12),
                child: Row(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(25),
                      child: CachedNetworkImage(
                        imageUrl: data.photoPath?.toString() ?? '',
                        width: 42,
                        height: 42,
                        fit: BoxFit.cover,
                        placeholder: (context, url) => Container(color: Colors.grey.shade200),
                        errorWidget: (context, url, error) => Image.asset(ImageConstant.logo, width: 42, height: 42),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${data.prenomConducteur ?? ""} ${data.nomConducteur ?? ""}'.trim(),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontFamily: AppThemeData.bold,
                              fontSize: 13,
                              color: isDark ? Colors.white : const Color(0xFF0F172A),
                            ),
                          ),
                          const SizedBox(height: 2),
                          Row(
                            children: [
                              StarRating(
                                size: 14,
                                rating: double.tryParse(data.moyenne?.toString() ?? "0") ?? 0.0,
                                color: AppThemeData.warning200,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                '${double.tryParse(data.moyenne?.toString() ?? "0")?.toStringAsFixed(1) ?? "0.0"}',
                                style: TextStyle(
                                  fontFamily: AppThemeData.medium,
                                  fontSize: 11,
                                  color: isDark ? Colors.white60 : const Color(0xFF64748B),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    // Action Icons for Active Ride (Call & Share)
                    if (isInProgress) ...[
                      if (data.driverPhone != null && data.driverPhone.toString().isNotEmpty) ...[
                        InkWell(
                          onTap: () => Constant.makePhoneCall(data.driverPhone.toString()),
                          borderRadius: BorderRadius.circular(20),
                          child: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: const Color(0xFF16A34A).withValues(alpha: 0.12),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.phone_rounded, color: Color(0xFF16A34A), size: 18),
                          ),
                        ),
                        const SizedBox(width: 8),
                      ],
                      InkWell(
                        onTap: () async {
                          ShowToastDialog.showLoader("Please wait");
                          final Location currentLocation = Location();
                          LocationData location = await currentLocation.getLocation();
                          ShowToastDialog.closeLoader();
                          await Share.share(
                            'https://www.google.com/maps/search/?api=1&query=${location.latitude},${location.longitude}',
                            subject: "Fiinway Ride".tr,
                          );
                        },
                        borderRadius: BorderRadius.circular(20),
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: AppThemeData.primary200.withValues(alpha: 0.12),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(Icons.share_rounded, color: AppThemeData.primary200, size: 18),
                        ),
                      ),
                    ]
                  ],
                ),
              )
            ],

            // ── ACTION BUTTONS FOOTER ─────────────────────────────────────────
            if (isInProgress) ...[
              Padding(
                padding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
                child: SizedBox(
                  height: 42,
                  child: ElevatedButton.icon(
                    onPressed: () async {
                      var argumentData = {'type': data.statut.toString(), 'data': data};
                      if (Constant.selectedMapType == 'osm') {
                        await Get.to(() => const RouteOsmViewScreen(), arguments: argumentData)?.then((v) => controller.getNewRide());
                      } else {
                        await Get.to(() => const RouteViewScreen(), arguments: argumentData)?.then((v) => controller.getNewRide());
                      }
                    },
                    icon: const Icon(Icons.map_rounded, size: 18, color: Colors.white),
                    label: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text('Track Live Ride'.tr, style: const TextStyle(fontFamily: AppThemeData.bold, fontSize: 13, color: Colors.white)),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppThemeData.primary200,
                      elevation: 0,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                  ),
                ),
              )
            ] else if (isPaymentAwaited) ...[
              Padding(
                padding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
                child: SizedBox(
                  height: 42,
                  child: ElevatedButton.icon(
                    onPressed: () async {
                      await Get.to(() => PaymentSelectionScreen(), arguments: {
                        "rideData": data,
                      })?.then((v) => controller.getNewRide());
                    },
                    icon: const Icon(Icons.payment_rounded, size: 18, color: Colors.white),
                    label: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text('Pay Now (${Constant().amountShow(amount: data.montant?.toString() ?? "0")})'.tr, style: const TextStyle(fontFamily: AppThemeData.bold, fontSize: 13, color: Colors.white)),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFE67E22),
                      elevation: 0,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                  ),
                ),
              )
            ] else if (isCompleted) ...[
              Padding(
                padding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
                child: Row(
                  children: [
                    Expanded(
                      child: SizedBox(
                        height: 38,
                        child: OutlinedButton(
                          onPressed: () async {
                            Get.to(const AddReviewScreen(), arguments: {
                              "data": data,
                              "ride_type": "ride",
                            })?.then((value) => controller.getNewRide());
                          },
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(horizontal: 6),
                            side: const BorderSide(color: Color(0xFFE67E22), width: 1.2),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                          child: FittedBox(
                            fit: BoxFit.scaleDown,
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(Icons.star_outline_rounded, size: 16, color: Color(0xFFE67E22)),
                                const SizedBox(width: 4),
                                Text('Rate Driver'.tr, style: const TextStyle(fontFamily: AppThemeData.bold, fontSize: 12, color: Color(0xFFE67E22))),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: SizedBox(
                        height: 38,
                        child: OutlinedButton(
                          onPressed: () async {
                            Get.to(AddComplaintScreen(), arguments: {
                              "data": data,
                              "ride_type": "ride",
                            })?.then((value) => controller.getNewRide());
                          },
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(horizontal: 6),
                            side: BorderSide(color: isDark ? Colors.white24 : const Color(0xFFCBD5E1), width: 1.2),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                          child: FittedBox(
                            fit: BoxFit.scaleDown,
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.report_problem_outlined, size: 16, color: isDark ? Colors.white70 : const Color(0xFF64748B)),
                                const SizedBox(width: 4),
                                Text('Complaint'.tr, style: TextStyle(fontFamily: AppThemeData.medium, fontSize: 12, color: isDark ? Colors.white70 : const Color(0xFF64748B))),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              )
            ]
          ],
        ),
      ),
    );
  }

  Widget _buildMetricCell({
    required String label,
    required String value,
    required bool isDark,
    bool isPrice = false,
  }) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              value,
              maxLines: 1,
              style: TextStyle(
                fontFamily: AppThemeData.bold,
                fontSize: isPrice ? 13 : 12,
                color: isPrice ? const Color(0xFF16A34A) : (isDark ? Colors.white : const Color(0xFF0F172A)),
              ),
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontFamily: AppThemeData.regular,
              fontSize: 10,
              color: isDark ? Colors.white60 : const Color(0xFF64748B),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMetricDivider(bool isDark) {
    return Container(
      width: 1,
      height: 20,
      margin: const EdgeInsets.symmetric(horizontal: 2),
      color: isDark ? Colors.white10 : const Color(0xFFE2E8F0),
    );
  }
}
