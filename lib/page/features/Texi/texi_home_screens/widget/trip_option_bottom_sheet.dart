
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:get/get.dart';

import 'package:finway/controller/home_osm_controller.dart';
import 'package:finway/themes/constant_colors.dart';
import 'package:finway/themes/text_field_them.dart';
import 'package:finway/themes/button_them.dart';
import 'package:finway/constant/show_toast_dialog.dart';

class TripOptionBottomSheet {
  static void show({
    required BuildContext context,
    required bool isDarkMode,
    required HomeOsmController controller,
    required VoidCallback onSelectVehicle,
  }) {
    final passengerController = TextEditingController(text: "1");

    showModalBottomSheet(
        barrierColor: isDarkMode ? AppThemeData.grey800.withAlpha(200) : Colors.black26,
        isDismissible: true,
        isScrollControlled: true,
        context: context,
        backgroundColor: isDarkMode ? AppThemeData.surface50Dark : AppThemeData.surface50,
        builder: (context) {
          return StatefulBuilder(builder: (context, setState) {
            return Padding(
              padding: MediaQuery.of(context).viewInsets,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Container(
                          margin: const EdgeInsets.symmetric(vertical: 10),
                          height: 8,
                          width: 75,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(100),
                            color: isDarkMode ? AppThemeData.grey300Dark : AppThemeData.grey300,
                          )),
                    ),
                    IconButton(
                        onPressed: () {
                          Get.back();
                        },
                        icon: Transform(
                          alignment: Alignment.center,
                          transform: Directionality.of(context) == TextDirection.rtl ? Matrix4.rotationY(3.14159) : Matrix4.identity(),
                          child: SvgPicture.asset(
                            'assets/icons/ic_left.svg',
                            colorFilter: ColorFilter.mode(
                              isDarkMode ? AppThemeData.grey900Dark : AppThemeData.grey900,
                              BlendMode.srcIn,
                            ),
                          ),
                        )),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 15.0, vertical: 8),
                      child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
                        // Location Fields
                        Column(
                          children: [
                            TextFieldWidget(
                              isReadOnly: true,
                              prefix: IconButton(
                                  onPressed: () {},
                                  icon: SvgPicture.asset(
                                    'assets/icons/ic_location.svg',
                                    colorFilter: ColorFilter.mode(
                                      AppThemeData.success300,
                                      BlendMode.srcIn,
                                    ),
                                  )),
                              controller: controller.departureController,
                              hintText: 'Pick Up Location'.tr,
                            ),
                            TextFieldWidget(
                              isReadOnly: true,
                              prefix: IconButton(
                                  onPressed: () {},
                                  icon: SvgPicture.asset(
                                    'assets/icons/ic_location.svg',
                                    colorFilter: ColorFilter.mode(
                                      AppThemeData.warning200,
                                      BlendMode.srcIn,
                                    ),
                                  )),
                              controller: controller.destinationController,
                              hintText: 'Where you want to go?'.tr,
                            ),
                            // Multi Stop List
                            ReorderableListView(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              children: <Widget>[
                                for (int index = 0; index < controller.multiStopListNew.length; index += 1)
                                  Container(
                                    key: ValueKey(controller.multiStopListNew[index]),
                                    child: Column(
                                      children: [
                                        Row(crossAxisAlignment: CrossAxisAlignment.center, children: [
                                          Expanded(
                                            child: TextFieldWidget(
                                              isReadOnly: true,
                                              onTap: () async {},
                                              prefix: IconButton(
                                                onPressed: () {},
                                                icon: Text(
                                                  String.fromCharCode(index + 65),
                                                  style: TextStyle(
                                                    fontSize: 16,
                                                    fontFamily: AppThemeData.regular,
                                                    color: isDarkMode ? AppThemeData.grey500Dark : AppThemeData.grey500,
                                                  ),
                                                ),
                                              ),
                                              hintText: "Where do you want to stop?".tr,
                                              controller: controller.multiStopListNew[index].editingController,
                                            ),
                                          ),
                                        ]),
                                      ],
                                    ),
                                  ),
                              ],
                              onReorder: (int oldIndex, int newIndex) {
                                if (oldIndex < newIndex) {
                                  newIndex -= 1;
                                }
                                final AddStopModelData item = controller.multiStopListNew.removeAt(oldIndex);
                                controller.multiStopListNew.insert(newIndex, item);
                              },
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          child: Text(
                            "Trip Options".tr,
                            style: TextStyle(
                              fontSize: 18,
                              fontFamily: AppThemeData.semiBold,
                              color: isDarkMode ? AppThemeData.grey900Dark : AppThemeData.grey900,
                            ),
                          ),
                        ),
                        // Passenger and Children Fields
                        Column(children: [
                          TextFieldWidget(
                            prefix: IconButton(
                                onPressed: () {},
                                icon: SvgPicture.asset(
                                  'assets/icons/ic_parent.svg',
                                  colorFilter: ColorFilter.mode(
                                    isDarkMode ? AppThemeData.grey500Dark : AppThemeData.grey300Dark,
                                    BlendMode.srcIn,
                                  ),
                                )),
                            controller: passengerController,
                            hintText: 'Enter passengers'.tr,
                          ),
                          ListView.builder(
                              physics: const NeverScrollableScrollPhysics(),
                              shrinkWrap: true,
                              itemCount: controller.addChildList.length,
                              itemBuilder: (_, index) {
                                return TextFieldWidget(
                                  prefix: IconButton(
                                      onPressed: () {},
                                      icon: SvgPicture.asset(
                                        'assets/icons/ic_child.svg',
                                        colorFilter: ColorFilter.mode(
                                          isDarkMode ? AppThemeData.grey500Dark : AppThemeData.grey300Dark,
                                          BlendMode.srcIn,
                                        ),
                                      )),
                                  controller: controller.addChildList[index].editingController,
                                  hintText: 'Any children ? Age of child'.tr,
                                );
                              }),
                          Visibility(
                            visible: controller.addChildList.length < 3,
                            child: Container(
                              decoration: BoxDecoration(
                                  border: Border.all(
                                    color: isDarkMode ? AppThemeData.grey300Dark : AppThemeData.grey300,
                                    width: 0.5,
                                  )),
                              child: Padding(
                                padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.start,
                                  children: [
                                    GestureDetector(
                                      onTap: () {
                                        if (controller.addChildList.length < 3) {
                                          controller.addChildList.add(AddChildModelData(editingController: TextEditingController()));
                                        }
                                      },
                                      child: SizedBox(
                                        child: Row(
                                          children: [
                                            Icon(
                                              Icons.add,
                                              color: AppThemeData.warning200,
                                              size: 20,
                                            ),
                                            const SizedBox(width: 10),
                                            Text(
                                              "Add Children's".tr,
                                              style: TextStyle(
                                                color: AppThemeData.warning200,
                                                fontFamily: AppThemeData.regular,
                                                fontSize: 16,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ]),
                        const SizedBox(height: 30),
                        Padding(
                          padding: const EdgeInsets.only(top: 10),
                          child: ButtonThem.buildButton(context, title: "Select Vehicle".tr, btnColor: AppThemeData.primary200, onPress: () async {
                            if (passengerController.text.isEmpty) {
                              ShowToastDialog.showToast("Please Enter Passenger".tr);
                            } else {
                              Get.back();
                              onSelectVehicle();
                            }
                          }),
                        )
                      ]),
                    ),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            );
          });
        });
  }
}