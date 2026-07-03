import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:finway/constant/constant.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;

import '../../../../../constant/logdata.dart';
import '../../../../../constant/show_toast_dialog.dart';
import '../../../../../service/api.dart';
import '../../AccountDetails/model/account_details_model.dart';
import '../../ScanAndTransfer/view/scanner_and_transfer_screen.dart';

class PinEntryController extends GetxController {
    RxString pin = ''.obs;
    RxBool isLoading = false.obs;
    final int maxPinLength = 4;
    String correctPin = '';

    Rx<AccountDetailsModel?> accountDetailsModel = Rx<AccountDetailsModel?>(null);

    @override
    void onInit() {
        // TODO: implement onInit
        super.onInit();


        getNameByAccountNumber("${Constant.getUserData().data?.acNo}");
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
            correctPin = "${model.data?.mPin}";
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

    void addDigit(String digit) {
        if (pin.value.length < maxPinLength) {
            pin.value += digit;
        }
    }

    void removeDigit() {
        if (pin.value.isNotEmpty) {
            pin.value = pin.value.substring(0, pin.value.length - 1);
        }
    }

    void clearPin() {
        pin.value = '';
    }

    Future<void> processPayment(
        String paymentData, String amount, bool isQRPayment) async {
        if (pin.value.length != maxPinLength) {
            Get.snackbar(
                'Error',
                'Please enter complete PIN',
                snackPosition: SnackPosition.BOTTOM,
                backgroundColor: Colors.red,
                colorText: Colors.white,
                duration: const Duration(seconds: 2)
            );
            return;
        }

        // Validate PIN
        if (pin.value != correctPin) {
            // Clear PIN on wrong attempt
            clearPin();

            Get.snackbar(
                'Invalid PIN',
                'The PIN you entered is incorrect. Please try again.',
                snackPosition: SnackPosition.BOTTOM,
                backgroundColor: Colors.red,
                colorText: Colors.white,
                duration: const Duration(seconds: 3),
                icon: const Icon(Icons.error_outline, color: Colors.white)
            );
            return;
        }

        // PIN is correct, proceed with payment
        isLoading.value = true;

        try {

            Map bodyParams = {
                "sender_ac_no":"${Constant.getUserData().data?.acNo}",
                "receiver_ac_no":paymentData,
                "amount":amount,
                "sender_type":"customer"
            };

            final response = await http.post(
                Uri.parse(API.transferToWallet),
                headers: API.header,
                body: jsonEncode(bodyParams)
            ).timeout(const Duration(seconds: 30));

            showLog("getAccountDetails => API :: URL :: ${API.accountDetails}");
            showLog("getAccountDetails => API :: Request Body :: ${jsonEncode(bodyParams)}");
            showLog("getAccountDetails => API :: Headers :: ${API.header}");
            showLog("getAccountDetails => API :: Response Status :: ${response.statusCode}");
            showLog("getAccountDetails => API :: Response Body :: ${response.body}");

            if (response.statusCode == 200) {
                Map<String, dynamic> responseBody = json.decode(response.body);
                // AccountDetailsModel model = AccountDetailsModel.fromJson(responseBody);

                Get.to(() => PaymentResultScreen(
                        paymentData: paymentData,
                        amount: amount,
                        isQRPayment: isQRPayment,
                        isSuccess: responseBody.containsKey('res') && responseBody['res'] == 'success',
                        transactionId:
                        "TXN${DateTime.now().millisecondsSinceEpoch.toString().substring(5)}"));
                isLoading.value = false;
            }
            else {
                isLoading.value = false;
                ShowToastDialog.showToast('Server error. Please try again.');
                return;
            }
        }
        on TimeoutException catch (e) {
            isLoading.value = false;
            showLog("getAccountDetails => TimeoutException :: $e");
            ShowToastDialog.showToast('Request timeout. Please try again.');
            return;
        }
        on SocketException catch (e) {
            isLoading.value = false;
            showLog("getAccountDetails => SocketException :: $e");
            ShowToastDialog.showToast('Network error. Please check your connection.');
            return;
        }
        on FormatException catch (e) {
            isLoading.value = false;
            showLog("getAccountDetails => FormatException :: $e");
            ShowToastDialog.showToast('Invalid response format.');
            return;
        }
        catch (e) {
            isLoading.value = false;
            showLog("getAccountDetails => Exception :: $e");
            ShowToastDialog.showToast('Failed to fetch account details. Please try again.');
            return;
        }

        finally {
            isLoading.value = false;
        }
    }
}
