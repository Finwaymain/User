import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:finway/constant/show_toast_dialog.dart';
import 'package:finway/model/user_model.dart';
import 'package:finway/service/api.dart';
import 'package:finway/utils/Preferences.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;

class AuthOtpController extends GetxController {
  // ── Shared state ────────────────────────────────────────────────────────────
  final phoneController = TextEditingController().obs;
  final phoneOtpController = TextEditingController().obs;
  final emailController = TextEditingController().obs;
  final emailOtpController = TextEditingController().obs;
  final firstNameController = TextEditingController().obs;
  final lastNameController = TextEditingController().obs;

  var phone = ''.obs;
  var emailHint = ''.obs; // masked email shown during login OTP step
  var isLoading = false.obs;

  // Resend timer
  var resendSeconds = 60.obs;
  var canResend = false.obs;
  Timer? _resendTimer;

  @override
  void onClose() {
    _resendTimer?.cancel();
    phoneController.value.dispose();
    phoneOtpController.value.dispose();
    emailController.value.dispose();
    emailOtpController.value.dispose();
    firstNameController.value.dispose();
    lastNameController.value.dispose();
    super.onClose();
  }

  void startResendTimer() {
    resendSeconds.value = 60;
    canResend.value = false;
    _resendTimer?.cancel();
    _resendTimer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (resendSeconds.value > 0) {
        resendSeconds.value--;
      } else {
        canResend.value = true;
        t.cancel();
      }
    });
  }

  // ── SIGNUP: Step 1 — Send phone OTP ─────────────────────────────────────────
  // TODO: dummy OTP 1234 used on backend for phone verification.
  //       Replace with real SMS gateway (Fast2SMS/Msg91) before production launch.
  Future<bool> sendPhoneOtp(String phoneNumber, {String mode = 'signup'}) async {
    try {
      isLoading.value = true;
      final body = jsonEncode({
        'phone': phoneNumber,
        'user_cat': 'customer',
        'mode': mode,
      });
      final res = await http.post(Uri.parse(API.authSendPhoneOtp), headers: API.authheader, body: body);
      final data = json.decode(res.body);
      isLoading.value = false;

      if (res.statusCode == 200 && data['success'] == 'success') {
        phone.value = phoneNumber;
        startResendTimer();
        return true;
      } else {
        ShowToastDialog.showToast(data['error'] ?? 'Failed to send OTP');
        return false;
      }
    } on SocketException {
      isLoading.value = false;
      ShowToastDialog.showToast('No internet connection');
      return false;
    } catch (e) {
      isLoading.value = false;
      ShowToastDialog.showToast(e.toString());
      return false;
    }
  }

  // ── SIGNUP: Step 2 — Verify phone OTP ───────────────────────────────────────
  Future<bool> verifyPhoneOtp(String otp) async {
    try {
      isLoading.value = true;
      final body = jsonEncode({
        'phone': phone.value,
        'otp': otp,
        'user_cat': 'customer',
      });
      final res = await http.post(Uri.parse(API.authVerifyPhoneOtp), headers: API.authheader, body: body);
      final data = json.decode(res.body);
      isLoading.value = false;

      if (res.statusCode == 200 && data['success'] == 'success') {
        return true;
      } else {
        ShowToastDialog.showToast(data['error'] ?? 'Invalid OTP');
        return false;
      }
    } on SocketException {
      isLoading.value = false;
      ShowToastDialog.showToast('No internet connection');
      return false;
    } catch (e) {
      isLoading.value = false;
      ShowToastDialog.showToast(e.toString());
      return false;
    }
  }

  // ── SIGNUP: Step 4 — Send email OTP ─────────────────────────────────────────
  Future<bool> sendEmailOtp(String email) async {
    try {
      isLoading.value = true;
      final body = jsonEncode({
        'phone': phone.value,
        'email': email,
        'user_cat': 'customer',
      });
      final res = await http.post(Uri.parse(API.authSendEmailOtp), headers: API.authheader, body: body);
      final data = json.decode(res.body);
      isLoading.value = false;

      if (res.statusCode == 200 && data['success'] == 'success') {
        startResendTimer();
        return true;
      } else {
        ShowToastDialog.showToast(data['error'] ?? 'Failed to send email OTP');
        return false;
      }
    } on SocketException {
      isLoading.value = false;
      ShowToastDialog.showToast('No internet connection');
      return false;
    } catch (e) {
      isLoading.value = false;
      ShowToastDialog.showToast(e.toString());
      return false;
    }
  }

  // ── SIGNUP: Step 5 — Verify email OTP + create account ──────────────────────
  Future<UserModel?> verifyEmailAndRegister({
    required String email,
    required String otp,
    required String firstName,
    required String lastName,
    String referralCode = '',
  }) async {
    try {
      isLoading.value = true;
      final body = jsonEncode({
        'phone': phone.value,
        'email': email,
        'otp': otp,
        'firstname': firstName,
        'lastname': lastName,
        'user_cat': 'customer',
        'referral_code': referralCode,
      });
      final res = await http.post(Uri.parse(API.authVerifyEmailRegister), headers: API.authheader, body: body);
      final data = json.decode(res.body);
      isLoading.value = false;

      if (res.statusCode == 200 && data['success'] == 'success') {
        return await _saveAndReturnUser(data);
      } else {
        ShowToastDialog.showToast(data['error'] ?? 'Registration failed');
        return null;
      }
    } on SocketException {
      isLoading.value = false;
      ShowToastDialog.showToast('No internet connection');
      return null;
    } catch (e) {
      isLoading.value = false;
      ShowToastDialog.showToast(e.toString());
      return null;
    }
  }

  // ── LOGIN: Step 1 — Find user by phone, send email OTP ──────────────────────
  Future<bool> loginByPhone(String phoneNumber) async {
    try {
      isLoading.value = true;
      final body = jsonEncode({
        'phone': phoneNumber,
        'user_cat': 'customer',
      });
      final res = await http.post(Uri.parse(API.authLoginByPhone), headers: API.authheader, body: body);
      final data = json.decode(res.body);
      isLoading.value = false;

      if (res.statusCode == 200 && data['success'] == 'success') {
        phone.value = phoneNumber;
        emailHint.value = data['email_hint'] ?? '';
        startResendTimer();
        return true;
      } else {
        ShowToastDialog.showToast(data['error'] ?? 'Phone number not found');
        return false;
      }
    } on SocketException {
      isLoading.value = false;
      ShowToastDialog.showToast('No internet connection');
      return false;
    } catch (e) {
      isLoading.value = false;
      ShowToastDialog.showToast(e.toString());
      return false;
    }
  }

  // ── LOGIN: Step 2 — Verify login email OTP ──────────────────────────────────
  Future<UserModel?> verifyLoginEmailOtp(String otp) async {
    try {
      isLoading.value = true;
      final body = jsonEncode({
        'phone': phone.value,
        'otp': otp,
        'user_cat': 'customer',
      });
      final res = await http.post(Uri.parse(API.authVerifyLoginEmailOtp), headers: API.authheader, body: body);
      final data = json.decode(res.body);
      isLoading.value = false;

      if (res.statusCode == 200 && data['success'] == 'Success') {
        return await _saveAndReturnUser(data);
      } else {
        ShowToastDialog.showToast(data['error'] ?? 'Invalid OTP');
        return null;
      }
    } on SocketException {
      isLoading.value = false;
      ShowToastDialog.showToast('No internet connection');
      return null;
    } catch (e) {
      isLoading.value = false;
      ShowToastDialog.showToast(e.toString());
      return null;
    }
  }

  // ── Shared helper: persist session ──────────────────────────────────────────
  Future<UserModel> _saveAndReturnUser(Map<String, dynamic> responseBody) async {
    final model = UserModel.fromJson(responseBody);
    if (model.data != null) {
      await Preferences.setInt(Preferences.userId, int.parse(model.data!.id.toString()));
      await Preferences.setString(Preferences.user, jsonEncode(responseBody));
      await Preferences.setString(Preferences.accesstoken, model.data!.accesstoken.toString());
      await Preferences.setString(Preferences.admincommission, (model.data!.adminCommission ?? '0').toString());
      API.header['accesstoken'] = model.data!.accesstoken.toString();
      await Preferences.setBoolean(Preferences.isLogin, true);
    }
    return model;
  }
}
