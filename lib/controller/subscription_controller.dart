import 'dart:async';
import 'dart:math';

import 'package:finway/constant/constant.dart';
import 'package:finway/constant/logdata.dart';
import 'package:finway/constant/show_toast_dialog.dart';
import 'package:finway/controller/dash_board_controller.dart';
import 'package:finway/controller/wallet_controller.dart';
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
  RxString loadError = ''.obs;
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
    super.onInit();
    refreshAll();
  }

  RxString ref = ''.obs;

  Future<void> refreshAll() async {
    isLoading.value = true;
    loadError.value = '';
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
      showLog("API :: responseStatus :: ${response.statusCode} ");
      Map<String, dynamic> responseBody = json.decode(response.body);
      if (response.statusCode == 200 && responseBody['success'] == "success") {
        await Preferences.setString(Preferences.paymentSetting, jsonEncode(responseBody));
        paymentSettingModel.value = Constant.getPaymentSetting();
      }
    } catch (e) {
      paymentSettingModel.value = Constant.getPaymentSetting();
    }
    return null;
  }

  Future<bool> completeSubscription({bool redirect = false, String? mpin}) async {
    final planId = selectedSubscriptionPlan.value.id;
    final userId = userModel.value.data?.id;

    if (planId == null || planId.isEmpty) {
      ShowToastDialog.showToast('Please select a subscription plan');
      return false;
    }
    if (userId == null || userId.isEmpty) {
      ShowToastDialog.showToast('Please login to purchase a plan');
      return false;
    }
    if (selectedRadioTile.value.isEmpty) {
      ShowToastDialog.showToast('Please select a payment method');
      return false;
    }

    try {
      ShowToastDialog.showLoader("Please wait");
      final bodyParams = {
        "planId": planId,
        "userId": userId,
        "paymentType": selectedRadioTile.value,
        if (mpin != null && mpin.isNotEmpty) "mpin": mpin,
      };
      final response = await http
          .post(Uri.parse(API.setSubscription), headers: API.header, body: jsonEncode(bodyParams))
          .timeout(const Duration(seconds: 30));
      showLog("API :: URL :: ${API.setSubscription} ");
      showLog("API :: Request Body :: ${jsonEncode(bodyParams)} ");
      showLog("API :: responseStatus :: ${response.statusCode} ");
      showLog("API :: responseBody :: ${response.body} ");

      final rawBody = response.body.trim();
      if (rawBody.isEmpty || rawBody.startsWith('<!DOCTYPE') || rawBody.startsWith('<html')) {
        ShowToastDialog.closeLoader();
        ShowToastDialog.showToast('Server error while activating plan. Please try again.');
        return false;
      }

      final responseBody = json.decode(rawBody);
      if (response.statusCode == 200 && responseBody['success'] == "success") {
        await _applySubscriptionSuccess(responseBody);
        ShowToastDialog.closeLoader();
        ShowToastDialog.showToast(responseBody['message'] ?? 'Subscription plan updated successfully!');
        return true;
      } else {
        ShowToastDialog.closeLoader();
        ShowToastDialog.showToast(responseBody['message'] ?? responseBody['error'] ?? 'Something went wrong. Please try again later');
      }
    } on TimeoutException {
      ShowToastDialog.closeLoader();
      ShowToastDialog.showToast('Request timed out. Please try again.');
    } catch (e) {
      ShowToastDialog.closeLoader();
      ShowToastDialog.showToast(e.toString());
    }
    return false;
  }

  Future<void> _applySubscriptionSuccess(Map<String, dynamic> responseBody) async {
    final plan = selectedSubscriptionPlan.value;
    final user = userModel.value.data;
    if (user == null) return;

    user.consumerPlanId = plan.id;
    user.consumerPlan = plan;

    final data = responseBody['data'];
    if (data is Map<String, dynamic>) {
      user.consumerPlanId = data['consumer_plan_id']?.toString() ?? plan.id;
      user.consumerPlanExpiryDate = data['consumer_plan_expiry_date']?.toString();
      if (data['amount'] != null) {
        user.amount = data['amount']?.toString();
      }
      if (data['consumer_plan'] is Map<String, dynamic>) {
        user.consumerPlan = SubscriptionPlanData.fromJson(Map<String, dynamic>.from(data['consumer_plan']));
        selectedSubscriptionPlan.value = user.consumerPlan!;
      }
    } else {
      final days = int.tryParse(plan.expiryDay ?? '') ?? 365;
      user.consumerPlanExpiryDate = DateTime.now().add(Duration(days: days)).toIso8601String();
    }

    userModel.refresh();
    await Preferences.setString(Preferences.user, jsonEncode(userModel.value));

    if (Get.isRegistered<DashBoardController>()) {
      await Get.find<DashBoardController>().getUsrData();
    }
    if (Get.isRegistered<WalletController>()) {
      final walletController = Get.find<WalletController>();
      await walletController.getAmount();
      await walletController.getTransaction(showLoader: false);
    }
  }

  Future<dynamic> getSubscription() async {
    isLoading.value = true;
    loadError.value = '';

    try {
      showLog("API :: URL :: ${API.getSubscriptionPlans}");
      final response = await http.get(Uri.parse(API.getSubscriptionPlans), headers: API.header).timeout(const Duration(seconds: 15));
      showLog("API :: Response Status :: ${response.statusCode}");
      showLog("API :: Response Body :: ${response.body}");

      final responseBody = json.decode(response.body);
      if (response.statusCode == 200 && responseBody['success'] == "success" && responseBody['data'] is List) {
        final model = SubscriptionPlanModel.fromJson(responseBody);
        final plans = model.data ?? [];

        if (plans.isEmpty) {
          subscriptionPlanList.clear();
          loadError.value = 'No subscription plans available right now.';
        } else {
          plans.sort((a, b) {
            final aOrder = int.tryParse(a.place ?? '') ?? 0;
            final bOrder = int.tryParse(b.place ?? '') ?? 0;
            return aOrder.compareTo(bOrder);
          });

          subscriptionPlanList.assignAll(plans);
          _syncSelectedPlanWithUser();
        }
      } else {
        subscriptionPlanList.clear();
        loadError.value = responseBody['error']?.toString() ?? responseBody['message']?.toString() ?? 'Unable to load plans';
        showLog("API :: Error :: ${loadError.value}");
      }
    } on TimeoutException {
      subscriptionPlanList.clear();
      loadError.value = 'Connection timed out. Pull to refresh and try again.';
    } catch (e) {
      subscriptionPlanList.clear();
      loadError.value = 'Unable to load subscription plans';
      showLog("API :: Exception :: $e");
    } finally {
      isLoading.value = false;
    }
    return null;
  }

  void _syncSelectedPlanWithUser() {
    if (subscriptionPlanList.isEmpty) return;

    final activePlanId = userModel.value.data?.consumerPlanId?.toString();
    if (activePlanId != null && activePlanId.isNotEmpty) {
      final activePlan = subscriptionPlanList.firstWhereOrNull((plan) => plan.id?.toString() == activePlanId);
      if (activePlan != null) {
        selectedSubscriptionPlan.value = activePlan;
        totalAmount.value = double.tryParse(activePlan.price ?? '0') ?? 0;
        return;
      }
    }

    selectedSubscriptionPlan.value = subscriptionPlanList.first;
    totalAmount.value = double.tryParse(subscriptionPlanList.first.price ?? '0') ?? 0;
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
