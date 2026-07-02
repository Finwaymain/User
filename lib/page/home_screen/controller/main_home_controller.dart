import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../utils/Preferences.dart';
import '../../auth_screens/phone_entry_screen.dart';
import '../../features/SmartValue/Payout/view/payout_screen.dart';
import '../../in_progress_screen.dart';
import '../../features/Texi/texi_dash_board.dart';
import '../view/home_screen.dart';

class MainHomeController extends GetxController
    with GetTickerProviderStateMixin {
  late List<AnimationController> controllers;
  late List<Animation<Offset>> slideAnimations;

  final featureCards = [
    {
      "routeName": "/addFund",
      "icon": Icons.payments_rounded,
      "title": "Add Fund",
      "status": 1,
    },
    {
      "routeName": "/rewards",
      "icon": Icons.card_giftcard,
      "title": "Rewards",
      "status": 1,
    },
    {
      "routeName": "/payouts",
      "icon": Icons.payments_outlined,
      "title": "Payouts",
      "status": 1,
    },
  ];

  final serviceCards = [
    {
      "routeName": "/travelTransport",
      "title": "Travel & Transport",
      "subtitle": "Book cabs, recharge passes, pay bills, and more",
      "status": 1,
    },
    {
      "routeName": "/cashbackCard",
      "title": "Cashback Card",
      "subtitle": "Send money to friends or pay shops and earn rewards",
      "status": 1,
    },
    {
      "routeName": "/smartValue",
      "title": "Smart Value",
      "subtitle": "Pay directly within the app and ride instantly",
      "status": 1,
    },
  ];

  final medicalCards = [
    {
      "routeName": "/medical",
      "title": "Medical",
      "subtitle": "Medical services and consultations",
      "status": 1,
    }
  ];

  @override
  void onInit() {
    super.onInit();

    controllers = List.generate(serviceCards.length, (index) {
      return AnimationController(
        vsync: this,
        duration: const Duration(milliseconds: 600),
      );
    });

    slideAnimations = controllers.map((controller) {
      return Tween<Offset>(
        begin: const Offset(1, 0),
        end: Offset.zero,
      ).animate(CurvedAnimation(parent: controller, curve: Curves.easeOut));
    }).toList();

    _startAnimations();
  }

  Future<void> _startAnimations() async {
    for (int i = 0; i < controllers.length; i++) {
      await Future.delayed(Duration(milliseconds: i * 200));
      controllers[i].forward();
    }
    update();
  }

  void onFeatureTap(int index) {
    final card = featureCards[index];
    final status = card['status'] ?? 0;
    final routeName = (card['routeName'] ?? '').toString();
    final bool isLogin = Preferences.getBoolean(Preferences.isLogin) ?? false;

    if (!isLogin) {
      Get.to(() => const PhoneEntryScreen(),
          transition: Transition.rightToLeftWithFade);
    }
    else if (routeName == '/addFund') {
      Get.to(() => AddFundScreen(), transition: Transition.rightToLeftWithFade);
    }

    else if (routeName == '/payouts') {
      Get.to(() => PayoutScreen(), transition: Transition.rightToLeftWithFade);
    } else {
      Get.to(() => const InProgressScreen(),
          transition: Transition.rightToLeftWithFade);
    }
  }

  void onServiceTap(int index) {
    final card = serviceCards[index];
    final bool isLogin = Preferences.getBoolean(Preferences.isLogin) ?? false;
    final status = card['status'] ?? 0;
    final String routeName = card['routeName']?.toString() ?? '';

    if (!isLogin) {
      Get.to(() => const PhoneEntryScreen(),
          transition: Transition.rightToLeftWithFade);
    } else if (index == 0) {
      Get.to(() => TexiDashboard(), transition: Transition.rightToLeftWithFade);
    } else {
      Get.to(() => const InProgressScreen(),
          transition: Transition.rightToLeftWithFade);
    }
  }

  @override
  void onClose() {
    for (var controller in controllers) {
      controller.dispose();
    }
    super.onClose();
  }
}
