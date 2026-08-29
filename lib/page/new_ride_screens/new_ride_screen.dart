import 'package:finway/constant/constant.dart';
import 'package:finway/constant/show_toast_dialog.dart';
import 'package:finway/controller/new_ride_controller.dart';
import 'package:finway/model/ride_model.dart';
import 'package:finway/page/complaint/add_complaint_screen.dart';
import 'package:finway/page/completed_ride_screens/payment_selection_screen.dart';
import 'package:finway/page/completed_ride_screens/trip_history_screen.dart';
import 'package:finway/page/route_view_screen/route_view_screen.dart';
import 'package:finway/page/route_view_screen/route_osm_view_screen.dart';
import 'package:finway/page/review_screens/add_review_screen.dart';
import 'package:finway/themes/appbar_cust.dart';
import 'package:finway/themes/button_them.dart';
import 'package:finway/themes/constant_colors.dart';
import 'package:finway/themes/responsive.dart';
import 'package:finway/utils/dark_theme_provider.dart';
import 'package:finway/widget/StarRating.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:get/get.dart';
import 'package:location/location.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:text_scroll/text_scroll.dart';

import '../../constant/image_constant.dart';

class NewRideScreen extends StatelessWidget {
  const NewRideScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final themeChange = Provider.of<DarkThemeProvider>(context);
    return GetBuilder<NewRideController>(
      init: NewRideController(),
      builder: (controller) {
        return Scaffold(
            appBar: CustomAppbar(
              bgColor: AppThemeData.primary200,
              title: 'All Rides'.tr,
            ),
            body: Stack(
              children: [
                Column(
                  children: [
                    Expanded(
                      flex: 1,
                      child: Container(
                        color: AppThemeData.primary200,
                      ),
                    ),
                    Expanded(
                        flex: 10,
                        child: Container(
                          color: themeChange.getThem() ? AppThemeData.surface50Dark : AppThemeData.surface50,
                        )),
                  ],
                ),
                SafeArea(
                  child: Column(
                    children: [
                      const SizedBox(height: 20),
                      Expanded(
                        child: Container(
                          margin: const EdgeInsets.symmetric(horizontal: 16),
                          height: Responsive.height(70, context),
                          color: themeChange.getThem() ? AppThemeData.surface50Dark : AppThemeData.surface50,
                          child: Theme(
                            data: ThemeData(
                              tabBarTheme: TabBarThemeData(
                                indicatorColor: AppThemeData.primary200,
                              ),
                            ),
                            child: DefaultTabController(
                              length: 3,
                              child: Column(children: [
                                TabBar(
                                  isScrollable: false,
                                  indicatorSize: TabBarIndicatorSize.tab,
                                  indicatorColor: AppThemeData.primary200,
                                  indicatorWeight: 0.1,
                                  labelPadding: const EdgeInsets.symmetric(vertical: 8),
                                  dividerColor: Colors.transparent,
                                  labelColor: AppThemeData.primary200,
                                  automaticIndicatorColorAdjustment: true,
                                  labelStyle: TextStyle(fontFamily: AppThemeData.medium, fontSize: 16, color: AppThemeData.primary200),
                                  unselectedLabelStyle:
                                      TextStyle(fontFamily: AppThemeData.regular, fontSize: 16, color: themeChange.getThem() ? AppThemeData.grey300Dark : AppThemeData.grey400),
                                  tabs: [
                                    Tab(
                                      text: 'New'.tr,
                                    ),
                                    Tab(
                                      text: 'Completed'.tr,
                                    ),
                                    Tab(
                                      text: 'Rejected'.tr,
                                    ),
                                  ],
                                ),
                                Expanded(
                                   child: TabBarView(children: [
                                    SizedBox(
                                      child: RefreshIndicator(
                                        backgroundColor: AppThemeData.primary200,
                                        onRefresh: () => controller.getNewRide(isinit: true),
                                        child: controller.isLoading.value
                                            ? SizedBox() //Constant.loader(context)
                                            : controller.newRideList.isEmpty
                                                ? Constant.emptyView(context, "You have not booked any trip.\n Please book a cab now", true)
                                                : ListView.builder(
                                                    controller: controller.scrollControllerNew,
                                                    itemCount: controller.newRideList.length + (controller.isLoadMoreRunning.value ? 1 : 0),
                                                    shrinkWrap: false,
                                                    physics: const AlwaysScrollableScrollPhysics(),
                                                    itemBuilder: (context, index) {
                                                      if (index == controller.newRideList.length) {
                                                        return Center(
                                                          child: Padding(
                                                            padding: const EdgeInsets.all(8.0),
                                                            child: CircularProgressIndicator(color: AppThemeData.primary200),
                                                          ),
                                                        );
                                                      }
                                                      return Padding(
                                                        padding: const EdgeInsets.only(top: 24),
                                                        child: newRideWidgets(controller, context, controller.newRideList[index]),
                                                      );
                                                    }),
                                      ),
                                    ),
                                    SizedBox(
                                      child: RefreshIndicator(
                                        backgroundColor: AppThemeData.primary200,
                                        color: themeChange.getThem() ? AppThemeData.grey900Dark : AppThemeData.grey900,
                                        onRefresh: () => controller.getNewRide(isinit: true),
                                        child: controller.isLoading.value
                                            ? SizedBox()
                                            : controller.completedRideList.isEmpty
                                                ? Constant.emptyView(context, "You have not completed any trip.", false)
                                                : ListView.builder(
                                                    controller: controller.scrollControllerCompleted,
                                                    itemCount: controller.completedRideList.length + (controller.isLoadMoreRunning.value ? 1 : 0),
                                                    shrinkWrap: false,
                                                    physics: const AlwaysScrollableScrollPhysics(),
                                                    itemBuilder: (context, index) {
                                                      if (index == controller.completedRideList.length) {
                                                        return Center(
                                                          child: Padding(
                                                            padding: const EdgeInsets.all(8.0),
                                                            child: CircularProgressIndicator(color: AppThemeData.primary200),
                                                          ),
                                                        );
                                                      }
                                                      return Padding(
                                                        padding: const EdgeInsets.only(top: 24),
                                                        child: newRideWidgets(controller, context, controller.completedRideList[index]),
                                                      );
                                                    }),
                                      ),
                                    ),
                                    SizedBox(
                                      child: RefreshIndicator(
                                        backgroundColor: AppThemeData.primary200,
                                        onRefresh: () => controller.getNewRide(isinit: true),
                                        child: controller.isLoading.value
                                            ? SizedBox()
                                            : controller.rejectedRideList.isEmpty
                                                ? Constant.emptyView(context, "You have not rejected any trip.", false)
                                                : ListView.builder(
                                                    controller: controller.scrollControllerRejected,
                                                    itemCount: controller.rejectedRideList.length + (controller.isLoadMoreRunning.value ? 1 : 0),
                                                    shrinkWrap: false,
                                                    physics: const AlwaysScrollableScrollPhysics(),
                                                    itemBuilder: (context, index) {
                                                      if (index == controller.rejectedRideList.length) {
                                                        return Center(
                                                          child: Padding(
                                                            padding: const EdgeInsets.all(8.0),
                                                            child: CircularProgressIndicator(color: AppThemeData.primary200),
                                                          ),
                                                        );
                                                      }
                                                      return Padding(
                                                        padding: const EdgeInsets.only(top: 24),
                                                        child: newRideWidgets(controller, context, controller.rejectedRideList[index]),
                                                      );
                                                    }),
                                      ),
                                    ),
                                  ]),
                                )
                              ]),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ));
      },
    );
  }

  Widget newRideWidgets(NewRideController controller, BuildContext context, RideData data) {
    final themeChange = Provider.of<DarkThemeProvider>(context);
    return InkWell(
      onTap: () async {
        if (data.statut == 'completed' && data.statutPaiement != 'yes') {
          await Get.to(() => PaymentSelectionScreen(), arguments: {
            "rideData": data,
          })?.then((v) {
            controller.getNewRide();
          });
        } else if (data.statut == 'confirmed' || data.statut == 'on ride') {
          var argumentData = {'type': data.statut.toString(), 'data': data};
          if (Constant.selectedMapType == 'osm') {
            await Get.to(() => const RouteOsmViewScreen(), arguments: argumentData)?.then((v) {
              controller.getNewRide();
            });
          } else {
            await Get.to(() => const RouteViewScreen(), arguments: argumentData)?.then((v) {
              controller.getNewRide();
            });
          }
        } else {
          await Get.to(() => TripHistoryScreen(), arguments: {
            "rideData": data,
          })?.then((v) {
            controller.getNewRide();
          });
        }
      },
      child: Container(
        decoration: BoxDecoration(
            border: Border.all(
          color: themeChange.getThem() ? AppThemeData.grey200Dark : AppThemeData.grey200,
        )),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Column(
                      children: [
                        SvgPicture.asset(
                          'assets/icons/ic_location.svg',
                          colorFilter: ColorFilter.mode(
                            AppThemeData.success300,
                            BlendMode.srcIn,
                          ),
                        ),
                        Container(
                          width: 2,
                          height: 30,
                          color: themeChange.getThem() ? AppThemeData.grey200Dark : AppThemeData.grey200,
                        )
                      ],
                    ),
                    const SizedBox(
                      width: 5,
                    ),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            data.departName.toString(),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 14,
                              fontFamily: AppThemeData.regular,
                              color: themeChange.getThem() ? AppThemeData.grey400 : AppThemeData.grey300Dark,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Divider(),
                    Align(
                      alignment: Alignment.topRight,
                      child: data.statut == "new"
                          ? statusTile(title: 'New', bgColor: AppThemeData.primary50.withAlpha(200), txtColor: AppThemeData.primary200)
                          : data.statut == "on ride"
                              ? statusTile(title: 'Active', bgColor: AppThemeData.primary50.withAlpha(200), txtColor: AppThemeData.primary200)
                              : data.statut == "confirmed"
                                  ? statusTile(title: 'Confirmed', bgColor: AppThemeData.primary50.withAlpha(200), txtColor: AppThemeData.primary200)
                                  : data.statut == "completed"
                                      ? statusTile(title: 'Completed', bgColor: AppThemeData.success50.withAlpha(200), txtColor: AppThemeData.success300)
                                      : statusTile(title: 'Rejected', bgColor: AppThemeData.error50.withAlpha(200), txtColor: AppThemeData.error200),
                    ),
                  ],
                ),
                ListView.builder(
                    padding: EdgeInsets.zero,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: data.stops!.length,
                    itemBuilder: (context, int index) {
                      return Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 7),
                            child: Column(
                              children: [
                                Text(
                                  String.fromCharCode(index + 65),
                                  style: const TextStyle(
                                    fontSize: 16,
                                  ),
                                ),
                                Container(
                                  width: 2,
                                  height: 30,
                                  color: themeChange.getThem() ? AppThemeData.grey200Dark : AppThemeData.grey200,
                                )
                              ],
                            ),
                          ),
                          const SizedBox(
                            width: 5,
                          ),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  data.stops![index].location.toString(),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontFamily: AppThemeData.regular,
                                    color: themeChange.getThem() ? AppThemeData.grey400 : AppThemeData.grey300Dark,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      );
                    }),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: [
                    SvgPicture.asset(
                      'assets/icons/ic_location.svg',
                      colorFilter: ColorFilter.mode(
                        AppThemeData.warning200,
                        BlendMode.srcIn,
                      ),
                    ),
                    const SizedBox(
                      width: 5,
                    ),
                    Expanded(
                      child: Text(
                        data.destinationName.toString(),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 14,
                          fontFamily: AppThemeData.regular,
                          color: themeChange.getThem() ? AppThemeData.grey400 : AppThemeData.grey300Dark,
                        ),
                      ),
                    ),
                  ],
                ),
              ]),
            ),
            (data.statut == "confirmed" && Constant.rideOtp.toString().toLowerCase() == 'yes'.toLowerCase() && data.rideType != 'driver') == true
                ? Column(
                    children: [
                      Divider(
                        color: themeChange.getThem() ? AppThemeData.grey200Dark : AppThemeData.grey200,
                        thickness: 1,
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        child: Row(
                          children: [
                            Text(
                              'OTP : '.tr,
                              style: TextStyle(
                                fontFamily: AppThemeData.medium,
                                color: themeChange.getThem() ? AppThemeData.grey400 : AppThemeData.grey300Dark,
                                fontSize: 14,
                              ),
                            ),
                            Text(
                              data.otp.toString(),
                              style: TextStyle(
                                letterSpacing: 1.2,
                                fontFamily: AppThemeData.semiBold,
                                color: themeChange.getThem() ? AppThemeData.grey900Dark : AppThemeData.grey900,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Divider(
                        color: themeChange.getThem() ? AppThemeData.grey200Dark : AppThemeData.grey200,
                        thickness: 1,
                      ),
                    ],
                  )
                : Container(
                    height: 1,
                    color: themeChange.getThem() ? AppThemeData.grey200Dark : AppThemeData.grey200,
                  ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Expanded(
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          TextScroll("${double.parse(data.distance.toString()).toStringAsFixed(int.parse(Constant.decimal!))} ${data.distanceUnit}",
                              mode: TextScrollMode.bouncing,
                              pauseBetween: const Duration(seconds: 2),
                              style: TextStyle(
                                fontFamily: AppThemeData.semiBold,
                                color: AppThemeData.primary200,
                                fontSize: 18,
                              )),
                          const SizedBox(
                            height: 2,
                          ),
                          Text('Distance'.tr,
                              maxLines: 1,
                              style: TextStyle(
                                fontFamily: AppThemeData.regular,
                                color: themeChange.getThem() ? AppThemeData.grey900Dark : AppThemeData.grey900,
                                fontSize: 12,
                              )),
                        ],
                      ),
                    ),
                  ),
                  Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(data.numberPoeple.toString().padLeft(2, '0'),
                            style: TextStyle(
                              fontFamily: AppThemeData.semiBold,
                              color: AppThemeData.primary200,
                              fontSize: 18,
                            )),
                        const SizedBox(
                          height: 2,
                        ),
                        Text("Passangers".tr,
                            style: TextStyle(
                              fontFamily: AppThemeData.regular,
                              color: themeChange.getThem() ? AppThemeData.grey900Dark : AppThemeData.grey900,
                              fontSize: 12,
                            )),
                      ],
                    ),
                  ),
                  Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        TextScroll(data.duree.toString(),
                            mode: TextScrollMode.bouncing,
                            pauseBetween: const Duration(seconds: 2),
                            style: TextStyle(
                              fontFamily: AppThemeData.semiBold,
                              color: AppThemeData.primary200,
                              fontSize: 18,
                            )),
                        const SizedBox(
                          height: 2,
                        ),
                        Text('Duration'.tr,
                            maxLines: 1,
                            style: TextStyle(
                              fontFamily: AppThemeData.regular,
                              color: themeChange.getThem() ? AppThemeData.grey900Dark : AppThemeData.grey900,
                              fontSize: 12,
                            )),
                      ],
                    ),
                  ),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(Constant().amountShow(amount: data.montant.toString()),
                              maxLines: 1,
                              style: TextStyle(
                                fontFamily: AppThemeData.semiBold,
                                color: AppThemeData.primary200,
                                fontSize: 18,
                              )),
                          const SizedBox(
                            height: 2,
                          ),
                          Text("Trip Price".tr,
                              style: TextStyle(
                                fontFamily: AppThemeData.regular,
                                color: themeChange.getThem() ? AppThemeData.grey900Dark : AppThemeData.grey900,
                                fontSize: 12,
                              )),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: data.statut == "new"
                  ? Row(
                      children: [
                        SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(AppThemeData.primary200),
                          ),
                        ),
                        const SizedBox(width: 15),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                "Looking for nearby drivers...".tr,
                                style: TextStyle(
                                  fontFamily: AppThemeData.semiBold,
                                  color: themeChange.getThem() ? AppThemeData.grey900Dark : AppThemeData.grey900,
                                  fontSize: 15,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                "Notifying all drivers in your area".tr,
                                style: TextStyle(
                                  fontFamily: AppThemeData.regular,
                                  color: themeChange.getThem() ? AppThemeData.grey400 : AppThemeData.grey400,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Visibility(
                          visible: true,
                          child: Padding(
                            padding: const EdgeInsets.only(left: 10),
                            child: InkWell(
                                onTap: () async {
                                  ShowToastDialog.showLoader("Please wait");
                                  final Location currentLocation = Location();
                                  LocationData location = await currentLocation.getLocation();
                                  ShowToastDialog.closeLoader();
                                  await Share.share(
                                    'https://www.google.com/maps/search/?api=1&query=${location.latitude},${location.longitude}',
                                    subject: "Cabme".tr,
                                  );
                                },
                                child: Container(
                                  alignment: Alignment.center,
                                  height: 44,
                                  width: 44,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: AppThemeData.secondary200,
                                  ),
                                  child: SvgPicture.asset(
                                    'assets/icons/ic_share.svg',
                                    height: 20,
                                    width: 20,
                                    colorFilter: ColorFilter.mode(
                                      themeChange.getThem() ? AppThemeData.surface50Dark : AppThemeData.surface50,
                                      BlendMode.srcIn,
                                    ),
                                  ),
                                )),
                          ),
                        ),
                      ],
                    )
                  : Row(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(80),
                          child: CachedNetworkImage(
                            imageUrl: data.photoPath.toString(),
                            height: 60,
                            width: 60,
                            fit: BoxFit.cover,
                            placeholder: (context, url) => Constant.loader(context),
                            errorWidget: (context, url, error) => Image.asset(
                              ImageConstant.logo,
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text("${data.prenomConducteur} ${data.nomConducteur}",
                                  style: TextStyle(
                                    fontFamily: AppThemeData.semiBold,
                                    color: themeChange.getThem() ? AppThemeData.grey900Dark : AppThemeData.grey900,
                                    fontSize: 16,
                                    letterSpacing: 0.6,
                                  )),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.start,
                                children: [
                                  StarRating(
                                    size: 20,
                                    rating: data.moyenne != "null" ? double.parse(data.moyenne.toString()) : 0.0,
                                    color: AppThemeData.warning200,
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Row(
                              children: [
                                Row(
                                  children: [
                                    Visibility(
                                        visible: data.statut == "on ride" || data.statut == "confirmed",
                                        child: Padding(
                                          padding: const EdgeInsets.only(left: 10),
                                          child: InkWell(
                                              onTap: () async {
                                                ShowToastDialog.showLoader("Please wait");
                                                final Location currentLocation = Location();
                                                LocationData location = await currentLocation.getLocation();
                                                ShowToastDialog.closeLoader();
                                                await Share.share(
                                                  'https://www.google.com/maps/search/?api=1&query=${location.latitude},${location.longitude}',
                                                  subject: "Cabme".tr,
                                                );
                                              },
                                              child: Container(
                                                alignment: Alignment.center,
                                                height: 44,
                                                width: 44,
                                                decoration: BoxDecoration(
                                                  shape: BoxShape.circle,
                                                  color: AppThemeData.secondary200,
                                                ),
                                                child: SvgPicture.asset(
                                                  'assets/icons/ic_share.svg',
                                                  height: 20,
                                                  width: 20,
                                                  colorFilter: ColorFilter.mode(
                                                    themeChange.getThem() ? AppThemeData.surface50Dark : AppThemeData.surface50,
                                                    BlendMode.srcIn,
                                                  ),
                                                ),
                                              )),
                                        )),
                                  ],
                                ),
                                Visibility(
                                    visible: data.statut == "completed" || data.statut == "rejected",
                                    child: ButtonThem.buildIconButton(
                                      btnWidthRatio: 0.3,
                                      radius: 50,
                                      btnHeight: 50,
                                      context,
                                      title: 'Ratings'.tr,
                                      btnColor: AppThemeData.info200,
                                      txtColor: AppThemeData.grey900,
                                      iconColor: AppThemeData.grey900,
                                      iconSize: 18.0,
                                      txtSize: 14,
                                      icon: Icons.add,
                                      onPress: () async {
                                        Get.to(const AddReviewScreen(), arguments: {
                                          "data": data,
                                          "ride_type": "ride",
                                        })!
                                            .then((value) {
                                          controller.getNewRide();
                                        });
                                      },
                                    )),
                                Visibility(
                                  visible: data.statut == "on ride" || data.statut == "confirmed",
                                  child: Row(
                                    children: [
                                      Padding(
                                        padding: const EdgeInsets.only(left: 10),
                                        child: InkWell(
                                            onTap: () {
                                              Constant.makePhoneCall(data.driverPhone.toString());
                                            },
                                            child: Container(
                                              alignment: Alignment.center,
                                              height: 44,
                                              width: 44,
                                              decoration: BoxDecoration(
                                                shape: BoxShape.circle,
                                                color: AppThemeData.warning200,
                                              ),
                                              child: SvgPicture.asset(
                                                'assets/icons/call_icon.svg',
                                                height: 20,
                                                width: 20,
                                                colorFilter: ColorFilter.mode(
                                                  themeChange.getThem() ? AppThemeData.surface50Dark : AppThemeData.surface50,
                                                  BlendMode.srcIn,
                                                ),
                                              ),
                                            )),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ],
                    ),
            ),
            const SizedBox(height: 20),
            Visibility(
              visible: data.statut == "completed",
              child: ButtonThem.buildBorderButton(
                btnHeight: 50,
                context,
                title: 'Add Complaint'.tr,
                btnColor: themeChange.getSystemThem() ? Colors.transparent : AppThemeData.surface50,
                txtColor: AppThemeData.primary200,
                btnBorderColor: AppThemeData.primary200,
                onPress: () async {
                  Get.to(AddComplaintScreen(), arguments: {
                    "data": data,
                    "ride_type": "ride",
                  })!
                      .then((value) {
                    controller.getNewRide();
                  });
                },
              ),
            ),
            Visibility(
              visible: data.statut == "completed" && data.statutPaiement != "yes",
              child: Padding(
                padding: const EdgeInsets.only(
                  top: 5.0,
                ),
                child: Row(
                  children: [
                    Expanded(
                        child: ButtonThem.buildButton(context,
                            btnHeight: 50,
                            title: "Pay Now".tr,
                            btnColor: AppThemeData.primary200,
                            txtColor: Colors.white, onPress: () async {
                      await Get.to(() => PaymentSelectionScreen(), arguments: {
                        "rideData": data,
                      })?.then((v) {
                        controller.getNewRide();
                      });
                    })),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget statusTile({required String title, Color? bgColor, Color? txtColor}) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(4),
        color: bgColor,
      ),
      alignment: Alignment.center,
      height: 32,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8),
        child: Text(
          title.tr,
          style: TextStyle(fontSize: 14, color: txtColor, fontFamily: AppThemeData.medium),
        ),
      ),
    );
  }
}
