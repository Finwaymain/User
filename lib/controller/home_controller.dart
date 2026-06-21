// ignore_for_file: depend_on_referenced_packages

import 'dart:async';
import 'package:firebase_database/firebase_database.dart';
import 'dart:convert';
import 'dart:io';
import 'package:finway/constant/constant.dart';
import 'package:finway/constant/logdata.dart';
import 'package:finway/constant/show_toast_dialog.dart';
import 'package:finway/model/banner_model.dart';
import 'package:finway/model/driver_location_update.dart';
import 'package:finway/model/driver_model.dart';
import 'package:finway/model/payment_method_model.dart';
import 'package:finway/model/vehicle_category_model.dart';
import 'package:finway/page/rent_vehicle_screens/rent_vehicle_screen.dart';
import 'package:finway/service/api.dart';
import 'package:finway/themes/constant_colors.dart';
import 'package:finway/utils/Preferences.dart';
import 'package:flutter/material.dart';
import 'package:flutter_polyline_points/flutter_polyline_points.dart';
import 'package:geolocator/geolocator.dart';
import 'package:get/get.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:http/http.dart' as http;
import 'package:location/location.dart';
import '../model/payment_setting_model.dart';
import 'package:geocoding/geocoding.dart' as get_cord_address;

import 'package:geolocator/geolocator.dart' as locationData;

class HomeController extends GetxController with GetSingleTickerProviderStateMixin {
  //for Choose your Rider
  TabController? tabController;
  LatLng get center {
    if (departureLatLong.value.latitude != 0.0 && departureLatLong.value.longitude != 0.0) {
      return departureLatLong.value;
    }
    return const LatLng(41.4219057, -102.0840772);
  }

  final TextEditingController currentLocationController = TextEditingController();
  final TextEditingController departureController = TextEditingController();
  final TextEditingController destinationController = TextEditingController();

  RxString selectPaymentMode = "Payment Method".obs;
  List<AddChildModel> addChildList = [AddChildModel(editingController: TextEditingController())];
  List<AddStopModel> multiStopList = [];
  List<AddStopModel> multiStopListNew = [];

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
  RxBool isHomePageLoading = false.obs;
  RxString walletAmount = '0'.obs;
  @override
  void onInit() {
    setInitData();
    super.onInit();
  }

  setInitData() async {
    isHomePageLoading.value = true;
    if (Constant.homeScreenType != 'OlaHome') {
      await setIcons();
    }
    paymentSettingModel.value = Constant.getPaymentSetting();
    await setTabr();
    
    // Run long-running initialization tasks concurrently/asynchronously
    getTaxiData();
    initData();
    getCurrentAddress();
    getBannerData();
    
    isHomePageLoading.value = false;
  }

  initData() async {
    multiStopList.clear();
    multiStopListNew.clear();
    await getCurrentLocation(true);
  }

  getCurrentAddress() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        print("Geolocator service is not enabled");
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied || permission == LocationPermission.deniedForever) {
          print("Geolocator location permission denied");
          return;
        }
      }

      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: locationData.LocationAccuracy.low,
        timeLimit: const Duration(seconds: 10),
      );
      if (Constant.selectedMapType != 'osm') {
        final address = await Constant().getAddressFromLatLong(position);
        currentLocationController.text = address;
        departureController.text = address;
        departureLatLong.value = LatLng(position.latitude, position.longitude);
      }
    } catch (e) {
      print("Error in getCurrentAddress: $e");
    }
  }

  Rx<Location> currentLocation = Location().obs;
  getCurrentLocation(bool isDepartureSet) async {
    try {
      if (isDepartureSet) {
        bool serviceEnabled = await currentLocation.value.serviceEnabled();
        if (!serviceEnabled) {
          serviceEnabled = await currentLocation.value.requestService();
          if (!serviceEnabled) {
            print("Location service disabled");
            return;
          }
        }

        PermissionStatus permissionGranted = await currentLocation.value.hasPermission();
        if (permissionGranted == PermissionStatus.denied) {
          permissionGranted = await currentLocation.value.requestPermission();
          if (permissionGranted != PermissionStatus.granted) {
            print("Location permission denied");
            return;
          }
        }

        LocationData location = await currentLocation.value.getLocation().timeout(const Duration(seconds: 10));
        List<get_cord_address.Placemark> placeMarks = await get_cord_address.placemarkFromCoordinates(location.latitude ?? 0.0, location.longitude ?? 0.0);

        if (placeMarks.isNotEmpty && placeMarks.first.country != null) {
          for (var i = 0; i < Constant.allTaxList.length; i++) {
            if (Constant.allTaxList[i].country != null &&
                placeMarks.first.country!.toUpperCase() == Constant.allTaxList[i].country!.toUpperCase()) {
              Constant.taxList.add(Constant.allTaxList[i]);
            }
          }
        }

        String address = "";
        if (placeMarks.isNotEmpty) {
          var first = placeMarks.first;
          address = (first.subLocality == null || first.subLocality!.isEmpty ? '' : "${first.subLocality}, ") +
              (first.street == null || first.street!.isEmpty ? '' : "${first.street}, ") +
              (first.name == null || first.name!.isEmpty ? '' : "${first.name}, ") +
              (first.subAdministrativeArea == null || first.subAdministrativeArea!.isEmpty ? '' : "${first.subAdministrativeArea}, ") +
              (first.administrativeArea == null || first.administrativeArea!.isEmpty ? '' : "${first.administrativeArea}, ") +
              (first.country == null || first.country!.isEmpty ? '' : "${first.country}, ") +
              (first.postalCode == null || first.postalCode!.isEmpty ? '' : "${first.postalCode}, ");
        }
        currentLocationController.text = address;
        departureController.text = address;
        setDepartureMarker(LatLng(location.latitude ?? 0.0, location.longitude ?? 0.0));
      }
    } catch (e) {
      print("Error in getCurrentLocation: $e");
    }
  }

  GoogleMapController? mapController;
  setDepartureMarker(LatLng departure) {
    departureLatLong.value = departure;

    if (Constant.homeScreenType != 'OlaHome') {
      markers.remove("Departure");
      markers['Departure'] = Marker(
        markerId: const MarkerId('Departure'),
        infoWindow: InfoWindow(title: "Departure".tr),
        position: departure,
        icon: departureIcon!,
      );

      mapController?.animateCamera(CameraUpdate.newCameraPosition(CameraPosition(target: LatLng(departure.latitude, departure.longitude), zoom: 14)));

      // _controller?.animateCamera(CameraUpdate.newCameraPosition(CameraPosition(target: LatLng(departure.latitude, departure.longitude), zoom: 18)));
      if (departureLatLong.value.latitude != 0 && destinationLatLong.value.latitude != 0) {
        getDirections();
        confirmWidgetVisible.value = true;
        // conformationBottomSheet(context);
      }
    }
  }

  setDestinationMarker(LatLng destination) {
    destinationLatLong.value = destination;
    if (Constant.homeScreenType != 'OlaHome') {
      markers['Destination'] = Marker(
        markerId: const MarkerId('Destination'),
        infoWindow: InfoWindow(title: "Destination".tr),
        position: destination,
        icon: destinationIcon!,
      );

      if (departureLatLong.value.latitude != 0 && destinationLatLong.value.latitude != 0) {
        getDirections();
        confirmWidgetVisible.value = true;
        // conformationBottomSheet(context);
      }
    }
  }

  setStopMarker(LatLng destination, int index) {
    // final List<int> codeUnits = "Anand".codeUnits;
    // final Uint8List unit8List = Uint8List.fromList(codeUnits);
    // print('\x1b[97m ===== $unit8List =====');
    markers['Stop $index'] = Marker(
      markerId: MarkerId('Stop $index'),
      infoWindow: InfoWindow(title: "${"Stop".tr} ${String.fromCharCode(index + 65)}"),
      position: destination,
      icon: stopIcon!,
    ); //BitmapDescriptor.fromBytes(unit8List));
    // destinationLatLong = destination;

    if (departureLatLong.value.latitude != 0 && destinationLatLong.value.latitude != 0) {
      getDirections();
      confirmWidgetVisible.value = true;
      // conformationBottomSheet(context);
    }
  }

  Rx<LatLng> departureLatLong = const LatLng(0.0, 0.0).obs;
  Rx<LatLng> destinationLatLong = const LatLng(0.0, 0.0).obs;
  getDirections() async {
    if (Constant.homeScreenType != 'OlaHome') {
      List<PolylineWayPoint> wayPointList = [];
      for (var i = 0; i < multiStopList.length; i++) {
        wayPointList.add(PolylineWayPoint(location: multiStopList[i].editingController.text));
      }
      List<LatLng> polylineCoordinates = [];

      PolylineRequest requestData = PolylineRequest(
        wayPoints: wayPointList,
        optimizeWaypoints: true,
        mode: TravelMode.driving,
        origin: PointLatLng(departureLatLong.value.latitude, departureLatLong.value.longitude),
        destination: PointLatLng(destinationLatLong.value.latitude, destinationLatLong.value.longitude),
      );
      PolylineResult result = await PolylinePoints().getRouteBetweenCoordinates(
        googleApiKey: Constant.kGoogleApiKey.toString(),
        request: requestData,
      );

      if (result.points.isNotEmpty) {
        for (var point in result.points) {
          polylineCoordinates.add(LatLng(point.latitude, point.longitude));
        }
      }
      addPolyLine(polylineCoordinates);

      // Call Distance Matrix API to populate distance and duration reactively
      getDurationDistance(departureLatLong.value, destinationLatLong.value).then((value) {
        if (value != null) {
          if (Constant.distanceUnit == "KM") {
            distance.value = ((value['rows'].first['elements'].first['distance']['value'] as num) / 1000.00).toDouble();
          } else {
            distance.value = ((value['rows'].first['elements'].first['distance']['value'] as num) / 1609.34).toDouble();
          }
          duration.value = value['rows'].first['elements'].first['duration']['text'].toString();
          update();
        }
      });
    }
  }

  RxMap<PolylineId, Polyline> polyLines = <PolylineId, Polyline>{}.obs;
  addPolyLine(List<LatLng> polylineCoordinates) {
    PolylineId id = const PolylineId("poly");
    Polyline polyline = Polyline(
      polylineId: id,
      color: AppThemeData.primary200,
      points: polylineCoordinates,
      width: 6,
      geodesic: true,
    );
    polyLines[id] = polyline;
    updateCameraLocation(polylineCoordinates.first, polylineCoordinates.last, mapController);
  }

  Future<void> updateCameraLocation(
    LatLng source,
    LatLng destination,
    GoogleMapController? mapController,
  ) async {
    if (mapController == null) return;

    LatLngBounds bounds;

    if (source.latitude > destination.latitude && source.longitude > destination.longitude) {
      bounds = LatLngBounds(southwest: destination, northeast: source);
    } else if (source.longitude > destination.longitude) {
      bounds = LatLngBounds(southwest: LatLng(source.latitude, destination.longitude), northeast: LatLng(destination.latitude, source.longitude));
    } else if (source.latitude > destination.latitude) {
      bounds = LatLngBounds(southwest: LatLng(destination.latitude, source.longitude), northeast: LatLng(source.latitude, destination.longitude));
    } else {
      bounds = LatLngBounds(southwest: source, northeast: destination);
    }

    CameraUpdate cameraUpdate = CameraUpdate.newLatLngBounds(bounds, 90);

    return checkCameraLocation(cameraUpdate, mapController);
  }

  Future<void> checkCameraLocation(CameraUpdate cameraUpdate, GoogleMapController mapController) async {
    mapController.animateCamera(cameraUpdate);
    LatLngBounds l1 = await mapController.getVisibleRegion();
    LatLngBounds l2 = await mapController.getVisibleRegion();

    if (l1.southwest.latitude == -90 || l2.southwest.latitude == -90) {
      return checkCameraLocation(cameraUpdate, mapController);
    }
  }

  setTabr() {
    if (Constant.parcelActive.toString() == "yes") {
      tabController = TabController(length: 3, vsync: this);
    } else {
      tabController = TabController(length: 2, vsync: this);
    }
    tabController?.addListener(() {
      if (tabController!.indexIsChanging) {
        if (tabController?.index == 1) {
          Get.to(RentVehicleScreen())?.then((v) {
            tabController?.animateTo(0, duration: const Duration(milliseconds: 100));
          });
        }
      }
    });
  }

  BitmapDescriptor? departureIcon;
  BitmapDescriptor? destinationIcon;
  BitmapDescriptor? taxiIcon;
  BitmapDescriptor? stopIcon;

  final Map<String, Marker> markers = {};

  Future<void> setIcons() async {
    try {
      const ImageConfiguration imageConfig = ImageConfiguration(size: Size(48, 48));
      departureIcon = await BitmapDescriptor.fromAssetImage(imageConfig, "assets/icons/pickup.png");
      destinationIcon = await BitmapDescriptor.fromAssetImage(imageConfig, "assets/icons/dropoff.png");
      taxiIcon = await BitmapDescriptor.fromAssetImage(imageConfig, "assets/icons/ic_taxi.png");
      stopIcon = await BitmapDescriptor.fromAssetImage(imageConfig, "assets/icons/location.png");
    } catch (e) {
      print('Error loading icons: $e');
    }
  }

  addStops() async {
    ShowToastDialog.showLoader("Please wait");
    multiStopList.add(AddStopModel(editingController: TextEditingController(), latitude: "", longitude: ""));
    multiStopListNew = List<AddStopModel>.generate(
      multiStopList.length,
      (int index) => AddStopModel(editingController: multiStopList[index].editingController, latitude: multiStopList[index].latitude, longitude: multiStopList[index].longitude),
    );
    ShowToastDialog.closeLoader();
    update();
  }

  removeStops(int index) {
    ShowToastDialog.showLoader("Please wait");
    multiStopList.removeAt(index);
    multiStopListNew = List<AddStopModel>.generate(
      multiStopList.length,
      (int index) => AddStopModel(editingController: multiStopList[index].editingController, latitude: multiStopList[index].latitude, longitude: multiStopList[index].longitude),
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


  /// Cache of driver positions used for smooth interpolation.
  final Map<String, LatLng> _previousDriverPositions = {};

  /// Animates a driver marker from its last known position to [target] over ~500ms.
  void _animateMarker(String driverId, LatLng target, double targetRotation) {
    final LatLng start = _previousDriverPositions[driverId] ?? target;
    _previousDriverPositions[driverId] = target;
    if (start == target) return;

    const int steps = 30;   // ~500ms at 16ms/frame
    int step = 0;

    Timer.periodic(const Duration(milliseconds: 16), (t) {
      step++;
      if (step >= steps) {
        t.cancel();
        markers[driverId] = markers[driverId]!.copyWith(
          positionParam: target,
          rotationParam: targetRotation,
        );
        update();
        return;
      }
      final double fraction = step / steps;
      final LatLng interpolated = LatLng(
        start.latitude + (target.latitude - start.latitude) * fraction,
        start.longitude + (target.longitude - start.longitude) * fraction,
      );
      if (markers.containsKey(driverId)) {
        markers[driverId] = markers[driverId]!.copyWith(
          positionParam: interpolated,
          rotationParam: targetRotation,
        );
        update();
      }
    });
  }

  RxList<DriverLocationUpdate> driverLocationList = <DriverLocationUpdate>[].obs;

  Future getTaxiData() async {
    FirebaseDatabase.instance.ref("drivers").onValue.listen((event) {
      if (event.snapshot.value == null) return;
      try {
        final driversData = event.snapshot.value as Map<dynamic, dynamic>;
        driverLocationList.clear();
        driversData.forEach((key, value) {
          if (value is Map) {
            final active = value['active'] ?? false;
            if (active == true) {
              final driverId = key.toString();
              final lat = double.tryParse(value['driver_latitude']?.toString() ?? '') ?? 0.0;
              final lng = double.tryParse(value['driver_longitude']?.toString() ?? '') ?? 0.0;
              final rot = double.tryParse(value['rotation']?.toString() ?? '') ?? 0.0;

              final driverLoc = DriverLocationUpdate(
                driverId: driverId,
                driverLatitude: lat.toString(),
                driverLongitude: lng.toString(),
                rotation: rot.toString(),
                active: true,
              );
              driverLocationList.add(driverLoc);

              if (Constant.homeScreenType != 'OlaHome') {
                final LatLng target = LatLng(lat, lng);
                if (!markers.containsKey(driverId)) {
                  // First appearance — place immediately
                  markers[driverId] = Marker(
                    markerId: MarkerId(driverId),
                    rotation: rot,
                    position: target,
                    icon: taxiIcon!,
                  );
                  _previousDriverPositions[driverId] = target;
                  update();
                } else {
                  // Subsequent updates — smooth interpolation
                  _animateMarker(driverId, target, rot);
                }
              }
            }
          }
        });

        // Remove markers for drivers who went offline
        if (Constant.homeScreenType != 'OlaHome') {
          final activIds = driverLocationList.map((d) => d.driverId).toSet();
          markers.removeWhere((key, _) =>
              key != 'Departure' &&
              key != 'Destination' &&
              !key.startsWith('Stop') &&
              !activIds.contains(key));
          update();
        }
      } catch (e) {
        showLog("Error parsing RTDB drivers: $e");
      }
    });
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

  Future<dynamic> getDurationDistance(LatLng departureLatLong, LatLng destinationLatLong) async {
    try {
      ShowToastDialog.showLoader("Please wait");
      double originLat, originLong, destLat, destLong;
      originLat = departureLatLong.latitude;
      originLong = departureLatLong.longitude;
      destLat = destinationLatLong.latitude;
      destLong = destinationLatLong.longitude;

      String url = 'https://maps.googleapis.com/maps/api/distancematrix/json';
      http.Response response = await http.get(Uri.parse('$url?units=metric&origins=$originLat,'
          '$originLong&destinations=$destLat,$destLong&key=${Constant.kGoogleApiKey}'));

      showLog("API :: URL :: '${'$url?units=metric&origins=$originLat,'
          '$originLong&destinations=$destLat,$destLong&key=${Constant.kGoogleApiKey}'}");
      showLog("API :: Request Header :: ${API.header.toString()} ");
      showLog("API :: responseStatus :: ${response.statusCode} ");
      showLog("API :: responseBody :: ${response.body} ");

      var decodedResponse = jsonDecode(response.body);

      if (decodedResponse['status'] == 'OK' && decodedResponse['rows'].first['elements'].first['status'] == 'OK') {
        ShowToastDialog.closeLoader();
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
  }

  Future<dynamic> getUserPendingPayment() async {
    try {
      Map<String, dynamic> bodyParams = {'user_id': Preferences.getInt(Preferences.userId)};
      final response = await http.post(Uri.parse(API.userPendingPayment), headers: API.header, body: jsonEncode(bodyParams));
      showLog("API :: URL :: '${API.userPendingPayment}");
      showLog("API :: Body :: '${jsonEncode(bodyParams)}");
      showLog("API :: Request Header :: ${API.header.toString()} ");
      showLog("API :: responseStatus :: ${response.statusCode} ");
      showLog("API :: responseBody :: ${response.body} ");
      Map<String, dynamic> responseBody = json.decode(response.body);
      if (response.statusCode == 200) {
        return responseBody;
      } else {
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
      showLog("API :: URL :: '${API.getVehicleCategory}");
      showLog("API :: Request Header :: ${API.header.toString()} ");
      showLog("API :: responseStatus :: ${response.statusCode} ");
      showLog("API :: responseBody :: ${response.body} ");
      Map<String, dynamic> responseBody = json.decode(response.body);
      if (response.statusCode == 200) {
        update();
        ShowToastDialog.closeLoader();
        return VehicleCategoryModel.fromJson(responseBody);
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
      showLog("API :: Request Body :: ${jsonEncode(bodyParams)} ");
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
      showLog("API :: Request Body :: ${jsonEncode(bodyParams)} ");
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
    } on TimeoutException catch (e) {
      ShowToastDialog.closeLoader();
      return {
        'success': 'failed',
        'error': 'Connection timed out. Please check your network and try again.'
      };
    } on SocketException catch (e) {
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

  double calculateTripPrice({required double distance, required double minimumDeliveryChargesWithin, required double minimumDeliveryCharges, required double deliveryCharges}) {
    double cout = 0.0;

    if (distance > minimumDeliveryChargesWithin) {
      cout = (distance * deliveryCharges).toDouble();
    } else {
      cout = minimumDeliveryCharges;
    }
    return cout;
  }

  Rx<BannerModel> bannerModel = BannerModel().obs;
}

class AddChildModel {
  TextEditingController editingController = TextEditingController();

  AddChildModel({required this.editingController});
}

class AddStopModel {
  String latitude = "";
  String longitude = "";
  TextEditingController editingController = TextEditingController();

  AddStopModel({
    required this.editingController,
    required this.latitude,
    required this.longitude,
  });
}
