import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:hm_shop/api/cart.dart';
import 'package:hm_shop/api/goods.dart';
import 'package:hm_shop/components/GoodsDetail/hm_action_bar.dart';
import 'package:hm_shop/components/GoodsDetail/hm_goods_brand.dart';
import 'package:hm_shop/components/GoodsDetail/hm_goods_gallery.dart';
import 'package:hm_shop/components/GoodsDetail/hm_goods_price_info.dart';
import 'package:hm_shop/components/GoodsDetail/hm_goods_properties.dart';
import 'package:hm_shop/components/GoodsDetail/hm_sku_selector.dart';
import 'package:hm_shop/components/common/app_error_view.dart';
import 'package:hm_shop/components/common/app_network_image.dart';
import 'package:hm_shop/models/goods.dart';
import 'package:hm_shop/routes/app_routes.dart';
import 'package:hm_shop/stores/cart_controller.dart';
import 'package:hm_shop/stores/token_manager.dart';
import 'package:hm_shop/utils/api_exception.dart';
import 'package:hm_shop/utils/loading_dialog.dart';
import 'package:hm_shop/utils/toast_utils.dart';

/// 商品详情页
///
/// 接收商品 id，进入页面后请求商品详情数据；
/// 加载中展示进度提示，加载失败时展示错误信息与重试入口。
class GoodsDetailPage extends StatefulWidget {
  // 商品 id，由列表项点击时传入
  final String goodsId;

  const GoodsDetailPage({super.key, required this.goodsId});

  @override
  State<GoodsDetailPage> createState() => _GoodsDetailPageState();
}

class _GoodsDetailPageState extends State<GoodsDetailPage> {
  // 商品详情数据
  GoodsDetail? _detail;

  // 详情数据是否仍在加载
  bool _isLoading = true;

  // 加载失败提示，为空表示无异常
  String _errorMessage = '';

  // 当前展示的主图下标
  int _pictureIndex = 0;

  // 购物车件数的全局态，加购成功后刷新底部 tab 角标
  final CartController _cartController = Get.find<CartController>();

  @override
  void initState() {
    super.initState();
    _getGoodsDetail();
  }

  // 获取商品详情
  Future<void> _getGoodsDetail() async {
    if (widget.goodsId.isEmpty) {
      // 缺少商品 id 时不发起请求，直接展示异常提示
      setState(() {
        _isLoading = false;
        _errorMessage = '商品信息缺失';
      });
      return;
    }
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });
    try {
      final detail = await getGoodsDetailAPI(widget.goodsId);
      if (!mounted) return;
      setState(() {
        _detail = detail;
      });
    } catch (e) {
      debugPrint('获取商品详情失败: $e');
      if (!mounted) return;
      setState(() {
        _errorMessage = resolveErrorMessage(e, fallback: '商品信息加载失败');
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  // 校验登录态，未登录时提示并跳转登录页
  bool _checkLogin() {
    if (tokenManager.getToken().isNotEmpty) {
      return true;
    }
    ToastUtils.showToast(context, '请先登录');
    Navigator.pushNamed(context, AppRoutes.login);
    return false;
  }

  /// 打开规格选择弹层
  ///
  /// 商品没有可用规格时直接提示并返回 null，不进入弹层。
  Future<SkuSelection?> _selectSku(String confirmText) async {
    final detail = _detail;
    if (detail == null || detail.skus.isEmpty) {
      ToastUtils.showToast(context, '商品规格信息缺失，暂无法购买');
      return null;
    }
    return showSkuSelector(context, detail: detail, confirmText: confirmText);
  }

  // 加入购物车：先选规格与数量，再带上登录态校验
  Future<void> _onAddCart() async {
    final selection = await _selectSku('加入购物车');
    if (!mounted || selection == null) return;
    if (!_checkLogin()) {
      return;
    }
    LoadingDialog.show(context, message: '正在加入购物车');
    try {
      await addCartAPI(selection.sku.id, selection.count);
      LoadingDialog.hide();
      if (!mounted) return;
      // 同步底部 tab 的购物车角标
      await _cartController.refreshCount();
      if (!mounted) return;
      ToastUtils.showToast(context, '已加入购物车');
    } catch (e) {
      LoadingDialog.hide();
      if (!mounted) return;
      final errorMsg = resolveErrorMessage(e, fallback: '加入购物车失败');
      ToastUtils.showToast(context, errorMsg);
    }
  }

  // 立即购买：携带选中的规格与数量进入订单确认页
  Future<void> _onBuyNow() async {
    final selection = await _selectSku('立即购买');
    if (!mounted || selection == null) return;
    if (!_checkLogin()) {
      return;
    }
    Navigator.pushNamed(
      context,
      AppRoutes.orderConfirm(selection.sku.id, selection.count),
    );
  }

  // 详情内容区域
  Widget _buildContent(GoodsDetail detail) {
    final detailPictures = detail.detailPictures;
    return CustomScrollView(
      slivers: [
        SliverToBoxAdapter(
          child: HmGoodsGallery(
            pictures: detail.mainPictures,
            currentIndex: _pictureIndex,
            onIndexChanged: (index) {
              setState(() {
                _pictureIndex = index;
              });
            },
          ),
        ),
        SliverToBoxAdapter(child: HmGoodsPriceInfo(detail: detail)),
        if (detail.brand != null)
          SliverToBoxAdapter(child: HmGoodsBrand(brand: detail.brand!)),
        if (detail.properties.isNotEmpty)
          SliverToBoxAdapter(
            child: HmGoodsProperties(properties: detail.properties),
          ),
        if (detailPictures.isNotEmpty) ...[
          const SliverToBoxAdapter(child: HmGoodsDetailHeader()),
          // 详情图较长，使用 SliverList 按需构建
          SliverList.builder(
            itemCount: detailPictures.length,
            itemBuilder: (BuildContext context, int index) {
              return AppNetworkImage(
                url: detailPictures[index],
                width: double.infinity,
                fit: BoxFit.fitWidth,
                decodeWidth: MediaQuery.sizeOf(context).width,
                placeholderIconSize: 40,
              );
            },
          ),
        ],
        const SliverToBoxAdapter(child: SizedBox(height: 20)),
      ],
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    final detail = _detail;
    if (detail == null) {
      return AppErrorView(
        message: _errorMessage.isEmpty ? '商品信息加载失败' : _errorMessage,
        onRetry: _getGoodsDetail,
      );
    }
    return _buildContent(detail);
  }

  @override
  Widget build(BuildContext context) {
    final detail = _detail;
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('商品详情'),
        centerTitle: true,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
      ),
      body: _buildBody(),
      // 底部固定操作栏，由 Scaffold 预留布局空间，不遮挡页面内容
      bottomNavigationBar: detail == null
          ? null
          : HmActionBar(
              price: detail.price,
              onAddCart: _onAddCart,
              onBuyNow: _onBuyNow,
            ),
    );
  }
}
