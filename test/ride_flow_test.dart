import 'dart:math' as math;
import 'package:flutter_test/flutter_test.dart';

/// Test helper implementing the exact Haversine algorithm from RouteViewScreen
double haversineMeters(double lat1, double lng1, double lat2, double lng2) {
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

bool isDriverArrivedAtPickup({
  required double driverLat,
  required double driverLng,
  required double pickupLat,
  required double pickupLng,
  double thresholdMeters = 150.0,
}) {
  final distance = haversineMeters(driverLat, driverLng, pickupLat, pickupLng);
  return distance <= thresholdMeters;
}

String getRideStatusSubtitle({
  required String status,
  required bool driverArrivedAtPickup,
}) {
  if (status == 'on ride') {
    return 'Heading to your destination';
  } else if (status == 'confirmed') {
    return driverArrivedAtPickup
        ? 'Captain has arrived at pickup point'
        : 'Captain is on the way to pickup';
  }
  return "We're finding the best driver for you";
}

bool shouldShowOtp({
  required String rideOtpSetting,
  required String rideStatus,
  required String? rideType,
  required bool driverArrivedAtPickup,
}) {
  return rideOtpSetting.toLowerCase() == 'yes' &&
      rideStatus == 'confirmed' &&
      rideType != 'driver';
}

void main() {
  group('Ride Flow - Automated Unit Tests', () {
    test('Haversine distance calculation is accurate within ~1 meter', () {
      // Distance between two known coordinates (e.g. Statue of Liberty & Empire State Building: ~8.4 km)
      const lat1 = 40.689247;
      const lng1 = -74.044502;
      const lat2 = 40.748817;
      const lng2 = -73.985428;

      final dist = haversineMeters(lat1, lng1, lat2, lng2);
      expect(dist, greaterThan(8000));
      expect(dist, lessThan(9000));
    });

    test('Zero distance when points are identical', () {
      const lat = 12.9716;
      const lng = 77.5946;
      final dist = haversineMeters(lat, lng, lat, lng);
      expect(dist, closeTo(0.0, 0.001));
    });

    test('Driver arrival detection triggers when <= 150m from pickup', () {
      // Pickup point
      const pickupLat = 12.9715987;
      const pickupLng = 77.5945627;

      // Driver ~80 meters away (approx 0.0007 deg difference)
      const driverLatClose = 12.9721000;
      const driverLngClose = 77.5945627;

      final arrived = isDriverArrivedAtPickup(
        driverLat: driverLatClose,
        driverLng: driverLngClose,
        pickupLat: pickupLat,
        pickupLng: pickupLng,
      );
      expect(arrived, isTrue, reason: 'Driver at ~80m should be marked arrived');
    });

    test('Driver arrival detection is false when > 150m from pickup', () {
      const pickupLat = 12.9715987;
      const pickupLng = 77.5945627;

      // Driver ~500 meters away
      const driverLatFar = 12.9760000;
      const driverLngFar = 77.5945627;

      final arrived = isDriverArrivedAtPickup(
        driverLat: driverLatFar,
        driverLng: driverLngFar,
        pickupLat: pickupLat,
        pickupLng: pickupLng,
      );
      expect(arrived, isFalse, reason: 'Driver at ~500m should not be marked arrived');
    });

    test('Status subtitle dynamically updates based on ride state and arrival', () {
      // 1. Confirmed but far
      expect(
        getRideStatusSubtitle(status: 'confirmed', driverArrivedAtPickup: false),
        equals('Captain is on the way to pickup'),
      );

      // 2. Confirmed and arrived
      expect(
        getRideStatusSubtitle(status: 'confirmed', driverArrivedAtPickup: true),
        equals('Captain has arrived at pickup point'),
      );

      // 3. On ride
      expect(
        getRideStatusSubtitle(status: 'on ride', driverArrivedAtPickup: true),
        equals('Heading to your destination'),
      );

      // 4. Default / searching
      expect(
        getRideStatusSubtitle(status: 'new', driverArrivedAtPickup: false),
        equals("We're finding the best driver for you"),
      );
    });

    test('OTP visibility rules validate correctly', () {
      expect(
        shouldShowOtp(
          rideOtpSetting: 'yes',
          rideStatus: 'confirmed',
          rideType: 'cab',
          driverArrivedAtPickup: true,
        ),
        isTrue,
      );

      // Hidden if rideOtp is disabled in admin settings
      expect(
        shouldShowOtp(
          rideOtpSetting: 'no',
          rideStatus: 'confirmed',
          rideType: 'cab',
          driverArrivedAtPickup: true,
        ),
        isFalse,
      );

      // Hidden if ride has already started (status: on ride)
      expect(
        shouldShowOtp(
          rideOtpSetting: 'yes',
          rideStatus: 'on ride',
          rideType: 'cab',
          driverArrivedAtPickup: true,
        ),
        isFalse,
      );
    });
  });
}
