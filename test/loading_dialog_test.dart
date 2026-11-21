import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hm_shop/utils/loading_dialog.dart';

/// 加载弹窗的展示、重复展示与关闭。
void main() {
  Widget wrap() {
    return MaterialApp(
      home: Builder(
        builder: (BuildContext context) => Scaffold(
          body: Center(
            child: ElevatedButton(
              onPressed: () => LoadingDialog.show(context, message: '正在提交'),
              child: const Text('开始'),
            ),
          ),
        ),
      ),
    );
  }

  testWidgets('展示后可以用 hide 关闭，且不会误关页面', (tester) async {
    await tester.pumpWidget(wrap());

    await tester.tap(find.text('开始'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.text('正在提交'), findsOneWidget);
    expect(find.text('开始'), findsOneWidget);

    LoadingDialog.hide();
    await tester.pumpAndSettle();

    expect(find.text('正在提交'), findsNothing);
    // 页面本身仍在，说明 hide 只移除了弹窗路由
    expect(find.text('开始'), findsOneWidget);
  });

  testWidgets('重复调用 show 不会叠加弹窗，hide 后只留页面', (tester) async {
    await tester.pumpWidget(wrap());

    await tester.tap(find.text('开始'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    final context = tester.element(find.text('开始'));
    LoadingDialog.show(context, message: '第二次');
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.text('正在提交'), findsOneWidget);
    expect(find.text('第二次'), findsNothing);

    LoadingDialog.hide();
    await tester.pumpAndSettle();
    expect(find.text('正在提交'), findsNothing);
  });

  testWidgets('没有展示时调用 hide 不会抛异常', (tester) async {
    await tester.pumpWidget(wrap());

    LoadingDialog.hide();
    expect(tester.takeException(), isNull);
  });
}
