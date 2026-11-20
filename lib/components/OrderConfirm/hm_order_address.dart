import 'package:flutter/material.dart';
import 'package:hm_shop/components/OrderConfirm/hm_order_card.dart';
import 'package:hm_shop/constants/app_theme.dart';
import 'package:hm_shop/models/order.dart';

/// 订单确认页的收货地址卡片
///
/// [address] 为空时展示占位文案，避免整块卡片消失导致页面跳动。
class HmOrderAddress extends StatelessWidget {
  final OrderAddress? address;

  const HmOrderAddress({super.key, required this.address});

  @override
  Widget build(BuildContext context) {
    final address = this.address;
    return OrderCard(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.location_on_outlined,
            size: 22,
            color: AppColors.primary,
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
}
