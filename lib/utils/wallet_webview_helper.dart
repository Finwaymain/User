import 'package:finway/page/web_view_screen/web_view_screen.dart';
import 'package:finway/utils/onboarding_url.dart';
import 'package:get/get.dart';

void openUserWebWallet({String title = 'Smart Value Wallet'}) {
  final url = OnboardingUrl.build('/wallet', extra: {'user_type': 'user'});
  Get.to(() => WebViewScreen(url: url, title: title));
}
