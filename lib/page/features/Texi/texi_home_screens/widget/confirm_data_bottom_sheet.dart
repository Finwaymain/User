import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:get/get.dart';
import 'package:cached_network_image/cached_network_image.dart';

import 'package:finway/controller/home_osm_controller.dart';
import 'package:finway/model/vehicle_category_model.dart';
import 'package:finway/model/driver_model.dart';
import 'package:finway/themes/constant_colors.dart';
import 'package:finway/themes/button_them.dart';
import 'package:finway/themes/text_field_them.dart';
import 'package:finway/constant/constant.dart';
import 'package:finway/constant/image_constant.dart';
import 'package:finway/widget/StarRating.dart';
import 'package:finway/utils/Preferences.dart';
import 'package:finway/constant/show_toast_dialog.dart';

class ConfirmDataBottomSheet {
  static void show({
    required BuildContext context,
    required VehicleCategoryModel vehicleCategoryModel,
    required DriverData driverModel,
    required double tripPrice,
    required bool isDarkMode,
    required HomeOsmController controller,
    required VoidCallback onBack,
    required VoidCallback onSelectPayment,
  }) {
    final favouriteNameTextController = TextEditingController();

    showModalBottomSheet(
        barrierColor: isDarkMode ? AppThemeData.grey800.withAlpha(200) : Colors.black26,
        isDismissible: true,
        isScrollControlled: true,
        context: context,
        backgroundColor: isDarkMode ? AppThemeData.surface50Dark : AppThemeData.surface50,
        builder: (context) {
          return StatefulBuilder(builder: (context, setState) {
            return Obx(
                  () => Column(
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
                            isDarkMode ? AppThemeData.grey900Dark : AppThemeData.grey900,
                            BlendMode.srcIn,
                          ),
                        ),
                      )),
                  const SizedBox(height: 10),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Column(
                      children: [
                        // Driver Photo
                        ClipRRect(
                          borderRadius: BorderRadius.circular(100),
                          child: CachedNetworkImage(
                            imageUrl: driverModel.photo.toString(),
                            fit: BoxFit.cover,
                            height: 110,
                            width: 110,
                            placeholder: (context, url) => Constant.loader(context),
                            errorWidget: (context, url, error) => Image.asset(
                              ImageConstant.logo,
                              fit: BoxFit.cover,
                              height: 110,
                              width: 110,
                            ),
                          ),
                        ),
                        const SizedBox(height: 10),
                        // Driver Details
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              '${driverModel.prenom ?? ''} ${driverModel.nom ?? ''}',
                              style: TextStyle(
                                fontSize: 18,
                                fontFamily: AppThemeData.semiBold,
                                color: isDarkMode ? AppThemeData.grey900Dark : AppThemeData.grey900,
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.only(top: 3),
                              child: StarRating(
                                size: 20,
                                rating: double.parse(driverModel.moyenne.toString()),
                                color: AppThemeData.warning200,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        // Trip Details
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 20.0),
                          child: Row(
                            children: [
                              Expanded(
                                  child: _buildDetails(
                                    title: driverModel.totalCompletedRide.toString(),
                                    value: 'Total Trips'.tr,
                                    isDarkMode: isDarkMode,
                                  )),
                              const SizedBox(width: 10),
                              Expanded(
                                  child: _buildDetails(
                                    title: controller.duration.value,
                                    value: 'Duration'.tr,
                                    isDarkMode: isDarkMode,
                                  )),
                              const SizedBox(width: 10),
                              Expanded(
                                  child: _buildDetails(
                                    title: Constant().amountShow(amount: tripPrice.toString()),
                                    value: 'Trip Price'.tr,
                                    isDarkMode: isDarkMode,
                                  )),
                            ],
                          ),
                        ),
                        const SizedBox(height: 10),
                        // Cab Details Container
                        Container(
                          decoration: BoxDecoration(
                            border: Border.all(
                              width: 1,
                              color: isDarkMode ? AppThemeData.grey300Dark : AppThemeData.grey300,
                            ),
                          ),
                          child: Column(
                            children: [
                              Padding(
                                padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      "Cab Details".tr,
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontFamily: AppThemeData.regular,
                                        color: isDarkMode ? AppThemeData.grey900Dark : AppThemeData.grey900,
                                      ),
                                    ),
                                    Text(
                                      "${driverModel.numberplate}",
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontFamily: AppThemeData.medium,
                                        color: isDarkMode ? AppThemeData.grey900Dark : AppThemeData.grey900,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Container(
                                color: isDarkMode ? AppThemeData.grey300Dark : AppThemeData.grey300,
                                height: 1,
                              ),
                              Padding(
                                padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      "Driver's Contact No.".tr,
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontFamily: AppThemeData.regular,
                                        color: isDarkMode ? AppThemeData.grey900Dark : AppThemeData.grey900,
                                      ),
                                    ),
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.end,
                                      children: [
                                        Text(
                                          "${driverModel.phone}",
                                          style: TextStyle(
                                            fontSize: 16,
                                            fontFamily: AppThemeData.medium,
                                            color: isDarkMode ? AppThemeData.grey900Dark : AppThemeData.grey900,
                                          ),
                                        ),
                                        const SizedBox(width: 5),
                                        InkWell(
                                          splashColor: Colors.transparent,
                                          onTap: () {
                                            Constant.makePhoneCall(driverModel.phone.toString());
                                          },
                                          child: SvgPicture.asset(
                                            'assets/icons/ic_phone.svg',
                                            colorFilter: ColorFilter.mode(
                                              AppThemeData.secondary200,
                                              BlendMode.srcIn,
                                            ),
                                          ),
                                        )
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                        // Add Favourite Option
                        InkWell(
                          splashColor: Colors.transparent,
                          onTap: () {
                            _showFavouriteNameDialog(context, controller, favouriteNameTextController);
                          },
                          child: Padding(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                SvgPicture.asset(
                                  'assets/icons/ic_star.svg',
                                  height: 24,
                                  width: 24,
                                  colorFilter: ColorFilter.mode(
                                    AppThemeData.secondary300,
                                    BlendMode.srcIn,
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Text(
                                  "Add Favourite Name".tr,
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontFamily: AppThemeData.regular,
                                    color: AppThemeData.secondary300,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        // Select Payment Button
                        Padding(
                            padding: const EdgeInsets.symmetric(vertical: 20),
                            child: ButtonThem.buildButton(context, title: "Select Payment Method".tr, onPress: () async {
                              var amount = await Constant().getAmount();
                              if (amount != null) {
                                controller.walletAmount.value = amount;
                              }
                              Get.back();
                              onSelectPayment();
                            })),
                      ],
                    ),
                  ),
                ],
              ),
            );
          });
        });
  }

  static Widget _buildDetails({required String title, required String value, required bool isDarkMode}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          title,
          textAlign: TextAlign.center,
          maxLines: 1,
          style: TextStyle(
            fontSize: 22,
            fontFamily: AppThemeData.semiBold,
            color: AppThemeData.secondary200,
          ),
        ),
        Text(
          value,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 12,
            fontFamily: AppThemeData.regular,
            color: isDarkMode ? AppThemeData.grey900Dark : AppThemeData.grey900,
          ),
        ),
      ],
    );
  }

  static void _showFavouriteNameDialog(BuildContext context, HomeOsmController controller, TextEditingController favouriteNameTextController) {
    showDialog(
        context: context,
        builder: (context) {
          return AlertDialog(
            title: Text("Enter Favourite Name".tr),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFieldThem.buildTextField(
                  title: 'Favourite name'.tr,
                  labelText: 'Favourite name'.tr,
                  controller: favouriteNameTextController,
                  textInputType: TextInputType.text,
                  contentPadding: EdgeInsets.zero,
                ),
                Padding(
                  padding: const EdgeInsets.only(top: 30),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      InkWell(
                          splashColor: Colors.transparent,
                          onTap: () {
                            Get.back();
                          },
                          child: Text("cancel".tr)),
                      InkWell(
                          splashColor: Colors.transparent,
                          onTap: () {
                            Map<String, String> bodyParams = {
                              'id_user_app': Preferences.getInt(Preferences.userId).toString(),
                              'lat1': '${controller.departureLatLong.value.latitude}',
                              'lng1': '${controller.departureLatLong.value.longitude}',
                              'lat2': '${controller.destinationLatLong.value.latitude}',
                              'lng2': '${controller.destinationLatLong.value.longitude}',
                              'distance': controller.distance.value.toString(),
                              'distance_unit': Constant.distanceUnit.toString(),
                              'depart_name': controller.departureController.text,
                              'destination_name': controller.destinationController.text,
                              'fav_name': favouriteNameTextController.text,
                            };
                            controller.setFavouriteRide(bodyParams).then((value) {
                              if (value['success'] == "Success") {
                                Get.back();
                              } else {
                                ShowToastDialog.showToast(value['error']);
                              }
                            });
                          },
                          child: Padding(
                            padding: const EdgeInsets.only(left: 20),
                            child: Text("Ok".tr),
                          )),
                    ],
                  ),
                )
              ],
            ),
          );
        });
  }
}