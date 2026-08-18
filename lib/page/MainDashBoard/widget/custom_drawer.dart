import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:get/get.dart';
import 'package:provider/provider.dart';

import 'package:finway/constant/constant.dart';
import 'package:finway/constant/image_constant.dart';
import 'package:finway/controller/dash_board_controller.dart';
import 'package:finway/controller/subscription_controller.dart';
import 'package:finway/themes/constant_colors.dart';
import 'package:finway/utils/Preferences.dart';
import 'package:finway/utils/dark_theme_provider.dart';
import '../../auth_screens/phone_entry_screen.dart';
import '../../subscription_plan_screen/subscription_plan_screen.dart' as subs;

class CustomDrawer extends StatelessWidget {
  const CustomDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    final bool isLogin = Preferences.getBoolean(Preferences.isLogin) ?? false;
    final themeChange = Provider.of<DarkThemeProvider>(context);
    final bool isDark = themeChange.getThem();
    final dashBoardController = Get.put(DashBoardController());

    // Refresh user data
    dashBoardController.getUsrData();

    var drawerOptions = <Widget>[];
    for (var i = 0; i < dashBoardController.drawerItems.length; i++) {
      var d = dashBoardController.drawerItems[i];
      if (d.title == 'Log Out' && !isLogin) {
        continue;
      }
      final bool isLogout = d.title == 'Log Out' ||
          (i == dashBoardController.drawerItems.length - 1 && d.title.toLowerCase().contains('log out'));

      drawerOptions.add(Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (d.section != null && d.section!.isNotEmpty) ...[
            Padding(
              padding: const EdgeInsets.only(top: 20, bottom: 6, left: 16, right: 16),
              child: Text(
                d.section!.toUpperCase(),
                style: TextStyle(
                  color: isDark ? AppThemeData.grey400Dark : AppThemeData.grey500,
                  fontSize: 11,
                  fontFamily: AppThemeData.bold,
                  letterSpacing: 1,
                ),
              ),
            ),
          ],
          InkWell(
            onTap: () {
              if (d.isSwitch == true) {
                themeChange.darkTheme = isDark ? 1 : 0;
              } else {
                dashBoardController.onSelectItem(i, isLogin);
              }
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Row(
                      children: [
                        SvgPicture.asset(
                          d.icon,
                          width: 20,
                          height: 20,
                          colorFilter: ColorFilter.mode(
                            isLogout
                                ? AppThemeData.error200
                                : dashBoardController.selectedDrawerIndex.value == i
                                    ? AppThemeData.primary200
                                    : isDark
                                        ? AppThemeData.grey400Dark
                                        : AppThemeData.grey400,
                            BlendMode.srcIn,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Text(
                            d.title,
                            style: TextStyle(
                              color: isLogout
                                  ? AppThemeData.error200
                                  : dashBoardController.selectedDrawerIndex.value == i
                                      ? AppThemeData.primary200
                                      : isDark
                                          ? AppThemeData.grey900Dark
                                          : AppThemeData.grey900,
                              fontSize: 15,
                              fontFamily: AppThemeData.medium,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (d.isSwitch == true)
                    SizedBox(
                      height: 25,
                      child: Switch.adaptive(
                        value: isDark,
                        activeColor: AppThemeData.primary200,
                        onChanged: (bool val) {
                          themeChange.darkTheme = val ? 0 : 1;
                        },
                      ),
                    )
                  else
                    SvgPicture.asset(
                      'assets/icons/ic_right_arrow.svg',
                      width: 18,
                      height: 18,
                      colorFilter: ColorFilter.mode(
                        isDark ? AppThemeData.grey400Dark : AppThemeData.grey400,
                        BlendMode.srcIn,
                      ),
                    ),
                ],
              ),
            ),
          ),
        ],
      ));
    }

    return Drawer(
      child: SingleChildScrollView(
        child: Column(
          children: [
            // Drawer Header
            Container(
              width: double.infinity,
              padding: const EdgeInsets.only(left: 16, right: 16, top: 50, bottom: 20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    AppThemeData.primary200,
                    AppThemeData.primary200.withValues(alpha: 0.8),
                  ],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomRight,
                ),
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      Container(
                        height: 60,
                        width: 60,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 2),
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(60.0),
                          child: isLogin
                              ? CachedNetworkImage(
                                  imageUrl: (dashBoardController.userModel.value?.data?.photoPath?.isNotEmpty == true)
                                      ? dashBoardController.userModel.value!.data!.photoPath!
                                      : (Constant.placeholderUrl ?? ''),
                                  height: double.infinity,
                                  width: double.infinity,
                                  fit: BoxFit.cover,
                                  errorWidget: (context, url, error) => Image.asset(
                                    ImageConstant.logo,
                                    height: double.infinity,
                                    width: double.infinity,
                                    fit: BoxFit.cover,
                                  ),
                                )
                              : Container(
                                  color: Colors.grey[400],
                                  child: const Icon(Icons.person, size: 40, color: Colors.white),
                                ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              isLogin
                                  ? "${dashBoardController.userModel.value?.data?.prenom ?? ''} ${dashBoardController.userModel.value?.data?.nom ?? ''}".trim().isEmpty
                                      ? "User"
                                      : "${dashBoardController.userModel.value?.data?.prenom ?? ''} ${dashBoardController.userModel.value?.data?.nom ?? ''}"
                                  : "Guest User",
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: AppThemeData.surface50,
                                fontSize: 16,
                                fontFamily: AppThemeData.bold,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              isLogin
                                  ? "${(dashBoardController.userModel.value?.data?.phone ?? 'user')}@${Constant.appName ?? 'fiinway'}.com".toLowerCase()
                                  : "guest@fiinway.com",
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: AppThemeData.surface50.withValues(alpha: 0.8),
                                fontSize: 11,
                                fontFamily: AppThemeData.regular,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  if (!isLogin) ...[
                    const SizedBox(height: 14),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () {
                          Get.to(() => const PhoneEntryScreen(), transition: Transition.rightToLeftWithFade);
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: AppThemeData.primary200,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 10),
                        ),
                        child: Text(
                          "Sign In",
                          style: TextStyle(
                            color: AppThemeData.primary200,
                            fontSize: 14,
                            fontFamily: AppThemeData.bold,
                          ),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),

            // Subscription / Membership Plan Card
            GestureDetector(
              onTap: () {
                Get.back(); // close drawer
                Get.delete<SubscriptionController>();
                Get.to(() => const subs.SubscriptionPlanScreen(isbackButton: true));
              },
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF1E293B) : Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppThemeData.primary200, width: 1.5),
                  boxShadow: [
                    BoxShadow(
                      color: AppThemeData.primary200.withValues(alpha: 0.12),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Obx(() => Row(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: (dashBoardController.userModel.value?.data?.consumerPlan?.image?.isNotEmpty == true)
                          ? CachedNetworkImage(
                              imageUrl: dashBoardController.userModel.value!.data!.consumerPlan!.image!,
                              width: 36,
                              height: 36,
                              fit: BoxFit.cover,
                              errorWidget: (context, url, error) => Container(
                                padding: const EdgeInsets.all(6),
                                decoration: BoxDecoration(
                                  color: AppThemeData.primary200.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Icon(Icons.card_membership_rounded, color: AppThemeData.primary200, size: 24),
                              ),
                            )
                          : Container(
                              padding: const EdgeInsets.all(6),
                              decoration: BoxDecoration(
                                color: AppThemeData.primary200.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Icon(Icons.card_membership_rounded, color: AppThemeData.primary200, size: 24),
                            ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            dashBoardController.userModel.value?.data?.consumerPlan?.name ?? 'Standard Plan',
                            style: TextStyle(
                              color: isDark ? Colors.white : AppThemeData.grey900,
                              fontSize: 14,
                              fontFamily: AppThemeData.bold,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'View membership & change plan',
                            style: TextStyle(
                              color: isDark ? AppThemeData.grey400Dark : AppThemeData.grey500,
                              fontSize: 11,
                              fontFamily: AppThemeData.regular,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Icon(Icons.arrow_forward_ios_rounded, color: AppThemeData.primary200, size: 14),
                  ],
                )),
              ),
            ),

            const Divider(height: 1),

            Column(children: drawerOptions),

            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}
