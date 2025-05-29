import 'package:shared_preferences/shared_preferences.dart';

class LaunchService {
  static Future<bool> isFirstLaunch() async {
    final prefs = await SharedPreferences.getInstance();
    final isFirst = prefs.getBool('isFirstLaunch');
    if (isFirst == null || isFirst) {
      await prefs.setBool('isFirstLaunch', false);
      return true;
    }
    return false;
  }
}