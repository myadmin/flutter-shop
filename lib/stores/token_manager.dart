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
    _token = token;
    // 必须 await，否则方法返回时 token 尚未落盘，进程被杀会丢失登录态。
    await prefs.setString(GlobalConstants.tokenKey, token);
  }

  // 获取 token
  String getToken() {
    return _token;
  }

  // 清除 token
  Future<void> removeToken() async {
    final prefs = await _getInstance();
    _token = '';
    await prefs.remove(GlobalConstants.tokenKey);
  }
}

final tokenManager = TokenManager();
