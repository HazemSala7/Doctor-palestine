import 'dart:async';

import 'package:clinic_dr_alla/Components/animations/animations.dart';
import 'package:clinic_dr_alla/Components/animations/effects.dart';
import 'package:clinic_dr_alla/Components/ui_kit.dart';
import 'package:clinic_dr_alla/Constants/app_theme.dart';
import 'package:clinic_dr_alla/data/models.dart';
import 'package:clinic_dr_alla/data/repository.dart';
import 'package:flutter/material.dart';

/// Browsable, filterable list for any [PlaceKind].
class PlacesPage extends StatefulWidget {
  final PlaceKind kind;
  final int? initialCityId;
  final String? initialSpecialty;

  /// True when shown as a bottom-nav tab (no back button, room for the bar).
  final bool embedded;

  const PlacesPage({
    super.key,
    required this.kind,
    this.initialCityId,
    this.initialSpecialty,
    this.embedded = false,
  });

  @override
  State<PlacesPage> createState() => _PlacesPageState();
}

class _PlacesPageState extends State<PlacesPage> {
  late int? _cityId = widget.initialCityId;
  late String? _specialty = widget.initialSpecialty;
  String _query = '';
  Timer? _debounce;
  List<City> _cities = [];
  late Future<List<Place>> _future;

  PlaceKind get kind => widget.kind;

  @override
  void initState() {
    super.initState();
    _load();
    Repository.cities().then((c) {
      if (mounted) setState(() => _cities = c);
    });
  }

  void _load() {
    _future = Repository.places(kind,
        cityId: _cityId, specialty: _specialty, query: _query);
  }

  void _reload() => setState(_load);

  void _onSearch(String v) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 400), () {
      _query = v;
      _reload();
    });
  }

  @override
  void dispose() {
    _debounce?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final topInset = MediaQuery.of(context).padding.top;

    return Scaffold(
      backgroundColor: kBrandSurface,
      body: FutureBuilder<List<Place>>(
        future: _future,
        builder: (context, snap) {
          return RefreshIndicator(
            color: kind.colors.first,
            edgeOffset: 200,
            onRefresh: () async {
              _reload();
              await _future;
            },
            child: CustomScrollView(
              physics: const BouncingScrollPhysics(
                  parent: AlwaysScrollableScrollPhysics()),
              slivers: [
                SliverToBoxAdapter(child: _header(topInset, snap)),
                SliverToBoxAdapter(child: _filters()),
                placesSliver(snap),
                SliverToBoxAdapter(
                    child: SizedBox(height: widget.embedded ? 120 : 24)),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _header(double topInset, AsyncSnapshot<List<Place>> snap) {
    final done = snap.connectionState == ConnectionState.done;
    return ClipRRect(
      borderRadius: const BorderRadius.vertical(bottom: Radius.circular(36)),
      child: AuroraBackground(
        colors: [kind.colors.first, kind.colors.last],
        child: Stack(
          children: [
            const Positioned.fill(child: FloatingBubbles(count: 12)),
            PositionedDirectional(
              end: 18,
              top: topInset + 46,
              child: FloatingWidget(
                distance: 10,
                child: Opacity(
                  opacity: 0.9,
                  child: Text(kind.emoji, style: const TextStyle(fontSize: 86)),
                ),
              ),
            ),
            Padding(
              padding: EdgeInsets.fromLTRB(16, topInset + 10, 16, 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    height: 44,
                    child: widget.embedded
                        ? null
                        : Align(
                            alignment: AlignmentDirectional.centerStart,
                            child: GlassButton(
                              onTap: () => Navigator.pop(context),
                              child: const Icon(
                                  Icons.arrow_back_ios_new_rounded,
                                  color: Colors.white,
                                  size: 19),
                            ),
                          ),
                  ),
                  const SizedBox(height: 14),
                  FadeSlideIn(
                    offset: const Offset(0.2, 0),
                    child: Text(
                      _specialty ?? kind.plural,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 30,
                        fontWeight: FontWeight.w900,
                        height: 1.1,
                      ),
                    ),
                  ),
                  const SizedBox(height: 4),
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 300),
                    child: done
                        ? Row(
                            key: ValueKey(snap.data?.length),
                            children: [
                              CountUp(
                                value: snap.data?.length ?? 0,
                                duration: const Duration(milliseconds: 800),
                                style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w900,
                                    fontSize: 15),
                              ),
                              Text(
                                ' نتيجة متاحة${_cityId != null ? ' في ${_cityName()}' : ''}',
                                style: TextStyle(
                                    color: Colors.white.withValues(alpha: 0.9),
                                    fontSize: 14),
                              ),
                            ],
                          )
                        : Text('جارِ البحث...',
                            key: const ValueKey('loading'),
                            style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.9))),
                  ),
                  const SizedBox(height: 16),
                  _searchField(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _cityName() =>
      _cities.where((c) => c.id == _cityId).map((c) => c.name).firstOrNull ??
      '';

  Widget _searchField() {
    return Container(
      height: 52,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.12),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: TextField(
        onChanged: _onSearch,
        textInputAction: TextInputAction.search,
        decoration: InputDecoration(
          hintText: 'ابحث في ${kind.plural}...',
          hintStyle: const TextStyle(color: kBrandMuted, fontSize: 14),
          prefixIcon: Icon(Icons.search_rounded, color: kind.colors.first),
          filled: false,
          border: InputBorder.none,
          enabledBorder: InputBorder.none,
          focusedBorder: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(vertical: 15),
        ),
      ),
    );
  }

  Widget _filters() {
    final specialties = Repository.specialties();
    return Padding(
      padding: const EdgeInsets.only(top: 16, bottom: 10),
      child: Column(
        children: [
          if (_cities.isNotEmpty)
            ChoiceChipsRow<int>(
              values: [null, ..._cities.map((c) => c.id)],
              selected: _cityId,
              activeColors: kind.colors,
              label: (id) => id == null
                  ? 'كل المدن'
                  : _cities.firstWhere((c) => c.id == id).name,
              emoji: (id) => id == null
                  ? '🗺️'
                  : _cities.firstWhere((c) => c.id == id).emoji,
              onSelected: (id) {
                _cityId = id;
                _reload();
              },
            ),
          if (kind == PlaceKind.doctor) ...[
            const SizedBox(height: 8),
            ChoiceChipsRow<String>(
              values: [null, ...specialties.map((s) => s.name)],
              selected: _specialty,
              activeColors: kind.colors,
              label: (s) => s ?? 'كل التخصصات',
              emoji: (s) => s == null
                  ? '✨'
                  : specialties.firstWhere((x) => x.name == s).emoji,
              onSelected: (s) {
                _specialty = s;
                _reload();
              },
            ),
          ],
        ],
      ),
    );
  }
}
