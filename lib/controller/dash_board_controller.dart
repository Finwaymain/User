import 'dart:async';
import 'dart:convert';
import 'dart:developer';
import 'dart:io';
import 'package:finway/constant/constant.dart';
import 'package:finway/constant/show_toast_dialog.dart';
import 'package:finway/model/user_model.dart';
import 'package:finway/page/auth_screens/phone_entry_screen.dart';
import 'package:finway/page/features/Texi/texi_dash_board.dart';
import 'package:finway/page/favotite_ride_screens/favorite_ride_screen.dart';
import 'package:finway/page/my_profile/change_password_screen.dart';
import 'package:finway/page/my_profile/my_profile_screen.dart';
import 'package:finway/page/new_ride_screens/new_ride_screen.dart';
import 'package:finway/page/parcel_service_screen/all_parcel_screen.dart';
import 'package:finway/page/privacy_policy/privacy_policy_screen.dart';
import 'package:finway/page/referral/submit_aadhar_screen.dart';
import 'package:finway/page/referral_screen/referral_screen.dart';

import 'package:finway/page/terms_service/terms_of_service_screen.dart';
import 'package:finway/page/wallet/wallet_screen.dart';
import 'package:finway/service/api.dart';
import 'package:finway/service/app_version_service.dart';
import 'package:finway/utils/Preferences.dart';
import 'package:finway/utils/dark_theme_provider.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import 'package:in_app_review/in_app_review.dart';
import 'package:finway/constant/logdata.dart';

class DashBoardController extends GetxController {
  RxInt selectedDrawerIndex = 0.obs;
  RxBool darkModel = false.obs;
  Rx<UserModel?> userModel = Rx<UserModel?>(null);

  @override
  void onInit() {
    getUsrData();
    super.onInit();
  }

  setThemeMode(bool isDarkMode) async {
    var themeProvider = Provider.of<DarkThemeProvider>(Get.context!);
    themeProvider.darkTheme = (isDarkMode == true ? 0 : 1);
  }

  getUsrData() async {
    userModel.value = Constant.getUserData();
    getDrawerItems();
    getTexiDrawerItems();
    updateToken();
    getPaymentSettingData();
    // Fetch latest wallet balance
    await getWalletBalance();
    // Check for compulsory or optional Play Store updates
    AppVersionService.checkAppVersion(appType: 'customer');
  }

  Future<void> getWalletBalance() async {
    try {
      final response = await http.get(
        Uri.parse("${API.wallet}?id_user=${Preferences.getInt(Preferences.userId)}&user_cat=user_app"),
        headers: API.header,
      );
      showLog("API :: URL :: ${API.wallet}?id_user=${Preferences.getInt(Preferences.userId)}&user_cat=user_app");
      showLog("API :: responseStatus :: ${response.statusCode} ");
      showLog("API :: responseBody :: ${response.body} ");
      Map<String, dynamic> responseBody = json.decode(response.body);

      if (response.statusCode == 200 && responseBody['success'] == "success") {
        // Update wallet amount in user model
        if (userModel.value != null && userModel.value!.data != null && responseBody['data'] != null) {
          userModel.value!.data!.amount = responseBody['data']['amount']?.toString() ?? userModel.value!.data!.amount;
          userModel.value!.data!.earnAmount = responseBody['data']['earn_amount']?.toString() ?? userModel.value!.data!.earnAmount;
          // Save updated user data
          await Preferences.setString(Preferences.user, jsonEncode(userModel.value));
        }
      }
    } catch (e) {
      showLog("Error in getWalletBalance: $e");
    }
  }

  updateToken() async {
    // use the returned token to send messages to users from your custom server
    String? token = await FirebaseMessaging.instance.getToken();
    if (token != null) {
      updateFCMToken(token);
    }
  }


  getTexiDrawerItems() async {
    drawerTexiItems = [
      DrawerItem(
        title: 'All Rides'.tr,
        description: 'Manage taxi rides and parcel history easily',
        icon: 'assets/icons/ic_parcel.svg',
        section: '${'Ride'.tr}${Constant.parcelActive.toString() == "yes" ? ' and Parcel Management'.tr : ''}',
      ),
      DrawerItem(
        title: 'Favourite Rides'.tr,
        description: 'Access frequently booked rides in one tap',
        icon: 'assets/icons/ic_rent.svg',
      ),
      if (Constant.parcelActive.toString() == "yes")
        DrawerItem(
          title: 'Parcel History'.tr,
          description: 'View and manage all your parcel orders',
          icon: 'assets/icons/ic_car.svg',
        ),
    ];
  }


  // getDrawerItems() {
  //   drawerItems = [
  //     DrawerItem('Home'.tr, 'assets/icons/ic_home.svg' , ""),
  //
  //     DrawerItem('Wallet'.tr, 'assets/icons/ic_wallet.svg', section: 'Account & Payments'.tr),
  //     DrawerItem('My Profile'.tr, 'assets/icons/ic_profile.svg'),
  //     DrawerItem('Change Password'.tr, 'assets/icons/ic_lock.svg'),
  //     DrawerItem('Refer a Friend'.tr, 'assets/icons/ic_refer.svg'),
  //     DrawerItem('Change Language'.tr, 'assets/icons/ic_language.svg', section: 'App Settings'.tr),
  //     DrawerItem('Terms & Conditions'.tr, 'assets/icons/ic_terms.svg'),
  //     DrawerItem('Privacy & Policy'.tr, 'assets/icons/ic_privacy.svg'),
  //     DrawerItem('Dark Mode'.tr, 'assets/icons/ic_dark.svg', isSwitch: true),
  //     DrawerItem('Rate the App'.tr, 'assets/icons/ic_star_line.svg', section: 'Feedback & Support'.tr),
  //     DrawerItem('Log Out'.tr, 'assets/icons/ic_logout.svg'),
  //   ];
  // }
  getDrawerItems() {
    final bool hasAadhar = (Preferences.getString('user_aadhar_number') ?? '').isNotEmpty;
    final String partnerTitle = hasAadhar ? 'Partner Dashboard'.tr : 'Join as a Partner'.tr;
    final String partnerDesc = hasAadhar 
        ? 'Manage your partner team, view earnings and rewards'.tr 
        : 'Submit Aadhaar to become a partner and earn rewards'.tr;

    drawerItems = [
      DrawerItem(
        title: 'Home'.tr,
        description: '',
        icon: 'assets/icons/ic_home.svg',
      ),
      DrawerItem(
        title: 'Smart Value'.tr,
        description: 'Manage transactions, view balance and earnings',
        icon: 'assets/icons/ic_wallet.svg',
        section: 'Account & Payments'.tr,
      ),
      DrawerItem(
        title: 'My Profile'.tr,
        description: 'View and update your personal profile details',
        icon: 'assets/icons/ic_profile.svg',
      ),

      DrawerItem(
        title: partnerTitle,
        description: partnerDesc,
        icon: 'assets/icons/ic_refer.svg',
      ),
      DrawerItem(
        title: 'Terms & Conditions'.tr,
        description: 'Read detailed user agreement and policies',
        icon: 'assets/icons/ic_terms.svg',
        section: 'App Settings'.tr,
      ),
      DrawerItem(
        title: 'Privacy & Policy'.tr,
        description: 'Learn how we use and protect data',
        icon: 'assets/icons/ic_privacy.svg',
      ),
      DrawerItem(
        title: 'Dark Mode'.tr,
        description: '',
        icon: 'assets/icons/ic_dark.svg',
        isSwitch: true,
      ),
      DrawerItem(
        title: 'Rate the App'.tr,
        description: 'Give feedback and rate your app experience',
        icon: 'assets/icons/ic_star_line.svg',
        section: 'Feedback & Support'.tr,
      ),
      DrawerItem(
        title: 'Log Out'.tr,
        description: 'Sign out and return to login screen',
        icon: 'assets/icons/ic_logout.svg',
      ),
    ];
  }



  var drawerItems = [];
  var drawerTexiItems = [];
  final InAppReview inAppReview = InAppReview.instance;



  onSelectItem(int index,bool isLogin) async {
    Get.back();
    if (index >= drawerItems.length) return;
    var item = drawerItems[index];
    final bool hasAadhar = (Preferences.getString('user_aadhar_number') ?? '').isNotEmpty;
    final String partnerTitle = hasAadhar ? 'Partner Dashboard'.tr : 'Join as a Partner'.tr;

    if (item.title == 'Wallet'.tr || item.title == 'Smart Value'.tr || item.title == 'My Profile'.tr || item.title == 'Change Password'.tr || item.title == 'Join as a Partner'.tr || item.title == 'Partner Dashboard'.tr) {
      if (!isLogin) {
        Get.to(const PhoneEntryScreen());
        return;
      }
    }
    if (item.title == 'Wallet'.tr || item.title == 'Smart Value'.tr) {
      Get.to(WalletScreen());
    } else if (item.title == 'My Profile'.tr) {
      Get.to(MyProfileScreen());
    } else if (item.title == 'Change Password'.tr) {
      Get.to(ChangePasswordScreen());
    } else if (item.title == 'Join as a Partner'.tr || item.title == 'Partner Dashboard'.tr || item.title == partnerTitle) {
      Get.to(const ReferralScreen());
    } else if (item.title == 'Terms & Conditions'.tr) {
      Get.to(const TermsOfServiceScreen());
    } else if (item.title == 'Privacy & Policy'.tr) {
      Get.to(const PrivacyPolicyScreen());
    } else if (item.title == 'Rate the App'.tr) {
      try {
        if (await inAppReview.isAvailable()) {
          inAppReview.requestReview();
        } else {
          log(":::::::::InAppReview:::::::::::");
          inAppReview.openStoreListing();
        }
      } catch (e) {
        log("Error triggering in-app review: $e");
      }
    } else if (item.title == 'Log Out'.tr) {
      ShowToastDialog.showLoader("Logging out...");
      await updateFCMToken('');
      ShowToastDialog.closeLoader();
      Preferences.clearKeyData(Preferences.isLogin);
      Preferences.clearKeyData(Preferences.user);
      Preferences.clearKeyData(Preferences.userId);
      Get.offAll(const PhoneEntryScreen());
    } else {
      selectedDrawerIndex.value = index;
    }
  }

  onTexiSelectItem(int index) async {
    Get.back();
    if (index >= drawerTexiItems.length) return;
    var item = drawerTexiItems[index];
    if (item.title == 'All Rides'.tr) {
      Get.to(const NewRideScreen());
    } else if (item.title == 'Favourite Rides'.tr) {
      Get.to(const FavoriteRideScreen());
    } else if (item.title == 'Parcel History'.tr) {
      Get.to(const AllParcelScreen());
    } else {
      selectedDrawerIndex.value = index;
    }
  }

  Future<dynamic> updateFCMToken(String token) async {
    try {
      final intId = Preferences.getInt(Preferences.userId);
      final strId = Preferences.getString(Preferences.userId);
      final userId = intId > 0 ? intId.toString() : (strId.isNotEmpty ? strId : (userModel.value?.data?.id ?? ""));
      final phone = userModel.value?.data?.phone ?? "";

      Map<String, dynamic> bodyParams = {
        'user_id': userId,
        'phone': phone,
        'fcm_id': token,
        'device_id': "",
        'user_cat': userModel.value?.data?.userCat ?? "user_app"
      };
      final response = await http.post(Uri.parse(API.updateToken), headers: API.header, body: jsonEncode(bodyParams)).timeout(const Duration(seconds: 10));
      showLog("API :: URL :: ${API.updateToken} ");
      showLog("API :: Request Body :: ${jsonEncode(bodyParams)} ");
      showLog("API :: Request Header :: ${API.header.toString()} ");
      showLog("API :: responseStatus :: ${response.statusCode} ");
      showLog("API :: responseBody :: ${response.body} ");
      Map<String, dynamic> responseBody = json.decode(response.body);
      if (response.statusCode == 200) {
        return responseBody;
      } else if (response.statusCode == 401) {
        Preferences.clearKeyData(Preferences.isLogin);
        Preferences.clearKeyData(Preferences.user);
        Preferences.clearKeyData(Preferences.userId);
        ShowToastDialog.closeLoader();
        ShowToastDialog.showToast('An admin has deleted your account. You no longer have access.'.tr);
        Get.offAll(const PhoneEntryScreen());
      } else {
        // Silently fail - don't block UI
        throw Exception('Failed to load album');
      }
    } on TimeoutException catch (e) {
      // Silently fail - don't block UI
    } on SocketException catch (e) {
      // Silently fail - don't block UI
    } on Error catch (e) {
      // Silently fail - don't block UI
    } catch (e) {
      // Silently fail - don't block UI
    }
    return null;
  }

  Future<dynamic> getPaymentSettingData() async {
    try {
      final response = await http.get(Uri.parse(API.paymentSetting), headers: API.header).timeout(const Duration(seconds: 10));
      showLog("API :: URL :: ${API.paymentSetting} ");
      showLog("API :: Request Header :: ${API.header.toString()} ");
      showLog("API :: responseStatus :: ${response.statusCode} ");
      showLog("API :: responseBody :: ${response.body} ");
      Map<String, dynamic> responseBody = json.decode(response.body);
      if (response.statusCode == 200 && responseBody['success'] == "success") {
        Preferences.setString(Preferences.paymentSetting, jsonEncode(responseBody));
      } else if (response.statusCode == 200 && responseBody['success'] == "Failed") {
      } else {
        // Silently fail - don't block UI
        throw Exception('Failed to load album');
      }
    } on TimeoutException {
      // Silently fail - don't block UI
    } on SocketException {
      // Silently fail - don't block UI
    } on Error {
      // Silently fail - don't block UI
    } catch (e) {
      // Silently fail - don't block UI
    }
    return null;
  }
}
