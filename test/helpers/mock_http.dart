import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:hm_shop/utils/dio_request.dart';

/// 用脚本化响应替换 Dio 的 HTTP 适配器，避免测试真的发网络请求。
///
/// 页面级测试需要同时断言「界面状态」和「发出了哪些请求」，所以既提供
/// [handler] 生成响应，也把每次请求记录在 [requests] 里供断言。
class MockAdapter implements HttpClientAdapter {
  MockAdapter(this.handler);

  final ResponseBody Function(RequestOptions options) handler;

  final List<RequestOptions> requests = [];

  /// 按 HTTP 方法过滤记录下来的请求
  List<RequestOptions> requestsWhere(String method) => requests
      .where((option) => option.method.toUpperCase() == method.toUpperCase())
      .toList();

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    requests.add(options);
    return handler(options);
  }

  @override
  void close({bool force = false}) {}
}

/// 构造 JSON 响应体
ResponseBody jsonResponse(Object? body, {int statusCode = 200}) {
  return ResponseBody.fromString(
    jsonEncode(body),
    statusCode,
    headers: {
      Headers.contentTypeHeader: [Headers.jsonContentType],
    },
  );
}

/// 构造业务成功（code=1）的响应体
ResponseBody envelope(Object? result) {
  return jsonResponse({'code': '1', 'result': result});
}

/// 构造业务失败的响应体，例如 `envelopeError('库存不足', code: '10001')`
ResponseBody envelopeError(String msg, {String code = '10001'}) {
  return jsonResponse({'code': code, 'msg': msg});
}

/// 换上 mock 适配器，返回可用于断言的实例
MockAdapter installMock(ResponseBody Function(RequestOptions options) handler) {
  final adapter = MockAdapter(handler);
  dioRequest.dio.httpClientAdapter = adapter;
  return adapter;
}

/// 一条购物车条目，只覆盖测试关心的字段
Map<String, dynamic> cartItemJson({
  String skuId = 'sku-1',
  String name = '测试商品',
  String nowPrice = '69.90',
  int count = 1,
  bool selected = true,
  int stock = 10,
  bool isEffective = true,
}) {
  return {
    'id': 'goods-1',
    'skuId': skuId,
    'name': name,
    'attrsText': '规格:默认 ',
    'picture': '',
    'price': '89.00',
    'nowPrice': nowPrice,
    'selected': selected,
    'stock': stock,
    'count': count,
    'isEffective': isEffective,
    'postFee': 8,
  };
}

/// 一个一级分类（含两个二级分类）
Map<String, dynamic> categoryJson({String id = 'c1', String name = '测试分类'}) {
  return {
    'id': id,
    'name': name,
    'picture': '',
    'children': [
      {'id': 'sub-1', 'name': '子分类一', 'picture': ''},
      {'id': 'sub-2', 'name': '子分类二', 'picture': ''},
    ],
  };
}

/// 一条推荐商品
Map<String, dynamic> goodsItemJson({
  String id = 'goods-1',
  String name = '推荐商品',
  String price = '69.90',
}) {
  return {
    'id': id,
    'name': name,
    'price': price,
    'picture': '',
    'orderNum': 1,
    'payCount': 12,
  };
}

/// 一份商品详情（结构对齐 `/goods` 接口的 result）
Map<String, dynamic> goodsDetailJson({
  String id = 'goods-1',
  String name = '测试商品',
  String price = '89.00',
  String oldPrice = '99.00',
  List<Map<String, dynamic>> skus = const [],
  List<Map<String, dynamic>> properties = const [],
  Map<String, dynamic>? brand,
  List<String> detailPictures = const [],
  int salesCount = 12,
  int commentCount = 3,
}) {
  return {
    'id': id,
    'name': name,
    'desc': '测试商品描述',
    'price': price,
    'oldPrice': oldPrice,
    // 空串会走 AppNetworkImage 的占位分支，测试里不发起真实图片请求
    'mainPictures': [''],
    'salesCount': salesCount,
    'commentCount': commentCount,
    'brand': ?brand,
    'skus': skus,
    'details': {'properties': properties, 'pictures': detailPictures},
  };
}

/// 一个规格（颜色 × 尺码可自行组合）
Map<String, dynamic> skuJson({
  String id = 'sku-1',
  String price = '89.00',
  int inventory = 10,
  String color = '米白',
  String size = 'M',
}) {
  return {
    'id': id,
    'price': price,
    'inventory': inventory,
    'picture': '',
    'specs': [
      {'name': '颜色', 'valueName': color},
      {'name': '尺码', 'valueName': size},
    ],
  };
}

/// 立即购买结算信息（结构对齐 `/member/order/pre/now` 接口的 result）
Map<String, dynamic> preOrderJson({
  String receiver = '张三',
  String contact = '13800138000',
  String goodsName = '测试商品',
  int count = 2,
  String totalPayPrice = '190.00',
}) {
  return {
    'userAddresses': [
      {
        'id': 'addr-1',
        'receiver': receiver,
        'contact': contact,
        'fullLocation': '北京市 东城区',
        'address': '23号',
        'isDefault': 1,
      },
    ],
    'goods': [
      {
        'id': 'goods-1',
        'name': goodsName,
        'picture': '',
        'count': count,
        'attrsText': '规格:默认',
        'price': '89.00',
        'totalPayPrice': '178.00',
      },
    ],
    'summary': {
      'goodsCount': count,
      'totalPrice': '178.00',
      'totalPayPrice': totalPayPrice,
      'postFee': '12.00',
      'discountPrice': '0.00',
    },
  };
}

/// 分类商品列表（结构对齐 `/category/sub/filter` 接口的 result）
Map<String, dynamic> categoryGoodsJson({
  String id = 'sub-1',
  String name = '子分类一',
  String parentName = '测试分类',
  List<Map<String, dynamic>>? goods,
  List<Map<String, dynamic>>? siblings,
}) {
  return {
    'id': id,
    'name': name,
    'picture': '',
    'parentId': 'c1',
    'parentName': parentName,
    'goods':
        goods ??
        [
          goodsItemJson(id: 'goods-1', name: '分类商品一', price: '10.00'),
          goodsItemJson(id: 'goods-2', name: '分类商品二', price: '20.00'),
        ],
    'categories':
        siblings ??
        [
          {'id': 'sub-1', 'name': '子分类一'},
          {'id': 'sub-2', 'name': '子分类二'},
        ],
  };
}

/// 订单里的一个商品行（`skus` 数组项）
Map<String, dynamic> orderSkuJson({
  String id = 'sku-1',
  String name = '测试商品',
  String curPrice = '89.00',
  int quantity = 2,
  String attrsText = '规格:默认',
}) {
  return {
    'id': id,
    'spuId': 'goods-1',
    'name': name,
    'quantity': quantity,
    'image': '',
    'realPay': curPrice,
    'curPrice': curPrice,
    'properties': <Map<String, dynamic>>[],
    'attrsText': attrsText,
  };
}

/// 一条订单（结构对齐 `/member/order` 接口 items 数组项）
Map<String, dynamic> orderItemJson({
  String id = 'order-00000042',
  int orderState = 2,
  String createTime = '2026-11-20 10:00:00',
  String payMoney = '190.00',
  String totalMoney = '178.00',
  int totalNum = 2,
  List<Map<String, dynamic>>? skus,
}) {
  return {
    'id': id,
    'createTime': createTime,
    'payType': 0,
    'orderState': orderState,
    'payLatestTime': '2026-11-20 10:30:00',
    'postFee': '12.00',
    'payMoney': payMoney,
    'totalMoney': totalMoney,
    'totalNum': totalNum,
    'skus': skus ?? [orderSkuJson()],
  };
}

/// 订单列表分页结果（结构对齐 `/member/order` 接口的 result）
Map<String, dynamic> orderListJson({
  int counts = 1,
  int pages = 1,
  int page = 1,
  List<Map<String, dynamic>>? items,
}) {
  return {
    'counts': counts,
    'pageSize': 10,
    'pages': pages,
    'page': page,
    'items': items ?? [orderItemJson()],
  };
}

/// 订单详情（结构对齐 `/member/order/{id}` 接口的 result）
Map<String, dynamic> orderDetailJson({
  String id = 'order-00000042',
  int orderState = 2,
  String receiverContact = '张三',
  String receiverMobile = '13800138000',
  String receiverAddress = '北京市 东城区23号',
  int payChannel = 1,
  String payTime = '2026-11-20 10:05:00',
  List<Map<String, dynamic>>? skus,
}) {
  return {
    ...orderItemJson(id: id, orderState: orderState, skus: skus),
    'payState': 2,
    'countdown': -1,
    'deliveryTimeType': 0,
    'receiverContact': receiverContact,
    'receiverMobile': receiverMobile,
    'receiverAddress': receiverAddress,
    'payChannel': payChannel,
    'payTime': payTime,
    'consignTime': '',
    'endTime': '',
    'closeTime': '',
  };
}

/// 收藏项（结构对齐 `/member/collect` 的 items 元素）
Map<String, dynamic> collectItemJson({
  String id = 'collect-1',
  String goodsId = 'goods-1',
  String name = '测试收藏商品',
  String picture = '',
  String price = '59.00',
  int collectType = 1,
  String createTime = '2026-11-20 09:00:00',
}) {
  return {
    'id': id,
    'goodsId': goodsId,
    'name': name,
    'picture': picture,
    'price': price,
    'collectType': collectType,
    'createTime': createTime,
  };
}

/// 收藏列表分页结果（结构对齐 `/member/collect` 的 result）
Map<String, dynamic> collectListJson({
  int counts = 1,
  int pages = 1,
  int page = 1,
  List<Map<String, dynamic>>? items,
}) {
  return {
    'counts': counts,
    'pageSize': 10,
    'pages': pages,
    'page': page,
    'items': items ?? [collectItemJson()],
  };
}

/// 品牌列表项（结构对齐 `/home/brand` 的数组元素）
Map<String, dynamic> brandItemJson({
  String id = 'brand-1',
  String name = '测试品牌',
  String nameEn = 'TestBrand',
  String logo = '',
  String desc = '品牌简介',
  String place = '中国',
}) {
  return {
    'id': id,
    'name': name,
    'nameEn': nameEn,
    'logo': logo,
    'picture': logo,
    'desc': desc,
    'place': place,
  };
}

/// 品牌详情（结构对齐 `/brand/{id}` 的 result）
Map<String, dynamic> brandDetailJson({
  String id = 'brand-1',
  String name = '测试品牌',
  String nameEn = 'TestBrand',
  String logo = '',
  String brandImage = '',
  String slogan = '为热爱而造',
  String productionPlace = '中国',
  String brandStory = '品牌故事正文',
  int collectNum = 0,
  bool isCollect = false,
}) {
  return {
    'id': id,
    'name': name,
    'nameEn': nameEn,
    'logo': logo,
    'brandImage': brandImage,
    'slogan': slogan,
    'productionPlace': productionPlace,
    'brandStory': brandStory,
    'collectNum': collectNum,
    'isCollect': isCollect,
  };
}

/// 首页「人气好物榜」数据（结构对齐 `/hot/new`，与 `/hot/inVogue` 相同）
Map<String, dynamic> hotResultJson({
  String id = 'rank-1',
  String title = '新鲜好物',
  String subTypeTitle = '抢先尝鲜',
  List<Map<String, dynamic>>? items,
}) {
  return {
    'id': id,
    'title': title,
    'subTypes': [
      {
        'id': 'sub-1',
        'title': subTypeTitle,
        'goodsItems': {
          'counts': 1,
          'pageSize': 10,
          'pages': 1,
          'page': 1,
          'items': items ?? [goodsItemJson()],
        },
      },
    ],
  };
}

/// 个人资料（结构对齐 `/member/profile` 的 result）
Map<String, dynamic> userProfileJson({
  String id = 'u-1',
  String nickname = '晚星12',
  String account = '用户13800138000',
  String avatar = '',
  String gender = '女',
  String birthday = '1995-06-18',
  String fullLocation = '河南省 郑州市 中原区',
  String profession = '前端工程师',
  String token = 'token-new',
}) {
  return {
    'id': id,
    'nickname': nickname,
    'account': account,
    'avatar': avatar,
    'gender': gender,
    'birthday': birthday,
    'fullLocation': fullLocation,
    'profession': profession,
    'token': token,
  };
}

/// 首页「专题精选」条目（结构对齐 `/home/special` 的数组元素）
Map<String, dynamic> specialTopicJson({
  String id = 'special-1',
  String title = '测试专题',
  String summary = '专题简介',
  num lowestPrice = 59,
  String cover = '',
  int collectNum = 0,
  int viewNum = 0,
  int replyNum = 0,
}) {
  return {
    'id': id,
    'classificationId': '1',
    'title': title,
    'summary': summary,
    'lowestPrice': lowestPrice,
    'cover': cover,
    'detailsUrl': cover,
    'collectNum': collectNum,
    'viewNum': viewNum,
    'replyNum': replyNum,
  };
}

/// 首页分类楼层（结构对齐 `/home/goods` 的数组元素）
Map<String, dynamic> homeFloorJson({
  String id = 'floor-1',
  String name = '测试楼层',
  String picture = '',
  String saleInfo = '全场3件8折',
  List<Map<String, dynamic>>? children,
  List<Map<String, dynamic>>? goods,
}) {
  return {
    'id': id,
    'name': name,
    'picture': picture,
    'saleInfo': saleInfo,
    'children':
        children ??
        [
          {'id': 'sub-a', 'name': '子分类A', 'layer': 2, 'parent': id},
          {'id': 'sub-b', 'name': '子分类B', 'layer': 2, 'parent': id},
        ],
    'goods': goods ?? [goodsItemJson()],
  };
}
