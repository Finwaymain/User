import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:finway/constant/constant.dart';
import 'package:finway/constant/logdata.dart';
import 'package:finway/constant/show_toast_dialog.dart';
import 'package:finway/model/user_model.dart';
import 'package:finway/service/api.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;

class ParcelDetailsController extends GetxController {
  @override
  void onInit() {
    getUsrData();
    super.onInit();
  }

  UserModel? userModel;

  getUsrData() {
    userModel = Constant.getUserData();
  }

  Future<dynamic> rejectParcel(Map<String, String> bodyParams) async {
    try {
      ShowToastDialog.showLoader("Please wait");
      final response = await http.post(Uri.parse(API.parcelCanceled), headers: API.header, body: jsonEncode(bodyParams));
      showLog("API :: URL :: ${API.parcelCanceled}");
      showLog("API :: URL :: ${jsonEncode(bodyParams)}");
      showLog("API :: Request Header :: ${API.header.toString()} ");
      showLog("API :: responseStatus :: ${response.statusCode} ");
      showLog("API :: responseBody :: ${response.body} ");
      Map<String, dynamic> responseBody = json.decode(response.body);

      final success = responseBody['success']?.toString().toLowerCase();
      if (response.statusCode == 200 && success == "success") {
        ShowToastDialog.closeLoader();
        return responseBody;
      } else if (response.statusCode == 200 && (success == "failed" || success == "false")) {
        ShowToastDialog.closeLoader();
        ShowToastDialog.showToast(responseBody['error']?.toString() ?? responseBody['message']?.toString() ?? 'Failed');
      } else {
        ShowToastDialog.closeLoader();
        ShowToastDialog.showToast(responseBody['error']?.toString() ?? 'Something went wrong. Please try again later');
        throw Exception('Failed to cancel parcel');
      }
    } on TimeoutException catch (e) {
      ShowToastDialog.closeLoader();
      ShowToastDialog.showToast(e.message.toString());
    } on SocketException catch (e) {
      ShowToastDialog.closeLoader();
      ShowToastDialog.showToast(e.message.toString());
    } on Error catch (e) {
      ShowToastDialog.closeLoader();
      ShowToastDialog.showToast(e.toString());
    }
    ShowToastDialog.closeLoader();
    return null;
  }

  Future<dynamic> canceledParcel(Map<String, String> bodyParams) async {
    try {
      ShowToastDialog.showLoader("Please wait");
      final response = await http.post(Uri.parse(API.parcelReject), headers: API.header, body: jsonEncode(bodyParams));
      showLog("API :: URL :: ${API.parcelReject}");
      showLog("API :: URL :: ${jsonEncode(bodyParams)}");
      showLog("API :: Request Header :: ${API.header.toString()} ");
      showLog("API :: responseStatus :: ${response.statusCode} ");
      showLog("API :: responseBody :: ${response.body} ");
      Map<String, dynamic> responseBody = json.decode(response.body);

      final success = responseBody['success']?.toString().toLowerCase();
      if (response.statusCode == 200 && success == "success") {
        ShowToastDialog.closeLoader();
        return responseBody;
      } else if (response.statusCode == 200 && (success == "failed" || success == "false")) {
        ShowToastDialog.closeLoader();
        ShowToastDialog.showToast(responseBody['error']?.toString() ?? responseBody['message']?.toString() ?? 'Failed');
      } else {
        ShowToastDialog.closeLoader();
        ShowToastDialog.showToast(responseBody['error']?.toString() ?? 'Something went wrong. Please try again later');
        throw Exception('Failed to cancel parcel');
      }
    } on TimeoutException catch (e) {
      ShowToastDialog.closeLoader();
      ShowToastDialog.showToast(e.message.toString());
    } on SocketException catch (e) {
      ShowToastDialog.closeLoader();
      ShowToastDialog.showToast(e.message.toString());
    } on Error catch (e) {
      ShowToastDialog.closeLoader();
      ShowToastDialog.showToast(e.toString());
    }
    ShowToastDialog.closeLoader();
    return null;
  }
}
