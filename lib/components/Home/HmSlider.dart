import 'package:carousel_slider/carousel_slider.dart';
import 'package:flutter/material.dart';
import 'package:hm_shop/models/home.dart';

class HmSlider extends StatefulWidget {
  final List<BannerItem> bannerList;

  HmSlider({Key? key, required this.bannerList}) : super(key: key);

  @override
  _HmSliderState createState() => _HmSliderState();
}

class _HmSliderState extends State<HmSlider> {
  final CarouselSliderController _controller = CarouselSliderController();

  int _currentIndex = 0;

  Widget _getSlider() {
    final double screenWidth = MediaQuery.of(context).size.width;

    return CarouselSlider(
      carouselController: _controller,
      items: List.generate(widget.bannerList.length, (int index) {
        return Image.network(
          widget.bannerList[index].imageUrl,
          fit: BoxFit.cover,
          width: screenWidth,
        );
      }),
      options: CarouselOptions(
        viewportFraction: 1.0,
        autoPlay: true,
        // autoPlayInterval: Duration(seconds: 2),
        height: 300,
        onPageChanged: (index, reason) {
          setState(() {
            _currentIndex = index;
          });
        },
      ),
    );
  }

  Widget _getSearch() {
    return Positioned(
      top: 10,
      left: 0,
      right: 0,
      child: Padding(
        padding: EdgeInsets.all(10),
        child: Container(
          alignment: Alignment.centerLeft,
          padding: EdgeInsets.symmetric(horizontal: 20),
          height: 50,
          decoration: BoxDecoration(
            color: const Color.fromRGBO(0, 0, 0, 0.4),
            borderRadius: BorderRadius.circular(25),
          ),
          child: Text(
            '搜索...',
            style: TextStyle(color: Colors.white, fontSize: 20),
          ),
        ),
      ),
    );
  }

  Widget _getDots() {
    return Positioned(
      left: 0,
      right: 0,
      bottom: 10,
      child: SizedBox(
        height: 40,
        width: double.infinity,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(widget.bannerList.length, (int index) {
            return GestureDetector(
              onTap: () {
                _controller.animateToPage(index);
              },
              child: AnimatedContainer(
                duration: Duration(milliseconds: 300),
                width: index == _currentIndex ? 40 : 20,
                height: 6,
                margin: EdgeInsets.symmetric(horizontal: 10),
                decoration: BoxDecoration(
                  color: index == _currentIndex
                      ? Colors.white
                      : Colors.grey.shade400,
                  borderRadius: BorderRadius.circular(5),
                ),
              ),
            );
          }),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Stack(children: [_getSlider(), _getSearch(), _getDots()]);
  }
}
