import  'package:finway/constant/constant.dart';
import 'package:finway/controller/on_boarding_controller.dart';
import 'package:finway/themes/button_them.dart';
import 'package:finway/themes/constant_colors.dart';
import 'package:finway/themes/responsive.dart';
import 'package:finway/utils/Preferences.dart';
import 'package:finway/utils/dark_theme_provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:get/get.dart';
import 'package:provider/provider.dart';
import 'MainDashBoard/screen/main_dashboard.dart';

class OnBoardingScreen extends StatelessWidget {
  const OnBoardingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final themeChange = Provider.of<DarkThemeProvider>(context);
    return GetX<OnBoardingController>(
      init: OnBoardingController(),
      builder: (controller) {
        return Scaffold(
          appBar: AppBar(
            leading: controller.selectedPageIndex.value != 0
                ? IconButton(
                    onPressed: () {
                      controller.selectedPageIndex.value = controller.selectedPageIndex.value - 1;
                      controller.pageController.jumpToPage(controller.selectedPageIndex.value);
                      controller.update();
                    },
                    icon: SvgPicture.asset(
                      "assets/icons/ic_back_arrow.svg",
                      colorFilter: ColorFilter.mode(
                        themeChange.getThem() ? AppThemeData.grey900Dark : AppThemeData.grey900,
                        BlendMode.srcIn,
                      ),
                    ))
                : null,
            backgroundColor: themeChange.getThem() ? AppThemeData.surface50Dark : AppThemeData.surface50,
            elevation: 0,
            actions: [
              if (controller.onboardingModel.value.data != null && controller.selectedPageIndex.value != controller.onboardingModel.value.data!.length - 1)
                InkWell(
                  splashColor: Colors.transparent,
                  onTap: () {

                    Preferences.setBoolean(Preferences.isFinishOnBoardingKey, true);
                    Get.offAll(const MainDashboard());
                  },
                  child: Padding(
                    padding: const EdgeInsets.only(right: 20),
                    child: Text(
                      'skip'.tr,
                      style: TextStyle(
                        fontSize: 16,
                        decoration: TextDecoration.underline,
                        decorationColor: AppThemeData.secondary200,
                        color: AppThemeData.secondary200,
                        fontFamily: AppThemeData.regular,
                      ),
                    ),
                  ),
                ),
            ],
          ),
          body: controller.isLoading.value == true
              ? SizedBox()
              : Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Expanded(
                      child: PageView.builder(
                          controller: controller.pageController,
                          onPageChanged: controller.selectedPageIndex.call,
                          itemCount: controller.onboardingModel.value.data?.length,
                          itemBuilder: (context, index) {
                            return Column(
                              children: [
                                Padding(
                                  padding: const EdgeInsets.only(top: 40),
                                  child: Column(
                                    children: [
                                      Text(
                                        controller.onboardingModel.value.data?[index].title ?? '',
                                        textAlign: TextAlign.center,
                                        style: TextStyle(
                                            fontSize: 24,
                                            color: themeChange.getThem() ? AppThemeData.grey900Dark : AppThemeData.grey900,
                                            fontFamily: AppThemeData.semiBold,
                                            letterSpacing: 1.5),
                                      ),
                                      Padding(
                                        padding: const EdgeInsets.symmetric(horizontal: 40.0, vertical: 12),
                                        child: Text(
                                          controller.onboardingModel.value.data?[index].description ?? '',
                                          textAlign: TextAlign.center,
                                          style: TextStyle(
                                            fontSize: 16,
                                            color: themeChange.getThem() ? AppThemeData.grey900Dark : AppThemeData.grey900,
                                            letterSpacing: 1.5,
                                            fontFamily: AppThemeData.regular,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                // Expanded(
                                //     child: Center(
                                //   child: Image.asset(
                                //     controller.localImage[index],
                                //     fit: BoxFit.cover,
                                //     width: Responsive.width(100, context),
                                //     height: Responsive.width(100, context),
                                //   ),
                                // )),
                                Expanded(
                                    child: Center(
                                  child: CachedNetworkImage(
                                    filterQuality: FilterQuality.high,
                                    fit: BoxFit.cover,
                                    width: Responsive.width(100, context),
                                    height: Responsive.width(100, context),
                                    imageUrl: controller.onboardingModel.value.data?[index].image ?? '',
                                    placeholder: (context, url) => Constant.loader(context),
                                    errorWidget: (context, url, error) => Image.asset(
                                      controller.localImage[index],
                                      fit: BoxFit.cover,
                                      width: Responsive.width(100, context),
                                      height: Responsive.width(100, context),
                                    ),
                                  ),
                                )),
                              ],
                            );
                          }),
                    ),
                    if (controller.onboardingModel.value.data != null && controller.selectedPageIndex.value == (controller.onboardingModel.value.data!.length - 1))
                      Center(
                        heightFactor: 1,
                        child: ButtonThem.buildButton(
                          btnColor: AppThemeData.primary200,
                          txtColor: themeChange.getThem() ? AppThemeData.grey900 : AppThemeData.grey900Dark,
                          context,
                          title: 'start_your_journey'.tr,
                          btnWidthRatio: 0.6,
                          onPress: () async {
                            Preferences.setBoolean(Preferences.isFinishOnBoardingKey, true);
                            Get.offAll(const MainDashboard());
                          },
                        ),
                      ),

                    if (controller.onboardingModel.value.data != null && controller.selectedPageIndex.value != (controller.onboardingModel.value.data!.length - 1))
                      Center(
                        heightFactor: 1,
                        child: ButtonThem.buildButton(
                          btnColor: AppThemeData.primary200,
                          txtColor: themeChange.getThem() ? AppThemeData.grey900 : AppThemeData.grey900Dark,
                          context,
                          title: 'next'.tr,
                          btnWidthRatio: 0.6,
                          onPress: () async {
                            controller.selectedPageIndex.value = controller.selectedPageIndex.value + 1;
                            controller.pageController.jumpToPage(controller.selectedPageIndex.value);
                          },
                        ),
                      ),
                    const SizedBox(height: 20),
                    // InkWell(onTap: () {
                    //   if (controller.selectedPageIndex.value == controller.onBoardingList.length - 1) {
                    //     Preferences.setBoolean(Preferences.isFinishOnBoardingKey, true);
                    //     Get.offAll(LoginScreen());
                    //   } else {
                    //     controller.pageController.nextPage(duration: 300.milliseconds, curve: Curves.ease);
                    //   }
                    // }, child: Obx(() {
                    //   return Text(
                    //     controller.isLastPage ? 'done'.tr : 'next'.tr,
                    //     style: const TextStyle(fontSize: 16),
                    //   );
                    // }))
                  ],
                ),
        );
      },
    );
  }

  BorderRadiusGeometry borderRadius(int index, int currentIndex) {
    if (index == 0 && currentIndex == 0) {
      return const BorderRadius.all(Radius.circular(10.0));
    }
    if (index == 0 && currentIndex == 1) {
      return const BorderRadius.only(topLeft: Radius.circular(40.0), bottomLeft: Radius.circular(40.0));
    }
    if (index == 0 && currentIndex == 2) {
      return const BorderRadius.only(topRight: Radius.circular(40.0), bottomRight: Radius.circular(40.0));
    }
    if (index == 1 && currentIndex == 1) {
      return const BorderRadius.all(Radius.circular(10.0));
    }
    if (index == 1 && currentIndex == 1) {
      return const BorderRadius.all(Radius.circular(10.0));
    }
    if (index == 1 && currentIndex == 2) {
      return const BorderRadius.all(Radius.circular(10.0));
    }
    if (index == 2 && currentIndex == 2) {
      return const BorderRadius.all(Radius.circular(10.0));
    }
    if (index == 2 && currentIndex == 0) {
      return const BorderRadius.only(topLeft: Radius.circular(40.0), bottomLeft: Radius.circular(40.0));
    }
    if (index == 2 && currentIndex == 1) {
      return const BorderRadius.only(topRight: Radius.circular(40.0), bottomRight: Radius.circular(40.0));
    }
    return const BorderRadius.all(Radius.circular(10.0));
  }
}
