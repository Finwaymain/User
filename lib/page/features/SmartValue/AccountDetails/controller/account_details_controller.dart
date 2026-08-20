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
  AccountDetailsController({this.popOnError = true});

  final bool popOnError;

  // Observable variables
  var isFront = true.obs;
  var isLoading = false.obs;
  Rx<AccountDetailsModel?> accountDetailsModel = Rx<AccountDetailsModel?>(null);

  // Animation controllers
  late AnimationController flipController;
  late AnimationController shimmerController;
  late Animation<double> flipAnimation;
  late Animation<double> shimmerAnimation;

  void resetCardState() {
    isFront.value = true;
    if (flipController.isAnimating) {
      flipController.stop();
    }
    flipController.value = 0;
  }

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

    resetCardState();
    _applyCachedProfile();
    isLoading.value = accountDetailsModel.value == null;

    final acNo = Constant.getUserData().data?.acNo;
    if (acNo != null && acNo.isNotEmpty) {
      getAccountDetails(acNo);
    } else {
      isLoading.value = false;
    }
  }


  void flipCard() {
    if (isFront.value) {
      flipController.forward();
    } else {
      flipController.reverse();
    }
    isFront.value = !isFront.value;
  }

  String get digitalPocket => _profile()?.acNo ?? '000000000';

  String get holderName {
    final name = _profile()?.getFullName() ?? '';
    if (name.isNotEmpty) return name;

    final user = Constant.getUserData().data;
    final fallback = '${user?.prenom ?? ''} ${user?.nom ?? ''}'.trim();
    return fallback.isNotEmpty ? fallback : 'N/A';
  }

  String get mobile => _profile()?.phone ?? "N/A";

  String get accountNumber => _profile()?.acNo ?? "N/A";

  String get expDays => _profile()?.getDaysToStart()?.toString() ?? "0";

  String get expDate => _profile()?.getFormattedStartDate() ?? "00/00";

  String get accountType {
    final status = _profile()?.statut;
    return status == "yes" ? "Active Account" : "Inactive Account";
  }

  String get cardType => "PLATINUM";

  String get bank => "Smart Value";

  String get cvv => _profile()?.mPin ?? "00/00";

  String get amount => _profile()?.amount ?? "0.00";

  String get earnAmount => _profile()?.earnAmount ?? "0.00";

  bool get hasCashback => cashbackText.isNotEmpty;

  String get cashbackText {
    final profileData = _profile();
    
    // 1. Try percentage / perSender from user profile / schedules
    String rawVal = profileData?.percentage?.trim() ?? '';
    if (rawVal.isEmpty || rawVal == '0' || rawVal == '0.0' || rawVal == '0.00' || rawVal == 'null') {
      rawVal = profileData?.perSender?.trim() ?? '';
    }
    
    // 2. Check user's active consumer plan cashback
    if (rawVal.isEmpty || rawVal == '0' || rawVal == '0.0' || rawVal == '0.00' || rawVal == 'null') {
      final userPlan = Constant.getUserData().data?.consumerPlan;
      if (userPlan?.cashbackOnPurchase != null &&
          userPlan!.cashbackOnPurchase!.trim().isNotEmpty &&
          userPlan.cashbackOnPurchase != '0' &&
          userPlan.cashbackOnPurchase != '0.0' &&
          userPlan.cashbackOnPurchase != '0.00' &&
          userPlan.cashbackOnPurchase != 'null') {
        rawVal = userPlan.cashbackOnPurchase!.trim();
      }
    }

    if (rawVal.isEmpty || rawVal == '0' || rawVal == '0.0' || rawVal == '0.00' || rawVal == 'null') {
      return '';
    }

    // If already contains % symbol
    if (rawVal.contains('%')) {
      final clean = rawVal.replaceAll('Cashback', '').replaceAll('cashback', '').trim();
      return '$clean Cashback';
    }

    // If contains rupee symbol or Rs or starts with ₹
    if (rawVal.contains('₹') || rawVal.toLowerCase().contains('rs')) {
      final clean = rawVal.replaceAll('Cashback', '').replaceAll('cashback', '').trim();
      return '$clean Cashback';
    }

    // Parse numeric value
    final numVal = double.tryParse(rawVal);
    if (numVal != null) {
      if (numVal <= 0) return '';
      final formattedNum = (numVal % 1 == 0) ? numVal.toInt().toString() : numVal.toString();
      // If admin entered a flat amount (like 50, 100, 25) or > 10
      if (numVal > 10) {
        return '₹$formattedNum Cashback';
      }
      // If <= 10, by default it is a percentage (e.g. 1%, 2%, 5%)
      return '$formattedNum% Cashback';
    }

    return '$rawVal Cashback';
  }

  AccountData? _profile() {
    if (accountDetailsModel.value?.data != null) {
      return accountDetailsModel.value!.data;
    }
    final user = Constant.getUserData().data;
    if (user == null) return null;
    return AccountData.fromJson({
      'id': user.id,
      'ac_no': user.acNo,
      'nom': user.nom,
      'prenom': user.prenom,
      'holder_name': '${user.prenom ?? ''} ${user.nom ?? ''}'.trim(),
      'phone': user.phone,
      'm_pin': user.mPin,
      'statut': user.statut,
      'amount': user.amount,
      'earn_amount': user.earnAmount,
      'start_date': user.startDate,
    });
  }

  void _applyCachedProfile() {
    final user = Constant.getUserData().data;
    if (user == null) return;

    accountDetailsModel.value = AccountDetailsModel(
      res: 'success',
      msg: 'Cached profile',
      data: AccountData.fromJson({
        'id': user.id,
        'ac_no': user.acNo,
        'nom': user.nom,
        'prenom': user.prenom,
        'holder_name': '${user.prenom ?? ''} ${user.nom ?? ''}'.trim(),
        'phone': user.phone,
        'm_pin': user.mPin,
        'statut': user.statut,
        'amount': user.amount,
        'earn_amount': user.earnAmount,
        'start_date': user.startDate,
      }),
    );
  }


  Future<AccountDetailsModel?> getAccountDetails(String accountNumber) async {
    final showBlockingLoader = accountDetailsModel.value == null;
    if (showBlockingLoader) {
      isLoading.value = true;
    }

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
          _applyCachedProfile();
          isLoading.value = false;
          if (popOnError) {
            Get.back();
            ShowToastDialog.showToast(model.msg ?? 'Account not found', isError: true);
          }
          return accountDetailsModel.value;
        }
      } else {
        _applyCachedProfile();
        isLoading.value = false;
        if (popOnError) {
          ShowToastDialog.showToast('Server error. Please try again.');
        }
        return accountDetailsModel.value;
      }
    } on TimeoutException catch (e) {
      _applyCachedProfile();
      isLoading.value = false;
      showLog("getAccountDetails => TimeoutException :: $e");
      if (popOnError) ShowToastDialog.showToast('Request timeout. Please try again.');
      return accountDetailsModel.value;
    } on SocketException catch (e) {
      _applyCachedProfile();
      isLoading.value = false;
      showLog("getAccountDetails => SocketException :: $e");
      if (popOnError) ShowToastDialog.showToast('Network error. Please check your connection.');
      return accountDetailsModel.value;
    } on FormatException catch (e) {
      _applyCachedProfile();
      isLoading.value = false;
      showLog("getAccountDetails => FormatException :: $e");
      if (popOnError) ShowToastDialog.showToast('Invalid response format.');
      return accountDetailsModel.value;
    } catch (e) {
      _applyCachedProfile();
      isLoading.value = false;
      showLog("getAccountDetails => Exception :: $e");
      if (popOnError) ShowToastDialog.showToast('Failed to fetch account details. Please try again.');
      return accountDetailsModel.value;
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
