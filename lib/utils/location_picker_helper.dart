import 'dart:convert';
import 'dart:io';

import 'package:finway/constant/constant.dart';
import 'package:finway/constant/show_toast_dialog.dart';
import 'package:finway/page/search_location_screen.dart';
import 'package:finway/themes/constant_colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter_osm_plugin/flutter_osm_plugin.dart';
import 'package:geolocator/geolocator.dart';
import 'package:location/location.dart' as loc_pkg;
import 'package:get/get.dart';
import 'package:http/http.dart' as http;

class PickedLocation {
  final double latitude;
  final double longitude;
  final String address;

  const PickedLocation({
    required this.latitude,
    required this.longitude,
    required this.address,
  });

  SearchInfo toSearchInfo() {
    return SearchInfo(
      point: GeoPoint(latitude: latitude, longitude: longitude),
      address: Address(name: address),
    );
  }
}

class LocationPickerHelper {
  static final loc_pkg.Location _loc = loc_pkg.Location();

  /// Ensures GPS / Location services and permissions are enabled.
  /// If not enabled, asks the user to turn on GPS via native dialog or settings handler.
  static Future<bool> ensureLocationAccess({BuildContext? context, bool showPromptDialog = true}) async {
    try {
      // 1. Check & Request Location Service (GPS)
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        // Try native Google Play Services location popup first
        try {
          serviceEnabled = await _loc.requestService();
        } catch (_) {}
      }

      if (!serviceEnabled) {
        if (showPromptDialog) {
          final shouldOpen = await _showEnableGpsDialog(context);
          if (shouldOpen) {
            await Geolocator.openLocationSettings();
            // Wait briefly and re-check
            await Future.delayed(const Duration(seconds: 1));
            serviceEnabled = await Geolocator.isLocationServiceEnabled();
          }
        }
        if (!serviceEnabled) return false;
      }

      // 2. Check & Request Permission
      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      if (permission == LocationPermission.deniedForever) {
        if (showPromptDialog) {
          final shouldOpen = await _showPermissionSettingsDialog(context);
          if (shouldOpen) {
            await Geolocator.openAppSettings();
          }
        }
        return false;
      }

      if (permission == LocationPermission.denied) {
        ShowToastDialog.showToast('Location permission is required to detect pickup point.'.tr);
        return false;
      }

      return true;
    } catch (e) {
      print("ensureLocationAccess error: $e");
      return false;
    }
  }

  static Future<bool> _showEnableGpsDialog(BuildContext? context) async {
    final ctx = context ?? Get.context;
    if (ctx == null) return true;

    final result = await showDialog<bool>(
      context: ctx,
      barrierDismissible: false,
      builder: (dialogCtx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: Row(
          children: [
            Icon(Icons.location_off_rounded, color: AppThemeData.primary200, size: 28),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                'Enable Location / GPS'.tr,
                style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
        content: Text(
          'Your device location is turned off. Please turn on GPS so we can automatically set your pickup location and show available rides near you.'.tr,
          style: const TextStyle(fontSize: 14, color: Colors.black87),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogCtx, false),
            child: Text('Cancel'.tr, style: TextStyle(color: Colors.grey.shade600)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppThemeData.primary200,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
            ),
            onPressed: () => Navigator.pop(dialogCtx, true),
            child: Text('Turn On GPS'.tr, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );

    return result ?? false;
  }

  static Future<bool> _showPermissionSettingsDialog(BuildContext? context) async {
    final ctx = context ?? Get.context;
    if (ctx == null) return true;

    final result = await showDialog<bool>(
      context: ctx,
      barrierDismissible: false,
      builder: (dialogCtx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: Row(
          children: [
            Icon(Icons.security_rounded, color: AppThemeData.primary200, size: 28),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                'Location Permission Needed'.tr,
                style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
        content: Text(
          'Location permission is permanently denied. Please grant location access in App Settings to detect your pickup point automatically.'.tr,
          style: const TextStyle(fontSize: 14, color: Colors.black87),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogCtx, false),
            child: Text('Cancel'.tr, style: TextStyle(color: Colors.grey.shade600)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppThemeData.primary200,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
            ),
            onPressed: () => Navigator.pop(dialogCtx, true),
            child: Text('Open Settings'.tr, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );

    return result ?? false;
  }

  static Future<String> _resolveAddress(double latitude, double longitude) async {
    try {
      final address = await Constant().getAddressFromLatLong(
        Position(
          latitude: latitude,
          longitude: longitude,
          timestamp: DateTime.now(),
          accuracy: 1,
          altitude: 0,
          heading: 0,
          speed: 0,
          speedAccuracy: 0,
          altitudeAccuracy: 0,
          headingAccuracy: 0,
        ),
      );
      if (address.trim().isNotEmpty) return address;
    } catch (_) {}

    try {
      final package = Platform.isAndroid ? 'com.cabme' : 'com.cabme.ios';
      final url =
          'https://nominatim.openstreetmap.org/reverse?format=json&lat=$latitude&lon=$longitude&zoom=18&addressdetails=1';
      final response = await http.get(Uri.parse(url), headers: {'User-Agent': package});
      if (response.statusCode == 200) {
        final data = json.decode(response.body) as Map<String, dynamic>;
        final displayName = data['display_name']?.toString();
        if (displayName != null && displayName.isNotEmpty) return displayName;
        final addr = data['address'];
        if (addr is Map) {
          final parts = [
            addr['house_number'],
            addr['road'],
            addr['suburb'],
            addr['city'] ?? addr['town'] ?? addr['village'],
            addr['state'],
            addr['postcode'],
          ].whereType<String>().where((s) => s.trim().isNotEmpty).toList();
          if (parts.isNotEmpty) return parts.join(', ');
        }
      }
    } catch (_) {}

    return '';
  }

  static Future<PickedLocation?> fetchCurrentLocation({
    BuildContext? context,
    bool showLoader = false,
    bool showPromptDialog = true,
  }) async {
    if (showLoader) ShowToastDialog.showLoader('Fetching your location...'.tr);
    try {
      final hasAccess = await ensureLocationAccess(context: context, showPromptDialog: showPromptDialog);
      if (!hasAccess) return null;

      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: const Duration(seconds: 15),
      );

      final address = await _resolveAddress(position.latitude, position.longitude);
      return PickedLocation(
        latitude: position.latitude,
        longitude: position.longitude,
        address: address,
      );
    } catch (e) {
      print("fetchCurrentLocation error: $e");
      return null;
    } finally {
      if (showLoader) ShowToastDialog.closeLoader();
    }
  }

  static Future<PickedLocation?> pickFromSearch() async {
    final result = await Get.to(() => const AddressSearchScreen());
    if (result is SearchInfo && result.point != null) {
      final address = result.address?.toString().trim() ?? '';
      return PickedLocation(
        latitude: result.point!.latitude,
        longitude: result.point!.longitude,
        address: address.isNotEmpty ? address : await _resolveAddress(result.point!.latitude, result.point!.longitude),
      );
    }
    return null;
  }

  static Future<PickedLocation?> showPickerSheet(BuildContext context) async {
    final choice = await showModalBottomSheet<String>(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(4)),
                ),
                const SizedBox(height: 14),
                Text(
                  'Select Service Location'.tr,
                  style: TextStyle(fontFamily: AppThemeData.bold, fontSize: 16),
                ),
                const SizedBox(height: 14),
                ListTile(
                  leading: CircleAvatar(
                    backgroundColor: AppThemeData.primary200.withValues(alpha: 0.12),
                    child: Icon(Icons.my_location_rounded, color: AppThemeData.primary200),
                  ),
                  title: Text('Use Current Location (GPS)'.tr, style: TextStyle(fontFamily: AppThemeData.semiBold)),
                  subtitle: Text('Detect location automatically'.tr, style: const TextStyle(fontSize: 12)),
                  onTap: () => Navigator.pop(ctx, 'gps'),
                ),
                ListTile(
                  leading: CircleAvatar(
                    backgroundColor: Colors.grey.withValues(alpha: 0.12),
                    child: const Icon(Icons.search_rounded, color: Colors.black54),
                  ),
                  title: Text('Search Address'.tr, style: TextStyle(fontFamily: AppThemeData.semiBold)),
                  subtitle: Text('Type and pick from suggestions'.tr, style: const TextStyle(fontSize: 12)),
                  onTap: () => Navigator.pop(ctx, 'search'),
                ),
              ],
            ),
          ),
        );
      },
    );

    if (choice == 'gps') return fetchCurrentLocation();
    if (choice == 'search') return pickFromSearch();
    return null;
  }
}
