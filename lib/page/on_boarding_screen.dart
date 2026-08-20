import 'package:flutter/material.dart';
import 'package:finway/page/web_view_screen/web_view_screen.dart';

class OnBoardingScreen extends StatelessWidget {
  const OnBoardingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const WebViewScreen(
      url: 'https://api.fiinway.com/onboarding/welcome?type=user',
      title: 'Welcome to Fiinway',
      showAppBar: false,
    );
  }
}
