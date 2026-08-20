import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:finway/page/web_view_screen/web_view_screen.dart';
import 'package:finway/utils/Preferences.dart';

class ReferralEarnScreen extends StatelessWidget {
  const ReferralEarnScreen({super.key});

  @override
  Widget build(BuildContext context) {
    String userId = Preferences.getString(Preferences.userId);
    String phone = '';
    final userStr = Preferences.getString(Preferences.user);
    if (userStr.isNotEmpty) {
      try {
        final map = jsonDecode(userStr);
        if (userId.isEmpty || userId == "0") {
          userId = (map['id'] ?? map['id_user'] ?? map['data']?['id'] ?? '').toString();
        }
        phone = (map['phone'] ?? map['data']?['phone'] ?? '').toString();
      } catch (_) {}
    }

    final token = Preferences.getString(Preferences.accesstoken);
    final url = 'https://api.fiinway.com/onboarding/referral?user_id=$userId&id_user=$userId&user_cat=customer&user_type=customer&phone=${Uri.encodeComponent(phone)}&accesstoken=$token';

    return WebViewScreen(
      url: url,
      title: 'Partner Dashboard',
      showAppBar: true,
      showBottomBar: true,
    );
  }
}
