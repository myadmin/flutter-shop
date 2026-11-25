import 'package:flutter/material.dart';
import 'package:hm_shop/api/order.dart';
import 'package:hm_shop/components/Order/hm_order_info_row.dart';
import 'package:hm_shop/components/Order/hm_order_sku_row.dart';
import 'package:hm_shop/components/common/app_error_view.dart';
import 'package:hm_shop/components/common/hm_bottom_bar.dart';
import 'package:hm_shop/constants/app_text_styles.dart';
import 'package:hm_shop/constants/app_theme.dart';
import 'package:hm_shop/models/order_list.dart';
import 'package:hm_shop/utils/api_exception.dart';
import 'package:hm_shop/utils/order_actions.dart';
import 'package:hm_shop/utils/toast_utils.dart';

/// 订单详情页
///
/// 自上而下：状态说明 → 收货信息 → 商品清单 → 金额明细 → 订单信息。
/// 删除订单成功后回传 `true`，列表页据此刷新。
class OrderDetailPage extends StatefulWidget {
  final String orderId;

  const OrderDetailPage({super.key, required this.orderId});

  @override
  State<OrderDetailPage> createState() => _OrderDetailPageState();
}

class _OrderDetailPageState extends State<OrderDetailPage> {
  OrderDetail? _detail;

  bool _isLoading = true;

  bool _busy = false;

  String _errorMessage = '';

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    if (widget.orderId.isEmpty) {
      setState(() {
        _isLoading = false;
        _errorMessage = '订单信息缺失，请返回重新进入';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      final detail = await getOrderDetailAPI(widget.orderId);
      if (!mounted) return;
      setState(() {
        _detail = detail;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _errorMessage = resolveErrorMessage(e, fallback: '订单详情加载失败');
      });
    }
  }

  Future<void> _delete() async {
    final detail = _detail;
    if (detail == null || _busy) return;

    final confirmed = await confirmDeleteOrder(context);
    if (!confirmed || !mounted) return;

    setState(() => _busy = true);
    try {
      await deleteOrderAPI([detail.id]);
      if (!mounted) return;
      ToastUtils.showToast(context, '订单已删除');
      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      setState(() => _busy = false);
      ToastUtils.showToast(context, resolveErrorMessage(e, fallback: '删除订单失败'));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.pageBackground,
      appBar: AppBar(
        title: const Text('订单详情'),
        centerTitle: true,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
      ),
      body: _buildBody(),
      bottomNavigationBar: _detail == null ? null : _buildBottomBar(_detail!),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_errorMessage.isNotEmpty) {
      return AppErrorView(message: _errorMessage, onRetry: _load);
    }

    final detail = _detail;
    if (detail == null) {
      return const Center(child: Text('暂无订单信息'));
    }

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(
          maxWidth: HmBottomBar.maxContentWidth,
        ),
        child: ListView(
          padding: const EdgeInsets.fromLTRB(12, 10, 12, 16),
          children: [
            _buildStatusBanner(detail),
            const SizedBox(height: 8),
            _buildAddressCard(detail),
            const SizedBox(height: 8),
            _buildGoodsCard(detail),
            const SizedBox(height: 8),
            _buildAmountCard(detail),
            const SizedBox(height: 8),
            _buildInfoCard(detail),
          ],
        ),
      ),
    );
  }

  /// 顶部状态说明
  Widget _buildStatusBanner(OrderDetail detail) {
    final hint = OrderState.hintOf(detail.orderState);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
      decoration: BoxDecoration(
        color: AppColors.primarySurface,
        borderRadius: BorderRadius.circular(AppRadius.card),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            OrderState.labelOf(detail.orderState),
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: AppColors.darkBrown,
            ),
          ),
          if (hint.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              hint,
              style: const TextStyle(fontSize: 12, color: AppColors.darkBrown),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildAddressCard(OrderDetail detail) {
    return _buildCard(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.location_on_outlined,
            size: 20,
            color: AppColors.primary,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        detail.receiverContact,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTextStyles.bodyStrong,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Text(detail.receiverMobile, style: AppTextStyles.caption),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  detail.receiverAddress,
                  style: const TextStyle(fontSize: 12, color: Colors.black87),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGoodsCard(OrderDetail detail) {
    return _buildCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (final sku in detail.skus) HmOrderSkuRow(sku: sku),
          const Divider(height: 16, color: AppColors.divider),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Text('共 ${detail.goodsCount} 件商品', style: AppTextStyles.caption),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAmountCard(OrderDetail detail) {
    return _buildCard(
      child: Column(
        children: [
          HmOrderInfoRow(label: '商品总额', value: '￥${detail.totalMoney}'),
          HmOrderInfoRow(label: '运费', value: '￥${detail.postFee}'),
          HmOrderInfoRow(
            label: '实付金额',
            value: '￥${detail.payMoney}',
            emphasize: true,
          ),
        ],
      ),
    );
  }

  Widget _buildInfoCard(OrderDetail detail) {
    return _buildCard(
      child: Column(
        children: [
          HmOrderInfoRow(label: '订单编号', value: detail.id),
          HmOrderInfoRow(label: '下单时间', value: detail.createTime),
          HmOrderInfoRow(label: '支付方式', value: detail.payChannelLabel),
          if (detail.payTime.isNotEmpty)
            HmOrderInfoRow(label: '支付时间', value: detail.payTime),
          if (detail.consignTime.isNotEmpty)
            HmOrderInfoRow(label: '发货时间', value: detail.consignTime),
          if (detail.endTime.isNotEmpty)
            HmOrderInfoRow(label: '完成时间', value: detail.endTime),
          if (detail.closeTime.isNotEmpty)
            HmOrderInfoRow(label: '关闭时间', value: detail.closeTime),
        ],
      ),
    );
  }

  Widget _buildCard({required Widget child}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppRadius.card),
      ),
      child: child,
    );
  }

  Widget _buildBottomBar(OrderDetail detail) {
    final action = OrderState.primaryActionOf(detail.orderState);
    return HmBottomBar(
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          HmBottomBarButton(text: '删除订单', onPressed: _busy ? null : _delete),
          if (action.isNotEmpty) ...[
            const SizedBox(width: 10),
            HmBottomBarButton(
              text: action,
              primary: true,
              onPressed: _busy
                  ? null
                  : () => performOrderPrimaryAction(context, detail),
            ),
          ],
        ],
      ),
    );
  }
}
