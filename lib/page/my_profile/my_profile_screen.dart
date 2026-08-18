// ignore_for_file: must_be_immutable

import 'dart:convert';
import 'dart:io';
import 'package:finway/constant/constant.dart';
import 'package:finway/constant/show_toast_dialog.dart';
import 'package:finway/controller/auth_otp_controller.dart';
import 'package:finway/controller/dash_board_controller.dart';
import 'package:finway/controller/my_profile_controller.dart';
import 'package:finway/page/auth_screens/phone_entry_screen.dart';
import 'package:finway/themes/appbar_cust.dart';
import 'package:finway/themes/button_them.dart';
import 'package:finway/themes/constant_colors.dart';
import 'package:finway/themes/responsive.dart';
import 'package:finway/themes/text_field_them.dart';
import 'package:finway/utils/Preferences.dart';
import 'package:finway/utils/dark_theme_provider.dart';
import 'package:finway/model/user_model.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/svg.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl_phone_field/intl_phone_field.dart';
import 'package:intl_phone_field/countries.dart';
import 'package:provider/provider.dart';

import '../../constant/image_constant.dart';

class MyProfileScreen extends StatelessWidget {
  MyProfileScreen({super.key});

  final GlobalKey<FormState> _profileKey = GlobalKey();
  final dashboardController = Get.put(DashBoardController());
  final ImagePicker _imagePicker = ImagePicker();

  @override
  Widget build(BuildContext context) {
    final themeChange = Provider.of<DarkThemeProvider>(context);
    final isDark = themeChange.getThem();

    return GetX<MyProfileController>(
      init: MyProfileController(),
      builder: (myProfileController) {
        return Scaffold(
          resizeToAvoidBottomInset: true,
          appBar: CustomAppbar(
            title: 'My Profile'.tr,
            bgColor: AppThemeData.primary200,
          ),
          bottomNavigationBar: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            color: isDark ? AppThemeData.surface50Dark : AppThemeData.surface50,
            child: SafeArea(
              child: SizedBox(
                height: 56,
                child: buildShowDetails(
                  isTrailingShow: false,
                  textIconColor: AppThemeData.error200,
                  isDarkMode: isDark,
                  title: "Delete Account".tr,
                  icon: 'assets/icons/ic_delete.svg',
                  onPress: () async {
                    await showDialog(
                      context: context,
                      useSafeArea: true,
                      builder: (context) {
                        return AlertDialog(
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                          title: Text(
                            'Are you sure you want to delete account?'.tr,
                            style: const TextStyle(fontSize: 16),
                          ),
                          actions: [
                            Row(
                              children: [
                                Expanded(
                                  child: ButtonThem.buildButton(
                                    context,
                                    title: 'No'.tr,
                                    btnColor: Colors.grey.shade400,
                                    txtColor: Colors.white,
                                    onPress: () => Get.back(),
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: ButtonThem.buildButton(
                                    context,
                                    title: 'Yes'.tr,
                                    btnColor: AppThemeData.error200,
                                    txtColor: Colors.white,
                                    onPress: () {
                                      myProfileController.deleteAccount(Preferences.getInt(Preferences.userId).toString()).then((value) {
                                        if (value != null && value["success"] == "success") {
                                          ShowToastDialog.showToast(value['message']);
                                          Get.back();
                                          Preferences.clearSharPreference();
                                          Get.offAll(const PhoneEntryScreen());
                                        }
                                      });
                                    },
                                  ),
                                ),
                              ],
                            )
                          ],
                        );
                      },
                    );
                  },
                ),
              ),
            ),
          ),
          body: Stack(
            children: [
              Column(
                children: [
                  Expanded(
                    flex: 1,
                    child: Container(color: AppThemeData.primary200),
                  ),
                  Expanded(
                    flex: 8,
                    child: Container(
                      color: isDark ? AppThemeData.surface50Dark : AppThemeData.surface50,
                    ),
                  ),
                ],
              ),
              SafeArea(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Column(
                    children: [
                      Expanded(
                        child: SingleChildScrollView(
                          physics: const BouncingScrollPhysics(),
                          child: Form(
                            key: _profileKey,
                            child: Column(
                              children: [
                                const SizedBox(height: 20),
                                // Avatar Section with Smooth Border
                                Align(
                                  alignment: Alignment.center,
                                  child: Container(
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.black.withValues(alpha: 0.1),
                                          blurRadius: 10,
                                          offset: const Offset(0, 4),
                                        ),
                                      ],
                                    ),
                                    child: SizedBox(
                                      height: 120,
                                      width: 120,
                                      child: Stack(
                                        alignment: Alignment.bottomCenter,
                                        children: [
                                          Center(
                                            child: ClipRRect(
                                              borderRadius: BorderRadius.circular(100),
                                              child: myProfileController.imageData.value.path.isNotEmpty
                                                  ? Image.file(
                                                File(myProfileController.imageData.value.path),
                                                height: 120,
                                                width: 120,
                                                fit: BoxFit.cover,
                                              )
                                                  : CachedNetworkImage(
                                                imageUrl: myProfileController.photoPath.isNotEmpty
                                                    ? myProfileController.photoPath.toString()
                                                    : Constant.placeholderUrl,
                                                height: 120,
                                                width: 120,
                                                fit: BoxFit.cover,
                                                progressIndicatorBuilder: (context, url, downloadProgress) => Center(
                                                  child: CircularProgressIndicator(value: downloadProgress.progress),
                                                ),
                                                errorWidget: (context, url, error) => Image.asset(ImageConstant.logo),
                                              ),
                                            ),
                                          ),
                                          Align(
                                            alignment: Alignment.bottomRight,
                                            child: InkWell(
                                              onTap: () => buildBottomSheet(context, myProfileController),
                                              child: ClipOval(
                                                child: Container(
                                                  decoration: BoxDecoration(
                                                    color: AppThemeData.primary200,
                                                    borderRadius: BorderRadius.circular(50),
                                                  ),
                                                  padding: const EdgeInsets.all(8.0),
                                                  child: SvgPicture.asset(
                                                    'assets/icons/ic_edit.svg',
                                                    width: 20,
                                                    height: 20,
                                                    colorFilter: ColorFilter.mode(
                                                      isDark ? AppThemeData.grey900 : AppThemeData.grey900Dark,
                                                      BlendMode.srcIn,
                                                    ),
                                                  ),
                                                ),
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 30),

                                // Form Fields Container Card with Rounded Corners
                                Container(
                                  decoration: BoxDecoration(
                                    color: isDark ? AppThemeData.surface50Dark : Colors.white,
                                    borderRadius: BorderRadius.circular(20),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withValues(alpha: 0.04),
                                        blurRadius: 15,
                                        offset: const Offset(0, 5),
                                      ),
                                    ],
                                  ),
                                  padding: const EdgeInsets.all(16),
                                  child: Column(
                                    children: [
                                      Row(
                                        children: [
                                          Expanded(
                                            child: TextFieldWidget(
                                              prefix: IconButton(
                                                onPressed: () {},
                                                icon: SvgPicture.asset(
                                                  'assets/icons/ic_user.svg',
                                                  colorFilter: ColorFilter.mode(
                                                    isDark ? AppThemeData.grey500Dark : AppThemeData.grey300Dark,
                                                    BlendMode.srcIn,
                                                  ),
                                                ),
                                              ),
                                              hintText: 'Name'.tr,
                                              controller: myProfileController.fullNameController.value,
                                              textInputType: TextInputType.text,
                                              maxLength: 22,
                                              validators: (String? value) {
                                                return (value != null && value.isNotEmpty) ? null : 'required'.tr;
                                              },
                                            ),
                                          ),
                                          const SizedBox(width: 10),
                                          Expanded(
                                            child: TextFieldWidget(
                                              prefix: IconButton(
                                                onPressed: () {},
                                                icon: SvgPicture.asset(
                                                  'assets/icons/ic_user.svg',
                                                  colorFilter: ColorFilter.mode(
                                                    isDark ? AppThemeData.grey500Dark : AppThemeData.grey300Dark,
                                                    BlendMode.srcIn,
                                                  ),
                                                ),
                                              ),
                                              hintText: 'Last Name'.tr,
                                              controller: myProfileController.lastNameController.value,
                                              textInputType: TextInputType.text,
                                              maxLength: 22,
                                              validators: (String? value) {
                                                return (value != null && value.isNotEmpty) ? null : 'required'.tr;
                                              },
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 12),
                                      Container(
                                        decoration: BoxDecoration(
                                          borderRadius: BorderRadius.circular(12),
                                          border: Border.all(
                                            color: isDark ? AppThemeData.grey200Dark : AppThemeData.grey200,
                                            width: 0.8,
                                          ),
                                        ),
                                        child: IntlPhoneField(
                                          countries: countries.where((country) => country.code == 'IN').toList(),
                                          initialCountryCode: 'IN',
                                          textAlign: TextAlign.start,
                                          flagsButtonPadding: const EdgeInsets.only(left: 10, right: 10),
                                          readOnly: true,
                                          initialValue: myProfileController.phoneController.value.text,
                                          onChanged: (phone) {
                                            myProfileController.phoneController.value.text = phone.completeNumber;
                                          },
                                          invalidNumberMessage: "number invalid".tr,
                                          showDropdownIcon: false,
                                          disableLengthCheck: true,
                                          decoration: InputDecoration(
                                            border: InputBorder.none,
                                            focusedBorder: UnderlineInputBorder(
                                              borderSide: BorderSide(color: AppThemeData.primary200, width: 0.8),
                                            ),
                                            contentPadding: const EdgeInsets.symmetric(vertical: 14),
                                            hintText: 'Phone Number'.tr,
                                            isDense: true,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(height: 12),
                                      TextFieldWidget(
                                        isReadOnly: false,
                                        prefix: IconButton(
                                          onPressed: () {},
                                          icon: SvgPicture.asset(
                                            'assets/icons/ic_email.svg',
                                            colorFilter: ColorFilter.mode(
                                              isDark ? AppThemeData.grey500Dark : AppThemeData.grey300Dark,
                                              BlendMode.srcIn,
                                            ),
                                          ),
                                        ),
                                        hintText: 'email'.tr,
                                        controller: myProfileController.emailController.value,
                                        textInputType: TextInputType.emailAddress,
                                        validators: (String? value) {
                                          bool emailValid = RegExp(r'^.+@[a-zA-Z]+\.{1}[a-zA-Z]+(\.{0,1}[a-zA-Z]+)$').hasMatch(value ?? '');
                                          return emailValid ? null : 'email not valid'.tr;
                                        },
                                      ),
                                      const SizedBox(height: 10),
                                      SwitchListTile(
                                        title: Text(
                                          'Marketplace Visibility'.tr,
                                          style: TextStyle(
                                            color: isDark ? Colors.white : Colors.black87,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                        subtitle: Text(
                                          myProfileController.marketplaceEnabled.value
                                              ? 'Marketplace is active'.tr
                                              : 'Marketplace is disabled'.tr,
                                          style: TextStyle(
                                            color: isDark ? Colors.white70 : Colors.black54,
                                            fontSize: 12,
                                          ),
                                        ),
                                        value: myProfileController.marketplaceEnabled.value,
                                        activeColor: AppThemeData.primary200,
                                        onChanged: (bool value) {
                                          myProfileController.toggleMarketplace(value);
                                        },
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 16),

                                // Referral Code Card Container
                                Container(
                                  decoration: BoxDecoration(
                                    color: isDark ? AppThemeData.surface50Dark : Colors.white,
                                    borderRadius: BorderRadius.circular(20),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withValues(alpha: 0.04),
                                        blurRadius: 15,
                                        offset: const Offset(0, 5),
                                      ),
                                    ],
                                  ),
                                  child: _ReferralCodeCard(
                                    userId: Constant.getUserData().data?.id?.toString() ?? '',
                                    isDark: isDark,
                                  ),
                                ),
                                const SizedBox(height: 20),
                              ],
                            ),
                          ),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        child: ButtonThem.buildButton(
                          context,
                          title: 'Save Details'.tr,
                          onPress: () async {
                            FocusScope.of(context).unfocus();
                            if (_profileKey.currentState!.validate()) {
                              await myProfileController
                                  .updateUser(
                                image: File(myProfileController.imageData.value.path),
                                name: myProfileController.fullNameController.value.text.trim(),
                                lname: myProfileController.lastNameController.value.text.trim(),
                                email: myProfileController.emailController.value.text.trim(),
                                phoneNum: myProfileController.phoneController.value.text.trim(),
                                password: myProfileController.currentPasswordController.value.text.trim(),
                              )
                                  .then((value) {
                                if (value != null) {
                                  if (value.success == "success") {
                                    Preferences.setInt(Preferences.userId, int.parse(value.data!.id.toString()));
                                    Preferences.setString(Preferences.user, jsonEncode(value));
                                    Get.back();
                                  } else {
                                    ShowToastDialog.showToast(value.error);
                                  }
                                }
                              });
                            }
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget buildShowDetails({
    required String title,
    required String icon,
    required Function()? onPress,
    required bool isDarkMode,
    Color? textIconColor,
    bool? isTrailingShow = true,
  }) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      splashColor: Colors.transparent,
      leading: SvgPicture.asset(
        icon,
        width: 20,
        height: 20,
        colorFilter: ColorFilter.mode(
          textIconColor ?? (isDarkMode ? AppThemeData.grey900Dark : AppThemeData.grey900),
          BlendMode.srcIn,
        ),
      ),
      title: Text(
        title,
        style: TextStyle(
          fontSize: 15,
          fontFamily: AppThemeData.medium,
          color: textIconColor ?? (isDarkMode ? AppThemeData.grey900Dark : AppThemeData.grey900),
        ),
      ),
      onTap: onPress,
      trailing: isTrailingShow == false
          ? null
          : SvgPicture.asset(
        'assets/icons/ic_right_arrow.svg',
        width: 18,
        height: 18,
        colorFilter: ColorFilter.mode(
          isDarkMode ? AppThemeData.grey300Dark : AppThemeData.grey400,
          BlendMode.srcIn,
        ),
      ),
    );
  }

  buildBottomSheet(BuildContext context, MyProfileController controller) {
    return showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Container(
          height: Responsive.height(20, context),
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text(
                "Please Select".tr,
                style: TextStyle(
                  color: const Color(0XFF333333).withValues(alpha: 0.8),
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 10),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Column(
                      children: [
                        IconButton(
                          onPressed: () => pickFile(controller, source: ImageSource.camera),
                          icon: const Icon(Icons.camera_alt, size: 30),
                        ),
                        Text("camera".tr, style: const TextStyle(fontSize: 12)),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Column(
                      children: [
                        IconButton(
                          onPressed: () => pickFile(controller, source: ImageSource.gallery),
                          icon: const Icon(Icons.photo_library_sharp, size: 30),
                        ),
                        Text("gallery".tr, style: const TextStyle(fontSize: 12)),
                      ],
                    ),
                  )
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Future pickFile(MyProfileController controller, {required ImageSource source}) async {
    try {
      XFile? image = await _imagePicker.pickImage(source: source);
      if (image == null) return;
      Get.back();
      controller.imageData.value = image;
      controller.uploadPhoto(File(image.path)).then((value) {
        if (value != null && value["success"] == "Success") {
          UserModel userModel = Constant.getUserData();
          userModel.data!.photoPath = value['data']['photo_path'];
          Preferences.setString(Preferences.user, jsonEncode(userModel.toJson()));
          controller.getUsrData();
          dashboardController.getUsrData();
          ShowToastDialog.showToast("Upload successfully!".tr);
        } else if (value != null) {
          ShowToastDialog.showToast(value['error']);
        }
      });
    } on PlatformException catch (e) {
      ShowToastDialog.showToast("${"Failed to Pick :".tr}\n $e");
    }
  }
}

// ══════════════════════════════════════════════════════════════════════════════
// REFERRAL CODE CARD (shown in profile — lets user apply a referral code
// if they missed it during registration)
// ══════════════════════════════════════════════════════════════════════════════
class _ReferralCodeCard extends StatefulWidget {
  final String userId;
  final bool isDark;

  const _ReferralCodeCard({
    required this.userId,
    required this.isDark,
  });

  @override
  State<_ReferralCodeCard> createState() => _ReferralCodeCardState();
}

class _ReferralCodeCardState extends State<_ReferralCodeCard> {
  final _codeController = TextEditingController();
  bool _applying = false;
  bool _applied = false;

  @override
  void dispose() {
    _codeController.dispose();
    super.dispose();
  }

  Future<void> _apply() async {
    final code = _codeController.text.trim();
    if (code.isEmpty) {
      ShowToastDialog.showToast('Please enter a referral code'.tr);
      return;
    }
    setState(() => _applying = true);
    final controller = Get.put(AuthOtpController());
    final ok = await controller.applyReferralCode(
      widget.userId,
      code,
      userCat: 'customer',
    );
    setState(() {
      _applying = false;
      if (ok) _applied = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    final cardBg = widget.isDark ? AppThemeData.surface50Dark : Colors.white;
    final borderColor = widget.isDark ? AppThemeData.grey200Dark : AppThemeData.grey200;
    final textPrimary = widget.isDark ? AppThemeData.grey900Dark : AppThemeData.grey900;
    final textSecondary = widget.isDark ? AppThemeData.grey400Dark : AppThemeData.grey400;
    final primaryColor = AppThemeData.primary200;
    final inputBg = widget.isDark ? const Color(0xFF0F172A) : const Color(0xFFF1F5F9);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: primaryColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(Icons.card_giftcard_rounded, color: primaryColor, size: 18),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Enter Referral Code'.tr,
                      style: TextStyle(
                        fontFamily: AppThemeData.bold,
                        fontSize: 14,
                        color: textPrimary,
                      ),
                    ),
                    Text(
                      'Reward the friend who invited you'.tr,
                      style: TextStyle(
                        fontFamily: AppThemeData.regular,
                        fontSize: 12,
                        color: textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          if (_applied) ...[
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: Colors.green.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.green.withValues(alpha: 0.3)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.check_circle_rounded, color: Colors.green, size: 18),
                  const SizedBox(width: 8),
                  Text(
                    'Referral code applied successfully!'.tr,
                    style: const TextStyle(
                      fontFamily: AppThemeData.medium,
                      fontSize: 13,
                      color: Colors.green,
                    ),
                  ),
                ],
              ),
            ),
          ] else ...[
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _codeController,
                    textCapitalization: TextCapitalization.characters,
                    style: TextStyle(
                      fontFamily: AppThemeData.medium,
                      color: textPrimary,
                      fontSize: 14,
                      letterSpacing: 1.5,
                    ),
                    decoration: InputDecoration(
                      hintText: 'e.g. ab3f2'.tr,
                      hintStyle: TextStyle(
                        fontFamily: AppThemeData.regular,
                        color: textSecondary,
                        fontSize: 13,
                        letterSpacing: 0,
                      ),
                      filled: true,
                      fillColor: inputBg,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide(color: borderColor),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide(color: borderColor),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide(color: primaryColor, width: 1.5),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                SizedBox(
                  height: 48,
                  child: ElevatedButton(
                    onPressed: _applying ? null : _apply,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primaryColor,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      elevation: 0,
                    ),
                    child: _applying
                        ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                        : Text('Apply'.tr, style: const TextStyle(color: Colors.white, fontFamily: AppThemeData.bold, fontSize: 13)),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'You can only apply a referral code once.'.tr,
              style: TextStyle(fontFamily: AppThemeData.regular, fontSize: 11, color: textSecondary),
            ),
          ],
        ],
      ),
    );
  }
}