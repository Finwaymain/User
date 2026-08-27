// ignore_for_file: must_be_immutable

import 'package:finway/constant/show_toast_dialog.dart';
import 'package:finway/controller/bank_details_controller.dart';
import 'package:finway/themes/button_them.dart';
import 'package:finway/themes/constant_colors.dart';
import 'package:finway/themes/text_field_them.dart';
import 'package:finway/utils/dark_theme_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart';
import 'package:provider/provider.dart';

class AddBankAccount extends StatelessWidget {
  const AddBankAccount({
    super.key,
  });

  Widget dividerCust({required bool isDarkMode}) {
    return Divider(
      height: 1,
      thickness: 1,
      color: isDarkMode ? AppThemeData.grey200Dark : AppThemeData.grey200,
    );
  }

  @override
  Widget build(BuildContext context) {
    final themeChange = Provider.of<DarkThemeProvider>(context);
    return GetX<BankDetailsController>(
        init: BankDetailsController(),
        builder: (controller) {
          return Container(
            decoration: BoxDecoration(
              color: themeChange.getThem() ? AppThemeData.surface50Dark : AppThemeData.surface50,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(20),
                topRight: Radius.circular(20),
              ),
            ),
            child: Padding(
              padding: MediaQuery.of(context).viewInsets,
              child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                        margin: const EdgeInsets.symmetric(vertical: 10),
                        height: 10,
                        width: 75,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(100),
                          color: themeChange.getThem() ? AppThemeData.grey300Dark : AppThemeData.grey300,
                        )),
                  ),
                  const SizedBox(
                    height: 10,
                  ),
                  InkWell(
                      onTap: () {
                        Get.back();
                      },
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Transform(
                          alignment: Alignment.center,
                          transform: Directionality.of(context) == TextDirection.rtl ? Matrix4.rotationY(3.14159) : Matrix4.identity(),
                          child: SvgPicture.asset(
                            'assets/icons/ic_left.svg',
                            colorFilter: ColorFilter.mode(
                              themeChange.getThem() ? AppThemeData.grey900Dark : AppThemeData.grey900,
                              BlendMode.srcIn,
                            ),
                          ),
                        ),
                      )),
                  const SizedBox(
                    height: 10,
                  ),
                  Form(
                    key: controller.formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: Text(
                            'Add Bank'.tr,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: themeChange.getThem() ? AppThemeData.grey900Dark : AppThemeData.grey900,
                              fontSize: 18,
                              fontFamily: AppThemeData.semiBold,
                            ),
                          ),
                        ),
                        Container(
                          margin: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
                          decoration: BoxDecoration(
                              color: themeChange.getThem() ? AppThemeData.surface50Dark : AppThemeData.surface50,
                              border: Border.all(color: themeChange.getThem() ? AppThemeData.grey200Dark : AppThemeData.grey200, width: 1),
                              borderRadius: const BorderRadius.all(Radius.circular(12))),
                          child: Padding(
                            padding: const EdgeInsets.all(4.0),
                            child: Column(
                              children: [
                                TextFieldWidget(
                                  prefix: IconButton(
                                    onPressed: () {},
                                    icon: SvgPicture.asset(
                                      'assets/icons/ic_bank_2.svg',
                                      width: 25,
                                      height: 25,
                                      fit: BoxFit.cover,
                                      colorFilter: ColorFilter.mode(
                                        themeChange.getThem() ? AppThemeData.grey200 : AppThemeData.grey500Dark,
                                        BlendMode.srcIn,
                                      ),
                                    ),
                                  ),
                                  controller: controller.bankNameController.value,
                                  textInputType: TextInputType.text,
                                  validators: (String? value) {
                                    if (value == null || value.trim().isEmpty) {
                                      return 'Bank Name is required'.tr;
                                    }
                                    if (!RegExp(r'^[a-zA-Z\s]+$').hasMatch(value.trim())) {
                                      return 'Bank name must contain only letters (no numbers or symbols)'.tr;
                                    }
                                    return null;
                                  },
                                  hintText: 'Bank Name (Words only)'.tr,
                                ),
                                dividerCust(isDarkMode: themeChange.getThem()),
                                TextFieldWidget(
                                  prefix: IconButton(
                                    onPressed: () {},
                                    icon: SvgPicture.asset(
                                      'assets/icons/ic_bank_2.svg',
                                      width: 25,
                                      height: 25,
                                      fit: BoxFit.cover,
                                      colorFilter: ColorFilter.mode(
                                        themeChange.getThem() ? AppThemeData.grey200 : AppThemeData.grey500Dark,
                                        BlendMode.srcIn,
                                      ),
                                    ),
                                  ),
                                  controller: controller.branchNameController.value,
                                  textInputType: TextInputType.text,
                                  validators: (String? value) {
                                    if (value != null && value.isNotEmpty) {
                                      return null;
                                    } else {
                                      return 'required'.tr;
                                    }
                                  },
                                  hintText: 'Branch Name'.tr,
                                ),
                                dividerCust(isDarkMode: themeChange.getThem()),
                                TextFieldWidget(
                                  prefix: IconButton(
                                    onPressed: () {},
                                    icon: SvgPicture.asset(
                                      'assets/icons/ic_user.svg',
                                      width: 25,
                                      height: 25,
                                      fit: BoxFit.cover,
                                      colorFilter: ColorFilter.mode(
                                        themeChange.getThem() ? AppThemeData.grey200 : AppThemeData.grey500Dark,
                                        BlendMode.srcIn,
                                      ),
                                    ),
                                  ),
                                  controller: controller.holderNameController.value,
                                  textInputType: TextInputType.text,
                                  validators: (String? value) {
                                    if (value == null || value.trim().isEmpty) {
                                      return 'Holder Name is required'.tr;
                                    }
                                    if (!RegExp(r'^[a-zA-Z\s]+$').hasMatch(value.trim())) {
                                      return 'Holder name must contain only letters'.tr;
                                    }
                                    return null;
                                  },
                                  hintText: 'Account Holder Name'.tr,
                                ),
                                dividerCust(isDarkMode: themeChange.getThem()),
                                TextFieldWidget(
                                  prefix: IconButton(
                                    onPressed: () {},
                                    icon: SvgPicture.asset(
                                      'assets/icons/ic_number.svg',
                                      width: 25,
                                      height: 25,
                                      fit: BoxFit.cover,
                                      colorFilter: ColorFilter.mode(
                                        themeChange.getThem() ? AppThemeData.grey200 : AppThemeData.grey500Dark,
                                        BlendMode.srcIn,
                                      ),
                                    ),
                                  ),
                                  controller: controller.accountNumberController.value,
                                  textInputType: TextInputType.number,
                                  validators: (String? value) {
                                    if (value == null || value.trim().isEmpty) {
                                      return 'Account Number is required'.tr;
                                    }
                                    if (!RegExp(r'^[0-9]+$').hasMatch(value.trim())) {
                                      return 'Account number must contain only numbers'.tr;
                                    }
                                    if (value.trim().length < 8 || value.trim().length > 22) {
                                      return 'Account number must be between 9 and 18 digits'.tr;
                                    }
                                    return null;
                                  },
                                  hintText: 'Account Number (Numbers only)'.tr,
                                ),
                                dividerCust(isDarkMode: themeChange.getThem()),
                                TextFieldWidget(
                                  prefix: IconButton(
                                    onPressed: () {},
                                    icon: SvgPicture.asset(
                                      'assets/icons/ic_barcode.svg',
                                      width: 25,
                                      height: 25,
                                      fit: BoxFit.cover,
                                      colorFilter: ColorFilter.mode(
                                        themeChange.getThem() ? AppThemeData.grey200 : AppThemeData.grey500Dark,
                                        BlendMode.srcIn,
                                      ),
                                    ),
                                  ),
                                  controller: controller.ifscCodeController.value,
                                  textInputType: TextInputType.text,
                                  validators: (String? value) {
                                    if (value == null || value.trim().isEmpty) {
                                      return 'IFSC Code is required'.tr;
                                    }
                                    if (!RegExp(r'^[A-Za-z0-9]{11}$').hasMatch(value.trim())) {
                                      return 'IFSC code must be 11 alphanumeric characters'.tr;
                                    }
                                    return null;
                                  },
                                  hintText: 'IFSC Code (e.g. SBIN0001234)'.tr,
                                ),
                                dividerCust(isDarkMode: themeChange.getThem()),
                                TextFieldWidget(
                                  prefix: IconButton(
                                    onPressed: () {},
                                    icon: SvgPicture.asset(
                                      'assets/icons/ic_list.svg',
                                      width: 25,
                                      height: 25,
                                      fit: BoxFit.cover,
                                      colorFilter: ColorFilter.mode(
                                        themeChange.getThem() ? AppThemeData.grey200 : AppThemeData.grey500Dark,
                                        BlendMode.srcIn,
                                      ),
                                    ),
                                  ),
                                  controller: controller.otherInformationController.value,
                                  textInputType: TextInputType.text,
                                  validators: (String? value) {
                                    if (value!.isNotEmpty) {
                                      return null;
                                    } else {
                                      return 'required'.tr;
                                    }
                                  },
                                  hintText: 'Other Informations'.tr,
                                ),
                              ],
                            ),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.only(bottom: 16, left: 16, right: 16, top: 16),
                          child: ButtonThem.buildButton(context,
                              title: "Save Bank Details".tr,
                              btnColor: AppThemeData.primary200,
                              txtColor: themeChange.getThem() ? AppThemeData.grey900 : AppThemeData.grey900Dark, onPress: () {
                            if (controller.formKey.currentState!.validate()) {
                              Map<String, String> bodyParams = {
                                'user_id': controller.userId,
                                'driver_id': controller.userId,
                                'user_type': 'customer',
                                'bank_name': controller.bankNameController.value.text,
                                'branch_name': controller.branchNameController.value.text,
                                'holder_name': controller.holderNameController.value.text,
                                'account_no': controller.accountNumberController.value.text,
                                'information': controller.otherInformationController.value.text,
                                'ifsc_code': controller.ifscCodeController.value.text
                              };

                              controller.setBankDetails(bodyParams).then((value) {
                                if (value != null) {
                                  Get.back(result: true);
                                } else {
                                  ShowToastDialog.showToast("Something went wrong.");
                                }
                              });
                            }
                          }),
                        )
                      ],
                    ),
                  )
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
