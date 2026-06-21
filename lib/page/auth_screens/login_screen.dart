import 'dart:convert';
import 'dart:io';
import 'package:finway/constant/show_toast_dialog.dart';
import 'package:finway/controller/login_conroller.dart';
import 'package:finway/page/auth_screens/forgot_password.dart';
import 'package:finway/page/auth_screens/mobile_number_screen.dart';
import 'package:finway/page/auth_screens/signup_screen.dart';
import 'package:finway/themes/button_them.dart';
import 'package:finway/themes/constant_colors.dart';
import 'package:finway/themes/text_field_them.dart';
import 'package:finway/utils/Preferences.dart';
import 'package:finway/utils/dark_theme_provider.dart';
import 'package:finway/widget/permission_dialog.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:location/location.dart';
import 'package:provider/provider.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../MainDashBoard/screen/main_dashboard.dart';

class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final themeChange = Provider.of<DarkThemeProvider>(context);
    bool isDarkMode = themeChange.getThem();

    return GetBuilder(
        init: LoginController(),
        initState: (state) async {
          try {
            PermissionStatus location = await Location().hasPermission();
            if (PermissionStatus.granted != location) {
              showDialogPermission(context);
            }
          } on PlatformException catch (e) {
            ShowToastDialog.showToast("${e.message}");
          }
        },
        builder: (controller) {
          return Scaffold(
            resizeToAvoidBottomInset: false,
            backgroundColor: AppThemeData.primary200,
            body: SafeArea(
              child: Stack(
                children: [
                  Column(
                    children: [
                      Expanded(
                        flex: 1,
                        child: Container(
                          color: AppThemeData.primary200,
                          child: Padding(
                            padding:
                                const EdgeInsets.symmetric(horizontal: 15.0),
                            child: SingleChildScrollView(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const SizedBox(height: 20),
                                  Text(
                                    "Welcome Back!".tr,
                                    style: TextStyle(
                                      fontSize: 24,
                                      fontFamily: AppThemeData.semiBold,
                                      color: isDarkMode
                                          ? AppThemeData.grey50
                                          : AppThemeData.grey50Dark,
                                    ),
                                  ),
                                  const SizedBox(height: 10),
                                  Text(
                                    "Log in to your CabME account and continue your journey with seamless rides."
                                        .tr,
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontFamily: AppThemeData.regular,
                                      color: isDarkMode
                                          ? AppThemeData.grey50
                                          : AppThemeData.grey50Dark,
                                    ),
                                  ),
                                  const SizedBox(height: 60),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                      Expanded(
                        flex: Platform.isIOS ? 3 : 4,
                        child: Container(
                          color: isDarkMode
                              ? AppThemeData.surface50Dark
                              : AppThemeData.surface50,
                          child: Stack(
                            alignment: Alignment.bottomCenter,
                            children: [
                              Image.asset(
                                isDarkMode
                                    ? 'assets/images/ic_bg_signup_dark.png'
                                    : 'assets/images/ic_bg_signup_light.png',
                                width: double.infinity,
                                fit: BoxFit.cover,
                              ),

                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                  Column(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      SingleChildScrollView(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            const SizedBox(height: 130),
                            Column(
                              children: [
                                TextFieldWidget(
                                  prefix: IconButton(
                                    onPressed: () {},
                                    icon: SvgPicture.asset(
                                      "assets/icons/ic_email.svg",
                                      colorFilter: ColorFilter.mode(
                                        isDarkMode
                                            ? AppThemeData.grey500Dark
                                            : AppThemeData.grey300Dark,
                                        BlendMode.srcIn,
                                      ),
                                    ),
                                  ),
                                  hintText: 'email address'.tr,
                                  controller: controller.phoneController.value,
                                  textInputType: TextInputType.emailAddress,
                                ),
                                TextFieldWidget(
                                  prefix: IconButton(
                                    onPressed: () {},
                                    icon: SvgPicture.asset(
                                      'assets/icons/ic_lock.svg',
                                      colorFilter: ColorFilter.mode(
                                        isDarkMode
                                            ? AppThemeData.grey500Dark
                                            : AppThemeData.grey300Dark,
                                        BlendMode.srcIn,
                                      ),
                                    ),
                                  ),
                                  hintText: 'enter password'.tr,
                                  controller:
                                      controller.passwordController.value,
                                  textInputType: TextInputType.text,
                                  obscureText: true,
                                ),
                              ],
                            ),
                            Align(
                              alignment: Alignment.centerRight,
                              child: GestureDetector(
                                onTap: () {
                                  Get.to(
                                    ForgotPasswordScreen(),
                                    duration: const Duration(milliseconds: 400),
                                    transition: Transition.rightToLeft,
                                  );
                                },
                                child: Padding(
                                  padding: const EdgeInsets.only(top: 10),
                                  child: Text(
                                    "forgot password".tr,
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: AppThemeData.secondary200,
                                      fontFamily: AppThemeData.regular,
                                      decoration: TextDecoration.underline,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.only(top: 50),
                              child: ButtonThem.buildButton(
                                context,
                                title: 'Log in'.tr,
                                onPress: () async {
                                  if (controller
                                      .phoneController.value.text.isEmpty) {
                                    ShowToastDialog.showToast(
                                        'Please enter the email address');
                                  } else if (controller
                                      .passwordController.value.text.isEmpty) {
                                    ShowToastDialog.showToast(
                                        'Please enter the password');
                                  } else {
                                    FocusScope.of(context).unfocus();
                                    Map<String, String> bodyParams = {
                                      'email': controller
                                          .phoneController.value.text
                                          .trim(),
                                      'mdp': controller
                                          .passwordController.value.text,
                                      'user_cat': "customer",
                                    };
                                    await controller
                                        .loginAPI(bodyParams)
                                        .then((value) {
                                      if (value != null) {
                                        if (value.success == "Success") {
                                          Preferences.setInt(
                                              Preferences.userId,
                                              int.parse(
                                                  value.data!.id.toString()));
                                          Preferences.setString(
                                              Preferences.user,
                                              jsonEncode(value));
                                          Preferences.setBoolean(
                                              Preferences.isLogin, true);
                                          controller.phoneController.value
                                              .clear();
                                          controller.passwordController.value
                                              .clear();
                                          Get.offAll(MainDashboard(), duration: const Duration(milliseconds: 400), transition: Transition.rightToLeft);
                                          // Get.offAll(TexiDashboard(), duration: const Duration(milliseconds: 400), transition: Transition.rightToLeft);
                                        } else {
                                          ShowToastDialog.showToast(
                                              value.error);
                                        }
                                      }
                                    });
                                  }
                                },
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.symmetric(vertical: 24),
                              child: Text(
                                "or continue with".tr,
                                style: TextStyle(
                                  fontSize: 14,
                                  color: isDarkMode
                                      ? AppThemeData.grey400Dark
                                      : AppThemeData.grey400,
                                  fontFamily: AppThemeData.regular,
                                ),
                              ),
                            ),
                            ButtonThem.buildIconButtonWidget(
                              context,
                              title: 'Mobile number'.tr,
                              btnColor: isDarkMode
                                  ? AppThemeData.grey300Dark
                                  : AppThemeData.grey300,
                              txtColor: isDarkMode
                                  ? AppThemeData.grey900Dark
                                  : AppThemeData.grey900,
                              iconColor: isDarkMode
                                  ? AppThemeData.grey900Dark
                                  : AppThemeData.grey900,
                              icon: SvgPicture.asset(
                                  "assets/icons/ic_phone_line.svg"),
                              onPress: () {
                                FocusScope.of(context).unfocus();
                                Get.to(MobileNumberScreen(isLogin: true),
                                    duration: const Duration(milliseconds: 400),
                                    transition: Transition.rightToLeft);
                              },
                            ),
                            const SizedBox(height: 10),
                            Platform.isAndroid
                                ? ButtonThem.buildIconButtonWidget(
                                    btnWidthRatio: 1,
                                    context,
                                    title: 'Google'.tr,
                                    btnColor: isDarkMode
                                        ? AppThemeData.grey300Dark
                                        : AppThemeData.grey300,
                                    txtColor: isDarkMode
                                        ? AppThemeData.grey900Dark
                                        : AppThemeData.grey900,
                                    onPress: () {
                                      FocusScope.of(context).unfocus();
                                      controller.loginWithGoogle();
                                    },
                                    iconColor: isDarkMode
                                        ? AppThemeData.grey900Dark
                                        : AppThemeData.grey900,
                                    icon: SvgPicture.asset(
                                        "assets/icons/ic_google.svg"),
                                  )
                                : Row(
                                    children: [
                                      Expanded(
                                        child: ButtonThem.buildIconButtonWidget(
                                          btnWidthRatio: 1,
                                          context,
                                          title: 'Google'.tr,
                                          btnColor: isDarkMode
                                              ? AppThemeData.grey300Dark
                                              : AppThemeData.grey300,
                                          txtColor: isDarkMode
                                              ? AppThemeData.grey900Dark
                                              : AppThemeData.grey900,
                                          onPress: () {
                                            FocusScope.of(context).unfocus();
                                            controller.loginWithGoogle();
                                          },
                                          iconColor: isDarkMode
                                              ? AppThemeData.grey900Dark
                                              : AppThemeData.grey900,
                                          icon: SvgPicture.asset(
                                              "assets/icons/ic_google.svg"),
                                        ),
                                      ),
                                      const SizedBox(width: 10),
                                      Expanded(
                                        child: ButtonThem.buildIconButtonWidget(
                                          btnWidthRatio: 1,
                                          context,
                                          title: 'Apple'.tr,
                                          btnColor: isDarkMode
                                              ? AppThemeData.grey300Dark
                                              : AppThemeData.grey300,
                                          txtColor: isDarkMode
                                              ? AppThemeData.grey900Dark
                                              : AppThemeData.grey900,
                                          iconColor: isDarkMode
                                              ? AppThemeData.grey900Dark
                                              : AppThemeData.grey900,
                                          icon: SvgPicture.asset(
                                              "assets/icons/ic_apple.svg"),
                                          onPress: () {
                                            FocusScope.of(context).unfocus();
                                            controller.loginWithApple();
                                          },
                                        ),
                                      )
                                    ],
                                  ),
                          ],
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.only(bottom: 20),
                        child: Text.rich(
                          textAlign: TextAlign.center,
                          TextSpan(
                            text: 'First time in CabMe?'.tr,
                            style: TextStyle(
                              fontSize: 16,
                              fontFamily: AppThemeData.regular,
                              color: isDarkMode
                                  ? AppThemeData.grey800Dark
                                  : AppThemeData.grey800,
                            ),
                            children: <TextSpan>[
                              TextSpan(
                                text: ' Sign up'.tr,
                                style: TextStyle(
                                  fontFamily: AppThemeData.medium,
                                        color: AppThemeData.secondary200,
                                  decoration: TextDecoration.underline,
                                ),
                                recognizer: TapGestureRecognizer()
                                  ..onTap = () {
                                    // Get.toNamed('/signup');
                                    Get.to(
                                        // MobileNumberScreen(
                                        //   isLogin: false,
                                        // ),
                                      SignupScreen(),
                                        duration:
                                            const Duration(milliseconds: 400),
                                        //duration of transitions, default 1 sec
                                        transition: Transition.rightToLeft);
                                  },
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        });
  }

  showDialogPermission(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => const LocationPermissionDisclosureDialog(),
    );
  }
}