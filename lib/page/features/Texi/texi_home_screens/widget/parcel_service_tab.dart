import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:get/get.dart';
import 'package:cached_network_image/cached_network_image.dart';

import 'package:finway/controller/home_osm_controller.dart';
import 'package:finway/controller/parcel_service_controller.dart';
import 'package:finway/themes/constant_colors.dart';
import 'package:finway/themes/responsive.dart';
import 'package:finway/constant/constant.dart';
import 'package:finway/constant/image_constant.dart';
import 'package:finway/page/parcel_service_screen/book_parcel_screen.dart';

class ParcelServiceTab extends StatelessWidget {
  final HomeOsmController controller;
  final bool isDarkMode;

  const ParcelServiceTab({
    super.key,
    required this.controller,
    required this.isDarkMode,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      child: GetX<ParcelServiceController>(
          init: ParcelServiceController(),
          builder: (parcelServiceController) {
            return Padding(
              padding: EdgeInsets.symmetric(horizontal: Constant.homeScreenType == 'OlaHome' ? 0 : 16),
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 20),
                    Text(
                      "Select what are you sending?".tr,
                      style: TextStyle(
                        fontSize: 18,
                        fontFamily: AppThemeData.semiBold,
                        color: isDarkMode ? AppThemeData.grey900Dark : AppThemeData.grey900,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Container(
                      width: double.infinity,
                      decoration: BoxDecoration(
                        border: Border.all(
                          color: isDarkMode ? AppThemeData.grey300Dark : AppThemeData.grey300,
                          width: 1,
                        ),
                      ),
                      child: ListView.separated(
                          primary: false,
                          padding: EdgeInsets.zero,
                          separatorBuilder: (context, index) => Container(
                            height: 1,
                            color: isDarkMode ? AppThemeData.grey300Dark : AppThemeData.grey300,
                          ),
                          shrinkWrap: true,
                          itemCount: parcelServiceController.parcelCategoryList.length,
                          itemBuilder: (BuildContext context, int index) {
                            return InkWell(
                              splashColor: Colors.transparent,
                              onTap: () {
                                parcelServiceController.selectedParcelCategory.value = parcelServiceController.parcelCategoryList[index];
                                Get.to(() => const BookParcelScreen());
                              },
                              child: Padding(
                                padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Row(
                                      children: [
                                        Padding(
                                          padding: const EdgeInsets.symmetric(horizontal: 16),
                                          child: CachedNetworkImage(
                                            imageUrl: parcelServiceController.parcelCategoryList[index].image.toString(),
                                            height: 25,
                                            width: 25,
                                            imageBuilder: (context, imageProvider) => Container(
                                              decoration: BoxDecoration(
                                                image: DecorationImage(image: imageProvider, fit: BoxFit.cover),
                                              ),
                                            ),
                                            placeholder: (context, url) => Constant.loader(context),
                                            errorWidget: (context, url, error) =>
                                                Image.asset(ImageConstant.logo, height: 25, width: 25, fit: BoxFit.cover),
                                            fit: BoxFit.cover,
                                          ),
                                        ),
                                        const SizedBox(width: 6),
                                        Text(
                                          parcelServiceController.parcelCategoryList[index].title.toString(),
                                          style: TextStyle(
                                            fontSize: 16,
                                            fontFamily: AppThemeData.medium,
                                            color: isDarkMode ? AppThemeData.grey900Dark : AppThemeData.grey900,
                                          ),
                                        ),
                                      ],
                                    ),
                                    SvgPicture.asset(
                                      'assets/icons/ic_right_arrow.svg',
                                      fit: BoxFit.cover,
                                      colorFilter: ColorFilter.mode(
                                        isDarkMode ? AppThemeData.grey500Dark : AppThemeData.grey500,
                                        BlendMode.srcIn,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          }),
                    ),
                    const SizedBox(height: 20),
                    ListView.builder(
                      padding: EdgeInsets.zero,
                      primary: false,
                      shrinkWrap: true,
                      itemCount: controller.bannerModel.value.data?.length,
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
                                  imageUrl: controller.bannerModel.value.data?[i].image ?? '',
                                  fit: BoxFit.cover,
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
                                        controller.bannerModel.value.data?[i].title ?? '',
                                        maxLines: 1,
                                        style: TextStyle(
                                          fontSize: 16,
                                          fontFamily: AppThemeData.medium,
                                          color: AppThemeData.grey50Dark,
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        controller.bannerModel.value.data?[i].description ?? '',
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
                ),
              ),
            );
          }),
    );
  }
}