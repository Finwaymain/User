import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';

import 'package:finway/constant/show_toast_dialog.dart';
import 'package:finway/page/referral/partner_webview_screen.dart';
import 'package:finway/service/api.dart';
import 'package:finway/themes/constant_colors.dart';
import 'package:finway/utils/Preferences.dart';
import 'package:finway/utils/dark_theme_provider.dart';

class SubmitAadharScreen extends StatefulWidget {
  const SubmitAadharScreen({super.key});

  @override
  State<SubmitAadharScreen> createState() => _SubmitAadharScreenState();
}

class _SubmitAadharScreenState extends State<SubmitAadharScreen> {
  final _formKey = GlobalKey<FormState>();
  final _aadharController = TextEditingController();
  bool _isSubmitting = false;

  @override
  void dispose() {
    _aadharController.dispose();
    super.dispose();
  }

  Future<void> _submitAadhar() async {
    if (!_formKey.currentState!.validate()) return;

    final aadhar = _aadharController.text.trim().replaceAll(' ', '');
    final userId = Preferences.getInt(Preferences.userId);

    if (userId == 0) {
      ShowToastDialog.showToast('Please login to continue.'.tr);
      return;
    }

    setState(() => _isSubmitting = true);
    ShowToastDialog.showLoader('Submitting Aadhaar...'.tr);

    try {
      final response = await http.post(
        Uri.parse('${API.baseUrl}user/submit-aadhar'),
        headers: API.header,
        body: json.encode({
          'user_id': userId,
          'id_user': userId,
          'aadhar_number': aadhar,
        }),
      );

      ShowToastDialog.closeLoader();
      setState(() => _isSubmitting = false);

      final data = json.decode(response.body);
      if (response.statusCode == 200 && (data['success'] == true || data['success'] == 'success')) {
        await Preferences.setString('user_aadhar_number', aadhar);
        Get.snackbar(
          'Account Activated!'.tr,
          'Your Aadhaar is verified. Welcome to Partner Dashboard!'.tr,
          backgroundColor: AppThemeData.success300,
          colorText: Colors.white,
          snackPosition: SnackPosition.BOTTOM,
          margin: const EdgeInsets.all(16),
        );
        Get.off(
          () => const PartnerWebViewScreen(
            title: 'Partner Dashboard',
            urlPath: 'partner-dashboard',
          ),
        );
      } else {
        ShowToastDialog.showToast(data['message'] ?? 'Failed to submit Aadhaar. Please try again.'.tr);
      }
    } catch (e) {
      ShowToastDialog.closeLoader();
      setState(() => _isSubmitting = false);
      ShowToastDialog.showToast('An error occurred. Please try again.'.tr);
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeChange = Provider.of<DarkThemeProvider>(context);
    final isDark = themeChange.getThem();

    return Scaffold(
      backgroundColor: isDark ? AppThemeData.surface50Dark : AppThemeData.surface50,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: isDark ? const Color(0xFF1E293B) : Colors.white,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded, color: isDark ? Colors.white : AppThemeData.grey900, size: 20),
          onPressed: () => Get.back(),
        ),
        title: Text(
          'Join as a Partner'.tr,
          style: TextStyle(
            color: isDark ? Colors.white : AppThemeData.grey900,
            fontFamily: AppThemeData.bold,
            fontSize: 18,
          ),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const SizedBox(height: 10),
                // Header Banner Card
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [AppThemeData.primary200, AppThemeData.primary300],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: AppThemeData.primary200.withValues(alpha: 0.3),
                        blurRadius: 15,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.2),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.handshake_rounded, color: Colors.white, size: 48),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Become a Fiinway Partner'.tr,
                        style: const TextStyle(
                          color: Colors.white,
                          fontFamily: AppThemeData.bold,
                          fontSize: 22,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Enter your 12-digit Aadhaar number to verify identity and unlock your Partner Dashboard with exclusive referral earnings.'.tr,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.9),
                          fontSize: 13,
                          height: 1.4,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 30),

                // Form Card
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF1E293B) : Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.05),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.badge_rounded, color: AppThemeData.primary200, size: 22),
                          const SizedBox(width: 8),
                          Text(
                            'Aadhaar Verification'.tr,
                            style: TextStyle(
                              fontFamily: AppThemeData.bold,
                              fontSize: 16,
                              color: isDark ? Colors.white : AppThemeData.grey900,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _aadharController,
                        keyboardType: TextInputType.number,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                          LengthLimitingTextInputFormatter(12),
                        ],
                        style: TextStyle(
                          fontSize: 16,
                          letterSpacing: 2.0,
                          fontFamily: AppThemeData.medium,
                          color: isDark ? Colors.white : AppThemeData.grey900,
                        ),
                        decoration: InputDecoration(
                          hintText: 'Enter 12-digit Aadhaar Number'.tr,
                          hintStyle: TextStyle(
                            letterSpacing: 0,
                            fontSize: 14,
                            color: isDark ? AppThemeData.grey400Dark : AppThemeData.grey400,
                          ),
                          prefixIcon: Icon(Icons.credit_card_rounded, color: AppThemeData.primary200),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: isDark ? AppThemeData.grey500Dark : AppThemeData.grey200),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: isDark ? AppThemeData.grey500Dark : AppThemeData.grey200),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: AppThemeData.primary200, width: 2),
                          ),
                          filled: true,
                          fillColor: isDark ? AppThemeData.surface50Dark : const Color(0xFFF8FAFC),
                        ),
                        validator: (value) {
                          final val = (value ?? '').trim();
                          if (val.isEmpty) {
                            return 'Please enter your Aadhaar number'.tr;
                          }
                          if (val.length != 12) {
                            return 'Aadhaar number must be exactly 12 digits'.tr;
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Icon(Icons.shield_outlined, size: 14, color: AppThemeData.grey500),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              'Your information is securely encrypted and saved.'.tr,
                              style: TextStyle(fontSize: 11, color: AppThemeData.grey500),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 30),

                // Submit Button
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppThemeData.primary200,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      elevation: 2,
                    ),
                    onPressed: _isSubmitting ? null : _submitAadhar,
                    child: _isSubmitting
                        ? const CircularProgressIndicator(color: Colors.white)
                        : Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                'Submit & Activate Partner Account'.tr,
                                style: const TextStyle(
                                  fontFamily: AppThemeData.bold,
                                  fontSize: 16,
                                ),
                              ),
                              const SizedBox(width: 8),
                              const Icon(Icons.arrow_forward_rounded, size: 20),
                            ],
                          ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
