# دليل رفع تطبيق طبيبك على Google Play

- اسم الحزمة: `ps.tabebak.app`
- الإصدار: `1.5.0` (رمز الإصدار 7)
- ملف الرفع: `tabebak-release.aab` في هذا المجلد
- الصور: مجلد `graphics`

## 1. قبل ما تبدأ

- [ ] **سياسة الخصوصية:** لازم تكون على رابط عام. الملف جاهز (`privacy-policy.html`)، وبعد الرفع رابطه: `https://qadrs.com/tabebak_admin/privacy-policy.html`
- [ ] **حساب للمراجعين:** اعمل من لوحة التحكم طبيب تجريبي بحساب، وحط رقمه وكلمة السر بقسم 4 تحت.
- [ ] **البيانات الحقيقية:** على السيرفر طبيب واحد بس حالياً. عبّي أطباء ومراكز حقيقية قبل النشر، لأن التطبيق الفاضي ممكن ينرفض.
- [ ] **الوظائف:** الوظائف الخمس على السيرفر أمثلة تجريبية (Mobile Developer في Austin وغيرها) وبتظهر بالرئيسية. احذفها أو بدّلها بوظائف حقيقية.
- [ ] **إنستغرام:** الرابط بالإعدادات حالياً `yolo_beauty.ps`، وهذا لازم يتغير من لوحة التحكم.
- [ ] **البريد:** تأكد إن `support@doctorspal.com` شغال، لأن Google والمستخدمين رح يراسلوك عليه.
- [ ] **خرائط Google:** بعد إنشاء التطبيق، انسخ SHA-1 من Play Console > Test and release > App integrity > App signing، وأضفه لمفتاح الخرائط في Google Cloud وقيّد المفتاح على اسم الحزمة. أضف كمان SHA-1 مفتاح الرفع:
  `06:5E:EC:AC:0A:E5:FB:A4:93:01:8F:0D:52:D4:F5:5D:A1:E5:72:64`
- [ ] **الحسابات الشخصية:** إذا حسابك على Play Console شخصي ومعمول بعد نوفمبر 2023، لازم اختبار مغلق مع 12 مختبر لمدة 14 يوم قبل النشر العام. حسابات الشركات مش مطلوب منها.

## 2. بيانات الصفحة في المتجر

**اللغة الافتراضية:** العربية. **الفئة:** Medical. **النوع:** App، مجاني.

**الاسم (30 حرف كحد أقصى)**

```
طبيبك - دليل الأطباء في فلسطين
```

**الوصف القصير (80 حرف كحد أقصى)**

```
ابحث عن الأطباء والمراكز الطبية في فلسطين واحجز موعدك بسهولة
```

**الوصف الكامل**

```
طبيبك هو دليلك الطبي في فلسطين. ابحث عن الطبيب المناسب حسب التخصص والمدينة، وتعرّف على المراكز الطبية القريبة منك، واحجز موعدك من هاتفك بدون إنشاء حساب.

ماذا يقدم لك التطبيق؟

• دليل الأطباء: ابحث حسب التخصص والمدينة، وشاهد صفحة كل طبيب مع نبذته وعنوانه وموقعه على الخريطة وطاقم عيادته.
• حجز المواعيد: اختر اليوم والساعة المتاحين عند الأطباء الذين يستقبلون الحجز عبر التطبيق، وتابع حالة موعدك أو ألغه.
• المراكز الطبية: مستشفيات وصيدليات ومختبرات ومراكز أشعة ومراكز تجميل وتغذية وعلاج ومستودعات طبية ونظارات.
• التقييمات: اقرأ آراء المرضى وشارك تجربتك.
• الريلز: فيديوهات قصيرة من الأطباء.
• الوظائف الشاغرة في القطاع الطبي.
• تواصل مباشر بالاتصال أو واتساب، واحفظ أماكنك المفضلة.

للأطباء

يدير الطبيب من حسابه مواعيد عيادته وساعات العمل وبيانات صفحته وطاقم العمل وفيديوهاته، ويرد على تقييمات المرضى.

تنبيه: المعلومات والفيديوهات في التطبيق للتعريف فقط ولا تغني عن استشارة الطبيب. في الحالات الطارئة اتصل بالإسعاف على 101.
```

**الصور**

| الخانة | الملف |
|---|---|
| App icon | `graphics/icon-512.png` |
| Feature graphic | `graphics/feature-graphic-1024x500.png` |
| Phone screenshots | كل الملفات في `graphics/screenshots` |

## 3. قسم App content

| البند | الإجابة |
|---|---|
| Privacy policy | الرابط من قسم 1 |
| Ads | Yes، لأن التطبيق يعرض إعلانات ترويجية للأطباء والمراكز |
| App access | All or some functionality is restricted، وأدخل نص قسم 4 |
| Content rating | ابدأ الاستبيان، النوع All other app types. لا عنف ولا محتوى جنسي ولا مقامرة. مشاركة محتوى بين المستخدمين: Yes (تقييمات وفيديوهات). مشاركة الموقع: No. مشتريات رقمية: No |
| Target audience | 18 and over |
| News app | No |
| Government app | No |
| Financial features | My app doesn't provide any financial features |
| Health apps | اختر فئة خدمات الرعاية الصحية وإدارتها (مواعيد ودليل أطباء). التطبيق ليس جهازاً طبياً ولا يقدم تشخيصاً |
| Advertising ID | No، التطبيق ما بيستخدمه |

## 4. وصول المراجعين (App access)

```
Patients do not need an account. Everything except the doctor area is open.

Doctor area: open the last tab (المزيد), tap the doctor login (دخول الأطباء), and sign in with:
Phone: [رقم الطبيب التجريبي]
Password: [كلمة السر]
```

## 5. Data safety

**الإجابات العامة:** Collects data: Yes. Encrypted in transit: Yes. Account creation: No للمرضى، وحسابات الأطباء تنشئها الإدارة. Users can request data deletion: Yes، عبر البريد وواتساب.

| نوع البيانات | Collected | Shared | Optional | الغرض |
|---|---|---|---|---|
| Personal info > Name | Yes | No | Yes | App functionality |
| Personal info > Phone number | Yes | No | Yes | App functionality, Account management |
| Health and fitness > Health info (ملاحظات الحجز) | Yes | No | Yes | App functionality |
| Photos and videos > Photos | Yes (للأطباء) | No | Yes | App functionality |
| Photos and videos > Videos | Yes (للأطباء) | No | Yes | App functionality |
| App activity > Other user-generated content (التقييمات) | Yes | No | Yes | App functionality |

وصول بيانات الحجز للطبيب اللي اختاره المريض هو طلب من المريض نفسه، فما بينحسب Shared حسب تعريف Google.

**خرائط Google:** مكتبتها بتجمع بيانات خاصة فيها. قبل الحفظ راجع صفحة Google عن Maps SDK وData safety، وأضف أي نوع بتذكره (عادة تفاعلات التطبيق وسجلات الأعطال والتشخيص).

## 6. رفع النسخة

1. Create app > الاسم «طبيبك» > App > Free.
2. عبّي قسم 2 و3 و5.
3. Test and release > Testing > Closed testing (أو Production إذا حسابك شركة) > Create new release.
4. وافق على Play App Signing، وارفع `tabebak-release.aab`.
5. ملاحظات الإصدار: `الإصدار الأول من تطبيق طبيبك.`
6. Review and roll out.

## 7. التحديثات القادمة

- زِد رمز الإصدار في `tabebak_app/pubspec.yaml` كل مرة (مثلاً `1.5.1+8`).
- البناء: `flutter build appbundle --release`
- **مفتاح الرفع في `D:\Apps\tabebak_keys`:** اعمل منه نسخة احتياطية، وما تحطه على GitHub أبداً.
