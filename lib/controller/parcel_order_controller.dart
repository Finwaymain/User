import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:finway/constant/logdata.dart';
import 'package:finway/constant/show_toast_dialog.dart';
import 'package:finway/model/parcel_model.dart';
import 'package:finway/service/api.dart';
import 'package:finway/utils/Preferences.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;

class ParcelOrderController extends GetxController {
  var isLoading = true.obs;
  var newParcelList = <ParcelData>[].obs;
  var completedParcelList = <ParcelData>[].obs;
  var rejectedParcelList = <ParcelData>[].obs;

  @override
  void onInit() {
    getParcel(isInit: true);
    _startPeriodicFetch();
    super.onInit();
  }

  Timer? _timer;

  @override
  void onClose() {
    _timer?.cancel(); // Cancel the timer when the controller is disposed
    super.onClose();
  }

  void _startPeriodicFetch() {
    _timer = Timer.periodic(const Duration(seconds: 15), (timer) {
      getParcel();
    });
  }

  Future<void> getParcel({bool isInit = false}) async {
    try {
      if (isInit) {
        ShowToastDialog.showLoader("Please wait");
      }
      final response = await http.get(
        Uri.parse("${API.getParcel}?id_user_app=${Preferences.getInt(Preferences.userId)}"),
        headers: API.header,
      );
      showLog("API :: URL :: ${API.getParcel}?id_user_app=${Preferences.getInt(Preferences.userId)}");
      showLog("API :: Request Header :: ${API.header.toString()} ");
      showLog("API :: responseStatus :: ${response.statusCode} ");
      showLog("API :: responseBody :: ${response.body} ");
      Map<String, dynamic> responseBody = json.decode(response.body);

      if (response.statusCode == 200 && responseBody['success'].toString() == "success") {
        isLoading.value = false;

        ParcelModel model = ParcelModel.fromJson(responseBody);
        newParcelList.clear();
        completedParcelList.clear();
        rejectedParcelList.clear();
        for (var parcel in model.data!) {
          if (parcel.status == "rejected" || parcel.status == "driver_rejected") {
            rejectedParcelList.add(parcel);
          } else if (parcel.status == "completed") {
            completedParcelList.add(parcel);
          } else if (parcel.status != "canceled") {
            newParcelList.add(parcel);
          }
        }
        ShowToastDialog.closeLoader();
      } else {
        rejectedParcelList.clear();
        completedParcelList.clear();
        newParcelList.clear();
        ShowToastDialog.closeLoader();
        isLoading.value = false;
      }
    } on TimeoutException catch (e) {
      isLoading.value = false;
      ShowToastDialog.closeLoader();
      ShowToastDialog.showToast(e.message.toString());
    } on SocketException catch (e) {
      isLoading.value = false;
      ShowToastDialog.closeLoader();
      ShowToastDialog.showToast(e.message.toString());
    } on Error catch (e) {
      isLoading.value = false;
      ShowToastDialog.closeLoader();
      ShowToastDialog.showToast(e.toString());
    } catch (e) {
      isLoading.value = false;
      ShowToastDialog.closeLoader();
      ShowToastDialog.showToast(e.toString());
    }
  }
}
