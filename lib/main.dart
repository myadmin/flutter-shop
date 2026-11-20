import 'dart:ui' show PlatformDispatcher;

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:hm_shop/routes/index.dart';
import 'package:hm_shop/stores/cart_controller.dart';
import 'package:hm_shop/stores/user_controller.dart';

void main(List<String> args) {
  // 插件（SharedPreferences）依赖 binding，必须在 runApp 之前初始化
  WidgetsFlutterBinding.ensureInitialized();
  // 捕获未处理的框架异常，release 下也保留一条可检索的日志
  FlutterError.onError = (details) {
    FlutterError.presentError(details);
    debugPrint('[FlutterError] ${details.exceptionAsString()}');
  };
  // 兜住「没有 await 的 Future 抛出的异常」：FlutterError.onError 只处理
  // 框架内的同步异常，异步链路里的错误会走到这里。返回 true 表示已记录，
  // 不再向平台抛，避免 release 下整段错误无声消失。
  PlatformDispatcher.instance.onError = (Object error, StackTrace stack) {
    debugPrint('[未捕获异步异常] $error\n$stack');
    return true;
  };
  // 全局共享状态在此统一注册，页面只通过 Get.find 取用。
  // 注册放在启动阶段，避免依赖某个页面何时被创建。
  Get.put(UserController(), permanent: true);
  Get.put(CartController(), permanent: true);
  runApp(getRootWidget());
}
