import 'package:finway/constant/show_toast_dialog.dart';
import 'package:finway/controller/auth_otp_controller.dart';
import 'package:finway/page/MainDashBoard/screen/main_dashboard.dart';
import 'package:finway/themes/button_them.dart';
import 'package:finway/themes/constant_colors.dart';
import 'package:finway/utils/Preferences.dart';
import 'package:finway/utils/dark_theme_provider.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:provider/provider.dart';

class ProfileSetupScreen extends StatefulWidget {
  final String otp;
  final String mpin;

  const ProfileSetupScreen({super.key, required this.otp, required this.mpin});

  @override
  State<ProfileSetupScreen> createState() => _ProfileSetupScreenState();
}

class _ProfileSetupScreenState extends State<ProfileSetupScreen> {
  bool _isSubmitting = false;

  Future<void> _submitRegistration(BuildContext context, AuthOtpController controller) async {
    if (_isSubmitting || controller.isLoading.value) return;

    // Dismiss keyboard on submit click
    FocusScope.of(context).unfocus();
    FocusManager.instance.primaryFocus?.unfocus();

    final first = controller.firstNameController.value.text.trim();
    final last = controller.lastNameController.value.text.trim();
    final referral = controller.referralCodeController.value.text.trim();

    if (first.isEmpty) {
      ShowToastDialog.showToast('Please enter your first name.'.tr);
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    ShowToastDialog.showLoader('Creating account...'.tr);

    try {
      final user = await controller.registerSimple(
        phoneNumber: controller.phone.value,
        otp: widget.otp,
        mpin: widget.mpin,
        firstName: first,
        lastName: last,
        userCat: 'customer',
        referralCode: referral,
      );

      ShowToastDialog.closeLoader();

      final bool isLogin = Preferences.getBoolean(Preferences.isLogin);
      final String savedUserId = Preferences.getString(Preferences.userId);

      if (user != null || isLogin || savedUserId.isNotEmpty) {
        Get.offAll(() => const MainDashboard());
      } else {
        if (mounted) {
          setState(() {
            _isSubmitting = false;
          });
        }
      }
    } catch (e) {
      ShowToastDialog.closeLoader();
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
      ShowToastDialog.showToast(e.toString());
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeChange = Provider.of<DarkThemeProvider>(context);
    final bool isDark = themeChange.getThem();
    final controller = Get.find<AuthOtpController>();

    final bgColor = ConstantColors.background;
    final titleColor = ConstantColors.titleTextColor;
    final subtitleColor = ConstantColors.subTitleTextColor;
    final hintColor = ConstantColors.hintTextColor;
    final inputBg = isDark ? const Color(0xff1E293B) : Colors.white;
    final borderColor = ConstantColors.textFieldBoarderColor;

    InputDecoration inputDecoration(String label, String hint, IconData icon, {bool optional = false}) {
      return InputDecoration(
        labelText: optional ? '$label (Optional)' : label,
        labelStyle: TextStyle(color: hintColor, fontFamily: AppThemeData.regular, fontSize: 14),
        hintText: hint,
        hintStyle: TextStyle(color: hintColor, fontFamily: AppThemeData.regular),
        prefixIcon: Icon(icon, color: ConstantColors.primary, size: 20),
        filled: true,
        fillColor: inputBg,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: borderColor),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: borderColor),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: ConstantColors.primary, width: 1.5),
        ),
      );
    }

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded, color: titleColor, size: 20),
          onPressed: () => Get.back(),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 16),
              Text(
                'Complete your profile'.tr,
                style: TextStyle(
                  fontSize: 26,
                  fontFamily: AppThemeData.bold,
                  color: titleColor,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'This will be shown on your profile and ride receipts.'.tr,
                style: TextStyle(fontSize: 14, color: subtitleColor, fontFamily: AppThemeData.regular),
              ),

              const SizedBox(height: 36),

              // First name
              TextField(
                controller: controller.firstNameController.value,
                style: TextStyle(color: titleColor, fontFamily: AppThemeData.medium),
                textCapitalization: TextCapitalization.words,
                textInputAction: TextInputAction.next,
                decoration: inputDecoration('First name'.tr, 'e.g. Rahul', Icons.person_outline_rounded),
              ),

              const SizedBox(height: 16),

              // Last name
              TextField(
                controller: controller.lastNameController.value,
                style: TextStyle(color: titleColor, fontFamily: AppThemeData.medium),
                textCapitalization: TextCapitalization.words,
                textInputAction: TextInputAction.next,
                decoration: inputDecoration('Last name'.tr, 'e.g. Sharma', Icons.person_outline_rounded, optional: true),
              ),

              const SizedBox(height: 16),

              // Referral code (optional)
              TextField(
                controller: controller.referralCodeController.value,
                style: TextStyle(color: titleColor, fontFamily: AppThemeData.medium),
                textCapitalization: TextCapitalization.characters,
                textInputAction: TextInputAction.done,
                onSubmitted: (_) => _submitRegistration(context, controller),
                decoration: inputDecoration('Referral code'.tr, 'e.g. ab3f2', Icons.card_giftcard_rounded, optional: true),
              ),

              // Referral tip
              Padding(
                padding: const EdgeInsets.only(top: 6, left: 4),
                child: Text(
                  'Have a friend\'s referral code? Enter it above to reward them.'.tr,
                  style: TextStyle(fontSize: 12, color: hintColor, fontFamily: AppThemeData.regular),
                ),
              ),

              const SizedBox(height: 48),

              Obx(() => ButtonThem.buildButton(
                    context,
                    title: (_isSubmitting || controller.isLoading.value) ? 'Creating account...' : 'Complete Registration'.tr,
                    onPress: (_isSubmitting || controller.isLoading.value)
                        ? () {}
                        : () => _submitRegistration(context, controller),
                  )),

              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}
