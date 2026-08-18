import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../constant/constant.dart';
import '../../controller/support_chat_controller.dart';
import '../../model/support_chat_model.dart';
import '../../themes/constant_colors.dart';
import '../../utils/dark_theme_provider.dart';

class SupportChatScreen extends StatelessWidget {
  final String userType;

  const SupportChatScreen({super.key, this.userType = 'customer'});

  @override
  Widget build(BuildContext context) {
    final themeChange = Provider.of<DarkThemeProvider>(context);
    final isDark = themeChange.getThem();

    final bgColor = isDark ? AppThemeData.surface50Dark : const Color(0xFFF8FAFC);
    final cardBg = isDark ? AppThemeData.grey800 : Colors.white;
    final textColor = isDark ? AppThemeData.grey50Dark : AppThemeData.grey900;
    final mutedColor = isDark ? AppThemeData.grey500Dark : AppThemeData.grey500;
    final borderColor = isDark
        ? AppThemeData.grey300Dark.withValues(alpha: 0.3)
        : AppThemeData.grey300.withValues(alpha: 0.5);

    final controller = Get.put(SupportChatController(userType: userType));

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: cardBg,
        elevation: 0.5,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded, color: textColor, size: 20),
          onPressed: () => Get.back(),
        ),
        titleSpacing: 0,
        title: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [AppThemeData.primary200, AppThemeData.primary400],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                shape: BoxShape.circle,
              ),
              child: const Center(
                child: Icon(Icons.headset_mic_rounded, color: Colors.white, size: 22),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Fiinway Support'.tr,
                    style: TextStyle(
                      color: textColor,
                      fontSize: 16,
                      fontFamily: AppThemeData.bold,
                    ),
                  ),
                  Row(
                    children: [
                      Container(
                        width: 7,
                        height: 7,
                        decoration: const BoxDecoration(
                          color: Color(0xFF10B981),
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 5),
                      Text(
                        'Online • Replies within minutes'.tr,
                        style: const TextStyle(
                          color: Color(0xFF10B981),
                          fontSize: 11,
                          fontFamily: AppThemeData.medium,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      body: Obx(() {
        if (controller.isLoading.value) {
          return Center(
            child: CircularProgressIndicator(color: AppThemeData.primary200),
          );
        }

        return Column(
          children: [
            // Quick Questions Horizontal Carousel
            if (controller.quickQuestions.isNotEmpty)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  color: cardBg,
                  border: Border(bottom: BorderSide(color: borderColor)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                      child: Row(
                        children: [
                          Icon(Icons.help_outline_rounded, size: 14, color: AppThemeData.primary200),
                          const SizedBox(width: 6),
                          Text(
                            'Quick Questions (Tap to ask)'.tr,
                            style: TextStyle(
                              fontSize: 12,
                              color: mutedColor,
                              fontFamily: AppThemeData.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 6),
                    SizedBox(
                      height: 38,
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        itemCount: controller.quickQuestions.length,
                        separatorBuilder: (_, __) => const SizedBox(width: 8),
                        itemBuilder: (context, index) {
                          final q = controller.quickQuestions[index];
                          return ActionChip(
                            elevation: 0,
                            pressElevation: 1,
                            backgroundColor: isDark ? AppThemeData.grey700 : const Color(0xFFEEF2F6),
                            side: BorderSide(color: AppThemeData.primary200.withValues(alpha: 0.3)),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                            label: Text(
                              q.question,
                              style: TextStyle(
                                fontSize: 12,
                                color: textColor,
                                fontFamily: AppThemeData.medium,
                              ),
                            ),
                            onPressed: () => controller.onQuestionSelected(q),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),

            // Messages List Area
            Expanded(
              child: controller.messages.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(18),
                            decoration: BoxDecoration(
                              color: AppThemeData.primary200.withValues(alpha: 0.1),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(Icons.forum_outlined, size: 40, color: AppThemeData.primary200),
                          ),
                          const SizedBox(height: 14),
                          Text(
                            'How can we help you?'.tr,
                            style: TextStyle(
                              fontSize: 17,
                              fontFamily: AppThemeData.bold,
                              color: textColor,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'Tap a quick question above or send a message below.'.tr,
                            style: TextStyle(fontSize: 13, color: mutedColor),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      controller: controller.scrollController,
                      padding: const EdgeInsets.all(16),
                      itemCount: controller.messages.length,
                      itemBuilder: (context, index) {
                        final msg = controller.messages[index];
                        return _buildMessageBubble(msg, isDark, textColor, mutedColor);
                      },
                    ),
            ),

            // Bottom Input Bar
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: cardBg,
                border: Border(top: BorderSide(color: borderColor)),
              ),
              child: SafeArea(
                child: Row(
                  children: [
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        decoration: BoxDecoration(
                          color: isDark ? AppThemeData.grey700 : const Color(0xFFF1F5F9),
                          borderRadius: BorderRadius.circular(24),
                        ),
                        child: TextField(
                          controller: controller.messageInputController,
                          style: TextStyle(color: textColor, fontSize: 14),
                          maxLines: 4,
                          minLines: 1,
                          textCapitalization: TextCapitalization.sentences,
                          decoration: InputDecoration(
                            hintText: 'Type your message...'.tr,
                            hintStyle: TextStyle(color: mutedColor, fontSize: 14),
                            border: InputBorder.none,
                            isDense: true,
                            contentPadding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Obx(
                      () => InkWell(
                        onTap: controller.isSending.value
                            ? null
                            : () => controller.sendUserMessage(),
                        borderRadius: BorderRadius.circular(24),
                        child: Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [AppThemeData.primary200, AppThemeData.primary400],
                            ),
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: AppThemeData.primary200.withValues(alpha: 0.3),
                                blurRadius: 8,
                                offset: const Offset(0, 3),
                              ),
                            ],
                          ),
                          child: Center(
                            child: controller.isSending.value
                                ? const SizedBox(
                                    width: 18,
                                    height: 18,
                                    child: CircularProgressIndicator(
                                      color: Colors.white,
                                      strokeWidth: 2,
                                    ),
                                  )
                                : const Icon(Icons.send_rounded, color: Colors.white, size: 20),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        );
      }),
    );
  }

  Widget _buildMessageBubble(
    SupportMessageModel msg,
    bool isDark,
    Color textColor,
    Color mutedColor,
  ) {
    final isAdmin = msg.isAdmin;
    final timeStr = _formatMessageTime(msg.createdAt);

    return Align(
      alignment: isAdmin ? Alignment.centerLeft : Alignment.centerRight,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        constraints: BoxConstraints(maxWidth: Get.width * 0.78),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: isAdmin
              ? (isDark ? AppThemeData.grey700 : Colors.white)
              : AppThemeData.primary200,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(16),
            topRight: const Radius.circular(16),
            bottomLeft: Radius.circular(isAdmin ? 2 : 16),
            bottomRight: Radius.circular(isAdmin ? 16 : 2),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
          border: isAdmin
              ? Border.all(
                  color: isDark
                      ? AppThemeData.grey300Dark.withValues(alpha: 0.2)
                      : const Color(0xFFE2E8F0),
                )
              : null,
        ),
        child: Column(
          crossAxisAlignment:
              isAdmin ? CrossAxisAlignment.start : CrossAxisAlignment.end,
          children: [
            if (isAdmin)
              Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.verified_user_rounded,
                        size: 12, color: AppThemeData.primary200),
                    const SizedBox(width: 4),
                    Text(
                      msg.senderName.isNotEmpty ? msg.senderName : 'Support Agent',
                      style: TextStyle(
                        fontSize: 11,
                        fontFamily: AppThemeData.bold,
                        color: AppThemeData.primary200,
                      ),
                    ),
                  ],
                ),
              ),
            Text(
              msg.message,
              style: TextStyle(
                fontSize: 14,
                color: isAdmin ? textColor : Colors.white,
                height: 1.35,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              timeStr,
              style: TextStyle(
                fontSize: 10,
                color: isAdmin ? mutedColor : Colors.white70,
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatMessageTime(String? dateStr) {
    if (dateStr == null || dateStr.isEmpty) return '';
    try {
      final dt = DateTime.parse(dateStr).toLocal();
      return DateFormat('hh:mm a').format(dt);
    } catch (_) {
      return '';
    }
  }
}
