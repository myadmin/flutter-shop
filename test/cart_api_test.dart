import 'package:flutter_test/flutter_test.dart';
import 'package:hm_shop/api/cart.dart';

import 'helpers/mock_http.dart';

/// 购物车接口层：请求方法、路径与入参，以及返回值的解析。
void main() {
  test('购物车列表请求 /member/cart 并解析出条目', () async {
    final adapter = installMock(
      (options) => envelope([
        cartItemJson(skuId: 'sku-1', count: 2),
        cartItemJson(skuId: 'sku-2', count: 1, selected: false),
      ]),
    );

    final items = await getCartListAPI();

    expect(items, hasLength(2));
    expect(items.first.skuId, 'sku-1');
    expect(items.last.selected, isFalse);
    expect(adapter.requests, hasLength(1));
    expect(adapter.requests.first.method, 'GET');
    expect(adapter.requests.first.path, '/member/cart');
  });

  test('购物车件数兼容对象与数字两种返回', () async {
    installMock((options) => envelope({'count': 13}));
    expect(await getCartCountAPI(), 13);

    installMock((options) => envelope(7));
    expect(await getCartCountAPI(), 7);
  });

  test('加入购物车按 skuId 与数量提交', () async {
    final adapter = installMock(
      (options) => envelope(cartItemJson(skuId: 'sku-9', count: 3)),
    );

    final item = await addCartAPI('sku-9', 3);

    expect(item.skuId, 'sku-9');
    expect(item.count, 3);
    expect(adapter.requests.first.method, 'POST');
    expect(adapter.requests.first.path, '/member/cart');
    expect(adapter.requests.first.data, {'skuId': 'sku-9', 'count': 3});
  });

  test('修改条目只提交传入的字段', () async {
    final adapter = installMock(
      (options) => envelope(cartItemJson(skuId: 'sku-1', count: 5)),
    );

    await updateCartItemAPI('sku-1', count: 5);
    await updateCartItemAPI('sku-1', selected: true);

    expect(adapter.requests[0].method, 'PUT');
    expect(adapter.requests[0].path, '/member/cart/sku-1');
    expect(adapter.requests[0].data, {'count': 5});
    expect(adapter.requests[1].data, {'selected': true});
  });

  test('删除条目把规格 id 放进请求体', () async {
    final adapter = installMock((options) => envelope(true));

    final deleted = await deleteCartItemsAPI(['sku-1', 'sku-2']);

    expect(deleted, isTrue);
    expect(adapter.requests.first.method, 'DELETE');
    expect(adapter.requests.first.path, '/member/cart');
    expect(adapter.requests.first.data, {
      'ids': ['sku-1', 'sku-2'],
    });
  });
}
