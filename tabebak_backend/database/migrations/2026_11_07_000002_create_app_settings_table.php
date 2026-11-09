<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Schema;

/**
 * Texts and contact details the app shows, edited from the dashboard.
 * Seeded with what the app used to have built in, so nothing changes until edited.
 */
return new class extends Migration
{
    public function up()
    {
        Schema::create('app_settings', function (Blueprint $table) {
            $table->string('key', 60)->primary();
            $table->text('value')->nullable();
            $table->timestamps();
        });

        $about = <<<'TXT'
عزيزي المستخدم، عزيزتي المستعملة ..
أهلاً بكم في تطبيق طبيبك، دليل الأطباء والعيادات في فلسطين، الدليل الطبي الأول الذي يجمع بين الراحة والدقة في الوصول إلى خدمات الرعاية الصحية.

- التطبيق يتيح لكم البحث بسهولة عن الأطباء حسب التخصص، المدينة، والاسم.
- يمكنكم تصفح معلومات العيادات، أوقات الدوام، أرقام التواصل، ومواقعها على الخريطة.
- يمكنكم حجز موعد مع الأطباء المشتركين بخدمة الحجز مباشرة من التطبيق.
- وفرنا لكم إمكانية إضافة الأطباء إلى قائمة المفضلة للرجوع إليهم لاحقاً بسرعة.
- لا يشمل التطبيق أي معاملات مالية، وهو مجاني تماماً للاستخدام.

مع كامل التقدير لحضراتكم .. نتمنى لكم الصحة والسلامة ونسعد بخدمتكم دائماً.
TXT;

        $privacy = <<<'TXT'
في تطبيق طبيبك نلتزم بحماية خصوصيتك وضمان أن جميع معلوماتك الشخصية محفوظة وآمنة.

1. جمع المعلومات الشخصية
عند حجز موعد عبر التطبيق نجمع الاسم ورقم الهاتف وأي ملاحظات تكتبها للطبيب، ونرسلها إلى الطبيب الذي حجزت عنده فقط.

2. استخدام المعلومات
- تنظيم مواعيدك مع الأطباء وتمكينهم من التواصل معك بخصوص الموعد.
- تحسين أداء التطبيق وجودة المحتوى.

3. مشاركة المعلومات
لا نشارك أو نبيع بياناتك لأي طرف ثالث.

4. أمان المعلومات
نطبق معايير أمان وتقنيات حماية لضمان سرية بياناتك ومنع أي استخدام غير مصرح به لها.

5. صلاحيات المستخدم
يحق لك طلب الاطلاع على بياناتك أو حذفها بالتواصل معنا.

6. تحديث سياسة الخصوصية
قد نعدّل هذه السياسة من وقت لآخر، وتظهر النسخة الحالية دائماً داخل التطبيق.

7. التواصل معنا
لأي استفسار يتعلق بالخصوصية تواصل معنا عبر البريد الإلكتروني: support@doctorspal.com
TXT;

        $now = now();
        $defaults = [
            'tagline' => 'دليلك الطبي الشامل في فلسطين',
            'about_us' => $about,
            'privacy_policy' => $privacy,
            'support_whatsapp' => '0594606276',
            'support_phone' => '',
            'support_email' => 'support@doctorspal.com',
            'facebook_url' => 'https://www.facebook.com/profile.php?id=61563302551082',
            'instagram_url' => 'https://www.instagram.com/yolo_beauty.ps?igsh=MXc5d2lkOTBmZjA3bA',
            'tiktok_url' => '',
            'website_url' => '',
        ];
        foreach ($defaults as $key => $value) {
            DB::table('app_settings')->insert(['key' => $key, 'value' => $value, 'created_at' => $now, 'updated_at' => $now]);
        }
    }

    public function down()
    {
        Schema::dropIfExists('app_settings');
    }
};
