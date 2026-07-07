import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../../constant/logdata.dart';
import '../../../../../constant/show_toast_dialog.dart';
import '../../../../../service/api.dart';
import '../../AccountDetails/model/account_details_model.dart';
import '../../PinEntryScreen/view/pin_entry_screen.dart';
import 'package:http/http.dart' as http;

class AmountEntryController extends GetxController {
  final TextEditingController amountController = TextEditingController();
  RxString amount = ''.obs;
  RxBool isLoading = false.obs;
  RxBool isLoadingName = true.obs; // Start with true for initial shimmer
  RxString accountHolderName = ''.obs; // Start empty
  Rx<AccountDetailsModel?> accountDetailsModel = Rx<AccountDetailsModel?>(null);

  // Make paymentData nullable and initialize it properly
  String? _paymentData;

  // Getter for paymentData
  String get paymentData => _paymentData ?? '';

  @override
  void onInit() {
    super.onInit();
    amountController.addListener(() {
      amount.value = amountController.text;
    });

    // Initialize with arguments
    if (Get.arguments != null) {
      if (Get.arguments is Map) {
        _paymentData = Get.arguments['paymentData'];
        if (Get.arguments['amount'] != null) {
          amountController.text = Get.arguments['amount'];
          amount.value = amountController.text;
        }
      } else if (Get.arguments is String) {
        _paymentData = Get.arguments;
      }
      if (_paymentData != null) {
        initializeWithPaymentData(_paymentData!);
      }
    } else {
      // If no arguments, stop loading
      isLoadingName.value = false;
      accountHolderName.value = 'Unknown User';
    }
  }

  @override
  void onClose() {
    amountController.dispose();
    super.onClose();
  }

  // Method to initialize and fetch name
  Future<void> initializeWithPaymentData(String paymentData) async {
    try {
      isLoadingName.value = true;
      accountHolderName.value = '';

      final name = await getNameByAccountNumber(paymentData);

      if (name != null && name.data!.acNo!.isNotEmpty) {
        accountHolderName.value = name.data!.getFullName() ?? 'Unknown User';
      } else {
        accountHolderName.value = 'Unknown User';
      }
    } catch (e) {
      accountHolderName.value = 'Unknown User';
    } finally {
      isLoadingName.value = false;
    }
  }

  Future<AccountDetailsModel?> getNameByAccountNumber(String accountNumber) async {
    try {
      Map bodyParams = {
        'ac_no': accountNumber,
      };

      final response = await http.post(
        Uri.parse(API.accountDetails),
        headers: API.header,
        body: jsonEncode(bodyParams),
      ).timeout(const Duration(seconds: 30)); // Add timeout

      showLog("getNameByAccountNumber => API :: URL :: ${API.accountDetails}");
      showLog("getNameByAccountNumber => API :: Request Body :: ${jsonEncode(bodyParams)}");
      showLog("getNameByAccountNumber => API :: Headers :: ${API.header}");
      showLog("getNameByAccountNumber => API :: Response Status :: ${response.statusCode}");
      showLog("getNameByAccountNumber => API :: Response Body :: ${response.body}");

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
      showLog("getNameByAccountNumber => TimeoutException :: $e");
      ShowToastDialog.showToast('Request timeout. Please try again.');
      return null;
    } on SocketException catch (e) {
      showLog("getNameByAccountNumber => SocketException :: $e");
      ShowToastDialog.showToast('Network error. Please check your connection.');
      return null;
    } on FormatException catch (e) {
      showLog("getNameByAccountNumber => FormatException :: $e");
      ShowToastDialog.showToast('Invalid response format.');
      return null;
    } catch (e) {
      showLog("getNameByAccountNumber => Exception :: $e");
      ShowToastDialog.showToast('Failed to fetch account details. Please try again.');
      return null;
    }
  }

  void proceedToPinEntry(String paymentData, bool isQRPayment) {
    if (amount.value.isEmpty || double.tryParse(amount.value) == null) {
      Get.snackbar(
        'Error',
        'Please enter a valid amount',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
      return;
    }

    double enteredAmount = double.parse(amount.value);
    if (enteredAmount <= 0) {
      Get.snackbar(
        'Error',
        'Please enter an amount greater than 0',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
      return;
    }

    isLoading.value = true;

    try {
      Get.to(() => PinEntryScreen(
        paymentData: paymentData,
        amount: amount.value,
        isQRPayment: isQRPayment,
      ));
    } finally {
      isLoading.value = false;
    }
  }
}