import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:get/get.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:provider/provider.dart';

import 'package:finway/controller/home_osm_controller.dart';
import 'package:finway/model/vehicle_category_model.dart';
import 'package:finway/model/driver_model.dart';
import 'package:finway/themes/constant_colors.dart';
import 'package:finway/themes/button_them.dart';
import 'package:finway/constant/constant.dart';
import 'package:finway/constant/show_toast_dialog.dart';
import 'package:finway/constant/image_constant.dart';
import 'package:finway/utils/dark_theme_provider.dart';

class ChooseVehicleBottomSheet {
  static void show({
    required BuildContext context,
    required VehicleCategoryModel vehicleCategoryModel,
    required bool isDarkMode,
    required HomeOsmController controller,
    required VoidCallback onBack,
    required Function(DriverData, double) onNext,
  }) {
    showModalBottomSheet(
        barrierColor: isDarkMode ? AppThemeData.grey800.withAlpha(200) : Colors.black26,
        isDismissible: true,
        isScrollControlled: true,
        context: context,
        backgroundColor: isDarkMode ? AppThemeData.surface50Dark : AppThemeData.surface50,
        builder: (context) {
          final themeChange = Provider.of<DarkThemeProvider>(context);
          return StatefulBuilder(builder: (context, setState) {
            return Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                      margin: const EdgeInsets.symmetric(vertical: 10),
                      height: 8,
                      width: 75,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(100),
                        color: isDarkMode ? AppThemeData.grey300Dark : AppThemeData.grey300,
                      )),
                ),
                IconButton(
                    onPressed: () {
                      Get.back();
                      onBack();
                    },
                    icon: Transform(
                      alignment: Alignment.center,
                      transform: Directionality.of(context) == TextDirection.rtl ? Matrix4.rotationY(3.14159) : Matrix4.identity(),
                      child: SvgPicture.asset(
                        'assets/icons/ic_left.svg',
                        colorFilter: ColorFilter.mode(
                          themeChange.getThem() ? AppThemeData.grey900Dark : AppThemeData.grey900,
                          BlendMode.srcIn,
                        ),
                      ),
                    )),
                const SizedBox(height: 10),
                Flexible(
                  child: SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 15.0, vertical: 0),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            decoration: BoxDecoration(
                                border: Border.all(
                                  color: themeChange.getThem() ? AppThemeData.grey300Dark : AppThemeData.grey300,
                                  width: 1,
                                )),
                            child: Column(
                              children: [
                                Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Row(
                                        children: [
                                          SvgPicture.asset(
                                            'assets/icons/ic_map.svg',
                                            colorFilter: ColorFilter.mode(
                                              AppThemeData.success300,
                                              BlendMode.srcIn,
                                            ),
                                          ),
                                          const SizedBox(width: 10),
                                          Text(
                                            'Total Distances'.tr,
                                            style: TextStyle(
                                              fontSize: 16,
                                              fontFamily: AppThemeData.regular,
                                              color: themeChange.getThem() ? AppThemeData.grey900Dark : AppThemeData.grey900,
                                            ),
                                          )
                                        ],
                                      ),
                                      Text(
                                        '${controller.distance.value.toStringAsFixed(2)} ${Constant.distanceUnit}',
                                        style: TextStyle(
                                          fontSize: 16,
                                          fontFamily: AppThemeData.medium,
                                          color: themeChange.getThem() ? AppThemeData.grey900Dark : AppThemeData.grey900,
                                        ),
                                      )
                                    ],
                                  ),
                                ),
                                Container(
                                  color: themeChange.getThem() ? AppThemeData.grey300Dark : AppThemeData.grey300,
                                  height: 1,
                                ),
                                Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Row(
                                        children: [
                                          SvgPicture.asset(
                                            'assets/icons/ic_group.svg',
                                            colorFilter: ColorFilter.mode(
                                              AppThemeData.warning200,
                                              BlendMode.srcIn,
                                            ),
                                          ),
                                          const SizedBox(width: 10),
                                          Text(
                                            'About Passengers'.tr,
                                            style: TextStyle(
                                              fontSize: 16,
                                              fontFamily: AppThemeData.regular,
                                              color: themeChange.getThem() ? AppThemeData.grey900Dark : AppThemeData.grey900,
                                            ),
                                          )
                                        ],
                                      ),
                                      Text(
                                        '1 ${'Persons'.tr}',
                                        style: TextStyle(
                                          fontSize: 16,
                                          fontFamily: AppThemeData.medium,
                                          color: themeChange.getThem() ? AppThemeData.grey900Dark : AppThemeData.grey900,
                                        ),
                                      )
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 10),
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 10),
                            child: Text(
                              "Recommended for you".tr,
                              style: TextStyle(
                                fontSize: 18,
                                fontFamily: AppThemeData.semiBold,
                                color: themeChange.getThem() ? AppThemeData.grey900Dark : AppThemeData.grey900,
                              ),
                            ),
                          ),
                          ListView.separated(
                            separatorBuilder: (context, index) {
                              return Container(
                                color: themeChange.getThem() ? AppThemeData.grey300Dark : AppThemeData.grey300,
                                height: 1,
                              );
                            },
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: vehicleCategoryModel.data?.length ?? 0,
                            scrollDirection: Axis.vertical,
                            shrinkWrap: true,
                            itemBuilder: (context, index) {
                              return Obx(
                                () => InkWell(
                                  onTap: () {
                                    controller.vehicleData.value = vehicleCategoryModel.data![index];
                                  },
                                  child: Container(
                                    decoration: BoxDecoration(
                                      color: controller.vehicleData.value.id == vehicleCategoryModel.data![index].id.toString()
                                          ? AppThemeData.secondary50
                                          : themeChange.getThem()
                                              ? AppThemeData.surface50Dark
                                              : AppThemeData.surface50,
                                    ),
                                    child: Padding(
                                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                      child: Row(
                                        children: [
                                          Expanded(
                                            child: Row(
                                              children: [
                                                CachedNetworkImage(
                                                  imageUrl: vehicleCategoryModel.data![index].image.toString(),
                                                  fit: BoxFit.cover,
                                                  width: 40,
                                                  height: 40,
                                                  placeholder: (context, url) => Constant.loader(context),
                                                  errorWidget: (context, url, error) => Image.asset(
                                                    ImageConstant.logo,
                                                  ),
                                                ),
                                                const SizedBox(width: 16),
                                                Column(
                                                  crossAxisAlignment: CrossAxisAlignment.start,
                                                  children: [
                                                    Text(
                                                      vehicleCategoryModel.data![index].libelle.toString(),
                                                      textAlign: TextAlign.start,
                                                      style: TextStyle(
                                                        fontSize: 16,
                                                        color: controller.vehicleData.value.id == vehicleCategoryModel.data![index].id.toString()
                                                            ? AppThemeData.grey900
                                                            : themeChange.getThem()
                                                                ? AppThemeData.grey900Dark
                                                                : AppThemeData.grey900,
                                                        fontFamily: AppThemeData.semiBold,
                                                      ),
                                                    ),
                                                    Text(
                                                      vehicleCategoryModel.data![index].prix.toString(),
                                                      textAlign: TextAlign.center,
                                                      style: TextStyle(
                                                        fontSize: 12,
                                                        color: controller.vehicleData.value.id == vehicleCategoryModel.data![index].id.toString()
                                                            ? AppThemeData.grey900
                                                            : themeChange.getThem()
                                                                ? AppThemeData.grey900Dark
                                                                : AppThemeData.grey900,
                                                        fontFamily: AppThemeData.regular,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ],
                                            ),
                                          ),
                                          Column(
                                            crossAxisAlignment: CrossAxisAlignment.end,
                                            children: [
                                              Padding(
                                                padding: const EdgeInsets.only(top: 5),
                                                child: Column(
                                                  crossAxisAlignment: CrossAxisAlignment.end,
                                                  mainAxisAlignment: MainAxisAlignment.start,
                                                  children: [
                                                    Text(
                                                      Constant().amountShow(
                                                          amount: "${controller.calculateTripPrice(
                                                            distance: controller.distance.value,
                                                            deliveryCharges: double.parse(vehicleCategoryModel.data![index].deliveryCharges ?? '0'),
                                                            minimumDeliveryCharges: double.parse(vehicleCategoryModel.data![index].minimumDeliveryCharges ?? '0'),
                                                            minimumDeliveryChargesWithin: double.parse(vehicleCategoryModel.data![index].minimumDeliveryChargesWithin ?? '0'),
                                                            basePrice: double.tryParse(vehicleCategoryModel.data![index].basePrice ?? ''),
                                                            perKmPrice: double.tryParse(vehicleCategoryModel.data![index].perKmPrice ?? ''),
                                                          )}"),
                                                      textAlign: TextAlign.center,
                                                      style: TextStyle(
                                                        fontSize: 16,
                                                        color: controller.vehicleData.value.id == vehicleCategoryModel.data![index].id.toString()
                                                            ? AppThemeData.grey900
                                                            : themeChange.getThem()
                                                                ? AppThemeData.grey900Dark
                                                                : AppThemeData.grey900,
                                                        fontFamily: AppThemeData.semiBold,
                                                      ),
                                                    ),
                                                    Text(
                                                      controller.duration.value,
                                                      textAlign: TextAlign.center,
                                                      style: TextStyle(
                                                        fontSize: 12,
                                                        color: controller.vehicleData.value.id == vehicleCategoryModel.data![index].id.toString()
                                                            ? AppThemeData.grey900
                                                            : themeChange.getThem()
                                                                ? AppThemeData.grey900Dark
                                                                : AppThemeData.grey900,
                                                        fontFamily: AppThemeData.regular,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                          const SizedBox(height: 20),
                          ButtonThem.buildButton(context, title: "Next".tr, btnColor: AppThemeData.primary200, onPress: () async {
                            if (controller.vehicleData.value.id != null) {
                              double cout = controller.calculateTripPrice(
                                distance: controller.distance.value,
                                deliveryCharges: double.tryParse(controller.vehicleData.value.deliveryCharges ?? '') ?? 0.0,
                                minimumDeliveryCharges: double.tryParse(controller.vehicleData.value.minimumDeliveryCharges ?? '') ?? 0.0,
                                minimumDeliveryChargesWithin: double.tryParse(controller.vehicleData.value.minimumDeliveryChargesWithin ?? '') ?? 0.0,
                                basePrice: double.tryParse(controller.vehicleData.value.basePrice ?? ''),
                                perKmPrice: double.tryParse(controller.vehicleData.value.perKmPrice ?? ''),
                              );

                              await controller
                                  .getDriverDetails(
                                  controller.vehicleData.value.id ?? '',
                                  '${controller.departureLatLong.value.latitude}',
                                  '${controller.departureLatLong.value.longitude}')
                                  .then((value) {
                                if (value != null) {
                                  if (value.success == "Success") {
                                    if (value.data != null && value.data!.isNotEmpty && value.data!.first.id?.isNotEmpty == true) {
                                      Get.back();
                                      onNext(value.data!.first, cout);
                                    } else {
                                      ShowToastDialog.showToast("Driver not found in your area.".tr);
                                    }
                                  } else {
                                    ShowToastDialog.showToast("Driver not found in your area.".tr);
                                  }
                                }
                              });
                            } else {
                              ShowToastDialog.showToast("Please select Vehicle Type".tr);
                            }
                          }),
                          const SizedBox(height: 20),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            );
          });
        });
  }
}