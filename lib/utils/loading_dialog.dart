import 'package:flutter/material.dart';
import 'package:hm_shop/constants/app_theme.dart';

class LoadingDialog {
  /// 当前正在展示的加载弹窗路由。
  ///
  /// 只有持有这个 Route 引用才能确定"栈顶是不是我们的 Loading"，
  /// 单纯用 `Navigator.canPop` 判断会把页面本身误关掉。
  static Route<void>? _route;

  /// 当前弹窗是否处于显示状态。
  static bool get isShowing => _route != null;

  static void show(BuildContext context, {String? message = "加载中..."}) {
    if (_route != null) {
      // 已有一个 Loading 在显示，避免重复入栈导致 hide 只关掉其中一个。
      return;
    }

    final navigator = Navigator.of(context, rootNavigator: true);
    late final Route<void> route;
    route = DialogRoute<void>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return PopScope(
          canPop: false,
          child: Dialog(
            backgroundColor: Colors.transparent,
            child: Center(
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(AppRadius.card),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const CircularProgressIndicator(),
                    const SizedBox(height: 10),
                    Text(message ?? ""),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
    _route = route;
    navigator.push(route).whenComplete(() {
      // 无论是被 hide() 还是被外部逻辑移除，都要复位状态。
      if (identical(_route, route)) {
        _route = null;
      }
    });
  }

  static void hide() {
    final route = _route;
    if (route == null || !route.isActive) {
      _route = null;
      return;
    }
    _route = null;
    // 使用 route 自身的 navigator，确保 pop 掉的就是 Loading 这一层。
    route.navigator?.removeRoute(route);
  }
}
