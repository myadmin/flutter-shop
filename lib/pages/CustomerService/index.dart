import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hm_shop/constants/app_text_styles.dart';
import 'package:hm_shop/constants/app_theme.dart';
import 'package:hm_shop/utils/toast_utils.dart';

/// 客服中心
///
/// 演示接口没有客服相关端点，这里把服务时间、联系方式与常见问题做成静态内容：
/// 客服热线支持一键复制，「在线客服」「意见反馈」给出「演示接口未提供」的提示，
/// 让每个可点区域都有反馈，而不是点了没反应。
class CustomerServicePage extends StatelessWidget {
  const CustomerServicePage({super.key});

  static const String hotline = '400-000-0000';
  static const String email = 'service@hm-shop.example.com';
  static const String serviceTime = '每天 09:00 - 21:00（法定节假日不休）';

  /// 常见问题（问题 + 回答）
  static const List<({String question, String answer})> faqs = [
    (
      question: '如何申请退换货？',
      answer:
          '签收后 7 天内可在「我的订单」中发起退换货，商品需保持完好、吊牌与配件齐全；'
          '生鲜与定制商品不支持无理由退货。',
    ),
    (question: '下单后多久发货？', answer: '现货商品在付款后 48 小时内发出，预售商品以商品页标注的发货时间为准。'),
    (
      question: '运费怎么计算？',
      answer: '单笔订单满 99 元包邮；未满 99 元收取 10 元运费，偏远地区按实际重量另行计算。',
    ),
    (question: '可以开发票吗？', answer: '订单完成后联系在线客服提供抬头与税号，电子发票会在 3 个工作日内发送到你的邮箱。'),
  ];

  Future<void> _copyHotline(BuildContext context) async {
    await Clipboard.setData(const ClipboardData(text: hotline));
    if (!context.mounted) return;
    ToastUtils.showToast(context, '客服热线已复制：$hotline');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.pageBackground,
      appBar: AppBar(
        title: const Text('客服中心'),
        centerTitle: true,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 600),
          child: ListView(
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 24),
            children: [
              _buildServiceCard(context),
              const SizedBox(height: 10),
              _buildContactCard(context),
              const SizedBox(height: 10),
              _buildFaqCard(),
            ],
          ),
        ),
      ),
    );
  }

  /// 顶部服务卡：服务时间 + 在线客服入口
  Widget _buildServiceCard(BuildContext context) {
    return _card(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: AppColors.primarySurface,
              borderRadius: BorderRadius.circular(AppRadius.image),
            ),
            child: const Icon(
              Icons.headset_mic_outlined,
              color: AppColors.primary,
              size: 24,
            ),
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '在线客服',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
                ),
                SizedBox(height: 4),
                Text(serviceTime, style: AppTextStyles.caption),
              ],
            ),
          ),
          const SizedBox(width: 8),
          SizedBox(
            height: 32,
            child: ElevatedButton(
              onPressed: () =>
                  ToastUtils.showToast(context, '演示接口未提供在线客服，可拨打 $hotline'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                elevation: 0,
                padding: const EdgeInsets.symmetric(horizontal: 14),
                shape: const StadiumBorder(),
                textStyle: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
              child: const Text('联系客服'),
            ),
          ),
        ],
      ),
    );
  }

  /// 联系方式卡：热线（可复制）+ 邮箱
  Widget _buildContactCard(BuildContext context) {
    return _card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '联系方式',
            style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              const Icon(
                Icons.call_outlined,
                size: 18,
                color: AppColors.textSecondary,
              ),
              const SizedBox(width: 8),
              const Expanded(child: Text(hotline, style: AppTextStyles.body)),
              TextButton(
                onPressed: () => _copyHotline(context),
                child: const Text('复制'),
              ),
            ],
          ),
          const Divider(height: 1, color: AppColors.divider),
          const SizedBox(height: 10),
          const Row(
            children: [
              Icon(
                Icons.mail_outline,
                size: 18,
                color: AppColors.textSecondary,
              ),
              SizedBox(width: 8),
              Expanded(child: Text(email, style: AppTextStyles.body)),
            ],
          ),
        ],
      ),
    );
  }

  /// 常见问题卡：展开查看回答
  Widget _buildFaqCard() {
    return _card(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.fromLTRB(14, 10, 14, 2),
            child: Text(
              '常见问题',
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
            ),
          ),
          for (var i = 0; i < faqs.length; i++) ...[
            if (i > 0) const Divider(height: 1, color: AppColors.divider),
            ExpansionTile(
              title: Text(faqs[i].question, style: AppTextStyles.body),
              tilePadding: const EdgeInsets.symmetric(horizontal: 14),
              childrenPadding: const EdgeInsets.fromLTRB(14, 0, 14, 12),
              expandedCrossAxisAlignment: CrossAxisAlignment.start,
              iconColor: AppColors.primary,
              collapsedIconColor: AppColors.textSecondary,
              shape: const Border(),
              collapsedShape: const Border(),
              children: [
                Text(
                  faqs[i].answer,
                  style: const TextStyle(
                    fontSize: 13,
                    height: 1.5,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  /// 白底圆角卡片容器
  Widget _card({
    required Widget child,
    EdgeInsetsGeometry padding = const EdgeInsets.all(14),
  }) {
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppRadius.card),
      ),
      child: child,
    );
  }
}
