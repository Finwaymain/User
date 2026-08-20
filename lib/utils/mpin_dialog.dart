import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';

import 'package:finway/constant/constant.dart';
import 'package:finway/service/api.dart';
import 'package:finway/themes/constant_colors.dart';
import 'package:finway/utils/dark_theme_provider.dart';

Future<bool> verifyMpin(String enteredPin, {String userCat = 'customer'}) async {
  try {
    final user = Constant.getUserData().data;
    final userId = user?.id;

    if (userId != null && userId.toString().isNotEmpty) {
      final response = await http.post(
        Uri.parse(API.verifyMpin),
        headers: API.header,
        body: jsonEncode({
          'user_id': userId,
          'user_cat': userCat,
          'mpin': enteredPin,
        }),
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['valid'] == true || data['success'] == 'success') {
          return true;
        } else {
          return false;
        }
      }
    }
  } catch (e) {
    // If backend unreachable, perform fallback check against cached MPIN
  }

  final user = Constant.getUserData().data;
  if (user == null) return false;

  final storedMPin = user.mPin;
  if (storedMPin != null && storedMPin.isNotEmpty) {
    if (enteredPin == storedMPin) return true;
    final hashedPin = md5.convert(utf8.encode(enteredPin)).toString();
    if (hashedPin == storedMPin) return true;
  }

  return false;
}

Future<String?> showMpinVerificationBottomSheet(
  BuildContext context, {
  required double amount,
  String? title,
  String userCat = 'customer',
}) async {
  final pinController = TextEditingController();
  final focusNode = FocusNode();
  String enteredPin = '';
  String? errorMessage;
  bool isVerifying = false;

  final result = await showModalBottomSheet<String>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (ctx) {
      final isDark = Provider.of<DarkThemeProvider>(ctx, listen: false).getThem();
      return StatefulBuilder(
        builder: (context, setState) {
          return Padding(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(context).viewInsets.bottom,
            ),
            child: Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: isDark ? AppThemeData.grey50Dark : Colors.white,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey[400],
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    title ?? 'Enter MPIN to Pay'.tr,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white : Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    '${'Confirm wallet payment of'.tr} ${(Constant.currency ?? '₹')}${amount.toStringAsFixed(0)}',
                    style: TextStyle(
                      fontSize: 13,
                      color: isDark ? Colors.white70 : Colors.black54,
                    ),
                  ),
                  const SizedBox(height: 24),
                  // PIN Dots
                  GestureDetector(
                    onTap: () => focusNode.requestFocus(),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(4, (index) {
                        final filled = index < enteredPin.length;
                        return Container(
                          margin: const EdgeInsets.symmetric(horizontal: 10),
                          width: 18,
                          height: 18,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: filled
                                ? AppThemeData.primary200
                                : (isDark ? Colors.grey[700] : Colors.grey[300]),
                          ),
                        );
                      }),
                    ),
                  ),
                  const SizedBox(height: 16),
                  if (errorMessage != null) ...[
                    Text(
                      errorMessage!,
                      style: const TextStyle(color: Colors.red, fontSize: 13, fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 12),
                  ],
                  // Hidden text input
                  Opacity(
                    opacity: 0,
                    child: SizedBox(
                      height: 1,
                      width: 1,
                      child: TextField(
                        controller: pinController,
                        focusNode: focusNode,
                        autofocus: true,
                        enabled: !isVerifying,
                        keyboardType: TextInputType.number,
                        maxLength: 4,
                        obscureText: true,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                          LengthLimitingTextInputFormatter(4),
                        ],
                        onChanged: (val) {
                          setState(() {
                            enteredPin = val;
                            errorMessage = null;
                          });
                        },
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: isVerifying ? null : () => Navigator.pop(ctx, null),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          child: Text('Cancel'.tr),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: (enteredPin.length == 4 && !isVerifying)
                              ? () async {
                                  setState(() {
                                    isVerifying = true;
                                    errorMessage = null;
                                  });

                                  final ok = await verifyMpin(enteredPin, userCat: userCat);

                                  if (ok) {
                                    if (context.mounted) {
                                      Navigator.pop(ctx, enteredPin);
                                    }
                                  } else {
                                    setState(() {
                                      isVerifying = false;
                                      errorMessage = 'Incorrect MPIN. Please try again.'.tr;
                                      enteredPin = '';
                                      pinController.clear();
                                    });
                                  }
                                }
                              : null,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppThemeData.primary200,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          child: isVerifying
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                                )
                              : Text('Confirm'.tr),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      );
    },
  );

  return result;
}
