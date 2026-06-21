import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:get/get.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_osm_plugin/flutter_osm_plugin.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import 'package:finway/controller/home_osm_controller.dart';
import 'package:finway/themes/constant_colors.dart';
import 'package:finway/themes/text_field_them.dart';
import 'package:finway/themes/button_them.dart';
import 'package:finway/themes/responsive.dart';
import 'package:finway/constant/constant.dart';
import 'package:finway/constant/show_toast_dialog.dart';
import 'package:finway/constant/image_constant.dart';
import 'package:finway/page/search_location_screen.dart';

class RideBookingTab extends StatefulWidget {
  final HomeOsmController controller;
  final bool isDarkMode;
  final VoidCallback onTripOptionBottomSheet;
  final VoidCallback onPendingPaymentDialog;

  const RideBookingTab({
    super.key,
    required this.controller,
    required this.isDarkMode,
    required this.onTripOptionBottomSheet,
    required this.onPendingPaymentDialog,
  });

  @override
  State<RideBookingTab> createState() => _RideBookingTabState();
}

class _RideBookingTabState extends State<RideBookingTab> {
  @override
  Widget build(BuildContext context) {
    return SizedBox(
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: Constant.homeScreenType == 'OlaHome' ? 0 : 16),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 20),
              Text(
                "Enter Destination".tr,
                style: TextStyle(
                  fontSize: 18,
                  fontFamily: AppThemeData.semiBold,
                  color: widget.isDarkMode ? AppThemeData.grey900Dark : AppThemeData.grey900,
                ),
              ),
              const SizedBox(height: 12),
              Column(
                children: [
                  // Departure Field
                  TextFieldWidget(
                    onTap: () {
                      Get.to(AddressSearchScreen())?.then((value) async {
                        if (value != null) {
                          SearchInfo place = value;
                          widget.controller.departureController.text = '';
                          await widget.controller.setDepartureMarker(place.point!);
                          widget.controller.departureController = TextEditingController(text: place.address.toString());
                        }
                      });
                    },
                    isReadOnly: true,
                    prefix: IconButton(
                        onPressed: () {},
                        icon: SvgPicture.asset(
                          'assets/icons/ic_location.svg',
                          colorFilter: ColorFilter.mode(
                            widget.isDarkMode ? AppThemeData.grey500Dark : AppThemeData.grey300Dark,
                            BlendMode.srcIn,
                          ),
                        )),
                    controller: widget.controller.departureController,
                    hintText: 'Pick Up Location'.tr,
                    suffix: IconButton(
                        onPressed: () {},
                        icon: SvgPicture.asset(
                          'assets/icons/ic_right_arrow.svg',
                          colorFilter: ColorFilter.mode(
                            widget.isDarkMode ? AppThemeData.grey300Dark : AppThemeData.grey500Dark,
                            BlendMode.srcIn,
                          ),
                        )),
                  ),
                  // Destination Field
                  TextFieldWidget(
                    onTap: () {
                      Get.to(AddressSearchScreen())?.then((value) async {
                        if (value != null) {
                          widget.controller.destinationController.text = '';
                          SearchInfo place = value;
                          await widget.controller.setDestinationMarker(place.point!);
                          widget.controller.destinationController = TextEditingController(text: place.address.toString());
                        }
                      });
                    },
                    isReadOnly: true,
                    prefix: IconButton(
                        onPressed: () {},
                        icon: SvgPicture.asset(
                          'assets/icons/ic_location.svg',
                          colorFilter: ColorFilter.mode(
                            widget.isDarkMode ? AppThemeData.grey500Dark : AppThemeData.grey300Dark,
                            BlendMode.srcIn,
                          ),
                        )),
                    controller: widget.controller.destinationController,
                    hintText: 'Where you want to go?'.tr,
                    suffix: IconButton(
                        onPressed: () {},
                        icon: SvgPicture.asset(
                          'assets/icons/ic_right_arrow.svg',
                          colorFilter: ColorFilter.mode(
                            widget.isDarkMode ? AppThemeData.grey300Dark : AppThemeData.grey500Dark,
                            BlendMode.srcIn,
                          ),
                        )),
                  ),
                  // Multi Stop List
                  ReorderableListView(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    children: <Widget>[
                      for (int index = 0; index < widget.controller.multiStopListNew.length; index += 1)
                        Container(
                          key: ValueKey(widget.controller.multiStopListNew[index]),
                          child: Column(
                            children: [
                              InkWell(
                                  onTap: () async {
                                    Get.to(AddressSearchScreen())?.then((value) {
                                      if (value != null) {
                                        SearchInfo place = value;
                                        widget.controller.multiStopListNew[index].editingController.text = place.address.toString();
                                        widget.controller.multiStopListNew[index].latitude = '${place.point?.latitude ?? '0'}';
                                        widget.controller.multiStopListNew[index].longitude = '${place.point?.longitude ?? '0'}';
                                        widget.controller.setStopMarker(place.point!, index);
                                      }
                                    });
                                  },
                                  child: Row(crossAxisAlignment: CrossAxisAlignment.center, children: [
                                    Expanded(
                                      child: TextFieldWidget(
                                        onTap: () async {
                                          Get.to(AddressSearchScreen())?.then((value) {
                                            if (value != null) {
                                              SearchInfo place = value;
                                              widget.controller.multiStopListNew[index].editingController.text = place.address.toString();
                                              widget.controller.multiStopListNew[index].latitude = '${place.point?.latitude ?? 0}';
                                              widget.controller.multiStopListNew[index].longitude = '${place.point?.longitude ?? '0'}';
                                              widget.controller.setStopMarker(place.point!, index);
                                            }
                                          });
                                        },
                                        isReadOnly: true,
                                        suffix: InkWell(
                                          onTap: () {
                                            widget.controller.removeStops(index);
                                            if (widget.controller.markers.containsKey('Stop $index')) {
                                              widget.controller.mapController.removeMarker(widget.controller.markers['Stop $index']!);
                                              widget.controller.markers.remove('Stop $index');
                                            }
                                            widget.controller.getDirections();
                                          },
                                          child: Icon(
                                            Icons.close,
                                            size: 20,
                                            color: widget.isDarkMode ? AppThemeData.grey300Dark : AppThemeData.grey500Dark,
                                          ),
                                        ),
                                        prefix: IconButton(
                                          onPressed: () {},
                                          icon: Text(
                                            String.fromCharCode(index + 65),
                                            style: TextStyle(
                                                fontSize: 16,
                                                fontFamily: AppThemeData.regular,
                                                color: widget.isDarkMode ? AppThemeData.grey500Dark : AppThemeData.grey500),
                                          ),
                                        ),
                                        hintText: "Where do you want to stop?".tr,
                                        controller: widget.controller.multiStopListNew[index].editingController,
                                      ),
                                    ),
                                  ])),
                            ],
                          ),
                        ),
                    ],
                    onReorder: (int oldIndex, int newIndex) {
                      if (oldIndex < newIndex) {
                        newIndex -= 1;
                      }
                      final AddStopModelData item = widget.controller.multiStopListNew.removeAt(oldIndex);
                      widget.controller.multiStopListNew.insert(newIndex, item);
                    },
                  ),
                  // Add Stop Field
                  TextFieldWidget(
                    textColor: AppThemeData.warning200,
                    hintColor: AppThemeData.warning200,
                    isReadOnly: true,
                    onTap: () {
                      widget.controller.addStops();
                      setState(() {});
                    },
                    prefix: IconButton(
                        onPressed: () {},
                        icon: Container(
                          height: 14,
                          width: 14,
                          color: AppThemeData.warning200,
                        )),
                    controller: widget.controller.addStop,
                    hintText: 'Add Stop'.tr,
                    suffix: IconButton(
                        onPressed: () {},
                        icon: SvgPicture.asset(
                          'assets/icons/ic_right_arrow.svg',
                          colorFilter: ColorFilter.mode(
                            widget.isDarkMode ? AppThemeData.grey300Dark : AppThemeData.grey500Dark,
                            BlendMode.srcIn,
                          ),
                        )),
                  ),
                  // Search Button
                  ButtonThem.buildButton(
                    context,
                    title: 'Search Destination'.tr,
                    onPress: () async {
                      await _handleSearchDestination();
                    },
                  ),
                  const SizedBox(height: 25),
                  // Banner List
                  ListView.builder(
                    padding: EdgeInsets.zero,
                    primary: false,
                    shrinkWrap: true,
                    itemCount: widget.controller.bannerModel.value.data?.length,
                    itemBuilder: (BuildContext context, int i) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 20),
                        child: Center(
                          child: Stack(
                            alignment: Alignment.bottomLeft,
                            children: [
                              CachedNetworkImage(
                                filterQuality: FilterQuality.high,
                                width: Responsive.width(100, context),
                                height: 180,
                                imageUrl: widget.controller.bannerModel.value.data?[i].image ?? '',
                                fit: BoxFit.fill,
                                placeholder: (context, url) => Constant.loader(context),
                                errorWidget: (context, url, error) => Image.asset(
                                  ImageConstant.logo,
                                  fit: BoxFit.cover,
                                ),
                              ),
                              Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      widget.controller.bannerModel.value.data?[i].title ?? '',
                                      maxLines: 1,
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontFamily: AppThemeData.medium,
                                        color: AppThemeData.grey50Dark,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      widget.controller.bannerModel.value.data?[i].description ?? '',
                                      maxLines: 2,
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontFamily: AppThemeData.regular,
                                        color: AppThemeData.grey50Dark,
                                      ),
                                    )
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  )
                ],
              )
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _handleSearchDestination() async {
    FocusManager.instance.primaryFocus?.unfocus();

    if (widget.controller.departureLatLong.value.latitude != 0 &&
        widget.controller.destinationLatLong.value.latitude != 0 &&
        Constant.homeScreenType != 'UberHome') {
      var data = await Constant().getDurationOsmDistance(
          LatLng(widget.controller.departureLatLong.value.latitude, widget.controller.departureLatLong.value.longitude),
          LatLng(widget.controller.destinationLatLong.value.latitude, widget.controller.destinationLatLong.value.longitude));

      widget.controller.distance.value = double.parse(data['distance'].toString());
      widget.controller.duration.value = data['duration'].toString();
      widget.controller.confirmWidgetVisible.value = true;
    }

    if (widget.controller.departureLatLong.value == GeoPoint(latitude: 0.0, longitude: 0.0)) {
      ShowToastDialog.showToast("Please Enter PickUp Address.");
    } else if (widget.controller.destinationLatLong.value == GeoPoint(latitude: 0.0, longitude: 0.0)) {
      ShowToastDialog.showToast("Please Enter Destination Address.");
    } else {
      await widget.controller.getUserPendingPayment().then((value) async {
        if (value != null) {
          if (value['success'] == "success") {
            if (value['data']['amount'] != 0) {
              widget.onPendingPaymentDialog();
            } else {
              await _proceedToTripOptions();
            }
          } else {
            await _proceedToTripOptions();
          }
        }
      });
    }
  }

  Future<void> _proceedToTripOptions() async {
    if (widget.controller.distance.value == 0.0) {
      widget.controller.distance.value = widget.controller.roadInfo.value.distance!;
      widget.controller.duration.value = Constant().getDurationByDistance(widget.controller.roadInfo.value.duration!);
      widget.controller.confirmWidgetVisible.value = false;
    }

    var dataMulti = widget.controller.multiStopListNew
        .where((stop) => stop.latitude.isNotEmpty && stop.longitude.isNotEmpty && stop.editingController.text.isNotEmpty)
        .toList();

    widget.controller.multiStopListNew = dataMulti;
    widget.controller.multiStopList = List.from(dataMulti);
    setState(() {});
    widget.onTripOptionBottomSheet();
  }
}