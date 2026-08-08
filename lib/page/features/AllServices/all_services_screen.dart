import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:provider/provider.dart';

import 'package:finway/controller/all_services_controller.dart';
import 'package:finway/model/service_category_model.dart';
import 'package:finway/themes/constant_colors.dart';
import 'package:finway/utils/dark_theme_provider.dart';
import 'lab_sample_selection_screen.dart';
import 'service_category_detail_screen.dart';
import 'service_category_tile.dart';
import 'service_request_screen.dart';
import 'service_style.dart';

class AllServicesScreen extends StatefulWidget {
  const AllServicesScreen({super.key});

  @override
  State<AllServicesScreen> createState() => _AllServicesScreenState();
}

class _AllServicesScreenState extends State<AllServicesScreen> {
  final _controller = Get.put(AllServicesController(), tag: UniqueKey().toString());
  final _searchController = TextEditingController();
  Timer? _searchDebounce;

  bool _isLoading = true;
  bool _searchOpen = false;
  bool _searchLoading = false;
  List<ServiceCategoryData> _categories = [];
  List<ServiceCategoryData> _searchResults = [];

  static const _gridDelegate = SliverGridDelegateWithFixedCrossAxisCount(
    crossAxisCount: 5,
    mainAxisSpacing: 14,
    crossAxisSpacing: 8,
    childAspectRatio: 0.72,
  );

  static const _searchGridDelegate = SliverGridDelegateWithFixedCrossAxisCount(
    crossAxisCount: 5,
    mainAxisSpacing: 14,
    crossAxisSpacing: 8,
    childAspectRatio: 0.58,
  );

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _searchDebounce?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final data = await _controller.fetchCategories();
    if (mounted) {
      setState(() {
        _categories = data;
        _isLoading = false;
      });
    }
  }

  void _toggleSearch() {
    setState(() {
      _searchOpen = !_searchOpen;
      if (!_searchOpen) {
        _searchController.clear();
        _searchResults = [];
        _searchLoading = false;
      }
    });
  }

  void _onSearchChanged(String value) {
    _searchDebounce?.cancel();
    if (value.trim().isEmpty) {
      setState(() {
        _searchResults = [];
        _searchLoading = false;
      });
      return;
    }
    setState(() => _searchLoading = true);
    _searchDebounce = Timer(const Duration(milliseconds: 350), () async {
      final results = await _controller.searchCategories(value);
      if (mounted) {
        setState(() {
          _searchResults = results;
          _searchLoading = false;
        });
      }
    });
  }

  String _breadcrumbLabel(ServiceCategoryData category) {
    return category.breadcrumb.map(cleanServiceName).where((s) => s.isNotEmpty).join(' › ');
  }

  String _parentCategoryName(ServiceCategoryData category) {
    if (category.breadcrumb.isNotEmpty) return cleanServiceName(category.breadcrumb.last);
    return cleanServiceName(category.libelle);
  }

  void _onTapCategory(ServiceCategoryData category) {
    final rawName = category.libelle ?? '';
    final cleanName = cleanServiceName(rawName);
    final lower = cleanName.toLowerCase();

    if (lower.contains('lab sample') || lower.contains('lab collection')) {
      Get.to(() => LabSampleSelectionScreen(categoryName: _parentCategoryName(category)));
      return;
    }

    if (isParentServiceCategory(rawName)) {
      Get.to(() => ServiceCategoryDetailScreen(categoryId: category.id ?? 0, categoryName: rawName));
      return;
    }

    Get.to(() => ServiceRequestScreen(
          serviceName: rawName,
          categoryName: _parentCategoryName(category),
        ));
  }

  Widget _buildGrid(List<ServiceCategoryData> items, bool isDarkMode, {bool showBreadcrumb = false}) {
    if (items.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Text(
            showBreadcrumb ? 'No matching services found'.tr : 'No services available'.tr,
            style: TextStyle(color: AppThemeData.grey500),
          ),
        ),
      );
    }
    return GridView.builder(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 24),
      itemCount: items.length,
      gridDelegate: showBreadcrumb ? _searchGridDelegate : _gridDelegate,
      itemBuilder: (context, index) {
        final category = items[index];
        return ServiceCategoryTile(
          label: category.libelle,
          imageUrl: null,
          subtitle: showBreadcrumb ? _breadcrumbLabel(category) : null,
          isDarkMode: isDarkMode,
          iconSize: showBreadcrumb ? 48 : 56,
          onTap: () => _onTapCategory(category),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final themeChange = Provider.of<DarkThemeProvider>(context);
    final isDarkMode = themeChange.getThem();
    final isSearching = _searchOpen && _searchController.text.trim().isNotEmpty;

    return Scaffold(
      backgroundColor: isDarkMode ? AppThemeData.surface50Dark : Colors.white,
      appBar: AppBar(
        backgroundColor: isDarkMode ? AppThemeData.surface50Dark : Colors.white,
        elevation: 0,
        iconTheme: IconThemeData(color: isDarkMode ? AppThemeData.grey900Dark : Colors.black),
        title: _searchOpen
            ? TextField(
                controller: _searchController,
                autofocus: true,
                onChanged: _onSearchChanged,
                style: TextStyle(
                  fontFamily: AppThemeData.medium,
                  fontSize: 15,
                  color: isDarkMode ? AppThemeData.grey900Dark : Colors.black,
                ),
                decoration: InputDecoration(
                  hintText: 'Search home services...'.tr,
                  border: InputBorder.none,
                  hintStyle: TextStyle(color: AppThemeData.grey500, fontFamily: AppThemeData.regular),
                ),
              )
            : Text(
                'Home Services'.tr,
                style: TextStyle(
                  fontFamily: AppThemeData.bold,
                  fontSize: 18,
                  color: isDarkMode ? AppThemeData.grey900Dark : Colors.black,
                ),
              ),
        actions: [
          IconButton(
            icon: Icon(_searchOpen ? Icons.close_rounded : Icons.search_rounded),
            color: isDarkMode ? AppThemeData.grey900Dark : Colors.black,
            onPressed: _toggleSearch,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : isSearching
              ? (_searchLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _buildGrid(_searchResults, isDarkMode, showBreadcrumb: true))
              : _buildGrid(_categories, isDarkMode),
    );
  }
}
