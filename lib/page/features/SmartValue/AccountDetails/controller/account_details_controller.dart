import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;

import '../../../../../constant/constant.dart';
import '../../../../../constant/logdata.dart';
import '../../../../../constant/show_toast_dialog.dart';
import '../../../../../service/api.dart';
import '../model/account_details_model.dart';

class AccountDetailsController extends GetxController with GetTickerProviderStateMixin {
  // Observable variables
  var isFront = true.obs;
  var isLoading = false.obs;
  Rx<AccountDetailsModel?> accountDetailsModel = Rx<AccountDetailsModel?>(null);

  // Animation controllers
  late AnimationController flipController;
  late AnimationController shimmerController;
  late Animation<double> flipAnimation;
  late Animation<double> shimmerAnimation;

  @override
  void onInit() {
    super.onInit();

    flipController = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 800),
    );

    shimmerController = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 2000),
    )..repeat();

    flipAnimation = Tween<double>(begin: 0, end: pi).animate(
      CurvedAnimation(parent: flipController, curve: Curves.easeInOut),
    );

    shimmerAnimation = Tween<double>(begin: -1, end: 2).animate(
      CurvedAnimation(parent: shimmerController, curve: Curves.easeInOut),
    );

    // Set loading true before API call
    isLoading.value = true;

    // Load account details when controller initializes
    getAccountDetails("${Constant.getUserData().data?.acNo}");
  }


  void flipCard() {
    if (isFront.value) {
      flipController.forward();
    } else {
      flipController.reverse();
    }
    isFront.value = !isFront.value;
  }

  // Get data from model for display
  String get digitalPocket => accountDetailsModel.value?.data?.acNo ?? '000000000';

  String get holderName => accountDetailsModel.value?.data?.getFullName() ?? "N/A";

  String get mobile => accountDetailsModel.value?.data?.phone ?? "N/A";

  String get accountNumber => accountDetailsModel.value?.data?.acNo ?? "N/A";

  String get expDays => accountDetailsModel.value?.data?.getDaysToStart()?.toString() ?? "0";

  String get expDate => accountDetailsModel.value?.data?.getFormattedStartDate() ?? "00/00";

  String get accountType {
    final status = accountDetailsModel.value?.data?.statut;
    return status == "yes" ? "Active Account" : "Inactive Account";
  }

  String get cardType => "PLATINUM";

  String get bank => "Smart Value";

  String get cvv => accountDetailsModel.value?.data?.mPin ?? "00/00";

  String get amount => accountDetailsModel.value?.data?.amount ?? "0.00";

  String get earnAmount => accountDetailsModel.value?.data?.earnAmount ?? "0.00";


  Future<AccountDetailsModel?> getAccountDetails(String accountNumber) async {
    try {
      Map bodyParams = {
        "ac_no": accountNumber
      };

      final response = await http.post(
        Uri.parse(API.accountDetails),
        headers: API.header,
        body: jsonEncode(bodyParams),
      ).timeout(const Duration(seconds: 30));

      showLog("getAccountDetails => API :: URL :: ${API.accountDetails}");
      showLog("getAccountDetails => API :: Request Body :: ${jsonEncode(bodyParams)}");
      showLog("getAccountDetails => API :: Headers :: ${API.header}");
      showLog("getAccountDetails => API :: Response Status :: ${response.statusCode}");
      showLog("getAccountDetails => API :: Response Body :: ${response.body}");

      if (response.statusCode == 200) {
        Map<String, dynamic> responseBody = json.decode(response.body);
        AccountDetailsModel model = AccountDetailsModel.fromJson(responseBody);

        if (model.res == 'success') {
          accountDetailsModel.value = model;
          // IMPORTANT: Set loading false AFTER data is set
          await Future.delayed(Duration(milliseconds: 100)); // Small delay for smooth transition
          isLoading.value = false;
          return model;
        } else {
          isLoading.value = false;
          Get.back();
          ShowToastDialog.showToast(model.msg ?? 'Account not found', isError: true);
          return null;
        }
      } else {
        isLoading.value = false;
        ShowToastDialog.showToast('Server error. Please try again.');
        return null;
      }
    } on TimeoutException catch (e) {
      isLoading.value = false;
      showLog("getAccountDetails => TimeoutException :: $e");
      ShowToastDialog.showToast('Request timeout. Please try again.');
      return null;
    } on SocketException catch (e) {
      isLoading.value = false;
      showLog("getAccountDetails => SocketException :: $e");
      ShowToastDialog.showToast('Network error. Please check your connection.');
      return null;
    } on FormatException catch (e) {
      isLoading.value = false;
      showLog("getAccountDetails => FormatException :: $e");
      ShowToastDialog.showToast('Invalid response format.');
      return null;
    } catch (e) {
      isLoading.value = false;
      showLog("getAccountDetails => Exception :: $e");
      ShowToastDialog.showToast('Failed to fetch account details. Please try again.');
      return null;
    }
  }

  String get totalAmount {
    try {
      double amt = double.parse(amount);
      double earned = double.parse(earnAmount);
      double total = amt + earned;
      return total.toStringAsFixed(2);
    } catch (e) {
      return "0.00";
    }
  }

  @override
  void onClose() {
    flipController.dispose();
    shimmerController.dispose();
    super.onClose();
  }
}


// import 'dart:async';
// import 'dart:convert';
// import 'dart:io';
// import 'dart:math';
//
// import 'package:flutter/material.dart';
// import 'package:get/get.dart';
// import 'package:http/http.dart' as http;
//
// import '../../../../../constant/logdata.dart';
// import '../../../../../constant/show_toast_dialog.dart';
// import '../../../../../service/api.dart';
//
// class AccountDetailsController extends GetxController with GetTickerProviderStateMixin {
//   // Observable variables
//   var isFront = true.obs;
//
//   // Animation controllers
//   late AnimationController flipController;
//   late AnimationController shimmerController;
//   late Animation<double> flipAnimation;
//   late Animation<double> shimmerAnimation;
//
//   // Card data
//   final Map<String, String> cardData = {
//     "digitalPocket": "DP987654321",
//     "holderName": "Aditya Kumar",
//     "mobile": "+91 9876543210",
//     "code": "PREMIUM",
//     "expDays": "32",
//     "expDate": "12/28",
//     "cardType": "PLATINUM",
//     "bank": "Smart Value",
//     "cvv": "456",
//     "accountType": "Premium Account"
//   };
//
//   @override
//   void onInit() {
//     super.onInit();
//
//     flipController = AnimationController(
//       vsync: this,
//       duration: Duration(milliseconds: 800),
//     );
//
//     shimmerController = AnimationController(
//       vsync: this,
//       duration: Duration(milliseconds: 2000),
//     )..repeat();
//
//     flipAnimation = Tween<double>(begin: 0, end: pi).animate(
//       CurvedAnimation(parent: flipController, curve: Curves.easeInOut),
//     );
//
//     shimmerAnimation = Tween<double>(begin: -1, end: 2).animate(
//       CurvedAnimation(parent: shimmerController, curve: Curves.easeInOut),
//     );
//   }
//
//   void flipCard() {
//     if (isFront.value) {
//       flipController.forward();
//     } else {
//       flipController.reverse();
//     }
//     isFront.value = !isFront.value;
//   }
//
//   @override
//   void onClose() {
//     flipController.dispose();
//     shimmerController.dispose();
//     super.onClose();
//   }
//
//
//   Future<String?> getAccountDetails(String accountNumber) async {
//     try {
//       Map bodyParams = {
//         "ac_no":"$accountNumber"
//       };
//
//       final response = await http.post(
//         Uri.parse(API.accountDetails),
//         headers: API.header,
//         body: jsonEncode(bodyParams),
//       ).timeout(const Duration(seconds: 30)); // Add timeout
//
//       showLog("getNameByAccountNumber => API :: URL :: ${API.getNameByAcNo}");
//       showLog("getNameByAccountNumber => API :: Request Body :: ${jsonEncode(bodyParams)}");
//       showLog("getNameByAccountNumber => API :: Headers :: ${API.header}");
//       showLog("getNameByAccountNumber => API :: Response Status :: ${response.statusCode}");
//       showLog("getNameByAccountNumber => API :: Response Body :: ${response.body}");
//
//       if (response.statusCode == 200) {
//         Map<String, dynamic> responseBody = json.decode(response.body);
//
//         if (responseBody['res'] == 'success') {
//           return responseBody['msg']?.toString() ?? 'Unknown User';
//         } else {
//           Get.back(); // Go back to previous screen
//           String errorMsg = responseBody['msg']?.toString() ?? 'Account not found';
//           ShowToastDialog.showToast(errorMsg, isError: true);
//           return null;
//         }
//       } else {
//         ShowToastDialog.showToast('Server error. Please try again.');
//         return null;
//       }
//     } on TimeoutException catch (e) {
//       showLog("getNameByAccountNumber => TimeoutException :: $e");
//       ShowToastDialog.showToast('Request timeout. Please try again.');
//       return null;
//     } on SocketException catch (e) {
//       showLog("getNameByAccountNumber => SocketException :: $e");
//       ShowToastDialog.showToast('Network error. Please check your connection.');
//       return null;
//     } on FormatException catch (e) {
//       showLog("getNameByAccountNumber => FormatException :: $e");
//       ShowToastDialog.showToast('Invalid response format.');
//       return null;
//     } catch (e) {
//       showLog("getNameByAccountNumber => Exception :: $e");
//       ShowToastDialog.showToast('Failed to fetch account details. Please try again.');
//       return null;
//     }
//   }
// }
