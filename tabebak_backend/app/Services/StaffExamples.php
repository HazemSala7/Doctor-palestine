<?php

namespace App\Services;

use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Schema;

/**
 * Sample team members so the "طاقم العمل" section can be seen before real
 * data is entered. Only places with no team get them; each one is an
 * ordinary row, edited or deleted on the dashboard (طاقم العمل).
 */
class StaffExamples
{
    /** Per place type: [role, bio, female?]. */
    private const TEAMS = [
        'doctor' => [
            ['ممرضة العيادة', 'تستقبل المرضى وتجهّزهم للكشف، وتتابع قياس الضغط والسكر والحرارة.', true],
            ['سكرتير العيادة', 'لحجز المواعيد وتأكيدها والإجابة عن الاستفسارات.', false],
            ['مساعدة الطبيب', 'تساعد في الإجراءات داخل العيادة وتشرح للمريض تعليمات ما بعد الزيارة.', true],
        ],
        'hospital' => [
            ['المدير الطبي', 'يشرف على الأقسام الطبية وجودة الخدمة المقدمة للمرضى.', false],
            ['أخصائي طب الطوارئ', 'مناوب في قسم الطوارئ لاستقبال الحالات العاجلة.', false],
            ['رئيسة قسم التمريض', 'تنسّق فرق التمريض في الأقسام وتتابع رعاية المرضى المنوّمين.', true],
            ['أخصائية المختبر', 'تشرف على الفحوصات المخبرية داخل المستشفى.', true],
        ],
        'pharmacy' => [
            ['الصيدلاني المسؤول', 'يصرف الوصفات الطبية ويقدّم الاستشارة الدوائية.', false],
            ['صيدلانية', 'استشارات في الأدوية ومستحضرات العناية بالبشرة والأطفال.', true],
            ['مساعد صيدلي', 'لترتيب الطلبات وتوصيلها.', false],
        ],
        'lab' => [
            ['أخصائي مختبرات طبية', 'يشرف على تحليل العينات وإصدار النتائج.', false],
            ['فنية سحب الدم', 'سحب العينات للكبار والأطفال بلطف وأمان.', true],
            ['موظف الاستقبال', 'تسجيل الطلبات وتسليم النتائج.', false],
        ],
        'radiology' => [
            ['طبيب الأشعة', 'يقرأ الصور الشعاعية ويكتب التقارير.', false],
            ['فني تصوير الرنين المغناطيسي', 'يجري صور الرنين والطبقي ويجهّز المريض قبل التصوير.', false],
            ['فنية الأشعة والألتراساوند', 'صور الأشعة العادية والتصوير بالموجات فوق الصوتية.', true],
        ],
        'beauty_center' => [
            ['أخصائية العناية بالبشرة', 'جلسات تنظيف البشرة ونضارتها وعلاج حب الشباب.', true],
            ['أخصائية الليزر', 'جلسات إزالة الشعر بالليزر.', true],
            ['خبيرة التجميل', 'استشارات الإطلالة والمكياج.', true],
        ],
        'warehouse' => [
            ['مدير المستودع', 'يتابع الطلبيات والتوريد للصيدليات والمراكز.', false],
            ['مندوب المبيعات', 'لعروض الأسعار والطلبيات الجديدة.', false],
            ['مسؤولة الحسابات', 'الفواتير وكشوفات الحساب.', true],
        ],
        'nutrition' => [
            ['أخصائية التغذية العلاجية', 'برامج غذائية لإنقاص الوزن ولمرضى السكري والضغط.', true],
            ['أخصائي تغذية رياضية', 'أنظمة غذائية لبناء العضلات ورفع اللياقة.', false],
            ['منسقة المتابعة', 'تتابع المراجعين أسبوعياً وتحجز مواعيد القياس.', true],
        ],
        'optic' => [
            ['أخصائي البصريات', 'فحص النظر وقياس النظارات والعدسات اللاصقة.', false],
            ['فني تركيب العدسات', 'تجهيز النظارات وتركيب العدسات بدقة.', false],
            ['مستشارة الإطارات', 'تساعدك في اختيار الإطار المناسب لشكل الوجه.', true],
        ],
        'treatment_center' => [
            ['أخصائي العلاج الطبيعي', 'إعادة تأهيل الإصابات الرياضية وآلام الظهر والرقبة.', false],
            ['أخصائية العلاج الطبيعي', 'جلسات علاج للسيدات والأطفال.', true],
            ['أخصائي العلاج الوظيفي', 'تمارين استعادة الحركة بعد العمليات والجلطات.', false],
        ],
    ];

    private const MEN = ['محمد خليل', 'أحمد سعيد', 'خالد عمر', 'يوسف ناصر', 'سامر عيسى', 'إبراهيم موسى', 'عمر حسن', 'باسل جابر'];
    private const WOMEN = ['سارة أحمد', 'لينا محمود', 'رهف يوسف', 'نور خالد', 'هبة سليم', 'دعاء علي', 'ريم سامي', 'آية حسين'];

    /** Adds a team to the first `$perType` places of each kind that have none. Returns rows added. */
    public static function fill(int $perType = 3): int
    {
        if (! Schema::hasTable('staff_members')) {
            return 0;
        }
        $added = 0;
        $now = now();
        foreach (self::TEAMS as $type => $team) {
            $table = Reviews::TYPES[$type];
            if (! Schema::hasTable($table)) {
                continue;
            }
            $ids = DB::table($table)
                ->whereNotIn('id', DB::table('staff_members')->where('type', $type)->select('target_id'))
                ->orderBy('id')
                ->limit($perType)
                ->pluck('id');
            foreach ($ids as $n => $id) {
                $rows = [];
                foreach ($team as $i => [$role, $bio, $female]) {
                    $names = $female ? self::WOMEN : self::MEN;
                    $title = str_starts_with($role, 'طبيب') || $role === 'المدير الطبي' || str_starts_with($role, 'أخصائي طب') ? 'د. ' : '';
                    $rows[] = [
                        'type' => $type, 'target_id' => $id, 'role' => $role, 'bio' => $bio,
                        'name' => $title . $names[($id + $n * 3 + $i) % count($names)],
                        'sort_order' => $i + 1, 'active' => 1, 'created_at' => $now, 'updated_at' => $now,
                    ];
                }
                DB::table('staff_members')->insert($rows);
                $added += count($rows);
            }
        }

        return $added;
    }
}
