import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;

import '../../../../../constant/constant.dart';
import '../../../../../constant/logdata.dart';
import '../../../../../constant/show_toast_dialog.dart';
import '../../../../../model/user_model.dart';
import '../../../../../service/api.dart';
import '../../AccountDetails/model/account_details_model.dart';

class PayoutController extends GetxController with GetTickerProviderStateMixin {
  final TextEditingController amountController = TextEditingController();
  final List<int> presetAmounts = [50, 100, 200, 300, 500, 1000];
  late AnimationController slideController;
  late AnimationController fadeController;
  late Animation<Offset> slideAnimation;
  late Animation<double> fadeAnimation;
  Rx<AccountDetailsModel?> accountDetailsModel = Rx<AccountDetailsModel?>(null);

  String ac_no = '';

  final RxBool isLoading = false.obs;
  String get amount => accountDetailsModel.value?.data?.amount ?? "0.00";

  String get earnAmount => accountDetailsModel.value?.data?.earnAmount ?? "0.00";

  String get totalAmount => (double.parse(amount) + double.parse(earnAmount)).toStringAsFixed(2);


  @override
  void onInit() {
    super.onInit();

    UserModel userModel = Constant.getUserData();
    ac_no = userModel.data!.acNo ?? '';

    _initializeAnimations();
    getAccountDetails("${Constant.getUserData().data?.acNo}");
  }

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

  void _initializeAnimations() {
    slideController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    fadeController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: slideController,
      curve: Curves.easeOutCubic,
    ));

    fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: fadeController,
      curve: Curves.easeOut,
    ));

    slideController.forward();
    fadeController.forward();
  }

  @override
  void onClose() {
    slideController.dispose();
    fadeController.dispose();
    amountController.dispose();
    super.onClose();
  }

  void handleAmountSelection(int amount) {
    HapticFeedback.lightImpact();
    amountController.text = amount.toString();
    update(); // Update UI to reflect selection changes
  }

  // Confirmation Dialog Method
  Future<bool> showWithdrawConfirmationDialog() async {
    return await Get.dialog<bool>(
      AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.orange.shade100,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                Icons.warning_amber_rounded,
                color: Colors.orange.shade600,
                size: 24,
              ),
            ),
            const SizedBox(width: 12),
            const Text(
              'Confirm Withdrawal',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Are you sure you want to withdraw?',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey.shade700,
              ),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.blue.shade200),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Withdraw Amount:',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey.shade600,
                        ),
                      ),
                      Text(
                        '${Constant.currency}${amountController.text}',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.green,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Account No.:',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey.shade600,
                        ),
                      ),
                      Text(
                        ac_no,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),

                ],
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'This action cannot be undone.',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey.shade500,
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              HapticFeedback.lightImpact();
              Get.back(result: false);
            },
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: Text(
              'No, Cancel',
              style: TextStyle(
                color: Colors.grey.shade600,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              HapticFeedback.mediumImpact();
              Get.back(result: true);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              elevation: 0,
            ),
            child: const Text(
              'Yes, Withdraw',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
      barrierDismissible: false,
    ) ?? false;
  }

  // API call method for withdraw wallet
  Future<dynamic> withdrawWallet() async {
    try {
      ShowToastDialog.showLoader("Processing payout request...");

      Map<String, String> bodyParams = {
        "ac_no":"${Constant.getUserData().data?.acNo}",
        "amount":amountController.text,
        "user_type":"customer"
      };

      final response = await http.post(
          Uri.parse(API.withdrawWallet),
          headers: API.header,
          body: jsonEncode(bodyParams));

      showLog("withdrawWallet => API :: URL :: ${API.withdrawWallet}");
      showLog("withdrawWallet => API :: Request Body :: ${jsonEncode(bodyParams)} ");
      showLog("withdrawWallet => API :: Headers :: ${API.header} ");
      showLog("withdrawWallet => API :: Response Status :: ${response.statusCode} ");
      showLog("withdrawWallet => API :: Response Body :: ${response.body} ");

      Map<String, dynamic> responseBody = json.decode(response.body);

      if (responseBody['res'] == 'success') {
        ShowToastDialog.closeLoader();

        Map<String, dynamic> transactionData = responseBody['data'];

        String txnId = transactionData['txn_id'] ?? '';
        String amount = transactionData['amount'] ?? '';

        // Clear amount field
        amountController.clear();

        // 🔥 SUCCESS KE BAAD ACCOUNT DETAILS REFRESH KARO
        await getAccountDetails(ac_no);

        // Success message
        Get.snackbar(
          "Payout Requested! 🎉",
          "Your payout of ${Constant.currency}$amount has been submitted\nTransaction ID: $txnId",
          snackPosition: SnackPosition.TOP,
          backgroundColor: Colors.green.shade100,
          colorText: Colors.green.shade800,
          icon: const Icon(Icons.check_circle_outline, color: Colors.green),
          borderRadius: 12,
          margin: const EdgeInsets.all(16),
          duration: const Duration(seconds: 4),
        );

        return responseBody;
      }
      else {
        ShowToastDialog.closeLoader();
        // Show the actual error message from API if available
        String errorMsg = responseBody['msg'] ?? 'Something went wrong. Please try again later';
        ShowToastDialog.showToast(errorMsg,isError: true);
      }
    } on TimeoutException {
      ShowToastDialog.closeLoader();
      ShowToastDialog.showToast("Request timeout. Please check your internet connection.");
    } on SocketException {
      ShowToastDialog.closeLoader();
      ShowToastDialog.showToast("Network error. Please check your internet connection.");
    } on FormatException {
      ShowToastDialog.closeLoader();
      ShowToastDialog.showToast("Invalid response format. Please try again.");
    } on Error catch (e) {
      ShowToastDialog.closeLoader();
      ShowToastDialog.showToast("An error occurred: ${e.toString()}");
    } catch (e) {
      ShowToastDialog.closeLoader();
      ShowToastDialog.showToast("Failed to process request. Please try again.");
    }
    return null;
  }

  Future<void> handlePayoutRequest() async {

    // Prevent double click
    if (isLoading.value) return;

    final enteredAmountText = amountController.text.trim();

    if (enteredAmountText.isEmpty) {
      _showSnack(
        "Amount Required",
        "Please enter or select an amount",
        Icons.warning_amber_rounded,
        Colors.orange,
      );
      return;
    }

    // Decimal validation (max 2 decimal)
    if (!RegExp(r'^\d+(\.\d{1,2})?$').hasMatch(enteredAmountText)) {
      _showSnack(
        "Invalid Amount",
        "Only 2 decimal places allowed",
        Icons.error_outline,
        Colors.red,
      );
      return;
    }

    final double enteredAmount = double.tryParse(enteredAmountText) ?? 0;

    if (enteredAmount <= 0) {
      _showSnack(
        "Invalid Amount",
        "Amount must be greater than zero",
        Icons.error_outline,
        Colors.red,
      );
      return;
    }

    /// 🔹 Minimum withdraw rule
    const double minWithdraw = 50;
    if (enteredAmount < minWithdraw) {
      _showSnack(
        "Minimum Withdrawal",
        "Minimum withdraw amount is ${Constant.currency}$minWithdraw",
        Icons.info_outline,
        Colors.orange,
      );
      return;
    }

    /// 🔹 Maximum withdraw rule (optional)
    const double maxWithdraw = 10000;
    if (enteredAmount > maxWithdraw) {
      _showSnack(
        "Limit Exceeded",
        "Maximum withdraw amount is ${Constant.currency}$maxWithdraw",
        Icons.info_outline,
        Colors.orange,
      );
      return;
    }

    /// 🔹 Wallet balance check
    final double walletBalance =
        double.tryParse(amount?? '0') ?? 0;

    if (enteredAmount > walletBalance) {
      _showSnack(
        "Insufficient Balance",
        "Available balance is ${Constant.currency}$walletBalance",
        Icons.account_balance_wallet_outlined,
        Colors.red,
      );
      return;
    }

    /// 🔹 Account validation
    if (ac_no.isEmpty) {
      _showSnack(
        "Account Error",
        "Account number not found. Please contact support.",
        Icons.error_outline,
        Colors.red,
      );
      return;
    }

    /// 🔹 Confirmation Dialog
    bool confirmed = await showWithdrawConfirmationDialog();
    if (!confirmed) return;

    isLoading.value = true;
    HapticFeedback.heavyImpact();

    try {
      await withdrawWallet();
    } finally {
      isLoading.value = false;
    }
  }

  void _showSnack(
      String title,
      String message,
      IconData icon,
      Color color,
      ) {
    HapticFeedback.mediumImpact();
    Get.snackbar(
      title,
      message,
      snackPosition: SnackPosition.TOP,
      backgroundColor: color.withValues(alpha: 0.15),
      colorText: color.withValues(alpha: 0.8),
      icon: Icon(icon, color: color),
      borderRadius: 12,
      margin: const EdgeInsets.all(16),
    );
  }


}