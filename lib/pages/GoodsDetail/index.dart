import 'package:carousel_slider/carousel_slider.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:hm_shop/api/cart.dart';
import 'package:hm_shop/api/goods.dart';
import 'package:hm_shop/components/GoodsDetail/hm_action_bar.dart';
import 'package:hm_shop/models/goods.dart';
import 'package:hm_shop/stores/token_manager.dart';
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

  @override
  void initState() {
    super.initState();
    _getGoodsDetail(); // 进入页面立即加载商品详情
  }

  // 获取商品详情
  Future<void> _getGoodsDetail() async {
    if (widget.goodsId.isEmpty) {
      // 缺少商品 id 时不发起请求，直接展示异常提示
      setState(() {
        _isLoading = false;
        _errorMessage = '商品不存在';
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
        _errorMessage = e is DioException
            ? (e.message ?? '商品信息加载失败')
            : '网络或服务异常，请稍后重试';
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  // 校验登录态，未登录时提示并引导去登录
  bool _checkLogin() {
    if (tokenManager.getToken().isNotEmpty) {
      return true;
    }
    ToastUtils.showToast(context, '请先登录');
    Navigator.pushNamed(context, '/login');
    return false;
  }

  // 加入购物车
  Future<void> _onAddCart() async {
    final sku = _detail?.defaultSku;
    if (sku == null) {
      ToastUtils.showToast(context, '商品规格信息缺失，暂无法加入购物车');
      return;
    }
    if (!_checkLogin()) {
      return;
    }
    LoadingDialog.show(context, message: '正在加入购物车');
    try {
      await addCartAPI(sku.id, 1);
      if (!mounted) return;
      LoadingDialog.hide(context);
      ToastUtils.showToast(context, '已加入购物车');
    } catch (e) {
      if (!mounted) return;
      LoadingDialog.hide(context);
      final errorMsg = e is DioException
          ? (e.message ?? '加入购物车失败')
          : '网络或服务异常，请稍后重试';
      ToastUtils.showToast(context, errorMsg);
    }
  }

  // 立即购买，携带默认规格进入订单确认页
  void _onBuyNow() {
    final sku = _detail?.defaultSku;
    if (sku == null) {
      ToastUtils.showToast(context, '商品规格信息缺失，暂无法购买');
      return;
    }
    if (!_checkLogin()) {
      return;
    }
    Navigator.pushNamed(
      context,
      '/order/confirm',
      arguments: {'skuId': sku.id, 'count': 1},
    );
  }

  // 主图轮播
  Widget _buildPictureSlider(GoodsDetail detail) {
    final pictures = detail.mainPictures;
    if (pictures.isEmpty) {
      return Container(
        height: 300,
        color: Colors.grey.shade200,
        alignment: Alignment.center,
        child: const Icon(
          Icons.broken_image_outlined,
          size: 48,
          color: Colors.grey,
        ),
      );
    }
    // 商品主图为正方形，按屏幕宽度等比展示
    final double imageSize = MediaQuery.sizeOf(context).width;
    return Stack(
      children: [
        CarouselSlider(
          items: pictures.map((picture) {
            return Image.network(
              picture,
              width: imageSize,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) {
                return Container(
                  width: imageSize,
                  height: imageSize,
                  color: Colors.grey.shade200,
                  alignment: Alignment.center,
                  child: const Icon(
                    Icons.broken_image_outlined,
                    size: 48,
                    color: Colors.grey,
                  ),
                );
              },
            );
          }).toList(),
          options: CarouselOptions(
            height: imageSize,
            viewportFraction: 1.0,
            onPageChanged: (index, reason) {
              setState(() {
                _pictureIndex = index;
              });
            },
          ),
        ),
        // 底部指示器，标识当前展示第几张主图
        Positioned(
          left: 0,
          right: 0,
          bottom: 10,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(pictures.length, (int index) {
              return AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                width: index == _pictureIndex ? 16 : 6,
                height: 6,
                margin: const EdgeInsets.symmetric(horizontal: 3),
                decoration: BoxDecoration(
                  color: index == _pictureIndex
                      ? Colors.white
                      : Colors.grey.shade400,
                  borderRadius: BorderRadius.circular(3),
                ),
              );
            }),
          ),
        ),
      ],
    );
  }

  // 价格、销量与商品标题
  Widget _buildPriceInfo(GoodsDetail detail) {
    // 划线价仅在存在且与售价不同时展示
    final bool showOldPrice =
        detail.oldPrice.isNotEmpty && detail.oldPrice != detail.price;
    return Container(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '￥${detail.price}',
                maxLines: 1,
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                  color: Colors.black,
                ),
              ),
              if (showOldPrice) ...[
                const SizedBox(width: 8),
                Padding(
                  padding: const EdgeInsets.only(bottom: 3),
                  child: Text(
                    '￥${detail.oldPrice}',
                    style: const TextStyle(
                      fontSize: 12,
                      color: Colors.grey,
                      decoration: TextDecoration.lineThrough,
                    ),
                  ),
                ),
              ],
              const Spacer(),
              Text(
                '已售${detail.salesCount} · 评价${detail.commentCount}',
                style: const TextStyle(fontSize: 12, color: Colors.grey),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            detail.name,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Colors.black,
            ),
          ),
          if (detail.desc.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(
              detail.desc,
              style: const TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ],
        ],
      ),
    );
  }

  // 品牌信息
  Widget _buildBrand(GoodsBrand brand) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF7F7F7),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: brand.logo.isEmpty
                ? Container(
                    width: 40,
                    height: 40,
                    color: Colors.grey.shade200,
                    alignment: Alignment.center,
                    child: const Icon(
                      Icons.storefront_outlined,
                      size: 22,
                      color: Colors.grey,
                    ),
                  )
                : Image.network(
                    brand.logo,
                    width: 40,
                    height: 40,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        width: 40,
                        height: 40,
                        color: Colors.grey.shade200,
                        alignment: Alignment.center,
                        child: const Icon(
                          Icons.storefront_outlined,
                          size: 22,
                          color: Colors.grey,
                        ),
                      );
                    },
                  ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              brand.name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Colors.black,
              ),
            ),
          ),
          const Text(
            '品牌直供',
            style: TextStyle(fontSize: 12, color: Colors.grey),
          ),
        ],
      ),
    );
  }

  // 商品参数
  Widget _buildProperties(List<GoodsProperty> properties) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '商品参数',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.black,
            ),
          ),
          const SizedBox(height: 10),
          ...properties.map((property) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    width: 80,
                    child: Text(
                      property.name,
                      style: const TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                  ),
                  Expanded(
                    child: Text(
                      property.value,
                      style: const TextStyle(fontSize: 12, color: Colors.black),
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  // 商品详情标题分割线
  Widget _buildDetailHeader() {
    return const Padding(
      padding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      child: Row(
        children: [
          Expanded(child: Divider(color: Color(0xFFE0E0E0), thickness: 0.5)),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 10),
            child: Text(
              '商品详情',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Colors.black,
              ),
            ),
          ),
          Expanded(child: Divider(color: Color(0xFFE0E0E0), thickness: 0.5)),
        ],
      ),
    );
  }

  // 详情内容区域
  Widget _buildContent(GoodsDetail detail) {
    final detailPictures = detail.detailPictures;
    return CustomScrollView(
      slivers: [
        SliverToBoxAdapter(child: _buildPictureSlider(detail)),
        SliverToBoxAdapter(child: _buildPriceInfo(detail)),
        if (detail.brand != null)
          SliverToBoxAdapter(child: _buildBrand(detail.brand!)),
        if (detail.properties.isNotEmpty)
          SliverToBoxAdapter(child: _buildProperties(detail.properties)),
        if (detailPictures.isNotEmpty) ...[
          SliverToBoxAdapter(child: _buildDetailHeader()),
          // 详情图较长，使用 SliverList 按需构建
          SliverList.builder(
            itemCount: detailPictures.length,
            itemBuilder: (BuildContext context, int index) {
              return Image.network(
                detailPictures[index],
                width: double.infinity,
                fit: BoxFit.fitWidth,
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    height: 200,
                    color: Colors.grey.shade100,
                    alignment: Alignment.center,
                    child: const Icon(
                      Icons.broken_image_outlined,
                      size: 40,
                      color: Colors.grey,
                    ),
                  );
                },
              );
            },
          ),
        ],
        const SliverToBoxAdapter(child: SizedBox(height: 20)),
      ],
    );
  }

  // 加载失败提示
  Widget _buildError() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.error_outline, size: 48, color: Colors.grey.shade400),
          const SizedBox(height: 10),
          Text(
            _errorMessage.isEmpty ? '商品信息加载失败' : _errorMessage,
            style: const TextStyle(fontSize: 14, color: Colors.grey),
          ),
          const SizedBox(height: 20),
          OutlinedButton(
            onPressed: _getGoodsDetail,
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.black,
              side: const BorderSide(color: Colors.black),
            ),
            child: const Text('重新加载'),
          ),
        ],
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    final detail = _detail;
    if (detail == null) {
      return _buildError();
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
