import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:flutter_osm_plugin/flutter_osm_plugin.dart' show SearchInfo;

import 'package:finway/constant/constant.dart';
import 'package:finway/constant/show_toast_dialog.dart';
import 'package:finway/controller/home_controller.dart';
import 'package:finway/controller/wallet_controller.dart';
import 'package:finway/model/vehicle_category_model.dart';
import 'package:finway/model/ride_model.dart';
import 'package:finway/page/completed_ride_screens/trip_history_screen.dart';
import 'package:finway/page/new_ride_screens/searching_driver_screen.dart';
import 'package:finway/page/search_location_screen.dart';
import 'package:finway/themes/button_them.dart';
import 'package:finway/themes/constant_colors.dart';
import 'package:finway/utils/Preferences.dart';
import 'package:finway/utils/dark_theme_provider.dart';
import 'package:finway/utils/location_picker_helper.dart';

class TransportBookingScreen extends StatefulWidget {
  final String? initialVehicleLibelle;
  const TransportBookingScreen({super.key, this.initialVehicleLibelle});

  @override
  State<TransportBookingScreen> createState() => _TransportBookingScreenState();
}

class _TransportBookingScreenState extends State<TransportBookingScreen> {
  // Matches the reference "Book Your Transport" mockup's green branding for this
  // logistics flow (distinct from the app's default blue AppThemeData.primary200).
  static const Color _accent = Color(0xFF2E7D32);
  static const Color _dropPin = Color(0xFF1976D2);

  // Only these 4 truck-type categories belong on this dedicated screen —
  // everything else tj_type_vehicule returns (Bike/Sedan/SUV/...) is for the Cab flow.
  static const List<String> _allowedCategories = ['Mini Truck', 'Pickup', 'Medium Truck', 'Large Truck'];

  static const Map<String, String> _capacityLabel = {
    'Mini Truck': 'Up to 500 kg',
    'Pickup': 'Up to 1 Ton',
    'Medium Truck': 'Up to 3 Ton',
    'Large Truck': '3 Ton & Above',
  };

  static const List<String> _goodsTypes = [
    'Furniture',
    'Electronics',
    'Construction Material',
    'Household Items',
    'Other',
  ];

  final noteController = TextEditingController();

  bool isLoadingCategories = true;
  List<VehicleData> categories = [];
  VehicleData? selectedVehicle;

  String goodsType = _goodsTypes.first;
  String selectedPaymentMethod = 'wallet'; // cash, wallet
  bool isBookingInProgress = false;

  @override
  void initState() {
    super.initState();
    // This screen can be reached directly from the Logistics section without
    // first visiting the Home tab, which is where HomeController normally gets
    // registered — so register it here too if it isn't already.
    if (!Get.isRegistered<HomeController>()) {
      Get.put(HomeController());
    }
    Get.put(WalletController()).getAmount();
    fetchVehicleCategories();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      autoDetectPickupLocation();
    });
  }

  Future<void> autoDetectPickupLocation() async {
    final homeCtrl = Get.find<HomeController>();
    if (homeCtrl.departureController.text.trim().isNotEmpty &&
        homeCtrl.departureLatLong.value.latitude != 0.0) {
      return;
    }

    try {
      final loc = await LocationPickerHelper.fetchCurrentLocation(
        context: context,
        showLoader: false,
        showPromptDialog: true,
      );
      if (loc != null && mounted) {
        setState(() {
          homeCtrl.departureLatLong.value = LatLng(loc.latitude, loc.longitude);
          homeCtrl.departureController.text = loc.address;
          homeCtrl.currentLocationController.text = loc.address;
        });
        if (homeCtrl.destinationController.text.trim().isNotEmpty) {
          homeCtrl.getDirections();
        }
      }
    } catch (_) {}
  }

  @override
  void dispose() {
    noteController.dispose();
    super.dispose();
  }

  Future<void> fetchVehicleCategories() async {
    setState(() => isLoadingCategories = true);
    try {
      final homeCtrl = Get.find<HomeController>();
      final result = await homeCtrl.getVehicleCategory();
      final filtered = (result?.data ?? [])
          .where((cat) => _allowedCategories.contains(cat.libelle))
          .toList()
        ..sort((a, b) => _allowedCategories.indexOf(a.libelle ?? '').compareTo(_allowedCategories.indexOf(b.libelle ?? '')));

      if (mounted) {
        setState(() {
          categories = filtered;
          if (selectedVehicle == null || !filtered.any((c) => c.id == selectedVehicle!.id)) {
            if (widget.initialVehicleLibelle != null) {
              selectedVehicle = filtered.firstWhere(
                (c) => c.libelle == widget.initialVehicleLibelle,
                orElse: () => filtered.isNotEmpty ? filtered.first : VehicleData(),
              );
              if (selectedVehicle!.id == null) selectedVehicle = filtered.isNotEmpty ? filtered.first : null;
            } else {
              selectedVehicle = filtered.isNotEmpty ? filtered.first : null;
            }
          }
          isLoadingCategories = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => isLoadingCategories = false);
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
      } else {
        homeCtrl.departureLatLong.value = LatLng(lat, lng);
        homeCtrl.departureController.text = addr;
      }

      setState(() {});

      if (homeCtrl.departureController.text.isNotEmpty && homeCtrl.destinationController.text.isNotEmpty) {
        homeCtrl.getDirections();
        fetchVehicleCategories();
      }
    }
  }

  void clearLocation(bool isDrop) {
    final homeCtrl = Get.find<HomeController>();
    setState(() {
      if (isDrop) {
        homeCtrl.destinationController.clear();
        homeCtrl.destinationLatLong.value = const LatLng(0.0, 0.0);
      } else {
        homeCtrl.departureController.clear();
        homeCtrl.departureLatLong.value = const LatLng(0.0, 0.0);
      }
    });
  }

  void swapLocations() {
    final homeCtrl = Get.find<HomeController>();
    final tempText = homeCtrl.departureController.text;
    final tempLatLong = homeCtrl.departureLatLong.value;
    setState(() {
      homeCtrl.departureController.text = homeCtrl.destinationController.text;
      homeCtrl.departureLatLong.value = homeCtrl.destinationLatLong.value;
      homeCtrl.destinationController.text = tempText;
      homeCtrl.destinationLatLong.value = tempLatLong;
    });
    if (homeCtrl.departureController.text.isNotEmpty && homeCtrl.destinationController.text.isNotEmpty) {
      homeCtrl.getDirections();
      fetchVehicleCategories();
    }
  }

  // Same base + per-km formula used by the standard ride-booking flow (TexiHomeScreen),
  // kept identical so fares stay consistent across both booking screens.
  double calculateRidePrice(VehicleData category, double distanceVal) {
    double? basePrice = double.tryParse(category.basePrice ?? '');
    double? perKmPrice = double.tryParse(category.perKmPrice ?? '');

    if (basePrice != null || perKmPrice != null) {
      double base = basePrice ?? 0.0;
      double perKm = perKmPrice ?? 0.0;
      return base + (distanceVal * perKm);
    }

    double prix = double.tryParse(category.prix ?? '0.0') ?? 0.0;
    double price = prix * (distanceVal > 0.0 ? distanceVal : 1.0);
    return price < 1.0 ? prix : price;
  }

  Future<void> executeBooking() async {
    if (isBookingInProgress) return;
    final homeCtrl = Get.find<HomeController>();

    if (selectedVehicle == null) {
      ShowToastDialog.showToast("Please select a vehicle".tr);
      return;
    }
    if (homeCtrl.departureLatLong.value.latitude == 0.0 || homeCtrl.destinationLatLong.value.latitude == 0.0) {
      ShowToastDialog.showToast("Please set pickup and drop location".tr);
      return;
    }

    setState(() => isBookingInProgress = true);

    try {
      double totalCout = calculateRidePrice(selectedVehicle!, homeCtrl.distance.value);

      String paymentMethodId;
      if (selectedPaymentMethod == 'wallet') {
        paymentMethodId = homeCtrl.paymentSettingModel.value.myWallet?.idPaymentMethod?.toString() ?? "2";
      } else {
        paymentMethodId = homeCtrl.paymentSettingModel.value.cash?.idPaymentMethod?.toString() ?? "1";
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
        'id_conducteur': '0',
        'id_payment': paymentMethodId,
        'id_type_vehicule': selectedVehicle!.id.toString(),
        'depart_name': homeCtrl.departureController.text,
        'destination_name': homeCtrl.destinationController.text,
        'stops': [],
        'place': goodsType,
        'number_poeple': '1',
        'image': '',
        'image_name': "",
        'statut_round': 'no',
        'trip_objective': noteController.text,
        'age_children1': '',
        'age_children2': '',
        'age_children3': '',
      };

      final value = await homeCtrl.bookRide(bodyParams);
      if (mounted) setState(() => isBookingInProgress = false);

      if (value != null && value['success'] == "success") {
        Get.offAll(() => const SearchingDriverScreen(), arguments: {
          'rideData': RideData.fromJson(value['data']),
          'bookingBodyParams': bodyParams,
        });
      } else {
        ShowToastDialog.showToast(value != null ? value['error'] : "Booking failed".tr);
      }
    } catch (e) {
      if (mounted) setState(() => isBookingInProgress = false);
      ShowToastDialog.showToast("An error occurred: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeChange = Provider.of<DarkThemeProvider>(context);
    final bool isDarkMode = themeChange.getThem();
    final homeCtrl = Get.find<HomeController>();
    final walletCtrl = Get.find<WalletController>();

    return Obx(() {
      final distance = homeCtrl.distance.value;
      final totalFare = selectedVehicle != null ? calculateRidePrice(selectedVehicle!, distance) : 0.0;
      final baseFare = double.tryParse(selectedVehicle?.basePrice ?? '') ?? 0.0;
      final distanceFare = totalFare - baseFare;

      return Scaffold(
        backgroundColor: isDarkMode ? AppThemeData.surface50Dark : const Color(0xFFF7F8FA),
        appBar: AppBar(
          backgroundColor: isDarkMode ? AppThemeData.surface50Dark : Colors.white,
          elevation: 0,
          iconTheme: IconThemeData(color: isDarkMode ? AppThemeData.grey900Dark : Colors.black),
          title: Text(
            "Book Your Transport".tr,
            style: TextStyle(
              fontFamily: AppThemeData.bold,
              fontSize: 18,
              color: isDarkMode ? AppThemeData.grey900Dark : Colors.black,
            ),
          ),
          actions: [
            IconButton(
              onPressed: () => Get.to(() => TripHistoryScreen()),
              icon: Icon(Icons.history_rounded, color: isDarkMode ? AppThemeData.grey900Dark : Colors.black),
            ),
          ],
        ),
        body: SafeArea(
          child: Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildLocationCard(isDarkMode, homeCtrl),
                      const SizedBox(height: 14),
                      Row(
                        children: [
                          _mapPickButton(
                            icon: Icons.location_on_outlined,
                            label: "Pick on Map".tr,
                            onTap: () => selectSearchLocation(false),
                          ),
                          const SizedBox(width: 28),
                          _mapPickButton(
                            icon: Icons.map_outlined,
                            label: "Drop on Map".tr,
                            onTap: () => selectSearchLocation(true),
                          ),
                        ],
                      ),
                      const SizedBox(height: 22),
                      Text(
                        "Choose Vehicle".tr,
                        style: TextStyle(
                          fontFamily: AppThemeData.bold,
                          fontSize: 16,
                          color: isDarkMode ? AppThemeData.grey900Dark : AppThemeData.grey900,
                        ),
                      ),
                      const SizedBox(height: 12),
                      isLoadingCategories
                          ? const Center(child: Padding(padding: EdgeInsets.all(20), child: CircularProgressIndicator()))
                          : categories.isEmpty
                              ? Padding(
                                  padding: const EdgeInsets.symmetric(vertical: 20),
                                  child: Text("No vehicle categories available".tr, style: TextStyle(color: AppThemeData.grey500)),
                                )
                              : _buildVehicleRow(isDarkMode, distance),
                      const SizedBox(height: 22),
                      Text(
                        "Goods Details".tr,
                        style: TextStyle(
                          fontFamily: AppThemeData.bold,
                          fontSize: 16,
                          color: isDarkMode ? AppThemeData.grey900Dark : AppThemeData.grey900,
                        ),
                      ),
                      const SizedBox(height: 12),
                      IntrinsicHeight(
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(child: _buildGoodsDetails(isDarkMode)),
                            const SizedBox(width: 12),
                            Expanded(child: _buildFareSummary(isDarkMode, baseFare, distanceFare, distance, totalFare)),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),
                      _buildPaymentMethod(isDarkMode, walletCtrl),
                      const SizedBox(height: 20),
                    ],
                  ),
                ),
              ),
              _buildBottomBar(isDarkMode, totalFare),
            ],
          ),
        ),
      );
    });
  }

  Widget _mapPickButton({required IconData icon, required String label, required VoidCallback onTap}) {
    return InkWell(
      onTap: onTap,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: _accent, size: 18),
          const SizedBox(width: 6),
          Text(label, style: const TextStyle(color: _accent, fontFamily: 'Switzer-Medium', fontSize: 13)),
        ],
      ),
    );
  }

  Widget _buildLocationCard(bool isDarkMode, HomeController homeCtrl) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDarkMode ? AppThemeData.grey100Dark : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.withValues(alpha: 0.15)),
      ),
      child: Column(
        children: [
          _buildLocationRow(
            isDarkMode: isDarkMode,
            icon: Icon(Icons.radio_button_checked_rounded, color: _accent, size: 16),
            label: "Pickup Location".tr,
            value: homeCtrl.departureController.text,
            onTap: () => selectSearchLocation(false),
            onClear: homeCtrl.departureController.text.isNotEmpty ? () => clearLocation(false) : null,
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 7),
            child: Row(
              children: [
                SizedBox(
                  width: 6,
                  child: Column(
                    children: List.generate(3, (_) => Padding(
                      padding: const EdgeInsets.symmetric(vertical: 1.5),
                      child: Container(width: 2, height: 2, color: Colors.grey.withValues(alpha: 0.4)),
                    )),
                  ),
                ),
                const Spacer(),
                InkWell(
                  onTap: swapLocations,
                  borderRadius: BorderRadius.circular(20),
                  child: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white,
                      border: Border.all(color: Colors.grey.withValues(alpha: 0.3)),
                    ),
                    child: const Icon(Icons.swap_vert_rounded, size: 16, color: Colors.black54),
                  ),
                ),
              ],
            ),
          ),
          _buildLocationRow(
            isDarkMode: isDarkMode,
            icon: const Icon(Icons.location_on, color: _dropPin, size: 20),
            label: "Drop Location".tr,
            value: homeCtrl.destinationController.text,
            onTap: () => selectSearchLocation(true),
            onClear: homeCtrl.destinationController.text.isNotEmpty ? () => clearLocation(true) : null,
          ),
        ],
      ),
    );
  }

  Widget _buildLocationRow({
    required bool isDarkMode,
    required Widget icon,
    required String label,
    required String value,
    required VoidCallback onTap,
    VoidCallback? onClear,
  }) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(
          children: [
            SizedBox(width: 20, child: icon),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: TextStyle(
                      fontFamily: AppThemeData.medium,
                      fontSize: 12,
                      color: isDarkMode ? AppThemeData.grey500Dark : AppThemeData.grey500,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    value.isEmpty ? "Select location".tr : value,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontFamily: AppThemeData.semiBold,
                      fontSize: 14,
                      color: value.isEmpty
                          ? AppThemeData.grey400
                          : (isDarkMode ? AppThemeData.grey900Dark : AppThemeData.grey900),
                    ),
                  ),
                ],
              ),
            ),
            if (onClear != null)
              IconButton(
                onPressed: onClear,
                icon: const Icon(Icons.close_rounded, size: 18),
                color: Colors.black45,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildVehicleRow(bool isDarkMode, double distance) {
    return Row(
      children: categories.map((cat) {
        final isSelected = selectedVehicle?.id == cat.id;
        final fare = calculateRidePrice(cat, distance);
        return Expanded(
          child: Padding(
            padding: EdgeInsets.only(right: cat == categories.last ? 0 : 8),
            child: InkWell(
              borderRadius: BorderRadius.circular(12),
              onTap: () => setState(() => selectedVehicle = cat),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
                decoration: BoxDecoration(
                  color: isDarkMode ? AppThemeData.grey100Dark : Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isSelected ? _accent : Colors.grey.withValues(alpha: 0.2),
                    width: isSelected ? 1.5 : 1,
                  ),
                ),
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SizedBox(
                          height: 28,
                          width: 34,
                          child: CachedNetworkImage(
                            imageUrl: cat.image ?? '',
                            fit: BoxFit.contain,
                            placeholder: (context, url) => const Icon(Icons.local_shipping_outlined, size: 24, color: Colors.grey),
                            errorWidget: (context, url, error) => const Icon(Icons.local_shipping_outlined, size: 24, color: Colors.grey),
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          cat.libelle ?? '',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontFamily: AppThemeData.semiBold,
                            fontSize: 11.5,
                            color: isDarkMode ? AppThemeData.grey900Dark : AppThemeData.grey900,
                          ),
                        ),
                        const SizedBox(height: 1),
                        Text(
                          _capacityLabel[cat.libelle] ?? '',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontFamily: AppThemeData.regular,
                            fontSize: 9.5,
                            color: isDarkMode ? AppThemeData.grey500Dark : AppThemeData.grey500,
                          ),
                        ),
                        const SizedBox(height: 5),
                        Text(
                          "${Constant().amountShow(amount: fare.toStringAsFixed(0))} +",
                          style: const TextStyle(fontFamily: 'Switzer-Bold', fontSize: 12, color: _accent),
                        ),
                      ],
                    ),
                    if (isSelected)
                      Positioned(
                        top: -4,
                        right: -4,
                        child: Container(
                          width: 16,
                          height: 16,
                          decoration: const BoxDecoration(shape: BoxShape.circle, color: _accent),
                          child: const Icon(Icons.check, size: 11, color: Colors.white),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildGoodsDetails(bool isDarkMode) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: isDarkMode ? AppThemeData.grey100Dark : Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey.withValues(alpha: 0.2)),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: goodsType,
              isExpanded: true,
              icon: const Icon(Icons.keyboard_arrow_down_rounded, size: 20),
              style: TextStyle(
                fontFamily: AppThemeData.semiBold,
                fontSize: 13,
                color: isDarkMode ? AppThemeData.grey900Dark : AppThemeData.grey900,
              ),
              items: _goodsTypes.map((g) => DropdownMenuItem(value: g, child: Text(g))).toList(),
              onChanged: (val) {
                if (val != null) setState(() => goodsType = val);
              },
            ),
          ),
        ),
        const SizedBox(height: 10),
        Container(
          decoration: BoxDecoration(
            color: isDarkMode ? AppThemeData.grey100Dark : Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey.withValues(alpha: 0.2)),
          ),
          child: TextField(
            controller: noteController,
            maxLines: 3,
            style: TextStyle(fontSize: 13, color: isDarkMode ? AppThemeData.grey900Dark : AppThemeData.grey900),
            decoration: InputDecoration(
              hintText: "Additional Note (Optional)".tr,
              hintStyle: const TextStyle(color: Colors.grey, fontSize: 12),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.all(12),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildFareSummary(bool isDarkMode, double baseFare, double distanceFare, double distance, double totalFare) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDarkMode ? AppThemeData.grey100Dark : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Fare Summary".tr,
            style: TextStyle(
              fontFamily: AppThemeData.semiBold,
              fontSize: 13,
              color: isDarkMode ? AppThemeData.grey900Dark : AppThemeData.grey900,
            ),
          ),
          const SizedBox(height: 10),
          _fareRow("Base Fare".tr, Constant().amountShow(amount: baseFare.toStringAsFixed(0)), isDarkMode),
          const SizedBox(height: 6),
          _fareRow(
            "Distance (${distance.toStringAsFixed(0)} ${Constant.distanceUnit})".tr,
            Constant().amountShow(amount: distanceFare.toStringAsFixed(0)),
            isDarkMode,
          ),
          const SizedBox(height: 6),
          _fareRow("Loading & Handling".tr, Constant().amountShow(amount: '0'), isDarkMode),
          const Padding(padding: EdgeInsets.symmetric(vertical: 8), child: Divider(height: 1)),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text("Total Fare".tr, style: TextStyle(fontFamily: AppThemeData.bold, fontSize: 13, color: isDarkMode ? AppThemeData.grey900Dark : AppThemeData.grey900)),
              Text(
                Constant().amountShow(amount: totalFare.toStringAsFixed(0)),
                style: const TextStyle(fontFamily: 'Switzer-Bold', fontSize: 14, color: _accent),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _fareRow(String label, String value, bool isDarkMode) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(fontFamily: AppThemeData.regular, fontSize: 11.5, color: isDarkMode ? AppThemeData.grey500Dark : AppThemeData.grey500),
          ),
        ),
        Text(value, style: TextStyle(fontFamily: AppThemeData.medium, fontSize: 11.5, color: isDarkMode ? AppThemeData.grey900Dark : AppThemeData.grey900)),
      ],
    );
  }

  Widget _buildPaymentMethod(bool isDarkMode, WalletController walletCtrl) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: isDarkMode ? AppThemeData.grey100Dark : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          Icon(
            selectedPaymentMethod == 'wallet' ? Icons.account_balance_wallet_outlined : Icons.payments_outlined,
            color: _accent,
            size: 20,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              selectedPaymentMethod == 'wallet'
                  ? "Wallet Balance".tr
                  : "Cash Payment".tr,
              style: TextStyle(fontFamily: AppThemeData.medium, fontSize: 13, color: isDarkMode ? AppThemeData.grey900Dark : AppThemeData.grey900),
            ),
          ),
          if (selectedPaymentMethod == 'wallet')
            Text(
              Constant().amountShow(amount: walletCtrl.walletAmount.value.toStringAsFixed(0)),
              style: TextStyle(fontFamily: AppThemeData.semiBold, fontSize: 13, color: isDarkMode ? AppThemeData.grey900Dark : AppThemeData.grey900),
            ),
          DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: selectedPaymentMethod,
              icon: const Icon(Icons.keyboard_arrow_down_rounded, size: 20),
              items: [
                DropdownMenuItem(value: "wallet", child: Text("Wallet".tr)),
                DropdownMenuItem(value: "cash", child: Text("Cash".tr)),
              ],
              onChanged: (val) {
                if (val != null) setState(() => selectedPaymentMethod = val);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomBar(bool isDarkMode, double totalFare) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: isDarkMode ? AppThemeData.grey100Dark : Colors.white,
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 8, offset: const Offset(0, -2))],
      ),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("Total Fare".tr, style: TextStyle(fontFamily: AppThemeData.regular, fontSize: 12, color: isDarkMode ? AppThemeData.grey500Dark : AppThemeData.grey500)),
                Text(
                  Constant().amountShow(amount: totalFare.toStringAsFixed(0)),
                  style: TextStyle(fontFamily: AppThemeData.bold, fontSize: 18, color: isDarkMode ? AppThemeData.grey900Dark : AppThemeData.grey900),
                ),
              ],
            ),
            const SizedBox(width: 16),
            Expanded(
              child: ButtonThem.buildButton(
                context,
                title: isBookingInProgress ? "Booking...".tr : "Confirm Booking".tr,
                btnColor: _accent,
                radius: 10,
                onPress: isBookingInProgress ? () {} : executeBooking,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
