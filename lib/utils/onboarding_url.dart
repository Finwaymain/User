import 'dart:convert';
import '../constant/constant.dart';
import 'Preferences.dart';

class OnboardingUrl {
  static const String baseHost = 'https://api.fiinway.com';

  static String accessToken() {
    final fromPrefs = Preferences.getString(Preferences.accesstoken);
    if (fromPrefs.isNotEmpty) return fromPrefs;
    return Constant.getUserData().data?.accesstoken ?? '';
  }

  static String userId() {
    final fromPrefs = Preferences.getString(Preferences.userId);
    if (fromPrefs.isNotEmpty && fromPrefs != "0") return fromPrefs;
    final intId = Preferences.getInt(Preferences.userId);
    if (intId != 0) return intId.toString();
    return Constant.getUserData().data?.id?.toString() ?? '';
  }

  static String phone() {
    final fromUser = Constant.getUserData().data?.phone ?? '';
    if (fromUser.isNotEmpty) return fromUser;
    final userStr = Preferences.getString(Preferences.user);
    if (userStr.isNotEmpty) {
      try {
        final map = jsonDecode(userStr);
        return (map['phone'] ?? map['data']?['phone'] ?? '').toString();
      } catch (_) {}
    }
    return '';
  }

  static String userName() {
    final user = Constant.getUserData().data;
    if (user != null) {
      final prenom = user.prenom ?? '';
      final nom = user.nom ?? '';
      final full = '$prenom $nom'.trim();
      if (full.isNotEmpty) return full;
    }
    final userStr = Preferences.getString(Preferences.user);
    if (userStr.isNotEmpty) {
      try {
        final map = jsonDecode(userStr);
        final name = (map['name'] ?? map['data']?['name'] ?? map['prenom'] ?? map['data']?['prenom'] ?? '').toString();
        if (name.isNotEmpty) return name;
      } catch (_) {}
    }
    return '';
  }

  static String walletBalance() {
    final user = Constant.getUserData().data;
    if (user != null && user.amount != null) {
      return user.amount.toString();
    }
    final userStr = Preferences.getString(Preferences.user);
    if (userStr.isNotEmpty) {
      try {
        final map = jsonDecode(userStr);
        final amt = (map['amount'] ?? map['data']?['amount'] ?? '').toString();
        if (amt.isNotEmpty) return amt;
      } catch (_) {}
    }
    return '0';
  }

  static String pocketNumber() {
    final user = Constant.getUserData().data;
    if (user != null && (user.acNo?.isNotEmpty ?? false)) {
      return user.acNo!;
    }
    final userStr = Preferences.getString(Preferences.user);
    if (userStr.isNotEmpty) {
      try {
        final map = jsonDecode(userStr);
        final ac = (map['ac_no'] ?? map['data']?['ac_no'] ?? map['pocket_number'] ?? map['data']?['pocket_number'] ?? '').toString();
        if (ac.isNotEmpty) return ac;
      } catch (_) {}
    }
    return '';
  }

  static String build(
    String path, {
    Map<String, String> extra = const {},
  }) {
    final params = <String, String>{
      'accesstoken': accessToken(),
      'token': accessToken(),
      'user_id': userId(),
      'id_user': userId(),
      'phone': phone(),
      'mobile': phone(),
      'name': userName(),
      'username': userName(),
      'customer_name': userName(),
      'wallet_balance': walletBalance(),
      'balance': walletBalance(),
      'pocket_number': pocketNumber(),
      'ac_no': pocketNumber(),
      'acNo': pocketNumber(),
      'user_type': 'customer',
      'user_cat': 'customer',
      ...extra,
    };

    final query = params.entries
        .where((entry) => entry.value.isNotEmpty)
        .map(
          (entry) =>
              '${Uri.encodeComponent(entry.key)}=${Uri.encodeComponent(entry.value)}',
        )
        .join('&');

    final normalizedPath = path.startsWith('/') ? path : '/$path';
    return query.isEmpty ? '$baseHost$normalizedPath' : '$baseHost$normalizedPath?$query';
  }
}
