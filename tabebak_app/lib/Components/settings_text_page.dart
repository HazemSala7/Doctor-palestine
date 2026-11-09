import 'package:clinic_dr_alla/Components/animations/animations.dart';
import 'package:clinic_dr_alla/Components/brand_widgets.dart';
import 'package:clinic_dr_alla/Components/page_header.dart';
import 'package:clinic_dr_alla/Constants/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_html/flutter_html.dart';

/// A page of text written on the dashboard (About us, Privacy policy).
/// Plain text: each line is a paragraph, "- " lines are bullets and
/// "1. " lines are headings. Text containing HTML tags is rendered as HTML.
class SettingsTextPage extends StatelessWidget {
  final String title;
  final String emoji;
  final String text;

  const SettingsTextPage(
      {super.key, required this.title, required this.emoji, required this.text});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBrandSurface,
      body: ListView(
        padding: EdgeInsets.zero,
        physics: const BouncingScrollPhysics(),
        children: [
          GradientPageHeader(
            title: title,
            subtitle: 'طبيبك',
            emoji: emoji,
            colors: const [kBrandDark, kBrandPrimary, Color(0xFF29B6F6)],
          ),
          if (text.trim().isEmpty)
            const Padding(
              padding: EdgeInsets.only(top: 40),
              child: EmptyState(title: 'لا يوجد محتوى بعد', subtitle: ''),
            )
          else
            FadeSlideIn(
              delay: const Duration(milliseconds: 100),
              child: Container(
                margin: const EdgeInsets.fromLTRB(16, 18, 16, 40),
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(26),
                  boxShadow: softShadow(),
                ),
                child: RegExp(r'<[a-zA-Z/][^>]*>').hasMatch(text)
                    ? Html(data: text)
                    : Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [for (final line in text.split('\n')) _line(line)],
                      ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _line(String raw) {
    final line = raw.trim();
    if (line.isEmpty) return const SizedBox(height: 10);
    const body = TextStyle(height: 1.8, color: Color(0xFF3B4A63), fontSize: 14.5);
    if (line.startsWith('- ') || line.startsWith('• ')) {
      return Padding(
        padding: const EdgeInsetsDirectional.only(start: 6, bottom: 2),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Padding(
              padding: EdgeInsets.only(top: 11),
              child: CircleAvatar(radius: 3, backgroundColor: kBrandPrimary),
            ),
            const SizedBox(width: 10),
            Expanded(child: Text(line.substring(2), style: body)),
          ],
        ),
      );
    }
    if (RegExp(r'^\d+[.)-]\s').hasMatch(line)) {
      return Padding(
        padding: const EdgeInsets.only(top: 8, bottom: 2),
        child: Text(line,
            style: const TextStyle(
                fontSize: 16, fontWeight: FontWeight.w800, color: kBrandText)),
      );
    }
    return Text(line, style: body);
  }
}
