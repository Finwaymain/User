import 'dart:async';
import 'dart:convert';
import 'dart:developer';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:finway/constant/logdata.dart';
import 'package:finway/constant/show_toast_dialog.dart';
import 'package:finway/model/ride_model.dart';
import 'package:finway/service/api.dart';
import 'package:finway/utils/Preferences.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;

class NewRideController extends GetxController {
  var isLoading = true.obs;
  var newRideList = <RideData>[].obs;         // Awaiting driver acceptance (statut == 'new')
  var pendingRideList = <RideData>[].obs;     // In-progress / active (confirmed, on ride, arrived)
  var completedRideList = <RideData>[].obs;   // Finished & rejected (completed, rejected, canceled)
  Timer? timer;

  var currentPage = 1;
  var isMoreDataAvailable = true.obs;
  var isLoadMoreRunning = false.obs;

  final ScrollController scrollControllerNew = ScrollController();
  final ScrollController scrollControllerPending = ScrollController();
  final ScrollController scrollControllerCompleted = ScrollController();

  @override
  void onInit() {
    if (Preferences.getBoolean(Preferences.isLogin)) {
      getNewRide(isinit: true);
      timer = Timer.periodic(const Duration(seconds: 15), (timer) {
        // Periodic check fetches page 1 to check for updates or new rides
        getNewRide();
      });

      scrollControllerNew.addListener(() {
        if (scrollControllerNew.position.pixels == scrollControllerNew.position.maxScrollExtent) {
          loadMoreRides();
        }
      });
      scrollControllerPending.addListener(() {
        if (scrollControllerPending.position.pixels == scrollControllerPending.position.maxScrollExtent) {
          loadMoreRides();
        }
      });
      scrollControllerCompleted.addListener(() {
        if (scrollControllerCompleted.position.pixels == scrollControllerCompleted.position.maxScrollExtent) {
          loadMoreRides();
        }
      });
    } else {
      isLoading.value = false;
    }
    super.onInit();
  }

  @override
  void onClose() {
    timer?.cancel();
    scrollControllerNew.dispose();
    scrollControllerPending.dispose();
    scrollControllerCompleted.dispose();
    super.onClose();
  }

  Future<void> loadMoreRides() async {
    if (isMoreDataAvailable.value && !isLoadMoreRunning.value) {
      isLoadMoreRunning.value = true;
      currentPage++;
      await getNewRide(page: currentPage);
      isLoadMoreRunning.value = false;
    }
  }

  Future<dynamic> getNewRide({bool isinit = false, int page = 1}) async {
    try {
      if (!Preferences.getBoolean(Preferences.isLogin)) {
        isLoading.value = false;
        return null;
      }
      if (isinit) {
        ShowToastDialog.showLoader("Please wait");
        currentPage = 1;
        isMoreDataAvailable.value = true;
        newRideList.clear();
        pendingRideList.clear();
        completedRideList.clear();
      }

      final response = await http.get(
        Uri.parse("${API.userAllRides}?id_user_app=${Preferences.getInt(Preferences.userId)}&page=$page&limit=10"),
        headers: API.header
      );

      showLog("API :: URL :: ${API.userAllRides}?id_user_app=${Preferences.getInt(Preferences.userId)}&page=$page&limit=10 ");
      showLog("API :: Header :: ${API.header.toString()} ");
      showLog("API :: responseStatus :: ${response.statusCode} ");
      showLog("API :: responseBody :: ${response.body} ");
      
      Map<String, dynamic> responseBody = json.decode(response.body);
      if (response.statusCode == 200 && responseBody['success'] == "success") {
        isLoading.value = false;
        RideModel model = RideModel.fromJson(responseBody);
        
        if (model.data == null || model.data!.isEmpty) {
          if (page > 1) {
            isMoreDataAvailable.value = false;
          }
        } else {
          if (model.data!.length < 10) {
            isMoreDataAvailable.value = false;
          }

          for (var ride in model.data!) {
            // Remove first to avoid duplication, then add
            newRideList.removeWhere((r) => r.id == ride.id);
            pendingRideList.removeWhere((r) => r.id == ride.id);
            completedRideList.removeWhere((r) => r.id == ride.id);

            final status = (ride.statut ?? '').toLowerCase().trim();

            if (status == "new") {
              // Awaiting driver acceptance
              newRideList.add(ride);
            } else if (status == "confirmed" || status == "on ride" || status == "arrived" || status == "in progress") {
              // In progress / active rides
              pendingRideList.add(ride);
            } else if (status == "completed" || status == "rejected" || status == "canceled" || status == "cancelled") {
              // Completed & Rejected / Cancelled rides
              completedRideList.add(ride);
            } else {
              // Default fallback
              completedRideList.add(ride);
            }
          }

          // Sort lists in descending order of ID (most recent first)
          newRideList.sort((a, b) => int.parse(b.id ?? '0').compareTo(int.parse(a.id ?? '0')));
          pendingRideList.sort((a, b) => int.parse(b.id ?? '0').compareTo(int.parse(a.id ?? '0')));
          completedRideList.sort((a, b) => int.parse(b.id ?? '0').compareTo(int.parse(a.id ?? '0')));
        }
        ShowToastDialog.closeLoader();
      } else {
        if (page == 1) {
          newRideList.clear();
          pendingRideList.clear();
          completedRideList.clear();
        }
        ShowToastDialog.closeLoader();
        isLoading.value = false;
      }
    } on TimeoutException {
      ShowToastDialog.closeLoader();
      isLoading.value = false;
    } on SocketException {
      ShowToastDialog.closeLoader();
      isLoading.value = false;
    } on Error {
      ShowToastDialog.closeLoader();
      isLoading.value = false;
    } catch (e) {
      log('NewRideController getNewRide error $e');
      ShowToastDialog.closeLoader();
      ShowToastDialog.showToast(e.toString());
    }
    return null;
  }
}
