import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';

import '../../constant/constant.dart';
import '../../service/api.dart';
import '../../themes/constant_colors.dart';
import '../../utils/dark_theme_provider.dart';
import 'package:provider/provider.dart';
import 'support_chat_screen.dart';

class CustomerSupportScreen extends StatefulWidget {
  const CustomerSupportScreen({super.key});

  @override
  State<CustomerSupportScreen> createState() => _CustomerSupportScreenState();
}

class _CustomerSupportScreenState extends State<CustomerSupportScreen> {
  String whatsappNumber = '9429693669';
  String callNumber = '9429693669';
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchSupportNumbers();
  }

  Future<void> _fetchSupportNumbers() async {
    try {
      final response = await http.get(
        Uri.parse('${API.baseUrl}customer-care'),
        headers: API.header,
      );
      if (response.statusCode == 200) {
        final body = json.decode(response.body);
        if (body['success'] == 'success' && body['data'] != null) {
          final custApp = body['data']['customer_app'];
          if (custApp != null) {
            setState(() {
              if (custApp['whatsapp_number'] != null && custApp['whatsapp_number'].toString().trim().isNotEmpty) {
                whatsappNumber = custApp['whatsapp_number'].toString().trim();
              }
              if (custApp['call_number'] != null && custApp['call_number'].toString().trim().isNotEmpty) {
                callNumber = custApp['call_number'].toString().trim();
              }
            });
          }
        }
      }
    } catch (e) {
      debugPrint('Error fetching customer care numbers: $e');
    } finally {
      if (mounted) {
        setState(() => isLoading = false);
      }
    }
  }

  Future<void> _openWhatsApp() async {
    final cleanPhone = whatsappNumber.replaceAll(RegExp(r'[^\d+]'), '');
    final whatsappUri = Uri.parse("https://wa.me/$cleanPhone");
    try {
      if (await canLaunchUrl(whatsappUri)) {
        await launchUrl(whatsappUri, mode: LaunchMode.externalApplication);
      } else {
        final fallbackUri = Uri.parse("whatsapp://send?phone=$cleanPhone");
        if (await canLaunchUrl(fallbackUri)) {
          await launchUrl(fallbackUri, mode: LaunchMode.externalApplication);
        } else {
          Get.snackbar('WhatsApp Not Installed'.tr, 'Please install WhatsApp to chat with customer support.'.tr);
        }
      }
    } catch (e) {
      Get.snackbar('Error'.tr, 'Could not launch WhatsApp.'.tr);
    }
  }

  Future<void> _makeCall() async {
    await Constant.makePhoneCall(callNumber);
  }

  @override
  Widget build(BuildContext context) {
    final themeChange = Provider.of<DarkThemeProvider>(context);
    final isDark = themeChange.getThem();

    final bgColor = isDark ? AppThemeData.surface50Dark : AppThemeData.surface50;
    final cardBg = isDark ? AppThemeData.grey800 : Colors.white;
    final textColor = isDark ? AppThemeData.grey50Dark : AppThemeData.grey900;
    final mutedColor = isDark ? AppThemeData.grey500Dark : AppThemeData.grey500;
    final borderColor = isDark ? AppThemeData.grey300Dark.withValues(alpha: 0.4) : AppThemeData.grey300.withValues(alpha: 0.5);

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: cardBg,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded, color: textColor, size: 20),
          onPressed: () => Get.back(),
        ),
        title: Text(
          'Customer Support'.tr,
          style: TextStyle(
            color: textColor,
            fontSize: 18,
            fontFamily: AppThemeData.bold,
          ),
        ),
      ),
      body: isLoading
          ? Center(child: CircularProgressIndicator(color: AppThemeData.primary200))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Hero Card
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [AppThemeData.primary200, AppThemeData.primary200],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: AppThemeData.primary200.withValues(alpha: 0.3),
                          blurRadius: 15,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.headset_mic_rounded, color: Colors.white, size: 14),
                              const SizedBox(width: 6),
                              Text(
                                '24/7 Support Available'.tr,
                                style: const TextStyle(color: Colors.white, fontSize: 11, fontFamily: AppThemeData.bold),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 14),
                        Text(
                          'How can we help you today?'.tr,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 22,
                            fontFamily: AppThemeData.bold,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Reach out to our customer care team via WhatsApp chat or phone call for quick assistance.'.tr,
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 13,
                            height: 1.4,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 28),

                  Text(
                    'Contact Options'.tr,
                    style: TextStyle(
                      fontSize: 15,
                      fontFamily: AppThemeData.bold,
                      color: textColor,
                    ),
                  ),

                  const SizedBox(height: 14),

                  // Option 0: Live Chat Support
                  Card(
                    elevation: 0,
                    color: cardBg,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                      side: BorderSide(color: AppThemeData.primary200.withValues(alpha: 0.4)),
                    ),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(16),
                      onTap: () => Get.to(() => const SupportChatScreen(userType: 'customer')),
                      child: Padding(
                        padding: const EdgeInsets.all(18),
                        child: Row(
                          children: [
                            Container(
                              width: 52,
                              height: 52,
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [AppThemeData.primary200, AppThemeData.primary400],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                ),
                                borderRadius: BorderRadius.circular(14),
                                boxShadow: [
                                  BoxShadow(
                                    color: AppThemeData.primary200.withValues(alpha: 0.25),
                                    blurRadius: 8,
                                    offset: const Offset(0, 3),
                                  ),
                                ],
                              ),
                              child: const Icon(
                                Icons.forum_rounded,
                                color: Colors.white,
                                size: 26,
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Text(
                                        'Chat with Support Team'.tr,
                                        style: TextStyle(
                                          fontSize: 16,
                                          fontFamily: AppThemeData.bold,
                                          color: textColor,
                                        ),
                                      ),
                                      const SizedBox(width: 6),
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                        decoration: BoxDecoration(
                                          color: const Color(0xFF10B981).withValues(alpha: 0.15),
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                        child: Text(
                                          'Online'.tr,
                                          style: const TextStyle(
                                            color: Color(0xFF10B981),
                                            fontSize: 10,
                                            fontFamily: AppThemeData.bold,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'Realtime live chat • Instant answers'.tr,
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: mutedColor,
                                      fontFamily: AppThemeData.medium,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: AppThemeData.primary200,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: const Icon(Icons.arrow_forward_rounded, color: Colors.white, size: 18),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 14),

                  // Option 1: WhatsApp Support
                  Card(
                    elevation: 0,
                    color: cardBg,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                      side: BorderSide(color: borderColor),
                    ),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(16),
                      onTap: _openWhatsApp,
                      child: Padding(
                        padding: const EdgeInsets.all(18),
                        child: Row(
                          children: [
                            Container(
                              width: 52,
                              height: 52,
                              decoration: BoxDecoration(
                                color: const Color(0xFF25D366).withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(14),
                              ),
                              child: const Icon(
                                Icons.chat_rounded,
                                color: Color(0xFF25D366),
                                size: 28,
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'WhatsApp Chat'.tr,
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontFamily: AppThemeData.bold,
                                      color: textColor,
                                    ),
                                  ),

                                ],
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: const Color(0xFF25D366),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: const Icon(Icons.arrow_forward_rounded, color: Colors.white, size: 18),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 14),

                  // Option 2: Call Support
                  Card(
                    elevation: 0,
                    color: cardBg,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                      side: BorderSide(color: borderColor),
                    ),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(16),
                      onTap: _makeCall,
                      child: Padding(
                        padding: const EdgeInsets.all(18),
                        child: Row(
                          children: [
                            Container(
                              width: 52,
                              height: 52,
                              decoration: BoxDecoration(
                                color: AppThemeData.primary200.withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(14),
                              ),
                              child: Icon(
                                Icons.phone_in_talk_rounded,
                                color: AppThemeData.primary200,
                                size: 28,
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Call Support'.tr,
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontFamily: AppThemeData.bold,
                                      color: textColor,
                                    ),
                                  ),

                                ],
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: AppThemeData.primary200,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: const Icon(Icons.arrow_forward_rounded, color: Colors.white, size: 18),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 30),

                  // Info Note
                  Center(
                    child: Text(
                      'Fiinway Customer Care • Always Here to Help'.tr,
                      style: TextStyle(
                        fontSize: 12,
                        color: mutedColor,
                        fontFamily: AppThemeData.medium,
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}
