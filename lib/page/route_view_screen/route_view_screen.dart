import 'dart:async';
import 'dart:math' as math;
import 'dart:developer' as dev;
import 'package:firebase_database/firebase_database.dart';
import 'package:finway/constant/constant.dart';
import 'package:finway/constant/show_toast_dialog.dart';
import 'package:finway/controller/dash_board_controller.dart';
import 'package:finway/controller/ride_details_controller.dart';
import 'package:finway/model/ride_model.dart';
import 'package:finway/model/ride_details_model.dart';
import 'package:finway/page/chats_screen/conversation_screen.dart';
import 'package:finway/page/completed_ride_screens/payment_selection_screen.dart';
import 'package:finway/page/completed_ride_screens/trip_history_screen.dart';
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
import 'package:flutter_polyline_points/flutter_polyline_points.dart';
import 'package:flutter_svg/svg.dart';
import 'package:get/get.dart';
import 'package:finway/page/features/SmartValue/ScanAndTransfer/view/scanner_and_transfer_screen.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:location/location.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';

import '../../constant/image_constant.dart';
import '../../service/api.dart';

class RouteViewScreen extends StatefulWidget {
  const RouteViewScreen({super.key});

  @override
  State<RouteViewScreen> createState() => _RouteViewScreenState();
}

class _RouteViewScreenState extends State<RouteViewScreen> {
  dynamic argumentData = Get.arguments;

  GoogleMapController? _controller;

  Map<PolylineId, Polyline> polyLines = {};

  PolylinePoints polylinePoints = PolylinePoints();

  BitmapDescriptor? departureIcon;
  BitmapDescriptor? destinationIcon;
  BitmapDescriptor? taxiIcon;
  BitmapDescriptor? stopIcon;

  late LatLng departureLatLong;
  late LatLng destinationLatLong;

  final Map<String, Marker> _markers = {};

  String? type;
  RideData? rideData;
  String driverEstimateArrivalTime = '';
  Timer? _driverLocationTimer;
  StreamSubscription? _driverLocationSubscription;

  /// Previous driver position for smooth marker interpolation.
  LatLng? _previousDriverLatLng;
  /// Timestamp of the last getDirections() call — throttled to every 15 s.
  DateTime? _directionsLastFetched;

  /// True once driver is ≤ 150 m from pickup — gates OTP panel visibility.
  bool _driverArrivedAtPickup = false;

  /// Returns the great-circle distance in metres between two lat/lng points.
  double _haversineMeters(double lat1, double lng1, double lat2, double lng2) {
    const double R = 6371000;
    const double degToRad = 0.017453292519943295;
    final double dLat = (lat2 - lat1) * degToRad;
    final double dLng = (lng2 - lng1) * degToRad;
    final double a = math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.cos(lat1 * degToRad) *
            math.cos(lat2 * degToRad) *
            math.sin(dLng / 2) *
            math.sin(dLng / 2);
    final double c = 2 * math.atan2(math.sqrt(a.clamp(0.0, 1.0)), math.sqrt((1 - a).clamp(0.0, 1.0)));
    return R * c;
  }

  /// Linearly animates the driver marker from [start] to [end] over ~500 ms.
  void _animateDriverMarker(LatLng start, LatLng end, double rotation) {
    const int steps = 30;
    int step = 0;
    final String markerId = rideData!.id.toString();
    Timer.periodic(const Duration(milliseconds: 16), (t) {
      step++;
      if (!mounted) { t.cancel(); return; }
      if (step >= steps) {
        t.cancel();
        setState(() {
          _markers[markerId] = _markers[markerId]!.copyWith(
            positionParam: end,
            rotationParam: rotation,
          );
        });
        return;
      }
      final double f = step / steps;
      final LatLng pos = LatLng(
        start.latitude + (end.latitude - start.latitude) * f,
        start.longitude + (end.longitude - start.longitude) * f,
      );
      if (_markers.containsKey(markerId)) {
        setState(() {
          _markers[markerId] = _markers[markerId]!.copyWith(
            positionParam: pos,
            rotationParam: rotation,
          );
        });
      }
    });
  }

  @override
  void initState() {
    super.initState();
    // ⚠️ setIcons() MUST complete before getArgumentData() starts Firebase
    // listeners. _listenDriverLocation() creates a Marker with taxiIcon! (null
    // check) immediately on first RTDB event — if icons haven't loaded yet it
    // throws "Null check operator used on a null value" → blank map, no route.
    setIcons().then((_) {
      getArgumentData();
    });
  }

  @override
  void dispose() {
    _driverLocationSubscription?.cancel();
    _driverLocationTimer?.cancel();
    super.dispose();
  }

  void _listenDriverLocation() {
    if (rideData == null || rideData!.idConducteur == null) return;
    _driverLocationSubscription = FirebaseDatabase.instance
        .ref("drivers/${rideData!.idConducteur}")
        .onValue
        .listen((event) async {
      if (event.snapshot.value == null) return;
      try {
        final data = event.snapshot.value as Map<dynamic, dynamic>;
        final latStr = data['driver_latitude']?.toString();
        final lngStr = data['driver_longitude']?.toString();
        final rotStr = data['rotation']?.toString() ?? '0.0';

        if (latStr != null && latStr.isNotEmpty && lngStr != null && lngStr.isNotEmpty) {
          final double dLat = double.parse(latStr);
          final double dLng = double.parse(lngStr);
          final double rotation = double.parse(rotStr);
          final LatLng target = LatLng(dLat, dLng);
          final String markerId = rideData!.id.toString();

          // Safety guard: taxiIcon must be loaded before creating markers.
          // initState chains setIcons().then(getArgumentData) so this should
          // always be non-null here, but guard defensively.
          if (taxiIcon == null) return;

          // Ensure the marker exists before animating
          if (!_markers.containsKey(markerId) && mounted) {
            setState(() {
              _markers[markerId] = Marker(
                markerId: MarkerId(markerId),
                infoWindow: InfoWindow(title: rideData!.prenomConducteur.toString()),
                position: target,
                icon: taxiIcon!,
                rotation: rotation,
              );
            });
            _previousDriverLatLng = target;
          } else if (_previousDriverLatLng != null && _previousDriverLatLng != target) {
            // Smooth interpolation from last known to new position
            _animateDriverMarker(_previousDriverLatLng!, target, rotation);
            _previousDriverLatLng = target;
          }

          departureLatLong = target;

          // ─── OTP PROXIMITY DETECTION ───────────────────────────────────────
          // Only reveal the OTP panel when the driver is ≤ 150 m from pickup,
          // not immediately upon ride confirmation.
          if (rideData!.statut == 'confirmed' && !_driverArrivedAtPickup) {
            try {
              final double pLat = double.parse(rideData!.latitudeDepart.toString());
              final double pLng = double.parse(rideData!.longitudeDepart.toString());
              final double dist = _haversineMeters(dLat, dLng, pLat, pLng);
              if (dist <= 150 && mounted) {
                setState(() { _driverArrivedAtPickup = true; });
              }
            } catch (_) {}
          }
          // ──────────────────────────────────────────────────────────────────

          // Throttle expensive Directions API redraw to once every 15 seconds
          final now = DateTime.now();
          if (_directionsLastFetched == null ||
              now.difference(_directionsLastFetched!).inSeconds >= 15) {
            _directionsLastFetched = now;
            try {
              dynamic durationResponse = await Dio().get(
                  "https://maps.googleapis.com/maps/api/distancematrix/json?units=imperial&origins=${rideData!.latitudeDepart},${rideData!.longitudeDepart}&destinations=$dLat,$dLng&key=${Constant.kGoogleApiKey}");
              driverEstimateArrivalTime = durationResponse.data['rows'][0]['elements'][0]['duration']['text'].toString();
            } catch (e) {
              dev.log("Error fetching distance matrix: $e");
            }
            if (mounted) getDirections(dLat: dLat, dLng: dLng);
          }
        }
      } catch (e) {
        dev.log("Error listening to driver RTDB: $e");
      }
    });
  }

  Future<void> _fetchDriverLocation() async {
    try {
      final response = await Dio().get(
        "${API.rideDetails}?ride_id=${rideData!.id}",
        options: Options(headers: API.header),
      );
      if (response.statusCode == 200) {
        RideDetailsModel rideDetails = RideDetailsModel.fromJson(response.data);
        if (rideDetails.success == 'success' && rideDetails.rideDetailsdata != null) {
          var data = rideDetails.rideDetailsdata!;
          String currentStatus = data.statut.toString();
          
          if (currentStatus == "completed") {
            _driverLocationTimer?.cancel();
            _driverLocationSubscription?.cancel();
            RideData completedRideData = RideData(
              id: data.id,
              idUserApp: data.idUserApp,
              departName: data.departName,
              destinationName: data.destinationName,
              latitudeDepart: data.latitudeDepart,
              longitudeDepart: data.longitudeDepart,
              latitudeArrivee: data.latitudeArrivee,
              longitudeArrivee: data.longitudeArrivee,
              place: data.place,
              numberPoeple: data.numberPoeple,
              distance: data.distance,
              duree: data.duree,
              montant: data.montant,
              trajet: data.trajet,
              statut: data.statut,
              statutPaiement: data.statutPaiement,
              idConducteur: data.idConducteur,
              creer: data.creer,
              dateRetour: data.dateRetour,
              heureRetour: data.heureRetour,
              statutRound: data.statutRound,
              otp: data.otp,
              nomConducteur: data.nomConducteur ?? "",
              prenomConducteur: data.prenomConducteur ?? "",
              photoPath: data.photoPath,
              driverPhone: data.driverPhone,
              moyenne: data.moyenne,
              stops: data.stops,
            );
            if (completedRideData.statutPaiement != 'yes') {
              Get.off(() => PaymentSelectionScreen(), arguments: {
                "rideData": completedRideData
              });
            } else {
              Get.off(() => TripHistoryScreen(), arguments: {
                "rideData": completedRideData
              });
            }
            return;
          }
          
          if (currentStatus == "rejected") {
            _driverLocationTimer?.cancel();
            _driverLocationSubscription?.cancel();
            ShowToastDialog.showToast("Ride was cancelled.");
            Get.back();
            return;
          }

          if (data.driverLatitude != null && data.driverLatitude!.isNotEmpty &&
              data.driverLongitude != null && data.driverLongitude!.isNotEmpty) {
            double dLat = double.parse(data.driverLatitude!);
            double dLng = double.parse(data.driverLongitude!);

            try {
              dynamic durationResponse = await Dio().get(
                  "https://maps.googleapis.com/maps/api/distancematrix/json?units=imperial&origins=${rideData!.latitudeDepart},${rideData!.longitudeDepart}&destinations=$dLat,$dLng&key=${Constant.kGoogleApiKey}");
              driverEstimateArrivalTime = durationResponse.data['rows'][0]['elements'][0]['duration']['text'].toString();
            } catch (e) {
              dev.log("Error fetching distance matrix: $e");
            }

            if (mounted) {
              setState(() {
                rideData!.statut = currentStatus;
                departureLatLong = LatLng(dLat, dLng);
                _markers[rideData!.id.toString()] = Marker(
                  markerId: MarkerId(rideData!.id.toString()),
                  infoWindow: InfoWindow(title: rideData!.prenomConducteur.toString()),
                  position: departureLatLong,
                  icon: taxiIcon!,
                  rotation: 0.0,
                );
                getDirections(dLat: dLat, dLng: dLng);
              });
            }
          }
        }
      }
    } catch (e) {
      dev.log("Error fetching driver location: $e");
    }
  }

  final controllerRideDetails = Get.put(RideDetailsController());
  final controllerDashBoard = Get.put(DashBoardController());

  getArgumentData() {
    if (argumentData != null) {
      type = argumentData['type'];
      rideData = argumentData['data'];

      departureLatLong = LatLng(double.parse(rideData!.latitudeDepart.toString()), double.parse(rideData!.longitudeDepart.toString()));
      destinationLatLong = LatLng(double.parse(rideData!.latitudeArrivee.toString()), double.parse(rideData!.longitudeArrivee.toString()));

      if (rideData!.statut == "on ride" || rideData!.statut == 'confirmed') {
        _listenDriverLocation();
        _fetchDriverLocation();
        _driverLocationTimer = Timer.periodic(const Duration(seconds: 5), (timer) {
          _fetchDriverLocation();
        });
      } else {
        getDirections(dLat: 0.0, dLng: 0.0);
      }
    }
  }

  Future<void> setIcons() async {
    departureIcon = await BitmapDescriptor.fromAssetImage(const ImageConfiguration(size: Size(10, 10)), "assets/icons/pickup.png");
    destinationIcon = await BitmapDescriptor.fromAssetImage(const ImageConfiguration(size: Size(10, 10)), "assets/icons/dropoff.png");
    taxiIcon = await BitmapDescriptor.fromAssetImage(const ImageConfiguration(size: Size(10, 10)), "assets/icons/ic_taxi.png");
    stopIcon = await BitmapDescriptor.fromAssetImage(const ImageConfiguration(size: Size(10, 10)), "assets/icons/location.png");
  }

  @override
  Widget build(BuildContext context) {
    final themeChange = Provider.of<DarkThemeProvider>(context);
    return Scaffold(
      body: Stack(
        alignment: Alignment.bottomCenter,
        children: [
          GoogleMap(
            zoomControlsEnabled: false,
            myLocationButtonEnabled: false,
            myLocationEnabled: false,
            initialCameraPosition: const CameraPosition(
              target: LatLng(48.8561, 2.2930),
              zoom: 14.0,
            ),
            onMapCreated: (GoogleMapController controller) {
              _controller = controller;
              _controller!.moveCamera(CameraUpdate.newLatLngZoom(departureLatLong, 12));
            },
            polylines: Set<Polyline>.of(polyLines.values),
            markers: _markers.values.toSet(),
          ),
          Positioned(
            top: 10,
            left: 5,
            child: SafeArea(
              child: IconButton(
                onPressed: () => Get.back(),
                icon: Transform(
                  alignment: Alignment.center,
                  transform: Directionality.of(context) == TextDirection.rtl ? Matrix4.rotationY(3.14159) : Matrix4.identity(),
                  child: SvgPicture.asset(
                    'assets/icons/ic_left.svg',
                    width: 35,
                    height: 35,
                    colorFilter: ColorFilter.mode(
                      AppThemeData.grey900,
                      BlendMode.srcIn,
                    ),
                  ),
                ),
              ),
            ),
          ),
          Container(
            decoration: BoxDecoration(
              color: themeChange.getThem() ? AppThemeData.surface50Dark : Colors.white,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(28),
                topRight: Radius.circular(28),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.12),
                  blurRadius: 20,
                  offset: const Offset(0, -4),
                )
              ],
            ),
            child: SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Handle line
                    Center(
                      child: Container(
                        width: 44,
                        height: 5,
                        decoration: BoxDecoration(
                          color: Colors.grey.shade300,
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Success Banner
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: const BoxDecoration(
                            color: Color(0xFFD1FAE5),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.check_circle_rounded,
                            color: Color(0xFF10B981),
                            size: 24,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                rideData!.statut == "on ride"
                                    ? "Trip in Progress".tr
                                    : "Your Ride is Confirmed!".tr,
                                style: TextStyle(
                                  fontFamily: AppThemeData.bold,
                                  fontSize: 16,
                                  color: themeChange.getThem() ? AppThemeData.grey900Dark : AppThemeData.grey900,
                                ),
                              ),
                              const SizedBox(height: 2),
                               Text(
                                rideData!.statut == "on ride"
                                    ? "Heading to your destination".tr
                                    : _driverArrivedAtPickup
                                        ? "Captain has arrived at pickup point".tr
                                        : "Captain is on the way to pickup".tr,
                                style: TextStyle(
                                  fontFamily: AppThemeData.medium,
                                  fontSize: 12,
                                  color: themeChange.getThem() ? AppThemeData.grey500Dark : AppThemeData.grey500,
                                ),
                              ),
                            ],
                          ),
                        ),
                        if (rideData!.statut == 'confirmed' && driverEstimateArrivalTime.isNotEmpty)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                            decoration: BoxDecoration(
                              color: AppThemeData.primary200.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              driverEstimateArrivalTime,
                              style: TextStyle(
                                fontFamily: AppThemeData.bold,
                                fontSize: 13,
                                color: AppThemeData.primary200,
                              ),
                            ),
                          ),
                      ],
                    ),
                    const Divider(height: 28, thickness: 1),

                    // OTP Alert if active, confirmed and arrived (or fallback if OTP is present)
                    if (Constant.rideOtp.toString().toLowerCase() == 'yes'.toLowerCase() && rideData!.statut == 'confirmed' && rideData!.rideType != 'driver') ...[
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: _driverArrivedAtPickup
                              ? const Color(0xFF10B981).withValues(alpha: 0.1)
                              : AppThemeData.primary200.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: _driverArrivedAtPickup
                                ? const Color(0xFF10B981).withValues(alpha: 0.3)
                                : AppThemeData.primary200.withValues(alpha: 0.15),
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                Icon(
                                  _driverArrivedAtPickup ? Icons.verified_user : Icons.pin,
                                  color: _driverArrivedAtPickup ? const Color(0xFF10B981) : AppThemeData.primary200,
                                  size: 18,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  _driverArrivedAtPickup
                                      ? "Captain Arrived! Share OTP:".tr
                                      : "Start OTP:".tr,
                                  style: TextStyle(
                                    fontFamily: AppThemeData.medium,
                                    fontSize: 13,
                                    color: themeChange.getThem() ? AppThemeData.grey900Dark : AppThemeData.grey900,
                                  ),
                                ),
                              ],
                            ),
                            Text(
                              rideData!.otp.toString(),
                              style: TextStyle(
                                fontFamily: AppThemeData.bold,
                                fontSize: 16,
                                letterSpacing: 1.5,
                                color: _driverArrivedAtPickup ? const Color(0xFF10B981) : AppThemeData.primary200,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],

                    // Driver details card
                    Row(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(30),
                          child: CachedNetworkImage(
                            imageUrl: rideData!.photoPath.toString(),
                            height: 54,
                            width: 54,
                            fit: BoxFit.cover,
                            placeholder: (context, url) => Constant.loader(context),
                            errorWidget: (context, url, error) => Image.asset(ImageConstant.logo),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                "${rideData!.prenomConducteur.toString()} ${rideData!.nomConducteur.toString()}",
                                style: TextStyle(
                                  fontFamily: AppThemeData.bold,
                                  fontSize: 15,
                                  color: themeChange.getThem() ? AppThemeData.grey900Dark : AppThemeData.grey900,
                                ),
                              ),
                              const SizedBox(height: 3),
                              Row(
                                children: [
                                  const Icon(Icons.star_rounded, color: Colors.amber, size: 16),
                                  const SizedBox(width: 4),
                                  Text(
                                    rideData!.moyenne != "null" ? rideData!.moyenne.toString() : "5.0",
                                    style: TextStyle(
                                      fontFamily: AppThemeData.medium,
                                      fontSize: 12,
                                      color: themeChange.getThem() ? AppThemeData.grey500Dark : AppThemeData.grey500,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Container(
                                    width: 4,
                                    height: 4,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: Colors.grey.shade400,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      "${rideData!.color ?? ''} ${rideData!.brand ?? ''} ${rideData!.model ?? ''}",
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                        fontFamily: AppThemeData.medium,
                                        fontSize: 12,
                                        color: themeChange.getThem() ? AppThemeData.grey500Dark : AppThemeData.grey500,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Text(
                                rideData!.numberplate ?? "",
                                style: TextStyle(
                                  fontFamily: AppThemeData.bold,
                                  fontSize: 12,
                                  color: AppThemeData.primary200,
                                ),
                              ),
                            ],
                          ),
                        ),
                        
                        // Action buttons row
                        Row(
                          children: [
                            if (rideData!.statut == "confirmed")
                              IconButton(
                                icon: const Icon(Icons.chat_bubble_outline, color: Colors.blue),
                                onPressed: () {
                                  Get.to(ConversationScreen(), arguments: {
                                    'receiverId': int.parse(rideData!.idConducteur.toString()),
                                    'orderId': int.parse(rideData!.id.toString()),
                                    'receiverName': "${rideData!.prenomConducteur} ${rideData!.nomConducteur}",
                                    'receiverPhoto': rideData!.photoPath
                                  });
                                },
                              ),
                            IconButton(
                              icon: const Icon(Icons.phone_outlined, color: Colors.green),
                              onPressed: () {
                                Constant.makePhoneCall(rideData!.driverPhone.toString());
                              },
                            ),
                          ],
                        )
                      ],
                    ),
                    const Divider(height: 28, thickness: 1),

                    // Trip Summary details
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Column(
                          children: [
                            const Icon(Icons.circle, color: Colors.green, size: 10),
                            Container(
                              width: 1.5,
                              height: 36,
                              color: Colors.grey.shade300,
                            ),
                            const Icon(Icons.circle, color: Colors.red, size: 10),
                          ],
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                rideData!.departName ?? "",
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontFamily: AppThemeData.regular,
                                  fontSize: 13,
                                  color: themeChange.getThem() ? AppThemeData.grey500Dark : AppThemeData.grey500,
                                ),
                              ),
                              const SizedBox(height: 24),
                              Text(
                                rideData!.destinationName ?? "",
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontFamily: AppThemeData.bold,
                                  fontSize: 13,
                                  color: themeChange.getThem() ? AppThemeData.grey900Dark : AppThemeData.grey900,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Grid details
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                "Fare Amount".tr,
                                style: TextStyle(
                                  fontFamily: AppThemeData.regular,
                                  fontSize: 11,
                                  color: Colors.grey,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                Constant().amountShow(amount: rideData!.montant!.toString()),
                                style: TextStyle(
                                  fontFamily: AppThemeData.bold,
                                  fontSize: 14,
                                  color: themeChange.getThem() ? AppThemeData.grey900Dark : AppThemeData.grey900,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                "Payment Method".tr,
                                style: TextStyle(
                                  fontFamily: AppThemeData.regular,
                                  fontSize: 11,
                                  color: Colors.grey,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                rideData!.payment ?? "Cash",
                                style: TextStyle(
                                  fontFamily: AppThemeData.bold,
                                  fontSize: 14,
                                  color: themeChange.getThem() ? AppThemeData.grey900Dark : AppThemeData.grey900,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                "Distance".tr,
                                style: TextStyle(
                                  fontFamily: AppThemeData.regular,
                                  fontSize: 11,
                                  color: Colors.grey,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                "${rideData!.distance} ${rideData!.distanceUnit}",
                                style: TextStyle(
                                  fontFamily: AppThemeData.bold,
                                  fontSize: 14,
                                  color: themeChange.getThem() ? AppThemeData.grey900Dark : AppThemeData.grey900,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),

                    // Actions buttons at the very bottom
                    Row(
                      children: [
                        if (rideData!.statut == "on ride") ...[
                          Expanded(
                            child: ElevatedButton.icon(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppThemeData.primary200,
                                padding: const EdgeInsets.symmetric(vertical: 14),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              ),
                              onPressed: () {
                                Get.to(() => ScannerAndTransferScreen());
                              },
                              icon: const Icon(Icons.qr_code_scanner, color: Colors.white, size: 16),
                              label: Text("Pay & Get Cashback".tr, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12)),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: ElevatedButton.icon(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppThemeData.error200,
                                padding: const EdgeInsets.symmetric(vertical: 14),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              ),
                              onPressed: () async {
                                LocationData location = await Location().getLocation();
                                Map<String, dynamic> bodyParams = {
                                  'lat': location.latitude,
                                  'lng': location.longitude,
                                  'user_id': Preferences.getInt(Preferences.userId).toString(),
                                  'user_name': "${controllerRideDetails.userModel!.data!.prenom} ${controllerRideDetails.userModel!.data!.nom}",
                                  'user_cat': controllerRideDetails.userModel!.data!.userCat,
                                  'id_driver': rideData!.idConducteur,
                                  'feel_safe': 0,
                                  'trip_id': rideData!.id,
                                };
                                controllerRideDetails.feelNotSafe(bodyParams).then((value) {
                                  if (value != null && value['success'] == "success") {
                                    ShowToastDialog.showToast("Report submitted".tr);
                                  }
                                });
                              },
                              icon: const Icon(Icons.warning_amber_rounded, color: Colors.white, size: 16),
                              label: Text("SOS".tr, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12)),
                            ),
                          ),
                        ] else if (rideData!.statut != "rejected") ...[
                          Expanded(
                            child: OutlinedButton(
                              style: OutlinedButton.styleFrom(
                                side: BorderSide(color: AppThemeData.error200),
                                padding: const EdgeInsets.symmetric(vertical: 14),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              ),
                              onPressed: () => buildShowBottomSheet(context, themeChange.getThem()),
                              child: Text(
                                "Cancel Ride".tr,
                                style: TextStyle(color: AppThemeData.error200, fontWeight: FontWeight.bold),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: ElevatedButton.icon(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppThemeData.primary200,
                                padding: const EdgeInsets.symmetric(vertical: 14),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              ),
                              onPressed: () async {
                                ShowToastDialog.showLoader("Please wait".tr);
                                final Location currentLocation = Location();
                                LocationData location = await currentLocation.getLocation();
                                await Share.share(
                                  'https://www.google.com/maps/search/?api=1&query=${location.latitude},${location.longitude}',
                                  subject: "Cabme".tr,
                                );
                              },
                              icon: const Icon(Icons.share, color: Colors.white, size: 16),
                              label: Text(
                                "Share Trip".tr,
                                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                              ),
                            ),
                          ),
                        ]
                      ],
                    ),
                  ],
                ),
              ),
            ),
          )
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
                        "Cancel Trip".tr,
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
                        "Write a reason for trip cancellation".tr,
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
                                title: 'Cancel Trip'.tr,
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
                                            Map<String, String> bodyParams = {
                                              'id_ride': rideData!.id.toString(),
                                              'id_user': rideData!.idConducteur.toString(),
                                              'name': "${rideData!.prenom} ${rideData!.nom}",
                                              'from_id': Preferences.getInt(Preferences.userId).toString(),
                                              'user_cat': controllerRideDetails.userModel!.data!.userCat.toString(),
                                              'reason': resonController.text.toString(),
                                            };
                                            controllerRideDetails.canceledRide(bodyParams).then((value) {
                                              Get.back();
                                              if (value != null) {
                                                showDialog(
                                                    context: context,
                                                    builder: (BuildContext context) {
                                                      return CustomDialogBox(
                                                        title: "Cancel Successfully".tr,
                                                        descriptions: "Ride Successfully cancel.".tr,
                                                        onPress: () {
                                                          Get.back();
                                                          Get.back();
                                                          Get.back();
                                                        },
                                                        img: Image.asset('assets/images/green_checked.png'),
                                                      );
                                                    });
                                              }
                                            });
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

  getDirections({required double dLat, required double dLng}) async {
    List<LatLng> polylineCoordinates = [];
    PolylineResult result;
    List<PolylineWayPoint> wayPointList = [];
    if (rideData!.stops != null) {
      for (var i = 0; i < rideData!.stops!.length; i++) {
        wayPointList.add(PolylineWayPoint(location: rideData!.stops![i].location!));
      }
    }

    if (rideData!.statut == "confirmed") {
      PolylineRequest requestData = PolylineRequest(
        wayPoints: [],
        optimizeWaypoints: true,
        mode: TravelMode.driving,
        origin: PointLatLng(dLat, dLng),
        destination: PointLatLng(double.parse(rideData!.latitudeDepart.toString()), double.parse(rideData!.longitudeDepart.toString())),
      );
      result = await polylinePoints.getRouteBetweenCoordinates(
        googleApiKey: Constant.kGoogleApiKey.toString(),
        request: requestData,
      );
    } else if (rideData!.statut == "on ride") {
      PolylineRequest requestData = PolylineRequest(
        wayPoints: wayPointList,
        optimizeWaypoints: true,
        mode: TravelMode.driving,
        origin: PointLatLng(dLat, dLng),
        destination: PointLatLng(destinationLatLong.latitude, destinationLatLong.longitude),
      );
      result = await polylinePoints.getRouteBetweenCoordinates(
        googleApiKey: Constant.kGoogleApiKey.toString(),
        request: requestData,
      );
    } else {
      PolylineRequest requestData = PolylineRequest(
        wayPoints: wayPointList,
        optimizeWaypoints: true,
        mode: TravelMode.driving,
        origin: PointLatLng(departureLatLong.latitude, departureLatLong.longitude),
        destination: PointLatLng(destinationLatLong.latitude, destinationLatLong.longitude),
      );
      result = await polylinePoints.getRouteBetweenCoordinates(
        googleApiKey: Constant.kGoogleApiKey.toString(),
        request: requestData,
      );
    }

    _markers['Departure'] = Marker(
      markerId: const MarkerId('Departure'),
      infoWindow: const InfoWindow(title: "Departure"),
      position: LatLng(double.parse(rideData!.latitudeDepart.toString()), double.parse(rideData!.longitudeDepart.toString())),
      icon: departureIcon!,
    );

    _markers['Destination'] = Marker(
      markerId: const MarkerId('Destination'),
      infoWindow: const InfoWindow(title: "Destination"),
      position: destinationLatLong,
      icon: destinationIcon!,
    );

    if (rideData!.stops != null) {
      for (var i = 0; i < rideData!.stops!.length; i++) {
        _markers['${rideData!.stops![i]}'] = Marker(
          markerId: MarkerId('${rideData!.stops![i]}'),
          infoWindow: InfoWindow(title: rideData!.stops![i].location!),
          position: LatLng(double.parse(rideData!.stops![i].latitude!), double.parse(rideData!.stops![i].longitude!)),
          icon: stopIcon!,
        );
      }
    }

    if (result.points.isNotEmpty) {
      for (var point in result.points) {
        polylineCoordinates.add(LatLng(point.latitude, point.longitude));
      }
    }

    addPolyLine(polylineCoordinates);
  }

  addPolyLine(List<LatLng> polylineCoordinates) {
    PolylineId id = const PolylineId("poly");
    Polyline polyline = Polyline(
      polylineId: id,
      color: AppThemeData.primary200,
      points: polylineCoordinates,
      width: 6,
      geodesic: true,
    );
    polyLines[id] = polyline;
    updateCameraLocation(polylineCoordinates.first, polylineCoordinates.last, _controller);

    setState(() {});
  }

  Future<void> updateCameraLocation(
    LatLng source,
    LatLng destination,
    GoogleMapController? mapController,
  ) async {
    if (mapController == null) return;

    LatLngBounds bounds;

    if (source.latitude > destination.latitude && source.longitude > destination.longitude) {
      bounds = LatLngBounds(southwest: destination, northeast: source);
    } else if (source.longitude > destination.longitude) {
      bounds = LatLngBounds(southwest: LatLng(source.latitude, destination.longitude), northeast: LatLng(destination.latitude, source.longitude));
    } else if (source.latitude > destination.latitude) {
      bounds = LatLngBounds(southwest: LatLng(destination.latitude, source.longitude), northeast: LatLng(source.latitude, destination.longitude));
    } else {
      bounds = LatLngBounds(southwest: source, northeast: destination);
    }

    CameraUpdate cameraUpdate = CameraUpdate.newLatLngBounds(bounds, 10);

    return checkCameraLocation(cameraUpdate, mapController);
  }

  Future<void> checkCameraLocation(CameraUpdate cameraUpdate, GoogleMapController mapController) async {
    mapController.animateCamera(cameraUpdate);
    LatLngBounds l1 = await mapController.getVisibleRegion();
    LatLngBounds l2 = await mapController.getVisibleRegion();

    if (l1.southwest.latitude == -90 || l2.southwest.latitude == -90) {
      return checkCameraLocation(cameraUpdate, mapController);
    }
  }
}
