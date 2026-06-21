import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:finway/constant/constant.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;

import '../../../../../constant/logdata.dart';
import '../../../../../constant/show_toast_dialog.dart';
import '../../../../../model/user_model.dart';
import '../../../../../service/api.dart';
import '../../../../../themes/constant_colors.dart';
import '../../../../../utils/Preferences.dart';
import '../../AccountDetails/model/account_details_model.dart';

class MPinChangeController extends GetxController
    with GetSingleTickerProviderStateMixin {
  // Animation Controller
  late AnimationController animationController;
  late Animation<double> fadeAnimation;
  late Animation<double> slideAnimation;

  // PIN related observables
  var currentPinInput = ''.obs; // User input for current PIN
  var newPin = ''.obs;
  var confirmPin = ''.obs;
  var currentStep = 0.obs;
  var isLoading = false.obs;
  var isCurrentPinVisible = false.obs;
  var isNewPinVisible = false.obs;
  var isConfirmPinVisible = false.obs;
  final RxString userId = ''.obs;
  final RxBool hasMPinSet = false.obs;
  final RxBool isSetMode = false.obs;

  // Store correct PIN from API (separate from user input)
  String storedMPin = '';

  // Focus nodes for each step
  late List<FocusNode> currentPinFocusNodes;
  late List<FocusNode> newPinFocusNodes;
  late List<FocusNode> confirmPinFocusNodes;

  // Text controllers for each step
  late List<TextEditingController> currentPinControllers;
  late List<TextEditingController> newPinControllers;
  late List<TextEditingController> confirmPinControllers;
  Rx<AccountDetailsModel?> accountDetailsModel = Rx<AccountDetailsModel?>(null);

  @override
  void onInit() {
    super.onInit();
    userId.value = Preferences.getInt(Preferences.userId).toString();

    // Initialize controllers and animations first
    _initializeAnimations();
    _initializeControllers();

    // Fetch current PIN from API
    _fetchCurrentPinFromAPI();

    _startAnimations();
  }

  // Fetch current M-PIN from API
  Future<void> _fetchCurrentPinFromAPI() async {
    try {
      isLoading.value = true;

      final accountNumber = Constant.getUserData().data?.acNo ?? '';

      if (accountNumber.isEmpty) {
        showLog("Account number not found");
        isLoading.value = false;
        _checkMPinStatus();
        return;
      }

      final result = await getNameByAccountNumber(accountNumber);

      if (result != null && result.data?.mPin != null) {
        storedMPin = result.data!.mPin.toString();
        showLog("Current M-PIN fetched from API: $storedMPin");
      }

      isLoading.value = false;
      _checkMPinStatus();

    } catch (e) {
      showLog("Error fetching M-PIN: $e");
      isLoading.value = false;
      _checkMPinStatus();
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
          return model;
        } else {
          ShowToastDialog.showToast(model.msg ?? 'Account not found', isError: true);
          return null;
        }
      } else {
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

  void _checkMPinStatus() {
    // Check if M-PIN is set based on API response
    hasMPinSet.value = storedMPin.isNotEmpty;

    if (!hasMPinSet.value) {
      // If no M-PIN is set, switch to set mode
      isSetMode.value = true;
      currentStep.value = 1;

      Future.delayed(const Duration(milliseconds: 800), () {
        if (newPinFocusNodes.isNotEmpty && newPinFocusNodes[0].canRequestFocus) {
          newPinFocusNodes[0].requestFocus();
        }
      });
    } else {
      // If M-PIN exists, use change mode
      isSetMode.value = false;
      currentStep.value = 0;

      Future.delayed(const Duration(milliseconds: 800), () {
        if (currentPinFocusNodes.isNotEmpty && currentPinFocusNodes[0].canRequestFocus) {
          currentPinFocusNodes[0].requestFocus();
        }
      });
    }
  }

  void _initializeAnimations() {
    animationController = AnimationController(
        duration: const Duration(milliseconds: 1000), vsync: this);

    fadeAnimation = CurvedAnimation(
        parent: animationController, curve: Curves.easeOut);

    slideAnimation = CurvedAnimation(
        parent: animationController, curve: Curves.elasticOut);
  }

  void _initializeControllers() {
    currentPinFocusNodes = List.generate(4, (index) => FocusNode());
    newPinFocusNodes = List.generate(4, (index) => FocusNode());
    confirmPinFocusNodes = List.generate(4, (index) => FocusNode());

    currentPinControllers = List.generate(4, (index) => TextEditingController());
    newPinControllers = List.generate(4, (index) => TextEditingController());
    confirmPinControllers = List.generate(4, (index) => TextEditingController());

    for (int i = 0; i < 4; i++) {
      currentPinControllers[i].addListener(() => _updateCurrentPin());
      newPinControllers[i].addListener(() => _updateNewPin());
      confirmPinControllers[i].addListener(() => _updateConfirmPin());
    }
  }

  void _startAnimations() {
    animationController.forward();
  }

  void _updateCurrentPin() {
    currentPinInput.value = currentPinControllers.map((c) => c.text).join();
  }

  void _updateNewPin() {
    newPin.value = newPinControllers.map((c) => c.text).join();
  }

  void _updateConfirmPin() {
    confirmPin.value = confirmPinControllers.map((c) => c.text).join();
  }

  void onPinChanged(String value, int index, int step) {
    late List<TextEditingController> controllers;
    late List<FocusNode> focusNodes;

    switch (step) {
      case 0:
        controllers = currentPinControllers;
        focusNodes = currentPinFocusNodes;
        break;
      case 1:
        controllers = newPinControllers;
        focusNodes = newPinFocusNodes;
        break;
      case 2:
        controllers = confirmPinControllers;
        focusNodes = confirmPinFocusNodes;
        break;
    }

    if (value.isEmpty) {
      if (index > 0) {
        HapticFeedback.lightImpact();
        focusNodes[index - 1].requestFocus();
      }
    } else {
      if (value.length > 1) {
        controllers[index].text = value.substring(value.length - 1);
        controllers[index].selection =
            TextSelection.fromPosition(TextPosition(offset: 1));
      }

      HapticFeedback.lightImpact();

      if (index < 3 && value.isNotEmpty) {
        focusNodes[index + 1].requestFocus();
      } else if (index == 3) {
        focusNodes[index].unfocus();
      }
    }

    update();
  }

  bool onKeyPressed(RawKeyEvent event, int index, int step) {
    if (event is RawKeyDownEvent &&
        event.logicalKey == LogicalKeyboardKey.backspace) {
      late List<TextEditingController> controllers;
      late List<FocusNode> focusNodes;

      switch (step) {
        case 0:
          controllers = currentPinControllers;
          focusNodes = currentPinFocusNodes;
          break;
        case 1:
          controllers = newPinControllers;
          focusNodes = newPinFocusNodes;
          break;
        case 2:
          controllers = confirmPinControllers;
          focusNodes = confirmPinFocusNodes;
          break;
      }

      if (controllers[index].text.isEmpty && index > 0) {
        HapticFeedback.lightImpact();
        focusNodes[index - 1].requestFocus();
        controllers[index - 1].clear();
        return true;
      }
    }
    return false;
  }

  String getCurrentPinValue() {
    return currentPinControllers.map((c) => c.text).join();
  }

  String getNewPinValue() {
    return newPinControllers.map((c) => c.text).join();
  }

  String getConfirmPinValue() {
    return confirmPinControllers.map((c) => c.text).join();
  }

  void toggleCurrentPinVisibility() {
    HapticFeedback.lightImpact();
    isCurrentPinVisible.value = !isCurrentPinVisible.value;
    update();
  }

  void toggleNewPinVisibility() {
    HapticFeedback.lightImpact();
    isNewPinVisible.value = !isNewPinVisible.value;
    update();
  }

  void toggleConfirmPinVisibility() {
    HapticFeedback.lightImpact();
    isConfirmPinVisible.value = !isConfirmPinVisible.value;
    update();
  }

  void proceedToNextStep() async {
    isLoading.value = true;
    await Future.delayed(const Duration(milliseconds: 100));

    if (isSetMode.value) {
      if (currentStep.value == 1) {
        final newPinValue = getNewPinValue();
        if (newPinValue.length != 4) {
          _showErrorMessage('Please enter a 4-digit PIN');
          isLoading.value = false;
          return;
        }
        HapticFeedback.mediumImpact();
        currentStep.value = 2;
        Future.delayed(const Duration(milliseconds: 300), () {
          if (confirmPinFocusNodes.isNotEmpty) {
            confirmPinFocusNodes[0].requestFocus();
          }
        });
      }
    } else {
      if (currentStep.value == 0) {
        final currentPinValue = getCurrentPinValue();
        if (currentPinValue.length != 4) {
          _showErrorMessage('Please enter your current 4-digit PIN');
          isLoading.value = false;
          return;
        }

        // Verify current PIN with API fetched PIN
        if (storedMPin.isEmpty) {
          _showErrorMessage('Unable to verify PIN. Please try again.');
          isLoading.value = false;
          return;
        }

        if (currentPinValue != storedMPin) {
          _showErrorMessage('Current PIN is incorrect. Please try again.');
          _clearCurrentPin();
          Future.delayed(const Duration(milliseconds: 300), () {
            if (currentPinFocusNodes.isNotEmpty) {
              currentPinFocusNodes[0].requestFocus();
            }
          });
          isLoading.value = false;
          return;
        }

        HapticFeedback.mediumImpact();
        currentStep.value = 1;
        Future.delayed(const Duration(milliseconds: 300), () {
          if (newPinFocusNodes.isNotEmpty) {
            newPinFocusNodes[0].requestFocus();
          }
        });
      } else if (currentStep.value == 1) {
        final newPinValue = getNewPinValue();
        if (newPinValue.length != 4) {
          _showErrorMessage('Please enter a 4-digit new PIN');
          isLoading.value = false;
          return;
        }
        if (!isSetMode.value) {
          final currentPinValue = getCurrentPinValue();
          if (newPinValue == currentPinValue) {
            _showErrorMessage('New PIN must be different from current PIN');
            isLoading.value = false;
            return;
          }
        }
        HapticFeedback.mediumImpact();
        currentStep.value = 2;
        Future.delayed(const Duration(milliseconds: 300), () {
          if (confirmPinFocusNodes.isNotEmpty) {
            confirmPinFocusNodes[0].requestFocus();
          }
        });
      }
    }
    isLoading.value = false;
  }

  void goBackToPreviousStep() {
    HapticFeedback.lightImpact();

    if (isSetMode.value) {
      if (currentStep.value == 2) {
        currentStep.value = 1;
        _clearConfirmPin();
        Future.delayed(const Duration(milliseconds: 300), () {
          if (newPinFocusNodes.isNotEmpty) {
            newPinFocusNodes[0].requestFocus();
          }
        });
      }
    } else {
      if (currentStep.value > 0) {
        currentStep.value--;

        if (currentStep.value == 0) {
          _clearNewPin();
          _clearConfirmPin();
          Future.delayed(const Duration(milliseconds: 300), () {
            if (currentPinFocusNodes.isNotEmpty) {
              currentPinFocusNodes[0].requestFocus();
            }
          });
        } else if (currentStep.value == 1) {
          _clearConfirmPin();
          Future.delayed(const Duration(milliseconds: 300), () {
            if (newPinFocusNodes.isNotEmpty) {
              newPinFocusNodes[0].requestFocus();
            }
          });
        }
      }
    }
  }

  Future<void> changeMPin() async {
    isLoading.value = true;
    await Future.delayed(const Duration(milliseconds: 100));

    final newPinValue = getNewPinValue();
    final confirmPinValue = getConfirmPinValue();

    if (newPinValue.length != 4) {
      _showErrorMessage('Please enter new PIN');
      isLoading.value = false;
      return;
    }

    if (confirmPinValue.length != 4) {
      _showErrorMessage('Please enter confirmation PIN');
      isLoading.value = false;
      return;
    }

    if (newPinValue != confirmPinValue) {
      _showErrorMessage(
          'New PIN and confirmation PIN do not match. Please try again.');
      _clearConfirmPin();
      Future.delayed(const Duration(milliseconds: 300), () {
        if (confirmPinFocusNodes.isNotEmpty) {
          confirmPinFocusNodes[0].requestFocus();
        }
      });
      isLoading.value = false;
      return;
    }

    String currentPinValue = '';

    if (!isSetMode.value) {
      currentPinValue = getCurrentPinValue();
      if (currentPinValue.length != 4) {
        _showErrorMessage('Please enter current PIN');
        isLoading.value = false;
        return;
      }

      if (storedMPin.isEmpty) {
        _showErrorMessage('Unable to verify PIN. Please try again.');
        isLoading.value = false;
        return;
      }

      if (currentPinValue != storedMPin) {
        _showErrorMessage('Current PIN is incorrect.');
        isLoading.value = false;
        return;
      }

      if (newPinValue == currentPinValue) {
        _showErrorMessage('New PIN must be different from current PIN');
        isLoading.value = false;
        return;
      }
    }

    try {
      ShowToastDialog.showLoader(
          isSetMode.value ? "Setting PIN..." : "Changing PIN...");

      Map<String, String> bodyParams = {
        'ac_no': "${Constant.getUserData().data?.acNo}",
        'opass': isSetMode.value ? '' : currentPinValue,
        'npass': newPinValue,
        'cpass': confirmPinValue
      };

      final response = await http.post(Uri.parse(API.userSetMPin),
          headers: API.header, body: jsonEncode(bodyParams));

      showLog("${isSetMode.value ? 'SET' : 'CHANGE'} MPIN => API :: URL :: ${API.userSetMPin}");
      showLog("${isSetMode.value ? 'SET' : 'CHANGE'} MPIN => API :: Request Body :: ${jsonEncode(bodyParams)}");
      showLog("${isSetMode.value ? 'SET' : 'CHANGE'} MPIN => API :: Response Status :: ${response.statusCode}");
      showLog("${isSetMode.value ? 'SET' : 'CHANGE'} MPIN => API :: Response Body :: ${response.body}");

      Map<String, dynamic> responseBody = json.decode(response.body);

      ShowToastDialog.closeLoader();

      if (response.statusCode == 200 && responseBody['res'] == "success") {
        if (isSetMode.value) {
          hasMPinSet.value = true;
        }

        final value = UserModel.fromJson(responseBody['data']);

        Preferences.setInt(Preferences.userId, int.parse(value.data!.id.toString()));
        Preferences.setString(Preferences.user, jsonEncode(value));
        Preferences.setString(Preferences.accesstoken, value.data!.accesstoken.toString());
        Preferences.setString(Preferences.admincommission, value.data!.adminCommission.toString());
        API.header['accesstoken'] = Preferences.getString(Preferences.accesstoken);

        _showSuccessDialog();
      } else {
        String errorMsg = responseBody['error'] ??
            'Failed to ${isSetMode.value ? 'set' : 'change'} M-PIN. Please try again.';
        _showErrorMessage(errorMsg);
      }
    } on TimeoutException {
      ShowToastDialog.closeLoader();
      _showErrorMessage('Request timeout. Please check your internet connection.');
    } on SocketException {
      ShowToastDialog.closeLoader();
      _showErrorMessage('Network error. Please check your internet connection.');
    } on FormatException {
      ShowToastDialog.closeLoader();
      _showErrorMessage('Invalid response from server.');
    } catch (e) {
      ShowToastDialog.closeLoader();
      _showErrorMessage('An unexpected error occurred. Please try again.');
      showLog("${isSetMode.value ? 'SET' : 'CHANGE'} MPIN => Exception :: $e");
    } finally {
      isLoading.value = false;
    }
  }

  void _showSuccessDialog() {
    Get.dialog(
        AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            contentPadding: const EdgeInsets.all(24),
            content: Column(mainAxisSize: MainAxisSize.min, children: [
              Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                      color: Colors.green.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                      border: Border.all(
                          color: Colors.green.withValues(alpha: 0.3), width: 2)),
                  child: const Icon(Icons.check_circle_outline,
                      size: 40, color: Colors.green)),
              const SizedBox(height: 20),
              Text(
                  isSetMode.value
                      ? 'M-PIN Set Successfully!'
                      : 'M-PIN Changed Successfully!',
                  style: const TextStyle(
                      fontSize: 20, fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center),
              const SizedBox(height: 12),
              Text(
                  isSetMode.value
                      ? 'Your M-PIN has been set successfully. You can now use your PIN for transactions.'
                      : 'Your M-PIN has been changed successfully. You can now use your new PIN for transactions.',
                  style: const TextStyle(
                      fontSize: 14, color: Colors.grey, height: 1.4),
                  textAlign: TextAlign.center),
              const SizedBox(height: 24),
              SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton(
                      onPressed: () {
                        Get.back();
                        Get.back();
                      },
                      style: ElevatedButton.styleFrom(
                          backgroundColor: AppThemeData.primary200,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12))),
                      child: const Text('OK',
                          style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: Colors.white))))
            ])),
        barrierDismissible: false);
  }

  void _clearCurrentPin() {
    for (var controller in currentPinControllers) {
      controller.clear();
    }
    currentPinInput.value = '';
    update();
  }

  void _clearNewPin() {
    for (var controller in newPinControllers) {
      controller.clear();
    }
    newPin.value = '';
    update();
  }

  void _clearConfirmPin() {
    for (var controller in confirmPinControllers) {
      controller.clear();
    }
    confirmPin.value = '';
    update();
  }

  void resetPin() {
    HapticFeedback.mediumImpact();
    _clearCurrentPin();
    _clearNewPin();
    _clearConfirmPin();

    if (isSetMode.value) {
      currentStep.value = 1;
      Future.delayed(const Duration(milliseconds: 300), () {
        if (newPinFocusNodes.isNotEmpty) {
          newPinFocusNodes[0].requestFocus();
        }
      });
    } else {
      currentStep.value = 0;
      Future.delayed(const Duration(milliseconds: 300), () {
        if (currentPinFocusNodes.isNotEmpty) {
          currentPinFocusNodes[0].requestFocus();
        }
      });
    }
  }

  void goBack() {
    HapticFeedback.lightImpact();
    Get.back();
  }

  void _showErrorMessage(String message) {
    Get.snackbar('Error', message,
        backgroundColor: Colors.red.withValues(alpha: 0.9),
        colorText: Colors.white,
        snackPosition: SnackPosition.BOTTOM,
        duration: const Duration(seconds: 3),
        margin: const EdgeInsets.all(16),
        borderRadius: 12,
        icon: const Icon(Icons.error, color: Colors.white));
  }

  @override
  void onClose() {
    animationController.dispose();

    for (var node in currentPinFocusNodes) {
      node.dispose();
    }
    for (var node in newPinFocusNodes) {
      node.dispose();
    }
    for (var node in confirmPinFocusNodes) {
      node.dispose();
    }

    for (var controller in currentPinControllers) {
      controller.dispose();
    }
    for (var controller in newPinControllers) {
      controller.dispose();
    }
    for (var controller in confirmPinControllers) {
      controller.dispose();
    }

    super.onClose();
  }
}
// import 'package:finway/constant/constant.dart';
// import 'package:flutter/material.dart';
// import 'package:flutter/services.dart';
// import 'package:get/get.dart';
//
// import '../../../../../themes/constant_colors.dart';
//
// class MPinChangeController extends GetxController
//     with GetSingleTickerProviderStateMixin {
//   // Animation Controller
//   late AnimationController animationController;
//   late Animation<double> fadeAnimation;
//   late Animation<double> slideAnimation;
//
//   // PIN related observables
//   var currentPin = ''.obs;
//   var newPin = ''.obs;
//   var confirmPin = ''.obs;
//   var currentStep = 0.obs; // 0: current PIN, 1: new PIN, 2: confirm PIN
//   var isLoading = false.obs;
//   var isCurrentPinVisible = false.obs;
//   var isNewPinVisible = false.obs;
//   var isConfirmPinVisible = false.obs;
//
//   // Focus nodes for each step
//   late List<FocusNode> currentPinFocusNodes;
//   late List<FocusNode> newPinFocusNodes;
//   late List<FocusNode> confirmPinFocusNodes;
//
//   // Text controllers for each step
//   late List<TextEditingController> currentPinControllers;
//   late List<TextEditingController> newPinControllers;
//   late List<TextEditingController> confirmPinControllers;
//
//   @override
//   void onInit() {
//     super.onInit();
//     currentPin.value = Constant.getUserData().data!.mPin ?? '' ;
//     _initializeAnimations();
//     _initializeControllers();
//     _startAnimations();
//   }
//
//   void _initializeAnimations() {
//     animationController = AnimationController(
//       duration: const Duration(milliseconds: 1000),
//       vsync: this,
//     );
//
//     fadeAnimation = CurvedAnimation(
//       parent: animationController,
//       curve: Curves.easeOut,
//     );
//
//     slideAnimation = CurvedAnimation(
//       parent: animationController,
//       curve: Curves.elasticOut,
//     );
//   }
//
//   void _initializeControllers() {
//     // Initialize focus nodes and controllers for all PIN inputs
//     currentPinFocusNodes = List.generate(4, (index) => FocusNode());
//     newPinFocusNodes = List.generate(4, (index) => FocusNode());
//     confirmPinFocusNodes = List.generate(4, (index) => FocusNode());
//
//     currentPinControllers =
//         List.generate(4, (index) => TextEditingController());
//     newPinControllers = List.generate(4, (index) => TextEditingController());
//     confirmPinControllers =
//         List.generate(4, (index) => TextEditingController());
//
//     // Add listeners to controllers
//     for (int i = 0; i < 4; i++) {
//       currentPinControllers[i].addListener(() => _updateCurrentPin());
//       newPinControllers[i].addListener(() => _updateNewPin());
//       confirmPinControllers[i].addListener(() => _updateConfirmPin());
//     }
//   }
//
//   void _startAnimations() {
//     animationController.forward();
//   }
//
//   void _updateCurrentPin() {
//     currentPin.value = currentPinControllers.map((c) => c.text).join();
//   }
//
//   void _updateNewPin() {
//     newPin.value = newPinControllers.map((c) => c.text).join();
//   }
//
//   void _updateConfirmPin() {
//     confirmPin.value = confirmPinControllers.map((c) => c.text).join();
//   }
//
//   // Handle PIN input with proper backspace and navigation
//   void onPinChanged(String value, int index, int step) {
//     late List<TextEditingController> controllers;
//     late List<FocusNode> focusNodes;
//
//     switch (step) {
//       case 0:
//         controllers = currentPinControllers;
//         focusNodes = currentPinFocusNodes;
//         break;
//       case 1:
//         controllers = newPinControllers;
//         focusNodes = newPinFocusNodes;
//         break;
//       case 2:
//         controllers = confirmPinControllers;
//         focusNodes = confirmPinFocusNodes;
//         break;
//     }
//
//     if (value.isEmpty) {
//       // Handle backspace - move to previous field if current is empty
//       if (index > 0) {
//         HapticFeedback.lightImpact();
//         focusNodes[index - 1].requestFocus();
//       }
//     } else {
//       // Handle character input
//       if (value.length > 1) {
//         // If more than one character, take only the last one
//         controllers[index].text = value.substring(value.length - 1);
//         controllers[index].selection = TextSelection.fromPosition(
//           TextPosition(offset: 1),
//         );
//       }
//
//       HapticFeedback.lightImpact();
//
//       // Move to next field if not the last one
//       if (index < 3 && value.isNotEmpty) {
//         focusNodes[index + 1].requestFocus();
//       } else if (index == 3) {
//         // Last field, remove focus
//         focusNodes[index].unfocus();
//       }
//     }
//   }
//
//   // Handle backspace key specifically
//   bool onKeyPressed(RawKeyEvent event, int index, int step) {
//     if (event is RawKeyDownEvent &&
//         event.logicalKey == LogicalKeyboardKey.backspace) {
//       late List<TextEditingController> controllers;
//       late List<FocusNode> focusNodes;
//
//       switch (step) {
//         case 0:
//           controllers = currentPinControllers;
//           focusNodes = currentPinFocusNodes;
//           break;
//         case 1:
//           controllers = newPinControllers;
//           focusNodes = newPinFocusNodes;
//           break;
//         case 2:
//           controllers = confirmPinControllers;
//           focusNodes = confirmPinFocusNodes;
//           break;
//       }
//
//       if (controllers[index].text.isEmpty && index > 0) {
//         // If current field is empty and backspace is pressed, go to previous field
//         HapticFeedback.lightImpact();
//         focusNodes[index - 1].requestFocus();
//         controllers[index - 1].clear();
//         return true; // Consume the event
//       }
//     }
//     return false; // Don't consume the event
//   }
//
//   // Get PIN values
//   String getCurrentPinValue() {
//     return currentPinControllers.map((c) => c.text).join();
//   }
//
//   String getNewPinValue() {
//     return newPinControllers.map((c) => c.text).join();
//   }
//
//   String getConfirmPinValue() {
//     return confirmPinControllers.map((c) => c.text).join();
//   }
//
//   // Toggle PIN visibility
//   void toggleCurrentPinVisibility() {
//     HapticFeedback.lightImpact();
//     isCurrentPinVisible.value = !isCurrentPinVisible.value;
//   }
//
//   void toggleNewPinVisibility() {
//     HapticFeedback.lightImpact();
//     isNewPinVisible.value = !isNewPinVisible.value;
//   }
//
//   void toggleConfirmPinVisibility() {
//     HapticFeedback.lightImpact();
//     isConfirmPinVisible.value = !isConfirmPinVisible.value;
//   }
//
//   // Step navigation
//   void proceedToNextStep() async {
//     isLoading.value = true;
//     await Future.delayed(const Duration(milliseconds: 100));
//
//     if (currentStep.value == 0) {
//       final currentPinValue = getCurrentPinValue();
//       if (currentPinValue.length != 4) {
//         _showErrorMessage('Please enter your current 4-digit PIN');
//         isLoading.value = false;
//         return;
//       }
//       // TODO: Here, you should verify the current PIN with your API
//       // For now, we assume it's correct and proceed
//       HapticFeedback.mediumImpact();
//       currentStep.value = 1; // <-- Move to next step
//       // Focus on first new PIN field after animation
//       Future.delayed(const Duration(milliseconds: 300), () {
//         if (newPinFocusNodes.isNotEmpty) {
//           newPinFocusNodes[0].requestFocus();
//         }
//       });
//     } else if (currentStep.value == 1) {
//       final newPinValue = getNewPinValue();
//       if (newPinValue.length != 4) {
//         _showErrorMessage('Please enter a 4-digit new PIN');
//         isLoading.value = false;
//         return;
//       }
//       // Check if new PIN is different from current PIN
//       final currentPinValue = getCurrentPinValue();
//       if (newPinValue == currentPinValue) {
//         _showErrorMessage('New PIN must be different from current PIN');
//         isLoading.value = false;
//         return;
//       }
//       HapticFeedback.mediumImpact();
//       currentStep.value = 2; // <-- Move to next step
//       // Focus on first confirm PIN field after animation
//       Future.delayed(const Duration(milliseconds: 300), () {
//         if (confirmPinFocusNodes.isNotEmpty) {
//           confirmPinFocusNodes[0].requestFocus();
//         }
//       });
//     }
//     isLoading.value = false;
//   }
//
//   // Go back to previous step
//   void goBackToPreviousStep() {
//     HapticFeedback.lightImpact();
//     if (currentStep.value > 0) {
//       currentStep.value--;
//
//       // Clear fields of the step we're going back from
//       if (currentStep.value == 0) {
//         _clearNewPin();
//         _clearConfirmPin();
//         Future.delayed(const Duration(milliseconds: 300), () {
//           if (currentPinFocusNodes.isNotEmpty) {
//             currentPinFocusNodes[0].requestFocus();
//           }
//         });
//       } else if (currentStep.value == 1) {
//         _clearConfirmPin();
//         Future.delayed(const Duration(milliseconds: 300), () {
//           if (newPinFocusNodes.isNotEmpty) {
//             newPinFocusNodes[0].requestFocus();
//           }
//         });
//       }
//     }
//   }
//
//   // Change M-PIN
//   Future<void> changeMPin() async {
//     isLoading.value = true; // Loading start immediately
//     await Future.delayed(
//         Duration(milliseconds: 100)); // Optional: UI update ke liye thoda delay
//
//     final newPinValue = getNewPinValue();
//     final confirmPinValue = getConfirmPinValue();
//
//     if (confirmPinValue.length != 4) {
//       _showErrorMessage('Please enter confirmation PIN');
//       isLoading.value = false;
//       return;
//     }
//
//     if (newPinValue != confirmPinValue) {
//       _showErrorMessage(
//           'New PIN and confirmation PIN do not match. Please try again.');
//       _clearConfirmPin();
//       Future.delayed(const Duration(milliseconds: 300), () {
//         if (confirmPinFocusNodes.isNotEmpty) {
//           confirmPinFocusNodes[0].requestFocus();
//         }
//       });
//       isLoading.value = false;
//       return;
//     }
//
//     try {
//       // Simulate API call
//       await Future.delayed(const Duration(seconds: 2));
//       _showSuccessDialog();
//     } catch (e) {
//       _showErrorMessage('Failed to change M-PIN. Please try again.');
//     } finally {
//       isLoading.value = false;
//     }
//   }
//
//   // Show success dialog
//   void _showSuccessDialog() {
//     Get.dialog(
//       AlertDialog(
//         shape: RoundedRectangleBorder(
//           borderRadius: BorderRadius.circular(16),
//         ),
//         contentPadding: const EdgeInsets.all(24),
//         content: Column(
//           mainAxisSize: MainAxisSize.min,
//           children: [
//             // Success Icon
//             Container(
//               width: 80,
//               height: 80,
//               decoration: BoxDecoration(
//                 color: Colors.green.withOpacity(0.1),
//                 shape: BoxShape.circle,
//                 border: Border.all(
//                   color: Colors.green.withOpacity(0.3),
//                   width: 2,
//                 ),
//               ),
//               child: const Icon(
//                 Icons.check_circle_outline,
//                 size: 40,
//                 color: Colors.green,
//               ),
//             ),
//
//             const SizedBox(height: 20),
//
//             // Success Title
//             const Text(
//               'PIN Changed Successfully!',
//               style: TextStyle(
//                 fontSize: 20,
//                 fontWeight: FontWeight.bold,
//               ),
//               textAlign: TextAlign.center,
//             ),
//
//             const SizedBox(height: 12),
//
//             // Success Message
//             const Text(
//               'Your M-PIN has been changed successfully. You can now use your new PIN for transactions.',
//               style: TextStyle(
//                 fontSize: 14,
//                 color: Colors.grey,
//                 height: 1.4,
//               ),
//               textAlign: TextAlign.center,
//             ),
//
//             const SizedBox(height: 24),
//
//             // OK Button
//             SizedBox(
//               width: double.infinity,
//               height: 48,
//               child: ElevatedButton(
//                 onPressed: () {
//                   Get.back(); // Close dialog
//                   Get.back(); // Go back to dashboard
//                 },
//                 style: ElevatedButton.styleFrom(
//                   backgroundColor: AppThemeData.primary200,
//                   shape: RoundedRectangleBorder(
//                     borderRadius: BorderRadius.circular(12),
//                   ),
//                 ),
//                 child: const Text(
//                   'OK',
//                   style: TextStyle(
//                     fontSize: 16,
//                     fontWeight: FontWeight.w600,
//                     color: Colors.white,
//                   ),
//                 ),
//               ),
//             ),
//           ],
//         ),
//       ),
//       barrierDismissible: false,
//     );
//   }
//
//   // Clear PIN inputs
//   void _clearCurrentPin() {
//     for (var controller in currentPinControllers) {
//       controller.clear();
//     }
//     currentPin.value = '';
//   }
//
//   void _clearNewPin() {
//     for (var controller in newPinControllers) {
//       controller.clear();
//     }
//     newPin.value = '';
//   }
//
//   void _clearConfirmPin() {
//     for (var controller in confirmPinControllers) {
//       controller.clear();
//     }
//     confirmPin.value = '';
//   }
//
//   // Reset everything
//   void resetPin() {
//     HapticFeedback.mediumImpact();
//     _clearCurrentPin();
//     _clearNewPin();
//     _clearConfirmPin();
//     currentStep.value = 0;
//
//     // Focus on first current PIN field
//     Future.delayed(const Duration(milliseconds: 300), () {
//       if (currentPinFocusNodes.isNotEmpty) {
//         currentPinFocusNodes[0].requestFocus();
//       }
//     });
//   }
//
//   // Navigate back
//   void goBack() {
//     HapticFeedback.lightImpact();
//     Get.back();
//   }
//
//   // Show error message
//   void _showErrorMessage(String message) {
//     Get.snackbar(
//       'Error',
//       message,
//       backgroundColor: Colors.red.withOpacity(0.9),
//       colorText: Colors.white,
//       snackPosition: SnackPosition.BOTTOM,
//       duration: const Duration(seconds: 3),
//       margin: const EdgeInsets.all(16),
//       borderRadius: 12,
//       icon: const Icon(Icons.error, color: Colors.white),
//     );
//   }
//
//   @override
//   void onClose() {
//     animationController.dispose();
//
//     // Dispose focus nodes
//     for (var node in currentPinFocusNodes) {
//       node.dispose();
//     }
//     for (var node in newPinFocusNodes) {
//       node.dispose();
//     }
//     for (var node in confirmPinFocusNodes) {
//       node.dispose();
//     }
//
//     // Dispose controllers
//     for (var controller in currentPinControllers) {
//       controller.dispose();
//     }
//     for (var controller in newPinControllers) {
//       controller.dispose();
//     }
//     for (var controller in confirmPinControllers) {
//       controller.dispose();
//     }
//
//     super.onClose();
//   }
// }
