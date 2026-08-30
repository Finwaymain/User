import 'dart:async';
import 'dart:convert';
import 'dart:developer' as dev;

import 'package:finway/constant/constant.dart';
import 'package:finway/model/ride_model.dart';
import 'package:finway/page/completed_ride_screens/payment_selection_screen.dart';
import 'package:finway/page/new_ride_screens/searching_driver_screen.dart';
import 'package:finway/page/route_view_screen/route_view_screen.dart';
import 'package:finway/page/route_view_screen/route_osm_view_screen.dart';
import 'package:finway/themes/constant_colors.dart';
import 'package:finway/utils/dark_theme_provider.dart';
import 'package:finway/service/api.dart';
import 'package:finway/utils/Preferences.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:location/location.dart' as loc;
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';

class InProgressScreen extends StatefulWidget {
  const InProgressScreen({super.key});

  @override
  State<InProgressScreen> createState() => _InProgressScreenState();
}

class _InProgressScreenState extends State<InProgressScreen> {
  bool _isLoading = true;
  bool _isRedirecting = false;
  Timer? _refreshTimer;
  GoogleMapController? _mapController;
  LatLng _currentPosition = const LatLng(9.0820, 8.6753); // Default central point
  final loc.Location _location = loc.Location();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _fetchActiveRides();
    });
    _getUserLocation(requestIfNeeded: false);
    
    // Poll for active rides status every 6 seconds
    _refreshTimer = Timer.periodic(const Duration(seconds: 6), (_) {
      if (mounted) {
        _fetchActiveRides();
      }
    });
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    _mapController?.dispose();
    super.dispose();
  }

  Future<void> _getUserLocation({bool requestIfNeeded = false}) async {
    try {
      bool serviceEnabled = await _location.serviceEnabled();
      if (!serviceEnabled) {
        if (requestIfNeeded) {
          serviceEnabled = await _location.requestService();
        }
        if (!serviceEnabled) return;
      }

      loc.PermissionStatus permissionGranted = await _location.hasPermission();
      if (permissionGranted == loc.PermissionStatus.denied) {
        if (requestIfNeeded) {
          permissionGranted = await _location.requestPermission();
        }
        if (permissionGranted != loc.PermissionStatus.granted) return;
      }

      final locData = await _location.getLocation();
      if (locData.latitude != null && locData.longitude != null) {
        if (mounted) {
          setState(() {
            _currentPosition = LatLng(locData.latitude!, locData.longitude!);
          });
          _mapController?.animateCamera(
            CameraUpdate.newCameraPosition(
              CameraPosition(target: _currentPosition, zoom: 15),
            ),
          );
        }
      }
    } catch (e) {
      dev.log("Error getting user location: $e");
    }
  }

  Future<void> _fetchActiveRides() async {
    if (_isRedirecting) return;
    try {
      final userId = Preferences.getInt(Preferences.userId);
      final response = await http.get(
        Uri.parse('${API.newRide}?id_user_app=$userId'),
        headers: API.header,
      );
      if (response.statusCode == 200) {
        final body = json.decode(response.body);
        if (body['success'] == 'success' && body['data'] != null) {
          final allRides = (body['data'] as List)
              .map((e) => RideData.fromJson(e as Map<String, dynamic>))
              .toList();

          // 1. Check if any completed ride needs payment
          final unpaidCompleted = allRides.where((r) =>
              r.statut == 'completed' && r.statutPaiement != 'yes').toList();
          if (unpaidCompleted.isNotEmpty && mounted) {
            _isRedirecting = true;
            _refreshTimer?.cancel();
            Get.offAll(() => PaymentSelectionScreen(), arguments: {
              'rideData': unpaidCompleted.first,
            });
            return;
          }

          // 2. Check for active ongoing rides
          final activeRides = allRides.where((r) =>
              r.statut == 'confirmed' ||
              r.statut == 'on ride' ||
              r.statut == 'new').toList();

          if (activeRides.isNotEmpty && mounted) {
            final activeRide = activeRides.first;
            _isRedirecting = true;
            _refreshTimer?.cancel();

            if (activeRide.statut == 'new') {
              Get.offAll(() => const SearchingDriverScreen(), arguments: {
                'rideData': activeRide,
              });
            } else {
              var argumentData = {'type': activeRide.statut, 'data': activeRide};
              if (Constant.selectedMapType == 'osm') {
                Get.offAll(() => const RouteOsmViewScreen(), arguments: argumentData);
              } else {
                Get.offAll(() => const RouteViewScreen(), arguments: argumentData);
              }
            }
            return;
          }
        }
      }
    } catch (e) {
      dev.log('InProgressScreen fetch error: $e');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeChange = Provider.of<DarkThemeProvider>(context);
    final isDark = themeChange.getThem();

    return Scaffold(
      backgroundColor: isDark ? AppThemeData.surface50Dark : AppThemeData.surface50,
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Stack(
              children: [
                // Map Background
                Positioned.fill(
                  child: GoogleMap(
                    initialCameraPosition: CameraPosition(
                      target: _currentPosition,
                      zoom: 14.0,
                    ),
                    myLocationEnabled: true,
                    myLocationButtonEnabled: false,
                    zoomControlsEnabled: false,
                    compassEnabled: false,
                    onMapCreated: (controller) {
                      _mapController = controller;
                      if (isDark) {
                        _setDarkMapStyle(controller);
                      }
                    },
                  ),
                ),

                // Map HUD buttons
                Positioned(
                  right: 16,
                  bottom: 240,
                  child: FloatingActionButton(
                    heroTag: null,
                    mini: true,
                    backgroundColor: isDark ? AppThemeData.grey800 : Colors.white,
                    child: Icon(
                      Icons.my_location,
                      color: isDark ? Colors.white : AppThemeData.grey900,
                    ),
                    onPressed: () => _getUserLocation(requestIfNeeded: true),
                  ),
                ),

                // Premium overlay bottom sheet
                Positioned(
                  left: 16,
                  right: 16,
                  bottom: 30,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 26),
                    decoration: BoxDecoration(
                      color: isDark
                          ? AppThemeData.surface50Dark.withValues(alpha: 0.95)
                          : Colors.white.withValues(alpha: 0.95),
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(
                        color: isDark
                            ? Colors.white.withValues(alpha: 0.08)
                            : Colors.black.withValues(alpha: 0.04),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.12),
                          blurRadius: 24,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 48,
                          height: 4,
                          decoration: BoxDecoration(
                            color: isDark ? AppThemeData.grey300 : AppThemeData.grey300,
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                        const SizedBox(height: 20),
                        Icon(
                          Icons.directions_car_rounded,
                          size: 40,
                          color: AppThemeData.primary200,
                        ),
                        const SizedBox(height: 14),
                        Text(
                          'No Active Rides'.tr,
                          style: TextStyle(
                            fontFamily: AppThemeData.bold,
                            fontSize: 20,
                            letterSpacing: -0.3,
                            color: isDark ? Colors.white : AppThemeData.grey900,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'You have no active rides right now. Tap below to search for available rides and book one instantly.'.tr,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontFamily: AppThemeData.regular,
                            fontSize: 13,
                            height: 1.5,
                            color: isDark ? AppThemeData.grey500Dark : AppThemeData.grey500,
                          ),
                        ),
                        const SizedBox(height: 24),
                        SizedBox(
                          width: double.infinity,
                          height: 52,
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppThemeData.primary200,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                              elevation: 0,
                            ),
                            onPressed: () {
                              // Navigate back to the home/dashboard index 0 (TexiHomeScreen)
                              Get.back();
                            },
                            child: Text(
                              'Book a Ride'.tr,
                              style: const TextStyle(
                                fontFamily: AppThemeData.bold,
                                fontSize: 15,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
    );
  }

  void _setDarkMapStyle(GoogleMapController controller) {
    String darkMapStyle = '''
    [
      {
        "elementType": "geometry",
        "stylers": [
          {
            "color": "#212121"
          }
        ]
      },
      {
        "elementType": "labels.icon",
        "stylers": [
          {
            "visibility": "off"
          }
        ]
      },
      {
        "elementType": "labels.text.fill",
        "stylers": [
          {
            "color": "#757575"
          }
        ]
      },
      {
        "elementType": "labels.text.stroke",
        "stylers": [
          {
            "color": "#212121"
          }
        ]
      },
      {
        "featureType": "administrative",
        "elementType": "geometry",
        "stylers": [
          {
            "color": "#757575"
          }
        ]
      },
      {
        "featureType": "administrative.country",
        "elementType": "labels.text.fill",
        "stylers": [
          {
            "color": "#9e9e9e"
          }
        ]
      },
      {
        "featureType": "administrative.land_parcel",
        "stylers": [
          {
            "visibility": "off"
          }
        ]
      },
      {
        "featureType": "administrative.locality",
        "elementType": "labels.text.fill",
        "stylers": [
          {
            "color": "#bdbdbd"
          }
        ]
      },
      {
        "featureType": "poi",
        "elementType": "labels.text.fill",
        "stylers": [
          {
            "color": "#757575"
          }
        ]
      },
      {
        "featureType": "poi.park",
        "elementType": "geometry",
        "stylers": [
          {
            "color": "#181818"
          }
        ]
      },
      {
        "featureType": "poi.park",
        "elementType": "labels.text.fill",
        "stylers": [
          {
            "color": "#616161"
          }
        ]
      },
      {
        "featureType": "poi.park",
        "elementType": "labels.text.stroke",
        "stylers": [
          {
            "color": "#1b1b1b"
          }
        ]
      },
      {
        "featureType": "road",
        "elementType": "geometry.fill",
        "stylers": [
          {
            "color": "#2c2c2c"
          }
        ]
      },
      {
        "featureType": "road",
        "elementType": "labels.text.fill",
        "stylers": [
          {
            "color": "#8a8a8a"
          }
        ]
      },
      {
        "featureType": "road.arterial",
        "elementType": "geometry",
        "stylers": [
          {
            "color": "#373737"
          }
        ]
      },
      {
        "featureType": "road.highway",
        "elementType": "geometry",
        "stylers": [
          {
            "color": "#3c3c3c"
          }
        ]
      },
      {
        "featureType": "road.highway.controlled_access",
        "elementType": "geometry",
        "stylers": [
          {
            "color": "#4e4e4e"
          }
        ]
      },
      {
        "featureType": "road.local",
        "elementType": "labels.text.fill",
        "stylers": [
          {
            "color": "#616161"
          }
        ]
      },
      {
        "featureType": "transit",
        "elementType": "labels.text.fill",
        "stylers": [
          {
            "color": "#757575"
          }
        ]
      },
      {
        "featureType": "water",
        "elementType": "geometry",
        "stylers": [
          {
            "color": "#000000"
          }
        ]
      },
      {
        "featureType": "water",
        "elementType": "labels.text.fill",
        "stylers": [
          {
            "color": "#3d3d3d"
          }
        ]
      }
    ]
    ''';
    controller.setMapStyle(darkMapStyle);
  }
}
