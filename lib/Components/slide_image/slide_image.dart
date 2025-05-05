import 'package:clinic_dr_alla/model/slider_model.dart';
import 'package:flutter/material.dart';
import 'package:flutter_image_slideshow/flutter_image_slideshow.dart';
import 'package:fancy_shimmer_image/fancy_shimmer_image.dart';

// ignore: must_be_immutable
class SlideImage extends StatefulWidget {
  List<SliderModel> slideimage;
  SlideImage({
    Key? key,
    required this.slideimage,
  }) : super(key: key);

  @override
  State<SlideImage> createState() => _SlideImageState();
}

class _SlideImageState extends State<SlideImage> {
  @override
  Widget build(BuildContext context) {
    if (widget.slideimage.isEmpty) {
      return Container(
        height: 220,
        child: Center(child: Image.asset('assets/Yolo-Logo.png')),
      );
    }

    return StatefulBuilder(
      builder: (BuildContext context, StateSetter setState) {
        return ImageSlideshow(
          width: double.infinity,
          height: 220,
          children: widget.slideimage
              .map(
                (e) => FancyShimmerImage(
                  imageUrl: e.image,
                  boxFit: BoxFit.cover,
                  width: double.infinity,
                  height: MediaQuery.of(context).size.height * 0.3,
                  errorWidget: Image.asset('assets/Yolo-Logo.png'),
                  // Image.asset('assets/no-image.png'),
                ),
              )
              .toList(),
          autoPlayInterval: 3000,
          isLoop: true,
        );
      },
    );
  }
}
