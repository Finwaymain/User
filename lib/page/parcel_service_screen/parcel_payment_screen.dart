import 'package:finway/constant/constant.dart';
import 'package:finway/constant/show_toast_dialog.dart';
import 'package:finway/controller/parcel_service_controller.dart';
import 'package:finway/themes/appbar_cust.dart';
import 'package:finway/themes/button_them.dart';
import 'package:finway/themes/constant_colors.dart';
import 'package:finway/themes/radio_button.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:finway/utils/dark_theme_provider.dart';
import 'package:provider/provider.dart';

class ParcelPaymentScreen extends StatelessWidget {
  const ParcelPaymentScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final themeChange = Provider.of<DarkThemeProvider>(context);
    bool isDarkMode = themeChange.getThem();

    return GetX<ParcelServiceController>(
        init: ParcelServiceController(),
        builder: (controller) {
          return Scaffold(
            resizeToAvoidBottomInset: true,
            appBar: CustomAppbar(
              bgColor: AppThemeData.primary200,
              title: 'Select Payment Method'.tr,
            ),
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
                        flex: 8,
                        child: Container(
                          color: isDarkMode ? AppThemeData.surface50Dark : AppThemeData.surface50,
                        ),
                      ),
                    ],
                  ),
                ),
                Column(
                  children: [
                    Expanded(
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SizedBox(
                              height: 20,
                            ),
                            Container(
                              decoration: BoxDecoration(
                                  color: isDarkMode ? AppThemeData.surface50Dark : AppThemeData.surface50,
                                  border: Border.all(
                                    color: isDarkMode ? AppThemeData.grey300Dark : AppThemeData.grey300,
                                  )),
                              child: Column(
                                  children: [
                                    RadioButtonCustom(
                                      image: "assets/icons/cash.png",
                                      name: "Cash",
                                      groupValue: controller.paymentMethodType.value,
                                      isEnabled: controller.paymentSettingModel.value.cash!.isEnabled == "true" ? true : false,
                                      isSelected: controller.cash.value,
                                      onClick: (String? value) {
                                        controller.stripe = false.obs;
                                        controller.wallet = false.obs;
                                        controller.cash = true.obs;
                                        controller.razorPay = false.obs;

                                        controller.paypal = false.obs;
                                        controller.payStack = false.obs;
                                        controller.flutterWave = false.obs;
                                        controller.mercadoPago = false.obs;
                                        controller.payFast = false.obs;
                                        controller.xendit = false.obs;
                                        controller.midtrans = false.obs;
                                        controller.orangePay = false.obs;
                                        controller.upi = false.obs;
                                        controller.paymentMethodType.value = value!;
                                        controller.paymentMethodId.value = controller.paymentSettingModel.value.cash!.idPaymentMethod.toString();
                                      },
                                    ),
                                    RadioButtonCustom(
                                      subName: Constant().amountShow(amount: controller.walletAmount.value),
                                      image: "assets/icons/walltet_icons.png",
                                      name: "Wallet",
                                      groupValue: controller.paymentMethodType.value,
                                      isEnabled: controller.paymentSettingModel.value.myWallet!.isEnabled == "true" ? true : false,
                                      isSelected: controller.wallet.value,
                                      onClick: (String? value) {
                                        controller.stripe = false.obs;
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
                                        controller.upi = false.obs;
                                        controller.wallet = true.obs;
                                        controller.paymentMethodType.value = value!;
                                        controller.paymentMethodId = controller.paymentSettingModel.value.myWallet!.idPaymentMethod.toString().obs;
                                      },
                                    ),
                                    RadioButtonCustom(
                                      image: "assets/icons/paytm_@3x.png",
                                      name: "UPI (Mock)",
                                      groupValue: controller.paymentMethodType.value,
                                      isEnabled: true,
                                      isSelected: controller.upi.value,
                                      onClick: (String? value) {
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
                                        controller.upi = true.obs;
                                        controller.paymentMethodType.value = value!;
                                        controller.paymentMethodId.value = controller.paymentSettingModel.value.cash!.idPaymentMethod.toString();
                                      },
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                      ),
                      child: ButtonThem.buildButton(
                        context,
                        title: "Pay".tr + " ${Constant().amountShow(amount: '${controller.subTotal.value}')}".tr,
                        btnColor: AppThemeData.primary200,
                        onPress: () {
                          if (controller.paymentMethodId.isEmpty) {
                            ShowToastDialog.showToast("Select Payment Option");
                          } else if (controller.wallet.value && double.parse(controller.walletAmount.value) < controller.subTotal.value) {
                            ShowToastDialog.showToast("Insufficient wallet balance");
                          } else if (controller.upi.value) {
                            controller.simulateUPILaunch(() {
                              controller.bookParcelRide();
                            });
                          } else {
                            controller.bookParcelRide();
                          }
                        },
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],
                ),
                if (controller.isSimulatingUPI.value)
                  Positioned.fill(
                    child: Container(
                      color: Colors.black.withValues(alpha: 0.7),
                      child: Center(
                        child: Card(
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                          color: isDarkMode ? AppThemeData.surface50Dark : Colors.white,
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 30),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                CircularProgressIndicator(color: AppThemeData.primary200),
                                const SizedBox(height: 24),
                                Text(
                                  controller.upiStepText.value,
                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          );
        });
  }
}
