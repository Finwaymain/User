import 'dart:async';
import 'dart:convert';
import 'dart:developer';
import 'dart:io';
import 'package:finway/constant/logdata.dart';
import 'package:finway/constant/show_toast_dialog.dart';
import 'package:finway/model/onboarding_model.dart';
import 'package:finway/service/api.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;

import 'package:finway/utils/Preferences.dart';

import '../page/MainDashBoard/screen/main_dashboard.dart';
class OnBoardingController extends GetxController {
  var selectedPageIndex = 0.obs;

  bool isLastPage = false;
  RxBool isLoading = true.obs;
  var pageController = PageController();

  Rx<OnboardingModel> onboardingModel = OnboardingModel().obs;
  RxList<String> localImage = ['assets/images/intro_1.png', 'assets/images/intro_2.png'].obs;

  @override
  void onInit() {
    getBoardingData();
    super.onInit();
  }

  Future<dynamic> getBoardingData() async {
    try {
      isLoading.value = true;
      ShowToastDialog.showLoader("Please wait");
      http.Response obBoardingData = await http.get(Uri.parse(API.onBoarding), headers: API.header).timeout(const Duration(seconds: 3));
      showLog("API :: URL :: ${API.onBoarding}");
      showLog("API :: Request Header :: ${API.header.toString()}");
      showLog("API :: Response Status :: ${obBoardingData.statusCode} ");
      showLog("API :: Response Body :: ${obBoardingData.body} ");
      var decodedResponse = jsonDecode(obBoardingData.body);
      if (decodedResponse['success'] == 'success') {
        log("OnBoaring :: ${obBoardingData.body}");
        onboardingModel.value = OnboardingModel.fromJson(decodedResponse as Map<String, dynamic>);
        // Skip onboarding if data is empty or wrong structure
        if (onboardingModel.value.data == null || onboardingModel.value.data!.isEmpty) {
          Preferences.setBoolean(Preferences.isFinishOnBoardingKey, true);
          Get.offAll(const MainDashboard());
          return decodedResponse;
        }
        isLastPage = selectedPageIndex.value == (onboardingModel.value.data?.length ?? 0) - 1;
        isLoading.value = false;
        ShowToastDialog.closeLoader();
        return decodedResponse;
      } else {
        ShowToastDialog.closeLoader();
        isLoading.value = false;
        // Skip onboarding on error
        Preferences.setBoolean(Preferences.isFinishOnBoardingKey, true);
        Get.offAll(const MainDashboard());
      }
    } on TimeoutException catch (e) {
      isLoading.value = false;
      ShowToastDialog.closeLoader();
      ShowToastDialog.showToast(e.message.toString());
      // Skip onboarding on timeout
      Preferences.setBoolean(Preferences.isFinishOnBoardingKey, true);
      Get.offAll(const MainDashboard());
    } on SocketException catch (e) {
      isLoading.value = false;
      ShowToastDialog.closeLoader();
      ShowToastDialog.showToast(e.message.toString());
      // Skip onboarding on network error
      Preferences.setBoolean(Preferences.isFinishOnBoardingKey, true);
      Get.offAll(const MainDashboard());
    } on Error catch (e) {
      isLoading.value = false;
      ShowToastDialog.showToast(e.toString());
      // Skip onboarding on error
      Preferences.setBoolean(Preferences.isFinishOnBoardingKey, true);
      Get.offAll(const MainDashboard());
    } catch (e) {
      isLoading.value = false;
      ShowToastDialog.closeLoader();
      ShowToastDialog.showToast(e.toString());
      // Skip onboarding on error
      Preferences.setBoolean(Preferences.isFinishOnBoardingKey, true);
      Get.offAll(const MainDashboard());
    }
    return null;
  }
}
