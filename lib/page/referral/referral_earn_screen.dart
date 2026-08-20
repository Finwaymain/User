import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:finway/page/web_view_screen/web_view_screen.dart';
import 'package:finway/utils/Preferences.dart';

class ReferralEarnScreen extends StatelessWidget {
  const ReferralEarnScreen({super.key});

  @override
  Widget build(BuildContext context) {
    String userId = Preferences.getString(Preferences.userId);
    if (userId.isEmpty || userId == "0") {
      final userStr = Preferences.getString(Preferences.user);
      if (userStr.isNotEmpty) {
        try {
          final map = jsonDecode(userStr);
          userId = (map['id'] ?? map['id_user'] ?? map['id_driver'] ?? '').toString();
        } catch (_) {}
      }
    }

    final token = Preferences.getString(Preferences.accesstoken);
    final url = 'https://api.fiinway.com/onboarding/referral?driver_id=$userId&user_id=$userId&id_driver=$userId&id_user=$userId&accesstoken=$token';

    return WebViewScreen(
      url: url,
      title: 'Partner Dashboard',
      showAppBar: true,
    );
  }
}
