import 'package:flutter_test/flutter_test.dart';
import 'package:hm_shop/models/goods.dart';
import 'package:hm_shop/models/home.dart';
import 'package:hm_shop/models/order.dart';
import 'package:hm_shop/models/parsers.dart';
import 'package:hm_shop/utils/api_exception.dart';

void main() {
  group('模型反序列化取值工具', () {
    test('asString 兼容 null、数字与空串', () {
      expect(asString(null), '');
      expect(asString(4026450), '4026450');
      expect(asString(89.5), '89.5');
      expect(asString(''), '');
      expect(asString(null, fallback: '未知'), '未知');
      expect(asString('', fallback: '未知'), '未知');
    });

    test('asInt 兼容字符串数字、浮点数与非法值', () {
      expect(asInt(null), 0);
      expect(asInt(3), 3);
      expect(asInt('42'), 42);
      expect(asInt(' 7 '), 7);
      expect(asInt(9.9), 9);
      expect(asInt('不是一个数字'), 0);
      expect(asInt('', fallback: 1), 1);
    });

    test('asAmount 统一成两位小数的金额字符串', () {
      expect(asAmount(null), '0.00');
      expect(asAmount(89), '89.00');
      expect(asAmount(69.9), '69.90');
      expect(asAmount('69.9'), '69.90');
      expect(asAmount('0'), '0.00');
      expect(asAmount('abc'), '0.00');
    });

    test('asList 与 asStringList 在非数组输入下返回空列表', () {
      expect(asList<int>(null, (json) => 0), isEmpty);
      expect(asList<int>('不是数组', (json) => 0), isEmpty);
      expect(asList<int>(<int>[1, 2], (json) => 0), isEmpty);

      expect(asStringList(null), isEmpty);
      expect(asStringList(<Map<Object?, Object?>>[]), isEmpty);
      expect(asStringList(<dynamic>['a', 1, null]), <String>['a', '1']);
    });
  });

  group('模型对不稳定字段类型的容错', () {
    test('CategoryItem 的 id 为数字时不会抛类型异常', () {
      // 修复前 id 直接取 json['id']，数字 id 会因 String 类型不匹配抛 TypeError
      final item = CategoryItem.fromJson(<String, dynamic>{
        'id': 1462,
        'name': '婴幼童装',
        'picture': 'http://example.com/a.png',
      });

      expect(item.id, '1462');
      expect(item.children, isNull);
      expect(item.goods, isNull);
    });

    test('GoodsItems 的分页字段为字符串时能正确转成整数', () {
      final items = GoodsItems.fromJson(<String, dynamic>{
        'counts': '459',
        'pageSize': '10',
        'pages': 46,
        'page': '1',
        'items': [
          {'id': 1, 'name': '商品', 'price': 69.9, 'orderNum': '120'},
        ],
      });

      expect(items.counts, 459);
      expect(items.pageSize, 10);
      expect(items.pages, 46);
      expect(items.page, 1);
      expect(items.items.single.price, '69.90');
      expect(items.items.single.orderNum, 120);
    });

    test('GoodDetailItem 解析数字与字符串混合的价格和销量', () {
      final item = GoodDetailItem.fromJson(<String, dynamic>{
        'id': 4026450,
        'name': '测试商品',
        'price': 69,
        'picture': null,
        'orderNum': '1000',
        'payCount': 2600,
      });

      expect(item.id, '4026450');
      expect(item.price, '69.00');
      expect(item.picture, '');
      expect(item.orderNum, 1000);
      expect(item.payCount, 2600);
    });

    test('goodsItems 缺失时回退成空分页对象', () {
      final subType = SubType.fromJson(<String, dynamic>{'id': '1'});

      expect(subType.title, '');
      expect(subType.goodsItems.items, isEmpty);
      expect(subType.goodsItems.counts, 0);
    });

    test('GoodsDetail 在 details 缺失时仍能解析出主结构与空列表', () {
      final detail = GoodsDetail.fromJson(<String, dynamic>{
        'id': 1,
        'name': '测试商品',
        'price': 89,
        'oldPrice': '129.9',
        'mainPictures': ['a.png', 'b.png'],
        'salesCount': '12',
        'skus': [
          {'id': 11, 'price': 89, 'inventory': '5', 'picture': null},
        ],
      });

      expect(detail.id, '1');
      expect(detail.price, '89.00');
      expect(detail.oldPrice, '129.90');
      expect(detail.mainPictures, <String>['a.png', 'b.png']);
      expect(detail.salesCount, 12);
      expect(detail.properties, isEmpty);
      expect(detail.detailPictures, isEmpty);
      expect(detail.brand, isNull);
      expect(detail.skus.single.price, '89.00');
      expect(detail.skus.single.inventory, 5);
      expect(detail.skus.single.specs, isEmpty);
    });

    test('PreOrderGoods 的 count 缺失时回退为 1 件', () {
      final goods = PreOrderGoods.fromJson(<String, dynamic>{
        'id': '1',
        'name': '测试商品',
        'price': 99,
      });

      expect(goods.count, 1);
      expect(goods.price, '99.00');
      expect(goods.totalPayPrice, '0.00');
      expect(goods.picture, '');
      expect(goods.attrsText, '');
    });

    test('PreOrderResult 对非数组字段不抛异常', () {
      final result = PreOrderResult.fromJson(<String, dynamic>{
        'userAddresses': '不是数组',
        'goods': null,
        'summary': <String, dynamic>{'goodsCount': '2', 'totalPayPrice': 190},
      });

      expect(result.userAddresses, isEmpty);
      expect(result.goods, isEmpty);
      expect(result.defaultAddress, isNull);
      expect(result.summary.goodsCount, 2);
      expect(result.summary.totalPayPrice, '190.00');
    });
  });

  group('接口最外层结构的严格校验', () {
    test('asMap 收窄对象，结构不符时抛 FormatException', () {
      expect(asMap(<String, dynamic>{'id': '1'}), <String, dynamic>{'id': '1'});
      // 泛型未擦除的 Map 也能收窄
      expect(asMap(<dynamic, dynamic>{'id': 2}), <String, dynamic>{'id': 2});

      expect(() => asMap(<dynamic>[]), throwsFormatException);
      expect(() => asMap(null), throwsFormatException);
      expect(() => asMap('文本'), throwsFormatException);
    });

    test('asModelList 收窄数组，结构不符时抛 FormatException', () {
      final list = asModelList(<dynamic>[
        <String, dynamic>{'imgUrl': 'a.png'},
        '脏数据',
        <String, dynamic>{'imgUrl': 'b.png'},
      ], BannerItem.fromJson);

      // 非 Map 元素被跳过，不会中断整个列表
      expect(list.map((item) => item.imageUrl), <String>['a.png', 'b.png']);

      expect(
        () => asModelList(<String, dynamic>{}, BannerItem.fromJson),
        throwsFormatException,
      );
      expect(
        () => asModelList(null, BannerItem.fromJson),
        throwsFormatException,
      );
    });

    test('resolveErrorMessage 对结构异常给出可读文案', () {
      expect(
        resolveErrorMessage(const FormatException('期望接口返回数组')),
        '数据格式异常，请稍后重试',
      );
      expect(resolveErrorMessage(StateError('x')), '网络或服务异常，请稍后重试');
      expect(
        resolveErrorMessage(StateError('x'), fallback: '首页加载失败'),
        '首页加载失败',
      );
    });
  });
}
