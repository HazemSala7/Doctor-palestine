import 'package:clinic_dr_alla/Constants/app_theme.dart';
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

/// Shown when there are no slides or a slide fails to load.
class BrandPlaceholder extends StatelessWidget {
  const BrandPlaceholder({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      alignment: Alignment.center,
      padding: const EdgeInsets.all(24),
      child: Image.asset(kLogoAsset, fit: BoxFit.contain),
    );
  }
}

class _SlideImageState extends State<SlideImage> {
  @override
  Widget build(BuildContext context) {
    if (widget.slideimage.isEmpty) {
      return const BrandPlaceholder();
    }

    return ImageSlideshow(
      width: double.infinity,
      height: double.infinity,
      indicatorColor: Colors.white,
      indicatorBackgroundColor: Colors.white.withValues(alpha: 0.45),
      indicatorRadius: 4,
      autoPlayInterval: 3500,
      isLoop: true,
      children: widget.slideimage
          .map(
            (e) => FancyShimmerImage(
              imageUrl: e.image,
              boxFit: BoxFit.cover,
              width: double.infinity,
              height: double.infinity,
              shimmerBaseColor: kBrandSky,
              shimmerHighlightColor: Colors.white,
              errorWidget: const BrandPlaceholder(),
            ),
          )
          .toList(),
    );
  }
}
