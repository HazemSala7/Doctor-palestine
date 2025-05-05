import 'package:fancy_shimmer_image/fancy_shimmer_image.dart';
import 'package:flutter/material.dart';

class CategoryCard extends StatelessWidget {
  final String name;
  final String imageUrl;
  final bool hasSub;
  final List<dynamic> subcategories;
  final String id;
  final BuildContext context;
  final void Function(int) changeTabIndex;
  final Function(String) onLanguageSelected;

  const CategoryCard({
    Key? key,
    required this.name,
    required this.imageUrl,
    required this.hasSub,
    required this.subcategories,
    required this.id,
    required this.context,
    required this.changeTabIndex,
    required this.onLanguageSelected,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      child: InkWell(
        onTap: () {},
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(10),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: FancyShimmerImage(
                  imageUrl: imageUrl,
                  errorWidget: Image.asset('assets/Yolo-Logo.png'),
                ),
              ),
            ),
            const SizedBox(height: 10),
            Text(
              name,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}
