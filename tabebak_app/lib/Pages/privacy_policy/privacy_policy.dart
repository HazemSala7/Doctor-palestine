import 'package:clinic_dr_alla/Components/settings_text_page.dart';
import 'package:clinic_dr_alla/data/repository.dart';
import 'package:flutter/material.dart';

/// Privacy policy, written on the dashboard's settings page.
class Privacy extends StatelessWidget {
  const Privacy({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final text = Repository.config.privacyPolicy;
    return SettingsTextPage(
      title: 'سياسة الخصوصية',
      emoji: '🔒',
      // Built-in text when the server couldn't be reached.
      text: text.isNotEmpty ? text : _htmlContent,
    );
  }
}

const _htmlContent = """
  <div>
    <p>سياسة الخصوصية لتطبيق طبيبك</p>

    <p>1. البيانات التي نجمعها</p>
    <ul>
      <li>عند حجز موعد: الاسم ورقم الهاتف وموعد الزيارة وأي ملاحظات تكتبها للطبيب.</li>
      <li>عند كتابة تقييم: الاسم ورقم الهاتف والتقييم والتعليق.</li>
      <li>حسابات الأطباء: رقم الهاتف وكلمة المرور وما يضيفه الطبيب إلى صفحته من صور وفيديوهات وبيانات.</li>
    </ul>
    <p>لا يطلب التطبيق الوصول إلى موقعك، والأماكن المفضلة تُحفظ على جهازك فقط.</p>

    <p>2. من يطّلع على البيانات</p>
    <ul>
      <li>بيانات الحجز تصل إلى الطبيب الذي حجزت عنده وإلى إدارة التطبيق.</li>
      <li>اسمك وتقييمك وتعليقك يظهرون لمستخدمي التطبيق، أما رقم هاتفك فلا يظهر لهم.</li>
      <li>يستخدم التطبيق خرائط Google لعرض مواقع العيادات.</li>
    </ul>
    <p>لا نبيع بياناتك، ولا نستخدمها في إعلانات مخصصة.</p>

    <p>3. حقوقك</p>
    <p>يمكنك طلب الاطلاع على بياناتك أو تصحيحها أو حذفها عبر البريد support@doctorspal.com أو واتساب 0594606276.</p>

    <p>4. تنبيه طبي</p>
    <p>المعلومات والفيديوهات في التطبيق للتعريف فقط ولا تغني عن استشارة الطبيب.</p>
  </div>
""";
