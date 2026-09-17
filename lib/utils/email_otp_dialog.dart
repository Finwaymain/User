import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:finway/constant/constant.dart';
import 'package:finway/constant/show_toast_dialog.dart';
import 'package:finway/service/api.dart';
import 'package:finway/themes/constant_colors.dart';
import 'package:finway/utils/Preferences.dart';

Future<bool> showPlanEmailOtpDialog(
  BuildContext context, {
  required String currentEmail,
  required String userId,
  String userCat = 'customer',
  bool isDarkMode = false,
}) async {
  final emailController = TextEditingController(text: currentEmail);
  final otpController = TextEditingController();
  bool otpSent = false;
  bool isSendingOtp = false;
  bool isVerifyingOtp = false;
  String? errorMsg;

  final result = await showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    backgroundColor: isDarkMode ? const Color(0xFF1E293B) : Colors.white,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.only(
        topLeft: Radius.circular(24),
        topRight: Radius.circular(24),
      ),
    ),
    builder: (ctx) {
      return StatefulBuilder(
        builder: (context, setSheetState) {
          final bottomInset = MediaQuery.of(context).viewInsets.bottom;

          Future<void> sendOtp() async {
            final email = emailController.text.trim();
            if (email.isEmpty || !RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(email)) {
              setSheetState(() => errorMsg = 'Please enter a valid email address');
              return;
            }

            setSheetState(() {
              isSendingOtp = true;
              errorMsg = null;
            });

            try {
              final response = await http.post(
                Uri.parse(API.sendPlanEmailOtp),
                headers: API.header,
                body: jsonEncode({
                  'email': email,
                  'user_id': userId,
                  'user_cat': userCat,
                }),
              ).timeout(const Duration(seconds: 15));

              final data = jsonDecode(response.body);
              if (response.statusCode == 200 && (data['success'] == 'success' || data['success'] == true)) {
                setSheetState(() {
                  otpSent = true;
                  isSendingOtp = false;
                  errorMsg = null;
                });
                ShowToastDialog.showToast(data['message'] ?? 'OTP sent to $email');
              } else {
                setSheetState(() {
                  isSendingOtp = false;
                  errorMsg = data['error'] ?? data['message'] ?? 'Failed to send OTP';
                });
              }
            } catch (e) {
              setSheetState(() {
                isSendingOtp = false;
                errorMsg = 'Network error. Please try again.';
              });
            }
          }

          Future<void> verifyOtp() async {
            final email = emailController.text.trim();
            final otp = otpController.text.trim();

            if (otp.length < 6) {
              setSheetState(() => errorMsg = 'Please enter complete 6-digit OTP');
              return;
            }

            setSheetState(() {
              isVerifyingOtp = true;
              errorMsg = null;
            });

            try {
              final response = await http.post(
                Uri.parse(API.verifyPlanEmailOtp),
                headers: API.header,
                body: jsonEncode({
                  'email': email,
                  'otp': otp,
                  'user_id': userId,
                  'user_cat': userCat,
                }),
              ).timeout(const Duration(seconds: 15));

              final data = jsonDecode(response.body);
              if (response.statusCode == 200 && (data['success'] == 'success' || data['success'] == true)) {
                final userModel = Constant.getUserData();
                if (userModel.data != null) {
                  userModel.data!.email = email;
                  userModel.data!.emailVerifiedAt = DateTime.now().toIso8601String();
                  await Preferences.setString(Preferences.user, jsonEncode(userModel));
                }
                ShowToastDialog.showToast('Email verified successfully!');
                if (context.mounted) {
                  Navigator.of(context).pop(true);
                }
              } else {
                setSheetState(() {
                  isVerifyingOtp = false;
                  errorMsg = data['error'] ?? data['message'] ?? 'Invalid or expired OTP';
                });
              }
            } catch (e) {
              setSheetState(() {
                isVerifyingOtp = false;
                errorMsg = 'Verification failed. Please try again.';
              });
            }
          }

          return Padding(
            padding: EdgeInsets.only(
              left: 20,
              right: 20,
              top: 20,
              bottom: bottomInset + 20,
            ),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Container(
                    width: 44,
                    height: 5,
                    decoration: BoxDecoration(
                      color: isDarkMode ? Colors.white24 : Colors.black12,
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  const SizedBox(height: 18),
                  Container(
                    width: 58,
                    height: 58,
                    decoration: BoxDecoration(
                      color: AppThemeData.primary200.withOpacity(0.12),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.mark_email_read_rounded,
                      color: AppThemeData.primary200,
                      size: 32,
                    ),
                  ),
                  const SizedBox(height: 14),
                  Text(
                    otpSent ? 'Verify Email Code' : 'Verify Email Before Activation',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 18,
                      fontFamily: AppThemeData.bold,
                      color: isDarkMode ? Colors.white : const Color(0xFF0F172A),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    otpSent
                        ? 'Enter the 6-digit verification code sent to\n${emailController.text}'
                        : 'Your official Tax Invoice and active Plan Perks certificate will be sent to your verified email.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 13,
                      height: 1.4,
                      color: isDarkMode ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                    ),
                  ),
                  const SizedBox(height: 18),
                  if (errorMsg != null) ...[
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.red.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.red.withOpacity(0.3)),
                      ),
                      child: Text(
                        errorMsg!,
                        textAlign: TextAlign.center,
                        style: const TextStyle(color: Colors.red, fontSize: 12),
                      ),
                    ),
                    const SizedBox(height: 12),
                  ],
                  if (!otpSent) ...[
                    TextField(
                      controller: emailController,
                      keyboardType: TextInputType.emailAddress,
                      style: TextStyle(
                        color: isDarkMode ? Colors.white : const Color(0xFF0F172A),
                        fontSize: 15,
                      ),
                      decoration: InputDecoration(
                        labelText: 'Email Address',
                        hintText: 'name@example.com',
                        prefixIcon: const Icon(Icons.email_outlined, size: 20),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                      ),
                    ),
                    const SizedBox(height: 18),
                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: ElevatedButton(
                        onPressed: isSendingOtp ? null : sendOtp,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppThemeData.primary200,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        child: isSendingOtp
                            ? const SizedBox(
                                width: 22,
                                height: 22,
                                child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                              )
                            : const Text(
                                'Send Verification Code',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 15,
                                  fontFamily: AppThemeData.bold,
                                ),
                              ),
                      ),
                    ),
                  ] else ...[
                    TextField(
                      controller: otpController,
                      keyboardType: TextInputType.number,
                      textAlign: TextAlign.center,
                      maxLength: 6,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                      style: TextStyle(
                        letterSpacing: 10,
                        fontSize: 22,
                        fontFamily: AppThemeData.bold,
                        color: isDarkMode ? Colors.white : const Color(0xFF0F172A),
                      ),
                      decoration: InputDecoration(
                        counterText: '',
                        hintText: '••••••',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      ),
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: ElevatedButton(
                        onPressed: isVerifyingOtp ? null : verifyOtp,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppThemeData.primary200,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        child: isVerifyingOtp
                            ? const SizedBox(
                                width: 22,
                                height: 22,
                                child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                              )
                            : const Text(
                                'Verify & Continue',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 15,
                                  fontFamily: AppThemeData.bold,
                                ),
                              ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    TextButton(
                      onPressed: isSendingOtp ? null : sendOtp,
                      child: Text(
                        'Resend Code',
                        style: TextStyle(
                          color: AppThemeData.primary200,
                          fontFamily: AppThemeData.bold,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          );
        },
      );
    },
  );

  return result == true;
}
