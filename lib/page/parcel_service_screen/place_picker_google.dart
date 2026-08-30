import 'dart:developer';
import 'package:finway/constant/constant.dart';
import 'package:finway/page/search_location_screen.dart';
import 'package:finway/themes/constant_colors.dart';
import 'package:finway/themes/text_field_them.dart';
import 'package:finway/utils/dark_theme_provider.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:flutter_svg/svg.dart';
import 'package:geolocator/geolocator.dart';
import 'package:flutter_osm_plugin/flutter_osm_plugin.dart';
import 'package:get/get.dart';
import 'package:provider/provider.dart';

class GoogleLocationPicker extends StatefulWidget {
  const GoogleLocationPicker({super.key});

  @override
  State<GoogleLocationPicker> createState() => _GoogleLocationPickerState();
}

class _GoogleLocationPickerState extends State<GoogleLocationPicker> {
  LatLng? selectedLocation;
  GoogleMapController? mapController;
  Map<String, dynamic>? placeData;
  TextEditingController textController = TextEditingController();
  final Set<Marker> _markers = {};

  @override
  void initState() {
    super.initState();
    _setUserLocation();
  }

  updateMarkerAndAddress(LatLng position) async {
    _markers.clear();
    _markers.add(Marker(
      markerId: const MarkerId("selected_pos"),
      position: position,
      icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
    ));

    selectedLocation = position;

    try {
      final pos = Position(
        latitude: position.latitude,
        longitude: position.longitude,
        timestamp: DateTime.now(),
        accuracy: 1,
        altitude: 0,
        heading: 0,
        speed: 0,
        speedAccuracy: 0,
        altitudeAccuracy: 0,
        headingAccuracy: 0,
      );

      final addressResult = await Constant().getAddressFromLatLong(pos);
      String fullAddress = addressResult.toString();
      String city = fullAddress.split(",").last.trim();

      placeData = {
        'address': fullAddress,
        'lat': position.latitude,
        'lng': position.longitude,
        'city': city
      };
      textController.text = fullAddress;
    } catch (e) {
      log("Error getting address from latlong: $e");
    }

    setState(() {});
  }

  Future<void> _setUserLocation() async {
    try {
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied || permission == LocationPermission.deniedForever) {
        LatLng defaultPos = const LatLng(28.6139, 77.2090);
        updateMarkerAndAddress(defaultPos);
        return;
      }
      Position position = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
      LatLng userPos = LatLng(position.latitude, position.longitude);
      updateMarkerAndAddress(userPos);
      if (mapController != null) {
        mapController!.animateCamera(CameraUpdate.newLatLngZoom(userPos, 14));
      }
    } catch (e) {
      log("Error getting user location: $e");
      LatLng defaultPos = const LatLng(28.6139, 77.2090);
      updateMarkerAndAddress(defaultPos);
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeChange = Provider.of<DarkThemeProvider>(context);
    return Scaffold(
      body: Stack(
        children: [
          GoogleMap(
            initialCameraPosition: CameraPosition(
              target: selectedLocation ?? const LatLng(28.6139, 77.2090),
              zoom: 14,
            ),
            onMapCreated: (controller) {
              mapController = controller;
              if (selectedLocation != null) {
                mapController!.animateCamera(CameraUpdate.newLatLngZoom(selectedLocation!, 14));
              }
            },
            onTap: (LatLng latLng) {
              updateMarkerAndAddress(latLng);
            },
            markers: _markers,
            myLocationEnabled: true,
            myLocationButtonEnabled: false,
          ),
          if (placeData?['address'] != null)
            Align(
              alignment: Alignment.bottomCenter,
              child: Container(
                margin: const EdgeInsets.only(bottom: 100, left: 40, right: 40),
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                    color: themeChange.getThem() ? AppThemeData.surface50Dark : AppThemeData.surface50,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: themeChange.getThem() ? AppThemeData.grey200Dark : AppThemeData.grey200,
                    )),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        placeData?['address'] ?? '',
                        style: TextStyle(
                          fontSize: 16,
                          fontFamily: AppThemeData.medium,
                          color: themeChange.getThem() ? AppThemeData.grey900Dark : AppThemeData.grey900,
                        ),
                      ),
                    ),
                    IconButton(
                        onPressed: () {
                          Get.back(result: placeData);
                        },
                        icon: const Icon(
                          Icons.check_circle,
                          size: 40,
                        ))
                  ],
                ),
              ),
            ),
          SafeArea(
            child: Padding(
              padding: EdgeInsets.only(left: Directionality.of(context) == TextDirection.rtl ? 16 : 0, right: 16, top: 20),
              child: Row(
                children: [
                  IconButton(
                    onPressed: () {
                      Get.back();
                    },
                    icon: Transform(
                      alignment: Alignment.center,
                      transform: Directionality.of(context) == TextDirection.rtl ? Matrix4.rotationY(3.14159) : Matrix4.identity(),
                      child: SvgPicture.asset(
                        'assets/icons/ic_left.svg',
                        width: 35,
                        height: 35,
                        colorFilter: ColorFilter.mode(
                          AppThemeData.grey500,
                          BlendMode.srcIn,
                        ),
                      ),
                    ),
                  ),
                  Expanded(
                    child: InkWell(
                      onTap: () async {
                        Get.to(AddressSearchScreen())?.then((value) {
                          if (value != null) {
                            SearchInfo place = value;
                            LatLng latLng = LatLng(place.point!.latitude, place.point!.longitude);
                            updateMarkerAndAddress(latLng);
                            if (mapController != null) {
                              mapController!.animateCamera(CameraUpdate.newLatLngZoom(latLng, 14));
                            }
                          }
                        });
                      },
                      child: TextFieldWidgetBorder(
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        borderColor: AppThemeData.grey800,
                        radius: BorderRadius.circular(40),
                        enabled: false,
                        isReadOnly: true,
                        hintText: "Search Address".tr,
                        controller: textController,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        heroTag: null,
        onPressed: _setUserLocation,
        child: const Icon(Icons.my_location),
      ),
    );
  }
}
