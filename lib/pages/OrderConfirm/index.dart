import 'package:flutter/material.dart';
import 'package:hm_shop/api/order.dart';
import 'package:hm_shop/components/OrderConfirm/hm_order_address.dart';
import 'package:hm_shop/components/OrderConfirm/hm_order_goods.dart';
import 'package:hm_shop/components/OrderConfirm/hm_order_summary.dart';
import 'package:hm_shop/components/common/app_error_view.dart';
import 'package:hm_shop/components/common/hm_bottom_bar.dart';
import 'package:hm_shop/models/order.dart';
import 'package:hm_shop/utils/api_exception.dart';
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
        _errorMessage = resolveErrorMessage(e, fallback: '结算信息加载失败');
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
    setState(() {
      _isSubmitting = true;
    });
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
      final errorMsg = resolveErrorMessage(e, fallback: '订单提交失败');
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

  // 页面内容
  Widget _buildContent(PreOrderResult result) {
    return ListView(
      padding: const EdgeInsets.all(12),
      children: [
        HmOrderAddress(address: result.defaultAddress),
        ...result.goods.map((goods) => HmOrderGoods(goods: goods)),
        HmOrderSummary(summary: result.summary),
      ],
    );
  }

  // 底部提交栏
  Widget _buildSubmitBar() {
    final summary = _result?.summary;
    return HmBottomBar(
      child: Row(
        children: [
          Expanded(
            child: HmBottomBarPrice(
              label: '应付金额',
              amount: '￥${summary?.totalPayPrice ?? '0'}',
            ),
          ),
          HmBottomBarButton(
            text: '提交订单',
            primary: true,
            onPressed: _isSubmitting ? null : _submitOrder,
            child: _isSubmitting
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : null,
          ),
        ],
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    final result = _result;
    if (result == null) {
      return AppErrorView(
        message: _errorMessage.isEmpty ? '结算信息加载失败' : _errorMessage,
        onRetry: _getPreOrder,
      );
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
