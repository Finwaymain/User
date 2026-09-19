import 'package:finway/constant/constant.dart';
import 'package:finway/model/parcel_category_model.dart';
import 'package:finway/page/parcel_service_screen/all_parcel_screen.dart';
import 'package:finway/page/parcel_service_screen/book_parcel_screen.dart';
import 'package:finway/themes/constant_colors.dart';
import 'package:finway/themes/appbar_cust.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../constant/image_constant.dart';
import '../../controller/parcel_service_controller.dart';

class ParcelCategoryScreen extends StatelessWidget {
  const ParcelCategoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.isRegistered<ParcelServiceController>()
        ? Get.find<ParcelServiceController>()
        : Get.put(ParcelServiceController());

    return GetX<ParcelServiceController>(
        init: controller,
        builder: (controller) {
          return Scaffold(
            backgroundColor: ConstantColors.background,
            appBar: CustomAppbar(
              title: "Select Parcel Category".tr,
              bgColor: AppThemeData.primary200,
              actions: [
                IconButton(
                  tooltip: "My Parcels".tr,
                  icon: const Icon(Icons.history_rounded, color: Colors.white),
                  onPressed: () => Get.to(() => const AllParcelScreen()),
                ),
              ],
            ),
            body: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10),
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.only(left: 10.0, right: 10.0, bottom: 10, top: 6),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          "What are you sending?".tr,
                          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                          textAlign: TextAlign.left,
                        ),
                        InkWell(
                          onTap: () => Get.to(() => const AllParcelScreen()),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.inventory_2_outlined, size: 18, color: AppThemeData.primary200),
                              const SizedBox(width: 4),
                              Text(
                                "My Parcels".tr,
                                style: TextStyle(
                                  fontSize: 14,
                                  color: AppThemeData.primary200,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  controller.isLoading.value
                      ? SizedBox()
                      : Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 10),
                          child: GridView.builder(
                              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: 2,
                                crossAxisSpacing: 15,
                                mainAxisSpacing: 15,
                                mainAxisExtent: 120,
                              ),
                              itemCount: controller.parcelCategoryList.length,
                              padding: const EdgeInsets.all(8),
                              shrinkWrap: true,
                              physics: const ScrollPhysics(),
                              itemBuilder: (context, index) {
                                return buildItems(
                                  item: controller.parcelCategoryList[index],
                                  controller: controller,
                                );
                              }),
                        )
                ],
              ),
            ),
          );
        });
  }

  buildItems({required ParcelCategoryData item, required ParcelServiceController controller}) {
    return InkWell(
      onTap: () {
        controller.selectedParcelCategory.value = item;

        Get.to(
          () => const BookParcelScreen(),
        );
      },
      child: Card(
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            CachedNetworkImage(
              imageUrl: item.image.toString(),
              height: 60,
              width: 60,
              imageBuilder: (context, imageProvider) => Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(10),
                  image: DecorationImage(image: imageProvider, fit: BoxFit.cover),
                ),
              ),
              placeholder: (context, url) => Constant.loader(context),
              errorWidget: (context, url, error) => Image.asset(
                ImageConstant.logo,
              ),
              fit: BoxFit.cover,
            ),
            Text(item.title.toString()),
          ],
        ),
      ),
    );
  }
}
