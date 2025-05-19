import 'package:clinic_dr_alla/Constants/Constants.dart';
import 'package:flutter_html/flutter_html.dart';
import 'package:flutter/material.dart';

class Privacy extends StatefulWidget {
  const Privacy({Key? key}) : super(key: key);

  @override
  State<Privacy> createState() => _PrivacyState();
}

class _PrivacyState extends State<Privacy> {
  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      child: SafeArea(
        child: Scaffold(
          body: SingleChildScrollView(
            child: Container(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  Container(
                    color: Colors.white,
                    child: Padding(
                      padding:
                          const EdgeInsets.only(top: 10, left: 20, right: 10),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          IconButton(
                              onPressed: () {
                                Navigator.pop(context);
                              },
                              icon: Icon(
                                Icons.arrow_back_sharp,
                                color: kMainColor,
                                size: 25,
                              )),
                          Padding(
                            padding: const EdgeInsets.only(left: 30),
                            child: Text(
                              "سياسة الخصوصية",
                              style: TextStyle(
                                  fontSize: 22, fontWeight: FontWeight.bold),
                            ),
                          ),
                          Container()
                        ],
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Container(
                      width: double.infinity,
                      child: text1(),
                    ),
                  )
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Html text1() {
    return Html(data: _htmlContent);
  }

  final _htmlContent = """
  <div>
    <p>سياسة الخصوصية - تطبيق دليل الأطباء والعيادات في فلسطين</p>
    <p>في تطبيق دليل الأطباء، نحن ملتزمون بحماية خصوصيتك وضمان أن جميع معلوماتك الشخصية محفوظة وآمنة. نولي اهتماماً بالغاً بسرية بيانات المستخدمين ونسعى لتقديم تجربة موثوقة وآمنة للجميع.</p>

    <p>1. جمع المعلومات الشخصية</p>
    <p>عند استخدام التطبيق أو التسجيل فيه، قد نقوم بجمع البيانات التالية:</p>
    <ul>
      <li>الاسم الكامل</li>
      <li>رقم الهاتف</li>
      <li>المدينة / المنطقة</li>
      <li>معلومات حول الأطباء أو العيادات التي تفضلها</li>
    </ul>
    <p>يتم استخدام هذه البيانات لتحسين جودة الخدمة وتقديم تجربة مخصصة للمستخدم.</p>

    <p>2. استخدام المعلومات</p>
    <p>نقوم باستخدام بياناتك من أجل:</p>
    <ul>
      <li>عرض نتائج دقيقة حسب موقعك أو تفضيلاتك.</li>
      <li>تحسين أداء التطبيق وجودة المحتوى.</li>
      <li>التواصل معك لتقديم دعم أو تنبيهات عند الحاجة.</li>
      <li>إرسال إشعارات في حال وجود تحديثات مهمة.</li>
    </ul>

    <p>3. مشاركة المعلومات</p>
    <p>نحن لا نشارك أو نبيع بياناتك لأي طرف ثالث. يتم استخدام المعلومات داخلياً فقط من قبل فريق تطوير التطبيق.</p>

    <p>4. أمان المعلومات</p>
    <p>نطبق معايير أمان وتقنيات حماية لضمان سرية بياناتك ومنع أي استخدام غير مصرح به لها.</p>

    <p>5. صلاحيات المستخدم</p>
    <p>يحق للمستخدم الوصول إلى بياناته الشخصية وتعديلها أو حذفها متى أراد. يمكن التواصل معنا من خلال البريد الإلكتروني أو الدعم داخل التطبيق.</p>

    <p>6. تحديث سياسة الخصوصية</p>
    <p>قد نقوم بإجراء تعديلات على هذه السياسة من وقت لآخر. سيتم إعلام المستخدمين بأي تغييرات عبر التطبيق أو الموقع الرسمي.</p>

    <p>7. التواصل معنا</p>
    <p>لأي استفسارات أو طلبات متعلقة بالخصوصية، يرجى التواصل عبر البريد الإلكتروني: support@doctorspal.com</p>

    <p>شكراً لاستخدامكم تطبيق دليل الأطباء والعيادات في فلسطين.</p>
  </div>
""";
}
