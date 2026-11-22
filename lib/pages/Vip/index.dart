import 'package:flutter/material.dart';
import 'package:hm_shop/components/common/hm_bottom_bar.dart';
import 'package:hm_shop/constants/app_theme.dart';
import 'package:hm_shop/utils/toast_utils.dart';

/// 会员权益页（纯静态）
///
/// 后端没有任何会员接口（`/member/vip` 之类均不存在），因此这里只做权益说明，
/// 不伪造会员状态：不写本地标记、不显示「已开通」，底部按钮只给未开放的提示。
class VipBenefitsPage extends StatelessWidget {
  const VipBenefitsPage({super.key});

  static const List<({IconData icon, String title, String description})>
  benefits = [
    (
      icon: Icons.local_shipping_outlined,
      title: '无限免邮',
      description: '全店商品不限金额免邮',
    ),
    (
      icon: Icons.local_offer_outlined,
      title: '会员专享价',
      description: '会员价商品优先购买',
    ),
    (icon: Icons.cake_outlined, title: '生日礼包', description: '生日当月领取专属礼包'),
    (icon: Icons.support_agent, title: '优先客服', description: '客服排队优先接入'),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.pageBackground,
      appBar: AppBar(
        title: const Text('会员权益'),
        centerTitle: true,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
      ),
      bottomNavigationBar: HmBottomBar(
        child: HmBottomBarButton(
          text: '立即开通',
          primary: true,
          onPressed: () => ToastUtils.showToast(context, '会员开通暂未开放，敬请期待'),
        ),
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(
            maxWidth: HmBottomBar.maxContentWidth,
          ),
          child: ListView(
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 16),
            children: [
              _buildHeaderCard(),
              const SizedBox(height: 10),
              _buildBenefitsCard(),
              const SizedBox(height: 10),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 4),
                child: Text(
                  '会员权益为演示内容，尚未接入真实开通流程；'
                  '「立即开通」只会给出提示，不会产生扣费。',
                  style: TextStyle(
                    fontSize: 11,
                    height: 1.5,
                    color: AppColors.textSecondary,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeaderCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppRadius.card),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.vipBackground, AppColors.primarySurface],
        ),
      ),
      child: Row(
        children: [
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'HM 会员',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: AppColors.vipForeground,
                  ),
                ),
                SizedBox(height: 6),
                Text(
                  '开通会员，享受 4 项专属权益',
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.vipForeground,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(AppRadius.pill),
            ),
            child: const Text(
              '未开通',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: AppColors.vipForeground,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBenefitsCard() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppRadius.card),
      ),
      child: Column(
        children: [
          for (final benefit in benefits)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: const BoxDecoration(
                      color: AppColors.primarySurface,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      benefit.icon,
                      size: 20,
                      color: AppColors.primary,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          benefit.title,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          benefit.description,
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
