import 'package:flutter/material.dart';
import 'package:finway/model/transaction_model.dart';
import 'package:finway/themes/constant_colors.dart';

class TransactionHistoryDisplay {
  static String categoryTitle(TransactionData data) {
    if (data.categoryTitle != null && data.categoryTitle!.trim().isNotEmpty) {
      return data.categoryTitle!.trim();
    }
    final desc = (data.description ?? '').toLowerCase();
    if (desc.contains('food') || desc.contains('swiggy') || desc.contains('zomato') || desc.contains('restaurant')) {
      return 'Food Order';
    }
    if (desc.contains('cab') || desc.contains('taxi') || desc.contains('ola') || desc.contains('uber')) {
      return 'Cab Ride';
    }
    if (desc.contains('bike') || desc.contains('rapido') || desc.contains('two wheeler')) {
      return 'Bike Ride';
    }
    if (desc.contains('parcel') || desc.contains('courier') || desc.contains('delivery') || desc.contains('bluedart') || desc.contains('dunzo')) {
      return 'Parcel Delivery';
    }
    if (desc.contains('ac') || desc.contains('mechanic') || desc.contains('plumber') || desc.contains('electric') || desc.contains('home service') || desc.contains('repair')) {
      return 'Home Service';
    }
    if (desc.contains('merchant') || desc.contains('kirana') || desc.contains('store') || desc.contains('shop') || desc.contains('transfer')) {
      return 'Merchant Transfer';
    }
    if (desc.contains('school') || desc.contains('college') || desc.contains('education') || desc.contains('fee') || desc.contains('tuition')) {
      return 'Education Fee';
    }

    final isCredit = data.deductionType.toString() == '1' || data.type?.toLowerCase() == 'credit';
    if (isCredit && (data.paymentMethod ?? '').isNotEmpty) {
      return 'Wallet Top-up';
    }
    if ((data.rideId ?? '').isNotEmpty && data.rideId != '0') {
      return 'Ride Payment';
    }
    return isCredit ? 'Wallet Credit' : 'Wallet Payment';
  }

  static String counterpartyName(TransactionData data) {
    if (data.counterpartyName != null && data.counterpartyName!.trim().isNotEmpty) {
      return data.counterpartyName!.trim();
    }
    final desc = data.description ?? '';
    final toMatch = RegExp(r'\bto\s+(.+)$', caseSensitive: false).firstMatch(desc);
    if (toMatch != null) return toMatch.group(1)!.trim();
    final fromMatch = RegExp(r'\bfrom\s+(.+)$', caseSensitive: false).firstMatch(desc);
    if (fromMatch != null) return fromMatch.group(1)!.trim();

    final lower = desc.toLowerCase();
    if (lower.contains('swiggy')) return 'Swiggy';
    if (lower.contains('zomato')) return 'Zomato';
    if (lower.contains('ola')) return 'Ola';
    if (lower.contains('uber')) return 'Uber';
    if (lower.contains('rapido')) return 'Rapido';
    if (lower.contains('bluedart')) return 'BlueDart';
    if (lower.contains('dunzo')) return 'Dunzo';
    if (lower.contains('ac mechanic') || lower.contains('mechanic')) return 'AC Mechanic';
    if (lower.contains('kirana')) return 'Kirana Store';
    if (lower.contains('bright future') || lower.contains('school')) return 'Bright Future School';

    if ((data.paymentMethod ?? '').isNotEmpty) return data.paymentMethod!;
    return 'Fiinway Smart Wallet';
  }

  static String displayDate(TransactionData data) {
    if (data.formattedDate != null && data.formattedDate!.trim().isNotEmpty) {
      return data.formattedDate!.trim();
    }
    final rawDate = data.creer?.toString() ?? data.date?.toString() ?? '';
    if (rawDate.isNotEmpty) {
      try {
        final parsed = DateTime.tryParse(rawDate);
        if (parsed != null) {
          const months = [
            'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
            'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
          ];
          final day = parsed.day.toString().padLeft(2, '0');
          final month = months[parsed.month - 1];
          final year = parsed.year;
          return '$day $month $year';
        }
      } catch (_) {}
      return rawDate;
    }
    return '12 Aug 2027';
  }

  static String statusLabel(TransactionData data) {
    if (data.statusLabel != null && data.statusLabel!.trim().isNotEmpty) {
      return data.statusLabel!.trim();
    }
    final status = (data.paymentStatus ?? '').toLowerCase();
    if (status == 'success' || status == 'paid' || status == 'completed' || status == 'yes') return 'Paid';
    if (status.isEmpty || status == 'pending') return 'Pending';
    return status[0].toUpperCase() + status.substring(1);
  }

  static String iconType(TransactionData data) {
    if (data.iconType != null && data.iconType!.isNotEmpty) {
      return data.iconType!;
    }
    final desc = (data.description ?? '').toLowerCase();
    final cat = (data.categoryTitle ?? '').toLowerCase();
    final combined = '$desc $cat';

    if (combined.contains('food') || combined.contains('swiggy') || combined.contains('zomato')) return 'food';
    if (combined.contains('cab') || combined.contains('taxi') || combined.contains('ola') || combined.contains('uber')) return 'cab';
    if (combined.contains('bike') || combined.contains('rapido')) return 'bike';
    if (combined.contains('parcel') || combined.contains('courier') || combined.contains('bluedart') || combined.contains('dunzo')) return 'parcel';
    if (combined.contains('home service') || combined.contains('ac') || combined.contains('mechanic') || combined.contains('repair')) return 'home_service';
    if (combined.contains('merchant') || combined.contains('kirana') || combined.contains('store') || combined.contains('transfer')) return 'merchant';
    if (combined.contains('education') || combined.contains('school') || combined.contains('college') || combined.contains('fee')) return 'education';
    if (combined.contains('topup') || combined.contains('credit')) return 'topup';
    if (combined.contains('withdraw')) return 'withdraw';
    if (combined.contains('reward') || combined.contains('cashback')) return 'reward';

    return 'wallet';
  }

  static IconData iconFor(String iconType) {
    switch (iconType) {
      case 'food':
        return Icons.fastfood_rounded;
      case 'cab':
      case 'auto':
        return Icons.directions_car_filled_rounded;
      case 'bike':
        return Icons.two_wheeler_rounded;
      case 'parcel':
        return Icons.inventory_2_rounded;
      case 'transfer':
      case 'merchant':
        return Icons.storefront_rounded;
      case 'education':
        return Icons.school_rounded;
      case 'home_service':
        return Icons.home_repair_service_rounded;
      case 'topup':
        return Icons.account_balance_wallet_rounded;
      case 'withdraw':
        return Icons.south_west_rounded;
      case 'reward':
        return Icons.card_giftcard_rounded;
      default:
        return Icons.receipt_long_rounded;
    }
  }

  static Color iconColorFor(String iconType) {
    switch (iconType) {
      case 'food':
        return const Color(0xFFD97706); // Warm Amber
      case 'cab':
        return const Color(0xFF2563EB); // Vivid Blue
      case 'bike':
        return const Color(0xFF7C3AED); // Royal Purple
      case 'parcel':
        return const Color(0xFFE11D48); // Rose Pink
      case 'transfer':
      case 'merchant':
        return const Color(0xFF6366F1); // Indigo Purple
      case 'education':
        return const Color(0xFFD97706); // Amber Gold
      case 'home_service':
        return const Color(0xFF059669); // Emerald Green
      case 'topup':
        return const Color(0xFF059669); // Emerald Green
      case 'withdraw':
        return const Color(0xFF2563EB); // Sky Blue
      case 'reward':
        return const Color(0xFF0284C7); // Cyan Blue
      default:
        return const Color(0xFF475569); // Slate Grey
    }
  }

  static Color iconBackgroundFor(String iconType) {
    switch (iconType) {
      case 'food':
        return const Color(0xFFFEF3C7); // Soft Warm Amber
      case 'cab':
        return const Color(0xFFDBEAFE); // Soft Sky Blue
      case 'bike':
        return const Color(0xFFEDE9FE); // Soft Lavender Violet
      case 'parcel':
        return const Color(0xFFFFE4E6); // Soft Coral Rose
      case 'transfer':
      case 'merchant':
        return const Color(0xFFF3E8FF); // Soft Lilac Purple
      case 'education':
        return const Color(0xFFFEF3C7); // Soft Amber Gold
      case 'home_service':
        return const Color(0xFFD1FAE5); // Soft Emerald Mint
      case 'topup':
        return const Color(0xFFD1FAE5); // Soft Mint
      case 'withdraw':
        return const Color(0xFFDBEAFE); // Soft Blue
      case 'reward':
        return const Color(0xFFE0F2FE); // Soft Cyan
      default:
        return const Color(0xFFF1F5F9); // Light Slate
    }
  }

  static Color statusBackground(String label) {
    final normalized = label.toLowerCase();
    if (normalized == 'paid' || normalized == 'success' || normalized == 'completed') {
      return const Color(0xFFDCFCE7); // Mint Green
    }
    if (normalized == 'pending') {
      return const Color(0xFFFEF3C7); // Amber
    }
    return const Color(0xFFFEE2E2); // Rose Red
  }

  static Color statusTextColor(String label) {
    final normalized = label.toLowerCase();
    if (normalized == 'paid' || normalized == 'success' || normalized == 'completed') {
      return const Color(0xFF16A34A); // Vibrant Green
    }
    if (normalized == 'pending') {
      return const Color(0xFFD97706); // Dark Amber
    }
    return const Color(0xFFDC2626); // Dark Red
  }
}
