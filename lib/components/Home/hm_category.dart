import 'package:flutter/material.dart';
import 'package:hm_shop/components/common/app_network_image.dart';
import 'package:hm_shop/constants/app_theme.dart';
import 'package:hm_shop/models/home.dart';

class HmCategory extends StatelessWidget {
  final List<CategoryItem> categoryList;

  const HmCategory({super.key, required this.categoryList});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 100,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: categoryList.length,
        itemBuilder: (BuildContext context, int index) {
          final category = categoryList[index];
          return Container(
            width: 80,
            height: 100,
            margin: const EdgeInsets.symmetric(horizontal: 10),
            decoration: BoxDecoration(
              color: AppColors.categoryTile,
              borderRadius: BorderRadius.circular(40),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                AppNetworkImage(
                  url: category.picture,
                  width: 40,
                  height: 40,
                  decodeWidth: 40,
                  placeholderIconSize: 32,
                ),
                Text(
                  category.name,
                  style: const TextStyle(fontSize: 12, color: Colors.black),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
