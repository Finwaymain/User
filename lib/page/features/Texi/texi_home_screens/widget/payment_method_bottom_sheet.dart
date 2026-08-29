import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:get/get.dart';
import 'package:flutter_osm_plugin/flutter_osm_plugin.dart';

import 'package:finway/controller/home_osm_controller.dart';
import 'package:finway/model/vehicle_category_model.dart';
import 'package:finway/model/driver_model.dart';
import 'package:finway/themes/constant_colors.dart';
import 'package:finway/themes/button_them.dart';
import 'package:finway/themes/radio_button.dart';
import 'package:finway/constant/constant.dart';
import 'package:finway/constant/show_toast_dialog.dart';
import 'package:finway/utils/Preferences.dart';
import 'package:finway/page/new_ride_screens/searching_driver_screen.dart';
import 'package:finway/model/ride_model.dart';


class PaymentMethodBottomSheet {
  static void show({
    required BuildContext context,
    required VehicleCategoryModel vehicleCategoryModel,
    required double tripPrice,
    required DriverData driverData,
    required bool isDarkMode,
    required HomeOsmController controller,
    required VoidCallback onBack,
  }) {
    final passengerController = TextEditingController(text: "1");

    showModalBottomSheet(
        barrierColor: isDarkMode ? AppThemeData.grey800.withAlpha(200) : Colors.black26,
        isDismissible: true,
        isScrollControlled: true,
        shape: const RoundedRectangleBorder(borderRadius: BorderRadius.only(topRight: Radius.circular(15), topLeft: Radius.circular(15))),
        context: context,
        backgroundColor: isDarkMode ? AppThemeData.surface50Dark : AppThemeData.surface50,
        builder: (context) {
          return StatefulBuilder(builder: (context, setState) {
            return SizedBox(
              height: Get.height * 0.9,
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
                child: SingleChildScrollView(
                  child: Column(
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
                      InkWell(
                        onTap: () {
                          Get.back();
                          onBack();
                        },
                        child: Transform(
                          alignment: Alignment.center,
                          transform: Directionality.of(context) == TextDirection.rtl ? Matrix4.rotationY(3.14159) : Matrix4.identity(),
                          child: SvgPicture.asset(
                            'assets/icons/ic_left.svg',
                            colorFilter: ColorFilter.mode(
                              isDarkMode ? AppThemeData.grey900Dark : AppThemeData.grey900,
                              BlendMode.srcIn,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Container(
                        decoration: BoxDecoration(
                            border: Border.all(
                              color: isDarkMode ? AppThemeData.grey300Dark : AppThemeData.grey300,
                            )),
                        child: Column(
                          children: [
                            // Cash Payment Option
                            RadioButtonCustom(
                              image: "assets/icons/cash.png",
                              name: "Cash",
                              groupValue: controller.paymentMethodType.value,
                              isEnabled: controller.paymentSettingModel.value.cash?.isEnabled == "true" ? true : false,
                              isSelected: controller.cash.value,
                              onClick: (String? value) {
                                _resetPaymentMethods(controller);
                                controller.cash = true.obs;
                                controller.paymentMethodType.value = value!;
                                controller.paymentMethodId.value = controller.paymentSettingModel.value.cash!.idPaymentMethod.toString();
                                setState(() {});
                              },
                            ),
                            // Wallet Payment Option
                            RadioButtonCustom(
                              subName: Constant().amountShow(amount: controller.walletAmount.value),
                              image: "assets/icons/walltet_icons.png",
                              name: "Wallet",
                              groupValue: controller.paymentMethodType.value,
                              isEnabled: controller.paymentSettingModel.value.myWallet?.isEnabled == "true" ? true : false,
                              isSelected: controller.wallet.value,
                              onClick: (String? value) {
                                _resetPaymentMethods(controller);
                                controller.wallet = true.obs;
                                controller.paymentMethodType.value = value!;
                                controller.paymentMethodId.value = controller.paymentSettingModel.value.myWallet!.idPaymentMethod.toString();
                                setState(() {});
                              },
                            ),
                            // Stripe Payment Option
                            RadioButtonCustom(
                              image: "assets/icons/stripe.png",
                              name: 'Stripe',
                              groupValue: controller.paymentMethodType.value,
                              isEnabled: controller.paymentSettingModel.value.strip?.isEnabled == "true" ? true : false,
                              isSelected: controller.stripe.value,
                              onClick: (String? value) {
                                _resetPaymentMethods(controller);
                                controller.stripe = true.obs;
                                controller.paymentMethodType.value = value!;
                                controller.paymentMethodId.value = controller.paymentSettingModel.value.strip!.idPaymentMethod.toString();
                                setState(() {});
                              },
                            ),
                            // PayStack Payment Option
                            RadioButtonCustom(
                              isEnabled: controller.paymentSettingModel.value.payStack?.isEnabled == "true" ? true : false,
                              name: 'PayStack',
                              image: "assets/icons/paystack.png",
                              isSelected: controller.payStack.value,
                              groupValue: controller.paymentMethodType.value,
                              onClick: (String? value) {
                                _resetPaymentMethods(controller);
                                controller.payStack = true.obs;
                                controller.paymentMethodType.value = value!;
                                controller.paymentMethodId.value = controller.paymentSettingModel.value.payStack!.idPaymentMethod.toString();
                                setState(() {});
                              },
                            ),
                            // FlutterWave Payment Option
                            RadioButtonCustom(
                              isEnabled: controller.paymentSettingModel.value.flutterWave?.isEnabled == "true" ? true : false,
                              name: 'FlutterWave',
                              image: "assets/icons/flutterwave.png",
                              isSelected: controller.flutterWave.value,
                              groupValue: controller.paymentMethodType.value,
                              onClick: (String? value) {
                                _resetPaymentMethods(controller);
                                controller.flutterWave = true.obs;
                                controller.paymentMethodType.value = value!;
                                controller.paymentMethodId.value = controller.paymentSettingModel.value.flutterWave!.idPaymentMethod.toString();
                                setState(() {});
                              },
                            ),
                            // RazorPay Payment Option
                            RadioButtonCustom(
                              isEnabled: controller.paymentSettingModel.value.razorpay?.isEnabled == "true" ? true : false,
                              name: 'RazorPay',
                              image: "assets/icons/razorpay_@3x.png",
                              isSelected: controller.razorPay.value,
                              groupValue: controller.paymentMethodType.value,
                              onClick: (String? value) {
                                _resetPaymentMethods(controller);
                                controller.razorPay = true.obs;
                                controller.paymentMethodType.value = value!;
                                controller.paymentMethodId.value = controller.paymentSettingModel.value.razorpay!.idPaymentMethod.toString();
                                setState(() {});
                              },
                            ),
                            // PayFast Payment Option
                            RadioButtonCustom(
                              isEnabled: controller.paymentSettingModel.value.payFast?.isEnabled == "true" ? true : false,
                              name: 'PayFast',
                              image: "assets/icons/payfast.png",
                              isSelected: controller.payFast.value,
                              groupValue: controller.paymentMethodType.value,
                              onClick: (String? value) {
                                _resetPaymentMethods(controller);
                                controller.payFast = true.obs;
                                controller.paymentMethodType.value = value!;
                                controller.paymentMethodId.value = controller.paymentSettingModel.value.payFast!.idPaymentMethod.toString();
                                setState(() {});
                              },
                            ),
                            // MercadoPago Payment Option
                            RadioButtonCustom(
                              isEnabled: controller.paymentSettingModel.value.mercadopago?.isEnabled == "true" ? true : false,
                              name: 'MercadoPago',
                              image: "assets/icons/mercadopago.png",
                              isSelected: controller.mercadoPago.value,
                              groupValue: controller.paymentMethodType.value,
                              onClick: (String? value) {
                                _resetPaymentMethods(controller);
                                controller.mercadoPago = true.obs;
                                controller.paymentMethodType.value = value!;
                                controller.paymentMethodId.value = controller.paymentSettingModel.value.mercadopago!.idPaymentMethod.toString();
                                setState(() {});
                              },
                            ),
                            // PayPal Payment Option
                            RadioButtonCustom(
                              isEnabled: controller.paymentSettingModel.value.payPal?.isEnabled == "true" ? true : false,
                              name: 'PayPal',
                              image: "assets/icons/paypal_@3x.png",
                              isSelected: controller.paypal.value,
                              groupValue: controller.paymentMethodType.value,
                              onClick: (String? value) {
                                _resetPaymentMethods(controller);
                                controller.paypal = true.obs;
                                controller.paymentMethodType.value = value!;
                                controller.paymentMethodId.value = controller.paymentSettingModel.value.payPal!.idPaymentMethod.toString();
                                setState(() {});
                              },
                            ),
                            // Xendit Payment Option
                            RadioButtonCustom(
                              isEnabled: controller.paymentSettingModel.value.xendit?.isEnabled == "true" ? true : false,
                              name: 'Xendit',
                              image: "assets/icons/xendit.png",
                              isSelected: controller.xendit.value,
                              groupValue: controller.paymentMethodType.value,
                              onClick: (String? value) {
                                _resetPaymentMethods(controller);
                                controller.xendit = true.obs;
                                controller.paymentMethodType.value = value!;
                                controller.paymentMethodId.value = controller.paymentSettingModel.value.xendit!.idPaymentMethod.toString();
                                setState(() {});
                              },
                            ),
                            // Orange Pay Payment Option
                            RadioButtonCustom(
                              isEnabled: controller.paymentSettingModel.value.orangePay?.isEnabled == "true" ? true : false,
                              name: 'Orange Pay',
                              image: "assets/icons/orangeMoney.png",
                              isSelected: controller.orangePay.value,
                              groupValue: controller.paymentMethodType.value,
                              onClick: (String? value) {
                                _resetPaymentMethods(controller);
                                controller.orangePay = true.obs;
                                controller.paymentMethodType.value = value!;
                                controller.paymentMethodId.value = controller.paymentSettingModel.value.orangePay!.idPaymentMethod.toString();
                                setState(() {});
                              },
                            ),
                            // Midtrans Payment Option
                            RadioButtonCustom(
                              isEnabled: controller.paymentSettingModel.value.midtrans?.isEnabled == "true" ? true : false,
                              name: 'Midtrans',
                              image: "assets/icons/midtrans.png",
                              isSelected: controller.midtrans.value,
                              groupValue: controller.paymentMethodType.value,
                              onClick: (String? value) {
                                _resetPaymentMethods(controller);
                                controller.midtrans = true.obs;
                                controller.paymentMethodType.value = value!;
                                controller.paymentMethodId.value = controller.paymentSettingModel.value.midtrans!.idPaymentMethod.toString();
                                setState(() {});
                              },
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),
                      // Fare and Tax Breakdown Card
                      Builder(
                        builder: (context) {
                          final selectedMethod = controller.paymentMethodType.value.toLowerCase();
                          final activeTaxes = Constant.getActiveTaxes(selectedMethod);
                          double totalTax = 0.0;
                          for (var t in activeTaxes) {
                            totalTax += Constant.calculateTaxFor(t, tripPrice);
                          }
                          final grandTotal = tripPrice + totalTax;

                          return Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: isDarkMode ? AppThemeData.surface50Dark : const Color(0xFFF8FAFC),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                color: isDarkMode ? AppThemeData.grey300Dark : AppThemeData.grey200,
                              ),
                            ),
                            child: Column(
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text("Base Fare".tr, style: TextStyle(color: isDarkMode ? AppThemeData.grey400Dark : AppThemeData.grey700, fontSize: 13)),
                                    Text(Constant().amountShow(amount: tripPrice.toString()), style: TextStyle(fontWeight: FontWeight.w600, color: isDarkMode ? AppThemeData.grey200Dark : AppThemeData.grey900, fontSize: 13)),
                                  ],
                                ),
                                if (activeTaxes.isNotEmpty) ...[
                                  const SizedBox(height: 6),
                                  ...activeTaxes.map((tax) {
                                    final tAmt = Constant.calculateTaxFor(tax, tripPrice);
                                    final isPct = tax.type?.toLowerCase() == 'percentage';
                                    final label = isPct ? "${tax.libelle ?? 'GST'} (${tax.value}%)" : (tax.libelle ?? 'Tax');
                                    return Padding(
                                      padding: const EdgeInsets.symmetric(vertical: 2),
                                      child: Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          Text(label, style: TextStyle(color: isDarkMode ? AppThemeData.grey400Dark : AppThemeData.grey600, fontSize: 12)),
                                          Text(Constant().amountShow(amount: tAmt.toString()), style: TextStyle(color: isDarkMode ? AppThemeData.grey300Dark : AppThemeData.grey700, fontSize: 12)),
                                        ],
                                      ),
                                    );
                                  }),
                                ],
                                const Divider(height: 14, thickness: 0.8),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text("Total Payable".tr, style: TextStyle(fontWeight: FontWeight.bold, color: isDarkMode ? AppThemeData.grey100Dark : AppThemeData.grey900, fontSize: 14)),
                                    Text(Constant().amountShow(amount: grandTotal.toString()), style: TextStyle(fontWeight: FontWeight.bold, color: AppThemeData.primary200, fontSize: 15)),
                                  ],
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                      const SizedBox(height: 12),
                      // Book Button
                      Builder(
                        builder: (context) {
                          final selectedMethod = controller.paymentMethodType.value.toLowerCase();
                          final activeTaxes = Constant.getActiveTaxes(selectedMethod);
                          double totalTax = 0.0;
                          for (var t in activeTaxes) {
                            totalTax += Constant.calculateTaxFor(t, tripPrice);
                          }
                          final grandTotal = tripPrice + totalTax;

                          return ButtonThem.buildButton(
                            context,
                            btnHeight: 54,
                            title: "${"Book".tr} ${Constant().amountShow(amount: grandTotal.toString())}",
                            btnColor: AppThemeData.primary200,
                            txtColor: Colors.white,
                            onPress: () {
                              if (controller.paymentMethodType.value == "Select Method".tr) {
                                ShowToastDialog.showToast("Please select payment method".tr);
                              } else {
                                _bookRide(context, controller, driverData, tripPrice, passengerController);
                              }
                            },
                          );
                        },
                      ),
                      const SizedBox(height: 10),
                    ],
                  ),
                ),
              ),
            );
          });
        });
  }

  static void _resetPaymentMethods(HomeOsmController controller) {
    controller.stripe = false.obs;
    controller.wallet = false.obs;
    controller.cash = false.obs;
    controller.razorPay = false.obs;
    controller.paypal = false.obs;
    controller.payStack = false.obs;
    controller.flutterWave = false.obs;
    controller.mercadoPago = false.obs;
    controller.payFast = false.obs;
    controller.xendit = false.obs;
    controller.midtrans = false.obs;
    controller.orangePay = false.obs;
  }

  static void _bookRide(BuildContext context, HomeOsmController controller, DriverData driverData, double tripPrice, TextEditingController passengerController) {
    List stopsList = [];
    for (var i = 0; i < controller.multiStopListNew.length; i++) {
      stopsList.add({
        "latitude": controller.multiStopListNew[i].latitude.toString(),
        "longitude": controller.multiStopListNew[i].longitude.toString(),
        "location": controller.multiStopListNew[i].editingController.text.toString()
      });
    }

    Map<String, dynamic> bodyParams = {
      'user_id': Preferences.getInt(Preferences.userId).toString(),
      'lat1': controller.departureLatLong.value.latitude.toString(),
      'lng1': controller.departureLatLong.value.longitude.toString(),
      'lat2': controller.destinationLatLong.value.latitude.toString(),
      'lng2': controller.destinationLatLong.value.longitude.toString(),
      'cout': tripPrice.toString(),
      'distance': controller.distance.toString(),
      'distance_unit': Constant.distanceUnit.toString(),
      'duree': controller.duration.toString(),
      'id_conducteur': '0', // Broadcast mode
      'id_type_vehicule': controller.vehicleData.value.id.toString(),
      'id_payment': controller.paymentMethodId.value,
      'depart_name': controller.departureController.text,
      'destination_name': controller.destinationController.text,
      'stops': stopsList,
      'place': '',
      'number_poeple': passengerController.text,
      'image': '',
      'image_name': "",
      'statut_round': 'no',
      'trip_objective': controller.tripOptionCategory.value,
      'age_children1': controller.addChildList[0].editingController.text,
      'age_children2': controller.addChildList.length == 2 ? controller.addChildList[1].editingController.text : "",
      'age_children3': controller.addChildList.length == 3 ? controller.addChildList[2].editingController.text : "",
    };

    controller.bookRide(bodyParams).then((value) async {
      if (value != null) {
        if (value['success'] == "success") {
          Get.back();
          controller.departureController.clear();
          controller.destinationController.clear();
          controller.departureLatLong.value = GeoPoint(latitude: 0, longitude: 0);
          controller.destinationLatLong.value = GeoPoint(latitude: 0, longitude: 0);
          passengerController.clear();

          if (Constant.homeScreenType == 'UberHome') {
            controller.mapController.removeLastRoad();
            List<GeoPoint> allGeoPoints = controller.markers.values.toList();
            controller.mapController.removeMarkers(allGeoPoints);
            controller.getDirections();
          } else {
            controller.clearData();
          }
          Get.to(() => const SearchingDriverScreen(), arguments: {
            'rideData': RideData.fromJson(value['data']),
            'bookingBodyParams': bodyParams,
          });
        }
      }
    });
  }
}