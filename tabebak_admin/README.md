# لوحة تحكم طبيبك

لوحة تحكم React سريعة لإدارة بيانات تطبيق طبيبك: الأطباء، التخصصات، المستشفيات، الصيدليات، المختبرات، الأشعة، التجميل، المستودعات، التغذية، البصريات، العلاج الطبيعي، المدن، الوظائف، السلايدر والإعلانات.

- إضافة وتعديل وحذف، وحذف جماعي، ونسخ سجل كسجل جديد.
- بحث فوري، وفلترة حسب المدينة أو التخصص أو النوع، وترتيب، وتقسيم صفحات.
- رفع الصور بالسحب والإفلات أو باللصق (Ctrl+V)، مع معاينة.
- الإحداثيات مع خريطة حية. يمكن لصق رابط Google Maps مباشرة.
- إحصائيات ورسوم بيانية في الصفحة الرئيسية.
- وضع داكن، وواجهة تعمل على الجوال.
- اختصارات لوحة المفاتيح:

  | الاختصار | الوظيفة |
  | --- | --- |
  | `Ctrl+K` | بحث وانتقال سريع |
  | `N` | إضافة سجل جديد |
  | `/` | البحث في القسم الحالي |
  | `Ctrl+S` | حفظ |
  | `Esc` | إغلاق |

## التشغيل محلياً

```bash
cd admin
npm install
npm run dev        # http://localhost:5173
```

افتراضياً تعمل اللوحة في **الوضع التجريبي**:
- البيانات محفوظة في المتصفح فقط.
- الدخول بالبريد `admin@tabebak.ps` وكلمة المرور `123456`.
- زر ⟲ في الأعلى يعيد البيانات التجريبية الأصلية.

## الربط مع سيرفر Laravel (qadrs.com)

نسخة كاملة من كود السيرفر (`public_html/clinics_backend`) موجودة في مجلد [`../backend`](../backend). هذا ما أُضيف إليها:

| الملف | التغيير |
| --- | --- |
| `app/Http/Controllers/Admin/AdminResourceController.php` | جديد: إضافة وتعديل وحذف لكل الأقسام |
| `app/Http/Controllers/Admin/AdminAuthController.php` | جديد: تسجيل دخول الأدمن |
| `app/Http/Middleware/AdminToken.php` | جديد: حماية المسارات بتوكن |
| `routes/admin.php` | جديد: مسارات `/api/admin/...` |
| `routes/api.php` | سطر `require __DIR__ . '/admin.php';` |
| `routes/web.php` | مسار `storage/{path}` يعرض الصور المرفوعة |

ملاحظات:
- الدخول يتم بحسابات Voyager نفسها (جدول `users`). يُسمح فقط للحسابات التي دورها `admin`.
- البيانات تُحفظ بنفس طريقة Voyager تماماً، فلا يحتاج التطبيق أي تعديل:
  - الإحداثيات بصيغة `POINT(lng lat)`.
  - الصور في `storage/app/public/<القسم>/<الشهرالسنة>/`.
- الحذف نهائي، مثل Voyager، لأن موديلات التطبيق لا تستخدم SoftDeletes.
- الاستضافة لا تسمح بإنشاء رابط `public/storage`، لذلك كانت كل الصور ترجع 404. مسار `storage/{path}` في `web.php` يحل المشكلة.
- `GET /api/admin/health` يعرض الجداول وأعمدتها للتأكد من الإعداد.

### تشغيل السيرفر محلياً للتجربة

```bash
cd backend
composer install
# قاعدة بيانات محلية بدل الحقيقية، بمتغيرات بيئة بدون تعديل .env:
cd public
DB_HOST=127.0.0.1 DB_DATABASE=tabebak_local DB_USERNAME=root DB_PASSWORD=   php -S 127.0.0.1:8020 ../vendor/laravel/framework/src/Illuminate/Foundation/resources/server.php
```

### نشر اللوحة

```bash
npm run build   # يقرأ .env.production فيتصل بالسيرفر الحقيقي
# ثم ارفع محتوى dist/ إلى public_html/tabebak_admin/
#   → https://qadrs.com/tabebak_admin/
```

## بنية المشروع

```
src/lib/resources.ts   تعريف كل الأقسام وحقولها. أضف حقلاً هنا فيظهر في الجدول والنموذج.
src/lib/api/           مصدر البيانات: demo.ts (المتصفح) و laravel.ts (السيرفر).
src/lib/queries.ts     التخزين المؤقت والتحديث الفوري (TanStack Query).
src/pages/             الرئيسية، صفحة القسم، تسجيل الدخول.
src/components/        النماذج، الحقول، لوحة الأوامر، التخطيط.
../backend/            كود سيرفر Laravel (نسخة من clinics_backend).
```
