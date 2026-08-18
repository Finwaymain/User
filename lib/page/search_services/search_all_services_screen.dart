import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:provider/provider.dart';
import '../../themes/constant_colors.dart';
import '../../utils/dark_theme_provider.dart';
import '../features/Texi/texi_dash_board.dart';
import '../features/AllServices/all_services_screen.dart';
import '../parcel_service_screen/parcel_category_screen.dart';
import '../marketplace/view/marketplace_home_screen.dart';
import '../referral_screen/referral_screen.dart';
import '../wallet/wallet_screen.dart';
import '../features/SmartValue/ScanAndTransfer/view/scanner_and_transfer_screen.dart';
import '../features/SmartValue/Medical/view/medical_screen.dart';
import '../features/SmartValue/MyQR/view/my_qr_view.dart';
import '../features/SmartValue/AccountDetails/view/account_details.dart';
import '../contact_us/customer_support_screen.dart';

class ServiceSearchItem {
  final String id;
  final String title;
  final String category;
  final String description;
  final String iconEmoji;
  final IconData? iconData;
  final Color accentColor;
  final String? badge;
  final VoidCallback onTap;

  ServiceSearchItem({
    required this.id,
    required this.title,
    required this.category,
    required this.description,
    required this.iconEmoji,
    this.iconData,
    required this.accentColor,
    this.badge,
    required this.onTap,
  });
}

class SearchAllServicesScreen extends StatefulWidget {
  final bool isTab;
  const SearchAllServicesScreen({super.key, this.isTab = false});

  @override
  State<SearchAllServicesScreen> createState() => _SearchAllServicesScreenState();
}

class _SearchAllServicesScreenState extends State<SearchAllServicesScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _selectedCategory = 'All';
  String _searchQuery = '';

  final List<String> _categories = [
    'All',
    'Rides',
    'Home Services',
    'Logistics',
    'Smart Value',
    'Marketplace',
  ];

  List<ServiceSearchItem> _buildServicesList() {
    return [
      // 1. RIDES & MOBILITY
      ServiceSearchItem(
        id: 'ride_cab',
        title: 'Cab & Taxi Booking',
        category: 'Rides',
        description: 'Instant city rides, Sedan, Mini, Prime & SUV cabs',
        iconEmoji: '🚖',
        iconData: Icons.local_taxi_rounded,
        accentColor: const Color(0xFF2C5CE6),
        badge: 'Popular',
        onTap: () => Get.to(() => const TexiDashboard()),
      ),
      ServiceSearchItem(
        id: 'ride_bike',
        title: 'Bike Taxi',
        category: 'Rides',
        description: 'Quickest & most affordable two-wheeler city rides',
        iconEmoji: '🛵',
        iconData: Icons.two_wheeler_rounded,
        accentColor: const Color(0xFF00875A),
        badge: 'Fastest',
        onTap: () => Get.to(() => const TexiDashboard()),
      ),
      ServiceSearchItem(
        id: 'ride_auto',
        title: 'Auto Rickshaw',
        category: 'Rides',
        description: 'Doorstep auto rides with direct meter / upfront fares',
        iconEmoji: '🛺',
        iconData: Icons.electric_rickshaw_rounded,
        accentColor: const Color(0xFFFF8B00),
        onTap: () => Get.to(() => const TexiDashboard()),
      ),
      ServiceSearchItem(
        id: 'ride_rental',
        title: 'Rental Rides',
        category: 'Rides',
        description: 'Hourly packages with multiple stops and driver',
        iconEmoji: '⏱️',
        iconData: Icons.car_rental_rounded,
        accentColor: const Color(0xFF6554C0),
        onTap: () => Get.to(() => const TexiDashboard()),
      ),
      ServiceSearchItem(
        id: 'ride_outstation',
        title: 'Outstation Rides',
        category: 'Rides',
        description: 'One-way & round-trip intercity cab travel',
        iconEmoji: '🛣️',
        iconData: Icons.alt_route_rounded,
        accentColor: const Color(0xFF36B37E),
        onTap: () => Get.to(() => const TexiDashboard()),
      ),

      // 2. LOGISTICS & PARCEL
      ServiceSearchItem(
        id: 'parcel_send',
        title: 'Send Parcel & Courier',
        category: 'Logistics',
        description: 'Fast, secure doorstep package delivery across city',
        iconEmoji: '📦',
        iconData: Icons.local_shipping_rounded,
        accentColor: const Color(0xFFE65100),
        badge: 'Same Day',
        onTap: () => Get.to(() => const ParcelCategoryScreen()),
      ),
      ServiceSearchItem(
        id: 'parcel_documents',
        title: 'Document & Paper Delivery',
        category: 'Logistics',
        description: 'Urgent office, legal & confidential documents',
        iconEmoji: '📄',
        iconData: Icons.description_rounded,
        accentColor: const Color(0xFF0097A7),
        onTap: () => Get.to(() => const ParcelCategoryScreen()),
      ),
      ServiceSearchItem(
        id: 'parcel_food',
        title: 'Food & Essentials Delivery',
        category: 'Logistics',
        description: 'Home food, lunch boxes, groceries & essentials',
        iconEmoji: '🍱',
        iconData: Icons.fastfood_rounded,
        accentColor: const Color(0xFFD81B60),
        onTap: () => Get.to(() => const ParcelCategoryScreen()),
      ),
      ServiceSearchItem(
        id: 'parcel_electronics',
        title: 'Electronics & Fragile Items',
        category: 'Logistics',
        description: 'Careful handling for gadgets, boxes & fragile items',
        iconEmoji: '💻',
        iconData: Icons.devices_other_rounded,
        accentColor: const Color(0xFF5E35B1),
        onTap: () => Get.to(() => const ParcelCategoryScreen()),
      ),
      ServiceSearchItem(
        id: 'parcel_medicines',
        title: 'Medicine & Healthcare Delivery',
        category: 'Logistics',
        description: 'Urgent prescription medicines & emergency deliveries',
        iconEmoji: '💊',
        iconData: Icons.medical_services_rounded,
        accentColor: const Color(0xFFC2185B),
        badge: 'Urgent',
        onTap: () => Get.to(() => const ParcelCategoryScreen()),
      ),

      // 3. HOME SERVICES
      ServiceSearchItem(
        id: 'svc_electrician',
        title: 'Electrician',
        category: 'Home Services',
        description: 'Fan, MCB, switchboard, wiring & inverter repair',
        iconEmoji: '⚡',
        iconData: Icons.electrical_services_rounded,
        accentColor: const Color(0xFFFFB300),
        badge: 'Top Rated',
        onTap: () => Get.to(() => const AllServicesScreen()),
      ),
      ServiceSearchItem(
        id: 'svc_plumber',
        title: 'Plumber',
        category: 'Home Services',
        description: 'Tap, pipe leakage, toilet, basin & motor fittings',
        iconEmoji: '🔧',
        iconData: Icons.plumbing_rounded,
        accentColor: const Color(0xFF0288D1),
        badge: 'Verified',
        onTap: () => Get.to(() => const AllServicesScreen()),
      ),
      ServiceSearchItem(
        id: 'svc_appliance',
        title: 'AC & Appliance Repair',
        category: 'Home Services',
        description: 'AC servicing, washing machine, fridge, microwave & RO',
        iconEmoji: '❄️',
        iconData: Icons.ac_unit_rounded,
        accentColor: const Color(0xFF00ACC1),
        onTap: () => Get.to(() => const AllServicesScreen()),
      ),
      ServiceSearchItem(
        id: 'svc_cleaning',
        title: 'Home Cleaning & Deep Clean',
        category: 'Home Services',
        description: 'Full house deep cleaning, bathroom & kitchen shine',
        iconEmoji: '🧹',
        iconData: Icons.cleaning_services_rounded,
        accentColor: const Color(0xFF43A047),
        onTap: () => Get.to(() => const AllServicesScreen()),
      ),
      ServiceSearchItem(
        id: 'svc_salon_women',
        title: 'Women Salon & Beauty',
        category: 'Home Services',
        description: 'Facial, waxing, manicure, pedicure & bridal makeup at home',
        iconEmoji: '💄',
        iconData: Icons.face_retouching_natural_rounded,
        accentColor: const Color(0xFFEC407A),
        badge: 'Hygienic',
        onTap: () => Get.to(() => const AllServicesScreen()),
      ),
      ServiceSearchItem(
        id: 'svc_salon_men',
        title: 'Men Grooming & Massage',
        category: 'Home Services',
        description: 'Haircut, beard grooming, head massage & spa at home',
        iconEmoji: '✂️',
        iconData: Icons.content_cut_rounded,
        accentColor: const Color(0xFF5C6BC0),
        onTap: () => Get.to(() => const AllServicesScreen()),
      ),
      ServiceSearchItem(
        id: 'svc_carpenter',
        title: 'Carpenter & Woodwork',
        category: 'Home Services',
        description: 'Furniture repair, hinges, door locks & custom woodwork',
        iconEmoji: '🪚',
        iconData: Icons.carpenter_rounded,
        accentColor: const Color(0xFF8D6E63),
        onTap: () => Get.to(() => const AllServicesScreen()),
      ),
      ServiceSearchItem(
        id: 'svc_painter',
        title: 'Painter & Waterproofing',
        category: 'Home Services',
        description: 'Wall painting, damp proofing & interior wall textures',
        iconEmoji: '🎨',
        iconData: Icons.format_paint_rounded,
        accentColor: const Color(0xFF7E57C2),
        onTap: () => Get.to(() => const AllServicesScreen()),
      ),
      ServiceSearchItem(
        id: 'svc_pest',
        title: 'Pest Control',
        category: 'Home Services',
        description: 'Cockroach, termite, bed bug & mosquito disinfection',
        iconEmoji: '🛡️',
        iconData: Icons.pest_control_rounded,
        accentColor: const Color(0xFF388E3C),
        onTap: () => Get.to(() => const AllServicesScreen()),
      ),
      ServiceSearchItem(
        id: 'svc_doctor',
        title: 'Doctor Home Visit & Nursing',
        category: 'Home Services',
        description: 'Certified doctors, nursing care & physiotherapists at home',
        iconEmoji: '🩺',
        iconData: Icons.health_and_safety_rounded,
        accentColor: const Color(0xFFE53935),
        badge: 'Certified',
        onTap: () => Get.to(() => const AllServicesScreen()),
      ),
      ServiceSearchItem(
        id: 'svc_lab',
        title: 'Diagnostic Lab Sample Collection',
        category: 'Home Services',
        description: 'Blood tests, full body checkups & home sample pickup',
        iconEmoji: '🧪',
        iconData: Icons.biotech_rounded,
        accentColor: const Color(0xFF3949AB),
        onTap: () => Get.to(() => const AllServicesScreen()),
      ),
      ServiceSearchItem(
        id: 'svc_tutor',
        title: 'Home Tutor Services',
        category: 'Home Services',
        description: 'School subjects, competitive exams & private home tutors',
        iconEmoji: '📚',
        iconData: Icons.school_rounded,
        accentColor: const Color(0xFF00897B),
        onTap: () => Get.to(() => const AllServicesScreen()),
      ),
      ServiceSearchItem(
        id: 'svc_all_directory',
        title: 'Browse All 50+ Home Services',
        category: 'Home Services',
        description: 'Explore full directory of verified on-demand experts',
        iconEmoji: '🛠️',
        iconData: Icons.dashboard_customize_rounded,
        accentColor: const Color(0xFF6AA720),
        badge: 'View All',
        onTap: () => Get.to(() => const AllServicesScreen()),
      ),

      // 4. SMART VALUE & FINANCE
      ServiceSearchItem(
        id: 'sv_wallet',
        title: 'Smart Value Wallet',
        category: 'Smart Value',
        description: 'Recharge wallet, view balance, receipts & cashback',
        iconEmoji: '💳',
        iconData: Icons.account_balance_wallet_rounded,
        accentColor: const Color(0xFF6AA720),
        badge: 'Instant',
        onTap: () => Get.to(() => WalletScreen()),
      ),
      ServiceSearchItem(
        id: 'sv_scan',
        title: 'Scan & Pay / Transfer',
        category: 'Smart Value',
        description: 'Scan QR code & transfer funds instantly to any user',
        iconEmoji: '📲',
        iconData: Icons.qr_code_scanner_rounded,
        accentColor: const Color(0xFF2C5CE6),
        onTap: () => Get.to(() => ScannerAndTransferScreen()),
      ),
      ServiceSearchItem(
        id: 'sv_myqr',
        title: 'My QR Code',
        category: 'Smart Value',
        description: 'Show your personal QR code to receive payments',
        iconEmoji: '🔳',
        iconData: Icons.qr_code_rounded,
        accentColor: const Color(0xFF424242),
        onTap: () => Get.to(() => MyQRScreen()),
      ),
      ServiceSearchItem(
        id: 'sv_medical',
        title: 'Medical Cashback Card',
        category: 'Smart Value',
        description: 'Claim up to 100% cashback on medical & pharmacy bills',
        iconEmoji: '🏥',
        iconData: Icons.local_hospital_rounded,
        accentColor: const Color(0xFFE91E63),
        badge: 'Cashback',
        onTap: () => Get.to(() => MedicalScreen()),
      ),
      ServiceSearchItem(
        id: 'sv_referral',
        title: 'Refer & Earn Rewards',
        category: 'Smart Value',
        description: 'Invite friends and earn instant cash bonuses',
        iconEmoji: '🎁',
        iconData: Icons.card_giftcard_rounded,
        accentColor: const Color(0xFFFF6F00),
        badge: 'Bonus',
        onTap: () => Get.to(() => const ReferralScreen()),
      ),
      ServiceSearchItem(
        id: 'sv_bank',
        title: 'Bank & Account Details',
        category: 'Smart Value',
        description: 'View linked bank account, IFSC code and payouts',
        iconEmoji: '🏦',
        iconData: Icons.account_balance_rounded,
        accentColor: const Color(0xFF455A64),
        onTap: () => Get.to(() => AccountDetails()),
      ),

      // 5. MARKETPLACE & SUPPORT
      ServiceSearchItem(
        id: 'mkt_home',
        title: 'Fiinway Marketplace',
        category: 'Marketplace',
        description: 'Shop verified products, local store deals & essentials',
        iconEmoji: '🛍️',
        iconData: Icons.storefront_rounded,
        accentColor: const Color(0xFF673AB7),
        badge: 'Offers',
        onTap: () => Get.to(() => const MarketplaceHomeScreen()),
      ),
      ServiceSearchItem(
        id: 'support_help',
        title: 'Customer Support & Help',
        category: 'Smart Value',
        description: '24x7 help desk, query resolution & support chat',
        iconEmoji: '🎧',
        iconData: Icons.support_agent_rounded,
        accentColor: const Color(0xFF009688),
        onTap: () => Get.to(() => const CustomerSupportScreen()),
      ),
    ];
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final themeChange = Provider.of<DarkThemeProvider>(context);
    final isDark = themeChange.getThem();
    final allServices = _buildServicesList();

    final filteredServices = allServices.where((item) {
      final matchesCategory = _selectedCategory == 'All' || item.category == _selectedCategory;
      final query = _searchQuery.trim().toLowerCase();
      final matchesQuery = query.isEmpty ||
          item.title.toLowerCase().contains(query) ||
          item.description.toLowerCase().contains(query) ||
          item.category.toLowerCase().contains(query);
      return matchesCategory && matchesQuery;
    }).toList();

    return Scaffold(
      backgroundColor: isDark ? AppThemeData.surface50Dark : AppThemeData.surface50,
      appBar: widget.isTab
          ? null
          : AppBar(
              backgroundColor: isDark ? AppThemeData.surface50Dark : Colors.white,
              elevation: 0.5,
              title: Text(
                'Explore Services',
                style: TextStyle(
                  fontFamily: AppThemeData.semiBold,
                  fontSize: 18,
                  color: isDark ? Colors.white : AppThemeData.grey900,
                ),
              ),
              centerTitle: true,
              leading: IconButton(
                icon: Icon(
                  Icons.arrow_back_ios_new_rounded,
                  size: 20,
                  color: isDark ? Colors.white : AppThemeData.grey900,
                ),
                onPressed: () => Get.back(),
              ),
            ),
      body: SafeArea(
        top: !widget.isTab,
        child: Column(
          children: [
            // Top Search Bar Section
            Container(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
              color: isDark ? AppThemeData.surface50Dark : Colors.white,
              child: Column(
                children: [
                  Container(
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF1E2436) : const Color(0xFFF4F6F9),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: isDark ? Colors.white12 : const Color(0xFFE2E8F0),
                        width: 1,
                      ),
                    ),
                    child: TextField(
                      controller: _searchController,
                      onChanged: (val) {
                        setState(() {
                          _searchQuery = val;
                        });
                      },
                      style: TextStyle(
                        fontFamily: AppThemeData.medium,
                        fontSize: 14,
                        color: isDark ? Colors.white : AppThemeData.grey900,
                      ),
                      decoration: InputDecoration(
                        hintText: 'Search rides, home services, parcel, wallet...',
                        hintStyle: TextStyle(
                          fontFamily: AppThemeData.regular,
                          fontSize: 13,
                          color: isDark ? AppThemeData.grey500Dark : AppThemeData.grey400,
                        ),
                        prefixIcon: Icon(
                          Icons.search_rounded,
                          color: AppThemeData.primary200,
                          size: 22,
                        ),
                        suffixIcon: _searchQuery.isNotEmpty
                            ? IconButton(
                                icon: Icon(
                                  Icons.clear_rounded,
                                  size: 18,
                                  color: isDark ? Colors.white54 : AppThemeData.grey500,
                                ),
                                onPressed: () {
                                  _searchController.clear();
                                  setState(() {
                                    _searchQuery = '';
                                  });
                                },
                              )
                            : null,
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                    ),
                  ),

                  const SizedBox(height: 12),

                  // Horizontal Category Filter Chips
                  SizedBox(
                    height: 36,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      itemCount: _categories.length,
                      separatorBuilder: (context, index) => const SizedBox(width: 8),
                      itemBuilder: (context, index) {
                        final cat = _categories[index];
                        final isSelected = _selectedCategory == cat;
                        return InkWell(
                          onTap: () {
                            setState(() {
                              _selectedCategory = cat;
                            });
                          },
                          borderRadius: BorderRadius.circular(20),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? AppThemeData.primary200
                                  : isDark
                                      ? const Color(0xFF1E2436)
                                      : const Color(0xFFF1F5F9),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: isSelected
                                    ? AppThemeData.primary200
                                    : isDark
                                        ? Colors.white10
                                        : const Color(0xFFE2E8F0),
                              ),
                            ),
                            child: Center(
                              child: Text(
                                cat,
                                style: TextStyle(
                                  fontFamily: isSelected ? AppThemeData.semiBold : AppThemeData.medium,
                                  fontSize: 12,
                                  color: isSelected
                                      ? Colors.white
                                      : isDark
                                          ? AppThemeData.grey400Dark
                                          : AppThemeData.grey800,
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),

            // Services List
            Expanded(
              child: filteredServices.isEmpty
                  ? Center(
                      child: Padding(
                        padding: const EdgeInsets.all(24.0),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(20),
                              decoration: BoxDecoration(
                                color: isDark ? const Color(0xFF1E2436) : const Color(0xFFF1F5F9),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                Icons.search_off_rounded,
                                size: 48,
                                color: isDark ? Colors.white38 : AppThemeData.grey400,
                              ),
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'No matching services found',
                              style: TextStyle(
                                fontFamily: AppThemeData.semiBold,
                                fontSize: 16,
                                color: isDark ? Colors.white : AppThemeData.grey900,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              'Try searching for "Cab", "Electrician", "Parcel", or "Wallet"',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontFamily: AppThemeData.regular,
                                fontSize: 13,
                                color: isDark ? AppThemeData.grey500Dark : AppThemeData.grey500,
                              ),
                            ),
                            const SizedBox(height: 20),
                            ElevatedButton(
                              onPressed: () {
                                _searchController.clear();
                                setState(() {
                                  _searchQuery = '';
                                  _selectedCategory = 'All';
                                });
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppThemeData.primary200,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                              ),
                              child: const Text(
                                'Clear Search',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontFamily: AppThemeData.semiBold,
                                  fontSize: 13,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.fromLTRB(16, 12, 16, 120),
                      itemCount: filteredServices.length,
                      itemBuilder: (context, index) {
                        final item = filteredServices[index];
                        return _buildServiceCard(item, isDark);
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildServiceCard(ServiceSearchItem item, bool isDark) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E2436) : Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: isDark ? Colors.white10 : const Color(0xFFEBF0F7),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: isDark ? Colors.black.withValues(alpha: 0.2) : const Color(0xFF2C5CE6).withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(18),
        child: InkWell(
          onTap: item.onTap,
          borderRadius: BorderRadius.circular(18),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
            child: Row(
              children: [
                // Icon Avatar
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: item.accentColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Center(
                    child: item.iconData != null
                        ? Icon(item.iconData, color: item.accentColor, size: 24)
                        : Text(
                            item.iconEmoji,
                            style: const TextStyle(fontSize: 22),
                          ),
                  ),
                ),

                const SizedBox(width: 14),

                // Title, Category & Description
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              item.title,
                              style: TextStyle(
                                fontFamily: AppThemeData.semiBold,
                                fontSize: 14.5,
                                color: isDark ? Colors.white : AppThemeData.grey900,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (item.badge != null) ...[
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                              decoration: BoxDecoration(
                                color: item.accentColor.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                item.badge!,
                                style: TextStyle(
                                  fontFamily: AppThemeData.semiBold,
                                  fontSize: 10,
                                  color: item.accentColor,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 3),
                      Text(
                        item.description,
                        style: TextStyle(
                          fontFamily: AppThemeData.regular,
                          fontSize: 12,
                          color: isDark ? AppThemeData.grey500Dark : AppThemeData.grey500,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),

                const SizedBox(width: 8),

                // Arrow Action
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF283049) : const Color(0xFFF1F5F9),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.arrow_forward_ios_rounded,
                    size: 13,
                    color: isDark ? Colors.white70 : AppThemeData.grey500,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
