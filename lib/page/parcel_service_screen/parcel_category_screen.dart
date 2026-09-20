import 'package:finway/model/parcel_category_model.dart';
import 'package:finway/page/parcel_service_screen/all_parcel_screen.dart';
import 'package:finway/page/parcel_service_screen/book_parcel_screen.dart';
import 'package:finway/themes/constant_colors.dart';
import 'package:finway/themes/appbar_cust.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:provider/provider.dart';
import '../../controller/parcel_service_controller.dart';
import '../../utils/dark_theme_provider.dart';

class ParcelCategoryScreen extends StatelessWidget {
  const ParcelCategoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final themeChange = Provider.of<DarkThemeProvider>(context);
    final bool isDark = themeChange.getThem();

    final controller = Get.isRegistered<ParcelServiceController>()
        ? Get.find<ParcelServiceController>()
        : Get.put(ParcelServiceController());

    return GetX<ParcelServiceController>(
      init: controller,
      builder: (controller) {
        return Scaffold(
          backgroundColor: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
          appBar: CustomAppbar(
            title: "Select Parcel Category".tr,
            bgColor: AppThemeData.primary200,
            textColor: Colors.white,
            actions: [
              IconButton(
                tooltip: "My Parcels".tr,
                icon: const Icon(Icons.history_rounded, color: Colors.white, size: 24),
                onPressed: () => Get.to(() => const AllParcelScreen()),
              ),
            ],
          ),
          body: RefreshIndicator(
            color: AppThemeData.primary200,
            onRefresh: () async {
              await controller.getParcelCategory();
            },
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ─── Modern Feature Banner ──────────────────────────────────

                  const SizedBox(height: 18),

                  // ─── Header Section ─────────────────────────────────────────
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "What are you sending?".tr,
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w800,
                                fontFamily: AppThemeData.bold,
                                color: isDark ? Colors.white : const Color(0xFF0F172A),
                                letterSpacing: -0.3,
                              ),
                            ),
                            const SizedBox(height: 3),
                            Text(
                              "Choose a category to get started".tr,
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                                fontFamily: AppThemeData.regular,
                                color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      Material(
                        color: Colors.transparent,
                        child: InkWell(
                          borderRadius: BorderRadius.circular(24),
                          onTap: () => Get.to(() => const AllParcelScreen()),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                            decoration: BoxDecoration(
                              color: AppThemeData.primary200.withValues(alpha: isDark ? 0.18 : 0.1),
                              borderRadius: BorderRadius.circular(24),
                              border: Border.all(
                                color: AppThemeData.primary200.withValues(alpha: isDark ? 0.35 : 0.25),
                                width: 1.2,
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.inventory_2_outlined, size: 16, color: AppThemeData.primary200),
                                const SizedBox(width: 5),
                                Text(
                                  "My Parcels".tr,
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: AppThemeData.primary200,
                                    fontWeight: FontWeight.w700,
                                    fontFamily: AppThemeData.semiBold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // ─── Categories Grid or Skeleton ────────────────────────────
                  controller.isLoading.value
                      ? _buildShimmerGrid(isDark)
                      : controller.parcelCategoryList.isEmpty
                          ? _buildEmptyState(context, isDark, controller)
                          : GridView.builder(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: 2,
                                crossAxisSpacing: 14,
                                mainAxisSpacing: 14,
                                mainAxisExtent: 140,
                              ),
                              itemCount: controller.parcelCategoryList.length,
                              itemBuilder: (context, index) {
                                return _buildModernCategoryCard(
                                  context: context,
                                  item: controller.parcelCategoryList[index],
                                  controller: controller,
                                  isDark: isDark,
                                  index: index,
                                );
                              },
                            ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
        );
      },
    );
  }



  // ─── Modern Style Category Card ────────────────────────────────────────────
  Widget _buildModernCategoryCard({
    required BuildContext context,
    required ParcelCategoryData item,
    required ParcelServiceController controller,
    required bool isDark,
    required int index,
  }) {
    final titleLower = (item.title ?? '').toLowerCase();

    // Themed styling per category type
    _CategoryTheme theme = _getCategoryTheme(titleLower, isDark);

    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: (isDark ? Colors.black : const Color(0xFF0F172A)).withValues(alpha: isDark ? 0.25 : 0.04),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          splashColor: AppThemeData.primary200.withValues(alpha: 0.12),
          highlightColor: AppThemeData.primary200.withValues(alpha: 0.05),
          onTap: () {
            controller.selectedParcelCategory.value = item;
            Get.to(() => const BookParcelScreen());
          },
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Top Row: Icon container + subtle arrow
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 58,
                      height: 58,
                      decoration: BoxDecoration(
                        color: theme.iconBgColor,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: theme.iconBorderColor,
                          width: 1,
                        ),
                      ),
                      padding: const EdgeInsets.all(8),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: CachedNetworkImage(
                          imageUrl: item.image.toString(),
                          fit: BoxFit.contain,
                          placeholder: (context, url) => const Center(
                            child: SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            ),
                          ),
                          errorWidget: (context, url, error) => Icon(
                            theme.fallbackIcon,
                            size: 28,
                            color: theme.accentColor,
                          ),
                        ),
                      ),
                    ),
                    Container(
                      width: 28,
                      height: 28,
                      decoration: BoxDecoration(
                        color: (isDark ? Colors.white : const Color(0xFF0F172A)).withValues(alpha: 0.05),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.arrow_forward_rounded,
                        size: 14,
                        color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),

                // Bottom Content: Title and Subtitle
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.title.toString().tr,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        fontFamily: AppThemeData.bold,
                        color: isDark ? Colors.white : const Color(0xFF0F172A),
                        letterSpacing: -0.2,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      theme.subtitle.tr,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                        fontFamily: AppThemeData.regular,
                        color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ─── Theme helper for categories ──────────────────────────────────────────
  _CategoryTheme _getCategoryTheme(String titleLower, bool isDark) {
    if (titleLower.contains('doc') || titleLower.contains('paper') || titleLower.contains('file')) {
      return _CategoryTheme(
        iconBgColor: isDark ? const Color(0xFF1E3A8A).withValues(alpha: 0.35) : const Color(0xFFEFF6FF),
        iconBorderColor: isDark ? const Color(0xFF1D4ED8).withValues(alpha: 0.4) : const Color(0xFFDBEAFE),
        accentColor: const Color(0xFF2563EB),
        fallbackIcon: Icons.description_outlined,
        subtitle: "Files, papers & certificates",
      );
    } else if (titleLower.contains('gift') || titleLower.contains('present') || titleLower.contains('box')) {
      return _CategoryTheme(
        iconBgColor: isDark ? const Color(0xFF581C87).withValues(alpha: 0.35) : const Color(0xFFFAF5FF),
        iconBorderColor: isDark ? const Color(0xFF7E22CE).withValues(alpha: 0.4) : const Color(0xFFF3E8FF),
        accentColor: const Color(0xFF9333EA),
        fallbackIcon: Icons.card_giftcard_rounded,
        subtitle: "Presents, boxes & treats",
      );
    } else if (titleLower.contains('med') || titleLower.contains('health') || titleLower.contains('care')) {
      return _CategoryTheme(
        iconBgColor: isDark ? const Color(0xFF064E3B).withValues(alpha: 0.35) : const Color(0xFFECFDF5),
        iconBorderColor: isDark ? const Color(0xFF047857).withValues(alpha: 0.4) : const Color(0xFFA7F3D0),
        accentColor: const Color(0xFF059669),
        fallbackIcon: Icons.medical_services_outlined,
        subtitle: "Medicines & healthcare",
      );
    } else if (titleLower.contains('furn') || titleLower.contains('home') || titleLower.contains('item')) {
      return _CategoryTheme(
        iconBgColor: isDark ? const Color(0xFF78350F).withValues(alpha: 0.35) : const Color(0xFFFFFBEB),
        iconBorderColor: isDark ? const Color(0xFFB45309).withValues(alpha: 0.4) : const Color(0xFFFDE68A),
        accentColor: const Color(0xFFD97706),
        fallbackIcon: Icons.chair_outlined,
        subtitle: "Appliances & bulky items",
      );
    } else {
      return _CategoryTheme(
        iconBgColor: isDark ? const Color(0xFF312E81).withValues(alpha: 0.35) : const Color(0xFFEEF2FF),
        iconBorderColor: isDark ? const Color(0xFF4338CA).withValues(alpha: 0.4) : const Color(0xFFE0E7FF),
        accentColor: const Color(0xFF4F46E5),
        fallbackIcon: Icons.local_shipping_outlined,
        subtitle: "Custom parcel package",
      );
    }
  }

  // ─── Shimmer Skeleton for Smooth Loading ──────────────────────────────────
  Widget _buildShimmerGrid(bool isDark) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 14,
        mainAxisSpacing: 14,
        mainAxisExtent: 180,
      ),
      itemCount: 4,
      itemBuilder: (context, index) {
        final shimmerBase = isDark ? const Color(0xFF1E293B) : Colors.white;
        final shimmerFill = isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0);

        return Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: shimmerBase,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
              width: 1.2,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                width: 58,
                height: 58,
                decoration: BoxDecoration(
                  color: shimmerFill.withValues(alpha: 0.6),
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 90,
                    height: 14,
                    decoration: BoxDecoration(
                      color: shimmerFill.withValues(alpha: 0.8),
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Container(
                    width: 120,
                    height: 10,
                    decoration: BoxDecoration(
                      color: shimmerFill.withValues(alpha: 0.4),
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  // ─── Empty State ──────────────────────────────────────────────────────────
  Widget _buildEmptyState(BuildContext context, bool isDark, ParcelServiceController controller) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 20),
      alignment: Alignment.center,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.inventory_2_outlined,
            size: 56,
            color: isDark ? const Color(0xFF64748B) : const Color(0xFF94A3B8),
          ),
          const SizedBox(height: 12),
          Text(
            "No Categories Available".tr,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: isDark ? Colors.white : const Color(0xFF0F172A),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            "Check back later or tap to reload".tr,
            style: TextStyle(
              fontSize: 12,
              color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
            ),
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppThemeData.primary200,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            ),
            onPressed: () => controller.getParcelCategory(),
            icon: const Icon(Icons.refresh_rounded, size: 18, color: Colors.white),
            label: Text("Reload".tr, style: const TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}

class _CategoryTheme {
  final Color iconBgColor;
  final Color iconBorderColor;
  final Color accentColor;
  final IconData fallbackIcon;
  final String subtitle;

  _CategoryTheme({
    required this.iconBgColor,
    required this.iconBorderColor,
    required this.accentColor,
    required this.fallbackIcon,
    required this.subtitle,
  });
}
