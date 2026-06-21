import 'package:finway/constant/constant.dart';
import 'package:finway/controller/dash_board_controller.dart';
import 'package:finway/themes/constant_colors.dart';
import 'package:finway/themes/responsive.dart';
import 'package:finway/utils/dark_theme_provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:get/get.dart';
import 'package:provider/provider.dart';
import '../../../constant/image_constant.dart';
import 'texi_home_screens/texi_home_osm_screen.dart';
import 'texi_home_screens/texi_home_screen.dart';

class TexiDashboard extends StatelessWidget {
  TexiDashboard({super.key});

  DateTime backPress = DateTime.now();

  @override
  Widget build(BuildContext context) {
    return GetBuilder<DashBoardController>(
      init: DashBoardController(),
      builder: (controller) {
        controller.getDrawerItems();
        return Scaffold(
          body: (Constant.selectedMapType == 'osm' &&
                  controller.selectedDrawerIndex.value == 0)
              ? const TexiHomeOSMScreen()
              : const TexiHomeScreen(),
          // ),
        );
      },
    );
  }
}

buildAppDrawer(BuildContext context, DashBoardController controller) {
  final themeChange = Provider.of<DarkThemeProvider>(context);

  var drawerOptions = <Widget>[];
  for (var i = 0; i < controller.drawerTexiItems.length; i++) {
    var d = controller.drawerTexiItems[i];
    drawerOptions.add(InkWell(
      onTap: () {
        controller.onTexiSelectItem(i);
      },
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
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(mainAxisAlignment: MainAxisAlignment.start, children: [
                  SvgPicture.asset(
                    d.icon,
                    width: 24,
                    height: 24,
                    colorFilter: ColorFilter.mode(
                      controller.drawerItems[i].title ==
                              controller
                                  .drawerItems[
                                      controller.drawerItems.length - 1]
                                  .title
                          ? AppThemeData.error200
                          : controller.selectedDrawerIndex.value == i
                              ? AppThemeData.primary200
                              : themeChange.getThem()
                                  ? AppThemeData.grey900Dark
                                  : AppThemeData.grey900,
                      BlendMode.srcIn,
                    ),
                  ),
                  const SizedBox(
                    width: 16,
                  ),
                  Text(
                    d.title,
                    style: TextStyle(
                      color: controller.drawerItems[i].title ==
                              controller
                                  .drawerItems[
                                      controller.drawerItems.length - 1]
                                  .title
                          ? AppThemeData.error200
                          : controller.selectedDrawerIndex.value == i
                              ? AppThemeData.primary200
                              : themeChange.getThem()
                                  ? AppThemeData.grey900Dark
                                  : AppThemeData.grey900,
                      fontSize: 16,
                      fontFamily: AppThemeData.medium,
                    ),
                  ),
                ]),
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
                          thumbColor: WidgetStateProperty.resolveWith<Color>(
                              (Set<WidgetState> states) {
                            return themeChange.getThem()
                                ? AppThemeData.grey50
                                : AppThemeData.grey50Dark;
                          }),
                          value: themeChange.getThem(),
                          onChanged: (value) =>
                              (themeChange.darkTheme = value == true ? 0 : 1),
                        ),
                      ),
              ],
            ),
          ),
          if ((controller.drawerItems.length - 2) > i)
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16),
              height: 0.5,
              color: themeChange.getThem()
                  ? AppThemeData.grey200Dark
                  : AppThemeData.grey200,
            )
        ],
      ),
    ));
  }
  return Drawer(
    width: Responsive.width(85, context),
    backgroundColor: themeChange.getThem()
        ? AppThemeData.surface50Dark
        : AppThemeData.surface50,
    child: ListView(
      children: [
        // Row(
        //   mainAxisAlignment: MainAxisAlignment.start,
        //   children: [
        //     IconButton(
        //       onPressed: () {
        //        Scaffold.of(context).closeDrawer();
        //       },
        //       icon: SvgPicture.asset(
        //         'assets/icons/ic_back_arrow.svg',
        //         colorFilter: ColorFilter.mode(
        //           themeChange.getThem() ? AppThemeData.grey900Dark : AppThemeData.grey900,
        //           BlendMode.srcIn,
        //         ),
        //       ),
        //     ),
        //   ],
        // ),
        const SizedBox(height: 40),
        Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Align(
              alignment: Alignment.center,
              child: InkWell(
                onTap: () {},
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(80.0),
                  child: controller.userModel?.data?.photoPath?.isEmpty == true
                      ? CachedNetworkImage(
                          imageUrl: Constant.placeholderUrl,
                          height: 120,
                          width: 120,
                          fit: BoxFit.cover,
                          progressIndicatorBuilder:
                              (context, url, downloadProgress) => Center(
                            child: CircularProgressIndicator(
                                value: downloadProgress.progress),
                          ),
                          errorWidget: (context, url, error) => Image.asset(
                            ImageConstant.logo,
                          ),
                        )
                      : CachedNetworkImage(
                          imageUrl: controller.userModel?.data?.photoPath ?? '',
                          height: 120,
                          width: 120,
                          fit: BoxFit.cover,
                          progressIndicatorBuilder:
                              (context, url, downloadProgress) => Center(
                            child: CircularProgressIndicator(
                                value: downloadProgress.progress),
                          ),
                          errorWidget: (context, url, error) => Image.asset(
                            ImageConstant.logo,
                          ),
                        ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(top: 20),
              child: Text(
                "${controller.userModel!.data!.prenom} ${controller.userModel!.data!.nom}",
                style: TextStyle(
                  color: themeChange.getThem()
                      ? AppThemeData.grey900Dark
                      : AppThemeData.grey900,
                  fontSize: 22,
                  fontFamily: AppThemeData.regular,
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(
                '${controller.userModel!.data!.email}',
                style: TextStyle(
                  color: themeChange.getThem()
                      ? AppThemeData.grey500Dark
                      : AppThemeData.grey500,
                  fontSize: 14,
                  fontFamily: AppThemeData.regular,
                ),
              ),
            )
          ],
        ),
        const SizedBox(height: 30),
        Column(children: drawerOptions),
      ],
    ),
  );
}

class DrawerItem {
  String? title;
  String? description;
  String? icon;
  String? section;
  bool? isSwitch;

  DrawerItem({required this.title,required this.description,required this.icon, this.section, this.isSwitch});
}
