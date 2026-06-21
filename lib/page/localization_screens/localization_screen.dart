import 'package:finway/constant/show_toast_dialog.dart';
import 'package:finway/controller/localization_controller.dart';
import 'package:finway/page/on_boarding_screen.dart';
import 'package:finway/service/localization_service.dart';
import 'package:finway/themes/button_them.dart';
import 'package:finway/themes/constant_colors.dart';
import 'package:finway/themes/responsive.dart';
import 'package:finway/utils/Preferences.dart';
import 'package:finway/utils/dark_theme_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:get/get.dart';
import 'package:provider/provider.dart';

class LocalizationScreens extends StatelessWidget {
  final String intentType;

  const LocalizationScreens({super.key, required this.intentType});

  @override
  Widget build(BuildContext context) {
    final themeChange = Provider.of<DarkThemeProvider>(context);
    return GetX<LocalizationController>(
      init: LocalizationController(),
      builder: (controller) {
        return Scaffold(
          appBar: AppBar(
            backgroundColor: themeChange.getThem() ? AppThemeData.surface50Dark : AppThemeData.surface50,
            elevation: 0,
            actions: [
              if (intentType != "dashBoard")
                InkWell(
                  splashColor: Colors.transparent,
                  onTap: () {
                    LocalizationService().changeLocale(controller.selectedLanguage.value);
                    Preferences.setString(Preferences.languageCodeKey, controller.selectedLanguage.toString());
                    if (intentType == "dashBoard") {
                      ShowToastDialog.showToast("language_change_successfully".tr);
                    } else {
                      Get.offAll(const OnBoardingScreen(), transition: Transition.rightToLeft);
                    }
                  },
                  child: Padding(
                    padding: const EdgeInsets.only(right: 16),
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
          body: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.only(top: 20, bottom: 6),
                  child: Text(
                    'select_language'.tr,
                    style: TextStyle(
                      fontSize: 22,
                      fontFamily: AppThemeData.semiBold,
                      color: themeChange.getThem() ? AppThemeData.grey900Dark : AppThemeData.grey900,
                    ),
                  ),
                ),
                Text(
                  'choose_language_desc'.tr,
                  style: TextStyle(
                    fontSize: 16,
                    fontFamily: AppThemeData.regular,
                    color: themeChange.getThem() ? AppThemeData.grey900Dark : AppThemeData.grey900,
                  ),
                ),
                const SizedBox(height: 30),
                Expanded(
                  child: ListView.separated(
                    separatorBuilder: (context, index) {
                      return Container(
                        height: 0.6,
                        color: themeChange.getThem() ? AppThemeData.grey300Dark : AppThemeData.grey100,
                      );
                    },
                    itemCount: controller.languageList.length,
                    shrinkWrap: true,
                    itemBuilder: (context, index) {
                      return Obx(
                        () => InkWell(
                          splashColor: Colors.transparent,
                          onTap: () {
                            controller.selectedLanguage.value = controller.languageList[index].code.toString();
                          },
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 16,
                            ),
                            child: Column(
                              children: [
                                Row(
                                  children: [
                                    Expanded(
                                      child: Row(
                                        children: [
                                          ClipRRect(
                                            borderRadius: BorderRadius.circular(6),
                                            child: Image.network(
                                              controller.languageList[index].flag.toString(),
                                              height: 35,
                                              width: 50,
                                              fit: BoxFit.cover,
                                            ),
                                          ),
                                          const SizedBox(width: 16),
                                          Align(
                                              alignment: Alignment.bottomRight,
                                              child: Text(
                                                controller.languageList[index].language.toString(),
                                                style: TextStyle(
                                                  fontSize: 16,
                                                  fontFamily: AppThemeData.medium,
                                                  color: themeChange.getThem() ? AppThemeData.grey900Dark : AppThemeData.grey900,
                                                ),
                                              ))
                                        ],
                                      ),
                                    ),
                                    controller.languageList[index].code == controller.selectedLanguage.value
                                        ? SvgPicture.asset(
                                            "assets/icons/ic_radio_selected.svg",
                                            // colorFilter: ColorFilter.mode(
                                            //   themeChange.getThem() ? AppThemeData.grey300 : AppThemeData.grey600,
                                            //   BlendMode.srcIn,
                                            // ),
                                          )
                                        : SvgPicture.asset(
                                            "assets/icons/ic_radio_unselected.svg",
                                            // colorFilter: ColorFilter.mode(
                                            //   themeChange.getThem() ? AppThemeData.grey300 : AppThemeData.grey600,
                                            //   BlendMode.srcIn,
                                            // ),
                                          )
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
                Visibility(
                  visible: intentType != "dashBoard",
                  child: SizedBox(
                    width: Responsive.width(100, context),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: Text(
                        'skip_desc'.tr,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 16,
                          fontFamily: AppThemeData.light,
                          color: themeChange.getThem() ? AppThemeData.grey300Dark : AppThemeData.grey400,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          bottomNavigationBar: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
              child: Center(
                heightFactor: 1,
                child: ButtonThem.buildButton(
                  context,
                  title: intentType == "dashBoard" ? 'save'.tr : 'continue'.tr,
                  btnWidthRatio: intentType == "dashBoard" ? 1 : 0.6,
                  txtColor: themeChange.getThem() ? AppThemeData.grey50 : AppThemeData.grey50Dark,
                  onPress: () async {
                    LocalizationService().changeLocale(controller.selectedLanguage.value);
                    Preferences.setString(Preferences.languageCodeKey, controller.selectedLanguage.toString());
                    if (intentType == "dashBoard") {
                      ShowToastDialog.showToast("language_change_successfully".tr);
                    } else {
                      Get.offAll(const OnBoardingScreen());
                    }
                  },
                ),
              )),
        );
      },
    );
  }
}
