import 'dart:async';
import 'dart:convert';
import 'dart:developer';
import 'dart:io';
import 'package:finway/constant/constant.dart';
import 'package:finway/constant/logdata.dart';
import 'package:finway/constant/show_toast_dialog.dart';
import 'package:finway/model/settings_model.dart';
import 'package:finway/service/api.dart';
import 'package:finway/themes/constant_colors.dart';
import 'package:finway/utils/Preferences.dart';
import 'package:flutter/animation.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;

class SettingsController extends GetxController {
  @override
  void onInit() {
    API.header['accesstoken'] = Preferences.getString(Preferences.accesstoken);
    getSettingsData();
    fetchPaymentSettings();
    super.onInit();
  }

  Future<void> fetchPaymentSettings() async {
    try {
      final response = await http
          .get(Uri.parse(API.paymentSetting), headers: API.header)
          .timeout(const Duration(seconds: 8));
      if (response.statusCode == 200) {
        final body = json.decode(response.body);
        if (body['success'] == 'success') {
          Preferences.setString(Preferences.paymentSetting, jsonEncode(body));
        }
      }
    } catch (_) {}
  }

  Future<SettingsModel?> getSettingsData() async {
    try {
      final response = await http.get(
        Uri.parse(API.settings),
        headers: API.authheader,
      ).timeout(const Duration(seconds: 8));

      showLog("API :: URL :: ${API.settings}");
      showLog("API :: Request Header :: ${API.header.toString()} ");
      showLog("API :: responseStatus :: ${response.statusCode} ");
      showLog("API :: responseBody :: ${response.body} ");
      Map<String, dynamic> responseBody = json.decode(response.body);

      if (response.statusCode == 200 && responseBody['success'] == "success") {
        SettingsModel model = SettingsModel.fromJson(responseBody);
        Constant.liveTrackingMapType = model.data?.mapType ?? "";
        if (Platform.isAndroid) {
          Constant.selectedMapType = 'google';
        } else {
          Constant.selectedMapType = model.data?.mapForApplication != null ? '${model.data?.mapForApplication?.toLowerCase()}' : '';
        }
        if (model.data?.websiteColor != null && model.data!.websiteColor!.isNotEmpty) {
          Preferences.setString(Preferences.themeColor, model.data!.websiteColor!);
          AppThemeData.applyThemeColor(model.data!.websiteColor!);
        }
        Constant.distanceUnit = model.data?.deliveryDistance ?? "km";
        Constant.driverRadius = model.data?.driverRadios ?? "10";
        Constant.appVersion = model.data?.appVersion?.toString() ?? "1.0.0";
        Constant.decimal = model.data?.decimalDigit ?? "2";
        Constant.driverLocationUpdate = model.data?.driverLocationUpdate ?? "10";
        Constant.deliverChargeParcel = model.data?.deliverChargeParcel ?? "0";
        Constant.parcelActive = model.data?.parcelActive ?? "yes";
        Constant.parcelPerWeightCharge = model.data?.parcelPerWeightCharge ?? "0";
        Constant.parcelPerHeightCharge = model.data?.parcelPerHeightCharge ?? "0";
        if (model.data?.taxModel != null) {
          Constant.allTaxList = model.data!.taxModel!;
        }
        Constant.currency = model.data?.currency ?? "₹";
        Constant.symbolAtRight = model.data?.symbolAtRight == 'true' ? true : false;
        Constant.kGoogleApiKey = model.data?.googleMapApiKey ?? "";
        Constant.contactUsEmail = model.data?.contactUsEmail ?? "";
        Constant.contactUsAddress = model.data?.contactUsAddress ?? "";
        Constant.contactUsPhone = model.data?.contactUsPhone ?? "";
        Constant.rideOtp = model.data?.showRideOtp ?? "yes";
        Constant.senderId = model.data?.senderId ?? "";
        Constant.jsonNotificationFileURL = model.data?.serviceJson ?? "";
        Constant.homeScreenType = model.data?.homeScreenType;
      }
    } catch (e) {
      showLog("User SettingsController error: $e");
    }
    return null;
  }
}
