import 'package:clinic_dr_alla/Components/settings_text_page.dart';
import 'package:clinic_dr_alla/data/repository.dart';
import 'package:flutter/material.dart';

/// "About us", written on the dashboard's settings page.
class WhoWeAre extends StatelessWidget {
  const WhoWeAre({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final text = Repository.config.aboutUs;
    return SettingsTextPage(
      title: 'من نحن',
      emoji: 'ℹ️',
      // Built-in text when the server couldn't be reached.
      text: text.isNotEmpty ? text : _htmlContent,
    );
  }
}

final _htmlContent = """
  <div>
    <p>من نحن</p>
    <p>عزيزي المستخدم، عزيزتي المستعملة ..</p>
    <p>أهلاً بكم في تطبيق دليل الأطباء والعيادات في فلسطين، الدليل الطبي الأول الذي يجمع بين الراحة والدقة في الوصول إلى خدمات الرعاية الصحية.</p>

    <p>يرجى من حضرتكم الإحاطة بالنقاط التالية:</p>
    
    <p>- التطبيق يتيح لكم البحث بسهولة عن الأطباء حسب التخصص، المدينة، والاسم.</p>
    
    <p>- يمكنكم تصفح معلومات العيادات، أوقات الدوام، أرقام التواصل، ومواقعها على الخريطة.</p>
    
    <p>- وفرنا لكم إمكانية إضافة الأطباء إلى قائمة المفضلة للرجوع إليهم لاحقاً بسرعة.</p>
    
    
    <p>- لا يشمل التطبيق أي معاملات مالية، وهو مجاني تماماً للاستخدام.</p>
    
    <p>مع كامل التقدير لحضراتكم .. نتمنى لكم الصحة والسلامة ونسعد بخدمتكم دائماً عبر تطبيق دليل الأطباء في فلسطين.</p>
  </div>
""";
