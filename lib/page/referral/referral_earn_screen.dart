import 'package:finway/page/web_view_screen/web_view_screen.dart';
import 'package:finway/utils/Preferences.dart';
import 'package:flutter/material.dart';

class ReferralEarnScreen extends StatelessWidget {
  const ReferralEarnScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final userId = Preferences.getInt(Preferences.userId);
    final token = Preferences.getString(Preferences.accesstoken);
    final url = 'https://api.fiinway.com/onboarding/referral?user_id=$userId&accesstoken=$token';

    return WebViewScreen(
      url: url,
      title: 'Refer & Earn',
      showAppBar: true,
    );
  }
}
