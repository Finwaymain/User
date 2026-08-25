import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:finway/constant/constant.dart';
import 'package:finway/page/web_view_screen/web_view_screen.dart';
import 'package:finway/utils/Preferences.dart';
import 'package:finway/utils/onboarding_url.dart';

class ReferralEarnScreen extends StatelessWidget {
  const ReferralEarnScreen({super.key});

  @override
  Widget build(BuildContext context) {
    String userId = OnboardingUrl.userId();
    if (userId.isEmpty || userId == "0") {
      final intId = Preferences.getInt(Preferences.userId);
      if (intId != 0) userId = intId.toString();
    }
    if (userId.isEmpty || userId == "0") {
      userId = Preferences.getString(Preferences.userId);
    }
    if (userId.isEmpty || userId == "0") {
      userId = Constant.getUserData().data?.id?.toString() ?? '';
    }

    String phone = Constant.getUserData().data?.phone ?? '';
    if (phone.isEmpty) {
      final userStr = Preferences.getString(Preferences.user);
      if (userStr.isNotEmpty) {
        try {
          final map = jsonDecode(userStr);
          phone = (map['phone'] ?? map['data']?['phone'] ?? '').toString();
        } catch (_) {}
      }
    }

    final token = OnboardingUrl.accessToken();

    final url = OnboardingUrl.build(
      '/onboarding/referral',
      extra: {
        'user_id': userId,
        'id_user': userId,
        'user_cat': 'customer',
        'user_type': 'customer',
        if (phone.isNotEmpty) 'phone': phone,
        if (token.isNotEmpty) 'accesstoken': token,
      },
    );

    return WebViewScreen(
      url: url,
      title: 'Partner Dashboard',
      showAppBar: true,
    );
  }
}
