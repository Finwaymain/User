import 'dart:io';
import 'dart:math';
import 'dart:async';
import 'package:finway/constant/constant.dart';
import 'package:finway/constant/show_toast_dialog.dart';
import 'package:finway/controller/dash_board_controller.dart';
import 'package:finway/controller/parcel_details_controller.dart';
import 'package:finway/controller/parcel_order_controller.dart';
import 'package:finway/model/parcel_model.dart';
import 'package:finway/model/parcel_details_model.dart';
import 'package:finway/page/parcel_service_screen/all_parcel_screen.dart';
import 'package:finway/page/parcel_service_screen/parcel_payment_selection_screen.dart';
import 'package:finway/page/review_screens/add_review_screen.dart';
import 'package:finway/themes/button_them.dart';
import 'package:finway/themes/constant_colors.dart';
import 'package:finway/themes/custom_alert_dialog.dart';
import 'package:finway/themes/custom_dialog_box.dart';
import 'package:finway/themes/text_field_them.dart';
import 'package:finway/utils/Preferences.dart';
import 'package:finway/utils/dark_theme_provider.dart';
import 'package:finway/widget/StarRating.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_osm_plugin/flutter_osm_plugin.dart';
import 'package:get/get.dart';
import 'package:location/location.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';

import '../../constant/image_constant.dart';
import '../../service/api.dart';

class ParcelRouteOsmViewScreen extends StatefulWidget {
  const ParcelRouteOsmViewScreen({super.key});

  @override
  State<ParcelRouteOsmViewScreen> createState() => _ParcelRouteOsmViewScreenState();
}

class _ParcelRouteOsmViewScreenState extends State<ParcelRouteOsmViewScreen> {
  dynamic argumentData = Get.arguments;

  late MapController mapController;

  Map<String, GeoPoint> markers = <String, GeoPoint>{};

  Widget? departureIcon;
  Widget? destinationIcon;
  Widget? taxiIcon;
  Widget? stopIcon;

  GeoPoint? departureLatLong;
  GeoPoint? destinationLatLong;

  String? type;
  ParcelData? parcelData;
  String driverEstimateArrivalTime = '';
  Timer? _driverLocationTimer;

  RoadInfo roadInfo = RoadInfo();

  @override
  void initState() {
    if (argumentData != null) {
      type = argumentData['type'];
      parcelData = argumentData['data'];
    }
    ShowToastDialog.showLoader("Please wait");
    mapController = MapController(initPosition: GeoPoint(latitude: 48.8561, longitude: 2.2930));
    setIcons();
    super.initState();
  }

  @override
  void dispose() {
    _driverLocationTimer?.cancel();
    super.dispose();
  }

  Future<void> _fetchDriverLocation() async {
    if (parcelData == null || parcelData!.id == null) return;
    try {
      final response = await Dio().get(
        "${API.getParcelDetails}?parcel_id=${parcelData!.id}",
        options: Options(headers: API.header),
      );
      if (response.statusCode == 200) {
        ParcelDetailsModel parcelDetails = ParcelDetailsModel.fromJson(response.data);
        if (parcelDetails.success == 'success' && parcelDetails.rideDetailsdata != null) {
          var data = parcelDetails.rideDetailsdata!;
          final oldStatus = parcelData!.status;

          if (data.status != null) {
            parcelData!.status = data.status;
          }
          parcelData!.idConducteur = data.idConducteur;
          parcelData!.nomConducteur = data.nomConducteur;
          parcelData!.prenomConducteur = data.prenomConducteur;
          parcelData!.driverName = (data.driverName != null && data.driverName!.isNotEmpty)
              ? data.driverName
              : "${data.prenomConducteur ?? ''} ${data.nomConducteur ?? ''}".trim();
          parcelData!.driverPhone = data.driverPhone;
          parcelData!.driverPhoto = data.driverPhoto;
          parcelData!.otp = data.otp;
          parcelData!.moyenne = data.moyenne;
          parcelData!.paymentStatus = data.paymentStatus;

          if (oldStatus == 'new' && parcelData!.status == 'confirmed') {
            ShowToastDialog.showToast("Delivery partner assigned!".tr);
          }

          if (mounted) setState(() {});

          final bool hasAssignedDriver = parcelData!.status != 'new' &&
              parcelData!.idConducteur != null &&
              parcelData!.idConducteur.toString() != 'null' &&
              parcelData!.idConducteur.toString().isNotEmpty;

          if (hasAssignedDriver &&
              data.driverLatitude != null && data.driverLatitude!.isNotEmpty &&
              data.driverLongitude != null && data.driverLongitude!.isNotEmpty) {
            double dLat = double.parse(data.driverLatitude!);
            double dLng = double.parse(data.driverLongitude!);

            departureLatLong = GeoPoint(latitude: dLat, longitude: dLng);

            WidgetsBinding.instance.addPostFrameCallback((_) async {
              if (markers.containsKey(parcelData!.id.toString())) {
                await mapController.removeMarker(markers[parcelData!.id.toString()]!);
              }
              await mapController
                  .addMarker(departureLatLong!,
                      markerIcon: MarkerIcon(iconWidget: taxiIcon),
                      angle: pi / 3,
                      iconAnchor: IconAnchor(
                        anchor: Anchor.top,
                      ))
                  .then((v) {
                markers[parcelData!.id.toString()] = departureLatLong!;
              });

              getDirections(dLat: dLat, dLng: dLng);
            });
            mapController.moveTo(departureLatLong!, animate: true);
          } else if (parcelData!.status == 'new') {
            // Remove driver marker if previously added
            if (markers.containsKey(parcelData!.id.toString())) {
              await mapController.removeMarker(markers[parcelData!.id.toString()]!);
              markers.remove(parcelData!.id.toString());
            }
          }
        }
      }
    } catch (e) {
      print("Error fetching driver location: $e");
    }
  }

  final controllerRideDetails = Get.put(ParcelDetailsController());
  final controllerDashBoard = Get.put(DashBoardController());

  getArgumentData() {
    if (argumentData != null) {
      type = argumentData['type'];
      parcelData = argumentData['data'];

      departureLatLong = GeoPoint(latitude: double.parse(parcelData!.latSource.toString()), longitude: double.parse(parcelData!.lngSource.toString()));
      destinationLatLong = GeoPoint(latitude: double.parse(parcelData!.latDestination.toString()), longitude: double.parse(parcelData!.lngDestination.toString()));

      getDirections(dLat: 0.0, dLng: 0.0);
      _fetchDriverLocation();

      _driverLocationTimer?.cancel();
      _driverLocationTimer = Timer.periodic(const Duration(seconds: 4), (timer) {
        _fetchDriverLocation();
      });
      updateCameraLocation(source: departureLatLong!, destination: destinationLatLong!, mapController: mapController);
    }
  }

  setIcons() async {
    departureIcon = Image.asset("assets/icons/pickup.png", width: 30, height: 30);

    destinationIcon = Image.asset("assets/icons/dropoff.png", width: 30, height: 30);

    taxiIcon = Image.asset("assets/icons/ic_taxi.png", width: 30, height: 30);

    stopIcon = Image.asset("assets/icons/location.png", width: 30, height: 30);
  }

  @override
  Widget build(BuildContext context) {
    final themeChange = Provider.of<DarkThemeProvider>(context);
    final isDark = themeChange.getThem();

    return Scaffold(
      body: Stack(
        alignment: Alignment.bottomCenter,
        children: [
          OSMFlutter(
              controller: mapController,
              osmOption: OSMOption(
                userTrackingOption: const UserTrackingOption(
                  enableTracking: false,
                  unFollowUser: false,
                ),
                zoomOption: const ZoomOption(
                  initZoom: 14,
                  minZoomLevel: 2,
                  maxZoomLevel: 19,
                  stepZoom: 1.0,
                ),
                roadConfiguration: RoadOption(
                  roadWidth: Platform.isIOS ? 50 : 10,
                  roadColor: Colors.blue,
                  roadBorderWidth: Platform.isIOS ? 15 : 10,
                  roadBorderColor: Colors.black,
                  zoomInto: true,
                ),
              ),
              onMapIsReady: (active) async {
                if (active) {
                  getArgumentData();
                  ShowToastDialog.closeLoader();
                }
              }),
          Positioned(
              top: 10,
              left: 8,
              child: SafeArea(
                child: Container(
                  decoration: BoxDecoration(
                    color: isDark ? Colors.black54 : Colors.white70,
                    shape: BoxShape.circle,
                  ),
                  child: IconButton(
                      onPressed: () {
                        Get.back();
                      },
                      icon: Icon(Icons.arrow_back_ios_new, color: isDark ? Colors.white : Colors.black, size: 20)),
                ),
              )),
          // Modern Curved Bottom Sheet
          _buildModernCurvedSheet(context, isDark, themeChange),
        ],
      ),
    );
  }

  Widget _buildModernCurvedSheet(BuildContext context, bool isDark, DarkThemeProvider themeChange) {
    if (parcelData == null) return const SizedBox.shrink();

    final status = (parcelData!.status ?? 'new').toLowerCase();
    final bool isSearching = status == 'new' ||
        parcelData!.idConducteur == null ||
        parcelData!.idConducteur.toString() == 'null' ||
        parcelData!.idConducteur.toString().isEmpty ||
        parcelData!.idConducteur.toString() == '0';
    final bool isConfirmed = status == 'confirmed' && !isSearching;
    final bool isOnRide = (status == 'onride' || status == 'on ride');
    final bool isCompleted = status == 'completed';

    return Container(
      width: double.infinity,
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.65,
      ),
      decoration: BoxDecoration(
        color: isDark ? AppThemeData.surface50Dark : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.15),
            blurRadius: 24,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: SingleChildScrollView(
          padding: const EdgeInsets.only(left: 20, right: 20, top: 12, bottom: 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Grab handle
              Center(
                child: Container(
                  width: 44,
                  height: 5,
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: isDark ? Colors.grey[700] : Colors.grey[300],
                    borderRadius: BorderRadius.circular(2.5),
                  ),
                ),
              ),

              if (isSearching)
                _buildSearchingCard(context, isDark)
              else if (isConfirmed)
                _buildConfirmedCard(context, isDark, themeChange)
              else if (isOnRide)
                _buildOnRideCard(context, isDark, themeChange)
              else if (isCompleted)
                _buildCompletedCard(context, isDark)
              else
                _buildSearchingCard(context, isDark),
            ],
          ),
        ),
      ),
    );
  }

  // ── Stage 1: Searching for Driver ─────────────────────────────────────────
  Widget _buildSearchingCard(BuildContext context, bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: Colors.amber.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.amber.shade700, width: 1),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SizedBox(
                    width: 12,
                    height: 12,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.amber.shade800,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    "Searching for Delivery Partner".tr,
                    style: TextStyle(
                      fontSize: 12,
                      fontFamily: AppThemeData.semiBold,
                      color: Colors.amber.shade800,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Text(
          "Looking for nearby couriers...".tr,
          style: TextStyle(
            fontSize: 18,
            fontFamily: AppThemeData.bold,
            color: isDark ? Colors.white : Colors.black87,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          "Notifying verified delivery partners near your pickup point.".tr,
          style: TextStyle(
            fontSize: 13,
            fontFamily: AppThemeData.regular,
            color: isDark ? Colors.grey[400] : Colors.grey[600],
          ),
        ),
        const SizedBox(height: 16),
        // Trip Summary Card
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: isDark ? AppThemeData.grey200Dark.withValues(alpha: 0.15) : AppThemeData.grey200.withValues(alpha: 0.45),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.radio_button_checked, size: 18, color: Colors.green),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      parcelData!.source ?? '',
                      style: TextStyle(
                        fontSize: 13,
                        fontFamily: AppThemeData.medium,
                        color: isDark ? Colors.white70 : Colors.black87,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              Padding(
                padding: const EdgeInsets.only(left: 8),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Container(width: 2, height: 16, color: Colors.grey[400]),
                ),
              ),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.location_on, size: 18, color: Colors.red),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      parcelData!.destination ?? '',
                      style: TextStyle(
                        fontSize: 13,
                        fontFamily: AppThemeData.medium,
                        color: isDark ? Colors.white70 : Colors.black87,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              const Divider(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    "Estimated Fare".tr,
                    style: TextStyle(
                      fontSize: 13,
                      fontFamily: AppThemeData.regular,
                      color: isDark ? Colors.grey[400] : Colors.grey[600],
                    ),
                  ),
                  Text(
                    Constant().amountShow(amount: parcelData!.amount.toString()),
                    style: TextStyle(
                      fontSize: 18,
                      fontFamily: AppThemeData.bold,
                      color: AppThemeData.primary200,
                    ),
                  ),
                ],
              )
            ],
          ),
        ),
        const SizedBox(height: 16),
        ButtonThem.buildButton(
          context,
          title: 'Cancel Request'.tr,
          btnColor: AppThemeData.error200,
          txtColor: Colors.white,
          btnWidthRatio: 1.0,
          onPress: () => buildShowBottomSheet(context, isDark),
        ),
      ],
    );
  }

  // ── Stage 2: Driver Assigned (Heading to Pickup) ───────────────────────────
  Widget _buildConfirmedCard(BuildContext context, bool isDark, DarkThemeProvider themeChange) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: Colors.blue.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.blue.shade600, width: 1),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.two_wheeler, size: 14, color: Colors.blue.shade700),
                  const SizedBox(width: 6),
                  Text(
                    "Partner Assigned".tr,
                    style: TextStyle(
                      fontSize: 12,
                      fontFamily: AppThemeData.semiBold,
                      color: Colors.blue.shade700,
                    ),
                  ),
                ],
              ),
            ),
            if (driverEstimateArrivalTime.isNotEmpty)
              Text(
                driverEstimateArrivalTime,
                style: TextStyle(
                  fontSize: 13,
                  fontFamily: AppThemeData.bold,
                  color: AppThemeData.primary200,
                ),
              ),
          ],
        ),
        const SizedBox(height: 10),
        Text(
          "Partner is heading to your pickup point".tr,
          style: TextStyle(
            fontSize: 17,
            fontFamily: AppThemeData.bold,
            color: isDark ? Colors.white : Colors.black87,
          ),
        ),
        const SizedBox(height: 12),
        // PROMINENT PICKUP OTP CARD
        if (parcelData!.otp != null && parcelData!.otp!.isNotEmpty)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: AppThemeData.primary200.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppThemeData.primary200, width: 1.5),
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.pin, size: 18, color: AppThemeData.primary200),
                    const SizedBox(width: 6),
                    Text(
                      "PICKUP VERIFICATION OTP".tr,
                      style: TextStyle(
                        fontFamily: AppThemeData.bold,
                        fontSize: 13,
                        letterSpacing: 0.8,
                        color: isDark ? Colors.white : Colors.black87,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: parcelData!.otp!.split('').map((digit) {
                    return Container(
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      width: 38,
                      height: 44,
                      decoration: BoxDecoration(
                        color: isDark ? AppThemeData.surface50Dark : Colors.white,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: AppThemeData.primary200.withValues(alpha: 0.6)),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.05),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        digit,
                        style: TextStyle(
                          fontSize: 22,
                          fontFamily: AppThemeData.bold,
                          color: AppThemeData.primary200,
                        ),
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 6),
                Text(
                  "Share this OTP with courier at pickup handover".tr,
                  style: TextStyle(
                    fontSize: 11,
                    fontFamily: AppThemeData.regular,
                    color: isDark ? Colors.grey[400] : Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
        const SizedBox(height: 12),
        // Driver profile row
        _buildDriverRow(context, isDark, themeChange),
        const SizedBox(height: 12),
        ButtonThem.buildBorderButton(
          context,
          title: 'Cancel Booking'.tr,
          btnColor: Colors.transparent,
          txtColor: AppThemeData.error200,
          btnBorderColor: AppThemeData.error200,
          btnHeight: 44,
          btnWidthRatio: 1.0,
          onPress: () => buildShowBottomSheet(context, isDark),
        ),
      ],
    );
  }

  // ── Stage 3: In Transit (On Ride) ─────────────────────────────────────────
  Widget _buildOnRideCard(BuildContext context, bool isDark, DarkThemeProvider themeChange) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: Colors.teal.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.teal.shade700, width: 1),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.local_shipping, size: 14, color: Colors.teal.shade700),
                  const SizedBox(width: 6),
                  Text(
                    "In Transit".tr,
                    style: TextStyle(
                      fontSize: 12,
                      fontFamily: AppThemeData.semiBold,
                      color: Colors.teal.shade700,
                    ),
                  ),
                ],
              ),
            ),
            if (driverEstimateArrivalTime.isNotEmpty)
              Text(
                driverEstimateArrivalTime,
                style: TextStyle(
                  fontSize: 13,
                  fontFamily: AppThemeData.bold,
                  color: AppThemeData.primary200,
                ),
              ),
          ],
        ),
        const SizedBox(height: 10),
        Text(
          "Delivering parcel to destination".tr,
          style: TextStyle(
            fontSize: 17,
            fontFamily: AppThemeData.bold,
            color: isDark ? Colors.white : Colors.black87,
          ),
        ),
        const SizedBox(height: 10),
        // Dropoff info
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: isDark ? AppThemeData.grey200Dark.withValues(alpha: 0.15) : AppThemeData.grey200.withValues(alpha: 0.45),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Row(
            children: [
              const Icon(Icons.location_on, color: Colors.red, size: 22),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Delivery To: ${parcelData!.receiverName ?? 'Receiver'}".tr,
                      style: TextStyle(
                        fontSize: 13,
                        fontFamily: AppThemeData.semiBold,
                        color: isDark ? Colors.white : Colors.black87,
                      ),
                    ),
                    Text(
                      parcelData!.destination ?? '',
                      style: TextStyle(
                        fontSize: 12,
                        fontFamily: AppThemeData.regular,
                        color: isDark ? Colors.grey[400] : Colors.grey[600],
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              if (parcelData!.receiverPhone != null && parcelData!.receiverPhone!.isNotEmpty)
                IconButton(
                  onPressed: () => Constant.makePhoneCall(parcelData!.receiverPhone!),
                  icon: const Icon(Icons.phone, color: Colors.green),
                ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        _buildDriverRow(context, isDark, themeChange),
        if (parcelData!.paymentStatus != "yes") ...[
          const SizedBox(height: 12),
          ButtonThem.buildButton(
            context,
            btnColor: AppThemeData.primary200,
            title: 'Pay Now'.tr,
            btnWidthRatio: 1.0,
            onPress: () async {
              Get.to(ParcelPaymentSelectionScreen(), arguments: {
                "parcelData": parcelData,
              });
            },
          ),
        ],
      ],
    );
  }

  // ── Stage 4: Completed ───────────────────────────────────────────────────
  Widget _buildCompletedCard(BuildContext context, bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        const Icon(Icons.check_circle, size: 54, color: Colors.green),
        const SizedBox(height: 8),
        Text(
          "Parcel Delivered Successfully!".tr,
          style: TextStyle(
            fontSize: 18,
            fontFamily: AppThemeData.bold,
            color: isDark ? Colors.white : Colors.black87,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          "Total Amount: ${Constant().amountShow(amount: parcelData!.amount.toString())}",
          style: TextStyle(
            fontSize: 14,
            fontFamily: AppThemeData.medium,
            color: isDark ? Colors.grey[300] : Colors.grey[700],
          ),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: ButtonThem.buildBorderButton(
                context,
                title: 'All Parcels'.tr,
                btnColor: Colors.transparent,
                txtColor: isDark ? Colors.white : Colors.black87,
                btnBorderColor: Colors.grey,
                btnHeight: 45,
                onPress: () => Get.offAll(() => const AllParcelScreen()),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: ButtonThem.buildButton(
                context,
                title: 'Rate Driver'.tr,
                btnColor: AppThemeData.primary200,
                txtColor: Colors.black,
                btnHeight: 45,
                onPress: () => Get.to(const AddReviewScreen(), arguments: {
                  "data": parcelData,
                  "ride_type": "parcel",
                }),
              ),
            ),
          ],
        ),
      ],
    );
  }

  // ── Shared Driver Profile Row ─────────────────────────────────────────────
  Widget _buildDriverRow(BuildContext context, bool isDark, DarkThemeProvider themeChange) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: isDark ? AppThemeData.grey200Dark.withValues(alpha: 0.15) : AppThemeData.grey200.withValues(alpha: 0.45),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(30),
            child: CachedNetworkImage(
              imageUrl: parcelData!.driverPhoto.toString(),
              height: 50,
              width: 50,
              fit: BoxFit.cover,
              placeholder: (context, url) => Constant.loader(context),
              errorWidget: (context, url, error) => Image.asset(ImageConstant.logo, width: 50, height: 50),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "${parcelData!.driverName ?? 'Driver'}",
                  style: TextStyle(
                    fontFamily: AppThemeData.semiBold,
                    color: isDark ? AppThemeData.grey900Dark : AppThemeData.grey900,
                    fontSize: 15,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Row(
                  children: [
                    StarRating(
                      size: 16,
                      rating: parcelData!.moyenne != null && parcelData!.moyenne != "null"
                          ? double.tryParse(parcelData!.moyenne.toString()) ?? 5.0
                          : 5.0,
                      color: AppThemeData.warning200,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      parcelData!.moyenne != null && parcelData!.moyenne != "null"
                          ? double.tryParse(parcelData!.moyenne.toString())?.toStringAsFixed(1) ?? '5.0'
                          : '5.0',
                      style: TextStyle(
                        fontSize: 12,
                        fontFamily: AppThemeData.medium,
                        color: isDark ? Colors.grey[400] : Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          InkWell(
            onTap: () async {
              ShowToastDialog.showLoader("Please wait".tr);
              final Location currentLocation = Location();
              LocationData location = await currentLocation.getLocation();
              ShowToastDialog.closeLoader();
              await Share.share(
                'https://www.google.com/maps/search/?api=1&query=${location.latitude},${location.longitude}',
                subject: "Track My Parcel".tr,
              );
            },
            child: Container(
              height: 40,
              width: 40,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppThemeData.secondary200.withValues(alpha: 0.15),
              ),
              child: Icon(Icons.share, size: 20, color: AppThemeData.secondary200),
            ),
          ),
          const SizedBox(width: 8),
          InkWell(
            onTap: () {
              if (parcelData!.driverPhone != null && parcelData!.driverPhone!.isNotEmpty) {
                Constant.makePhoneCall(parcelData!.driverPhone!);
              }
            },
            child: Container(
              height: 40,
              width: 40,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.green.withValues(alpha: 0.15),
              ),
              child: const Icon(Icons.call, size: 20, color: Colors.green),
            ),
          ),
        ],
      ),
    );
  }

  final resonController = TextEditingController();

  buildShowBottomSheet(BuildContext context, bool isDarkMode) {
    return showModalBottomSheet(
        shape: const RoundedRectangleBorder(borderRadius: BorderRadius.only(topRight: Radius.circular(15), topLeft: Radius.circular(15))),
        context: context,
        isDismissible: true,
        isScrollControlled: true,
        backgroundColor: isDarkMode ? AppThemeData.surface50Dark : AppThemeData.surface50,
        builder: (context) {
          return StatefulBuilder(builder: (context, setState) {
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 15.0, vertical: 10),
              child: Padding(
                padding: MediaQuery.of(context).viewInsets,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      child: Text(
                        "Cancel Parcel".tr,
                        style: TextStyle(
                          fontSize: 18,
                          fontFamily: AppThemeData.semiBold,
                          color: isDarkMode ? AppThemeData.grey900Dark : AppThemeData.grey900,
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.only(top: 10),
                      child: Text(
                        "Write a reason for Parcel cancellation".tr,
                        style: TextStyle(
                          fontSize: 14,
                          fontFamily: AppThemeData.regular,
                          color: isDarkMode ? AppThemeData.grey400 : AppThemeData.grey300Dark,
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: TextFieldWidget(
                        maxLine: 3,
                        controller: resonController,
                        hintText: '',
                        fontSize: 14,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.only(top: 20),
                      child: Row(
                        children: [
                          Expanded(
                            child: Padding(
                              padding: const EdgeInsets.only(bottom: 5),
                              child: ButtonThem.buildButton(
                                context,
                                title: 'Submit'.tr,
                                btnWidthRatio: 0.8,
                                onPress: () async {
                                  if (resonController.text.isNotEmpty) {
                                    Get.back();
                                    showDialog(
                                      barrierColor: Colors.black26,
                                      context: context,
                                      builder: (context) {
                                        return CustomAlertDialog(
                                          title: "Do you want to cancel this booking?".tr,
                                          onPressNegative: () {
                                            Get.back();
                                          },
                                            onPressPositive: () {
                                              if (parcelData!.status.toString() == "new") {
                                                Map<String, String> bodyParams = {
                                                  'parcel_id': parcelData!.id.toString(),
                                                  'reason': resonController.text.toString(),
                                                };
                                                controllerRideDetails.rejectParcel(bodyParams).then((value) {
                                                  Get.back();
                                                  if (value != null) {
                                                    if (Get.isRegistered<ParcelOrderController>()) {
                                                      Get.find<ParcelOrderController>().getParcel();
                                                    }
                                                    showDialog(
                                                        context: context,
                                                        builder: (BuildContext context) {
                                                          return CustomDialogBox(
                                                            title: "Cancel Successfully".tr,
                                                            descriptions: "Parcel Successfully cancel.".tr,
                                                            onPress: () {
                                                              Get.back();
                                                              if (Get.isRegistered<ParcelOrderController>()) {
                                                                Get.find<ParcelOrderController>().getParcel();
                                                              }
                                                              Get.offAll(() => const AllParcelScreen());
                                                            },
                                                            img: Image.asset('assets/images/green_checked.png'),
                                                          );
                                                        });
                                                  }
                                                });
                                              } else {
                                                Map<String, String> bodyParams = {
                                                  'id_parcel': parcelData!.id.toString(),
                                                  'id_user': parcelData!.idConducteur?.toString() ?? '',
                                                  'name': "${parcelData!.senderName}",
                                                  'from_id': Preferences.getInt(Preferences.userId).toString(),
                                                  'user_cat': controllerRideDetails.userModel?.data?.userCat?.toString() ?? 'user_app',
                                                  'reason': resonController.text.toString(),
                                                };
                                                controllerRideDetails.canceledParcel(bodyParams).then((value) {
                                                  Get.back();
                                                  if (value != null) {
                                                    if (Get.isRegistered<ParcelOrderController>()) {
                                                      Get.find<ParcelOrderController>().getParcel();
                                                    }
                                                    showDialog(
                                                        context: context,
                                                        builder: (BuildContext context) {
                                                          return CustomDialogBox(
                                                            title: "Cancel Successfully".tr,
                                                            descriptions: "Parcel Successfully cancel.".tr,
                                                            onPress: () {
                                                              Get.back();
                                                              if (Get.isRegistered<ParcelOrderController>()) {
                                                                Get.find<ParcelOrderController>().getParcel();
                                                              }
                                                              Get.offAll(() => const AllParcelScreen());
                                                            },
                                                            img: Image.asset('assets/images/green_checked.png'),
                                                          );
                                                        });
                                                  }
                                                });
                                              }
                                            },
                                        );
                                      },
                                    );
                                  } else {
                                    ShowToastDialog.showToast("Please enter a reason");
                                  }
                                },
                              ),
                            ),
                          ),
                          Expanded(
                            child: Padding(
                              padding: const EdgeInsets.only(bottom: 5, left: 10),
                              child: ButtonThem.buildBorderButton(
                                context,
                                title: 'Close'.tr,
                                btnWidthRatio: 0.8,
                                btnColor: isDarkMode ? AppThemeData.surface50Dark : AppThemeData.surface50,
                                txtColor: AppThemeData.primary200,
                                btnBorderColor: AppThemeData.primary200,
                                onPress: () async {
                                  Get.back();
                                },
                              ),
                            ),
                          ),
                        ],
                      ),
                    )
                  ],
                ),
              ),
            );
          });
        });
  }

  drawRoad({required GeoPoint startPoint, required GeoPoint lastPoint}) async {
    await mapController.removeLastRoad();
    roadInfo = await mapController.drawRoad(
      startPoint,
      lastPoint,
      roadType: RoadType.car,
      roadOption: RoadOption(
        roadWidth: Platform.isIOS ? 50 : 10,
        roadColor: Colors.blue,
        roadBorderWidth: Platform.isIOS ? 15 : 10, // Set the road border width (outline)
        roadBorderColor: Colors.black, // Border color
        zoomInto: true,
      ),
    );
    int hours = (roadInfo.duration! ~/ 3600);
    int minutes = ((roadInfo.duration! % 3600) / 60).round();
    setState(() {
      driverEstimateArrivalTime = '$hours hours $minutes minutes';
    });
  }

  getDirections({required double dLat, required double dLng}) async {
    if (markers.containsKey('Departure')) {
      await mapController.removeMarker(markers['Departure']!);
    }
    await mapController
        .addMarker(
            GeoPoint(
              latitude: double.parse(parcelData!.latSource.toString()),
              longitude: double.parse(parcelData!.lngSource.toString()),
            ),
            markerIcon: MarkerIcon(iconWidget: departureIcon),
            angle: pi / 3,
            iconAnchor: IconAnchor(
              anchor: Anchor.top,
            ))
        .then((v) {
      markers['Departure'] = GeoPoint(
        latitude: double.parse(parcelData!.latSource.toString()),
        longitude: double.parse(parcelData!.lngSource.toString()),
      );
    });

    if (markers.containsKey('Destination')) {
      await mapController.removeMarker(markers['Destination']!);
    }
    await mapController
        .addMarker(destinationLatLong!,
            markerIcon: MarkerIcon(iconWidget: destinationIcon),
            angle: pi / 3,
            iconAnchor: IconAnchor(
              anchor: Anchor.top,
            ))
        .then((v) {
      markers['Destination'] = destinationLatLong!;
    });

    final bool isConfirmed = parcelData!.status == "confirmed" && dLat != 0.0 && dLng != 0.0;
    final bool isOnRide = (parcelData!.status == "on ride" || parcelData!.status == "onride") && dLat != 0.0 && dLng != 0.0;

    if (isConfirmed) {
      drawRoad(
        startPoint: GeoPoint(latitude: dLat, longitude: dLng),
        lastPoint: GeoPoint(
          latitude: double.parse(parcelData!.latSource.toString()),
          longitude: double.parse(parcelData!.lngSource.toString()),
        ),
      );
    } else if (isOnRide) {
      drawRoad(
        startPoint: GeoPoint(latitude: dLat, longitude: dLng),
        lastPoint: GeoPoint(
          latitude: destinationLatLong!.latitude,
          longitude: destinationLatLong!.longitude,
        ),
      );
    } else {
      drawRoad(
        startPoint: GeoPoint(
          latitude: double.parse(parcelData!.latSource.toString()),
          longitude: double.parse(parcelData!.lngSource.toString()),
        ),
        lastPoint: GeoPoint(
          latitude: destinationLatLong!.latitude,
          longitude: destinationLatLong!.longitude,
        ),
      );
    }
  }

  Future<void> updateCameraLocation({required GeoPoint source, required GeoPoint destination, required MapController mapController}) async {
    BoundingBox bounds;

    if (source.latitude > destination.latitude && source.longitude > destination.longitude) {
      bounds = BoundingBox(
        north: source.latitude,
        south: destination.latitude,
        east: source.longitude,
        west: destination.longitude,
      );
    } else if (source.longitude > destination.longitude) {
      bounds = BoundingBox(
        north: destination.latitude,
        south: source.latitude,
        east: source.longitude,
        west: destination.longitude,
      );
    } else if (source.latitude > destination.latitude) {
      bounds = BoundingBox(
        north: source.latitude,
        south: destination.latitude,
        east: destination.longitude,
        west: source.longitude,
      );
    } else {
      bounds = BoundingBox(
        north: destination.latitude,
        south: source.latitude,
        east: destination.longitude,
        west: source.longitude,
      );
    }

    await mapController.zoomToBoundingBox(bounds, paddinInPixel: 300);

    // Verify the camera location
    await checkCameraLocation(bounds, mapController);
  }

  Future<void> checkCameraLocation(BoundingBox bounds, MapController mapController) async {
    // await mapController.rotateMapCamera(0);
    BoundingBox currentBounds = await mapController.bounds;

    if (currentBounds.north == -90 || currentBounds.south == -90) {
      return checkCameraLocation(bounds, mapController);
    }
  }
}
