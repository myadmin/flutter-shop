import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:hm_shop/api/release.dart';
import 'package:hm_shop/components/common/hm_update_banner.dart';
import 'package:hm_shop/components/common/hm_update_dialog.dart';
import 'package:hm_shop/models/app_release.dart';
import 'package:hm_shop/pages/Main/index.dart';
import 'package:hm_shop/services/app_update_service.dart';
import 'package:hm_shop/stores/cart_controller.dart';
import 'package:hm_shop/stores/user_controller.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'helpers/mock_http.dart';

Map<String, dynamic> _apk(String name, {int size = 19324916}) {
  return <String, dynamic>{
    'name': name,
    'size': size,
    'browser_download_url': 'https://example.com/$name',
  };
}

AppRelease _release({String version = '1.0.13', List<dynamic>? assets}) {
  return AppRelease.fromJson(<String, dynamic>{
    'tag_name': 'v$version',
    'body': '## 更新\n- 修了点东西',
    'html_url':
        'https://github.com/myadmin/flutter-shop/releases/tag/v$version',
    'assets':
        assets ??
        <dynamic>[
          _apk('app-armeabi-v7a-release.apk', size: 16760656),
          _apk('app-arm64-v8a-release.apk'),
        ],
  });
}

/// 组装一个不碰网络的检查服务
AppUpdateService _service({
  String current = '1.0.12',
  AppRelease? release,
  bool fail = false,
  bool enabled = true,
  Duration ttl = Duration.zero,
  List<Uri>? opened,
  void Function()? onFetch,
}) {
  return AppUpdateService(
    enabled: enabled,
    cacheTtl: ttl,
    currentVersionLoader: () async => current,
    releaseFetcher: () async {
      onFetch?.call();
      if (fail) {
        throw StateError('network down');
      }
      return release;
    },
    urlLauncher: (Uri url) async {
      opened?.add(url);
      return true;
    },
  );
}

/// 底部容器会用到的接口，其余返回空 result
ResponseBody _response(RequestOptions options) {
  switch (options.path) {
    case '/home/banner':
    case '/home/category/head':
    case '/home/recommend':
    case '/home/new':
    case '/home/brand':
    case '/home/special':
    case '/home/goods':
      return envelope(<dynamic>[]);
    case '/hot/preference':
    case '/hot/inVogue':
    case '/hot/oneStop':
    case '/hot/new':
      return envelope(<String, dynamic>{
        'id': 'module-1',
        'title': '专题',
        'subTypes': <dynamic>[],
      });
    case '/member/cart/count':
      return envelope(0);
    default:
      return envelope(null);
  }
}

/// 轮播图会自动播放，`pumpAndSettle` 等不到静止
Future<void> _settle(WidgetTester tester) async {
  for (var i = 0; i < 10; i++) {
    await tester.pump(const Duration(milliseconds: 50));
  }
}

MockAdapter _boot() {
  SharedPreferences.setMockInitialValues(<String, Object>{});
  Get.reset();
  Get.put(UserController(), permanent: true);
  Get.put(CartController(), permanent: true);
  addTearDown(Get.reset);
  return installMock(_response);
}

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues(<String, Object>{});
  });

  group('版本号工具', () {
    test('归一化去掉 v 前缀与 +build 后缀', () {
      expect(normalizeVersion('v1.0.13'), '1.0.13');
      expect(normalizeVersion('V2.0.0'), '2.0.0');
      expect(normalizeVersion('1.0.13+14'), '1.0.13');
      expect(normalizeVersion('  1.0.13  '), '1.0.13');
      expect(normalizeVersion(''), '');
    });

    test('比较版本号', () {
      expect(compareVersions('1.0.13', '1.0.12'), 1);
      expect(compareVersions('1.0.12', '1.0.13'), -1);
      expect(compareVersions('1.0.13', '1.0.13'), 0);
      expect(compareVersions('1.0', '1.0.0'), 0);
      expect(compareVersions('1.0.9', '1.0.10'), -1);
      expect(compareVersions('2.0.0', '1.9.9'), 1);
      expect(compareVersions('1.0.13-beta', '1.0.13'), 0);
    });
  });

  group('AppRelease 解析', () {
    test('解析 Release 与安装包', () {
      final AppRelease release = _release();

      expect(release.versionName, '1.0.13');
      expect(release.notes, contains('修了点东西'));
      expect(release.htmlUrl, contains('/releases/tag/v1.0.13'));
      expect(release.assets, hasLength(2));
      // 优先 64 位包
      expect(
        release.androidApkUrl,
        'https://example.com/app-arm64-v8a-release.apk',
      );
      expect(release.androidApkSizeText, '18.4 MB');
    });

    test('没有 64 位包时退到 32 位包', () {
      final AppRelease release = _release(
        assets: <dynamic>[_apk('app-armeabi-v7a-release.apk')],
      );

      expect(
        release.androidApkUrl,
        'https://example.com/app-armeabi-v7a-release.apk',
      );
    });

    test('只有 iOS 包时没有安卓下载地址', () {
      final AppRelease release = _release(
        assets: <dynamic>[
          <String, dynamic>{
            'name': 'Runner.app.zip',
            'size': 7722982,
            'browser_download_url': 'https://example.com/Runner.app.zip',
          },
        ],
      );

      expect(release.androidApkUrl, isNull);
      expect(release.androidApkSizeText, '');
    });

    test('字段缺失时按空值兜底', () {
      final AppRelease release = AppRelease.fromJson(<String, dynamic>{});

      expect(release.versionName, '');
      expect(release.notes, '');
      expect(release.assets, isEmpty);
      expect(release.androidApkUrl, isNull);
    });
  });

  group('AppUpdateService', () {
    test('关闭检查时直接返回 null，不请求网络', () async {
      var fetched = 0;
      final AppUpdateService service = _service(
        enabled: false,
        release: _release(),
        onFetch: () => fetched++,
      );

      expect(await service.check(), isNull);
      expect(fetched, 0);
    });

    test('远端版本更新时返回 Release', () async {
      final AppUpdateService service = _service(release: _release());

      final AppRelease? release = await service.check();

      expect(release, isNotNull);
      expect(release!.versionName, '1.0.13');
    });

    test('远端版本相同或更旧时不提示', () async {
      expect(
        await _service(current: '1.0.13', release: _release()).check(),
        isNull,
      );
      expect(
        await _service(current: '1.0.14', release: _release()).check(),
        isNull,
      );
      expect(
        await _service(current: '1.0.13+14', release: _release()).check(),
        isNull,
      );
    });

    test('当前版本读不到时不提示', () async {
      expect(await _service(current: '', release: _release()).check(), isNull);
    });

    test('没有 Release 或请求失败都静默返回 null', () async {
      expect(await _service(release: null).check(), isNull);
      expect(await _service(release: _release(), fail: true).check(), isNull);
    });

    test('跳过此版本后不再提示', () async {
      final AppRelease release = _release();
      final AppUpdateService service = _service(release: release);

      expect(await service.check(), isNotNull);
      await service.skip(release);
      expect(await service.check(), isNull);
      // force 也绕不过「跳过」
      expect(await service.check(force: true), isNull);
    });

    test('间隔内不重复请求，force 可以强制检查', () async {
      var fetched = 0;
      final AppUpdateService service = _service(
        release: _release(),
        ttl: const Duration(hours: 6),
        onFetch: () => fetched++,
      );

      expect(await service.check(), isNotNull);
      expect(await service.check(), isNull);
      expect(fetched, 1);

      expect(await service.check(force: true), isNotNull);
      expect(fetched, 2);
    });

    test('安卓优先打开安装包，没有安装包时打开 Release 页', () async {
      final List<Uri> opened = <Uri>[];
      final AppUpdateService service = _service(opened: opened);

      expect(await service.openDownload(_release()), isTrue);
      expect(
        opened.last.toString(),
        'https://example.com/app-arm64-v8a-release.apk',
      );

      final AppRelease noApk = _release(assets: <dynamic>[]);
      expect(await service.openDownload(noApk), isTrue);
      expect(opened.last.toString(), contains('/releases/tag/v1.0.13'));
    });

    test('没有可用地址时返回 false', () async {
      final AppUpdateService service = _service(opened: <Uri>[]);
      final AppRelease empty = AppRelease.fromJson(<String, dynamic>{});

      expect(await service.openDownload(empty), isFalse);
    });

    test('打开地址抛异常时返回 false', () async {
      final AppUpdateService service = AppUpdateService(
        enabled: true,
        currentVersionLoader: () async => '1.0.12',
        urlLauncher: (Uri url) async => throw StateError('no browser'),
      );

      expect(await service.openDownload(_release()), isFalse);
    });
  });

  group('HmUpdateBanner', () {
    testWidgets('显示版本号并回调更新与关闭', (tester) async {
      var updated = 0;
      var closed = 0;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: HmUpdateBanner(
              versionName: '1.0.13',
              onUpdate: () => updated++,
              onClose: () => closed++,
            ),
          ),
        ),
      );

      expect(find.text('发现新版本 v1.0.13'), findsOneWidget);

      await tester.tap(find.text('立即更新'));
      await tester.pump();
      expect(updated, 1);

      await tester.tap(find.byIcon(Icons.close));
      await tester.pump();
      expect(closed, 1);
    });
  });

  group('更新弹窗', () {
    Future<void> pumpDialog(
      WidgetTester tester, {
      required VoidCallback onUpdate,
      required VoidCallback onSkip,
    }) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (BuildContext context) => TextButton(
                onPressed: () => showAppUpdateDialog(
                  context,
                  release: _release(),
                  currentVersion: '1.0.12',
                  onUpdate: onUpdate,
                  onSkip: onSkip,
                ),
                child: const Text('打开'),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.text('打开'));
      await tester.pumpAndSettle();
    }

    testWidgets('展示版本、体积与更新说明', (tester) async {
      await pumpDialog(tester, onUpdate: () {}, onSkip: () {});

      expect(find.text('发现新版本 v1.0.13'), findsOneWidget);
      expect(find.text('当前版本 1.0.12 · 安装包 18.4 MB'), findsOneWidget);
      expect(find.textContaining('修了点东西'), findsOneWidget);
    });

    testWidgets('点「立即更新」回调 onUpdate', (tester) async {
      var updated = 0;
      await pumpDialog(tester, onUpdate: () => updated++, onSkip: () {});

      await tester.tap(find.text('立即更新'));
      await tester.pumpAndSettle();

      expect(updated, 1);
      expect(find.text('发现新版本 v1.0.13'), findsNothing);
    });

    testWidgets('点「跳过此版本」回调 onSkip', (tester) async {
      var skipped = 0;
      await pumpDialog(tester, onUpdate: () {}, onSkip: () => skipped++);

      await tester.tap(find.text('跳过此版本'));
      await tester.pumpAndSettle();

      expect(skipped, 1);
      expect(find.text('发现新版本 v1.0.13'), findsNothing);
    });
  });

  group('MainPage 接入', () {
    testWidgets('安卓端发现新版本时弹出更新弹窗', (tester) async {
      _boot();
      final List<Uri> opened = <Uri>[];

      await tester.pumpWidget(
        MaterialApp(
          home: MainPage(
            updateService: _service(release: _release(), opened: opened),
          ),
        ),
      );
      await _settle(tester);

      expect(find.text('发现新版本 v1.0.13'), findsOneWidget);

      await tester.tap(find.text('立即更新'));
      await _settle(tester);

      expect(opened.single.toString(), contains('app-arm64-v8a-release.apk'));
      expect(find.text('发现新版本 v1.0.13'), findsNothing);
    });

    testWidgets('非安卓端用顶部横幅，可关闭', (tester) async {
      debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
      _boot();

      await tester.pumpWidget(
        MaterialApp(
          home: MainPage(updateService: _service(release: _release())),
        ),
      );
      await _settle(tester);

      expect(find.byType(HmUpdateBanner), findsOneWidget);
      expect(find.text('发现新版本 v1.0.13'), findsOneWidget);

      await tester.tap(find.byIcon(Icons.close));
      await _settle(tester);

      expect(find.byType(HmUpdateBanner), findsNothing);

      // 平台覆盖必须在用例内复位，否则框架的 debug 变量校验会报错
      debugDefaultTargetPlatformOverride = null;
    });

    testWidgets('没有新版本时不打扰用户', (tester) async {
      _boot();

      await tester.pumpWidget(
        MaterialApp(home: MainPage(updateService: _service(release: null))),
      );
      await _settle(tester);

      expect(find.byType(HmUpdateBanner), findsNothing);
      expect(find.textContaining('发现新版本'), findsNothing);
    });
  });

  group('GitHub Release 接口', () {
    MockAdapter mockRelease(ResponseBody Function(RequestOptions) handler) {
      final MockAdapter adapter = MockAdapter(handler);
      releaseDio.httpClientAdapter = adapter;
      addTearDown(() => releaseDio.httpClientAdapter = HttpClientAdapter());
      return adapter;
    }

    test('解析最新 Release', () async {
      final MockAdapter mock = mockRelease(
        (RequestOptions options) => jsonResponse(<String, dynamic>{
          'tag_name': 'v1.0.13',
          'body': '## 1.0.13',
          'html_url':
              'https://github.com/myadmin/flutter-shop/releases/tag/v1.0.13',
          'assets': <dynamic>[_apk('app-arm64-v8a-release.apk')],
        }),
      );

      final AppRelease? release = await fetchLatestRelease();

      expect(
        mock.requests.single.uri.toString(),
        contains('/repos/myadmin/flutter-shop'),
      );
      expect(release, isNotNull);
      expect(release!.versionName, '1.0.13');
      expect(release.androidApkUrl, isNotNull);
    });

    test('仓库没有 Release（404）时返回 null', () async {
      mockRelease(
        (RequestOptions options) => jsonResponse(<String, dynamic>{
          'message': 'Not Found',
        }, statusCode: 404),
      );

      expect(await fetchLatestRelease(), isNull);
    });

    test('其它错误照常抛出，由服务层静默处理', () async {
      mockRelease(
        (RequestOptions options) => jsonResponse(<String, dynamic>{
          'message': 'Server Error',
        }, statusCode: 500),
      );

      expect(fetchLatestRelease(), throwsA(isA<DioException>()));
    });

    test('读当前版本号（package_info）', () async {
      PackageInfo.setMockInitialValues(
        appName: 'hm_shop',
        packageName: 'com.example.hm_shop',
        version: '1.0.12',
        buildNumber: '13',
        buildSignature: '',
      );

      expect(await AppUpdateService().currentVersion(), '1.0.12');
    });
  });
}
