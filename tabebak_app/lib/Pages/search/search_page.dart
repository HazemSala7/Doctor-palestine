import 'dart:async';

import 'package:clinic_dr_alla/Components/animations/animations.dart';
import 'package:clinic_dr_alla/Components/brand_widgets.dart';
import 'package:clinic_dr_alla/Components/ui_kit.dart';
import 'package:clinic_dr_alla/Constants/app_theme.dart';
import 'package:clinic_dr_alla/data/models.dart';
import 'package:clinic_dr_alla/data/repository.dart';
import 'package:flutter/material.dart';

/// Searches doctors and every other kind of listing at once.
class SearchPage extends StatefulWidget {
  const SearchPage({super.key});

  @override
  State<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> {
  final _controller = TextEditingController();
  Timer? _debounce;
  String _query = '';
  Future<List<Place>>? _future;

  static const _suggestions = [
    'أسنان', 'أطفال', 'صيدلية', 'رام الله', 'مختبر', 'قلب', 'نابلس', //
    'طوارئ 24 ساعة', 'عيون', 'توصيل للمنزل',
  ];

  void _search(String v) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 300), () {
      setState(() {
        _query = v.trim();
        _future = _query.isEmpty ? null : Repository.search(_query);
      });
    });
  }

  void _pick(String s) {
    _controller.text = s;
    _controller.selection = TextSelection.collapsed(offset: s.length);
    _search(s);
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final topInset = MediaQuery.of(context).padding.top;
    return Scaffold(
      backgroundColor: kBrandSurface,
      body: Column(
        children: [
          Container(
            padding: EdgeInsets.fromLTRB(16, topInset + 12, 16, 18),
            decoration: const BoxDecoration(
              gradient: kBrandGradient,
              borderRadius: BorderRadius.vertical(bottom: Radius.circular(30)),
            ),
            child: Row(
              children: [
                GlassButton(
                  onTap: () => Navigator.pop(context),
                  child: const Icon(Icons.arrow_back_ios_new_rounded,
                      color: Colors.white, size: 19),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Hero(
                    tag: 'search-bar',
                    child: Material(
                      color: Colors.transparent,
                      child: Container(
                        height: 52,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(18),
                        ),
                        child: TextField(
                          controller: _controller,
                          autofocus: true,
                          onChanged: _search,
                          textInputAction: TextInputAction.search,
                          decoration: InputDecoration(
                            hintText: 'طبيب، تخصص، صيدلية، مدينة...',
                            hintStyle: const TextStyle(color: kBrandMuted),
                            prefixIcon: const Icon(Icons.search_rounded,
                                color: kBrandPrimary),
                            suffixIcon: _controller.text.isEmpty
                                ? null
                                : IconButton(
                                    icon: const Icon(Icons.close_rounded,
                                        color: kBrandMuted),
                                    onPressed: () {
                                      _controller.clear();
                                      _search('');
                                    },
                                  ),
                            filled: false,
                            border: InputBorder.none,
                            enabledBorder: InputBorder.none,
                            focusedBorder: InputBorder.none,
                            contentPadding:
                                const EdgeInsets.symmetric(vertical: 15),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 300),
              child: _future == null ? _idle() : _results(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _idle() {
    return ListView(
      key: const ValueKey('idle'),
      padding: const EdgeInsets.all(20),
      children: [
        const Text('عمليات بحث شائعة 🔥',
            style: TextStyle(
                fontWeight: FontWeight.w800, fontSize: 16, color: kBrandText)),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 10,
          children: [
            for (var i = 0; i < _suggestions.length; i++)
              FadeSlideIn.item(
                index: i,
                child: PressableScale(
                  onTap: () => _pick(_suggestions[i]),
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: softShadow(),
                    ),
                    child: Text(_suggestions[i],
                        style: const TextStyle(
                            fontWeight: FontWeight.w700, color: kBrandText)),
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 28),
        const Text('تصفح حسب الفئة',
            style: TextStyle(
                fontWeight: FontWeight.w800, fontSize: 16, color: kBrandText)),
        const SizedBox(height: 12),
        GridView.count(
          crossAxisCount: 4,
          shrinkWrap: true,
          padding: EdgeInsets.zero,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: 10,
          crossAxisSpacing: 10,
          childAspectRatio: 0.85,
          children: [
            for (var i = 0; i < PlaceKind.values.length; i++)
              FadeSlideIn.item(
                index: i,
                child: PressableScale(
                  onTap: () => _pick(PlaceKind.values[i].plural),
                  child: Column(
                    children: [
                      Container(
                        width: 56,
                        height: 56,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          gradient: PlaceKind.values[i].gradient,
                          borderRadius: BorderRadius.circular(18),
                        ),
                        child: Text(PlaceKind.values[i].emoji,
                            style: const TextStyle(fontSize: 26)),
                      ),
                      const SizedBox(height: 6),
                      Text(PlaceKind.values[i].short,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                              fontSize: 11.5,
                              fontWeight: FontWeight.w700,
                              color: kBrandText)),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ],
    );
  }

  Widget _results() {
    return FutureBuilder<List<Place>>(
      key: ValueKey(_query),
      future: _future,
      builder: (context, snap) {
        if (snap.connectionState != ConnectionState.done) {
          return ListView(
            padding: const EdgeInsets.only(top: 16),
            children: List.generate(4, (_) => const PlaceCardSkeleton()),
          );
        }
        final list = snap.data ?? [];
        if (list.isEmpty) {
          return EmptyState(
            title: 'لا نتائج لـ "$_query"',
            subtitle: 'جرّب كلمة أخرى مثل اسم تخصص أو مدينة',
          );
        }
        // Group by kind, doctors first.
        final groups = <PlaceKind, List<Place>>{};
        for (final p in list) {
          groups.putIfAbsent(p.kind, () => []).add(p);
        }
        final children = <Widget>[];
        var i = 0;
        for (final e in groups.entries) {
          children.add(Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 10),
            child: Row(
              children: [
                Text('${e.key.emoji}  ${e.key.plural}',
                    style: const TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 16,
                        color: kBrandText)),
                const SizedBox(width: 8),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 1),
                  decoration: BoxDecoration(
                    gradient: e.key.gradient,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text('${e.value.length}',
                      style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w800,
                          fontSize: 12)),
                ),
              ],
            ),
          ));
          for (final p in e.value) {
            children
                .add(FadeSlideIn.item(index: i++, child: PlaceCard(place: p)));
          }
        }
        return ListView(
          padding: const EdgeInsets.only(bottom: 30),
          physics: const BouncingScrollPhysics(),
          children: children,
        );
      },
    );
  }
}
