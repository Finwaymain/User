import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:finway/constant/constant.dart';
import 'package:flutter/material.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;

import '../../../../../constant/logdata.dart';
import '../../../../../constant/show_toast_dialog.dart';
import '../../../../../service/api.dart';
import '../../AccountDetails/model/account_details_model.dart';
import '../view/payment_result_screen.dart';

class PinEntryController extends GetxController {
    RxString pin = ''.obs;
    RxBool isLoading = false.obs;
    RxBool isPinReady = false.obs;
    final int maxPinLength = 4;

    Rx<AccountDetailsModel?> accountDetailsModel = Rx<AccountDetailsModel?>(null);

    @override
    void onInit() {
        super.onInit();
        pin.value = '';
        isPinReady.value = false;
        getNameByAccountNumber("${Constant.getUserData().data?.acNo}");
    }

    bool _isValidMpin(String enteredPin) {
        final storedMdp = accountDetailsModel.value?.data?.mdp;
        if (storedMdp != null && storedMdp.isNotEmpty) {
            final hashedPin = md5.convert(utf8.encode(enteredPin)).toString();
            if (hashedPin == storedMdp) {
                return true;
            }
        }

        final storedMPin = accountDetailsModel.value?.data?.mPin;
        if (storedMPin != null && storedMPin.isNotEmpty) {
            return enteredPin == storedMPin;
        }

        return false;
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
        ).timeout(const Duration(seconds: 30));

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
            isPinReady.value = true;
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
        showLog("getNameByAccountNumber => TimeoutException :: $e");
        ShowToastDialog.showToast('Request timeout. Please try again.');
        return null;
      } on SocketException catch (e) {
        isLoading.value = false;
        showLog("getNameByAccountNumber => SocketException :: $e");
        ShowToastDialog.showToast('Network error. Please check your connection.');
        return null;
      } on FormatException catch (e) {
        isLoading.value = false;
        showLog("getNameByAccountNumber => FormatException :: $e");
        ShowToastDialog.showToast('Invalid response format.');
        return null;
      } catch (e) {
        isLoading.value = false;
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
        if (!isPinReady.value) {
            ShowToastDialog.showToast('Please wait while we verify your account.');
            return;
        }

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

        if (!_isValidMpin(pin.value)) {
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

        isLoading.value = true;
        ShowToastDialog.showLoader("Processing payment...");

        try {

            Map bodyParams = {
                "sender_ac_no":"${Constant.getUserData().data?.acNo}",
                "receiver_ac_no":paymentData,
                "amount":amount,
                "sender_type":"customer",
                "mpin": pin.value,
            };

            final response = await http.post(
                Uri.parse(API.transferToWallet),
                headers: API.header,
                body: jsonEncode(bodyParams)
            ).timeout(const Duration(seconds: 30));

            showLog("transferToWallet => API :: URL :: ${API.transferToWallet}");
            showLog("transferToWallet => API :: Request Body :: ${jsonEncode(bodyParams)}");
            showLog("transferToWallet => API :: Headers :: ${API.header}");
            showLog("transferToWallet => API :: Response Status :: ${response.statusCode}");
            showLog("transferToWallet => API :: Response Body :: ${response.body}");

            if (response.statusCode == 200) {
                Map<String, dynamic> responseBody = json.decode(response.body);
                final isSuccess = responseBody.containsKey('res') && responseBody['res'] == 'success';

                if (!isSuccess) {
                    clearPin();
                    final errorMsg = responseBody['msg']?.toString() ?? 'Transfer failed. Please try again.';
                    ShowToastDialog.showToast(
                        errorMsg,
                        isError: true,
                    );
                    final lower = errorMsg.toLowerCase();
                    if (lower.contains('insufficient') || lower.contains('balance') || lower.contains('not enough') || lower.contains('low balance')) {
                        Future.delayed(const Duration(seconds: 2), () {
                            Get.back();
                        });
                    }
                    return;
                }

                final responseData = responseBody['data'];
                final txnId = responseData is Map
                    ? responseData['txn_id']?.toString()
                    : null;
                final receiverName = responseData is Map
                    ? responseData['receiver_name']?.toString()
                    : null;

                isLoading.value = false;
                ShowToastDialog.closeLoader();
                EasyLoading.dismiss();

                Get.off(() => PaymentResultScreen(
                      paymentData: paymentData,
                      amount: amount,
                      isQRPayment: isQRPayment,
                      isSuccess: true,
                      transactionId: (txnId != null && txnId.isNotEmpty)
                          ? txnId
                          : "TXN${DateTime.now().millisecondsSinceEpoch.toString().substring(5)}",
                      receiverName: receiverName,
                    ));
                return;
            }
            else {
                ShowToastDialog.showToast('Server error. Please try again.');
                return;
            }
        }
        on TimeoutException catch (e) {
            showLog("transferToWallet => TimeoutException :: $e");
            ShowToastDialog.showToast('Request timeout. Please try again.');
            return;
        }
        on SocketException catch (e) {
            showLog("transferToWallet => SocketException :: $e");
            ShowToastDialog.showToast('Network error. Please check your connection.');
            return;
        }
        on FormatException catch (e) {
            showLog("transferToWallet => FormatException :: $e");
            ShowToastDialog.showToast('Invalid response format.');
            return;
        }
        catch (e) {
            showLog("transferToWallet => Exception :: $e");
            ShowToastDialog.showToast('Failed to process payment. Please try again.');
            return;
        }

        finally {
            isLoading.value = false;
            ShowToastDialog.closeLoader();
            EasyLoading.dismiss();
        }
    }
}
