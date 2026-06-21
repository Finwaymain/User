import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:finway/themes/constant_colors.dart';
import 'package:flutter_svg/svg.dart';
import 'package:get/get.dart';
import 'package:provider/provider.dart';
import '../../../constant/constant.dart';
import '../../../constant/image_constant.dart';
import '../../../controller/dash_board_controller.dart';
import '../../../utils/Preferences.dart';
import '../../../utils/dark_theme_provider.dart';
import '../../auth_screens/login_screen.dart';

class CustomDrawer extends StatelessWidget {
  const CustomDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    final bool isLogin = Preferences.getBoolean(Preferences.isLogin) ?? false;
    final themeChange = Provider.of<DarkThemeProvider>(context);
    final dashBoardController = Get.put(DashBoardController());

    var drawerOptions = <Widget>[];
    for (var i = 0; i < dashBoardController.drawerItems.length; i++) {
      var d = dashBoardController.drawerItems[i];
      if (d.title == 'Log Out' && !isLogin) {
        continue;
      }
      drawerOptions.add(InkWell(
        onTap: () {
          dashBoardController.onSelectItem(i, isLogin);
        },
        child: Container(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Visibility(
                visible: d.section != null,
                child: Padding(
                  padding: const EdgeInsets.only(top: 30, bottom: 10, left: 16),
                  child: Text(
                    d.section ?? '',
                    style: TextStyle(
                      color: themeChange.getThem()
                          ? AppThemeData.grey500Dark
                          : AppThemeData.grey300Dark,
                      fontSize: 14,
                      fontFamily: AppThemeData.regular,
                    ),
                  ),
                ),
              ),
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          margin: EdgeInsets.only(
                              top: (d.description != null &&
                                      d.description!.isNotEmpty)
                                  ? 8
                                  : 0),
                          child: SvgPicture.asset(
                            d.icon,
                            width: 24,
                            height: 24,
                            colorFilter: ColorFilter.mode(
                              dashBoardController.drawerItems[i].title ==
                                      dashBoardController
                                          .drawerItems[dashBoardController
                                                  .drawerItems.length -
                                              1]
                                          .title
                                  ? AppThemeData.error200
                                  : dashBoardController
                                              .selectedDrawerIndex.value ==
                                          i
                                      ? AppThemeData.primary200
                                      : themeChange.getThem()
                                          ? AppThemeData.grey900Dark
                                          : AppThemeData.grey900,
                              BlendMode.srcIn,
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Flexible(
                          fit: FlexFit.loose,
                          child: ConstrainedBox(
                            constraints: BoxConstraints(
                                maxWidth:
                                    MediaQuery.of(context).size.width * 0.55),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  d.title,
                                  style: TextStyle(
                                    color: dashBoardController
                                                .drawerItems[i].title ==
                                            dashBoardController
                                                .drawerItems[dashBoardController
                                                        .drawerItems.length -
                                                    1]
                                                .title
                                        ? AppThemeData.error200
                                        : dashBoardController
                                                    .selectedDrawerIndex
                                                    .value ==
                                                i
                                            ? AppThemeData.primary200
                                            : themeChange.getThem()
                                                ? AppThemeData.grey900Dark
                                                : AppThemeData.grey900,
                                    fontSize: 16,
                                    fontFamily: AppThemeData.medium,
                                  ),
                                ),
                                if (d.description != null &&
                                    d.description!.isNotEmpty)
                                  Text(
                                    d.description ?? '',
                                    maxLines: 3,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: themeChange.getThem()
                                          ? AppThemeData.grey400Dark
                                          : AppThemeData.grey400,
                                      fontFamily: AppThemeData.regular,
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                    d.isSwitch == null
                        ? SvgPicture.asset(
                            'assets/icons/ic_right_arrow.svg',
                            width: 20,
                            height: 20,
                            colorFilter: ColorFilter.mode(
                              themeChange.getThem()
                                  ? AppThemeData.grey400Dark
                                  : AppThemeData.grey400,
                              BlendMode.srcIn,
                            ),
                          )
                        : SizedBox(
                            height: 25,
                            child: Switch(
                              trackOutlineColor:
                                  WidgetStateProperty.resolveWith<Color>(
                                      (Set<WidgetState> states) {
                                return Colors.transparent;
                              }),
                              inactiveTrackColor: themeChange.getThem()
                                  ? AppThemeData.grey300Dark
                                  : AppThemeData.grey300,
                              activeTrackColor: AppThemeData.primary200,
                              thumbColor:
                                  WidgetStateProperty.resolveWith<Color>(
                                      (Set<WidgetState> states) {
                                return themeChange.getThem()
                                    ? AppThemeData.grey50
                                    : AppThemeData.grey50Dark;
                              }),
                              value: themeChange.getThem(),
                              onChanged: (value) => (themeChange.darkTheme =
                                  value == true ? 0 : 1),
                            ),
                          ),
                  ],
                ),
              ),
              if ((dashBoardController.drawerItems.length - 2) > i)
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 16),
                  height: 0.5,
                  color: themeChange.getThem()
                      ? AppThemeData.grey200Dark
                      : AppThemeData.grey200,
                )
            ],
          ),
        ),
      ));
    }

    return Drawer(
      child: SingleChildScrollView(
        child: Column(
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    AppThemeData.primary200,
                    AppThemeData.primary200.withValues(alpha: 0.5)
                  ],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomRight,
                ),
              ),
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.only(
                        left: 0, right: 0, top: 50, bottom: 20),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.start,
                      children: [
                        Align(
                          alignment: Alignment.center,
                          child: InkWell(
                            onTap: () {},
                            child: Container(
                              height: 70,
                              width: 70,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(
                                    color: Colors.white,
                                    width: 2), // White circular border
                              ),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(80.0),
                                child: isLogin
                                    ? CachedNetworkImage(
                                        imageUrl: (dashBoardController
                                                    .userModel
                                                    ?.data
                                                    ?.photoPath
                                                    ?.isNotEmpty ??
                                                false)
                                            ? dashBoardController
                                                .userModel!.data!.photoPath!
                                            : Constant.placeholderUrl,
                                        height: double.infinity,
                                        width: double.infinity,
                                        fit: BoxFit.cover,
                                        progressIndicatorBuilder:
                                            (context, url, downloadProgress) =>
                                                Center(
                                          child: CircularProgressIndicator(
                                            value: downloadProgress.progress,
                                          ),
                                        ),
                                        errorWidget: (context, url, error) =>
                                            Image.asset(
                                          ImageConstant.logo,
                                          height: double.infinity,
                                          width: double.infinity,
                                          fit: BoxFit.cover,
                                        ),
                                      )
                                    : Container(
                                        color: Colors.grey[400],
                                        child: const Icon(Icons.person,
                                            size: 50, color: Colors.white),
                                      ),
                              ),
                            ),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.only(left: 10),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.start,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                isLogin
                                    ? "${dashBoardController.userModel?.data?.prenom ?? ''} ${dashBoardController.userModel?.data?.nom ?? ''}"
                                    : "Guest User",
                                style: TextStyle(
                                  color: AppThemeData.surface50,
                                  fontSize: 18,
                                  fontFamily: AppThemeData.regular,
                                ),
                              ),
                              Padding(
                                padding: const EdgeInsets.only(top: 4),
                                child: Text(
                                  isLogin
                                      ? "${(dashBoardController.userModel?.data?.phone ?? 'guest')}@${Constant.appName}.com"
                                          .toLowerCase()
                                      : "guest@${Constant.appName}.com"
                                          .toLowerCase(),
                                  style: TextStyle(
                                    color:
                                        AppThemeData.surface50.withValues(alpha: 0.7),
                                    fontSize: 12,
                                    fontFamily: AppThemeData.regular,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (!isLogin)
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () {
                          if (!isLogin) {
                            Get.to(() => const LoginScreen(),
                                transition: Transition.rightToLeftWithFade);
                          } else {}
                        },
                        style: ElevatedButton.styleFrom(
                          padding: EdgeInsets.zero,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                          ),
                          backgroundColor: Colors.transparent,
                          shadowColor: Colors.transparent,
                        ),
                        child: Ink(
                          decoration: BoxDecoration(
                            color: Colors.white, // Solid white background
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Container(
                            alignment: Alignment.center,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            child: Text(
                              isLogin ? "Sign Out" : "Sign In",
                              style: TextStyle(
                                color: AppThemeData.primary200,
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
            Column(children: drawerOptions),
          ],
        ),
      ),
    );
  }
}
