import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:finway/constant/constant.dart';
import 'package:finway/constant/logdata.dart';
import 'package:finway/constant/show_toast_dialog.dart';
import 'package:finway/model/bank_details_model.dart';
import 'package:finway/service/api.dart';
import 'package:finway/utils/Preferences.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;

class BankDetailsController extends GetxController {
  var bankNameController = TextEditingController().obs;
  var branchNameController = TextEditingController().obs;
  var holderNameController = TextEditingController().obs;
  var accountNumberController = TextEditingController().obs;
  var otherInformationController = TextEditingController().obs;
  var ifscCodeController = TextEditingController().obs;
  final formKey = GlobalKey<FormState>();

  @override
  void onInit() {
    getBankDetails();
    super.onInit();
  }

  void iniData() {
    bankNameController.value = TextEditingController(text: bankDetails.value.bankName);
    branchNameController.value = TextEditingController(text: bankDetails.value.branchName);
    holderNameController.value = TextEditingController(text: bankDetails.value.holderName);
    accountNumberController.value = TextEditingController(text: bankDetails.value.accountNo);
    otherInformationController.value = TextEditingController(text: bankDetails.value.otherInfo);
    ifscCodeController.value = TextEditingController(text: bankDetails.value.ifscCode);
    ShowToastDialog.closeLoader();
  }

  var isLoading = true.obs;
  var bankDetails = BankData().obs;

  String get userId {
    final userData = Constant.getUserData();
    if (userData.data?.id != null) {
      return userData.data!.id.toString();
    }
    return Preferences.getString(Preferences.userId);
  }

  Future<dynamic> getBankDetails() async {
    try {
      ShowToastDialog.showLoader("Please wait");
      final url = "${API.bankDetails}?driver_id=$userId&user_id=$userId&user_type=customer";
      final response = await http.get(Uri.parse(url), headers: API.header);
      showLog("API :: URL :: $url");
      showLog("API :: Request Header :: ${API.header.toString()}");
      showLog("API :: responseStatus :: ${response.statusCode}");
      showLog("API :: responseBody :: ${response.body}");

      Map<String, dynamic> responseBody = json.decode(response.body);

      if (response.statusCode == 200 && responseBody['success'] == "success") {
        isLoading.value = false;
        BankDetailsModel model = BankDetailsModel.fromJson(responseBody);
        if (model.data != null) {
          bankDetails.value = model.data!;
          iniData();
        } else {
          ShowToastDialog.closeLoader();
        }
      } else {
        isLoading.value = false;
        ShowToastDialog.closeLoader();
      }
    } on TimeoutException catch (e) {
      isLoading.value = false;
      ShowToastDialog.closeLoader();
      ShowToastDialog.showToast(e.message.toString());
    } on SocketException catch (e) {
      isLoading.value = false;
      ShowToastDialog.closeLoader();
      ShowToastDialog.showToast(e.message.toString());
    } catch (e) {
      isLoading.value = false;
      ShowToastDialog.closeLoader();
    }
    return null;
  }

  Future<dynamic> setBankDetails(Map<String, String> bodyParams) async {
    try {
      ShowToastDialog.showLoader("Please wait");
      final response = await http.post(Uri.parse(API.addBankDetails), headers: API.header, body: jsonEncode(bodyParams));
      showLog("API :: URL :: ${API.addBankDetails}");
      showLog("API :: Request Body :: ${jsonEncode(bodyParams)}");
      showLog("API :: responseStatus :: ${response.statusCode}");
      showLog("API :: responseBody :: ${response.body}");
      Map<String, dynamic> responseBody = json.decode(response.body);

      if (response.statusCode == 200 && responseBody['success'] == "success") {
        ShowToastDialog.closeLoader();
        return responseBody;
      } else if (response.statusCode == 200 && responseBody['success'] == "Failed") {
        ShowToastDialog.closeLoader();
        ShowToastDialog.showToast(responseBody['error'] ?? 'Failed to update bank details');
      } else {
        ShowToastDialog.closeLoader();
        ShowToastDialog.showToast(responseBody['error'] ?? 'Something went wrong. Please try again later');
      }
    } on TimeoutException catch (e) {
      ShowToastDialog.closeLoader();
      ShowToastDialog.showToast(e.message.toString());
    } on SocketException catch (e) {
      ShowToastDialog.closeLoader();
      ShowToastDialog.showToast(e.message.toString());
    } catch (e) {
      ShowToastDialog.closeLoader();
      ShowToastDialog.showToast(e.toString());
    }
    ShowToastDialog.closeLoader();
    return null;
  }
}
