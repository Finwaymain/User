import 'dart:async';
import 'dart:convert';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';

import '../../../constant/constant.dart';
import '../../../model/banner_model.dart';
import '../../../service/api.dart';

class HomeBannerSlider extends StatefulWidget {
  final String appType; // 'user' or 'driver'
  final EdgeInsetsGeometry padding;

  const HomeBannerSlider({
    super.key,
    this.appType = 'user',
    this.padding = const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
  });

  @override
  State<HomeBannerSlider> createState() => _HomeBannerSliderState();
}

class _HomeBannerSliderState extends State<HomeBannerSlider> {
  final PageController _pageController = PageController();
  List<BannerModelData> _banners = [];
  bool _isLoading = true;
  int _currentPage = 0;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _fetchBanners();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _pageController.dispose();
    super.dispose();
  }

  void _startAutoSlide() {
    _timer?.cancel();
    if (_banners.length <= 1) return;
    _timer = Timer.periodic(const Duration(seconds: 4), (timer) {
      if (!mounted || !_pageController.hasClients || _banners.isEmpty) return;
      int nextPage = _currentPage + 1;
      if (nextPage >= _banners.length) {
        nextPage = 0;
      }
      _pageController.animateToPage(
        nextPage,
        duration: const Duration(milliseconds: 600),
        curve: Curves.easeInOutCubic,
      );
    });
  }

  Future<void> _fetchBanners() async {
    try {
      final url = "${API.baseUrl}get-banners?app=${widget.appType}";
      final response = await http.get(Uri.parse(url), headers: API.header);

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        if (data['success'] == 'success' && data['data'] != null) {
          final List list = data['data'];
          if (mounted) {
            setState(() {
              _banners = list.map((v) => BannerModelData.fromJson(v)).toList();
              _isLoading = false;
            });
            _startAutoSlide();
            return;
          }
        }
      }
    } catch (e) {
      debugPrint("Error fetching banners: $e");
    }

    if (mounted) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _onBannerTap(BannerModelData banner) async {
    final link = (banner.link ?? '').trim();
    if (link.isEmpty) return;

    try {
      Uri uri = Uri.parse(link);
      if (!uri.hasScheme) {
        uri = Uri.parse("https://$link");
      }

      final userData = Constant.getUserData();
      final phone = userData.data?.phone ?? '';
      final userId = userData.data?.id?.toString() ?? '';
      final name = '${userData.data?.prenom ?? ''} ${userData.data?.nom ?? ''}'.trim();

      final queryParams = Map<String, String>.from(uri.queryParameters);
      if (phone.isNotEmpty) queryParams['phone'] = phone;
      if (userId.isNotEmpty) queryParams['user_id'] = userId;
      if (name.isNotEmpty) queryParams['name'] = name;

      final targetUri = uri.replace(queryParameters: queryParams);

      if (await canLaunchUrl(targetUri)) {
        await launchUrl(targetUri, mode: LaunchMode.externalApplication);
      } else {
        await launchUrl(targetUri);
      }
    } catch (e) {
      debugPrint("Could not launch banner url ($link): $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Padding(
        padding: widget.padding,
        child: Container(
          height: 140,
          decoration: BoxDecoration(
            color: Colors.grey.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(16),
          ),
        ),
      );
    }

    if (_banners.isEmpty) {
      return const SizedBox.shrink();
    }

    return Padding(
      padding: widget.padding,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            height: 140,
            child: PageView.builder(
              controller: _pageController,
              itemCount: _banners.length,
              onPageChanged: (index) {
                setState(() {
                  _currentPage = index;
                });
                _startAutoSlide();
              },
              itemBuilder: (context, index) {
                final banner = _banners[index];
                return Semantics(
                  label: banner.alt ?? banner.title ?? "Banner",
                  button: banner.link != null && banner.link!.isNotEmpty,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(16),
                    onTap: () => _onBannerTap(banner),
                    child: Container(
                      margin: const EdgeInsets.symmetric(horizontal: 2),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.06),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(16),
                        child: banner.image != null && banner.image!.isNotEmpty
                            ? CachedNetworkImage(
                                imageUrl: banner.image!,
                                fit: BoxFit.cover,
                                width: double.infinity,
                                height: 140,
                                placeholder: (context, url) => Container(
                                  color: Colors.grey.withValues(alpha: 0.1),
                                  child: const Center(
                                    child: SizedBox(
                                      width: 24,
                                      height: 24,
                                      child: CircularProgressIndicator(strokeWidth: 2),
                                    ),
                                  ),
                                ),
                                errorWidget: (context, url, error) => Container(
                                  color: Colors.grey.withValues(alpha: 0.12),
                                  alignment: Alignment.center,
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      const Icon(Icons.image_outlined, size: 36, color: Colors.grey),
                                      if ((banner.alt ?? banner.title) != null) ...[
                                        const SizedBox(height: 6),
                                        Text(
                                          banner.alt ?? banner.title!,
                                          style: const TextStyle(fontSize: 12, color: Colors.grey),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ],
                                    ],
                                  ),
                                ),
                              )
                            : Container(
                                color: Colors.grey.withValues(alpha: 0.12),
                                alignment: Alignment.center,
                                child: Text(banner.alt ?? banner.title ?? "Banner"),
                              ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          if (_banners.length > 1) ...[
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(_banners.length, (index) {
                final bool isActive = _currentPage == index;
                return AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  margin: const EdgeInsets.symmetric(horizontal: 3),
                  width: isActive ? 18 : 6,
                  height: 5,
                  decoration: BoxDecoration(
                    color: isActive
                        ? Theme.of(context).primaryColor
                        : Colors.grey.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(3),
                  ),
                );
              }),
            ),
          ],
        ],
      ),
    );
  }
}
