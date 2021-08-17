import 'package:afk_redeem/ui/appearance_manager.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:flutter/material.dart';

Dialog carouselDialog(BuildContext context, List<Widget> items) {
  return Dialog(
    insetPadding: EdgeInsets.all(20.0),
    child: Container(
      height: 450.0,
      width: 450.0,
      child: CarouselViewer(items),
    ),
  );
}

class CarouselViewer extends StatefulWidget {
  final List<Widget> items;
  final double? height;
  final double? aspectRatio;
  final bool? autoPlay;

  CarouselViewer(this.items, {this.height, this.aspectRatio, this.autoPlay});

  @override
  _CarouselViewerState createState() => _CarouselViewerState();
}

class _CarouselViewerState extends State<CarouselViewer> {
  final CarouselController _controller = CarouselController();
  int _current = 0;
  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: CarouselSlider(
            items: widget.items,
            carouselController: _controller,
            options: CarouselOptions(
                height: widget.height,
                viewportFraction: 0.95,
                autoPlay: widget.autoPlay ?? false,
                // enlargeCenterPage: false,
                enableInfiniteScroll: false,
                aspectRatio: widget.aspectRatio ?? 1.0,
                onPageChanged: (index, reason) {
                  setState(() {
                    _current = index;
                  });
                }),
          ),
        ),
        if (widget.items.length > 1)
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: widget.items.asMap().entries.map((entry) {
              return GestureDetector(
                onTap: () => _controller.animateToPage(entry.key),
                child: Container(
                  width: 12.0,
                  height: 12.0,
                  margin: EdgeInsets.symmetric(vertical: 8.0, horizontal: 4.0),
                  decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppearanceManager()
                          .color
                          .main
                          .withOpacity(_current == entry.key ? 0.9 : 0.4)),
                ),
              );
            }).toList(),
          ),
      ],
    );
  }
}
