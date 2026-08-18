import 'package:finway/page/MainDashBoard/screen/main_dashboard.dart';
import 'package:finway/themes/button_them.dart';
import 'package:finway/themes/constant_colors.dart';
import 'package:finway/themes/responsive.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:get/get.dart';

class ReviewSuccessScreen extends StatelessWidget {
  const ReviewSuccessScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        Get.offAll(() => const MainDashboard());
        return false;
      },
      child: Scaffold(
        backgroundColor: AppThemeData.blue200,
        body: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                const SizedBox(height: 20),
                Row(
                  children: [
                    InkWell(
                      onTap: () {
                        Get.offAll(() => const MainDashboard());
                      },
                      child: Transform(
                        alignment: Alignment.center,
                        transform: Directionality.of(context) == TextDirection.rtl ? Matrix4.rotationY(3.14159) : Matrix4.identity(),
                        child: SvgPicture.asset(
                          'assets/icons/ic_left.svg',
                          colorFilter: ColorFilter.mode(
                            AppThemeData.grey900,
                            BlendMode.srcIn,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: Responsive.height(15, context)),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Column(children: [
                    Image.asset(
                      'assets/icons/ic_done.gif',
                      width: 200,
                      height: 200,
                      fit: BoxFit.cover,
                    ),
                    Text(
                      'Thank you for your feedback!'.tr,
                      style: TextStyle(
                        color: AppThemeData.grey900,
                        fontSize: 22,
                        fontFamily: AppThemeData.semiBold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 10),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Text(
                        'Your rating has been submitted successfully. We appreciate your input in helping us improve your ride experience.'.tr,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: AppThemeData.grey900,
                          fontSize: 14,
                          fontFamily: AppThemeData.regular,
                        ),
                      ),
                    ),
                    const SizedBox(height: 40),
                    ButtonThem.buildButton(
                      context,
                      title: "Back to Home".tr,
                      btnColor: AppThemeData.primary200,
                      onPress: () {
                        Get.offAll(() => const MainDashboard());
                      },
                    ),
                    const SizedBox(height: 20),
                  ]),
                )
              ],
            ),
          ),
        ),
      ),
    );
  }
}
