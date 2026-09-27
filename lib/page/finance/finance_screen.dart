import 'package:finway/constant/constant.dart';
import 'package:finway/page/web_view_screen/web_view_screen.dart';
import 'package:flutter/material.dart';

class FinanceScreen extends StatelessWidget {
  /// Optional override URL — used when launching directly from the wallet card.
  /// If null, defaults to the finance hub with the user's phone number.
  final String? initialUrl;

  const FinanceScreen({super.key, this.initialUrl});

  @override
  Widget build(BuildContext context) {
    final phone = Constant.getUserData().data?.phone ?? '';
    final url = initialUrl ?? 'https://api.fiinway.com/finance?phone=$phone';

    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF0f172a),
        foregroundColor: Colors.white,
        title: const Text(
          'Loans',
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
        elevation: 0,
      ),
      body: WebViewScreen(
        url: url,
        title: 'Loans',
        showAppBar: false,
      ),
    );
  }
}
