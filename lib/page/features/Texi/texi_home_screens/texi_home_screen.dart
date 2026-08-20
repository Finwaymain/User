import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:provider/provider.dart';
import 'package:http/http.dart' as http;
import 'package:geolocator/geolocator.dart';
import 'package:location/location.dart';
import 'package:flutter_osm_plugin/flutter_osm_plugin.dart' show SearchInfo;

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
import 'package:finway/page/auth_screens/phone_entry_screen.dart';
import 'package:finway/page/route_view_screen/route_view_screen.dart';
import 'package:finway/page/route_view_screen/route_osm_view_screen.dart';
import 'package:finway/page/new_ride_screens/new_ride_screen.dart';
import 'package:finway/utils/location_picker_helper.dart';
import 'package:finway/page/MainDashBoard/widget/custom_bottom_navbar.dart';

class TexiHomeScreen extends StatefulWidget {
  final String? initialVehicleCategory;
  final int? initialTab;
  const TexiHomeScreen({super.key, this.initialVehicleCategory, this.initialTab});

  @override
  State<TexiHomeScreen> createState() => _TexiHomeScreenState();
}

class _TexiHomeScreenState extends State<TexiHomeScreen> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  final dashBoardController = Get.put(DashBoardController());
  int selectedTabIndex = 0;
  
  bool isLocationSelected = false;
  bool isPickingOnMap = false;
  bool pickingDrop = false; // true if picking drop, false if picking pickup
  bool isDetectingLocation = false;
  LatLng mapCenter = const LatLng(9.0820, 8.6753);
  
  List<SearchHistoryItem> searchHistory = [];
  VehicleCategoryModel? vehicleCategoryModel;
  VehicleData? selectedVehicle;
  DriverModel? nearbyDrivers;
  bool isLoadingDrivers = false;
  
  String selectedPaymentMethod = "cash"; // cash, wallet, upi
  bool isSimulatingUPI = false;
  String upiStepText = "";
  
  // Drag sheet state variables
  double sheetOffset = 0.0;
  bool isDragging = false;
  final GlobalKey _sheetKey = GlobalKey();
  double _sheetHeight = 450.0;
  
  // Booking progress guard
  bool isBookingInProgress = false;

  @override
  void initState() {
    super.initState();
    selectedTabIndex = widget.initialTab ?? 0;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      checkActiveRide();
      autoDetectPickupLocation();
    });
    loadHistory();
    fetchVehicleCategories();
  }

  /// Automatically fetches the current GPS location and sets it as the pickup location.
  /// If location / GPS is disabled, prompts the user via dialog to enable location.
  Future<void> autoDetectPickupLocation({bool userTriggered = false}) async {
    final homeCtrl = Get.find<HomeController>();

    // If pickup is already set and not explicitly re-triggered, don't overwrite
    if (!userTriggered &&
        homeCtrl.departureController.text.trim().isNotEmpty &&
        homeCtrl.departureLatLong.value.latitude != 0.0) {
      if (mounted) {
        setState(() {
          mapCenter = homeCtrl.departureLatLong.value;
        });
      }
      return;
    }

    if (mounted) {
      setState(() {
        isDetectingLocation = true;
      });
    }

    try {
      final loc = await LocationPickerHelper.fetchCurrentLocation(
        context: context,
        showLoader: userTriggered,
        showPromptDialog: true,
      );

      if (loc != null && mounted) {
        setState(() {
          homeCtrl.departureLatLong.value = LatLng(loc.latitude, loc.longitude);
          homeCtrl.departureController.text = loc.address;
          homeCtrl.currentLocationController.text = loc.address;
          mapCenter = LatLng(loc.latitude, loc.longitude);
          isDetectingLocation = false;
        });

        if (homeCtrl.mapController != null) {
          homeCtrl.mapController!.animateCamera(
            CameraUpdate.newLatLngZoom(LatLng(loc.latitude, loc.longitude), 15),
          );
        }

        if (homeCtrl.destinationController.text.trim().isNotEmpty) {
          setState(() {
            isLocationSelected = true;
          });
          homeCtrl.getDirections();
        }

        fetchVehicleCategories();
      } else if (mounted) {
        setState(() {
          isDetectingLocation = false;
        });
      }
    } catch (e) {
      print("autoDetectPickupLocation error: $e");
      if (mounted) {
        setState(() {
          isDetectingLocation = false;
        });
      }
    }
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
            final activeRide = rides.first;
            if (activeRide.statut == 'new') {
              Get.offAll(() => const SearchingDriverScreen(), arguments: {
                'rideData': activeRide,
              });
            } else {
              var argumentData = {'type': activeRide.statut, 'data': activeRide};
              if (Constant.selectedMapType == 'osm') {
                Get.offAll(() => RouteOsmViewScreen(), arguments: argumentData);
              } else {
                Get.offAll(() => RouteViewScreen(), arguments: argumentData);
              }
            }
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
      if (mounted) {
        setState(() {
          // Deduplicate by name/libelle — prevents same category name appearing multiple times
          // when the backend/driver-filter produces repeated matches
          if (categories != null && categories.data != null) {
            final seenNames = <String>{};
            categories.data = categories.data!
                .where((cat) {
                  final name = cat.libelle?.toLowerCase().trim() ?? '';
                  return name.isNotEmpty && seenNames.add(name);
                })
                .toList();
          }
          vehicleCategoryModel = categories ?? VehicleCategoryModel(data: []);
          selectedVehicle = null;
          nearbyDrivers = null;
        });
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
    if (result != null && result is SearchInfo) {
      final homeCtrl = Get.find<HomeController>();
      final double lat = result.point!.latitude;
      final double lng = result.point!.longitude;
      final String addr = result.address.toString();

      if (isDrop) {
        homeCtrl.destinationLatLong.value = LatLng(lat, lng);
        homeCtrl.destinationController.text = addr;

        // Save to SQLite search history
        await DBHelper.insertSearch(addr, lat, lng);
        loadHistory();
      } else {
        homeCtrl.departureLatLong.value = LatLng(lat, lng);
        homeCtrl.departureController.text = addr;
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

  double calculateRidePrice(VehicleData category, double distanceVal) {
    double? basePrice = double.tryParse(category.basePrice ?? '');
    double? perKmPrice = double.tryParse(category.perKmPrice ?? '');

    if (basePrice != null || perKmPrice != null) {
      double base = basePrice ?? 0.0;
      double perKm = perKmPrice ?? 0.0;
      return base + (distanceVal * perKm);
    }

    double prix = double.tryParse(category.prix ?? '0.0') ?? 0.0;
    double deliveryChargesPerKm = double.tryParse(category.deliveryCharges ?? '0.0') ?? 0.0;
    double minimumDeliveryCharges = double.tryParse(category.minimumDeliveryCharges ?? '0.0') ?? 0.0;
    double minimumDeliveryChargesWithin = double.tryParse(category.minimumDeliveryChargesWithin ?? '0.0') ?? 0.0;

    // Fallback if no delivery charges are set
    if (deliveryChargesPerKm == 0.0 && minimumDeliveryCharges == 0.0 && minimumDeliveryChargesWithin == 0.0) {
      double price = prix * (distanceVal > 0.0 ? distanceVal : 1.0);
      return price < 1.0 ? prix : price;
    }

    if (distanceVal <= minimumDeliveryChargesWithin) {
      return minimumDeliveryCharges;
    } else {
      return minimumDeliveryCharges + (distanceVal - minimumDeliveryChargesWithin) * deliveryChargesPerKm;
    }
  }

  Future<void> executeBooking() async {
    if (isBookingInProgress) return;

    final homeCtrl = Get.find<HomeController>();

    if (selectedVehicle == null) {
      ShowToastDialog.showToast("Please select a vehicle category");
      return;
    }

    if (homeCtrl.departureLatLong.value.latitude == 0.0 ||
        homeCtrl.destinationLatLong.value.latitude == 0.0) {
      ShowToastDialog.showToast("Please set pickup and drop location");
      return;
    }

    setState(() {
      isBookingInProgress = true;
    });

    try {
      // Price calculation using standard delivery charges formula
      double totalCout = calculateRidePrice(selectedVehicle!, homeCtrl.distance.value);

      // Resolve paymentMethodId
      String paymentMethodId = "";
      if (selectedPaymentMethod == "cash") {
        paymentMethodId = homeCtrl.paymentSettingModel.value.cash?.idPaymentMethod?.toString() ?? "1";
      } else if (selectedPaymentMethod == "wallet") {
        paymentMethodId = homeCtrl.paymentSettingModel.value.myWallet?.idPaymentMethod?.toString() ?? "2";
      } else {
        // UPI: use cash payment method ID as fallback since "upi_mock" is not a valid FK
        paymentMethodId = homeCtrl.paymentSettingModel.value.cash?.idPaymentMethod?.toString() ?? "1";
      }

      // Pass id_conducteur = 0 so the backend automatically finds the nearest
      // available driver for this vehicle type using its Haversine query.
      // This avoids pre-selecting a driver on the client, which could pick
      // a stale or unavailable driver.
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
        'id_conducteur': '0', // 0 = backend picks nearest driver automatically
        'id_payment': paymentMethodId,
        'id_type_vehicule': selectedVehicle!.id.toString(),
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
        await simulateUPILaunch(() async {
          try {
            final value = await homeCtrl.bookRide(bodyParams);
            setState(() {
              isBookingInProgress = false;
            });
            if (value != null && value['success'] == "success") {
              Get.offAll(() => const SearchingDriverScreen(), arguments: {
                'rideData': RideData.fromJson(value['data']),
                'bookingBodyParams': bodyParams,
              });
            } else {
              String errorMsg = value != null ? value['error'] : "Booking failed";
              ShowToastDialog.showToast(errorMsg);
              if (errorMsg.toLowerCase().contains("already on an active ride")) {
                checkActiveRide();
              }
            }
          } catch (e) {
            setState(() {
              isBookingInProgress = false;
            });
            ShowToastDialog.showToast("Booking failed: $e");
          }
        });
      } else {
        final value = await homeCtrl.bookRide(bodyParams);
        setState(() {
          isBookingInProgress = false;
        });
        if (value != null && value['success'] == "success") {
          Get.offAll(() => const SearchingDriverScreen(), arguments: {
            'rideData': RideData.fromJson(value['data']),
            'bookingBodyParams': bodyParams,
          });
        } else {
          String errorMsg = value != null ? value['error'] : "Booking failed";
          ShowToastDialog.showToast(errorMsg);
          if (errorMsg.toLowerCase().contains("already on an active ride")) {
            checkActiveRide();
          }
        }
      }
    } catch (e) {
      setState(() {
        isBookingInProgress = false;
      });
      ShowToastDialog.showToast("An error occurred: $e");
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
          bottomNavigationBar: const CustomBottomNavBar(currentIndex: 0),
          body: Stack(
            children: [
              // Map background (interactive map showing current location and route)
              Positioned.fill(
                child: GoogleMap(
                  zoomControlsEnabled: false,
                  myLocationButtonEnabled: false,
                  compassEnabled: false,
                  initialCameraPosition: CameraPosition(
                    target: controller.departureLatLong.value.latitude != 0.0
                        ? controller.departureLatLong.value
                        : controller.center,
                    zoom: 14.0,
                  ),
                  onMapCreated: (mapcontrollerdata) async {
                    controller.mapController = mapcontrollerdata;
                    if (controller.departureLatLong.value.latitude != 0.0 && controller.departureLatLong.value.longitude != 0.0) {
                      controller.mapController!.moveCamera(CameraUpdate.newLatLngZoom(
                        controller.departureLatLong.value, 15
                      ));
                    }
                  },
                  onCameraMove: (pos) {
                    mapCenter = pos.target;
                  },
                  polylines: Set<Polyline>.of(controller.polyLines.values),
                  myLocationEnabled: true,
                  markers: controller.markers.values.toSet(),
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

              // Custom Header / Address Card
              if (isPickingOnMap)
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
                          color: Colors.black.withValues(alpha: 0.08),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        )
                      ],
                    ),
                    child: Row(
                      children: [
                        IconButton(
                          icon: const Icon(Icons.arrow_back),
                          onPressed: () {
                            setState(() {
                              isPickingOnMap = false;
                            });
                          },
                        ),
                        const SizedBox(width: 8),
                        Text(
                          pickingDrop ? "Choose Drop Location".tr : "Choose Pickup Location".tr,
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ),
                )
              else
                Positioned(
                  top: 40,
                  left: 16,
                  right: 16,
                  child: buildTopAddressCard(controller, isDarkMode),
                ),

              // Bottom Sheet Panel
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                child: GestureDetector(
                  onVerticalDragStart: (details) {
                    setState(() {
                      isDragging = true;
                    });
                  },
                  onVerticalDragUpdate: (details) {
                    final RenderBox? renderBox = _sheetKey.currentContext?.findRenderObject() as RenderBox?;
                    if (renderBox != null) {
                      _sheetHeight = renderBox.size.height;
                    }
                    double maxOffset = _sheetHeight - 84.0;
                    if (maxOffset < 200.0) maxOffset = 320.0;

                    setState(() {
                      sheetOffset += details.primaryDelta!;
                      if (sheetOffset < 0) sheetOffset = 0;
                      if (sheetOffset > maxOffset) sheetOffset = maxOffset;
                    });
                  },
                  onVerticalDragEnd: (details) {
                    final RenderBox? renderBox = _sheetKey.currentContext?.findRenderObject() as RenderBox?;
                    if (renderBox != null) {
                      _sheetHeight = renderBox.size.height;
                    }
                    double maxOffset = _sheetHeight - 84.0;
                    if (maxOffset < 200.0) maxOffset = 320.0;

                    setState(() {
                      isDragging = false;
                      if (sheetOffset > maxOffset / 2 || (details.primaryVelocity ?? 0) > 300) {
                        sheetOffset = maxOffset;
                      } else {
                        sheetOffset = 0;
                      }
                    });
                  },
                  child: AnimatedContainer(
                    key: _sheetKey,
                    duration: Duration(milliseconds: isDragging ? 0 : 250),
                    curve: Curves.easeOutQuart,
                    transform: Matrix4.translationValues(0, sheetOffset, 0),
                    decoration: BoxDecoration(
                      color: isDarkMode ? AppThemeData.surface50Dark : Colors.white,
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(24),
                        topRight: Radius.circular(24),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.12),
                          blurRadius: 20,
                          offset: const Offset(0, -6),
                        )
                      ],
                    ),
                    padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Drag Handle
                        Center(
                          child: Container(
                            width: 48,
                            height: 5,
                            margin: const EdgeInsets.only(bottom: 12),
                            decoration: BoxDecoration(
                              color: isDarkMode ? Colors.grey[800] : Colors.grey[300],
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                        ),
                        isPickingOnMap
                            ? buildMapPickingPanel()
                            : buildUnifiedBookingPanel(controller, isDarkMode),
                      ],
                    ),
                  ),
                ),
              ),

              // UPI Simulation Overlay
              if (isSimulatingUPI)
                Positioned.fill(
                  child: Container(
                    color: Colors.black.withValues(alpha: 0.7),
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

Widget buildTopAddressCard(HomeController controller, bool isDarkMode) {
  final textColor = isDarkMode ? AppThemeData.grey900Dark : AppThemeData.grey900;

  return Container(
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
    decoration: BoxDecoration(
      color: isDarkMode ? AppThemeData.surface50Dark : Colors.white,
      borderRadius: BorderRadius.circular(16),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.08),
          blurRadius: 12,
          offset: const Offset(0, 3),
        )
      ],
    ),
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Ultra-compact Header Row
        Row(
          children: [
            InkWell(
              onTap: () => Get.back(),
              child: const Padding(
                padding: EdgeInsets.all(4.0),
                child: Icon(Icons.arrow_back_ios_new, size: 16),
              ),
            ),
            const SizedBox(width: 8),
            Text(
              "Book Your Ride".tr,
              style: TextStyle(
                fontFamily: AppThemeData.bold,
                fontSize: 15,
                color: textColor,
              ),
            ),
            const Spacer(),
            InkWell(
              onTap: () {
                if (!Preferences.getBoolean(Preferences.isLogin)) {
                  Get.to(() => const PhoneEntryScreen(), transition: Transition.rightToLeftWithFade);
                  return;
                }
                Get.to(() => NewRideScreen(), transition: Transition.rightToLeftWithFade);
              },
              child: const Padding(
                padding: EdgeInsets.all(4.0),
                child: Icon(Icons.history, size: 20),
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),

        // Compact Address Box
        Row(
          children: [
            // Left Pin/Line Visual
            Column(
              children: [
                const Icon(Icons.circle, color: Colors.green, size: 10),
                Container(width: 1, height: 20, color: Colors.grey.shade300),
                const Icon(Icons.circle, color: Colors.red, size: 10),
              ],
            ),
            const SizedBox(width: 10),

            // Input Labels
            Expanded(
              child: Column(
                children: [
                  InkWell(
                    onTap: () => selectSearchLocation(false),
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 2),
                      child: isDetectingLocation && controller.departureController.text.isEmpty
                          ? Row(
                              children: [
                                SizedBox(
                                  width: 12,
                                  height: 12,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: AppThemeData.primary200,
                                  ),
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  "Detecting pickup location...".tr,
                                  style: TextStyle(
                                    fontFamily: AppThemeData.medium,
                                    fontSize: 13,
                                    color: AppThemeData.primary200,
                                  ),
                                ),
                              ],
                            )
                          : Text(
                              controller.departureController.text.isNotEmpty
                                  ? controller.departureController.text
                                  : "Enter Pickup Location".tr,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontFamily: AppThemeData.medium,
                                fontSize: 13,
                                color: controller.departureController.text.isNotEmpty ? textColor : Colors.grey,
                              ),
                            ),
                    ),
                  ),
                  const Divider(height: 8, thickness: 0.8),
                  InkWell(
                    onTap: () => selectSearchLocation(true),
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 2),
                      child: Text(
                        controller.destinationController.text.isNotEmpty
                            ? controller.destinationController.text
                            : "Where to go?".tr,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontFamily: AppThemeData.medium,
                          fontSize: 13,
                          color: controller.destinationController.text.isNotEmpty ? textColor : Colors.grey,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Swap Button
            IconButton(
              visualDensity: VisualDensity.compact,
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
              icon: Icon(Icons.swap_vert_rounded, color: AppThemeData.primary200, size: 22),
              onPressed: () {
                final tempText = controller.departureController.text;
                final tempLatLng = controller.departureLatLong.value;
                controller.departureController.text = controller.destinationController.text;
                controller.departureLatLong.value = controller.destinationLatLong.value;
                controller.destinationController.text = tempText;
                controller.destinationLatLong.value = tempLatLng;
                if (controller.departureController.text.isNotEmpty &&
                    controller.destinationController.text.isNotEmpty) {
                  setState(() { isLocationSelected = true; });
                  controller.getDirections();
                  fetchVehicleCategories();
                } else {
                  setState(() { isLocationSelected = false; });
                }
              },
            ),
          ],
        ),
        const SizedBox(height: 6),

        // Inline Location Links
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            InkWell(
              onTap: () => autoDetectPickupLocation(userTriggered: true),
              child: Row(
                children: [
                  Icon(Icons.my_location_rounded, size: 14, color: AppThemeData.primary200),
                  const SizedBox(width: 4),
                  Text("Current GPS".tr, style: TextStyle(fontSize: 11, color: AppThemeData.primary200, fontWeight: FontWeight.w600)),
                ],
              ),
            ),
            Container(height: 10, width: 1, color: Colors.grey.shade300),
            InkWell(
              onTap: () => startMapPicking(false),
              child: Row(
                children: [
                  const Icon(Icons.map_outlined, size: 14, color: Colors.blue),
                  const SizedBox(width: 4),
                  Text("Pick Pickup".tr, style: const TextStyle(fontSize: 11, color: Colors.blue)),
                ],
              ),
            ),
            Container(height: 10, width: 1, color: Colors.grey.shade300),
            InkWell(
              onTap: () => startMapPicking(true),
              child: Row(
                children: [
                  const Icon(Icons.pin_drop_outlined, size: 14, color: Colors.blue),
                  const SizedBox(width: 4),
                  Text("Pick Drop".tr, style: const TextStyle(fontSize: 11, color: Colors.blue)),
                ],
              ),
            ),
          ],
        ),
      ],
    ),
  );
}
Widget buildUnifiedBookingPanel(HomeController controller, bool isDarkMode) {
  final allCategories = vehicleCategoryModel?.data ?? [];
  final displayedCategories = allCategories.where((cat) {
    final name = cat.libelle?.toLowerCase() ?? '';
    final isLogistics = name.contains('truck') || name.contains('delivery') ||
        name.contains('goods') || name.contains('logistics') ||
        name.contains('cargo');
    return selectedTabIndex == 1 ? isLogistics : !isLogistics;
  }).toList();

  if (selectedTabIndex == 1 && displayedCategories.isEmpty) {
    displayedCategories.add(VehicleData(
      id: "-99",
      libelle: "Cargo Truck",
      image: "https://cdn-icons-png.flaticon.com/512/2769/2769339.png",
      prix: "25.0",
    ));
  }

  double distanceVal = double.tryParse(controller.distance.value.toString()) ??
      0.0;
  double tripPrice = selectedVehicle != null ? calculateRidePrice(
      selectedVehicle!, distanceVal) : 0.0;

  // Set maximum panel height to 50% of the screen height
  final maxPanelHeight = MediaQuery
      .of(context)
      .size
      .height * 0.50;

  return Container(
    constraints: BoxConstraints(maxHeight: maxPanelHeight),
    child: Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Tab Bar Selector
        Row(
          children: [
            Expanded(
              child: InkWell(
                onTap: () {
                  setState(() {
                    selectedTabIndex = 0;
                    selectedVehicle = null;
                    nearbyDrivers = null;
                  });
                },
                child: Column(
                  children: [
                    Text(
                      "Ride Services".tr,
                      style: TextStyle(
                        fontFamily: AppThemeData.semiBold,
                        fontSize: 13,
                        color: selectedTabIndex == 0
                            ? AppThemeData.primary200
                            : (isDarkMode
                            ? AppThemeData.grey500Dark
                            : AppThemeData.grey500),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Container(
                      height: 2,
                      color: selectedTabIndex == 0
                          ? AppThemeData.primary200
                          : Colors.transparent,
                    ),
                  ],
                ),
              ),
            ),
            Expanded(
              child: InkWell(
                onTap: () {
                  setState(() {
                    selectedTabIndex = 1;
                    selectedVehicle = null;
                    nearbyDrivers = null;
                  });
                },
                child: Column(
                  children: [
                    Text(
                      "Logistics & Delivery".tr,
                      style: TextStyle(
                        fontFamily: AppThemeData.semiBold,
                        fontSize: 13,
                        color: selectedTabIndex == 1
                            ? AppThemeData.primary200
                            : (isDarkMode
                            ? AppThemeData.grey500Dark
                            : AppThemeData.grey500),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Container(
                      height: 2,
                      color: selectedTabIndex == 1
                          ? AppThemeData.primary200
                          : Colors.transparent,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),

        // Scrollable Vehicle Category List (bounded height)
        Expanded(
          child: vehicleCategoryModel == null
              ? const Center(child: CircularProgressIndicator())
              : displayedCategories.isEmpty
              ? Center(
            child: Text(
              "No services available under this category.".tr,
              style: const TextStyle(color: Colors.grey, fontSize: 12),
            ),
          )
              : ListView.separated(
            shrinkWrap: true,
            physics: const AlwaysScrollableScrollPhysics(),
            itemCount: displayedCategories.length,
            separatorBuilder: (context, index) => const SizedBox(height: 6),
            itemBuilder: (context, index) {
              final category = displayedCategories[index];
              final isSelected = selectedVehicle?.id == category.id;
              double calculatedPrice = calculateRidePrice(
                  category, distanceVal);

              return InkWell(
                onTap: () {
                  setState(() => selectedVehicle = category);
                  if (isLocationSelected) fetchNearbyDrivers();
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 8),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? AppThemeData.primary200.withValues(alpha: 0.08)
                        : (isDarkMode ? AppThemeData.grey800 : Colors.white),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isSelected ? AppThemeData.primary200 : Colors.grey
                          .withValues(alpha: 0.15),
                      width: 1.2,
                    ),
                  ),
                  child: Row(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(6),
                        child: CachedNetworkImage(
                          imageUrl: category.image.toString(),
                          width: 32,
                          height: 32,
                          fit: BoxFit.cover,
                          placeholder: (context, url) =>
                          const Icon(Icons.directions_car, size: 20),
                          errorWidget: (context, url, error) =>
                          const Icon(Icons.directions_car, size: 20),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Text(
                                  category.libelle.toString(),
                                  style: TextStyle(
                                    fontFamily: AppThemeData.semiBold,
                                    fontSize: 13,
                                    color: isDarkMode
                                        ? AppThemeData.grey900Dark
                                        : AppThemeData.grey900,
                                  ),
                                ),
                                if (isSelected &&
                                    nearbyDrivers?.data?.isNotEmpty ==
                                        true) ...[
                                  const SizedBox(width: 6),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 5, vertical: 1),
                                    decoration: BoxDecoration(
                                      color: AppThemeData.primary200.withValues(
                                          alpha: 0.12),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Text(
                                      '${nearbyDrivers!.data!.length} nearby',
                                      style: TextStyle(
                                        fontFamily: AppThemeData.medium,
                                        fontSize: 9,
                                        color: AppThemeData.primary200,
                                      ),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                            Text(
                              isLocationSelected ? "${controller.duration
                                  .value} away" : "Select route to see time".tr,
                              style: TextStyle(
                                fontFamily: AppThemeData.regular,
                                fontSize: 10,
                                color: isDarkMode
                                    ? AppThemeData.grey500Dark
                                    : AppThemeData.grey500,
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (isLocationSelected) ...[
                        Text(
                          "${controller.distance.value.toStringAsFixed(
                              1)} ${Constant.distanceUnit ?? 'KM'}",
                          style: TextStyle(
                            fontFamily: AppThemeData.medium,
                            fontSize: 11,
                            color: isDarkMode
                                ? AppThemeData.grey500Dark
                                : AppThemeData.grey500,
                          ),
                        ),
                        const SizedBox(width: 6),
                      ],
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            isLocationSelected ? Constant().amountShow(
                                amount: calculatedPrice.toString()) : "---",
                            style: TextStyle(
                              fontFamily: AppThemeData.bold,
                              fontSize: 13,
                              color: isDarkMode
                                  ? AppThemeData.grey900Dark
                                  : AppThemeData.grey900,
                            ),
                          ),
                          Icon(
                            isSelected
                                ? Icons.radio_button_checked_rounded
                                : Icons.radio_button_off_rounded,
                            color: isSelected ? AppThemeData.primary200 : Colors
                                .grey,
                            size: 16,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 8),

        // Compact Payment Method Selector
        if (selectedVehicle != null) ...[
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: isDarkMode ? AppThemeData.grey100Dark : Colors.grey.shade50,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey.withValues(alpha: 0.1)),
            ),
            child: Row(
              children: [
                Icon(Icons.account_balance_wallet_outlined,
                    color: AppThemeData.primary200, size: 18),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    selectedPaymentMethod == "wallet"
                        ? "Wallet Balance (₹1,250)".tr
                        : selectedPaymentMethod == "upi"
                        ? "UPI Payment".tr
                        : "Cash Payment".tr,
                    style: TextStyle(
                      fontFamily: AppThemeData.semiBold,
                      fontSize: 12,
                      color: isDarkMode ? AppThemeData.grey900Dark : AppThemeData.grey900,
                    ),
                  ),
                ),
                DropdownButton<String>(
                  value: selectedPaymentMethod,
                  underline: const SizedBox(),
                  isDense: true,
                  icon: const Icon(Icons.keyboard_arrow_down_rounded, size: 18),
                  items: [
                    DropdownMenuItem(value: "cash", child: Text("Cash".tr, style: const TextStyle(fontSize: 12))),
                    DropdownMenuItem(value: "wallet", child: Text("Wallet".tr, style: const TextStyle(fontSize: 12))),
                    DropdownMenuItem(value: "upi", child: Text("UPI".tr, style: const TextStyle(fontSize: 12))),
                  ],
                  onChanged: (val) {
                    if (val != null) setState(() => selectedPaymentMethod = val);
                  },
                )
              ],
            ),
          ),
          const SizedBox(height: 8),
        ],

        // Footer Fare & Action Button
        if (!isLocationSelected)
          Text(
            "Please select pickup & drop locations above to continue.".tr,
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.grey, fontSize: 11),
          )
        else if (selectedVehicle == null)
          Container(
            padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 14),
            decoration: BoxDecoration(
              color: isDarkMode ? AppThemeData.grey800 : Colors.grey.shade100,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.touch_app_outlined, size: 18, color: AppThemeData.primary200),
                const SizedBox(width: 8),
                Text(
                  "Select a vehicle above to see fare & book ride".tr,
                  style: TextStyle(
                    fontFamily: AppThemeData.medium,
                    fontSize: 12,
                    color: isDarkMode ? AppThemeData.grey500Dark : AppThemeData.grey500,
                  ),
                ),
              ],
            ),
          )
        else if (isLoadingDrivers)
          Container(
            padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 14),
            decoration: BoxDecoration(
              color: isDarkMode ? AppThemeData.grey800 : Colors.grey.shade100,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const SizedBox(
                  width: 14,
                  height: 14,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
                const SizedBox(width: 10),
                Text(
                  "Checking nearby ${selectedVehicle!.libelle} drivers...".tr,
                  style: TextStyle(
                    fontFamily: AppThemeData.medium,
                    fontSize: 12,
                    color: isDarkMode ? AppThemeData.grey500Dark : AppThemeData.grey500,
                  ),
                ),
              ],
            ),
          )
        else if (nearbyDrivers?.data == null || nearbyDrivers!.data!.isEmpty)
          Container(
            padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 14),
            decoration: BoxDecoration(
              color: const Color(0xFFFEF2F2),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFFCA5A5)),
            ),
            child: Row(
              children: [
                const Icon(Icons.info_outline, size: 18, color: Color(0xFFDC2626)),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    "No ${selectedVehicle!.libelle} drivers online nearby right now.".tr,
                    style: const TextStyle(
                      color: Color(0xFF991B1B),
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          )
        else
          Row(
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Total Fare".tr,
                    style: TextStyle(
                      fontFamily: AppThemeData.regular,
                      fontSize: 11,
                      color: isDarkMode
                          ? AppThemeData.grey500Dark
                          : AppThemeData.grey500,
                    ),
                  ),
                  Text(
                    Constant().amountShow(amount: tripPrice.toString()),
                    style: TextStyle(
                      fontFamily: AppThemeData.bold,
                      fontSize: 18,
                      color: isDarkMode
                          ? AppThemeData.grey900Dark
                          : AppThemeData.grey900,
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF10B981),
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: isBookingInProgress ? null : executeBooking,
                  child: isBookingInProgress
                      ? const SizedBox(
                    height: 16,
                    width: 16,
                    child: CircularProgressIndicator(
                        color: Colors.white, strokeWidth: 2),
                  )
                      : Text(
                    "Confirm & Continue".tr,
                    style: const TextStyle(color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 14),
                  ),
                ),
              ),
            ],
          ),
      ],
    ),
  );
}
}
