import 'dart:async';
import 'dart:convert';
import 'dart:math' as math;
import 'dart:developer' as dev;
import 'package:firebase_database/firebase_database.dart';
import 'package:finway/constant/constant.dart';
import 'package:finway/constant/show_toast_dialog.dart';
import 'package:finway/controller/dash_board_controller.dart';
import 'package:finway/controller/ride_details_controller.dart';
import 'package:finway/model/ride_model.dart';
import 'package:finway/page/chats_screen/conversation_screen.dart';
import 'package:finway/page/completed_ride_screens/payment_selection_screen.dart';
import 'package:finway/themes/button_them.dart';
import 'package:finway/themes/constant_colors.dart';
import 'package:finway/themes/custom_alert_dialog.dart';
import 'package:finway/themes/custom_dialog_box.dart';
import 'package:finway/themes/text_field_them.dart';
import 'package:finway/utils/Preferences.dart';
import 'package:finway/utils/dark_theme_provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
import 'package:flutter_polyline_points/flutter_polyline_points.dart';
import 'package:flutter_svg/svg.dart';
import 'package:get/get.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:location/location.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';

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

  LatLng? driverCurrentLocation;
  final DraggableScrollableController _sheetController = DraggableScrollableController();

  void _toggleSheet() {
    if (!_sheetController.isAttached) return;
    if (_sheetController.size > 0.25) {
      _sheetController.animateTo(
        0.16,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else {
      _sheetController.animateTo(
        0.68,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

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
    getArgumentData();
    setIcons().catchError((e) => dev.log("Error setting icons: $e"));
  }

  @override
  void dispose() {
    _driverLocationSubscription?.cancel();
    _driverLocationTimer?.cancel();
    _sheetController.dispose();
    resonController.dispose();
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

          driverCurrentLocation = target;

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
              final durationRes = await http.get(Uri.parse(
                  "https://maps.googleapis.com/maps/api/distancematrix/json?units=imperial&origins=${rideData!.latitudeDepart},${rideData!.longitudeDepart}&destinations=$dLat,$dLng&key=${Constant.kGoogleApiKey}"));
              if (durationRes.statusCode == 200) {
                final durationData = jsonDecode(durationRes.body);
                driverEstimateArrivalTime = durationData['rows'][0]['elements'][0]['duration']['text'].toString();
              }
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
    if (rideData == null || rideData!.id == null) return;
    try {
      final response = await http.get(
        Uri.parse("${API.rideDetails}?ride_id=${rideData!.id}"),
        headers: API.header,
      ).timeout(const Duration(seconds: 5));
      if (response.statusCode == 200) {
        Map<String, dynamic> rawJson = jsonDecode(response.body);
        dynamic rawItem = rawJson['data'] ?? rawJson['rideDetailsdata'];
        if (rawItem != null && rawItem is Map) {
          String currentStatus = (rawItem['statut'] ?? '').toString().toLowerCase();
          
          if (currentStatus == "completed") {
            _driverLocationTimer?.cancel();
            _driverLocationSubscription?.cancel();
            
            RideData completedRideData;
            try {
              completedRideData = RideData.fromJson(Map<String, dynamic>.from(rawItem));
            } catch (e) {
              dev.log("RideData parse error in completed handler: $e");
              completedRideData = RideData(
                id: (rawItem['id'] ?? rideData!.id).toString(),
                idUserApp: (rawItem['id_user_app'] ?? rideData!.idUserApp).toString(),
                idConducteur: (rawItem['id_conducteur'] ?? rideData!.idConducteur).toString(),
                montant: (rawItem['montant'] ?? rideData!.montant ?? '0').toString(),
                statut: 'completed',
                statutPaiement: (rawItem['statut_paiement'] ?? 'no').toString(),
                departName: (rawItem['depart_name'] ?? rideData!.departName).toString(),
                destinationName: (rawItem['destination_name'] ?? rideData!.destinationName).toString(),
                payment: (rawItem['payment'] ?? rideData!.payment ?? 'Cash').toString(),
              );
            }
            
            Get.offAll(() => PaymentSelectionScreen(), arguments: {
              "rideData": completedRideData
            });
            return;
          }
          
          if (currentStatus == "rejected") {
            _driverLocationTimer?.cancel();
            _driverLocationSubscription?.cancel();
            ShowToastDialog.showToast("Ride was cancelled.");
            Get.back();
            return;
          }

          if (mounted && rideData != null) {
            setState(() {
              if (rawItem['statut'] != null) rideData!.statut = rawItem['statut']?.toString();
              if (rawItem['brand'] != null && rawItem['brand'].toString().isNotEmpty) {
                rideData!.brand = rawItem['brand']?.toString();
              }
              if (rawItem['model'] != null && rawItem['model'].toString().isNotEmpty) {
                rideData!.model = rawItem['model']?.toString();
              }
              if (rawItem['color'] != null && rawItem['color'].toString().isNotEmpty) {
                rideData!.color = rawItem['color']?.toString();
              }
              if (rawItem['numberplate'] != null && rawItem['numberplate'].toString().isNotEmpty) {
                rideData!.numberplate = rawItem['numberplate']?.toString();
              }
              if (rawItem['passenger'] != null && rawItem['passenger'].toString().isNotEmpty) {
                rideData!.passenger = rawItem['passenger']?.toString();
              }
              if (rawItem['driverPhone'] != null || rawItem['driver_phone'] != null) {
                final p = (rawItem['driverPhone'] ?? rawItem['driver_phone'])?.toString();
                if (p != null && p.isNotEmpty && p != 'null') {
                  rideData!.driverPhone = p;
                }
              }
              if (rawItem['nomConducteur'] != null && rawItem['nomConducteur'].toString().isNotEmpty) {
                rideData!.nomConducteur = rawItem['nomConducteur']?.toString();
              }
              if (rawItem['prenomConducteur'] != null && rawItem['prenomConducteur'].toString().isNotEmpty) {
                rideData!.prenomConducteur = rawItem['prenomConducteur']?.toString();
              }
              if (rawItem['photo_path'] != null && rawItem['photo_path'].toString().isNotEmpty && rawItem['photo_path'].toString() != 'null') {
                rideData!.photoPath = rawItem['photo_path']?.toString();
              }
              if (rawItem['moyenne'] != null) {
                rideData!.moyenne = rawItem['moyenne']?.toString();
              }
              if (rawItem['distance_unit'] != null && rawItem['distance_unit'].toString().isNotEmpty) {
                rideData!.distanceUnit = rawItem['distance_unit']?.toString();
              }
            });
          }

          String? dLatStr = rawItem['driver_latitude']?.toString();
          String? dLngStr = rawItem['driver_longitude']?.toString();
          if (dLatStr != null && dLatStr.isNotEmpty && dLngStr != null && dLngStr.isNotEmpty) {
            double dLat = double.parse(dLatStr);
            double dLng = double.parse(dLngStr);

            driverCurrentLocation = LatLng(dLat, dLng);

            if (mounted) {
              setState(() {
                if (taxiIcon != null) {
                  _markers[rideData!.id.toString()] = Marker(
                    markerId: MarkerId(rideData!.id.toString()),
                    infoWindow: InfoWindow(title: rideData!.prenomConducteur.toString()),
                    position: driverCurrentLocation!,
                    icon: taxiIcon!,
                    rotation: 0.0,
                  );
                }
              });
            }

            final now = DateTime.now();
            if (polyLines.isEmpty ||
                _directionsLastFetched == null ||
                now.difference(_directionsLastFetched!).inSeconds >= 15) {
              _directionsLastFetched = now;
              if (mounted) getDirections(dLat: dLat, dLng: dLng);
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

      _listenDriverLocation();
      _fetchDriverLocation();
      _driverLocationTimer?.cancel();
      _driverLocationTimer = Timer.periodic(const Duration(seconds: 3), (timer) {
        _fetchDriverLocation();
      });

      getDirections(dLat: 0.0, dLng: 0.0);
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
    if (rideData == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }
    final themeChange = Provider.of<DarkThemeProvider>(context);
    return Scaffold(
      body: Stack(
        alignment: Alignment.bottomCenter,
        children: [
          GoogleMap(
            zoomControlsEnabled: false,
            myLocationButtonEnabled: false,
            myLocationEnabled: false,
            padding: const EdgeInsets.only(bottom: 130, top: 40),
            initialCameraPosition: CameraPosition(
              target: departureLatLong,
              zoom: 14.0,
            ),
            onMapCreated: (GoogleMapController controller) {
              _controller = controller;
              if (polyLines.containsKey(const PolylineId("poly")) &&
                  polyLines[const PolylineId("poly")]!.points.isNotEmpty) {
                final pts = polyLines[const PolylineId("poly")]!.points;
                updateCameraLocation(pts.first, pts.last, _controller);
              } else {
                _controller!.moveCamera(CameraUpdate.newLatLngZoom(departureLatLong, 12));
              }
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
          Positioned(
            top: 10,
            right: 16,
            child: SafeArea(
              child: Container(
                decoration: BoxDecoration(
                  color: themeChange.getThem() ? AppThemeData.surface50Dark : Colors.white,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.15),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    )
                  ],
                ),
                child: IconButton(
                  icon: Icon(
                    Icons.my_location_rounded,
                    color: AppThemeData.primary200,
                    size: 22,
                  ),
                  onPressed: () {
                    if (polyLines.containsKey(const PolylineId("poly")) &&
                        polyLines[const PolylineId("poly")]!.points.isNotEmpty) {
                      final pts = polyLines[const PolylineId("poly")]!.points;
                      updateCameraLocation(pts.first, pts.last, _controller);
                    } else {
                      updateCameraLocation(departureLatLong, destinationLatLong, _controller);
                    }
                  },
                ),
              ),
            ),
          ),
          DraggableScrollableSheet(
            controller: _sheetController,
            initialChildSize: 0.38,
            minChildSize: 0.16,
            maxChildSize: 0.70,
            snap: true,
            snapSizes: const [0.16, 0.38, 0.70],
            builder: (BuildContext context, ScrollController scrollController) {
              return Container(
                decoration: BoxDecoration(
                  color: themeChange.getThem() ? AppThemeData.surface50Dark : Colors.white,
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(28),
                    topRight: Radius.circular(28),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.15),
                      blurRadius: 20,
                      offset: const Offset(0, -4),
                    )
                  ],
                ),
                child: SafeArea(
                  top: false,
                  child: SingleChildScrollView(
                    controller: scrollController,
                    physics: const ClampingScrollPhysics(),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 8.0),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          // Interactive Drag Handle
                          GestureDetector(
                            behavior: HitTestBehavior.opaque,
                            onTap: _toggleSheet,
                            child: Container(
                              width: double.infinity,
                              padding: const EdgeInsets.symmetric(vertical: 8),
                              alignment: Alignment.center,
                              child: Container(
                                width: 44,
                                height: 5,
                                decoration: BoxDecoration(
                                  color: Colors.grey.shade400,
                                  borderRadius: BorderRadius.circular(10),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 6),

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

                    // Driver and Vehicle Details Card
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Driver Row
                        Row(
                          children: [
                            Container(
                              width: 52,
                              height: 52,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: AppThemeData.primary200.withValues(alpha: 0.3),
                                  width: 2,
                                ),
                              ),
                              child: ClipOval(
                                child: (rideData!.photoPath != null &&
                                        rideData!.photoPath!.isNotEmpty &&
                                        rideData!.photoPath != 'null' &&
                                        !rideData!.photoPath!.contains('placeholder'))
                                    ? CachedNetworkImage(
                                        imageUrl: rideData!.photoPath!,
                                        fit: BoxFit.cover,
                                        placeholder: (context, url) => Container(
                                          color: Colors.grey.shade200,
                                          child: const Icon(Icons.person, color: Colors.grey, size: 28),
                                        ),
                                        errorWidget: (context, url, error) => Container(
                                          color: Colors.grey.shade200,
                                          child: const Icon(Icons.person, color: Colors.grey, size: 28),
                                        ),
                                      )
                                    : Container(
                                        color: Colors.grey.shade200,
                                        child: const Icon(Icons.person, color: Colors.grey, size: 30),
                                      ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    "${rideData!.prenomConducteur ?? ''} ${rideData!.nomConducteur ?? ''}".trim(),
                                    style: TextStyle(
                                      fontFamily: AppThemeData.bold,
                                      fontSize: 16,
                                      color: themeChange.getThem() ? AppThemeData.grey900Dark : AppThemeData.grey900,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: Colors.amber.withValues(alpha: 0.15),
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        const Icon(Icons.star_rounded, color: Colors.amber, size: 14),
                                        const SizedBox(width: 3),
                                        Text(
                                          (rideData!.moyenne != null && rideData!.moyenne != "null" && rideData!.moyenne!.isNotEmpty)
                                              ? rideData!.moyenne.toString()
                                              : "5.0",
                                          style: const TextStyle(
                                            fontFamily: AppThemeData.bold,
                                            fontSize: 12,
                                            color: Color(0xFFB45309),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),

                            // Action buttons row (Chat & Active Call)
                            Row(
                              children: [
                                if (rideData!.statut == "confirmed") ...[
                                  InkWell(
                                    onTap: () {
                                      Get.to(ConversationScreen(), arguments: {
                                        'receiverId': int.tryParse(rideData!.idConducteur.toString()) ?? 0,
                                        'orderId': int.tryParse(rideData!.id.toString()) ?? 0,
                                        'receiverName': "${rideData!.prenomConducteur ?? ''} ${rideData!.nomConducteur ?? ''}".trim(),
                                        'receiverPhoto': rideData!.photoPath
                                      });
                                    },
                                    borderRadius: BorderRadius.circular(24),
                                    child: Container(
                                      padding: const EdgeInsets.all(9),
                                      decoration: BoxDecoration(
                                        color: Colors.blue.withValues(alpha: 0.1),
                                        shape: BoxShape.circle,
                                      ),
                                      child: const Icon(Icons.chat_bubble_outline_rounded, color: Colors.blue, size: 20),
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                ],
                                InkWell(
                                  onTap: () {
                                    Constant.makePhoneCall(rideData!.driverPhone);
                                  },
                                  borderRadius: BorderRadius.circular(24),
                                  child: Container(
                                    padding: const EdgeInsets.all(10),
                                    decoration: const BoxDecoration(
                                      color: Color(0xFF16A34A),
                                      shape: BoxShape.circle,
                                      boxShadow: [
                                        BoxShadow(
                                          color: Color(0x3316A34A),
                                          blurRadius: 8,
                                          offset: Offset(0, 3),
                                        ),
                                      ],
                                    ),
                                    child: const Icon(Icons.phone_rounded, color: Colors.white, size: 20),
                                  ),
                                ),
                              ],
                            )
                          ],
                        ),

                        const SizedBox(height: 12),

                        // Vehicle Details Container
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: themeChange.getThem() ? AppThemeData.surface50Dark : const Color(0xFFF8FAFC),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: themeChange.getThem() ? Colors.white12 : const Color(0xFFE2E8F0),
                            ),
                          ),
                          child: Column(
                            children: [
                              // Row 1: Vehicle Name & License Plate
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Expanded(
                                    child: Row(
                                      children: [
                                        Icon(
                                          Icons.directions_car_rounded,
                                          size: 18,
                                          color: AppThemeData.primary200,
                                        ),
                                        const SizedBox(width: 8),
                                        Expanded(
                                          child: Text(
                                            (() {
                                              final brand = (rideData!.brand ?? '').trim();
                                              final model = (rideData!.model ?? '').trim();
                                              final full = "$brand $model".trim();
                                              if (full.isNotEmpty && full != "null") return full;
                                              return (rideData!.place != null && rideData!.place!.isNotEmpty)
                                                  ? rideData!.place!
                                                  : "Cab / Taxi";
                                            })(),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                            style: TextStyle(
                                              fontFamily: AppThemeData.bold,
                                              fontSize: 14,
                                              color: themeChange.getThem() ? AppThemeData.grey900Dark : AppThemeData.grey900,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  // Number plate badge
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                    decoration: BoxDecoration(
                                      color: themeChange.getThem() ? Colors.black : Colors.white,
                                      borderRadius: BorderRadius.circular(6),
                                      border: Border.all(
                                        color: themeChange.getThem() ? Colors.white30 : Colors.grey.shade400,
                                        width: 1.2,
                                      ),
                                    ),
                                    child: Text(
                                      (rideData!.numberplate != null &&
                                              rideData!.numberplate!.isNotEmpty &&
                                              rideData!.numberplate != 'null')
                                          ? rideData!.numberplate!.toUpperCase()
                                          : 'NO NUMBER',
                                      style: TextStyle(
                                        fontFamily: AppThemeData.bold,
                                        fontSize: 12,
                                        letterSpacing: 0.8,
                                        color: themeChange.getThem() ? Colors.amber : const Color(0xFF0F172A),
                                      ),
                                    ),
                                  ),
                                ],
                              ),

                              const SizedBox(height: 8),

                              // Row 2: Colour & Passenger Capacity
                              Row(
                                children: [
                                  // Vehicle Colour
                                  Expanded(
                                    child: Row(
                                      children: [
                                        const Icon(Icons.palette_outlined, size: 15, color: Colors.grey),
                                        const SizedBox(width: 6),
                                        Expanded(
                                          child: Text(
                                            "Color: ${(rideData!.color != null && rideData!.color!.isNotEmpty && rideData!.color != 'null') ? rideData!.color : 'Standard'}",
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
                                  ),

                                  Container(
                                    width: 1,
                                    height: 14,
                                    color: Colors.grey.withValues(alpha: 0.3),
                                  ),
                                  const SizedBox(width: 8),

                                  // Passenger Capacity
                                  Expanded(
                                    child: Row(
                                      children: [
                                        const Icon(Icons.people_alt_outlined, size: 15, color: Colors.grey),
                                        const SizedBox(width: 6),
                                        Expanded(
                                          child: Text(
                                            "Seats: ${(rideData!.passenger != null && rideData!.passenger!.isNotEmpty && rideData!.passenger != 'null') ? rideData!.passenger : (rideData!.numberPoeple ?? '4')} Pass.",
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
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
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
                                "Payment Status".tr,
                                style: TextStyle(
                                  fontFamily: AppThemeData.regular,
                                  fontSize: 11,
                                  color: Colors.grey,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                (rideData!.statutPaiement == "yes") ? "Paid".tr : "Pay at Drop".tr,
                                style: TextStyle(
                                  fontFamily: AppThemeData.bold,
                                  fontSize: 14,
                                  color: (rideData!.statutPaiement == "yes") ? AppThemeData.success300 : AppThemeData.primary200,
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
                                "${rideData!.distance} ${(rideData!.distanceUnit != null && rideData!.distanceUnit != 'null' && rideData!.distanceUnit!.isNotEmpty) ? rideData!.distanceUnit : (Constant.distanceUnit ?? 'km')}",
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
                              icon: const Icon(Icons.warning_amber_rounded, color: Colors.white, size: 18),
                              label: Text("SOS".tr, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
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
          ),
        );
      },
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

  Future<void> getDirections({required double dLat, required double dLng}) async {
    if (rideData == null) return;

    List<LatLng> polylineCoordinates = [];
    List<PolylineWayPoint> wayPointList = [];

    if (rideData!.stops != null) {
      for (var i = 0; i < rideData!.stops!.length; i++) {
        final loc = rideData!.stops![i].location;
        if (loc != null && loc.isNotEmpty) {
          wayPointList.add(PolylineWayPoint(location: loc));
        }
      }
    }

    final double pLat = double.tryParse(rideData!.latitudeDepart?.toString() ?? '') ?? departureLatLong.latitude;
    final double pLng = double.tryParse(rideData!.longitudeDepart?.toString() ?? '') ?? departureLatLong.longitude;
    final double destLat = destinationLatLong.latitude;
    final double destLng = destinationLatLong.longitude;

    PointLatLng originPoint;
    PointLatLng destPoint;

    if (rideData!.statut == "confirmed") {
      originPoint = PointLatLng(dLat != 0.0 ? dLat : pLat, dLng != 0.0 ? dLng : pLng);
      destPoint = PointLatLng(pLat, pLng);

      try {
        final durationRes = await http.get(Uri.parse(
            "https://maps.googleapis.com/maps/api/distancematrix/json?units=imperial&origins=${originPoint.latitude},${originPoint.longitude}&destinations=$pLat,$pLng&key=${Constant.kGoogleApiKey}"));
        if (durationRes.statusCode == 200) {
          final durationData = jsonDecode(durationRes.body);
          if (durationData['rows'] != null &&
              durationData['rows'].isNotEmpty &&
              durationData['rows'][0]['elements'] != null &&
              durationData['rows'][0]['elements'].isNotEmpty &&
              durationData['rows'][0]['elements'][0]['duration'] != null) {
            driverEstimateArrivalTime = durationData['rows'][0]['elements'][0]['duration']['text'].toString();
          }
        }
      } catch (_) {}
    } else if (rideData!.statut == "on ride") {
      originPoint = PointLatLng(dLat != 0.0 ? dLat : pLat, dLng != 0.0 ? dLng : pLng);
      destPoint = PointLatLng(destLat, destLng);
    } else {
      originPoint = PointLatLng(pLat, pLng);
      destPoint = PointLatLng(destLat, destLng);
    }

    // Tier 1: Direct Google Directions API with Android package headers
    try {
      final apiKey = Constant.kGoogleApiKey ?? '';
      if (apiKey.isNotEmpty) {
        String url = "https://maps.googleapis.com/maps/api/directions/json"
            "?origin=${originPoint.latitude},${originPoint.longitude}"
            "&destination=${destPoint.latitude},${destPoint.longitude}"
            "&mode=driving"
            "&key=$apiKey";

        if (wayPointList.isNotEmpty) {
          final waypointsStr = wayPointList.map((w) => w.location).join('|');
          url += "&waypoints=$waypointsStr";
        }

        final response = await http.get(
          Uri.parse(url),
          headers: {
            'X-Android-Package': 'com.fiinway',
            'X-Android-Cert': '427CAACCD854958730B0A3187C9E986DDCA86726',
          },
        ).timeout(const Duration(seconds: 5));

        if (response.statusCode == 200) {
          final data = jsonDecode(response.body);
          if (data['routes'] != null && (data['routes'] as List).isNotEmpty) {
            final overview = data['routes'][0]['overview_polyline']?['points'];
            if (overview != null && overview.toString().isNotEmpty) {
              final decoded = polylinePoints.decodePolyline(overview.toString());
              for (var pt in decoded) {
                polylineCoordinates.add(LatLng(pt.latitude, pt.longitude));
              }
            }
          }
        }
      }
    } catch (e) {
      dev.log("User App Tier 1 Google Direct failed: $e");
    }

    // Tier 2: flutter_polyline_points with Google API Key
    if (polylineCoordinates.isEmpty) {
      try {
        PolylineRequest requestData = PolylineRequest(
          wayPoints: wayPointList,
          optimizeWaypoints: true,
          mode: TravelMode.driving,
          origin: originPoint,
          destination: destPoint,
        );
        final result = await polylinePoints.getRouteBetweenCoordinates(
          googleApiKey: Constant.kGoogleApiKey.toString(),
          request: requestData,
        );
        if (result.points.isNotEmpty) {
          for (var point in result.points) {
            polylineCoordinates.add(LatLng(point.latitude, point.longitude));
          }
        }
      } catch (e) {
        dev.log("User App Tier 2 PolylinePoints failed: $e");
      }
    }

    // Tier 3: OSRM High-resolution Road Router (guarantees real road polyline worldwide)
    if (polylineCoordinates.isEmpty) {
      try {
        String osrmUrl = "https://router.project-osrm.org/route/v1/driving/"
            "${originPoint.longitude},${originPoint.latitude};"
            "${destPoint.longitude},${destPoint.latitude}"
            "?overview=full&geometries=polyline";

        final osrmRes = await http.get(Uri.parse(osrmUrl)).timeout(const Duration(seconds: 5));
        if (osrmRes.statusCode == 200) {
          final data = jsonDecode(osrmRes.body);
          if (data['routes'] != null && (data['routes'] as List).isNotEmpty) {
            final geometry = data['routes'][0]['geometry'];
            if (geometry != null && geometry.toString().isNotEmpty) {
              final decoded = polylinePoints.decodePolyline(geometry.toString());
              for (var pt in decoded) {
                polylineCoordinates.add(LatLng(pt.latitude, pt.longitude));
              }
            }
          }
        }
      } catch (e) {
        dev.log("User App Tier 3 OSRM failed: $e");
      }
    }

    // Tier 4: Fallback line
    if (polylineCoordinates.isEmpty) {
      polylineCoordinates = [
        LatLng(originPoint.latitude, originPoint.longitude),
        LatLng(destPoint.latitude, destPoint.longitude),
      ];
    }

    // Markers placement
    _markers['Departure'] = Marker(
      markerId: const MarkerId('Departure'),
      infoWindow: InfoWindow(title: "Departure".tr, snippet: rideData!.departName ?? ''),
      position: LatLng(pLat, pLng),
      icon: departureIcon ?? BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen),
    );

    if (destLat != 0.0 && destLng != 0.0) {
      _markers['Destination'] = Marker(
        markerId: const MarkerId('Destination'),
        infoWindow: InfoWindow(title: "Destination".tr, snippet: rideData!.destinationName ?? ''),
        position: LatLng(destLat, destLng),
        icon: destinationIcon ?? BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
      );
    }

    if (rideData!.stops != null) {
      for (var i = 0; i < rideData!.stops!.length; i++) {
        final sLat = double.tryParse(rideData!.stops![i].latitude ?? '') ?? 0.0;
        final sLng = double.tryParse(rideData!.stops![i].longitude ?? '') ?? 0.0;
        if (sLat != 0.0 && sLng != 0.0) {
          _markers['stop_$i'] = Marker(
            markerId: MarkerId('stop_$i'),
            infoWindow: InfoWindow(title: rideData!.stops![i].location ?? "Stop"),
            position: LatLng(sLat, sLng),
            icon: stopIcon ?? BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueYellow),
          );
        }
      }
    }

    if (dLat != 0.0 && dLng != 0.0) {
      _markers[rideData!.id.toString()] = Marker(
        markerId: MarkerId(rideData!.id.toString()),
        infoWindow: InfoWindow(title: rideData!.prenomConducteur ?? "Captain"),
        position: LatLng(dLat, dLng),
        icon: taxiIcon ?? BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueOrange),
      );
    }

    addPolyLine(polylineCoordinates);
  }

  void addPolyLine(List<LatLng> polylineCoordinates) {
    if (polylineCoordinates.isEmpty) {
      polylineCoordinates = [departureLatLong, destinationLatLong];
    }
    PolylineId id = const PolylineId("poly");
    Polyline polyline = Polyline(
      polylineId: id,
      color: AppThemeData.primary200,
      points: polylineCoordinates,
      width: 6,
      geodesic: true,
    );
    polyLines[id] = polyline;

    if (_controller != null && polylineCoordinates.length >= 2) {
      updateCameraLocation(polylineCoordinates.first, polylineCoordinates.last, _controller);
    }

    if (mounted) {
      setState(() {});
    }
  }

  Future<void> updateCameraLocation(
    LatLng source,
    LatLng destination,
    GoogleMapController? mapController,
  ) async {
    if (mapController == null) return;
    if (source.latitude == 0.0 || destination.latitude == 0.0) return;

    if ((source.latitude - destination.latitude).abs() < 0.0001 &&
        (source.longitude - destination.longitude).abs() < 0.0001) {
      mapController.animateCamera(CameraUpdate.newLatLngZoom(source, 15));
      return;
    }

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

    CameraUpdate cameraUpdate = CameraUpdate.newLatLngBounds(bounds, 60);

    return checkCameraLocation(cameraUpdate, mapController);
  }

  Future<void> checkCameraLocation(CameraUpdate cameraUpdate, GoogleMapController mapController) async {
    try {
      await mapController.animateCamera(cameraUpdate);
      LatLngBounds l1 = await mapController.getVisibleRegion();
      LatLngBounds l2 = await mapController.getVisibleRegion();

      if (l1.southwest.latitude == -90 || l2.southwest.latitude == -90) {
        await Future.delayed(const Duration(milliseconds: 200));
        await mapController.animateCamera(cameraUpdate);
      }
    } catch (_) {}
  }
}
