import 'package:finway/constant/constant.dart';
import 'package:finway/page/web_view_screen/web_view_screen.dart';
import 'package:flutter/material.dart';

class FinanceScreen extends StatelessWidget {
  /// Optional override URL — used when launching directly from the wallet card.
  /// If null, defaults to the finance hub with the user's phone number.
  final String? initialUrl;
  final bool isTab;

  const FinanceScreen({super.key, this.initialUrl, this.isTab = false});

  @override
  Widget build(BuildContext context) {
    final phone = Constant.getUserData().data?.phone ?? '';
    var url = initialUrl ?? 'https://api.fiinway.com/finance?phone=$phone';
    if (!url.contains('hide_header=')) {
      final sep = url.contains('?') ? '&' : '?';
      url = '$url${sep}hide_header=1';
    }

    final webView = Padding(
      padding: EdgeInsets.only(bottom: isTab ? 65.0 : 0.0),
      child: WebViewScreen(
        url: url,
        title: 'Loans',
        showAppBar: false,
      ),
    );

    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0F172A),
        foregroundColor: Colors.white,
        automaticallyImplyLeading: !isTab,
        title: const Text(
          'Loans',
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
        elevation: 0,
      ),
      body: webView,
    );
  }
}
