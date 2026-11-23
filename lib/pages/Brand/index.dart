import 'package:flutter/material.dart';
import 'package:hm_shop/api/brand.dart';
import 'package:hm_shop/components/common/app_error_view.dart';
import 'package:hm_shop/components/common/app_network_image.dart';
import 'package:hm_shop/components/common/hm_bottom_bar.dart';
import 'package:hm_shop/constants/app_theme.dart';
import 'package:hm_shop/models/brand.dart';
import 'package:hm_shop/utils/api_exception.dart';

/// 品牌详情页：`/brand?id=<品牌 id>`
///
/// 数据来自 `/brand/<品牌 id>`，展示品牌 logo、中英文名、产地与品牌故事。
/// 后端没有「按品牌查商品」的接口，所以这里不放商品列表。
class BrandPage extends StatefulWidget {
  const BrandPage({super.key, required this.brandId});

  final String brandId;

  @override
  State<BrandPage> createState() => _BrandPageState();
}

class _BrandPageState extends State<BrandPage> {
  BrandDetail? _detail;
  bool _isLoading = true;
  String _errorMessage = '';

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    if (widget.brandId.isEmpty) {
      setState(() {
        _isLoading = false;
        _errorMessage = '品牌信息缺失，请返回重新进入';
      });
      return;
    }
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });
    try {
      final detail = await getBrandDetailAPI(widget.brandId);
      if (!mounted) return;
      setState(() {
        _detail = detail;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _errorMessage = resolveErrorMessage(e, fallback: '品牌信息加载失败');
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.pageBackground,
      appBar: AppBar(
        title: const Text('品牌详情'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    final String errorMessage = _errorMessage;
    if (errorMessage.isNotEmpty) {
      return AppErrorView(message: errorMessage, onRetry: _load);
    }
    final detail = _detail;
    if (detail == null) {
      return AppErrorView(message: '品牌信息加载失败', onRetry: _load);
    }
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(
          maxWidth: HmBottomBar.maxContentWidth,
        ),
        child: ListView(
          padding: const EdgeInsets.fromLTRB(10, 10, 10, 20),
          children: [
            _buildHeaderCard(detail),
            const SizedBox(height: 10),
            _buildStoryCard(detail),
          ],
        ),
      ),
    );
  }

  /// 品牌基本信息卡片：logo、中英文名、口号、产地、收藏数
  Widget _buildHeaderCard(BrandDetail detail) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppRadius.card),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(AppRadius.image),
                child: AppNetworkImage(
                  url: detail.logo,
                  width: 64,
                  height: 64,
                  fit: BoxFit.contain,
                  decodeWidth: 64,
                  placeholderIconSize: 28,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      detail.displayName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: Colors.black87,
                      ),
                    ),
                    if (detail.nameEn.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        detail.nameEn,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                    if (detail.productionPlace.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        '产地：${detail.productionPlace}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
          if (detail.slogan.isNotEmpty) ...[
            const SizedBox(height: 12),
            Text(
              detail.slogan,
              style: const TextStyle(
                fontSize: 13,
                height: 1.5,
                color: Colors.black87,
              ),
            ),
          ],
          if (detail.collectNum > 0) ...[
            const SizedBox(height: 10),
            Text(
              '${detail.collectNum} 人关注',
              style: const TextStyle(
                fontSize: 12,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ],
      ),
    );
  }

  /// 品牌故事卡片
  Widget _buildStoryCard(BrandDetail detail) {
    final String story = detail.brandStory.isNotEmpty
        ? detail.brandStory
        : '暂无品牌故事';
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppRadius.card),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '品牌故事',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: AppColors.darkBrown,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            story,
            style: TextStyle(
              fontSize: 13,
              height: 1.6,
              color: detail.brandStory.isNotEmpty
                  ? Colors.black87
                  : AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}
