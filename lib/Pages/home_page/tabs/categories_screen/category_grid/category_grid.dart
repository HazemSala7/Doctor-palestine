import 'package:clinic_dr_alla/Pages/home_page/tabs/categories_screen/category_card/category_card.dart';
import 'package:flutter/material.dart';

class CategoryGrid extends StatelessWidget {
  final List<dynamic> categories;
  final String languageCode;
  final void Function(int) changeTabIndex;
  final Function(String) onLanguageSelected;

  const CategoryGrid({
    Key? key,
    required this.categories,
    required this.languageCode,
    required this.changeTabIndex,
    required this.onLanguageSelected,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: MediaQuery.of(context).size.width * 0.03,
        mainAxisSpacing: MediaQuery.of(context).size.width * 0.02,
        childAspectRatio: MediaQuery.of(context).size.width < 380 ? 0.75 : 0.80,
      ),
      itemCount: categories.length,
      itemBuilder: (context, index) {
        var category = categories[index];
        return CategoryCard(
          name: languageCode == "ar"
              ? category['name_ar']
              : languageCode == "en"
                  ? category['name_en']
                  : category['name_he'],
          imageUrl: category['image'],
          id: category['id'].toString(),
          hasSub: category['has_subcategories'] ?? false,
          subcategories: category['subcategories'] ?? [],
          context: context,
          changeTabIndex: changeTabIndex,
          onLanguageSelected: onLanguageSelected,
        );
      },
    );
  }
}
