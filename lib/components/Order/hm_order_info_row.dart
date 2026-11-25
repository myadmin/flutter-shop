import 'package:flutter/material.dart';
import 'package:hm_shop/constants/app_text_styles.dart';
import 'package:hm_shop/constants/app_theme.dart';

/// 订单详情里的「标签 + 值」一行
///
/// 左右两端对齐，值过长时右侧省略；需要突出显示（如金额）时传 [emphasize]。
class HmOrderInfoRow extends StatelessWidget {
  const HmOrderInfoRow({
    super.key,
    required this.label,
    required this.value,
    this.emphasize = false,
  });

  final String label;
  final String value;

  /// 金额等需要强调的值：主色 + 加粗 + 略大字号
  final bool emphasize;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(width: 72, child: Text(label, style: AppTextStyles.caption)),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: TextStyle(
                fontSize: emphasize ? 15 : 12,
                fontWeight: emphasize ? FontWeight.w700 : FontWeight.normal,
                color: emphasize ? AppColors.primary : Colors.black,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
