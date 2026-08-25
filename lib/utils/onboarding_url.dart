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

  static String build(
    String path, {
    Map<String, String> extra = const {},
  }) {
    final params = <String, String>{
      'accesstoken': accessToken(),
      'user_id': userId(),
      'id_user': userId(),
      'phone': phone(),
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
