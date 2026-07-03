import 'dart:developer';
import 'dart:io';
import 'package:finway/constant/constant.dart';
import 'package:finway/constant/show_toast_dialog.dart';
import 'package:finway/controller/parcel_service_controller.dart';
import 'package:finway/page/parcel_service_screen/parcel_cart_screen.dart';
import 'package:finway/page/parcel_service_screen/place_picker_osm.dart';
import 'package:finway/page/parcel_service_screen/place_picker_google.dart';
import 'package:finway/themes/appbar_cust.dart';
import 'package:finway/themes/button_them.dart';
import 'package:finway/themes/constant_colors.dart';
import 'package:finway/themes/text_field_them.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:finway/themes/responsive.dart';
import 'package:finway/utils/dark_theme_provider.dart';
import 'package:flutter_svg/svg.dart';
import 'package:provider/provider.dart';

class BookParcelScreen extends StatelessWidget {
  const BookParcelScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final themeChange = Provider.of<DarkThemeProvider>(context);
    bool isDarkMode = themeChange.getThem();

    return GetX<ParcelServiceController>(
        init: ParcelServiceController(),
        builder: (controller) {
          return Scaffold(
            appBar: CustomAppbar(
              title: "${"Send".tr} ${controller.selectedParcelCategory.value.title}",
              bgColor: AppThemeData.primary200,
            ),
            resizeToAvoidBottomInset: true,
            body: Stack(
              alignment: AlignmentDirectional.topStart,
              children: [
                Container(
                  color: AppThemeData.primary200,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Expanded(flex: 1, child: SizedBox()),
                      Expanded(
                        flex: 9,
                        child: Container(
                          color: isDarkMode ? AppThemeData.surface50Dark : AppThemeData.surface50,
                        ),
                      ),
                    ],
                  ),
                ),
                SafeArea(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(
                          height: 20,
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(24),
                              width: double.infinity,
                              decoration: BoxDecoration(
                                  color: isDarkMode ? AppThemeData.surface50Dark : AppThemeData.surface50,
                                  border: Border.all(
                                    color: themeChange.getThem() ? AppThemeData.grey300Dark : AppThemeData.grey300,
                                    width: 0.8,
                                  )),
                              child: Column(
                                children: [
                                  SvgPicture.asset('assets/icons/ic_upload_doc.svg'),
                                  const SizedBox(
                                    height: 12,
                                  ),
                                  Text(
                                    "Upload Parcel Image".tr,
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontFamily: AppThemeData.semiBold,
                                      color: isDarkMode ? AppThemeData.grey900Dark : AppThemeData.grey900,
                                    ),
                                  ),
                                  const SizedBox(
                                    height: 12,
                                  ),
                                  Text(
                                    "Take a clear picture of your parcel or choose an image from your gallery to ensure smooth delivery.".tr,
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontFamily: AppThemeData.regular,
                                      color: isDarkMode ? AppThemeData.grey500Dark : AppThemeData.grey500,
                                    ),
                                  ),
                                  const SizedBox(
                                    height: 16,
                                  ),
                                  Text(
                                    "Max. 5MB, Accepted: JPG, PNG".tr,
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontFamily: AppThemeData.regular,
                                      color: isDarkMode ? AppThemeData.grey500Dark : AppThemeData.grey500,
                                    ),
                                  ),
                                  const SizedBox(
                                    height: 24,
                                  ),
                                  ButtonThem.buildButton(
                                    txtSize: 14,
                                    btnWidthRatio: 0.4,
                                    context,
                                    title: 'Click to Upload'.tr,
                                    btnColor: themeChange.getThem() ? AppThemeData.primary300Dark : AppThemeData.primary300,
                                    onPress: () async {
                                      controller.onCameraClick(context);
                                    },
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Visibility(
                          visible: controller.parcelImages.isNotEmpty,
                          child: SizedBox(
                            height: 100,
                            width: Responsive.width(100, context),
                            child: ListView.builder(
                              itemCount: controller.parcelImages.length,
                              shrinkWrap: true,
                              scrollDirection: Axis.horizontal,
                              physics: const NeverScrollableScrollPhysics(),
                              itemBuilder: (context, index) {
                                return Padding(
                                  padding: const EdgeInsets.only(right: 16),
                                  child: Container(
                                    width: 100,
                                    height: 100.0,
                                    decoration: BoxDecoration(
                                      image: DecorationImage(
                                        fit: BoxFit.cover,
                                        image: FileImage(File(controller.parcelImages[index].path)),
                                      ),
                                    ),
                                    child: InkWell(
                                        onTap: () {
                                          controller.parcelImages.removeAt(index);
                                        },
                                        child: const Icon(
                                          Icons.remove_circle,
                                          size: 30,
                                        )),
                                  ),
                                );
                              },
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          "Sender Informations".tr,
                          style: TextStyle(
                            fontSize: 18,
                            fontFamily: AppThemeData.semiBold,
                            color: isDarkMode ? AppThemeData.grey900Dark : AppThemeData.grey900,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Column(
                          children: [
                            InkWell(
                              splashColor: Colors.transparent,
                              onTap: () async {
                                if (Constant.selectedMapType == 'osm') {
                                  Get.to(() => const LocationPicker())?.then((value) {
                                    if (value != null) {
                                      controller.senderAddress.value = value['address'];
                                      controller.senderLocation = LatLng(value['lat'], value['lng']);
                                      controller.senderAddressCity.value = value['city']!;
                                      log("Sender Addres :: ${controller.senderAddressCity.value.toString()}");
                                      log("Reciver Addres :: ${controller.senderAddressCity.value.toString()}");
                                    }
                                  });
                                } else {
                                  Get.to(() => const GoogleLocationPicker())?.then((value) {
                                    if (value != null) {
                                      controller.senderAddress.value = value['address'];
                                      controller.senderLocation = LatLng(value['lat'], value['lng']);
                                      controller.senderAddressCity.value = value['city']!;
                                      log("Sender Addres :: ${controller.senderAddressCity.value.toString()}");
                                      log("Reciver Addres :: ${controller.senderAddressCity.value.toString()}");
                                    }
                                  });
                                }
                              },
                              child: Container(
                                width: double.infinity,
                                decoration: BoxDecoration(
                                    color: isDarkMode ? AppThemeData.surface50Dark : AppThemeData.surface50,
                                    border: Border.all(
                                      color: themeChange.getThem() ? AppThemeData.grey300Dark : AppThemeData.grey300,
                                      width: 0.8,
                                    )),
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
                                  child: Row(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      SvgPicture.asset(
                                        'assets/icons/ic_location.svg',
                                        colorFilter: ColorFilter.mode(
                                          themeChange.getThem() ? AppThemeData.grey500Dark : AppThemeData.grey300Dark,
                                          BlendMode.srcIn,
                                        ),
                                      ),
                                      const SizedBox(width: 10),
                                      Expanded(
                                        child: Text(controller.senderAddress.toString(),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                            style: TextStyle(
                                              fontSize: 16,
                                              color: themeChange.getThem() ? AppThemeData.grey900Dark : AppThemeData.grey900,
                                              fontFamily: AppThemeData.regular,
                                            )),
                                      ),
                                      const SizedBox(width: 5),
                                      Text('Change'.tr,
                                          style: TextStyle(
                                            decorationColor: themeChange.getThem() ? AppThemeData.primary300Dark : AppThemeData.primary300,
                                            decoration: TextDecoration.underline,
                                            fontSize: 14,
                                            color: themeChange.getThem() ? AppThemeData.primary300Dark : AppThemeData.primary300,
                                            fontFamily: AppThemeData.regular,
                                          ))
                                    ],
                                  ),
                                ),
                              ),
                            ),
                            TextFieldWidget(
                              prefix: IconButton(
                                  onPressed: () {},
                                  icon: SvgPicture.asset(
                                    'assets/icons/ic_user.svg',
                                    colorFilter: ColorFilter.mode(
                                      themeChange.getThem() ? AppThemeData.grey500Dark : AppThemeData.grey300Dark,
                                      BlendMode.srcIn,
                                    ),
                                  )),
                              controller: controller.sNameController,
                              hintText: 'Name'.tr,
                            ),
                            MobileTextFieldWidget(
                              onChanged: (number) {
                                controller.sPhoneController.value.text = number.completeNumber;
                              },
                              hintText: 'Mobile number'.tr,
                              controller: controller.sPhoneController.value,
                              initialCountryCode: 'IN',
                              countries: const ['IN'],
                            ),
                            SizedBox(
                              height: 53,
                              child: Row(
                                children: [
                                  Expanded(
                                    child: TextFieldWidget(
                                      onTap: () {
                                        controller.selectDate(
                                          context,
                                        );
                                      },
                                      isReadOnly: true,
                                      suffix: IconButton(
                                          onPressed: () {
                                            controller.selectDate(
                                              context,
                                            );
                                          },
                                          icon: SvgPicture.asset(
                                            'assets/icons/ic_date.svg',
                                            colorFilter: ColorFilter.mode(
                                              themeChange.getThem() ? AppThemeData.grey500Dark : AppThemeData.grey300Dark,
                                              BlendMode.srcIn,
                                            ),
                                          )),
                                      controller: TextEditingController(text: controller.senderDate.value),
                                      hintText: 'Date'.tr,
                                    ),
                                  ),
                                  Expanded(
                                    child: TextFieldWidget(
                                      onTap: () {
                                        controller.selectTime(
                                          context,
                                        );
                                      },
                                      isReadOnly: true,
                                      suffix: IconButton(
                                          onPressed: () {
                                            controller.selectTime(
                                              context,
                                            );
                                          },
                                          icon: SvgPicture.asset(
                                            'assets/icons/ic_time.svg',
                                            colorFilter: ColorFilter.mode(
                                              themeChange.getThem() ? AppThemeData.grey500Dark : AppThemeData.grey300Dark,
                                              BlendMode.srcIn,
                                            ),
                                          )),
                                      controller: TextEditingController(text: controller.senderTime.value),
                                      hintText: 'Time'.tr,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            SizedBox(
                              height: 53,
                              child: Row(
                                children: [
                                  Expanded(
                                    child: TextFieldWidget(
                                      textInputType: TextInputType.number,
                                      controller: controller.parcelWeightController,
                                      hintText: 'Enter kg'.tr,
                                      suffix: IconButton(
                                          onPressed: () {},
                                          icon: Text(
                                            'kg'.tr,
                                            style: TextStyle(
                                              fontSize: 16,
                                              fontFamily: AppThemeData.semiBold,
                                              color: isDarkMode ? AppThemeData.grey500Dark : AppThemeData.grey300Dark,
                                            ),
                                          )),
                                    ),
                                  ),
                                  Expanded(
                                    child: TextFieldWidget(
                                      textInputType: TextInputType.number,
                                      suffix: IconButton(
                                          onPressed: () {},
                                          icon: Text(
                                            'ft'.tr,
                                            style: TextStyle(
                                              fontSize: 16,
                                              fontFamily: AppThemeData.semiBold,
                                              color: isDarkMode ? AppThemeData.grey500Dark : AppThemeData.grey300Dark,
                                            ),
                                          )),
                                      controller: controller.parcelDimentionController,
                                      hintText: 'Enter ft'.tr,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            TextFieldWidget(
                              prefix: IconButton(
                                  onPressed: () {},
                                  icon: Icon(
                                    Icons.mode_edit_outline_outlined,
                                    size: 16,
                                    color: themeChange.getThem() ? AppThemeData.grey500Dark : AppThemeData.grey500,
                                  )),
                              controller: controller.noteController,
                              hintText: 'Note'.tr,
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          "Receiver’s Information".tr,
                          style: TextStyle(
                            fontSize: 18,
                            fontFamily: AppThemeData.semiBold,
                            color: isDarkMode ? AppThemeData.grey900Dark : AppThemeData.grey900,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Column(
                          children: [
                            InkWell(
                              splashColor: Colors.transparent,
                              onTap: () async {
                                if (Constant.selectedMapType == 'osm') {
                                  Get.to(() => const LocationPicker())?.then((value) {
                                    if (value != null) {
                                      log("value :: ${value.toString()}");
                                      controller.receiverAddress.value = value['address'];
                                      controller.receiverLocation = LatLng(value['lat'], value['lng']);
                                      controller.receiverAddressCity.value = value['city'];
                                    }
                                  });
                                } else {
                                  Get.to(() => const GoogleLocationPicker())?.then((value) {
                                    if (value != null) {
                                      log("value :: ${value.toString()}");
                                      controller.receiverAddress.value = value['address'];
                                      controller.receiverLocation = LatLng(value['lat'], value['lng']);
                                      controller.receiverAddressCity.value = value['city'];
                                    }
                                  });
                                }
                              },
                              child: Container(
                                width: double.infinity,
                                decoration: BoxDecoration(
                                    color: isDarkMode ? AppThemeData.surface50Dark : AppThemeData.surface50,
                                    border: Border.all(
                                      color: themeChange.getThem() ? AppThemeData.grey300Dark : AppThemeData.grey300,
                                      width: 0.8,
                                    )),
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
                                  child: Row(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      SvgPicture.asset(
                                        'assets/icons/ic_location.svg',
                                        colorFilter: ColorFilter.mode(
                                          themeChange.getThem() ? AppThemeData.grey500Dark : AppThemeData.grey300Dark,
                                          BlendMode.srcIn,
                                        ),
                                      ),
                                      const SizedBox(width: 10),
                                      Expanded(
                                        child: Text(controller.receiverAddress.toString(),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                            style: TextStyle(
                                              fontSize: 16,
                                              color: themeChange.getThem() ? AppThemeData.grey900Dark : AppThemeData.grey900,
                                              fontFamily: AppThemeData.regular,
                                            )),
                                      ),
                                      const SizedBox(width: 5),
                                      Text('Change'.tr,
                                          style: TextStyle(
                                            decorationColor: themeChange.getThem() ? AppThemeData.primary300Dark : AppThemeData.primary300,
                                            decoration: TextDecoration.underline,
                                            fontSize: 14,
                                            color: themeChange.getThem() ? AppThemeData.primary300Dark : AppThemeData.primary300,
                                            fontFamily: AppThemeData.regular,
                                          ))
                                    ],
                                  ),
                                ),
                              ),
                            ),
                            TextFieldWidget(
                              prefix: IconButton(
                                  onPressed: () {},
                                  icon: SvgPicture.asset(
                                    'assets/icons/ic_user.svg',
                                    colorFilter: ColorFilter.mode(
                                      themeChange.getThem() ? AppThemeData.grey500Dark : AppThemeData.grey300Dark,
                                      BlendMode.srcIn,
                                    ),
                                  )),
                              controller: controller.rNameController,
                              hintText: 'Name'.tr,
                            ),
                            MobileTextFieldWidget(
                              onChanged: (number) {
                                controller.rPhoneController.value.text = number.completeNumber;
                              },
                              hintText: 'Mobile number'.tr,
                              controller: controller.rPhoneController.value,
                              initialCountryCode: 'IN',
                              countries: const ['IN'],
                            ),
                            SizedBox(
                              height: 53,
                              child: Row(
                                children: [
                                  Expanded(
                                    child: TextFieldWidget(
                                      onTap: () {
                                        controller.selectDate(context, isPickUp: false);
                                      },
                                      isReadOnly: true,
                                      suffix: IconButton(
                                          onPressed: () {
                                            controller.selectDate(context, isPickUp: false);
                                          },
                                          icon: SvgPicture.asset(
                                            'assets/icons/ic_date.svg',
                                            colorFilter: ColorFilter.mode(
                                              themeChange.getThem() ? AppThemeData.grey500Dark : AppThemeData.grey300Dark,
                                              BlendMode.srcIn,
                                            ),
                                          )),
                                      controller: TextEditingController(text: controller.receiverDate.value),
                                      hintText: 'Arrive Date'.tr,
                                    ),
                                  ),
                                  Expanded(
                                    child: TextFieldWidget(
                                      onTap: () {
                                        controller.selectTime(context, isPickUp: false);
                                      },
                                      isReadOnly: true,
                                      suffix: IconButton(
                                          onPressed: () {
                                            controller.selectTime(context, isPickUp: false);
                                          },
                                          icon: SvgPicture.asset(
                                            'assets/icons/ic_time.svg',
                                            colorFilter: ColorFilter.mode(
                                              themeChange.getThem() ? AppThemeData.grey500Dark : AppThemeData.grey300Dark,
                                              BlendMode.srcIn,
                                            ),
                                          )),
                                      controller: TextEditingController(text: controller.receiverTime.value),
                                      hintText: 'Arrive Time'.tr,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 28),
                        ButtonThem.buildButton(
                          context,
                          title: 'Continue'.tr,
                          onPress: () async {
                            final sDigits = controller.sPhoneController.value.text.replaceAll(RegExp(r'\D'), '');
                            final rDigits = controller.rPhoneController.value.text.replaceAll(RegExp(r'\D'), '');
                            bool isValidSender = (sDigits.length == 10) || (sDigits.length == 12 && sDigits.startsWith('91'));
                            bool isValidReceiver = (rDigits.length == 10) || (rDigits.length == 12 && rDigits.startsWith('91'));

                            if (controller.sNameController.value.text.isEmpty) {
                              ShowToastDialog.showToast(
                                "Please Enter Sender Name.",
                              );
                            } else if (controller.sPhoneController.value.text.isEmpty) {
                              ShowToastDialog.showToast(
                                "Please Enter Sender Phone number.",
                              );
                            } else if (!isValidSender) {
                              ShowToastDialog.showToast(
                                "Please Enter valid 10-digit Indian phone number for Sender.",
                              );
                            } else if (controller.senderDate.isEmpty || controller.senderTime.isEmpty) {
                              ShowToastDialog.showToast(
                                "Select Sender date and time.",
                              );
                            } else if (controller.parcelWeightController.value.text.isEmpty) {
                              ShowToastDialog.showToast(
                                "Please Enter Kg.",
                              );
                            } else if (controller.parcelDimentionController.value.text.isEmpty) {
                              ShowToastDialog.showToast(
                                "Please Enter ft.",
                              );
                            } else if (controller.rNameController.value.text.isEmpty) {
                              ShowToastDialog.showToast(
                                "Please Enter Receiver Name.",
                              );
                            } else if (controller.rPhoneController.value.text.isEmpty) {
                              ShowToastDialog.showToast(
                                "Please Enter Receiver Phone number.",
                              );
                            } else if (!isValidReceiver) {
                              ShowToastDialog.showToast(
                                "Please Enter valid 10-digit Indian phone number for Receiver.",
                              );
                            } else if (controller.receiverDate.isEmpty || controller.receiverTime.isEmpty) {
                              ShowToastDialog.showToast("Select receiver date and time.");
                            } else if (controller.parcelImages.isEmpty) {
                              ShowToastDialog.showToast("Select parcel image");
                            } else {
                              if (Constant.selectedMapType == 'google') {
                                controller.getDurationDistance(controller.senderLocation!, controller.receiverLocation!);
                              } else {
                                controller.getDurationOSMDistance(controller.senderLocation!, controller.receiverLocation!);
                              }
                              Get.to(() => const CartParcelScreen());
                            }
                          },
                        ),
                        const SizedBox(height: 20),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          );
        });
  }
}
