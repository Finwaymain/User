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
    if (fromPrefs.isNotEmpty) return fromPrefs;
    final intId = Preferences.getInt(Preferences.userId);
    if (intId != 0) return intId.toString();
    return Constant.getUserData().data?.id?.toString() ?? '';
  }

  static String build(
    String path, {
    Map<String, String> extra = const {},
  }) {
    final params = <String, String>{
      'accesstoken': accessToken(),
      'user_id': userId(),
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
