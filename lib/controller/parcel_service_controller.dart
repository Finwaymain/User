import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:finway/constant/constant.dart';
import 'package:finway/constant/logdata.dart';
import 'package:finway/constant/show_toast_dialog.dart';
import 'package:finway/model/parcel_category_model.dart';
import 'package:finway/model/parcel_model.dart';
import 'package:finway/model/payment_setting_model.dart';
import 'package:finway/page/parcel_service_screen/parcel_sucess_screen.dart';
import 'package:finway/service/api.dart';
import 'package:finway/themes/constant_colors.dart';
import 'package:finway/utils/Preferences.dart';
import 'package:finway/utils/dark_theme_provider.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:get/get.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

class ParcelServiceController extends GetxController {
  String title = '';

  RxList<ParcelCategoryData> parcelCategoryList = <ParcelCategoryData>[].obs;
  var isLoading = true.obs;

  Rx<ParcelCategoryData> selectedParcelCategory = ParcelCategoryData().obs;

  TextEditingController sNameController = TextEditingController();

  var sPhoneController = TextEditingController().obs;
  TextEditingController parcelWeightController = TextEditingController();
  TextEditingController parcelDimentionController = TextEditingController();
  TextEditingController noteController = TextEditingController();

  TextEditingController rNameController = TextEditingController();
  var rPhoneController = TextEditingController().obs;

  RxString senderAddress = "".obs;
  RxString receiverAddress = "".obs;
  RxString senderAddressCity = "".obs;
  RxString receiverAddressCity = "".obs;

  LatLng? senderLocation;
  LatLng? receiverLocation;

  var paymentSettingModel = PaymentSettingModel().obs;

  DateTime selectedDatePickUp = DateTime.now();
  RxString senderDate = "".obs; //DateFormat('yyyy-MM-dd').format(DateTime.now());

  DateTime selectedDateDeliver = DateTime.now();
  RxString receiverDate = "".obs;

  TimeOfDay selectedTimePickUp = TimeOfDay.now();
  RxString senderTime = "".obs;

  TimeOfDay selectedTimeDeliver = TimeOfDay.now();
  RxString receiverTime = "".obs;

  RxDouble distance = 0.0.obs;
  RxDouble subTotal = 0.0.obs;
  RxString duration = "".obs;

  RxBool cash = false.obs;
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
  RxBool upi = false.obs;
  RxString paymentMethodType = "Select Method".obs;
  RxString paymentMethodId = "".obs;
  List<XFile> parcelImages = [];
  RxString walletAmount = (Constant.getUserData().data?.amount?.toString() ?? '0').obs;
  @override
  void onInit() {
    senderDate.value = DateFormat('yyyy-MM-dd').format(DateTime.now());
    senderTime.value = DateFormat('HH:mm:ss').format(DateTime.now());
    receiverDate.value = DateFormat('yyyy-MM-dd').format(DateTime.now());
    receiverTime.value = DateFormat('HH:mm:ss').format(DateTime.now().add(const Duration(hours: 2)));

    getParcelCategory();
    paymentSettingModel.value = Constant.getPaymentSetting();
    walletAmount.value = Constant.getUserData().data?.amount?.toString() ?? '0';
    Constant().getAmount().then((value) {
      if (value != null) {
        walletAmount.value = value;
      }
    });
    // getArgument();
    getCurrentLocation();
    super.onInit();
  }

  getCurrentLocation() async {
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    if (permission == LocationPermission.denied || permission == LocationPermission.deniedForever) {
      print("Geolocator location permission denied for parcel service");
      return;
    }
    Position position = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);

    if (Constant.selectedMapType == 'osm') {
      senderLocation = LatLng(position.latitude, position.longitude);
      receiverLocation = LatLng(position.latitude, position.longitude);
      var senderaddress = await Constant().getOSMAddressFromLatLong(position);
      senderAddress.value = senderaddress['display_name'] ?? '';
      receiverAddress.value = senderAddress.value;
      senderAddressCity.value =
          senderaddress['address']['city'] ?? senderaddress['address']['village'] ?? senderaddress['address']['state_district'] ?? senderaddress['address']['suburb'] ?? '';
      receiverAddressCity.value = senderAddressCity.value;
    } else {
      senderLocation = LatLng(position.latitude, position.longitude);
      receiverLocation = LatLng(position.latitude, position.longitude);
      senderAddress.value = await Constant().getAddressFromLatLong(position);
      receiverAddress.value = senderAddress.value;
      senderAddressCity.value = senderAddress.value.split(",").last.trim();
      receiverAddressCity.value = senderAddress.value.split(",").last.trim();
    }
  }

  // getArgument() async {
  //   dynamic argumentData = Get.arguments;
  //   print("========$argumentData");
  //   if (argumentData != null) {
  //     selectedCategory.value = argumentData["title"];
  //   }
  //   update();
  // }

  Future<GetParcelCategoryModel?> getParcelCategory() async {
    try {
      ShowToastDialog.showLoader("Please wait");
      final response = await http.get(Uri.parse(API.getParcelCategory), headers: API.header);
      showLog("API :: URL :: ${API.getParcelCategory}");
      showLog("API :: Request Header :: ${API.header.toString()} ");
      showLog("API :: responseStatus :: ${response.statusCode} ");
      showLog("API :: responseBody :: ${response.body} ");
      Map<String, dynamic> responseBody = json.decode(response.body);

      if (response.statusCode == 200 && responseBody['success'] == "success") {
        update();
        isLoading.value = false;
        GetParcelCategoryModel data = GetParcelCategoryModel.fromJson(responseBody);
        parcelCategoryList.value = data.data!;
        selectedParcelCategory.value = parcelCategoryList[0];
        ShowToastDialog.closeLoader();
        return GetParcelCategoryModel.fromJson(responseBody);
      } else {
        isLoading.value = false;
        ShowToastDialog.closeLoader();
        ShowToastDialog.showToast('Something want wrong. Please try again later');
        throw Exception('Failed to load album');
      }
    } on TimeoutException catch (e) {
      isLoading.value = false;
      ShowToastDialog.closeLoader();
      ShowToastDialog.showToast(e.message.toString());
    } on SocketException catch (e) {
      isLoading.value = false;
      ShowToastDialog.closeLoader();
      ShowToastDialog.showToast(e.message.toString());
    } on Error catch (e) {
      isLoading.value = false;
      ShowToastDialog.closeLoader();
      ShowToastDialog.showToast(e.toString());
    } catch (e) {
      isLoading.value = false;
      ShowToastDialog.closeLoader();
      ShowToastDialog.showToast(e.toString());
    }
    return null;
  }

  void calculateSubTotal() {
    double weight = double.tryParse(parcelWeightController.text.toString()) ?? 0.0;
    double height = double.tryParse(parcelDimentionController.text.toString()) ?? 0.0;
    double deliveryCharge = double.tryParse(Constant.deliverChargeParcel.toString()) ?? 0.0;
    double weightCharge = double.tryParse(Constant.parcelPerWeightCharge.toString()) ?? 0.0;
    double heightCharge = double.tryParse(Constant.parcelPerHeightCharge.toString()) ?? 0.0;

    // Default rate fallbacks if not yet configured in admin settings
    if (deliveryCharge <= 0) deliveryCharge = 15.0;
    if (weightCharge <= 0) weightCharge = 5.0;
    if (heightCharge <= 0) heightCharge = 5.0;

    subTotal.value = (distance.value * deliveryCharge) + (weight * weightCharge) + (height * heightCharge);
  }

  void _fallbackGeolocatorDistance(LatLng departureLatLong, LatLng destinationLatLong) {
    try {
      double directMeters = Geolocator.distanceBetween(
        departureLatLong.latitude,
        departureLatLong.longitude,
        destinationLatLong.latitude,
        destinationLatLong.longitude,
      );
      // Apply 1.25x road driving curvature factor
      double roadMeters = directMeters * 1.25;
      if (Constant.distanceUnit == "KM") {
        distance.value = roadMeters / 1000.0;
      } else {
        distance.value = roadMeters / 1609.34;
      }
      int minutes = ((distance.value / 30.0) * 60).round();
      if (minutes < 3) minutes = 3;
      duration.value = minutes >= 60 ? '${minutes ~/ 60} hours ${minutes % 60} mins' : '$minutes mins';
      calculateSubTotal();
    } catch (e) {
      showLog("Geolocator fallback error: $e");
    }
  }

  Future<dynamic> getDurationDistance(LatLng departureLatLong, LatLng destinationLatLong) async {
    ShowToastDialog.showLoader("Please wait");
    try {
      double originLat = departureLatLong.latitude;
      double originLong = departureLatLong.longitude;
      double destLat = destinationLatLong.latitude;
      double destLong = destinationLatLong.longitude;

      String url = 'https://maps.googleapis.com/maps/api/distancematrix/json';
      http.Response restaurantToCustomerTime = await http.get(Uri.parse('$url?units=metric&origins=$originLat,'
          '$originLong&destinations=$destLat,$destLong&key=${Constant.kGoogleApiKey}'));

      showLog("API :: URL :: $url?units=metric&origins=$originLat,$originLong&destinations=$destLat,$destLong&key=${Constant.kGoogleApiKey}");
      showLog("API :: responseStatus :: ${restaurantToCustomerTime.statusCode} ");
      showLog("API :: responseBody :: ${restaurantToCustomerTime.body} ");

      var decodedResponse = jsonDecode(restaurantToCustomerTime.body);

      if (decodedResponse['status'] == 'OK' && decodedResponse['rows'].first['elements'].first['status'] == 'OK') {
        if (Constant.distanceUnit == "KM") {
          distance.value = decodedResponse['rows'].first['elements'].first['distance']['value'] / 1000.00;
        } else {
          distance.value = decodedResponse['rows'].first['elements'].first['distance']['value'] / 1609.34;
        }
        duration.value = decodedResponse['rows'].first['elements'].first['duration']['text'].toString();
        calculateSubTotal();
        ShowToastDialog.closeLoader();
        return decodedResponse;
      } else {
        showLog("Google Distance Matrix not OK (${decodedResponse['status']}), falling back to OSRM / Geolocator");
      }
    } catch (e) {
      showLog("Google Distance Matrix error: $e, falling back to OSRM / Geolocator");
    }

    // Fallback 1: OSRM
    try {
      var value = await Constant().getDurationOsmDistance(departureLatLong, destinationLatLong);
      double osmDist = double.tryParse(value['distance'].toString()) ?? 0.0;
      if (osmDist > 0) {
        distance.value = osmDist;
        duration.value = value['duration']?.toString() ?? '';
        calculateSubTotal();
        ShowToastDialog.closeLoader();
        return value;
      }
    } catch (e) {
      showLog("OSRM fallback error: $e");
    }

    // Fallback 2: Geolocator (device mathematical direct calculation)
    _fallbackGeolocatorDistance(departureLatLong, destinationLatLong);
    ShowToastDialog.closeLoader();
    return null;
  }

  Future<void> getDurationOSMDistance(LatLng departureLatLong, LatLng destinationLatLong) async {
    ShowToastDialog.showLoader("Please wait");
    try {
      var value = await Constant().getDurationOsmDistance(departureLatLong, destinationLatLong);
      double osmDist = double.tryParse(value['distance'].toString()) ?? 0.0;
      if (osmDist > 0) {
        distance.value = osmDist;
        duration.value = value['duration']?.toString() ?? '';
        calculateSubTotal();
      } else {
        _fallbackGeolocatorDistance(departureLatLong, destinationLatLong);
      }
    } catch (e) {
      showLog("Error calculating OSM distance: $e, falling back to Geolocator");
      _fallbackGeolocatorDistance(departureLatLong, destinationLatLong);
    } finally {
      ShowToastDialog.closeLoader();
    }
  }

  bookParcelRide() async {
    try {
      ShowToastDialog.showLoader("Please wait");

      var request = http.MultipartRequest(
        'POST',
        Uri.parse(API.bookParcel),
      );
      request.headers.addAll(API.header);
      for (var i = 0; i < parcelImages.length; i++) {
        request.files.add(http.MultipartFile.fromBytes('parcel_image[]', File(parcelImages[i].path).readAsBytesSync(), filename: parcelImages[i].path.split('/').last));
      }

      request.fields['user_id'] = Preferences.getInt(Preferences.userId).toString();

      request.fields['lat1'] = senderLocation!.latitude.toString();

      request.fields['lng1'] = senderLocation!.longitude.toString();
      request.fields['lat2'] = receiverLocation!.latitude.toString();
      request.fields['lng2'] = receiverLocation!.longitude.toString();

      request.fields['source_city'] = senderAddressCity.value.toString().trim();
      request.fields['destination_city'] = receiverAddressCity.value.trim();

      request.fields['distance'] = distance.value.toStringAsFixed(2);
      request.fields['distance_unit'] = Constant.distanceUnit.toString();

      request.fields['id_payment'] = paymentMethodId.value.isNotEmpty ? paymentMethodId.value.toString() : '1';
      request.fields['source_adrs'] = senderAddress.toString().trim();

      request.fields['destination_adrs'] = receiverAddress.toString().trim();
      request.fields['sender_name'] = sNameController.text.toString().trim();
      request.fields['receiver_name'] = rNameController.text.toString().trim();
      request.fields['sender_phone'] = sPhoneController.value.text.trim().trim();
      request.fields['receiver_phone'] = rPhoneController.value.text.trim();
      request.fields['note'] = noteController.text.toString().trim();
      request.fields['parcel_weight'] = parcelWeightController.text.trim().toString();
      request.fields['parcel_dimension'] = parcelDimentionController.text.trim().toString();

      request.fields['parcel_type'] = selectedParcelCategory.value.id ?? '';
      request.fields['parcel_date'] = senderDate.value.isEmpty ? DateFormat('yyyy-MM-dd').format(DateTime.now()) : senderDate.value.toString();
      request.fields['parcel_time'] = senderTime.value.isEmpty ? DateFormat('HH:mm:ss').format(DateTime.now()) : senderTime.value.toString();
      request.fields['receive_date'] = receiverDate.value.isEmpty ? DateFormat('yyyy-MM-dd').format(DateTime.now()) : receiverDate.value.toString();
      request.fields['receive_time'] = receiverTime.value.isEmpty ? DateFormat('HH:mm:ss').format(DateTime.now().add(const Duration(hours: 2))) : receiverTime.value.toString();
      request.fields['amount'] = subTotal.value.toStringAsFixed(2);
      request.fields['duration'] = duration.value.toString();

      var res = await request.send();
      var responseData = await res.stream.toBytes();
      final responseBodyStr = String.fromCharCodes(responseData);
      showLog("API :: URL :: ${API.bookParcel}");
      showLog("API :: Request Body :: ${jsonEncode(request.fields)} ");
      showLog("API :: Response Status :: ${res.statusCode} ");
      showLog("API :: Response Body :: $responseBodyStr ");

      Map<String, dynamic>? response;
      try {
        response = jsonDecode(responseBodyStr);
      } catch (e) {
        showLog("JSON decode error: $e");
      }

      if (res.statusCode == 200 && response != null && response['success']?.toString().toLowerCase() == 'success') {
        ShowToastDialog.closeLoader();
        Get.delete<ParcelServiceController>();
        ParcelData? parcelOrderData;
        if (response['data'] != null && (response['data'] as List).isNotEmpty) {
          try {
            parcelOrderData = ParcelData.fromJson(response['data'][0]);
          } catch (e) {
            showLog("Error parsing booked parcel data: $e");
          }
        }
        Get.offAll(ParcelSuccessScreen(parcelData: parcelOrderData));
        return response;
      } else {
        ShowToastDialog.closeLoader();
        final errMsg = response?['error'] ?? response?['message'] ?? 'Booking failed (${res.statusCode}). Please try again.';
        ShowToastDialog.showToast(errMsg.toString());
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


  onCameraClick(context) {
    final action = CupertinoActionSheet(
      message: Text(
        'Add your parcel image.'.tr,
        style: const TextStyle(fontSize: 15.0),
      ),
      actions: <Widget>[
        CupertinoActionSheetAction(
          isDefaultAction: false,
          onPressed: () async {
            Navigator.pop(context);
            await ImagePicker().pickMultiImage(imageQuality: 70, maxWidth: 1024, maxHeight: 1024).then((value) {
              for (var element in value) {
                parcelImages.add(element);
              }
            });
          },
          child: Text('Choose image from gallery'.tr),
        ),
        CupertinoActionSheetAction(
          isDestructiveAction: false,
          onPressed: () async {
            Get.back();
            final XFile? photo = await ImagePicker().pickImage(source: ImageSource.camera, imageQuality: 70, maxWidth: 1024, maxHeight: 1024);
            if (photo != null) {
              parcelImages.add(photo);
            }
          },
          child: Text('Take a picture'.tr),
        ),
      ],
      cancelButton: CupertinoActionSheetAction(
        child: Text(
          'Cancel'.tr,
        ),
        onPressed: () {
          Get.back();
        },
      ),
    );
    showCupertinoModalPopup(context: context, builder: (context) => action);
  }

  selectDate(BuildContext context, {bool isPickUp = true}) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: selectedDatePickUp,
      initialDatePickerMode: DatePickerMode.day,
      firstDate: selectedDatePickUp,
      lastDate: DateTime(2101),
      builder: (BuildContext context, Widget? child) {
        final themeChange = Provider.of<DarkThemeProvider>(context);
        return Theme(
          data: ThemeData(
            colorScheme: themeChange.getThem()
                ? ColorScheme.dark(
                    primary: AppThemeData.primary200,
                    secondary: AppThemeData.grey300,
                    onPrimary: AppThemeData.surface50Dark,
                    onSurface: AppThemeData.primary200,
                  )
                : ColorScheme.light(
                    primary: AppThemeData.primary200,
                    secondary: AppThemeData.grey300,
                    onPrimary: AppThemeData.surface50,
                    onSurface: AppThemeData.primary200,
                  ), dialogTheme: DialogThemeData(backgroundColor: themeChange.getThem() ? AppThemeData.surface50Dark : AppThemeData.surface50),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      if (isPickUp) {
        selectedDatePickUp = picked;

        senderDate.value = DateFormat('dd-MMM-yyyy').format(selectedDatePickUp);
      } else {
        selectedDateDeliver = picked;

        receiverDate.value = DateFormat('dd-MMM-yyyy').format(selectedDateDeliver);
      }
    }
  }

  selectTime(BuildContext context, {bool isPickUp = true}) async {
    final localizations = MaterialLocalizations.of(context);

    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: selectedTimePickUp,
      builder: (BuildContext context, Widget? child) {
        final themeChange = Provider.of<DarkThemeProvider>(context);
        return Theme(
          data: ThemeData(
            colorScheme: themeChange.getThem()
                ? ColorScheme.dark(
                    primary: AppThemeData.primary200,
                    secondary: AppThemeData.grey300,
                    onPrimary: AppThemeData.surface50,
                    onSurface: AppThemeData.primary200,
                  )
                : ColorScheme.light(
                    primary: AppThemeData.primary200,
                    secondary: AppThemeData.grey300,
                    onPrimary: AppThemeData.surface50,
                    onSurface: AppThemeData.primary200,
                  ), dialogTheme: DialogThemeData(backgroundColor: themeChange.getThem() ? AppThemeData.surface50Dark : AppThemeData.surface50),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      if (isPickUp) {
        selectedTimePickUp = picked;
        senderTime.value = localizations.formatTimeOfDay(selectedTimePickUp);
      } else {
        selectedTimeDeliver = picked;
        receiverTime.value = localizations.formatTimeOfDay(selectedTimeDeliver);
      }
    }
  }
}
