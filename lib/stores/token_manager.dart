import 'package:hm_shop/constants/index.dart';
import 'package:shared_preferences/shared_preferences.dart';

class TokenManager {
  Future<SharedPreferences> _getInstance() async {
    return await SharedPreferences.getInstance();
  }

  String _token = '';
  // 初始化
  Future<void> init() async {
    final prefs = await _getInstance();
    _token = prefs.getString(GlobalConstants.tokenKey) ?? '';
  }

  // 设置 token
  Future<void> setToken(String token) async {
    final prefs = await _getInstance();
    prefs.setString(GlobalConstants.tokenKey, token);
    _token = token;
  }

  // 获取 token
  String getToken() {
    return _token;
  }

  // 清除 token
  Future<void> removeToken() async {
    final prefs = await _getInstance();
    prefs.remove(GlobalConstants.tokenKey);
    _token = '';
  }
}

final tokenManager = TokenManager();
