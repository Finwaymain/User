import 'package:finway/constant/constant.dart';
import 'package:finway/model/parcel_model.dart';
import 'package:finway/page/parcel_service_screen/all_parcel_screen.dart';
import 'package:finway/page/parcel_service_screen/parcel_route_osm_view_screen.dart';
import 'package:finway/page/parcel_service_screen/parcel_route_view_screen.dart';
import 'package:finway/themes/button_them.dart';
import 'package:finway/themes/constant_colors.dart';
import 'package:finway/themes/responsive.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:get/get.dart';

class ParcelSuccessScreen extends StatelessWidget {
  final ParcelData? parcelData;
  const ParcelSuccessScreen({super.key, this.parcelData});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
          backgroundColor: AppThemeData.pink2,
          leading: IconButton(
              onPressed: () {
                Get.offAll(const AllParcelScreen());
              },
              icon: Transform(
                alignment: Alignment.center,
                transform: Directionality.of(context) == TextDirection.rtl ? Matrix4.rotationY(3.14159) : Matrix4.identity(),
                child: SvgPicture.asset(
                  'assets/icons/ic_left.svg',
                  width: 30,
                  height: 30,
                  colorFilter: ColorFilter.mode(
                    AppThemeData.grey900,
                    BlendMode.srcIn,
                  ),
                ),
              ))),
      body: SafeArea(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 30.0),
          width: double.infinity,
          decoration: BoxDecoration(
            color: AppThemeData.pink2,
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              SizedBox(height: Responsive.height(12, context)),
              Image.asset(
                'assets/images/parcel_box.gif',
                width: 180,
                height: 180,
                fit: BoxFit.cover,
              ),
              const SizedBox(height: 24),
              Text(
                'Parcel Request Created Successfully!'.tr,
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
                  'Your parcel request has been sent to nearby drivers. You can track the delivery and driver location in real-time!'.tr,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: AppThemeData.grey900,
                    fontSize: 14,
                    fontFamily: AppThemeData.regular,
                  ),
                ),
              ),
              const SizedBox(height: 24),
              ButtonThem.buildButton(
                btnWidthRatio: 0.8,
                context,
                title: "Track Courier on Map".tr,
                btnColor: AppThemeData.warning200,
                txtColor: AppThemeData.grey50,
                onPress: () async {
                  if (parcelData != null) {
                    var argumentData = {'type': parcelData!.status ?? 'new', 'data': parcelData};
                    if (Constant.selectedMapType == "osm") {
                      Get.offAll(() => const ParcelRouteOsmViewScreen(), arguments: argumentData);
                    } else {
                      Get.offAll(() => const ParcelRouteViewScreen(), arguments: argumentData);
                    }
                  } else {
                    Get.offAll(const AllParcelScreen());
                  }
                },
              ),
              const SizedBox(height: 12),
              ButtonThem.buildButton(
                btnWidthRatio: 0.8,
                context,
                title: "View All Parcels".tr,
                btnColor: AppThemeData.primary200,
                txtColor: AppThemeData.grey50,
                onPress: () async {
                  Get.offAll(const AllParcelScreen());
                },
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}
