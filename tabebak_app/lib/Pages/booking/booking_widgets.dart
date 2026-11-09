import 'package:clinic_dr_alla/Components/animations/animations.dart';
import 'package:clinic_dr_alla/Constants/app_theme.dart';
import 'package:clinic_dr_alla/data/booking.dart';
import 'package:flutter/material.dart';

const kPendingColor = Color(0xFFEF6C00);
const kCancelledColor = Color(0xFFE53935);

Color statusColor(AppointmentStatus s) => switch (s) {
      AppointmentStatus.pending => kPendingColor,
      AppointmentStatus.confirmed => kBrandSuccess,
      AppointmentStatus.completed => kBrandPrimary,
      AppointmentStatus.cancelled => kCancelledColor,
    };

String statusEmoji(AppointmentStatus s) => switch (s) {
      AppointmentStatus.pending => '⏳',
      AppointmentStatus.confirmed => '✅',
      AppointmentStatus.completed => '🩺',
      AppointmentStatus.cancelled => '✖️',
    };

class StatusBadge extends StatelessWidget {
  final AppointmentStatus status;

  const StatusBadge(this.status, {super.key});

  @override
  Widget build(BuildContext context) {
    final color = statusColor(status);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text('${statusEmoji(status)} ${status.label}',
          style: TextStyle(
              color: color, fontWeight: FontWeight.w800, fontSize: 12)),
    );
  }
}

/// White rounded card with an emoji title, as on the details page.
class SectionCard extends StatelessWidget {
  final String title;
  final String emoji;
  final Widget child;
  final Widget? trailing;
  final int delay;

  const SectionCard({
    super.key,
    required this.title,
    required this.emoji,
    required this.child,
    this.trailing,
    this.delay = 0,
  });

  @override
  Widget build(BuildContext context) {
    return FadeSlideIn(
      delay: Duration(milliseconds: delay),
      child: Container(
        margin: const EdgeInsets.fromLTRB(16, 16, 16, 0),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(26),
          boxShadow: softShadow(),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              Text(emoji, style: const TextStyle(fontSize: 18)),
              const SizedBox(width: 8),
              Expanded(
                child: Text(title,
                    style: const TextStyle(
                        fontSize: 16.5,
                        fontWeight: FontWeight.w800,
                        color: kBrandText)),
              ),
              if (trailing != null) trailing!,
            ]),
            const SizedBox(height: 12),
            child,
          ],
        ),
      ),
    );
  }
}

/// Full-width gradient call to action.
class GradientButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback? onTap;
  final bool loading;
  final List<Color> colors;

  const GradientButton({
    super.key,
    required this.label,
    required this.icon,
    this.onTap,
    this.loading = false,
    this.colors = const [kBrandDark, kBrandPrimary, kBrandLight],
  });

  @override
  Widget build(BuildContext context) {
    final enabled = onTap != null && !loading;
    return PressableScale(
      onTap: enabled ? onTap : null,
      child: AnimatedOpacity(
        duration: const Duration(milliseconds: 250),
        opacity: onTap == null ? 0.5 : 1,
        child: Container(
          height: 56,
          decoration: BoxDecoration(
            gradient: LinearGradient(colors: colors),
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                  color: colors.first.withValues(alpha: 0.35),
                  blurRadius: 16,
                  offset: const Offset(0, 6)),
            ],
          ),
          alignment: Alignment.center,
          child: loading
              ? const SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(
                      color: Colors.white, strokeWidth: 2.6))
              : Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(icon, color: Colors.white),
                    const SizedBox(width: 8),
                    Flexible(
                      child: Text(label,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w800,
                              fontSize: 15.5)),
                    ),
                  ],
                ),
        ),
      ),
    );
  }
}

void showMessage(BuildContext context, String message) {
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(content: Text(message)));
}

/// Input styling used by the booking and doctor forms.
InputDecoration fieldDecoration(String label,
        {String? hint, IconData? icon, String? error, Widget? suffix}) =>
    InputDecoration(
      labelText: label,
      hintText: hint,
      errorText: error,
      prefixIcon: icon == null ? null : Icon(icon, color: kBrandPrimary),
      suffixIcon: suffix,
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
    );
