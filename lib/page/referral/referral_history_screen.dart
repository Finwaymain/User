import 'package:finway/page/web_view_screen/web_view_screen.dart';
import 'package:finway/utils/onboarding_url.dart';
import 'package:flutter/material.dart';

class ReferralHistoryScreen extends StatelessWidget {
  const ReferralHistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final url = OnboardingUrl.build(
      '/onboarding/referral',
      extra: {
        'view': 'dashboard',
        'user_type': 'customer',
        'user_cat': 'customer',
      },
    );

    return WebViewScreen(
      url: url,
      title: 'Referral History',
      showAppBar: true,
    );
  }
}
