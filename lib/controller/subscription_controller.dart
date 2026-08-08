import 'dart:async';
import 'dart:math';

import 'package:finway/constant/constant.dart';
import 'package:finway/constant/logdata.dart';
import 'package:finway/constant/show_toast_dialog.dart';
import 'package:finway/controller/dash_board_controller.dart';
import 'package:finway/model/payment_setting_model.dart';
import 'package:finway/model/razorpay_gen_orderid_model.dart';
import 'package:finway/model/subscription_plan_model.dart';
import 'package:finway/model/user_model.dart';
import 'package:finway/service/api.dart';
import 'package:finway/utils/Preferences.dart';
import 'package:get/get.dart';
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:flutter_stripe/flutter_stripe.dart';

class SubscriptionController extends GetxController {
  RxList<SubscriptionPlanData> subscriptionPlanList = <SubscriptionPlanData>[].obs;
  Rx<SubscriptionPlanData> selectedSubscriptionPlan = SubscriptionPlanData().obs;
  RxBool isLoading = true.obs;
  RxDouble totalAmount = 0.0.obs;
  Rx<UserModel> userModel = UserModel().obs;

  RxString selectedRadioTile = ''.obs;
  var paymentSettingModel = PaymentSettingModel().obs;

  RxBool wallet = false.obs;
  RxBool stripe = false.obs;
  RxBool razorPay = false.obs;
  RxBool paypal = false.obs;
  RxBool payStack = false.obs;
  RxBool flutterWave = false.obs;
  RxBool mercadoPago = false.obs;
  RxBool payFast = false.obs;
  RxBool xendit = false.obs;
  RxBool orangePay = false.obs;
  RxBool midtrans = false.obs;

  @override
  void onInit() {
    getInitData();
    super.onInit();
  }

  RxString ref = ''.obs;
  Future<void> getInitData() async {
    await getUsrData();
    await getPaymentSettingData();
    await getSubscription();
    setFlutterwaveRef();
    if (paymentSettingModel.value.strip?.isEnabled == 'true') {
      try {
        Stripe.publishableKey = paymentSettingModel.value.strip!.key!;
        Stripe.merchantIdentifier = "Fiinway";
        await Stripe.instance.applySettings();
      } catch (e) {
        showLog("Stripe initialization error: $e");
        // Continue without Stripe - other payment methods will still work
      }
    }
  }

  void setFlutterwaveRef() {
    Random numRef = Random();
    int year = DateTime.now().year;
    int refNumber = numRef.nextInt(20000);
    if (Platform.isAndroid) {
      ref.value = "AndroidRef$year$refNumber";
    } else if (Platform.isIOS) {
      ref.value = "IOSRef$year$refNumber";
    }
  }

  Future<void> getUsrData() async {
    userModel.value = Constant.getUserData();
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
        await Preferences.setString(Preferences.paymentSetting, jsonEncode(responseBody));
        paymentSettingModel.value = Constant.getPaymentSetting();
      }
    } catch (e) {
      // Silently fail - don't block UI
    }
    return null;
  }

  Future<bool> completeSubscription({bool redirect = false}) async {
    try {
      ShowToastDialog.showLoader("Please wait");
      Map<String, String> bodyParams = {
        "planId": selectedSubscriptionPlan.value.id.toString(),
        "userId": userModel.value.data!.id.toString(),
        "paymentType": selectedRadioTile.value
      };
      final response = await http.post(Uri.parse(API.setSubscription), headers: API.header, body: jsonEncode(bodyParams)).timeout(const Duration(seconds: 30));
      showLog("API :: URL :: ${API.setSubscription} ");
      showLog("API :: Request Body :: ${jsonEncode(bodyParams)} ");
      showLog("API :: responseStatus :: ${response.statusCode} ");
      showLog("API :: responseBody :: ${response.body} ");

      Map<String, dynamic> responseBody = json.decode(response.body);
      if (response.statusCode == 200 && responseBody['success'] == "success") {
        userModel.value.data?.consumerPlan = selectedSubscriptionPlan.value;
        userModel.value.data?.consumerPlanId = selectedSubscriptionPlan.value.id;
        await Preferences.setString(Preferences.user, jsonEncode(userModel.value));
        
        // Refresh dashboard controller user data
        if (Get.isRegistered<DashBoardController>()) {
          await Get.find<DashBoardController>().getUsrData();
        }
        
        ShowToastDialog.closeLoader();
        ShowToastDialog.showToast(responseBody['message'] ?? 'Subscription plan updated successfully!');
        return true;
      } else {
        ShowToastDialog.closeLoader();
        ShowToastDialog.showToast(responseBody['error'] ?? 'Something went wrong. Please try again later');
      }
    } catch (e) {
      ShowToastDialog.closeLoader();
      ShowToastDialog.showToast(e.toString());
    }
    return false;
  }

  Future<dynamic> getSubscription() async {
    try {
      showLog("API :: URL :: ${API.getSubscriptionPlans}");
      final response = await http.get(Uri.parse(API.getSubscriptionPlans), headers: API.header).timeout(const Duration(seconds: 10));
      showLog("API :: Response Status :: ${response.statusCode}");
      showLog("API :: Response Body :: ${response.body}");
      
      Map<String, dynamic> responseBody = json.decode(response.body);
      if (response.statusCode == 200 && responseBody['success'] == "success") {
        isLoading.value = false;
        SubscriptionPlanModel model = SubscriptionPlanModel.fromJson(responseBody);
        showLog("API :: Model Data Count :: ${model.data?.length ?? 0}");
        if (model.data?.isNotEmpty == true) {
          List<SubscriptionPlanData> subscriptionPlanData = model.data!;
          subscriptionPlanData.sort((a, b) {
            final aPlace = int.tryParse(a.place ?? '') ?? 0;
            final bPlace = int.tryParse(b.place ?? '') ?? 0;
            return aPlace.compareTo(bPlace);
          });
          
          subscriptionPlanList.clear();
          subscriptionPlanList.addAll(subscriptionPlanData);
          showLog("API :: Subscription Plan List Count :: ${subscriptionPlanList.length}");

          if (userModel.value.data?.consumerPlanId != null && userModel.value.data?.id != null) {
            for (int i = 0; i < subscriptionPlanList.length; i++) {
              if (subscriptionPlanList[i].id == userModel.value.data!.consumerPlanId) {
                selectedSubscriptionPlan.value = subscriptionPlanList[i];
              }
            }
          } else {
            selectedSubscriptionPlan.value = model.data!.first;
          }
        }
      } else {
        isLoading.value = false;
        showLog("API :: Error :: ${responseBody['error'] ?? 'Unknown error'}");
      }
    } catch (e) {
      isLoading.value = false;
      showLog("API :: Exception :: $e");
    }
    return null;
  }

  Future<dynamic> payStackURLGen({required String amount, required secretKey}) async {
    const url = "https://api.paystack.co/transaction/initialize";

    try {
      final response = await http.post(Uri.parse(url), body: {
        "email": userModel.value.data!.email ?? "demo@email.com",
        "amount": (double.parse(amount) * 100).toString(),
        "currency": "NGN",
      }, headers: {
        "Authorization": "Bearer $secretKey",
      });

      final responseBody = json.decode(response.body);
      if (response.statusCode == 200 && responseBody['status'] == true) {
        return responseBody;
      } else {
        ShowToastDialog.showToast(responseBody['error'] ?? 'Something went wrong. Please try again later');
      }
    } catch (e) {
      ShowToastDialog.showToast(e.toString());
    }
  }

  Future<dynamic> createStripeIntent({required String amount}) async {
    try {
      Map<String, dynamic> body = {
        'amount': ((double.parse(amount) * 100).round()).toString(),
        'currency': "USD",
        'payment_method_types[]': 'card',
        "description": "${Preferences.getInt(Preferences.userId)} Subscription Payment",
        "shipping[name]": "${userModel.value.data!.prenom ?? 'User'} ${userModel.value.data!.nom ?? ''}",
      };
      var stripeSecret = paymentSettingModel.value.strip!.secretKey;

      var response = await http.post(Uri.parse('https://api.stripe.com/v1/payment_intents'),
          body: body, headers: {'Authorization': 'Bearer $stripeSecret', 'Content-Type': 'application/x-www-form-urlencoded'});
      showLog("API :: URL :: https://api.stripe.com/v1/payment_intents");
      showLog("API :: Request Body :: ${jsonEncode(body)} ");
      showLog("API :: responseStatus :: ${response.statusCode} ");
      showLog("API :: responseBody :: ${response.body} ");
      return jsonDecode(response.body);
    } catch (e) {
      print("=====$e");
    }
  }

  Future<CreateRazorPayOrderModel?> createOrderRazorPay({required int amount}) async {
    final String orderId = "${Preferences.getInt(Preferences.userId)}_${DateTime.now().microsecondsSinceEpoch}";

    const url = "${API.baseUrl}payments/razorpay/createorder";

    try {
      final response = await http.post(
        Uri.parse(url),
        headers: {
          'apikey': API.apiKey,
          'accesstoken': Preferences.getString(Preferences.accesstoken),
        },
        body: {
          "amount": (amount * 100).toString(),
          "receipt_id": orderId,
          "currency": "INR",
          "razorpaykey": paymentSettingModel.value.razorpay!.key,
          "razorPaySecret": paymentSettingModel.value.razorpay!.secretKey,
          "isSandBoxEnabled": paymentSettingModel.value.razorpay!.isSandboxEnabled,
        },
      );
      showLog("API :: URL :: $url");
      showLog("API :: Request Body :: ${jsonEncode({
            "amount": (amount * 100).toString(),
            "receipt_id": orderId,
            "currency": "INR",
            "razorpaykey": paymentSettingModel.value.razorpay!.key,
            "razorPaySecret": paymentSettingModel.value.razorpay!.secretKey,
            "isSandBoxEnabled": paymentSettingModel.value.razorpay!.isSandboxEnabled,
          })} ");
      showLog("API :: Request Header :: ${{
        'apikey': API.apiKey,
        'accesstoken': Preferences.getString(Preferences.accesstoken),
      }.toString()} ");
      showLog("API :: responseStatus :: ${response.statusCode} ");
      showLog("API :: responseBody :: ${response.body} ");
      final responseBody = json.decode(response.body);

      if (response.statusCode == 200 && responseBody['id'] != null) {
        return CreateRazorPayOrderModel.fromJson(responseBody);
      } else {
        ShowToastDialog.showToast(responseBody['error'] ?? 'Something went wrong. Please try again later');
      }
    } catch (e) {
      ShowToastDialog.showToast(e.toString());
    }
    return null;
  }
}
