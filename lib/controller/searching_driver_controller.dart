import 'dart:async';
import 'dart:convert';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'dart:developer' as dev;

import 'package:finway/constant/constant.dart';
import 'package:finway/constant/show_toast_dialog.dart';
import 'package:finway/model/ride_model.dart';
import 'package:finway/model/ride_details_model.dart';
import 'package:finway/service/api.dart';
import 'package:finway/utils/Preferences.dart';
import 'package:finway/page/route_view_screen/route_view_screen.dart';
import 'package:finway/page/route_view_screen/route_osm_view_screen.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;

class SearchingDriverController extends GetxController {
  Rx<RideData?> rideData = Rx<RideData?>(null);
  RxString statut = "new".obs;
  RxInt remainingSeconds = 60.obs;
  RxString statusText = "Looking for nearby drivers...".obs;

  Timer? _countdownTimer;
  Timer? _pollingTimer;
  Map<String, dynamic>? bookingBodyParams;

  final List<String> statusMessages = [
    "Looking for nearby Captains...",
    "Analyzing driver proximity...",
    "Pinging the closest available driver...",
    "Waiting for Captain to accept...",
    "Almost there, prioritizing your request...",
    "Extending search window..."
  ];

  @override
  void onInit() {
    super.onInit();
    final args = Get.arguments;
    if (args != null) {
      rideData.value = args['rideData'] as RideData?;
      bookingBodyParams = args['bookingBodyParams'] as Map<String, dynamic>?;
    }
    startSearchTimer();
  }

  @override
  void onClose() {
    stopSearchTimer();
    super.onClose();
  }

  void startSearchTimer() {
    remainingSeconds.value = 60;
    statut.value = "new";
    statusText.value = statusMessages[0];

    _countdownTimer?.cancel();
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (remainingSeconds.value > 0) {
        remainingSeconds.value--;
        // Rotate status text every 8 seconds
        int index = (60 - remainingSeconds.value) ~/ 8;
        if (index < statusMessages.length) {
          statusText.value = statusMessages[index];
        }
      } else {
        // Timeout
        stopSearchTimer();
        statut.value = "driver_rejected";
        statusText.value = "No drivers found. Please try again.";
      }
    });

    // Fallback polling every 4 seconds to guarantee state updates
    _pollingTimer?.cancel();
    _pollingTimer = Timer.periodic(const Duration(seconds: 4), (timer) {
      checkRideStatus();
    });
  }

  void stopSearchTimer() {
    _countdownTimer?.cancel();
    _pollingTimer?.cancel();
  }

  Future<void> checkRideStatus() async {
    if (rideData.value == null || rideData.value!.id == null) return;
    try {
      // Trigger automated rotation checks on the server
      await http.post(
        Uri.parse(API.dispatchCheckTimeout),
        headers: API.header,
        body: jsonEncode({'ride_id': rideData.value!.id.toString()}),
      );

      final response = await http.get(
        Uri.parse("${API.rideDetails}?ride_id=${rideData.value!.id}"),
        headers: API.header,
      );
      if (response.statusCode == 200) {
        Map<String, dynamic> responseBody = json.decode(response.body);
        if (responseBody['success'] == "success" && responseBody['data'] != null) {
          RideDetailsModel details = RideDetailsModel.fromJson(responseBody);
          if (details.rideDetailsdata != null) {
            String currentStatus = details.rideDetailsdata!.statut.toString();
            if (currentStatus == "confirmed" || currentStatus == "driver_rejected" || currentStatus == "on ride") {
              // Convert RideDetailsdata to RideData
              RideData updatedRideData = RideData(
                id: details.rideDetailsdata!.id,
                idUserApp: details.rideDetailsdata!.idUserApp,
                departName: details.rideDetailsdata!.departName,
                destinationName: details.rideDetailsdata!.destinationName,
                latitudeDepart: details.rideDetailsdata!.latitudeDepart,
                longitudeDepart: details.rideDetailsdata!.longitudeDepart,
                latitudeArrivee: details.rideDetailsdata!.latitudeArrivee,
                longitudeArrivee: details.rideDetailsdata!.longitudeArrivee,
                place: details.rideDetailsdata!.place,
                numberPoeple: details.rideDetailsdata!.numberPoeple,
                distance: details.rideDetailsdata!.distance,
                duree: details.rideDetailsdata!.duree,
                montant: details.rideDetailsdata!.montant,
                trajet: details.rideDetailsdata!.trajet,
                statut: details.rideDetailsdata!.statut,
                statutPaiement: details.rideDetailsdata!.statutPaiement,
                idConducteur: details.rideDetailsdata!.idConducteur,
                creer: details.rideDetailsdata!.creer,
                dateRetour: details.rideDetailsdata!.dateRetour,
                heureRetour: details.rideDetailsdata!.heureRetour,
                statutRound: details.rideDetailsdata!.statutRound,
                // Driver info from ridedetails API
                otp: details.rideDetailsdata!.otp,
                nomConducteur: details.rideDetailsdata!.nomConducteur ?? "",
                prenomConducteur: details.rideDetailsdata!.prenomConducteur ?? "",
                photoPath: details.rideDetailsdata!.photoPath,
                driverPhone: details.rideDetailsdata!.driverPhone,
                moyenne: details.rideDetailsdata!.moyenne,
                stops: details.rideDetailsdata!.stops,
              );
              handleRideStatusTransition(currentStatus, updatedRideData);
            }
          }
        }
      }
    } catch (e) {
      dev.log("Error polling ride status: $e");
    }
  }

  void handleFCMMessage(RemoteMessage message) {
    String? status = message.data['statut']?.toString();
    if (status == "confirmed" || status == "driver_rejected" || status == "on ride") {
      try {
        RideData updatedData = RideData.fromJson(message.data);
        handleRideStatusTransition(status!, updatedData);
      } catch (e) {
        dev.log("Error parsing FCM ride data: $e");
        checkRideStatus();
      }
    }
  }

  void handleRideStatusTransition(String status, RideData updatedRideData) {
    if (status == "confirmed" || status == "on ride") {
      stopSearchTimer();
      statut.value = "confirmed";
      rideData.value = updatedRideData;
      statusText.value = "Captain Found! Preparing your ride...";

      Future.delayed(const Duration(milliseconds: 1200), () {
        var argumentData = {'type': status, 'data': updatedRideData};
        if (Constant.selectedMapType == 'osm') {
          Get.off(() => const RouteOsmViewScreen(), arguments: argumentData);
        } else {
          Get.off(() => const RouteViewScreen(), arguments: argumentData);
        }
      });
    } else if (status == "driver_rejected") {
      stopSearchTimer();
      statut.value = "driver_rejected";
      statusText.value = "No Captains accepted. Try searching again.";
    }
  }


  Future<bool> cancelSearch() async {
    if (rideData.value == null) return false;
    try {
      ShowToastDialog.showLoader("Canceling search...");
      Map<String, String> bodyParams = {
        'id_ride': rideData.value!.id.toString(),
        'id_user': (rideData.value!.idConducteur ?? "0").toString(),
        'name': "User App",
        'from_id': Preferences.getInt(Preferences.userId).toString(),
        'user_cat': "user_app",
        'reason': "User cancelled during search.",
      };

      final response = await http.post(
        Uri.parse(API.rejectRide),
        headers: API.header,
        body: jsonEncode(bodyParams),
      );

      ShowToastDialog.closeLoader();

      if (response.statusCode == 200) {
        Map<String, dynamic> responseBody = json.decode(response.body);
        if (responseBody['success'] == "success") {
          stopSearchTimer();
          return true;
        }
      }
    } catch (e) {
      ShowToastDialog.closeLoader();
      dev.log("Error canceling ride: $e");
    }
    return false;
  }

  /// Re-dispatches the EXISTING ride to the next available driver.

  /// Calls the backend reject endpoint with user_cat='retry_dispatch' and
  /// force=true which triggers Requests::rotateRequestIfNeeded($rideId, true).
  /// This avoids creating a duplicate ride record.
  Future<void> retryDispatch() async {
    if (rideData.value == null || rideData.value!.id == null) {
      ShowToastDialog.showToast("No ride data available to retry.");
      return;
    }

    try {
      ShowToastDialog.showLoader("Retrying search...");
      Map<String, String> bodyParams = {
        'ride_id': rideData.value!.id.toString(),
      };

      final response = await http.post(
        Uri.parse(API.dispatchRetry),
        headers: API.header,
        body: jsonEncode(bodyParams),
      );

      ShowToastDialog.closeLoader();

      if (response.statusCode == 200) {
        Map<String, dynamic> responseBody = json.decode(response.body);
        if (responseBody['success'] == "success") {
          // Reset the countdown and UI state to "searching"
          startSearchTimer();
          return;
        }
      }
      ShowToastDialog.showToast("Could not retry. Please try booking again.");
    } catch (e) {
      ShowToastDialog.closeLoader();
      dev.log("Error retrying dispatch: $e");
      ShowToastDialog.showToast("Retry failed. Please try again.");
    }
  }
}
