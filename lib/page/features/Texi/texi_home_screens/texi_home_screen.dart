import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:get/get.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:provider/provider.dart';
import 'package:http/http.dart' as http;
import 'package:geolocator/geolocator.dart';
import 'package:location/location.dart';

import 'package:finway/constant/constant.dart';
import 'package:finway/constant/show_toast_dialog.dart';
import 'package:finway/controller/dash_board_controller.dart';
import 'package:finway/controller/home_controller.dart';
import 'package:finway/model/driver_model.dart';
import 'package:finway/model/vehicle_category_model.dart';
import 'package:finway/model/ride_model.dart';
import 'package:finway/page/features/Texi/texi_dash_board.dart';
import 'package:finway/page/new_ride_screens/searching_driver_screen.dart';
import 'package:finway/page/search_location_screen.dart';
import 'package:finway/page/in_progress_screen.dart';
import 'package:finway/themes/button_them.dart';
import 'package:finway/themes/constant_colors.dart';
import 'package:finway/themes/responsive.dart';
import 'package:finway/utils/Preferences.dart';
import 'package:finway/utils/dark_theme_provider.dart';
import 'package:finway/service/db_helper.dart';
import 'package:finway/service/api.dart';
import 'package:finway/page/auth_screens/login_screen.dart';
import 'package:finway/page/new_ride_screens/new_ride_screen.dart';

class TexiHomeScreen extends StatefulWidget {
  const TexiHomeScreen({super.key});

  @override
  State<TexiHomeScreen> createState() => _TexiHomeScreenState();
}

class _TexiHomeScreenState extends State<TexiHomeScreen> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  final dashBoardController = Get.put(DashBoardController());
  
  bool isLocationSelected = false;
  bool isPickingOnMap = false;
  bool pickingDrop = false; // true if picking drop, false if picking pickup
  LatLng mapCenter = const LatLng(9.0820, 8.6753);
  
  List<SearchHistoryItem> searchHistory = [];
  VehicleCategoryModel? vehicleCategoryModel;
  VehicleData? selectedVehicle;
  DriverModel? nearbyDrivers;
  bool isLoadingDrivers = false;
  
  String selectedPaymentMethod = "cash"; // cash, wallet, upi
  bool isSimulatingUPI = false;
  String upiStepText = "";

  @override
  void initState() {
    super.initState();
    checkActiveRide();
    loadHistory();
    fetchVehicleCategories();
  }

  Future<void> checkActiveRide() async {
    try {
      final userId = Preferences.getInt(Preferences.userId);
      final response = await http.get(
        Uri.parse('${API.newRide}?id_user_app=$userId'),
        headers: API.header,
      );
      if (response.statusCode == 200) {
        final body = json.decode(response.body);
        if (body['success'] == 'success' && body['data'] != null) {
          final rides = (body['data'] as List)
              .map((e) => RideData.fromJson(e as Map<String, dynamic>))
              .where((r) =>
                  r.statut == 'confirmed' ||
                  r.statut == 'on ride' ||
                  r.statut == 'new')
              .toList();

          if (rides.isNotEmpty && mounted) {
            Get.off(() => const InProgressScreen());
          }
        }
      }
    } catch (e) {
      print('Check active ride error: $e');
    }
  }

  Future<void> loadHistory() async {
    try {
      final list = await DBHelper.getHistory();
      if (mounted) {
        setState(() {
          searchHistory = list;
        });
      }
    } catch (e) {
      print('Load history error: $e');
    }
  }

  Future<void> fetchVehicleCategories() async {
    try {
      final homeCtrl = Get.find<HomeController>();
      final categories = await homeCtrl.getVehicleCategory();
      if (categories != null && categories.data != null && categories.data!.isNotEmpty) {
        if (mounted) {
          setState(() {
            vehicleCategoryModel = categories;
            selectedVehicle = categories.data!.first;
          });
          fetchNearbyDrivers();
        }
      }
    } catch (e) {
      print('Fetch categories error: $e');
    }
  }

  Future<void> fetchNearbyDrivers() async {
    if (selectedVehicle == null) return;
    final homeCtrl = Get.find<HomeController>();
    if (mounted) {
      setState(() {
        isLoadingDrivers = true;
      });
    }
    try {
      final drivers = await homeCtrl.getDriverDetails(
        selectedVehicle!.id.toString(),
        homeCtrl.departureLatLong.value.latitude.toString(),
        homeCtrl.departureLatLong.value.longitude.toString(),
      );
      if (mounted) {
        setState(() {
          nearbyDrivers = drivers;
          isLoadingDrivers = false;
        });
      }
    } catch (e) {
      print('Fetch drivers error: $e');
      if (mounted) {
        setState(() {
          isLoadingDrivers = false;
        });
      }
    }
  }

  Future<void> selectSearchLocation(bool isDrop) async {
    final result = await Get.to(() => AddressSearchScreen());
    if (result != null) {
      final homeCtrl = Get.find<HomeController>();
      if (isDrop) {
        homeCtrl.destinationLatLong.value = LatLng(result.latitude, result.longitude);
        homeCtrl.destinationController.text = result.address;
        
        // Save to SQLite search history
        await DBHelper.insertSearch(result.address, result.latitude, result.longitude);
        loadHistory();
      } else {
        homeCtrl.departureLatLong.value = LatLng(result.latitude, result.longitude);
        homeCtrl.departureController.text = result.address;
      }

      if (homeCtrl.departureController.text.isNotEmpty && homeCtrl.destinationController.text.isNotEmpty) {
        setState(() {
          isLocationSelected = true;
        });
        homeCtrl.getDirections();
        fetchVehicleCategories();
      }
    }
  }

  void startMapPicking(bool isDrop) {
    setState(() {
      isPickingOnMap = true;
      pickingDrop = isDrop;
    });
  }

  Future<void> confirmMapPickedLocation() async {
    final homeCtrl = Get.find<HomeController>();
    ShowToastDialog.showLoader("Resolving address...".tr);
    try {
      String address = await Constant().getAddressFromLatLong(Position(
        latitude: mapCenter.latitude,
        longitude: mapCenter.longitude,
        timestamp: DateTime.now(),
        accuracy: 1.0,
        altitude: 0.0,
        heading: 0.0,
        speed: 0.0,
        speedAccuracy: 0.0,
        altitudeAccuracy: 0.0,
        headingAccuracy: 0.0,
      ));
      
      ShowToastDialog.closeLoader();

      if (pickingDrop) {
        homeCtrl.destinationLatLong.value = mapCenter;
        homeCtrl.destinationController.text = address;
        await DBHelper.insertSearch(address, mapCenter.latitude, mapCenter.longitude);
        loadHistory();
      } else {
        homeCtrl.departureLatLong.value = mapCenter;
        homeCtrl.departureController.text = address;
      }

      setState(() {
        isPickingOnMap = false;
      });

      if (homeCtrl.departureController.text.isNotEmpty && homeCtrl.destinationController.text.isNotEmpty) {
        setState(() {
          isLocationSelected = true;
        });
        homeCtrl.getDirections();
        fetchVehicleCategories();
      }
    } catch (e) {
      ShowToastDialog.closeLoader();
      ShowToastDialog.showToast("Failed to resolve location address.");
    }
  }

  Future<void> simulateUPILaunch(VoidCallback onSuccess) async {
    setState(() {
      isSimulatingUPI = true;
      upiStepText = "Connecting to UPI gateway...".tr;
    });
    await Future.delayed(const Duration(seconds: 1));
    setState(() {
      upiStepText = "Redirecting to installed BHIM UPI app...".tr;
    });
    await Future.delayed(const Duration(seconds: 1));
    setState(() {
      upiStepText = "Simulating transaction security handshake...".tr;
    });
    await Future.delayed(const Duration(seconds: 1));
    setState(() {
      isSimulatingUPI = false;
    });
    
    // Show beautiful success dialog
    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 30, horizontal: 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.check_circle_outline, color: Colors.green, size: 70),
              const SizedBox(height: 20),
              Text(
                "Payment Successful".tr,
                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 10),
              Text(
                "Your UPI transaction was completed successfully.".tr,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.grey),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppThemeData.primary200,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                onPressed: () {
                  Navigator.of(context).pop();
                },
                child: Text("OK".tr, style: const TextStyle(color: Colors.white)),
              )
            ],
          ),
        ),
      ),
    );
    
    onSuccess();
  }

  Future<void> executeBooking() async {
    final homeCtrl = Get.find<HomeController>();
    
    if (selectedVehicle == null) {
      ShowToastDialog.showToast("Please select a vehicle category");
      return;
    }

    if (nearbyDrivers == null || nearbyDrivers!.data == null || nearbyDrivers!.data!.isEmpty) {
      ShowToastDialog.showToast("No drivers available for this vehicle type");
      return;
    }

    // Select the first available driver from searched vehicle
    final driver = nearbyDrivers!.data!.first;

    // Price calculation
    double tripPrice = double.tryParse(selectedVehicle!.prix ?? '0') ?? 0.0;
    double totalCout = tripPrice * (homeCtrl.distance.value > 0.0 ? homeCtrl.distance.value : 1.0);

    // Resolve paymentMethodId
    String paymentMethodId = "";
    if (selectedPaymentMethod == "cash") {
      paymentMethodId = homeCtrl.paymentSettingModel.value.cash?.idPaymentMethod?.toString() ?? "1";
    } else if (selectedPaymentMethod == "wallet") {
      paymentMethodId = homeCtrl.paymentSettingModel.value.myWallet?.idPaymentMethod?.toString() ?? "2";
    } else {
      paymentMethodId = "upi_mock";
    }

    Map<String, dynamic> bodyParams = {
      'user_id': Preferences.getInt(Preferences.userId).toString(),
      'lat1': homeCtrl.departureLatLong.value.latitude.toString(),
      'lng1': homeCtrl.departureLatLong.value.longitude.toString(),
      'lat2': homeCtrl.destinationLatLong.value.latitude.toString(),
      'lng2': homeCtrl.destinationLatLong.value.longitude.toString(),
      'cout': totalCout.toString(),
      'distance': homeCtrl.distance.value.toString(),
      'distance_unit': Constant.distanceUnit.toString(),
      'duree': homeCtrl.duration.toString(),
      'id_conducteur': driver.id.toString(),
      'id_payment': paymentMethodId,
      'depart_name': homeCtrl.departureController.text,
      'destination_name': homeCtrl.destinationController.text,
      'stops': [],
      'place': '',
      'number_poeple': '1',
      'image': '',
      'image_name': "",
      'statut_round': 'no',
      'trip_objective': '',
      'age_children1': '',
      'age_children2': '',
      'age_children3': '',
    };

    if (selectedPaymentMethod == "upi") {
      await simulateUPILaunch(() {
        homeCtrl.bookRide(bodyParams).then((value) {
          if (value != null && value['success'] == "success") {
            Get.off(() => const SearchingDriverScreen(), arguments: {
              'rideData': RideData.fromJson(value['data']),
              'bookingBodyParams': bodyParams,
            });
          } else {
            ShowToastDialog.showToast(value != null ? value['error'] : "Booking failed");
          }
        });
      });
    } else {
      homeCtrl.bookRide(bodyParams).then((value) {
        if (value != null && value['success'] == "success") {
          Get.off(() => const SearchingDriverScreen(), arguments: {
            'rideData': RideData.fromJson(value['data']),
            'bookingBodyParams': bodyParams,
          });
        } else {
          ShowToastDialog.showToast(value != null ? value['error'] : "Booking failed");
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeChange = Provider.of<DarkThemeProvider>(context);
    final bool isDarkMode = themeChange.getThem();
    
    return GetX<HomeController>(
      init: HomeController(),
      builder: (controller) {
        return Scaffold(
          key: _scaffoldKey,
          drawer: buildAppDrawer(context, dashBoardController),
          body: Stack(
            children: [
              // Map background (only active when picking location or location is selected)
              if (isPickingOnMap || isLocationSelected)
                Positioned.fill(
                  child: GoogleMap(
                    zoomControlsEnabled: false,
                    myLocationButtonEnabled: false,
                    compassEnabled: false,
                    initialCameraPosition: CameraPosition(
                      target: controller.center,
                      zoom: 14.0,
                    ),
                    onMapCreated: (mapcontrollerdata) async {
                      controller.mapController = mapcontrollerdata;
                      if (controller.departureLatLong.value.latitude != 0.0 && controller.departureLatLong.value.longitude != 0.0) {
                        controller.mapController!.moveCamera(CameraUpdate.newLatLngZoom(
                          controller.departureLatLong.value, 14
                        ));
                      } else {
                        try {
                          LocationData location = await controller.currentLocation.value.getLocation().timeout(const Duration(seconds: 5));
                          controller.mapController!.moveCamera(CameraUpdate.newLatLngZoom(
                            LatLng(location.latitude ?? 0.0, location.longitude ?? 0.0), 14
                          ));
                        } catch (_) {}
                      }
                    },
                    onCameraMove: (pos) {
                      mapCenter = pos.target;
                    },
                    polylines: Set<Polyline>.of(controller.polyLines.values),
                    myLocationEnabled: true,
                    markers: controller.markers.values.toSet(),
                  ),
                )
              else
                Positioned.fill(
                  child: Container(
                    color: isDarkMode ? AppThemeData.surface50Dark : Colors.white,
                  ),
                ),

              // Custom floating appbar
              Positioned(
                top: 40,
                left: 16,
                right: 16,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: isDarkMode ? AppThemeData.surface50Dark : Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.08),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      )
                    ],
                  ),
                  child: Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.menu),
                        onPressed: () {
                          _scaffoldKey.currentState?.openDrawer();
                        },
                      ),
                      const SizedBox(width: 8),
                      Text(
                        "Fiinway Ride".tr,
                        style: TextStyle(
                          fontSize: 18,
                          fontFamily: AppThemeData.semiBold,
                          color: isDarkMode ? Colors.white : Colors.black87,
                        ),
                      ),
                      const Spacer(),
                      if (isLocationSelected || isPickingOnMap)
                        IconButton(
                          icon: const Icon(Icons.close),
                          onPressed: () {
                            setState(() {
                              isLocationSelected = false;
                              isPickingOnMap = false;
                            });
                            controller.polyLines.clear();
                          },
                        )
                      else
                        IconButton(
                          icon: const Icon(Icons.history),
                          onPressed: () {
                            if (!Preferences.getBoolean(Preferences.isLogin)) {
                              Get.to(() => const LoginScreen(), transition: Transition.rightToLeftWithFade);
                              return;
                            }
                            Get.to(() => const NewRideScreen(), transition: Transition.rightToLeftWithFade);
                          },
                        )
                    ],
                  ),
                ),
              ),

              // Pin crosshair for map selection mode
              if (isPickingOnMap)
                Align(
                  alignment: Alignment.center,
                  child: Padding(
                    padding: const EdgeInsets.only(bottom: 30),
                    child: const Text(
                      '📍',
                      style: TextStyle(
                        fontSize: 40,
                      ),
                    ),
                  ),
                ),

              // Bottom Sheet Panel
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                child: AnimatedSize(
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeOutQuart,
                  child: Container(
                    decoration: BoxDecoration(
                      color: isDarkMode ? AppThemeData.surface50Dark : Colors.white,
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(24),
                        topRight: Radius.circular(24),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.12),
                          blurRadius: 20,
                          offset: const Offset(0, -6),
                        )
                      ],
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
                    child: isPickingOnMap
                        ? buildMapPickingPanel()
                        : isLocationSelected
                            ? buildBookingDetailsPanel(controller, isDarkMode)
                            : buildSearchLocationPanel(controller, isDarkMode),
                  ),
                ),
              ),

              // UPI Simulation Overlay
              if (isSimulatingUPI)
                Positioned.fill(
                  child: Container(
                    color: Colors.black.withOpacity(0.7),
                    child: Center(
                      child: Card(
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        color: isDarkMode ? AppThemeData.surface50Dark : Colors.white,
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 30),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              CircularProgressIndicator(color: AppThemeData.primary200),
                              const SizedBox(height: 24),
                              Text(
                                upiStepText,
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                )
            ],
          ),
        );
      },
    );
  }

  Widget buildMapPickingPanel() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          pickingDrop ? "Choose Drop Location on Map".tr : "Choose Pickup Location on Map".tr,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 8),
        Text(
          "Drag map to position pin accurately.".tr,
          style: const TextStyle(fontSize: 13, color: Colors.grey),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 20),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: AppThemeData.primary200,
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
          onPressed: confirmMapPickedLocation,
          child: Text(
            "Confirm Location".tr,
            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
        )
      ],
    );
  }

  Widget buildSearchLocationPanel(HomeController controller, bool isDarkMode) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Title greeting
        Text(
          "Plan Your Journey".tr,
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: isDarkMode ? Colors.white : Colors.black87,
          ),
        ),
        const SizedBox(height: 16),

        // Pickup Input
        InkWell(
          onTap: () => selectSearchLocation(false),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: isDarkMode ? AppThemeData.grey800 : Colors.grey.shade100,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                const Icon(Icons.my_location, color: Colors.green, size: 20),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    controller.departureController.text.isNotEmpty
                        ? controller.departureController.text
                        : "Current Location".tr,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: isDarkMode ? Colors.white70 : Colors.black87,
                      fontSize: 14,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 10),

        // Destination Input (Search bar)
        InkWell(
          onTap: () => selectSearchLocation(true),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: isDarkMode ? AppThemeData.grey800 : Colors.grey.shade100,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppThemeData.primary200.withOpacity(0.5), width: 1.5),
            ),
            child: Row(
              children: [
                Icon(Icons.search, color: AppThemeData.primary200, size: 22),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    controller.destinationController.text.isNotEmpty
                        ? controller.destinationController.text
                        : "Where to go?".tr,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: controller.destinationController.text.isNotEmpty
                          ? (isDarkMode ? Colors.white : Colors.black87)
                          : Colors.grey,
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),

        // Pick on map option
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            TextButton.icon(
              onPressed: () => startMapPicking(false),
              icon: const Icon(Icons.pin_drop_outlined, size: 18),
              label: Text("Pick Pickup on Map".tr),
            ),
            TextButton.icon(
              onPressed: () => startMapPicking(true),
              icon: const Icon(Icons.map_outlined, size: 18),
              label: Text("Pick Drop on Map".tr),
            ),
          ],
        ),

        // SQLite persistent Search History List
        if (searchHistory.isNotEmpty) ...[
          const Divider(height: 20),
          Text(
            "Recent Searches".tr,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
          ),
          const SizedBox(height: 8),
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: searchHistory.length > 3 ? 3 : searchHistory.length,
            itemBuilder: (context, index) {
              final hist = searchHistory[index];
              return ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.history, color: Colors.grey),
                title: Text(
                  hist.address,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 13),
                ),
                onTap: () {
                  controller.destinationLatLong.value = LatLng(hist.latitude, hist.longitude);
                  controller.destinationController.text = hist.address;
                  if (controller.departureController.text.isNotEmpty) {
                    setState(() {
                      isLocationSelected = true;
                    });
                    controller.getDirections();
                    fetchVehicleCategories();
                  }
                },
              );
            },
          )
        ]
      ],
    );
  }

  Widget buildBookingDetailsPanel(HomeController controller, bool isDarkMode) {
    // Basic price show
    double basePrice = double.tryParse(selectedVehicle?.prix ?? '0.0') ?? 0.0;
    double distanceVal = double.tryParse(controller.distance.value.toString()) ?? 0.0;
    double tripPrice = basePrice * distanceVal;
    if (tripPrice < 1.0) tripPrice = basePrice;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Locations preview
        Row(
          children: [
            const Icon(Icons.circle, color: Colors.green, size: 12),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                controller.departureController.text,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 13),
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        Row(
          children: [
            const Icon(Icons.circle, color: Colors.red, size: 12),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                controller.destinationController.text,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
        const Divider(height: 20),

        // Horizontal vehicle categories list
        if (vehicleCategoryModel != null && vehicleCategoryModel!.data != null) ...[
          const Text(
            "Select Vehicle Category",
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
          ),
          const SizedBox(height: 8),
          SizedBox(
            height: 100,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: vehicleCategoryModel!.data!.length,
              itemBuilder: (context, index) {
                final category = vehicleCategoryModel!.data![index];
                final isSelected = selectedVehicle?.id == category.id;
                
                return GestureDetector(
                  onTap: () {
                    setState(() {
                      selectedVehicle = category;
                    });
                    fetchNearbyDrivers();
                  },
                  child: Container(
                    width: 110,
                    margin: const EdgeInsets.only(right: 12),
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? AppThemeData.primary200.withOpacity(0.12)
                          : (isDarkMode ? AppThemeData.grey800 : Colors.grey.shade50),
                      border: Border.all(
                        color: isSelected ? AppThemeData.primary200 : Colors.transparent,
                        width: 2,
                      ),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Expanded(
                          child: CachedNetworkImage(
                            imageUrl: category.image.toString(),
                            placeholder: (context, url) => const SizedBox(),
                            errorWidget: (context, url, error) => const Icon(Icons.directions_car),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          category.libelle.toString(),
                          maxLines: 1,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                          ),
                        ),
                        Text(
                          Constant().amountShow(
                            amount: ((double.tryParse(category.prix ?? '') ?? 0.0) * (distanceVal > 0.0 ? distanceVal : 1.0)).toString(),
                          ),
                          style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppThemeData.primary200),
                        )
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],

        // In search vehicle list available drivers
        const Divider(height: 24),
        Text(
          "Available Drivers (${selectedVehicle?.libelle ?? ''})".tr,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
        ),
        const SizedBox(height: 8),
        isLoadingDrivers
            ? const Center(child: Padding(
                padding: EdgeInsets.all(8.0),
                child: CircularProgressIndicator(),
              ))
            : selectedVehicle == null
                ? const Padding(
                    padding: EdgeInsets.all(12.0),
                    child: Text(
                      "Please select a vehicle category to view available drivers.",
                      style: TextStyle(color: Colors.grey, fontSize: 13),
                    ),
                  )
                : nearbyDrivers == null || nearbyDrivers!.data == null || nearbyDrivers!.data!.isEmpty
                    ? Padding(
                        padding: const EdgeInsets.all(12.0),
                        child: Text(
                          "No drivers found in this category nearby.".tr,
                          style: const TextStyle(color: Colors.grey, fontSize: 13),
                        ),
                      )
                    : SizedBox(
                        height: 125,
                        child: ListView.builder(
                          scrollDirection: Axis.horizontal,
                          itemCount: nearbyDrivers!.data!.length,
                          itemBuilder: (context, index) {
                            final driver = nearbyDrivers!.data![index];
                            return Container(
                              width: 180,
                              margin: const EdgeInsets.only(right: 12, bottom: 8, top: 4),
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: isDarkMode ? AppThemeData.grey800 : Colors.white,
                                border: Border.all(color: Colors.grey.withOpacity(0.2)),
                                borderRadius: BorderRadius.circular(16),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.04),
                                    blurRadius: 4,
                                    offset: const Offset(0, 2),
                                  )
                                ],
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Row(
                                    children: [
                                      CircleAvatar(
                                        backgroundImage: CachedNetworkImageProvider(driver.photo ?? Constant.placeholderUrl ?? ''),
                                        radius: 18,
                                      ),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              "${driver.prenom} ${driver.nom}",
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                                            ),
                                            Row(
                                              children: [
                                                const Icon(Icons.star, color: Colors.amber, size: 12),
                                                const SizedBox(width: 2),
                                                Text(
                                                  driver.moyenne ?? "5.0",
                                                  style: const TextStyle(fontSize: 10, color: Colors.grey),
                                                ),
                                              ],
                                            )
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                  const Spacer(),
                                  Text(
                                    driver.brand ?? "Active Driver",
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(fontWeight: FontWeight.w600, fontSize: 11, color: AppThemeData.primary200),
                                  ),
                                  Text(
                                    driver.numberplate ?? "",
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(fontSize: 10, color: Colors.grey),
                                  )
                                ],
                              ),
                            );
                          },
                        ),
                      ),

        // Payment Method Picker
        const Divider(height: 20),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              "Payment Method",
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            DropdownButton<String>(
              value: selectedPaymentMethod,
              items: [
                DropdownMenuItem(value: "cash", child: Text("Cash".tr)),
                DropdownMenuItem(value: "wallet", child: Text("Wallet".tr)),
                DropdownMenuItem(value: "upi", child: Text("UPI (Mock)".tr)),
              ],
              onChanged: (val) {
                if (val != null) {
                  setState(() {
                    selectedPaymentMethod = val;
                  });
                }
              },
            )
          ],
        ),
        const SizedBox(height: 16),

        // Book Button
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: AppThemeData.primary200,
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          ),
          onPressed: executeBooking,
          child: Text(
            "${"Book Ride - ".tr}${Constant().amountShow(amount: tripPrice.toString())}",
            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
          ),
        )
      ],
    );
  }
}
