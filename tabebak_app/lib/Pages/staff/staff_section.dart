import 'package:clinic_dr_alla/Components/animations/animations.dart';
import 'package:clinic_dr_alla/Components/brand_widgets.dart';
import 'package:clinic_dr_alla/Components/ui_kit.dart';
import 'package:clinic_dr_alla/Constants/app_theme.dart';
import 'package:clinic_dr_alla/Pages/booking/booking_widgets.dart';
import 'package:clinic_dr_alla/data/models.dart';
import 'package:clinic_dr_alla/data/staff.dart';
import 'package:flutter/material.dart';

/// "طاقم العمل" on a doctor's or centre's page. Hidden while it has no one.
class PlaceStaffSection extends StatefulWidget {
  final Place place;
  final int delay;

  const PlaceStaffSection({super.key, required this.place, this.delay = 0});

  @override
  State<PlaceStaffSection> createState() => _PlaceStaffSectionState();
}

class _PlaceStaffSectionState extends State<PlaceStaffSection> {
  List<StaffMember>? _team;

  @override
  void initState() {
    super.initState();
    StaffApi.list(widget.place.kind, widget.place.id).then((team) {
      if (mounted) setState(() => _team = team);
    }).catchError((_) {
      // A section that fails to load just stays hidden.
      if (mounted) setState(() => _team = const []);
    });
  }

  void _open(StaffMember m) => showModalBottomSheet<void>(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (_) => _StaffSheet(member: m, kind: widget.place.kind),
      );

  @override
  Widget build(BuildContext context) {
    final team = _team;
    if (team == null || team.isEmpty) return const SizedBox.shrink();
    final color = widget.place.kind.colors.first;
    return FadeSlideIn(
      delay: Duration(milliseconds: widget.delay),
      child: Container(
        margin: const EdgeInsets.fromLTRB(16, 16, 16, 0),
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(26),
          boxShadow: softShadow(),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(children: [
                const Text('👥', style: TextStyle(fontSize: 18)),
                const SizedBox(width: 8),
                const Text('طاقم العمل',
                    style: TextStyle(
                        fontSize: 16.5,
                        fontWeight: FontWeight.w800,
                        color: kBrandText)),
                const SizedBox(width: 8),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 9, vertical: 2),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text('${team.length}',
                      style: TextStyle(
                          color: color,
                          fontWeight: FontWeight.w800,
                          fontSize: 12.5)),
                ),
              ]),
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: 178,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: team.length,
                separatorBuilder: (_, __) => const SizedBox(width: 10),
                itemBuilder: (_, i) => FadeSlideIn.item(
                  index: i,
                  child: _StaffCard(
                    member: team[i],
                    color: color,
                    gradient: widget.place.kind.gradient,
                    onTap: () => _open(team[i]),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class StaffAvatar extends StatelessWidget {
  final StaffMember member;
  final double size;
  final Gradient gradient;

  const StaffAvatar(
      {super.key, required this.member, required this.size, required this.gradient});

  @override
  Widget build(BuildContext context) {
    final url = member.imageUrl ?? member.doctor?.logoUrl;
    final hasImage = url != null && url.isNotEmpty && !url.endsWith('/storage/');
    return ClipOval(
      child: hasImage
          ? NetImage(url, width: size, height: size, fit: BoxFit.cover)
          : Container(
              width: size,
              height: size,
              decoration: BoxDecoration(gradient: gradient),
              alignment: Alignment.center,
              child: Text(member.initials,
                  style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                      fontSize: size * 0.3)),
            ),
    );
  }
}

class _StaffCard extends StatelessWidget {
  final StaffMember member;
  final Color color;
  final Gradient gradient;
  final VoidCallback onTap;

  const _StaffCard(
      {required this.member,
      required this.color,
      required this.gradient,
      required this.onTap});

  @override
  Widget build(BuildContext context) => PressableScale(
        pressedScale: 0.95,
        onTap: onTap,
        child: Container(
          width: 128,
          padding: const EdgeInsets.fromLTRB(10, 14, 10, 10),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: color.withValues(alpha: 0.12)),
          ),
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(2.5),
                decoration: BoxDecoration(gradient: gradient, shape: BoxShape.circle),
                child: Container(
                  padding: const EdgeInsets.all(2),
                  decoration: const BoxDecoration(
                      color: Colors.white, shape: BoxShape.circle),
                  child: StaffAvatar(member: member, size: 58, gradient: gradient),
                ),
              ),
              const SizedBox(height: 8),
              Text(member.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                      fontWeight: FontWeight.w800,
                      color: kBrandText,
                      fontSize: 13.5)),
              const SizedBox(height: 3),
              Text(member.role,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                      color: kBrandMuted, fontSize: 11.5, height: 1.35)),
              const Spacer(),
              if (member.doctor != null)
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.verified_rounded, size: 13, color: color),
                    const SizedBox(width: 3),
                    Text('ملفه في التطبيق',
                        style: TextStyle(
                            color: color,
                            fontSize: 11,
                            fontWeight: FontWeight.w800)),
                  ],
                ),
            ],
          ),
        ),
      );
}

class _StaffSheet extends StatelessWidget {
  final StaffMember member;
  final PlaceKind kind;

  const _StaffSheet({required this.member, required this.kind});

  @override
  Widget build(BuildContext context) {
    final color = kind.colors.first;
    final doctor = member.doctor;
    return Container(
      padding: EdgeInsets.fromLTRB(
          20, 12, 20, 20 + MediaQuery.of(context).padding.bottom),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Center(
            child: Container(
              width: 42,
              height: 5,
              decoration: BoxDecoration(
                  color: Colors.black12, borderRadius: BorderRadius.circular(3)),
            ),
          ),
          const SizedBox(height: 18),
          Center(
            child: Container(
              padding: const EdgeInsets.all(3),
              decoration:
                  BoxDecoration(gradient: kind.gradient, shape: BoxShape.circle),
              child: Container(
                padding: const EdgeInsets.all(3),
                decoration: const BoxDecoration(
                    color: Colors.white, shape: BoxShape.circle),
                child:
                    StaffAvatar(member: member, size: 96, gradient: kind.gradient),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Text(member.name,
              textAlign: TextAlign.center,
              style: const TextStyle(
                  fontSize: 19, fontWeight: FontWeight.w900, color: kBrandText)),
          const SizedBox(height: 6),
          Center(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Text(member.role,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                      color: color, fontWeight: FontWeight.w800, fontSize: 13)),
            ),
          ),
          if (doctor?.specialty != null) ...[
            const SizedBox(height: 6),
            Text('${doctor!.specialty} • ${doctor.city}',
                textAlign: TextAlign.center,
                style: const TextStyle(color: kBrandMuted, fontSize: 12.5)),
          ],
          if (member.bio != null) ...[
            const SizedBox(height: 14),
            Text(member.bio!,
                textAlign: TextAlign.center,
                style: const TextStyle(
                    height: 1.7, color: Color(0xFF3B4A63), fontSize: 14)),
          ],
          if (doctor != null) ...[
            const SizedBox(height: 18),
            GradientButton(
              label: doctor.bookingEnabled ? 'عرض الملف والحجز' : 'عرض ملف الطبيب',
              icon: Icons.person_search_rounded,
              onTap: () {
                Navigator.pop(context);
                openPlace(context, doctor);
              },
            ),
          ],
          const SizedBox(height: 4),
        ],
      ),
    );
  }
}
