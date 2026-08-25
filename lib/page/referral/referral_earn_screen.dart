import 'package:flutter/material.dart';
import 'package:finway/page/web_view_screen/web_view_screen.dart';
import 'package:finway/utils/onboarding_url.dart';

class ReferralEarnScreen extends StatelessWidget {
  const ReferralEarnScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final url = OnboardingUrl.build('/onboarding/referral');

    return WebViewScreen(
      url: url,
      title: 'Partner Dashboard',
      showAppBar: true,
    );
  }
}
