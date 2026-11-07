import 'package:flutter/material.dart';
import 'package:hm_shop/models/home.dart';

class HmCategory extends StatefulWidget {
  final List<CategoryItem> categoryList;

  HmCategory({Key? key, required this.categoryList}) : super(key: key);

  @override
  _HmCategoryState createState() => _HmCategoryState();
}

class _HmCategoryState extends State<HmCategory> {
  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 100,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: widget.categoryList.length,
        itemBuilder: (BuildContext context, int index) {
          final category = widget.categoryList[index];
          return Container(
            width: 80,
            height: 100,
            margin: EdgeInsets.symmetric(horizontal: 10),
            decoration: BoxDecoration(
              color: const Color.fromARGB(255, 235, 234, 234),
              borderRadius: BorderRadius.circular(40),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Image.network(category.picture, width: 40, height: 40),
                Text(
                  category.name,
                  style: TextStyle(fontSize: 12, color: Colors.black),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
