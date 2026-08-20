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
  final referralCodeController = TextEditingController().obs;

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
    referralCodeController.value.dispose();
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

  // ── Check if user exists by phone ──────────────────────────────────────────
  Future<bool?> checkUserExists(String phoneNumber, {String userCat = 'customer'}) async {
    try {
      isLoading.value = true;
      final body = jsonEncode({
        'phone': phoneNumber,
        'user_cat': userCat,
      });
      final res = await http.post(Uri.parse(API.authCheckUser), headers: API.authheader, body: body);
      final data = json.decode(res.body);
      isLoading.value = false;

      if (res.statusCode == 200 && data['success'] == 'success') {
        return data['exists'] == true;
      } else {
        ShowToastDialog.showToast(data['error'] ?? 'Check user failed');
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

  // ── Login by MPIN ──────────────────────────────────────────────────────────
  Future<UserModel?> loginByMpin(String phoneNumber, String mpin, {String userCat = 'customer'}) async {
    try {
      isLoading.value = true;
      final body = jsonEncode({
        'phone': phoneNumber,
        'mpin': mpin,
        'user_cat': userCat,
      });
      final res = await http.post(Uri.parse(API.authLoginByMpin), headers: API.authheader, body: body);
      final data = json.decode(res.body);
      isLoading.value = false;

      if (res.statusCode == 200 && data['success'] == 'success') {
        return await _saveAndReturnUser(data);
      } else {
        ShowToastDialog.showToast(data['error'] ?? 'Incorrect MPIN');
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

  // ── Reset MPIN ─────────────────────────────────────────────────────────────
  Future<bool> resetMpin(String phoneNumber, String otp, String mpin, {String userCat = 'customer'}) async {
    try {
      isLoading.value = true;
      final body = jsonEncode({
        'phone': phoneNumber,
        'otp': otp,
        'mpin': mpin,
        'user_cat': userCat,
      });
      final res = await http.post(Uri.parse(API.authResetMpin), headers: API.authheader, body: body);
      final data = json.decode(res.body);
      isLoading.value = false;

      if (res.statusCode == 200 && data['success'] == 'success') {
        ShowToastDialog.showToast(data['message'] ?? 'MPIN reset successfully.');
        return true;
      } else {
        ShowToastDialog.showToast(data['error'] ?? 'Failed to reset MPIN');
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

  // ── Register Simple (Name + OTP + MPIN) ────────────────────────────────────
  Future<UserModel?> registerSimple({
    required String phoneNumber,
    required String otp,
    required String mpin,
    required String firstName,
    String lastName = '',
    String userCat = 'customer',
    String referralCode = '',
  }) async {
    try {
      isLoading.value = true;
      final body = jsonEncode({
        'phone': phoneNumber,
        'otp': otp,
        'mpin': mpin,
        'firstname': firstName,
        'lastname': lastName,
        'user_cat': userCat,
        'referral_code': referralCode,
      });
      final res = await http.post(Uri.parse(API.authRegisterSimple), headers: API.authheader, body: body);
      Map<String, dynamic> data = {};
      try {
        data = json.decode(res.body);
      } catch (_) {
        if (res.statusCode == 200) {
          data = {'success': 'success'};
        }
      }
      isLoading.value = false;

      if (res.statusCode == 200 && (data['success'] == 'success' || data['success'] == true || data['data'] != null)) {
        return await _saveAndReturnUser(data);
      } else {
        ShowToastDialog.showToast(data['error'] ?? data['message'] ?? 'Registration failed');
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

  // ── Apply Referral Code from Profile (post-registration) ───────────────────
  Future<bool> applyReferralCode(String userId, String referralCode, {String userCat = 'customer'}) async {
    try {
      isLoading.value = true;
      final body = jsonEncode({
        'user_id': userId,
        'referral_code': referralCode.trim(),
        'user_cat': userCat,
      });
      final res = await http.post(Uri.parse(API.authApplyReferral), headers: API.authheader, body: body);
      final data = json.decode(res.body);
      isLoading.value = false;

      if (res.statusCode == 200 && (data['success'] == 'success' || data['success'] == true)) {
        ShowToastDialog.showToast(data['message'] ?? 'Referral code applied!');
        return true;
      } else {
        ShowToastDialog.showToast(data['error'] ?? 'Failed to apply referral code');
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

  // ── Shared helper: persist session ──────────────────────────────────────────
  Future<UserModel> _saveAndReturnUser(Map<String, dynamic> responseBody) async {
    final model = UserModel.fromJson(responseBody);
    if (model.data != null || responseBody['data'] != null) {
      final dataMap = responseBody['data'] is Map<String, dynamic> ? responseBody['data'] : {};
      final String idStr = (model.data?.id ?? dataMap['id'] ?? '').toString();
      final String tokenStr = (model.data?.accesstoken ?? dataMap['accesstoken'] ?? '').toString();

      if (idStr.isNotEmpty) {
        await Preferences.setInt(Preferences.userId, int.tryParse(idStr) ?? 0);
        await Preferences.setString(Preferences.userId, idStr);
      }
      await Preferences.setString(Preferences.user, jsonEncode(responseBody));
      if (tokenStr.isNotEmpty) {
        await Preferences.setString(Preferences.accesstoken, tokenStr);
        API.header['accesstoken'] = tokenStr;
      }
      await Preferences.setBoolean(Preferences.isLogin, true);
    }
    return model;
  }
}
