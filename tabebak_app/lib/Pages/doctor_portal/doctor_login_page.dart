import 'package:clinic_dr_alla/Components/animations/animations.dart';
import 'package:clinic_dr_alla/Components/page_header.dart';
import 'package:clinic_dr_alla/Components/ui_kit.dart';
import 'package:clinic_dr_alla/Constants/app_theme.dart';
import 'package:clinic_dr_alla/Pages/booking/booking_widgets.dart';
import 'package:clinic_dr_alla/Pages/doctor_portal/doctor_dashboard_page.dart';
import 'package:clinic_dr_alla/data/booking.dart';
import 'package:clinic_dr_alla/data/repository.dart';
import 'package:flutter/material.dart';

/// Opens the dashboard when a doctor is signed in, otherwise the login.
Future<void> openDoctorPortal(BuildContext context) async {
  final signedIn = await DoctorApi.signedIn;
  if (!context.mounted) return;
  Navigator.push(
    context,
    MaterialPageRoute(
      builder: (_) =>
          signedIn ? const DoctorDashboardPage() : const DoctorLoginPage(),
    ),
  );
}

class DoctorLoginPage extends StatefulWidget {
  const DoctorLoginPage({super.key});

  @override
  State<DoctorLoginPage> createState() => _DoctorLoginPageState();
}

class _DoctorLoginPageState extends State<DoctorLoginPage> {
  final _form = GlobalKey<FormState>();
  final _phone = TextEditingController();
  final _password = TextEditingController();
  bool _hide = true;
  bool _loading = false;
  String? _error;

  @override
  void dispose() {
    _phone.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    if (!_form.currentState!.validate()) return;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final profile = await DoctorApi.login(_phone.text, _password.text);
      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => DoctorDashboardPage(profile: profile)),
      );
    } on ApiException catch (e) {
      if (mounted) setState(() => _error = e.message);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBrandSurface,
      body: ListView(
        padding: EdgeInsets.zero,
        physics: const BouncingScrollPhysics(),
        children: [
          const GradientPageHeader(
            title: 'دخول الأطباء',
            subtitle: 'تابع حجوزات عيادتك وحدّد أوقات استقبال المرضى',
            emoji: '🩺',
            colors: [kBrandDark, kBrandPrimary, Color(0xFF29B6F6)],
          ),
          FadeSlideIn(
            delay: const Duration(milliseconds: 100),
            child: Container(
              margin: const EdgeInsets.fromLTRB(16, 20, 16, 0),
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(28),
                boxShadow: softShadow(),
              ),
              child: Form(
                key: _form,
                child: AutofillGroup(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      TextFormField(
                        controller: _phone,
                        keyboardType: TextInputType.phone,
                        textDirection: TextDirection.ltr,
                        textInputAction: TextInputAction.next,
                        autofillHints: const [AutofillHints.telephoneNumber],
                        decoration: fieldDecoration('رقم الهاتف',
                            hint: '059xxxxxxx', icon: Icons.phone_iphone_rounded),
                        validator: (v) =>
                            (v ?? '').trim().isEmpty ? 'أدخل رقم الهاتف' : null,
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _password,
                        obscureText: _hide,
                        textInputAction: TextInputAction.done,
                        autofillHints: const [AutofillHints.password],
                        onFieldSubmitted: (_) => _login(),
                        decoration: fieldDecoration(
                          'كلمة المرور',
                          icon: Icons.lock_outline_rounded,
                          suffix: IconButton(
                            onPressed: () => setState(() => _hide = !_hide),
                            icon: Icon(_hide
                                ? Icons.visibility_outlined
                                : Icons.visibility_off_outlined),
                          ),
                        ),
                        validator: (v) =>
                            (v ?? '').isEmpty ? 'أدخل كلمة المرور' : null,
                      ),
                      AnimatedSize(
                        duration: const Duration(milliseconds: 250),
                        child: _error == null
                            ? const SizedBox(width: double.infinity)
                            : Container(
                                margin: const EdgeInsets.only(top: 12),
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: kCancelledColor.withValues(alpha: 0.08),
                                  borderRadius: BorderRadius.circular(14),
                                ),
                                child: Text(_error!,
                                    style: const TextStyle(
                                        color: kCancelledColor,
                                        fontWeight: FontWeight.w700)),
                              ),
                      ),
                      const SizedBox(height: 18),
                      GradientButton(
                        label: 'تسجيل الدخول',
                        icon: Icons.login_rounded,
                        loading: _loading,
                        onTap: _login,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          FadeSlideIn(
            delay: const Duration(milliseconds: 220),
            child: Container(
              margin: const EdgeInsets.fromLTRB(16, 16, 16, 40),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: kBrandSky,
                borderRadius: BorderRadius.circular(22),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('ليس لديك حساب؟',
                      style: TextStyle(
                          fontWeight: FontWeight.w800, color: kBrandText)),
                  const SizedBox(height: 4),
                  const Text(
                      'تُنشئ إدارة طبيبك حسابات الأطباء. تواصل معنا لنفعّل لك الحجز عبر التطبيق.',
                      style: TextStyle(color: kBrandMuted, height: 1.6)),
                  const SizedBox(height: 10),
                  PressableScale(
                    onTap: () => openWhatsApp(Repository.config.supportWhatsApp,
                        'مرحباً، أنا طبيب وأرغب بتفعيل الحجز عبر تطبيق طبيبك'),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 9),
                      decoration: BoxDecoration(
                        color: const Color(0xFF25D366),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.chat_rounded, color: Colors.white, size: 18),
                          SizedBox(width: 6),
                          Text('تواصل عبر واتساب',
                              style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w800)),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
