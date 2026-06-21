import 'dart:async';
import 'dart:convert';
import 'dart:developer';
import 'dart:io';
import 'package:finway/constant/constant.dart';
import 'package:finway/constant/show_toast_dialog.dart';
import 'package:finway/model/user_model.dart';
import 'package:finway/page/auth_screens/login_screen.dart';
import 'package:finway/page/features/Texi/texi_dash_board.dart';
import 'package:finway/page/favotite_ride_screens/favorite_ride_screen.dart';
import 'package:finway/page/localization_screens/localization_screen.dart';
import 'package:finway/page/my_profile/change_password_screen.dart';
import 'package:finway/page/my_profile/my_profile_screen.dart';
import 'package:finway/page/new_ride_screens/new_ride_screen.dart';
import 'package:finway/page/parcel_service_screen/all_parcel_screen.dart';
import 'package:finway/page/privacy_policy/privacy_policy_screen.dart';
import 'package:finway/page/referral_screen/referral_screen.dart';
import 'package:finway/page/rented_vehicle.dart';
import 'package:finway/page/terms_service/terms_of_service_screen.dart';
import 'package:finway/page/wallet/wallet_screen.dart';
import 'package:finway/service/api.dart';
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

  @override
  void onInit() {
    getUsrData();
    super.onInit();
  }

  setThemeMode(bool isDarkMode) async {
    var themeProvider = Provider.of<DarkThemeProvider>(Get.context!);
    themeProvider.darkTheme = (isDarkMode == true ? 0 : 1);
  }

  UserModel? userModel;

  getUsrData() async {
    userModel = Constant.getUserData();
    await getDrawerItems();
    await getTexiDrawerItems();
    if (Preferences.getBoolean(Preferences.isLogin)) {
      await updateToken();
      await getPaymentSettingData();
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
      DrawerItem(
        title: 'Rent Ride History'.tr,
        description: 'Track your previous rented ride activity here',
        icon: 'assets/icons/ic_fav.svg',
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
    drawerItems = [
      DrawerItem(
        title: 'Home'.tr,
        description: '',
        icon: 'assets/icons/ic_home.svg',
      ),
      DrawerItem(
        title: 'Wallet'.tr,
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
        title: 'Change Password'.tr,
        description: 'Update your password for better account security',
        icon: 'assets/icons/ic_lock.svg',
      ),
      DrawerItem(
        title: 'Refer a Friend'.tr,
        description: 'Share app link and earn referral rewards',
        icon: 'assets/icons/ic_refer.svg',
      ),
      DrawerItem(
        title: 'Change Language'.tr,
        description: 'Switch between supported languages anytime easily',
        icon: 'assets/icons/ic_language.svg',
        section: 'App Settings'.tr,
      ),
      DrawerItem(
        title: 'Terms & Conditions'.tr,
        description: 'Read detailed user agreement and policies',
        icon: 'assets/icons/ic_terms.svg',
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
    if( index == 1 || index == 2 || index == 3 || index == 4 ) {
      if(!isLogin){
        Get.to(LoginScreen());
        return;
      }
    }
    if (Constant.parcelActive.toString() == "yes") {

     if (index == 1) {

        Get.to(WalletScreen());
      } else if (index == 2) {
        Get.to(MyProfileScreen());
      } else if (index == 3) {
        Get.to(ChangePasswordScreen());
      } else if (index == 4) {
        Get.to(const ReferralScreen());
      } else if (index == 5) {
        Get.to(const LocalizationScreens(intentType: "dashBoard",));
      } else if (index == 6) {
        Get.to(const TermsOfServiceScreen());
      } else if (index == 7) {
        Get.to(const PrivacyPolicyScreen());
      } else if (index == 8) {
      } else if (index == 9) {

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
      } else if (index == 10) {
        Preferences.clearKeyData(Preferences.isLogin);
        Preferences.clearKeyData(Preferences.user);
        Preferences.clearKeyData(Preferences.userId);
        Get.offAll(const LoginScreen());
      } else {
        selectedDrawerIndex.value = index;
      }
    }
    else {
       if (index == 1) {
        Get.to(WalletScreen());
      } else if (index == 2) {
        Get.to(MyProfileScreen());
      } else if (index == 3) {
        Get.to(ChangePasswordScreen);
      } else if (index == 4) {
        Get.to(const ReferralScreen());
      } else if (index == 5) {
        Get.to(const LocalizationScreens(
          intentType: "dashBoard",
        ));
      } else if (index == 6) {
        Get.to(const TermsOfServiceScreen());
      } else if (index == 7) {
        Get.to(const PrivacyPolicyScreen());
      } else if (index == 8) {
      } else if (index == 9) {
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
      } else {
        if (index == 10) {
          Preferences.clearKeyData(Preferences.isLogin);
          Preferences.clearKeyData(Preferences.user);
          Preferences.clearKeyData(Preferences.userId);
          Get.offAll(const LoginScreen());
        } else {
          selectedDrawerIndex.value = index;
        }
      }
    }
  }

  onTexiSelectItem(int index) async {
    Get.back();
    if (Constant.parcelActive.toString() == "yes") {
      if (index == 1) {
        Get.to(const NewRideScreen());
      } else if (index == 2) {
        Get.to(const FavoriteRideScreen());
      } else if (index == 3) {
        Get.to(const RentedVehicleScreen());
      } else if (index == 4) {
        Get.to(const AllParcelScreen());
      } else if (index == 5) {
        Get.to(WalletScreen());
      } else if (index == 6) {
        Get.to(MyProfileScreen());
      } else if (index == 7) {
        Get.to(ChangePasswordScreen());
      } else if (index == 8) {
        Get.to(const ReferralScreen());
      } else if (index == 9) {
        Get.to(const LocalizationScreens(
          intentType: "dashBoard",
        ));
      } else if (index == 10) {
        Get.to(const TermsOfServiceScreen());
      } else if (index == 11) {
        Get.to(const PrivacyPolicyScreen());
      } else if (index == 12) {
      } else if (index == 13) {
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
      } else if (index == 14) {
        Preferences.clearKeyData(Preferences.isLogin);
        Preferences.clearKeyData(Preferences.user);
        Preferences.clearKeyData(Preferences.userId);
        Get.offAll(const LoginScreen());
      } else {
        selectedDrawerIndex.value = index;
      }
    } else {
      if (index == 1) {
        Get.to(const NewRideScreen());
      } else if (index == 2) {
        Get.to(const FavoriteRideScreen());
      } else if (index == 3) {
        Get.to(const RentedVehicleScreen());
      } else if (index == 4) {
        Get.to(WalletScreen());
      } else if (index == 5) {
        Get.to(MyProfileScreen());
      } else if (index == 6) {
        Get.to(ChangePasswordScreen);
      } else if (index == 7) {
        Get.to(const ReferralScreen());
      } else if (index == 8) {
        Get.to(const LocalizationScreens(
          intentType: "dashBoard",
        ));
      } else if (index == 9) {
        Get.to(const TermsOfServiceScreen());
      } else if (index == 10) {
        Get.to(const PrivacyPolicyScreen());
      } else if (index == 11) {
      } else if (index == 12) {
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
      } else {
        if (index == 13) {
          Preferences.clearKeyData(Preferences.isLogin);
          Preferences.clearKeyData(Preferences.user);
          Preferences.clearKeyData(Preferences.userId);
          Get.offAll(const LoginScreen());
        } else {
          selectedDrawerIndex.value = index;
        }
      }
    }
  }

  Future<dynamic> updateFCMToken(String token) async {
    try {
      Map<String, dynamic> bodyParams = {'user_id': Preferences.getInt(Preferences.userId), 'fcm_id': token, 'device_id': "", 'user_cat': userModel!.data!.userCat};
      final response = await http.post(Uri.parse(API.updateToken), headers: API.header, body: jsonEncode(bodyParams));
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
        Get.offAll(const LoginScreen());
      } else {
        ShowToastDialog.showToast('Something want wrong. Please try again later');
        throw Exception('Failed to load album');
      }
    } on TimeoutException catch (e) {
      ShowToastDialog.showToast(e.message.toString());
    } on SocketException catch (e) {
      ShowToastDialog.showToast(e.message.toString());
    } on Error catch (e) {
      ShowToastDialog.showToast(e.toString());
    } catch (e) {
      ShowToastDialog.showToast(e.toString());
    }
    return null;
  }

  Future<dynamic> getPaymentSettingData() async {
    try {
      final response = await http.get(Uri.parse(API.paymentSetting), headers: API.header);
      showLog("API :: URL :: ${API.paymentSetting} ");
      showLog("API :: Request Header :: ${API.header.toString()} ");
      showLog("API :: responseStatus :: ${response.statusCode} ");
      showLog("API :: responseBody :: ${response.body} ");
      Map<String, dynamic> responseBody = json.decode(response.body);
      if (response.statusCode == 200 && responseBody['success'] == "success") {
        Preferences.setString(Preferences.paymentSetting, jsonEncode(responseBody));
      } else if (response.statusCode == 200 && responseBody['success'] == "Failed") {
      } else {
        ShowToastDialog.showToast('Something want wrong. Please try again later');
        throw Exception('Failed to load album');
      }
    } on TimeoutException {
      // ShowToastDialog.showToast(e.message.toString());
    } on SocketException {
      // ShowToastDialog.showToast(e.message.toString());
    } on Error {
      // ShowToastDialog.showToast(e.toString());
    } catch (e) {
      ShowToastDialog.closeLoader();
      ShowToastDialog.showToast(e.toString());
    }
    return null;
  }
}
