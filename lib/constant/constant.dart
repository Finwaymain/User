// ignore_for_file: deprecated_member_use, non_constant_identifier_names, body_might_complete_normally_catch_error

import 'dart:async';
import 'dart:convert';
import 'dart:developer';
import 'dart:io';
import 'dart:typed_data';
import 'package:finway/constant/logdata.dart';
import 'package:finway/service/api.dart';
import 'package:flutter_google_places_hoc081098/google_maps_webservice_places.dart';
import 'package:finway/constant/show_toast_dialog.dart';
import 'package:finway/controller/dash_board_controller.dart';
import 'package:finway/model/payment_setting_model.dart';
import 'package:finway/model/tax_model.dart';
import 'package:finway/model/user_model.dart';
import 'package:finway/page/chats_screen/conversation_screen.dart';
import 'package:finway/themes/button_them.dart';
import 'package:finway/themes/constant_colors.dart';
import 'package:finway/utils/Preferences.dart';
import 'package:finway/utils/dark_theme_provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_google_places_hoc081098/flutter_google_places_hoc081098.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:get/get.dart';
import 'package:get_thumbnail_video/index.dart';
import 'package:get_thumbnail_video/video_thumbnail.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:map_launcher/map_launcher.dart' as launcher;
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
// ignore: depend_on_referenced_packages
import 'package:uuid/uuid.dart';
import 'package:video_compress/video_compress.dart';
// ignore: depend_on_referenced_packages
import 'package:http/http.dart' as http;
import 'package:google_api_headers/google_api_headers.dart';
import 'package:firebase_auth/firebase_auth.dart';

class Constant {
  static String? appName = "Fiinway";
  static String? kGoogleApiKey = "AIzaSyAxZaszdbtbO75kvNjSYm1LjW2Sk59D9C8";
  static String? distanceUnit = "KM";
  static String? appVersion = "0.0";
  static String? decimal = "2";
  static String? currency = "";
  static String? driverRadius = "0";
  static bool symbolAtRight = false;
  static List<TaxModel> allTaxList = [];
  static List<TaxModel> taxList = [];
  static String liveTrackingMapType = "google";
  static String selectedMapType = 'google'; // 'osm'

  static String driverLocationUpdate = "10";
  static String deliverChargeParcel = "0";
  static String? parcelActive = "yes";
  static String? parcelPerWeightCharge = "";
  static String? parcelPerHeightCharge = "";
  static String? jsonNotificationFileURL = "";
  static String? senderId = "";
  static String? homeScreenType = "UberHome"; //"OlaHome";

  static String placeholderUrl = 'https://cabme.siswebapp.com/assets/images/placeholder_image.jpg';

  // static String? taxValue = "0";
  // static String? taxType = 'Percentage';
  // static String? taxName = 'Tax';
  static String? contactUsEmail = "", contactUsAddress = "", contactUsPhone = "";
  static String? rideOtp = "yes";

  static String stripePublishablekey = "";

  static CollectionReference conversation = FirebaseFirestore.instance.collection('conversation');
  static CollectionReference driverLocationUpdateCollection = FirebaseFirestore.instance.collection('driver_location_update');

  static String getUuid() {
    var uuid = const Uuid();
    return uuid.v1();
  }

  static UserModel getUserData() {
    final String user = Preferences.getString(Preferences.user);
    if (user.isEmpty) return UserModel();
    Map<String, dynamic> userMap = jsonDecode(user);
    return UserModel.fromJson(userMap);
  }

  static PaymentSettingModel getPaymentSetting() {
    final String user = Preferences.getString(Preferences.paymentSetting);
    if (user.isNotEmpty) {
      Map<String, dynamic> userMap = jsonDecode(user);
      return PaymentSettingModel.fromJson(userMap);
    }
    return PaymentSettingModel();
  }

  String amountShow({required String? amount}) {
    String amountdata = (amount == 'null' || amount == '' || amount == null || amount == '0') ? '0' : amount;
    if (amountdata == '0') {
      if (Constant.symbolAtRight == true) {
        return "0${Constant.currency ?? ''}";
      } else {
        return "${Constant.currency ?? ''}0";
      }
    } else {
      if (Constant.symbolAtRight == true) {
        return "${double.parse(amountdata.toString()).toStringAsFixed(Constant.decimal == null ? 2 : int.parse(Constant.decimal!))}${Constant.currency ?? ''}";
      } else {
        return "${Constant.currency ?? ''}${double.parse(amountdata.toString()).toStringAsFixed(Constant.decimal == null ? 2 : int.parse(Constant.decimal!))}";
      }
    }
  }

  static Widget emptyView(BuildContext context, String msg, bool isButtonShow) {
    final themeChange = Provider.of<DarkThemeProvider>(context);
    final controllerDashBoard = Get.put(DashBoardController());
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 60),
          child: Image.asset('assets/images/empty_placeholde.png'),
        ),
        Padding(
          padding: const EdgeInsets.only(top: 10),
          child: Text(
            msg.tr,
            textAlign: TextAlign.center,
            style: TextStyle(color: themeChange.getThem() ? AppThemeData.grey300Dark : AppThemeData.grey400),
          ),
        ),
        Visibility(
          visible: isButtonShow,
          child: Padding(
            padding: const EdgeInsets.only(top: 20),
            child: ButtonThem.buildButton(
              context,
              title: 'Book now'.tr,
              btnWidthRatio: 0.8,
              onPress: () async {
                controllerDashBoard.onTexiSelectItem(0);
              },
            ),
          ),
        )
      ],
    );
  }

  static Widget loader(context, {Color? loadingcolor, Color? bgColor}) {
    final themeChange = Provider.of<DarkThemeProvider>(context);

    return Center(
      child: Container(
        width: 40,
        height: 40,
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: bgColor ?? (themeChange.getThem() ? AppThemeData.surface50Dark : AppThemeData.surface50),
          borderRadius: BorderRadius.circular(50),
        ),
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(loadingcolor ?? AppThemeData.primary200),
          strokeWidth: 3,
        ),
      ),
    );
  }

  static Future<void> makePhoneCall(String phoneNumber) async {
    final Uri launchUri = Uri(
      scheme: 'tel',
      path: phoneNumber,
    );
    await launchUrl(launchUri);
  }

  static Future<void> launchMapURl(String? latitude, String? longLatitude) async {
    String appleUrl = 'https://maps.apple.com/?saddr=&daddr=$latitude,$longLatitude&directionsmode=driving';
    String googleUrl = 'https://www.google.com/maps/search/?api=1&query=$latitude,$longLatitude';

    if (Platform.isIOS) {
      if (await canLaunch(appleUrl)) {
        await launch(appleUrl);
      } else {
        if (await canLaunch(googleUrl)) {
          await launch(googleUrl);
        } else {
          throw 'Could not open the map.';
        }
      }
    }
  }

  static Future<void> ensureFirebaseAuthenticated() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        log("No current user, signing in anonymously...");
        await FirebaseAuth.instance.signInAnonymously();
      } else {
        // Force refresh the token to verify if the session is still active/valid
        log("User exists, verifying/refreshing token...");
        await user.getIdToken(true);
      }
      log("Firebase Authentication active: ${FirebaseAuth.instance.currentUser?.uid}");
    } catch (e) {
      log("Firebase authentication check/refresh failed. Attempting clean anonymous sign-in: $e");
      try {
        // Sign out first to clear any corrupted/invalid state
        await FirebaseAuth.instance.signOut();
        await FirebaseAuth.instance.signInAnonymously();
        log("Clean anonymous sign-in successful: ${FirebaseAuth.instance.currentUser?.uid}");
      } catch (innerError) {
        log("Failed to sign in anonymously after reset: $innerError");
        throw Exception("Firebase Authentication failed: $innerError");
      }
    }
  }

  static const String imagekitUrlEndpoint = "https://ik.imagekit.io/77z5w3wmv";

  /// Upload a file to ImageKit via the server middleware.
  /// The server holds the private key — the app never touches it.
  static Future<String?> uploadFileViaServer(File file, {required String folder}) async {
    final uri = Uri.parse(API.uploadMarketplaceImage);
    final request = http.MultipartRequest('POST', uri);
    
    // Add auth headers (apikey + accesstoken)
    API.header.forEach((key, val) {
      request.headers[key] = val;
    });
    // Remove content-type so http package sets multipart boundary automatically
    request.headers.remove('content-type');
    
    request.fields['folder'] = folder;
    request.files.add(await http.MultipartFile.fromPath('image', file.path));
    
    final streamedResponse = await request.send();
    final response = await http.Response.fromStream(streamedResponse);
    
    if (response.statusCode == 200) {
      final Map<String, dynamic> responseData = jsonDecode(response.body);
      if (responseData['success'] == 'Success') {
        return responseData['url'];
      }
    }
    throw Exception("Upload error (${response.statusCode}): ${response.body}");
  }

  /// Upload raw bytes via server middleware (used for thumbnails etc.).
  /// Writes bytes to a temp file first, then uploads via server.
  static Future<String?> uploadBytesViaServer(Uint8List bytes, String fileName, {required String folder}) async {
    // Write bytes to a temporary file
    final tempDir = await getTemporaryDirectory();
    final tempFile = File('${tempDir.path}/$fileName');
    await tempFile.writeAsBytes(bytes);
    
    try {
      return await uploadFileViaServer(tempFile, folder: folder);
    } finally {
      // Clean up temp file
      if (await tempFile.exists()) {
        await tempFile.delete();
      }
    }
  }

  static Future<Url> uploadChatImageToFireStorage(File image) async {
    ShowToastDialog.showLoader('Uploading image...');
    try {
      final String? imageUrl = await uploadFileViaServer(image, folder: "/chats/images");
      ShowToastDialog.closeLoader();
      if (imageUrl == null) {
        throw Exception("Upload failed");
      }
      return Url(mime: 'image', url: imageUrl);
    } catch (e) {
      ShowToastDialog.closeLoader();
      log("Image upload error: $e");
      ShowToastDialog.showToast("Error: ${e.toString()}");
      rethrow;
    }
  }

  static Future<ChatVideoContainer?> uploadChatVideoToFireStorage(File video) async {
    try {
      ShowToastDialog.showLoader("Uploading video...");
      final String? videoUrl = await uploadFileViaServer(video, folder: "/chats/videos");
      if (videoUrl == null) {
        throw Exception("Failed to upload video");
      }

      ShowToastDialog.showLoader("Generating thumbnail...");
      final Uint8List thumbnailBytes = await VideoThumbnail.thumbnailData(
        video: video.path,
        imageFormat: ImageFormat.JPEG,
        maxHeight: 200,
        maxWidth: 200,
        quality: 75,
      );

      if (thumbnailBytes.isEmpty) {
        throw Exception("Failed to generate thumbnail.");
      }

      ShowToastDialog.showLoader("Uploading thumbnail...");
      final String? thumbnailUrl = await uploadBytesViaServer(thumbnailBytes, "thumbnail_${const Uuid().v4()}.jpg", folder: "/chats/thumbnails");
      ShowToastDialog.closeLoader();

      if (thumbnailUrl == null) {
        throw Exception("Failed to upload thumbnail");
      }

      return ChatVideoContainer(
        videoUrl: Url(url: videoUrl, mime: 'video', videoThumbnail: thumbnailUrl),
        thumbnailUrl: thumbnailUrl,
      );
    } catch (e) {
      ShowToastDialog.closeLoader();
      ShowToastDialog.showToast("Error: ${e.toString()}");
      return null;
    }
  }

  static Future<String> uploadVideoThumbnailToFireStorage(File file) async {
    final String? downloadUrl = await uploadFileViaServer(file, folder: "/chats/thumbnails");
    return downloadUrl ?? "";
  }

  static redirectMap({required String name, required double latitude, required double longLatitude}) async {
    if (Constant.liveTrackingMapType == "google") {
      bool? isAvailable = await launcher.MapLauncher.isMapAvailable(launcher.MapType.google);
      if (isAvailable == true) {
        await launcher.MapLauncher.showDirections(
          mapType: launcher.MapType.google,
          directionsMode: launcher.DirectionsMode.driving,
          destinationTitle: name,
          destination: launcher.Coords(latitude, longLatitude),
        );
      } else {
        ShowToastDialog.showToast("Google map is not installed");
      }
    } else if (Constant.liveTrackingMapType == "googleGo") {
      bool? isAvailable = await launcher.MapLauncher.isMapAvailable(launcher.MapType.googleGo);
      if (isAvailable == true) {
        await launcher.MapLauncher.showDirections(
          mapType: launcher.MapType.googleGo,
          directionsMode: launcher.DirectionsMode.driving,
          destinationTitle: name,
          destination: launcher.Coords(latitude, longLatitude),
        );
      } else {
        ShowToastDialog.showToast("Google Go map is not installed");
      }
    } else if (Constant.liveTrackingMapType == "waze") {
      bool? isAvailable = await launcher.MapLauncher.isMapAvailable(launcher.MapType.waze);
      if (isAvailable == true) {
        await launcher.MapLauncher.showDirections(
          mapType: launcher.MapType.waze,
          directionsMode: launcher.DirectionsMode.driving,
          destinationTitle: name,
          destination: launcher.Coords(latitude, longLatitude),
        );
      } else {
        ShowToastDialog.showToast("Waze is not installed");
      }
    } else if (Constant.liveTrackingMapType == "mapswithme") {
      bool? isAvailable = await launcher.MapLauncher.isMapAvailable(launcher.MapType.mapswithme);
      if (isAvailable == true) {
        await launcher.MapLauncher.showDirections(
          mapType: launcher.MapType.mapswithme,
          directionsMode: launcher.DirectionsMode.driving,
          destinationTitle: name,
          destination: launcher.Coords(latitude, longLatitude),
        );
      } else {
        ShowToastDialog.showToast("Mapswithme is not installed");
      }
    } else if (Constant.liveTrackingMapType == "yandexNavi") {
      bool? isAvailable = await launcher.MapLauncher.isMapAvailable(launcher.MapType.yandexNavi);
      if (isAvailable == true) {
        await launcher.MapLauncher.showDirections(
          mapType: launcher.MapType.yandexNavi,
          directionsMode: launcher.DirectionsMode.driving,
          destinationTitle: name,
          destination: launcher.Coords(latitude, longLatitude),
        );
      } else {
        ShowToastDialog.showToast("YandexNavi is not installed");
      }
    } else if (Constant.liveTrackingMapType == "yandexMaps") {
      bool? isAvailable = await launcher.MapLauncher.isMapAvailable(launcher.MapType.yandexMaps);
      if (isAvailable == true) {
        await launcher.MapLauncher.showDirections(
          mapType: launcher.MapType.yandexMaps,
          directionsMode: launcher.DirectionsMode.driving,
          destinationTitle: name,
          destination: launcher.Coords(latitude, longLatitude),
        );
      } else {
        ShowToastDialog.showToast("yandexMaps map is not installed");
      }
    }
  }

  Future<PlacesDetailsResponse?> placeSelectAPI(BuildContext context) async {
    // show input autocomplete with selected mode
    // then get the Prediction selected
    Prediction? p = await PlacesAutocomplete.show(
      hint: 'Search Adreess'.tr,
      context: context,
      apiKey: Constant.kGoogleApiKey,
      mode: Mode.fullscreen,
      onError: (response) {
        log("-->${response.status}");
      },
      language: 'fr',
      resultTextStyle: Theme.of(context).textTheme.titleMedium,
      types: [],
      strictbounds: false,
      components: [],
    );

    if (p == null) return null;
    return displayPrediction(p);
  }

  Future<PlacesDetailsResponse?> displayPrediction(Prediction? p) async {
    if (p != null) {
      GoogleMapsPlaces? places = GoogleMapsPlaces(
        apiKey: Constant.kGoogleApiKey,
        apiHeaders: await const GoogleApiHeaders().getHeaders(),
      );
      PlacesDetailsResponse? detail = await places.getDetailsByPlaceId(p.placeId.toString());

      return detail;
    }
    return null;
  }

  Future<Map<String, dynamic>> getOSMAddressFromLatLong(Position position) async {
    String url = 'https://nominatim.openstreetmap.org/reverse?format=json&lat=${position.latitude}&lon=${position.longitude}&zoom=18&addressdetails=1';

    var addressData = <String, dynamic>{};
    var package = Platform.isAndroid ? 'com.cabme.driver' : 'com.cabme.driver.ios';
    http.Response response = await http.get(
      Uri.parse(url),
      headers: {
        'User-Agent': package,
      },
    );
    showLog("API :: URL :: $url");
    showLog("API :: Request Body :: ${jsonEncode({
          'User-Agent': package,
        })} ");
    showLog("API :: Request Header :: ${API.header.toString()} ");
    showLog("API :: responseStatus :: ${response.statusCode} ");
    showLog("API :: responseBody :: ${response.body} ");

    if (response.statusCode == 200) {
      Map<String, dynamic> data = json.decode(response.body);
      addressData = data;
    }
    log("Adress :: ${addressData.toString()}");
    return addressData;
  }

  Future<Map<String, dynamic>> getOSMAddressFromLatLongLatlng({required double lat, required double lng}) async {
    String url = 'https://nominatim.openstreetmap.org/reverse?format=json&lat=$lat&lon=$lng&zoom=18&addressdetails=1';

    var addressData = <String, dynamic>{};
    var package = Platform.isAndroid ? 'com.cabme.driver' : 'com.cabme.driver.ios';
    http.Response response = await http.get(
      Uri.parse(url),
      headers: {
        'User-Agent': package,
      },
    );
    showLog("API :: URL :: $url");
    showLog("API :: Request Body :: ${jsonEncode({
          'User-Agent': package,
        })} ");
    showLog("API :: Request Header :: ${API.header.toString()} ");
    showLog("API :: responseStatus :: ${response.statusCode} ");
    showLog("API :: responseBody :: ${response.body} ");

    if (response.statusCode == 200) {
      Map<String, dynamic> data = json.decode(response.body);
      addressData = data;
    }
    log("Adress :: ${addressData.toString()}");
    return addressData;
  }

  Future<String> getAddressFromLatLong(Position position) async {
    try {
      List<Placemark> placemarks = await placemarkFromCoordinates(position.latitude, position.longitude);
      if (placemarks.isNotEmpty) {
        Placemark place = placemarks[0];
        String subLocality = place.subLocality ?? '';
        String locality = place.locality ?? '';
        if (subLocality.isNotEmpty && locality.isNotEmpty) {
          return '$subLocality, $locality';
        } else if (locality.isNotEmpty) {
          return locality;
        } else if (subLocality.isNotEmpty) {
          return subLocality;
        }
      }
    } catch (e) {
      log("Error getting address: $e");
    }
    return '';
  }

  Future<dynamic> getDurationDistance({required LatLng departureLatLong, required LatLng destinationLatLong}) async {
    ShowToastDialog.showLoader("Please wait");
    double originLat, originLong, destLat, destLong;
    originLat = departureLatLong.latitude;
    originLong = departureLatLong.longitude;
    destLat = destinationLatLong.latitude;
    destLong = destinationLatLong.longitude;
    var distance = 0.0;
    var duration = '';

    String url = 'https://maps.googleapis.com/maps/api/distancematrix/json';
    http.Response restaurantToCustomerTime = await http.get(Uri.parse('$url?units=metric&origins=$originLat,'
        '$originLong&destinations=$destLat,$destLong&key=${Constant.kGoogleApiKey}'));

    var decodedResponse = jsonDecode(restaurantToCustomerTime.body);

    if (decodedResponse['status'] == 'OK' && decodedResponse['rows'].first['elements'].first['status'] == 'OK') {
      ShowToastDialog.closeLoader();
      if (decodedResponse != null) {
        if (Constant.distanceUnit == "KM") {
          distance = (double.parse(decodedResponse['rows'].first['elements'].first['distance']['value'].toString()) / 1000.00);
        } else {
          distance = double.parse(decodedResponse['rows'].first['elements'].first['distance']['value'].toString()) / 1609.34;
        }
        duration = decodedResponse['rows'].first['elements'].first['duration']['text'].toString();
      }
      var data = {'distance': distance.toString(), 'duration': duration.toString()};
      return data;
    }
    ShowToastDialog.closeLoader();
    return null;
  }

  Future<Map<String, dynamic>> getDurationOsmDistance(LatLng departureLatLong, LatLng destinationLatLong) async {
    var distance = 0.0;
    var duration = '';
    // var amount = 0.0;
    String url = 'http://router.project-osrm.org/route/v1/driving';
    String coordinates = '${departureLatLong.longitude},${departureLatLong.latitude};${destinationLatLong.longitude},${destinationLatLong.latitude}';

    http.Response response = await http.get(Uri.parse('$url/$coordinates?overview=false&steps=false'));
    showLog("API :: URL :: $url/$coordinates?overview=false&steps=false");
    showLog("API :: responseStatus :: ${response.statusCode} ");
    showLog("API :: responseBody :: ${response.body} ");
    Map<String, dynamic> value = jsonDecode(response.body);

    if (value != {} && value.isNotEmpty) {
      int hours = value['routes'].first['duration'] ~/ 3600;
      int minutes = ((value['routes'].first['duration'] % 3600) / 60).round();
      duration = '$hours hours $minutes minutes';
      if (Constant.distanceUnit == "Km") {
        distance = (value['routes'].first['distance'] / 1000);
        // amount = amountCalculate(selectedType.value.kmCharge.toString(), distance.toStringAsFixed(Constant.currencyModel!.decimalDigits!));
      } else {
        distance = (value['routes'].first['distance'] / 1609.34);
        // amount = amountCalculate(selectedType.value.kmCharge.toString(), distance.toStringAsFixed(Constant.currencyModel!.decimalDigits!)_;
      }
    }
    var data = {'distance': distance.toString(), 'duration': duration.toString()};
    return data;
  }

  String getDurationByDistance(double duration) {
    int hours = duration ~/ 3600;
    int minutes = ((duration % 3600) / 60).round();
    return '$hours hours $minutes minutes';
  }

  double amountCalculate(String amount, String distance) {
    double finalAmount = 0.0;
    log("------->");
    log(amount);
    log(distance);
    finalAmount = double.parse(amount) * double.parse(distance);
    return finalAmount;
  }

  Future<String?> getAmount() async {
    try {
      ShowToastDialog.showLoader("Please wait");
      final response = await http.get(Uri.parse("${API.wallet}?id_user=${Preferences.getInt(Preferences.userId)}&user_cat=user_app"), headers: API.header);
      Map<String, dynamic> responseBody = json.decode(response.body);

      if (response.statusCode == 200 && responseBody['success'] == "success") {
        ShowToastDialog.closeLoader();
        return responseBody['data']['amount'].toString();
      } else if (response.statusCode == 200 && responseBody['success'] == "Failed") {
        ShowToastDialog.closeLoader();
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
      ShowToastDialog.showToast(e.toString());
    } catch (e) {
      ShowToastDialog.closeLoader();
      ShowToastDialog.showToast(e.toString());
    }
    return null;
  }
}

class Url {
  String mime;

  String url;

  String? videoThumbnail;

  Url({this.mime = '', this.url = '', this.videoThumbnail});

  factory Url.fromJson(Map<dynamic, dynamic> parsedJson) {
    return Url(mime: parsedJson['mime'] ?? '', url: parsedJson['url'] ?? '', videoThumbnail: parsedJson['videoThumbnail'] ?? '');
  }

  Map<String, dynamic> toJson() {
    return {'mime': mime, 'url': url, 'videoThumbnail': videoThumbnail};
  }
}
