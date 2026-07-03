// ignore_for_file: depend_on_referenced_packages

import 'dart:async';
import 'package:firebase_database/firebase_database.dart';
import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'package:finway/constant/constant.dart';
import 'package:finway/constant/logdata.dart';
import 'package:finway/constant/show_toast_dialog.dart';
import 'package:finway/model/banner_model.dart';
import 'package:finway/model/driver_location_update.dart';
import 'package:finway/model/driver_model.dart';
import 'package:finway/model/payment_method_model.dart';
import 'package:finway/model/vehicle_category_model.dart';
import 'package:finway/service/api.dart';
import 'package:finway/utils/Preferences.dart';
import 'package:flutter/material.dart';
import 'package:flutter_google_places_hoc081098/flutter_google_places_hoc081098.dart';
import 'package:flutter_google_places_hoc081098/google_maps_webservice_places.dart';
import 'package:flutter_osm_plugin/flutter_osm_plugin.dart';
import 'package:geolocator/geolocator.dart';
import 'package:get/get.dart';
import 'package:google_api_headers/google_api_headers.dart';

import 'package:http/http.dart' as http;
import 'package:geolocator/geolocator.dart' as locationData;
import '../model/payment_setting_model.dart';

class HomeOsmController extends GetxController with GetSingleTickerProviderStateMixin {
  RxBool isHomePageLoading = false.obs;
  late MapController mapController;
  TabController? tabController;
  Map<String, GeoPoint> markers = <String, GeoPoint>{};

  Rx<RoadInfo> roadInfo = RoadInfo().obs;

  TextEditingController currentLocationController = TextEditingController();
  TextEditingController departureController = TextEditingController();
  TextEditingController destinationController = TextEditingController();
  TextEditingController addStop = TextEditingController(text: 'Add Stop'.tr);

  RxString selectPaymentMode = "Payment Method".obs;
  List<AddChildModelData> addChildList = [AddChildModelData(editingController: TextEditingController())];
  List<AddStopModelData> multiStopList = [];
  List<AddStopModelData> multiStopListNew = [];

  Rx<VehicleData> vehicleData = VehicleData().obs;
  late PaymentMethodData? paymentMethodData;

  RxBool confirmWidgetVisible = false.obs;

  RxString tripOptionCategory = "General".obs;
  RxString paymentMethodType = "Select Method".obs;
  RxString paymentMethodId = "".obs;
  RxDouble distance = 0.0.obs;
  RxString duration = "".obs;

  var paymentSettingModel = PaymentSettingModel().obs;

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
  RxString walletAmount = '0'.obs;

  @override
  void onInit() {
    setInitData();
    super.onInit();
  }

  setInitData() async {
    isHomePageLoading.value = true;
    await setTabr();
    await getBannerData();
    if (Constant.homeScreenType == 'UberHome') {
      await initOSMData();
      ShowToastDialog.showLoader("Please wait");
    } else {
      await getCurrentAddress();
    }
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await getTaxiData();
    });
    paymentSettingModel.value = Constant.getPaymentSetting();
    isHomePageLoading.value = false;
  }

  initOSMData() async {
    await setMapController();
    await setIcons();
  }

  getCurrentAddress({bool setMarker = false}) async {
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.whileInUse || permission == LocationPermission.always) {
      Position position = await Geolocator.getCurrentPosition(desiredAccuracy: locationData.LocationAccuracy.high);
      if (Constant.selectedMapType == 'osm') {
        String url = 'https://nominatim.openstreetmap.org/reverse?format=json&lat=${position.latitude}&lon=${position.longitude}&zoom=18&addressdetails=1';
        var addressData = <String, dynamic>{};
        var package = Platform.isAndroid ? 'com.cabme' : 'com.cabme.ios';
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
        currentLocationController.text = addressData['display_name'] ?? '';
        departureController.text = addressData['display_name'] ?? '';
        departureLatLong.value = GeoPoint(latitude: position.latitude, longitude: position.longitude);
        if (setMarker) {
          for (var i = 0; i < Constant.allTaxList.length; i++) {
            if (addressData["address"]["county"].toString().toUpperCase() == Constant.allTaxList[i].country?.toUpperCase()) {
              Constant.taxList.add(Constant.allTaxList[i]);
            }
          }
          setDepartureMarker(GeoPoint(latitude: position.latitude, longitude: position.longitude));
        }
      }
    }
  }
}

  Rx<BannerModel> bannerModel = BannerModel().obs;
  setMapController() {
    multiStopList.clear();
    multiStopListNew.clear();
    if (departureLatLong.value.latitude != 0.0 && departureLatLong.value.longitude != 0.0) {
      mapController = MapController(initPosition: departureLatLong.value);
    } else {
      mapController = MapController(initPosition: GeoPoint(latitude: 41.4219057, longitude: -102.0840772));
    }
  }

  Future<dynamic> getBannerData() async {
    try {
      http.Response response = await http.get(Uri.parse(API.bannerHome), headers: API.header);
      var decodedResponse = jsonDecode(response.body);
      showLog("API :: URL :: ${API.bannerHome}");
      showLog("API :: Request Header :: ${API.header.toString()} ");
      showLog("API :: responseStatus :: ${response.statusCode} ");
      showLog("API :: responseBody :: ${response.body} ");
      if (decodedResponse['success'] == 'success') {
        bannerModel.value = BannerModel.fromJson(decodedResponse as Map<String, dynamic>);
        return decodedResponse;
      } else {
        ShowToastDialog.closeLoader();
        return null;
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
    ShowToastDialog.closeLoader();
    return null;
  }

  Rx<GeoPoint> departureLatLong = GeoPoint(latitude: 0.0, longitude: 0.0).obs;
  Rx<GeoPoint> destinationLatLong = GeoPoint(latitude: 0.0, longitude: 0.0).obs;

  @override
  void onClose() {
    destinationLatLong.value = GeoPoint(latitude: 0.0, longitude: 0.0);
    destinationLatLong.value = GeoPoint(latitude: 0.0, longitude: 0.0);
    destinationController = TextEditingController();
    departureController = TextEditingController();
    confirmWidgetVisible.value = false;
    isHomePageLoading.value = false;
    super.onClose();
  }

  setTabr() {
    if (Constant.parcelActive.toString() == "yes") {
      tabController = TabController(length: 2, vsync: this);
    } else {
      tabController = TabController(length: 1, vsync: this);
    }
  }

  Widget? departureIcon;
  Widget? destinationIcon;
  Widget? taxiIcon;
  Widget? stopIcon;

  setIcons() async {
    departureIcon = Image.asset("assets/icons/pickup.png", width: 30, height: 30);

    destinationIcon = Image.asset("assets/icons/dropoff.png", width: 30, height: 30);

    taxiIcon = Image.asset("assets/icons/ic_taxi.png", width: 30, height: 30);

    stopIcon = Image.asset("assets/icons/location.png", width: 30, height: 30);
  }

  addStops() async {
    ShowToastDialog.showLoader("Please wait");
    multiStopList.add(AddStopModelData(editingController: TextEditingController(), latitude: "", longitude: ""));
    multiStopListNew = List<AddStopModelData>.generate(
      multiStopList.length,
      (int index) =>
          AddStopModelData(editingController: multiStopList[index].editingController, latitude: multiStopList[index].latitude, longitude: multiStopList[index].longitude),
    );
    ShowToastDialog.closeLoader();

    update();
  }

  removeStops(int index) {
    ShowToastDialog.showLoader("Please wait");
    multiStopList.removeAt(index);
    multiStopListNew = List<AddStopModelData>.generate(
      multiStopList.length,
      (int index) =>
          AddStopModelData(editingController: multiStopList[index].editingController, latitude: multiStopList[index].latitude, longitude: multiStopList[index].longitude),
    );
    ShowToastDialog.closeLoader();
    update();
  }

  clearData() {
    selectPaymentMode.value = "Payment Method";
    tripOptionCategory = "General".obs;
    paymentMethodType = "Select Method".obs;
    paymentMethodId = "".obs;
    distance = 0.0.obs;
    duration = "".obs;
    multiStopList.clear();
    multiStopListNew.clear();
  }

  RxList<DriverLocationUpdate> driverLocationList = <DriverLocationUpdate>[].obs;
  Future getTaxiData() async {
    FirebaseDatabase.instance.ref("drivers").onValue.listen((event) async {
      if (event.snapshot.value == null) return;
      try {
        final driversData = event.snapshot.value as Map<dynamic, dynamic>;
        driverLocationList.clear();
        driversData.forEach((key, value) {
          if (value is Map) {
            final active = value['active'] ?? false;
            if (active == true) {
              final driverId = key.toString();
              final lat = value['driver_latitude']?.toString() ?? '0.0';
              final lng = value['driver_longitude']?.toString() ?? '0.0';
              final rot = value['rotation']?.toString() ?? '0.0';
              
              final driverLoc = DriverLocationUpdate(
                driverId: driverId,
                driverLatitude: lat,
                driverLongitude: lng,
                rotation: rot,
                active: true,
              );
              driverLocationList.add(driverLoc);
            }
          }
        });

        if (Constant.homeScreenType == 'UberHome') {
          // Remove old markers that aren't core markers
          final List<String> keysToRemove = [];
          markers.forEach((key, gp) {
            if (key != 'Departure' && key != 'Destination' && !key.startsWith('Stop')) {
              keysToRemove.add(key);
            }
          });
          
          for (var k in keysToRemove) {
            final gp = markers[k];
            if (gp != null) {
              try {
                await mapController.removeMarker(gp);
              } catch (_) {}
              markers.remove(k);
            }
          }

          for (var element in driverLocationList) {
            final gp = GeoPoint(
              latitude: double.parse(element.driverLatitude.toString().isNotEmpty ? element.driverLatitude.toString() : "0.0"),
              longitude: double.parse(element.driverLongitude.toString().isNotEmpty ? element.driverLongitude.toString() : "0.0"),
            );
            try {
              await mapController.addMarker(
                gp,
                markerIcon: MarkerIcon(iconWidget: taxiIcon!),
                angle: pi / 3,
                iconAnchor: IconAnchor(
                  anchor: Anchor.top,
                ),
              );
              markers[element.driverId.toString()] = gp;
            } catch (_) {}
          }
        }
        update();
      } catch (e) {
        showLog("Error parsing RTDB drivers: $e");
      }
    });

    Constant.driverLocationUpdateCollection.where("active", isEqualTo: true).snapshots().listen((event) async {
      for (var element in event.docs) {
        DriverLocationUpdate driverLocationUpdate = DriverLocationUpdate.fromJson(element.data() as Map<String, dynamic>);
        if (!driverLocationList.any((e) => e.driverId == driverLocationUpdate.driverId)) {
          driverLocationList.add(driverLocationUpdate);
          if (Constant.homeScreenType == 'UberHome') {
            final gp = GeoPoint(
              latitude: double.parse(driverLocationUpdate.driverLatitude.toString().isNotEmpty ? driverLocationUpdate.driverLatitude.toString() : "0.0"),
              longitude: double.parse(driverLocationUpdate.driverLongitude.toString().isNotEmpty ? driverLocationUpdate.driverLongitude.toString() : "0.0"),
            );
            try {
              await mapController.addMarker(
                gp,
                markerIcon: MarkerIcon(iconWidget: taxiIcon!),
                angle: pi / 3,
                iconAnchor: IconAnchor(
                  anchor: Anchor.top,
                ),
              );
              markers[driverLocationUpdate.driverId.toString()] = gp;
            } catch (_) {}
          }
        }
      }
      update();
    });
  }

  // Future<dynamic> getDurationDistance(LatLng departureLatLong, LatLng destinationLatLong) async {
  //   ShowToastDialog.showLoader("Please wait");
  //   double originLat, originLong, destLat, destLong;
  //   originLat = departureLatLong.latitude;
  //   originLong = departureLatLong.longitude;
  //   destLat = destinationLatLong.latitude;
  //   destLong = destinationLatLong.longitude;

  //   String url = 'https://maps.googleapis.com/maps/api/distancematrix/json';
  //   http.Response restaurantToCustomerTime = await http.get(Uri.parse('$url?units=metric&origins=$originLat,'
  //       '$originLong&destinations=$destLat,$destLong&key=${Constant.kGoogleApiKey}'));

  //   var decodedResponse = jsonDecode(restaurantToCustomerTime.body);

  //   if (decodedResponse['status'] == 'OK' && decodedResponse['rows'].first['elements'].first['status'] == 'OK') {
  //     ShowToastDialog.closeLoader();
  //     return decodedResponse;
  //   }
  //   ShowToastDialog.closeLoader();
  //   return null;
  // }

  Future<PlacesDetailsResponse?> placeSelectAPI(BuildContext context) async {
    // show input autocomplete with selected mode
    // then get the Prediction selected
    Prediction? p = await PlacesAutocomplete.show(
      context: context,
      apiKey: Constant.kGoogleApiKey,
      mode: Mode.overlay,
      onError: (response) {},
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

  Future<dynamic> getUserPendingPayment() async {
    try {
      ShowToastDialog.showLoader("Please wait");

      Map<String, dynamic> bodyParams = {'user_id': Preferences.getInt(Preferences.userId)};
      final response = await http.post(Uri.parse(API.userPendingPayment), headers: API.header, body: jsonEncode(bodyParams));
      showLog("API :: URL :: ${API.userPendingPayment}");
      showLog("API :: Body :: ${jsonEncode(bodyParams)}");
      showLog("API :: Request Header :: ${API.header.toString()} ");
      showLog("API :: responseStatus :: ${response.statusCode} ");
      showLog("API :: responseBody :: ${response.body} ");
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

  Future<VehicleCategoryModel?> getVehicleCategory() async {
    try {
      ShowToastDialog.showLoader("Please wait");
      final response = await http.get(Uri.parse(API.getVehicleCategory), headers: API.header);
      showLog("API :: URL :: ${API.getVehicleCategory}");
      showLog("API :: Request Header :: ${API.header.toString()} ");
      showLog("API :: responseStatus :: ${response.statusCode} ");
      showLog("API :: responseBody :: ${response.body} ");
      Map<String, dynamic> responseBody = json.decode(response.body);
      if (response.statusCode == 200) {
        VehicleCategoryModel categories = VehicleCategoryModel.fromJson(responseBody);
        
        if (categories.data != null &&
            departureLatLong.value.latitude != 0.0 &&
            departureLatLong.value.longitude != 0.0) {
          final lat = departureLatLong.value.latitude.toString();
          final lng = departureLatLong.value.longitude.toString();
          final driversResponse = await http.get(
            Uri.parse("${API.driverDetails}?lat1=$lat&lng1=$lng"),
            headers: API.header,
          );
          if (driversResponse.statusCode == 200) {
            final driversBody = json.decode(driversResponse.body);
            final drivers = DriverModel.fromJson(driversBody);
            if (drivers.success == "Success" && drivers.data != null) {
              final availableTypes = drivers.data!
                  .map((d) => d.typeVehicule?.toLowerCase().trim())
                  .whereType<String>()
                  .toSet();
              categories.data = categories.data!.where((category) {
                final categoryLibelle = category.libelle?.toLowerCase().trim() ?? '';
                return availableTypes.contains(categoryLibelle);
              }).toList();
            } else {
              categories.data = [];
            }
          }
        }

        if (categories.data == null || categories.data!.isEmpty) {
          update();
          ShowToastDialog.closeLoader();
          ShowToastDialog.showToast("No drivers available in your area.".tr);
          return null;
        }

        update();
        ShowToastDialog.closeLoader();
        return categories;
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

  Future<DriverModel?> getDriverDetails(String typeVehicle, String lat1, String lng1) async {
    try {
      ShowToastDialog.showLoader("Please wait");
      final response = await http.get(Uri.parse("${API.driverDetails}?type_vehicle=$typeVehicle&lat1=$lat1&lng1=$lng1"), headers: API.header);
      showLog("API :: URL :: ${API.driverDetails}?type_vehicle=$typeVehicle&lat1=$lat1&lng1=$lng1");
      showLog("API :: Request Header :: ${API.header.toString()} ");
      showLog("API :: responseStatus :: ${response.statusCode} ");
      showLog("API :: responseBody :: ${response.body} ");
      Map<String, dynamic> responseBody = json.decode(response.body);

      if (response.statusCode == 200) {
        ShowToastDialog.closeLoader();
        return DriverModel.fromJson(responseBody);
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

  Future<dynamic> setFavouriteRide(Map<String, String> bodyParams) async {
    try {
      ShowToastDialog.showLoader("Please wait");
      final response = await http.post(Uri.parse(API.setFavouriteRide), headers: API.header, body: jsonEncode(bodyParams));
      Map<String, dynamic> responseBody = json.decode(response.body);
      showLog("API :: URL :: ${API.setFavouriteRide}");
      showLog("API :: URL :: ${jsonEncode(bodyParams)}");
      showLog("API :: Request Header :: ${API.header.toString()} ");
      showLog("API :: responseStatus :: ${response.statusCode} ");
      showLog("API :: responseBody :: ${response.body} ");
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
  }

  Future<dynamic> bookRide(Map<String, dynamic> bodyParams) async {
    try {
      ShowToastDialog.showLoader("Please wait");
      final response = await http.post(Uri.parse(API.bookRides), headers: API.header, body: jsonEncode(bodyParams));
      showLog("API :: URL :: ${API.bookRides}");
      showLog("API :: URL :: ${jsonEncode(bodyParams)}");
      showLog("API :: Request Header :: ${API.header.toString()} ");
      showLog("API :: responseStatus :: ${response.statusCode} ");
      showLog("API :: responseBody :: ${response.body} ");
      
      ShowToastDialog.closeLoader();
      
      if (response.statusCode == 200) {
        Map<String, dynamic> responseBody = json.decode(response.body);
        return responseBody;
      } else {
        return {
          'success': 'failed',
          'error': 'Server error: ${response.statusCode}. Please try again later.'
        };
      }
    } on TimeoutException {
      ShowToastDialog.closeLoader();
      return {
        'success': 'failed',
        'error': 'Connection timed out. Please check your network and try again.'
      };
    } on SocketException {
      ShowToastDialog.closeLoader();
      return {
        'success': 'failed',
        'error': 'No internet connection. Please verify your network.'
      };
    } catch (e) {
      ShowToastDialog.closeLoader();
      return {
        'success': 'failed',
        'error': 'An unexpected error occurred: $e'
      };
    }
  }

  double calculateTripPrice({
    required double distance,
    required double minimumDeliveryChargesWithin,
    required double minimumDeliveryCharges,
    required double deliveryCharges,
    double? basePrice,
    double? perKmPrice,
  }) {
    if (basePrice != null || perKmPrice != null) {
      double base = basePrice ?? 0.0;
      double perKm = perKmPrice ?? 0.0;
      return base + (distance * perKm);
    }
    double cout = 0.0;

    if (distance > minimumDeliveryChargesWithin) {
      cout = (distance * deliveryCharges).toDouble();
    } else {
      cout = minimumDeliveryCharges;
    }
    return cout;
  }

  // getCurrentLocation(bool isDepartureSet) async {
  //   if (isDepartureSet) {
  //     GeoPoint location = await mapController.myLocation();

  //     String url = 'https://nominatim.openstreetmap.org/reverse?format=json&lat=${location.latitude}&lon=${location.longitude}&zoom=18&addressdetails=1';
  //     var addressData = <String, dynamic>{};
  //     var package = Platform.isAndroid ? 'com.cabme' : 'com.cabme.ios';
  //     http.Response response = await http.get(
  //       Uri.parse(url),
  //       headers: {
  //         'User-Agent': package,
  //       },
  //     );

  //     if (response.statusCode == 200) {
  //       Map<String, dynamic> data = json.decode(response.body);
  //       addressData = data;

  //       for (var i = 0; i < Constant.allTaxList.length; i++) {
  //         if (addressData["address"]["county"].toString().toUpperCase() == Constant.allTaxList[i].country?.toUpperCase()) {
  //           Constant.taxList.add(Constant.allTaxList[i]);
  //         }
  //       }

  //       currentLocationController.text = addressData['display_name'] ?? '';
  //       departureController.text = addressData['display_name'] ?? '';
  //       setDepartureMarker(GeoPoint(latitude: location.latitude, longitude: location.longitude));
  //     }
  //   }
  // }

  setDepartureMarker(GeoPoint departure) async {
    if (Constant.homeScreenType == 'OlaHome') {
      departureLatLong.value = departure;
    } else {
      if (departure.latitude != 0 && departure.longitude != 0) {
        WidgetsBinding.instance.addPostFrameCallback((_) async {
          if (markers.containsKey('Departure')) {
            await mapController.removeMarker(markers['Departure']!);
          }
          await mapController
              .addMarker(departure,
                  markerIcon: MarkerIcon(iconWidget: departureIcon),
                  angle: pi / 3,
                  iconAnchor: IconAnchor(
                    anchor: Anchor.top,
                  ))
              .then((v) {
            markers['Departure'] = departure;
          });
          departureLatLong.value = departure;
          if (departureLatLong.value.latitude != 0 && destinationLatLong.value.latitude != 0) {
            getDirections();
            confirmWidgetVisible.value = true;
            // conformationBottomSheet(context);
          } else {
            await mapController.moveTo(departure, animate: true);
          }
        });
      }
    }
  }

  getDirections() async {
    List<GeoPoint> wayPointList = [];
    wayPointList.add(GeoPoint(latitude: departureLatLong.value.latitude, longitude: departureLatLong.value.longitude));
    for (var i = 0; i < multiStopListNew.length; i++) {
      wayPointList.add(GeoPoint(
          latitude: multiStopListNew[i].latitude.isEmpty ? 0 : double.parse(multiStopListNew[i].latitude.toString()),
          longitude: multiStopListNew[i].longitude.isEmpty
              ? 0
              : double.parse(
                  multiStopListNew[i].longitude.toString(),
                )));
    }
    wayPointList.add(GeoPoint(latitude: destinationLatLong.value.latitude, longitude: destinationLatLong.value.longitude));
    addPolyLine(wayPointList);
  }

  addPolyLine(List<GeoPoint> wayPointList) async {
    if (Constant.homeScreenType != 'OlaHome') {
      await mapController.removeLastRoad();
      roadInfo.value = await mapController.drawRoad(
        wayPointList.first,
        wayPointList.last,
        roadType: RoadType.car,
        intersectPoint: [...wayPointList],
        roadOption: RoadOption(
          roadWidth: Platform.isIOS ? 50 : 10,
          roadColor: Colors.blue,
          roadBorderWidth: Platform.isIOS ? 15 : 10, // Set the road border width (outline)
          roadBorderColor: Colors.black, // Border color
          zoomInto: true,
        ),
      );
      updateCameraLocation(source: wayPointList.first, destination: wayPointList.last, mapController: mapController);
      // await mapController.moveTo(GeoPoint(latitude: wayPointList.first.latitude, longitude: wayPointList.first.longitude), animate: true);
    }
  }

  Future<void> updateCameraLocation({required GeoPoint source, required GeoPoint destination, required MapController mapController}) async {
    BoundingBox bounds;

    if (source.latitude > destination.latitude && source.longitude > destination.longitude) {
      bounds = BoundingBox(
        north: source.latitude,
        south: destination.latitude,
        east: source.longitude,
        west: destination.longitude,
      );
    } else if (source.longitude > destination.longitude) {
      bounds = BoundingBox(
        north: destination.latitude,
        south: source.latitude,
        east: source.longitude,
        west: destination.longitude,
      );
    } else if (source.latitude > destination.latitude) {
      bounds = BoundingBox(
        north: source.latitude,
        south: destination.latitude,
        east: destination.longitude,
        west: source.longitude,
      );
    } else {
      bounds = BoundingBox(
        north: destination.latitude,
        south: source.latitude,
        east: destination.longitude,
        west: source.longitude,
      );
    }

    await mapController.zoomToBoundingBox(bounds, paddinInPixel: 300);

    // Verify the camera location
    await checkCameraLocation(bounds, mapController);
  }

  Future<void> checkCameraLocation(BoundingBox bounds, MapController mapController) async {
    // await mapController.rotateMapCamera(0);
    BoundingBox currentBounds = await mapController.bounds;

    if (currentBounds.north == -90 || currentBounds.south == -90) {
      return checkCameraLocation(bounds, mapController);
    }
  }

  setDestinationMarker(GeoPoint destination) async {
    if (Constant.homeScreenType != 'UberHome') {
      destinationLatLong.value = destination;
    } else {
      if (destination.latitude != 0 && destination.latitude != 0) {
        WidgetsBinding.instance.addPostFrameCallback((_) async {
          if (markers.containsKey('Destination')) {
            await mapController.removeMarker(markers['Destination']!);
          }
          await mapController
              .addMarker(destination,
                  markerIcon: MarkerIcon(iconWidget: destinationIcon),
                  angle: pi / 3,
                  iconAnchor: IconAnchor(
                    anchor: Anchor.top,
                  ))
              .then((v) {
            markers['Destination'] = destination;
          });

          destinationLatLong.value = destination;

          getDirections();
          confirmWidgetVisible.value = true;
          // conformationBottomSheet(context);
        });
      }
    }
  }

  setStopMarker(GeoPoint destination, int index) async {
    if (Constant.homeScreenType != 'UberHome') {
      destinationLatLong.value = destination;
    } else {
      WidgetsBinding.instance.addPostFrameCallback((_) async {
        if (markers.containsKey('Stop $index')) {
          await mapController.removeMarker(markers['Stop $index']!);
        }
        await mapController
            .addMarker(destination,
                markerIcon: MarkerIcon(iconWidget: stopIcon),
                angle: pi / 3,
                iconAnchor: IconAnchor(
                  anchor: Anchor.top,
                ))
            .then((v) {
          markers['Stop $index'] = destination;
        });

        if (departureLatLong.value.latitude != 0 && departureLatLong.value.longitude != 0) {
          getDirections();
          confirmWidgetVisible.value = true;
          // conformationBottomSheet(context);
        }
      });
    }
  }
}

class AddChildModelData {
  TextEditingController editingController = TextEditingController();

  AddChildModelData({required this.editingController});
}

class AddStopModelData {
  String latitude = "";
  String longitude = "";
  TextEditingController editingController = TextEditingController();

  AddStopModelData({
    required this.editingController,
    required this.latitude,
    required this.longitude,
  });
}
