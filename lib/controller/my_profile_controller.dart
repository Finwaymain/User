import 'dart:async';
import 'dart:convert';
import 'dart:developer';
import 'dart:io';
import 'package:finway/constant/constant.dart';
import 'package:finway/constant/logdata.dart';
import 'package:finway/constant/show_toast_dialog.dart';
import 'package:finway/model/user_model.dart';
import 'package:finway/service/api.dart';
import 'package:finway/utils/Preferences.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';

class MyProfileController extends GetxController {
  RxString userCat = "".obs;
  RxString photoPath = "".obs;
  RxString userId = ''.obs;
  Rx<XFile> imageData = XFile('').obs;

  var fullNameController = TextEditingController().obs;
  var lastNameController = TextEditingController().obs;
  var emailController = TextEditingController().obs;
  var phoneController = TextEditingController().obs;
  var alternatePhoneController = TextEditingController().obs;
  var countryCode = TextEditingController().obs;
  var marketplaceEnabled = true.obs;

  @override
  void onInit() {
    getUsrData();
    super.onInit();
  }

  getUsrData() async {
    UserModel userModel = Constant.getUserData();
    if (userModel.data == null) return; // not logged in yet
    fullNameController.value.text = userModel.data!.prenom ?? '';
    lastNameController.value.text = userModel.data!.nom ?? '';
    emailController.value.text = userModel.data!.email ?? '';
    phoneController.value.text = userModel.data!.phone ?? '';
    alternatePhoneController.value.text = userModel.data!.alternatePhone ?? '';
    marketplaceEnabled.value = (userModel.data!.marketplaceEnabled == '1' || userModel.data!.marketplaceEnabled == 1);
    userCat.value = userModel.data!.userCat ?? 'user_app';
    photoPath.value = userModel.data!.photoPath ?? '';
    countryCode.value.text = userModel.data!.country ?? '';
    userId.value = userModel.data!.id?.toString() ?? '';

    log("PhoneNumber :: ${userModel.toJson().toString()}");
  }

  Future<dynamic> uploadPhoto(File image) async {
    try {
      ShowToastDialog.showLoader("Please wait");

      var request = http.MultipartRequest(
        'POST',
        Uri.parse(API.uploadUserPhoto),
      );
      request.headers.addAll(API.header);

      request.files.add(http.MultipartFile.fromBytes('image', image.readAsBytesSync(), filename: image.path.split('/').last));
      request.fields['id_user'] = Preferences.getInt(Preferences.userId).toString();
      request.fields['user_cat'] = userCat.value;

      var res = await request.send();
      var responseData = await res.stream.toBytes();
      showLog("API :: URL :: ${API.uploadUserPhoto}");
      showLog("API :: Request Body :: ${jsonEncode(request.fields)} ");
      showLog("API :: Response Status :: ${res.statusCode} ");
      showLog("API :: Response Body :: ${String.fromCharCodes(responseData)} ");

      Map<String, dynamic> response = jsonDecode(String.fromCharCodes(responseData));

      if (res.statusCode == 200) {
        ShowToastDialog.closeLoader();
        ShowToastDialog.showToast("Uploaded!");
        return response;
      } else {
        ShowToastDialog.closeLoader();
        ShowToastDialog.showToast('Something want wrong. Please try again later');
        throw Exception('Failed to load album');
      }
    } on TimeoutException catch (e) {
      ShowToastDialog.closeLoader();
      ShowToastDialog.showToast(e.message.toString());
    } on SocketException catch (e) {
      ShowToastDialog.closeLoader();
      ShowToastDialog.showToast(e.message.toString());
    } on Error catch (e) {
      ShowToastDialog.closeLoader();
      ShowToastDialog.showToast(e.toString());
    } catch (e) {
      ShowToastDialog.closeLoader();
      ShowToastDialog.showToast(e.toString());
    }
  }

  // Future<dynamic> updateEmail(Map<String, String> bodyParams) async {
  //   try {
  //     ShowToastDialog.showLoader("Please wait");
  //     final response = await http.post(Uri.parse(API.updateUserEmail), headers: API.header, body: jsonEncode(bodyParams));
  //     Map<String, dynamic> responseBody = json.decode(response.body);
  //
  //
  //     if (response.statusCode == 200) {
  //       ShowToastDialog.closeLoader();
  //       return responseBody;
  //     } else {
  //       ShowToastDialog.closeLoader();
  //       ShowToastDialog.showToast('Something want wrong. Please try again later');
  //       throw Exception('Failed to load album');
  //     }
  //   } on TimeoutException catch (e) {
  //     ShowToastDialog.closeLoader();
  //     ShowToastDialog.showToast(e.message.toString());
  //   } on SocketException catch (e) {
  //     ShowToastDialog.closeLoader();
  //     ShowToastDialog.showToast(e.message.toString());
  //   } on Error catch (e) {
  //     ShowToastDialog.closeLoader();
  //     ShowToastDialog.showToast(e.toString());
  //   } catch (e) {
  //     ShowToastDialog.closeLoader();
  //     ShowToastDialog.showToast(e.toString());
  //   }
  //   return null;
  // }

  Future<dynamic> updateFirstName(Map<String, String> bodyParams) async {
    try {
      ShowToastDialog.showLoader("Please wait");
      final response = await http.post(Uri.parse(API.updatePreName), headers: API.header, body: jsonEncode(bodyParams));
      Map<String, dynamic> responseBody = json.decode(response.body);

      if (response.statusCode == 200) {
        ShowToastDialog.closeLoader();
        return responseBody;
      } else {
        ShowToastDialog.closeLoader();
        ShowToastDialog.showToast('Something want wrong. Please try again later');
        throw Exception('Failed to load album');
      }
    } on TimeoutException catch (e) {
      ShowToastDialog.closeLoader();
      ShowToastDialog.showToast(e.message.toString());
    } on SocketException catch (e) {
      ShowToastDialog.closeLoader();
      ShowToastDialog.showToast(e.message.toString());
    } on Error catch (e) {
      ShowToastDialog.closeLoader();
      ShowToastDialog.showToast(e.toString());
    } catch (e) {
      ShowToastDialog.closeLoader();
      ShowToastDialog.showToast(e.toString());
    }
    return null;
  }

  Future<dynamic> updateLastName(Map<String, String> bodyParams) async {
    try {
      ShowToastDialog.showLoader("Please wait");
      final response = await http.post(Uri.parse(API.updateLastName), headers: API.header, body: jsonEncode(bodyParams));
      showLog("API :: URL :: ${API.updateLastName}");
      showLog("API :: Request Body :: ${jsonEncode(bodyParams)} ");
      showLog("API :: Response Status :: ${response.statusCode} ");
      showLog("API :: Response Body :: ${response.body} ");
      Map<String, dynamic> responseBody = json.decode(response.body);

      if (response.statusCode == 200) {
        ShowToastDialog.closeLoader();
        return responseBody;
      } else {
        ShowToastDialog.closeLoader();
        ShowToastDialog.showToast('Something want wrong. Please try again later');
        throw Exception('Failed to load album');
      }
    } on TimeoutException catch (e) {
      ShowToastDialog.closeLoader();
      ShowToastDialog.showToast(e.message.toString());
    } on SocketException catch (e) {
      ShowToastDialog.closeLoader();
      ShowToastDialog.showToast(e.message.toString());
    } on Error catch (e) {
      ShowToastDialog.closeLoader();
      ShowToastDialog.showToast(e.toString());
    } catch (e) {
      ShowToastDialog.closeLoader();
      ShowToastDialog.showToast(e.toString());
    }
    return null;
  }

  Future<dynamic> updateAddress(Map<String, String> bodyParams) async {
    try {
      ShowToastDialog.showLoader("Please wait");
      final response = await http.post(Uri.parse(API.updateAddress), headers: API.authheader, body: jsonEncode(bodyParams));
      showLog("API :: URL :: ${API.updateAddress}");
      showLog("API :: Request Body :: ${jsonEncode(bodyParams)} ");
      showLog("API :: Response Status :: ${response.statusCode} ");
      showLog("API :: Response Body :: ${response.body} ");
      Map<String, dynamic> responseBody = json.decode(response.body);

      if (response.statusCode == 200) {
        ShowToastDialog.closeLoader();
        return responseBody;
      } else {
        ShowToastDialog.closeLoader();
        ShowToastDialog.showToast('Something want wrong. Please try again later');
        throw Exception('Failed to load album');
      }
    } on TimeoutException catch (e) {
      ShowToastDialog.closeLoader();
      ShowToastDialog.showToast(e.message.toString());
    } on SocketException catch (e) {
      ShowToastDialog.closeLoader();
      ShowToastDialog.showToast(e.message.toString());
    } on Error catch (e) {
      ShowToastDialog.closeLoader();
      ShowToastDialog.showToast(e.toString());
    } catch (e) {
      ShowToastDialog.closeLoader();
      ShowToastDialog.showToast(e.toString());
    }
    return null;
  }

  Future<dynamic> updatePassword(Map<String, String> bodyParams) async {
    try {
      ShowToastDialog.showLoader("Please wait");
      final response = await http.post(Uri.parse(API.changePassword), headers: API.header, body: jsonEncode(bodyParams));
      ShowToastDialog.closeLoader();
      showLog("API :: URL :: ${API.changePassword}");
      showLog("API :: Response Body :: ${response.body} ");
      Map<String, dynamic> responseBody = json.decode(response.body);

      if (responseBody['success'] == 'success' || responseBody['res'] == 'success') {
        return responseBody;
      } else {
        final errorMsg = responseBody['error'] ?? responseBody['msg'] ?? responseBody['message'] ?? 'Failed to update MPIN';
        ShowToastDialog.showToast(errorMsg.toString());
        return null;
      }
    } catch (e) {
      ShowToastDialog.closeLoader();
      ShowToastDialog.showToast(e.toString());
      return null;
    }
  }

  Future<dynamic> updateUser({File? image, required String name, required String lname, required String phoneNum, required String email, String? password}) async {
    try {
      ShowToastDialog.showLoader("Please wait");

      var request = http.MultipartRequest(
        'POST',
        Uri.parse(API.editProfile),
      );
      request.headers.addAll(API.header);
      request.fields['nom'] = lname;
      request.fields['prenom'] = name;
      request.fields['id_user'] = Preferences.getInt(Preferences.userId).toString();
      if (image?.path.isNotEmpty == true && image?.path != '') {
        request.files.add(http.MultipartFile.fromBytes('image', image!.readAsBytesSync(), filename: image.path.split('/').last));
      }
      request.fields['email'] = email;
      request.fields['phone'] = phoneNum;
      if (password?.isNotEmpty == true && password != '') {
        request.fields['mdp'] = password!;
      }
      var res = await request.send();

      var responseData = await res.stream.toBytes();
      showLog("API :: URL :: ${API.editProfile}");
      showLog("API :: Request Body :: ${jsonEncode(request.fields)} ");
      showLog("API :: Response Status :: ${res.statusCode} ");
      showLog("API :: Response Body :: ${String.fromCharCodes(responseData)} ");
      Map<String, dynamic> response = jsonDecode(String.fromCharCodes(responseData));

      if (res.statusCode == 200) {
        UserModel userModel = UserModel.fromJson(response);
        ShowToastDialog.closeLoader();
        ShowToastDialog.showToast("Profile update successfully!");
        return userModel;
      } else {
        ShowToastDialog.closeLoader();
        ShowToastDialog.showToast('Something want wrong. Please try again later');
        throw Exception('Failed to load album');
      }
    } on TimeoutException catch (e) {
      ShowToastDialog.closeLoader();
      ShowToastDialog.showToast(e.message.toString());
    } on SocketException catch (e) {
      ShowToastDialog.closeLoader();
      ShowToastDialog.showToast(e.message.toString());
    } on Error catch (e) {
      ShowToastDialog.closeLoader();
      ShowToastDialog.showToast(e.toString());
    } catch (e) {
      ShowToastDialog.closeLoader();
      ShowToastDialog.showToast(e.toString());
    }
  }

  // Future<UserModel?> updateUser(Map<String, String> bodyParams) async {
  //   try {
  //     ShowToastDialog.showLoader("Please wait");
  //     final response = await http.post(Uri.parse(API.editProfile), headers: API.authheader, body: jsonEncode(bodyParams));
  //     Map<String, dynamic> responseBody = json.decode(response.body);
  //     log("${response.statusCode} ::Profile :: $responseBody");
  //     if (response.statusCode == 200) {
  //       ShowToastDialog.closeLoader();
  //       Preferences.setString(Preferences.accesstoken, responseBody['data']['accesstoken'].toString());
  //       Preferences.setString(Preferences.admincommission, responseBody['data']['admin_commission'].toString());
  //       API.header['accesstoken'] = Preferences.getString(Preferences.accesstoken);
  //       return UserModel.fromJson(responseBody);
  //     } else {
  //       ShowToastDialog.closeLoader();
  //       ShowToastDialog.showToast('Something want wrong. Please try again later');
  //       throw Exception('Failed to load album');
  //     }
  //   } on TimeoutException catch (e) {
  //     ShowToastDialog.closeLoader();
  //     ShowToastDialog.showToast(e.message.toString());
  //   } on SocketException catch (e) {
  //     ShowToastDialog.closeLoader();
  //     ShowToastDialog.showToast(e.message.toString());
  //   } on Error catch (e) {
  //     ShowToastDialog.closeLoader();
  //     ShowToastDialog.showToast(e.toString());
  //   } catch (e) {
  //     ShowToastDialog.closeLoader();
  //     ShowToastDialog.showToast(e.toString());
  //   }
  //   return null;
  // }

  Future<dynamic> deleteAccount(String userId) async {
    try {
      ShowToastDialog.showLoader("Please wait");
      final response = await http.get(
        Uri.parse('${API.deleteUser}$userId&user_cat=customer'),
        headers: API.header,
      );
      showLog("API :: URL :: ${API.deleteUser}$userId&user_cat=customer");
      showLog("API :: Response Status :: ${response.statusCode} ");
      showLog("API :: Response Body :: ${response.body} ");
      Map<String, dynamic> responseBody = json.decode(response.body);

      if (response.statusCode == 200) {
        ShowToastDialog.closeLoader();
        return responseBody;
      } else {
        ShowToastDialog.closeLoader();
        ShowToastDialog.showToast('Something want wrong. Please try again later');
        throw Exception('Failed to load album');
      }
    } on TimeoutException catch (e) {
      ShowToastDialog.closeLoader();
      ShowToastDialog.showToast(e.message.toString());
    } on SocketException catch (e) {
      ShowToastDialog.closeLoader();
      ShowToastDialog.showToast(e.message.toString());
    } on Error catch (e) {
      ShowToastDialog.closeLoader();
      ShowToastDialog.showToast(e.toString());
    } catch (e) {
      ShowToastDialog.closeLoader();
      ShowToastDialog.showToast(e.toString());
    }
    return null;
  }

  var currentPasswordController = TextEditingController().obs;
  var newPasswordController = TextEditingController().obs;
  var confirmPasswordController = TextEditingController().obs;

  Future<bool> updateAlternatePhone(String phoneVal) async {
    try {
      ShowToastDialog.showLoader("Please wait");
      final bodyParams = {
        'id_user': userId.value,
        'alternate_phone': phoneVal,
        'user_cat': userCat.value,
      };
      final response = await http.post(
        Uri.parse(API.updateUserAlternatePhone),
        headers: API.header,
        body: jsonEncode(bodyParams),
      );
      showLog("API :: URL :: ${API.updateUserAlternatePhone}");
      showLog("API :: Request Body :: ${jsonEncode(bodyParams)} ");
      showLog("API :: Response Status :: ${response.statusCode} ");
      showLog("API :: Response Body :: ${response.body} ");
      Map<String, dynamic> responseBody = json.decode(response.body);

      if (response.statusCode == 200 && responseBody['success'] == 'success') {
        ShowToastDialog.closeLoader();
        UserModel updatedModel = Constant.getUserData();
        if (updatedModel.data != null) {
          updatedModel.data!.alternatePhone = phoneVal;
          Preferences.setString(Preferences.user, jsonEncode(updatedModel.toJson()));
        }
        alternatePhoneController.value.text = phoneVal;
        ShowToastDialog.showToast("Alternate phone updated successfully".tr);
        return true;
      } else {
        ShowToastDialog.closeLoader();
        ShowToastDialog.showToast(responseBody['error'] ?? 'Something went wrong. Please try again later'.tr);
      }
    } catch (e) {
      ShowToastDialog.closeLoader();
      ShowToastDialog.showToast(e.toString());
    }
    return false;
  }

  Future<void> showOtpVerificationDialog(BuildContext context, String phoneVal) async {
    final otpTextController = TextEditingController();
    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text("Verify Alternate Phone".tr),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text("${"Enter the 4-digit OTP sent to".tr} $phoneVal\n${"(Use dummy OTP 1234)".tr}"),
              const SizedBox(height: 16),
              TextField(
                controller: otpTextController,
                keyboardType: TextInputType.number,
                maxLength: 4,
                decoration: InputDecoration(
                  labelText: "OTP".tr,
                  hintText: "1234",
                  counterText: "",
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text("Cancel".tr),
            ),
            TextButton(
              onPressed: () async {
                if (otpTextController.text.trim() == "1234") {
                  Navigator.of(context).pop();
                  await updateAlternatePhone(phoneVal);
                } else {
                  ShowToastDialog.showToast("Invalid OTP".tr);
                }
              },
              child: Text("Verify".tr),
            ),
          ],
        );
      },
    );
  }

  Future<bool> toggleMarketplace(bool enabled) async {
    try {
      ShowToastDialog.showLoader("Please wait");
      final bodyParams = {
        'id_user': userId.value,
        'marketplace_enabled': enabled ? '1' : '0',
        'user_cat': userCat.value,
      };
      final response = await http.post(
        Uri.parse(API.userToggleMarketplace),
        headers: API.header,
        body: jsonEncode(bodyParams),
      );
      showLog("API :: URL :: ${API.userToggleMarketplace}");
      showLog("API :: Request Body :: ${jsonEncode(bodyParams)} ");
      showLog("API :: Response Status :: ${response.statusCode} ");
      showLog("API :: Response Body :: ${response.body} ");
      Map<String, dynamic> responseBody = json.decode(response.body);

      if (response.statusCode == 200 && responseBody['success'] == 'success') {
        ShowToastDialog.closeLoader();
        UserModel updatedModel = Constant.getUserData();
        if (updatedModel.data != null) {
          updatedModel.data!.marketplaceEnabled = enabled ? '1' : '0';
          Preferences.setString(Preferences.user, jsonEncode(updatedModel.toJson()));
        }
        marketplaceEnabled.value = enabled;
        ShowToastDialog.showToast("Marketplace setting updated successfully".tr);
        return true;
      } else {
        ShowToastDialog.closeLoader();
        ShowToastDialog.showToast(responseBody['error'] ?? 'Something went wrong. Please try again later'.tr);
      }
    } catch (e) {
      ShowToastDialog.closeLoader();
      ShowToastDialog.showToast(e.toString());
    }
    return false;
  }
}
