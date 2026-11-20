import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:hm_shop/api/order.dart';
import 'package:hm_shop/models/order.dart';
import 'package:hm_shop/utils/loading_dialog.dart';
import 'package:hm_shop/utils/toast_utils.dart';

/// 订单确认页
///
/// 接收商品 skuId 与购买数量，展示默认收货地址、商品信息与金额汇总，
/// 底部固定展示应付金额与提交订单入口。
class OrderConfirmPage extends StatefulWidget {
  // 商品 skuId
  final String skuId;

  // 购买数量
  final int count;

  const OrderConfirmPage({super.key, required this.skuId, required this.count});

  @override
  State<OrderConfirmPage> createState() => _OrderConfirmPageState();
}

class _OrderConfirmPageState extends State<OrderConfirmPage> {
  // 结算信息
  PreOrderResult? _result;

  // 结算信息是否仍在加载
  bool _isLoading = true;

  // 加载失败提示，为空表示无异常
  String _errorMessage = '';

  // 是否正在提交订单，防止重复提交
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _getPreOrder(); // 进入页面立即加载结算信息
  }

  // 获取结算信息
  Future<void> _getPreOrder() async {
    if (widget.skuId.isEmpty) {
      // 缺少规格信息时不发起请求，直接展示异常提示
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
      final result = await getPreOrderAPI(widget.skuId, widget.count);
      if (!mounted) return;
      setState(() {
        _result = result;
      });
    } catch (e) {
      debugPrint('获取结算信息失败: $e');
      if (!mounted) return;
      setState(() {
        _errorMessage = e is DioException
            ? (e.message ?? '结算信息加载失败')
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

  // 提交订单
  Future<void> _submitOrder() async {
    final address = _result?.defaultAddress;
    if (address == null) {
      ToastUtils.showToast(context, '暂无收货地址，无法提交订单');
      return;
    }
    if (_isSubmitting) {
      return;
    }
    _isSubmitting = true;
    LoadingDialog.show(context, message: '正在提交订单');
    try {
      await submitOrderAPI({
        'goods': [
          {'skuId': widget.skuId, 'count': widget.count},
        ],
        'addressId': address.id,
        'deliveryTimeType': 1,
        'buyerMessage': '',
        'payType': 1,
        'payChannel': 1,
      });
      LoadingDialog.hide();
      if (!mounted) return;
      ToastUtils.showToast(context, '订单提交成功');
      Navigator.pop(context);
    } catch (e) {
      LoadingDialog.hide();
      if (!mounted) return;
      final errorMsg = e is DioException
          ? (e.message ?? '订单提交失败')
          : '网络或服务异常，请稍后重试';
      ToastUtils.showToast(context, errorMsg);
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      } else {
        _isSubmitting = false;
      }
    }
  }

  // 通用卡片容器
  Widget _buildCard({required Widget child}) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF7F7F7),
        borderRadius: BorderRadius.circular(10),
      ),
      child: child,
    );
  }

  // 收货地址
  Widget _buildAddress(OrderAddress? address) {
    return _buildCard(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.location_on_outlined,
            size: 22,
            color: Color(0xFFF47D62),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: address == null
                ? const Text(
                    '暂无收货地址',
                    style: TextStyle(fontSize: 14, color: Colors.grey),
                  )
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            address.receiver,
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                              color: Colors.black,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            address.contact,
                            style: const TextStyle(
                              fontSize: 13,
                              color: Colors.grey,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        address.fullAddress,
                        style: const TextStyle(
                          fontSize: 13,
                          color: Colors.black54,
                        ),
                      ),
                    ],
                  ),
          ),
        ],
      ),
    );
  }

  // 商品信息
  Widget _buildGoods(PreOrderGoods goods) {
    return _buildCard(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Image.network(
              goods.picture,
              width: 76,
              height: 76,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) {
                return Container(
                  width: 76,
                  height: 76,
                  color: Colors.grey.shade200,
                  alignment: Alignment.center,
                  child: const Icon(
                    Icons.broken_image_outlined,
                    size: 24,
                    color: Colors.grey,
                  ),
                );
              },
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  goods.name,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.black,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  goods.attrsText,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Text(
                      '￥${goods.price}',
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        color: Colors.black,
                      ),
                    ),
                    const Spacer(),
                    Text(
                      'x${goods.count}',
                      style: const TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // 金额汇总行
  Widget _buildSummaryRow(
    String label,
    String value, {
    bool highlight = false,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Text(label, style: const TextStyle(fontSize: 13, color: Colors.grey)),
          const Spacer(),
          Text(
            value,
            style: TextStyle(
              fontSize: highlight ? 15 : 13,
              fontWeight: highlight ? FontWeight.w800 : FontWeight.normal,
              color: highlight ? const Color(0xFFF47D62) : Colors.black,
            ),
          ),
        ],
      ),
    );
  }

  // 金额汇总
  Widget _buildSummary(OrderSummary summary) {
    return _buildCard(
      child: Column(
        children: [
          _buildSummaryRow('商品件数', '${summary.goodsCount}件'),
          _buildSummaryRow('商品金额', '￥${summary.totalPrice}'),
          _buildSummaryRow('运费', '￥${summary.postFee}'),
          _buildSummaryRow(
            '应付金额',
            '￥${summary.totalPayPrice}',
            highlight: true,
          ),
        ],
      ),
    );
  }

  // 页面内容
  Widget _buildContent(PreOrderResult result) {
    return ListView(
      padding: const EdgeInsets.all(12),
      children: [
        _buildAddress(result.defaultAddress),
        ...result.goods.map((goods) => _buildGoods(goods)),
        _buildSummary(result.summary),
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
            _errorMessage.isEmpty ? '结算信息加载失败' : _errorMessage,
            style: const TextStyle(fontSize: 14, color: Colors.grey),
          ),
          const SizedBox(height: 20),
          OutlinedButton(
            onPressed: _getPreOrder,
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

  // 底部提交栏
  Widget _buildSubmitBar() {
    final summary = _result?.summary;
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Color(0x14000000),
            blurRadius: 8,
            offset: Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Center(
          // heightFactor 为 1 时按内容高度收缩，避免撑满整个视口
          heightFactor: 1,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 600),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          '应付金额',
                          style: TextStyle(fontSize: 11, color: Colors.grey),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '￥${summary?.totalPayPrice ?? '0'}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w800,
                            color: Colors.black,
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(
                    height: 42,
                    child: ElevatedButton(
                      onPressed: _isSubmitting ? null : _submitOrder,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFF47D62),
                        foregroundColor: Colors.white,
                        disabledBackgroundColor: const Color(0xFFF8C4B7),
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(horizontal: 28),
                        shape: const StadiumBorder(),
                        textStyle: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      child: _isSubmitting
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Text('提交订单', maxLines: 1),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    final result = _result;
    if (result == null) {
      return _buildError();
    }
    return _buildContent(result);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('确认订单'),
        centerTitle: true,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
      ),
      body: _buildBody(),
      // 底部固定提交栏，由 Scaffold 预留布局空间，不遮挡页面内容
      bottomNavigationBar: _result == null ? null : _buildSubmitBar(),
    );
  }
}
