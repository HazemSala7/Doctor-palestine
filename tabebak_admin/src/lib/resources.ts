import type { LucideIcon } from 'lucide-react'
import {
  Stethoscope,
  Tags,
  MapPin,
  Building2,
  Pill,
  FlaskConical,
  ScanLine,
  Sparkles,
  Warehouse,
  Salad,
  Glasses,
  Activity,
  Briefcase,
  Images,
  Megaphone,
  KeyRound,
  CalendarCheck,
  Clapperboard,
  Star,
  Users,
} from 'lucide-react'

export type FieldType =
  | 'text'
  | 'textarea'
  | 'phone'
  | 'number'
  | 'image'
  | 'video'
  | 'url'
  | 'relation'
  | 'select'
  | 'coordinates'
  | 'date'
  | 'time'
  | 'boolean'
  /** Write-only: never sent back by the server; left empty on edit keeps the current one. */
  | 'password'
  /** Picks a record from the section chosen in the `type` field. */
  | 'target'

export interface Field {
  key: string
  label: string
  type: FieldType
  required?: boolean
  placeholder?: string
  /** For `relation`: the resource whose rows are the options. */
  relation?: string
  /** For `select`. */
  options?: { value: string; label: string }[]
  /** Shown as a table column. */
  column?: boolean
  /** Offered as a filter above the table. */
  filter?: boolean
  /** Spans both form columns. */
  wide?: boolean
  /** For `boolean`: text beside the switch when on / off. */
  toggleLabels?: [string, string]
  /** Small help text under the input. */
  hint?: string
  /** Shown in the table only; never edited or sent (e.g. a server-side counter). */
  readOnly?: boolean
  /** Value a new record starts with. */
  defaultValue?: string
}

export interface Resource {
  key: string
  label: string
  singular: string
  icon: LucideIcon
  emoji: string
  color: string
  group: string
  fields: Field[]
  titleField: string
  imageField?: string
  /** Shown as an image grid instead of a table. */
  gallery?: boolean
}

const cityField: Field = {
  key: 'city_id',
  label: 'المدينة',
  type: 'relation',
  relation: 'cities',
  required: true,
  column: true,
  filter: true,
}

/** Shown as buttons on the doctor's / centre's page in the app. */
const socialFields: Field[] = [
  {
    key: 'facebook_url',
    label: 'فيسبوك',
    type: 'url',
    placeholder: 'https://facebook.com/... أو اسم الصفحة',
    hint: 'يكفي اسم الصفحة، ويُكمَل الرابط تلقائياً',
  },
  {
    key: 'instagram_url',
    label: 'إنستغرام',
    type: 'url',
    placeholder: '@اسم_الحساب أو الرابط',
    hint: 'يكفي كتابة @اسم_الحساب',
  },
]

const coordinatesField: Field = {
  key: 'coordinates',
  label: 'الموقع على الخريطة',
  type: 'coordinates',
  wide: true,
}

/** Hospitals, pharmacies, labs, ... all share the same table shape. */
function placeResource(
  key: string,
  label: string,
  singular: string,
  icon: LucideIcon,
  emoji: string,
  color: string,
  extra: Field[] = [],
): Resource {
  return {
    key,
    label,
    singular,
    icon,
    emoji,
    color,
    group: 'المراكز الطبية',
    titleField: 'name',
    imageField: 'logo_image',
    fields: [
      { key: 'name', label: 'الاسم', type: 'text', required: true, column: true, wide: true },
      { key: 'logo_image', label: 'الشعار', type: 'image' },
      { key: 'cover_image', label: 'صورة الغلاف', type: 'image' },
      cityField,
      { key: 'mobile', label: 'رقم الهاتف', type: 'phone', column: true, placeholder: '059xxxxxxx' },
      { key: 'address', label: 'العنوان', type: 'text', column: true, wide: true },
      { key: 'experiance', label: 'سنوات الخبرة', type: 'number' },
      ...extra,
      ...socialFields,
      { key: 'description', label: 'الوصف', type: 'textarea', wide: true },
      coordinatesField,
    ],
  }
}

/** Values the backend's Voyager form uses for advertisement targets. */
export const AD_TARGETS = [
  { value: 'doctor', label: 'طبيب', resource: 'doctors' },
  { value: 'hospital', label: 'مستشفى', resource: 'hospitals' },
  { value: 'pharmacy', label: 'صيدلية', resource: 'pharmacies' },
  { value: 'lab', label: 'مختبر', resource: 'laboratories' },
  { value: 'radiology', label: 'مركز أشعة', resource: 'radiology_centers' },
  { value: 'beauty_center', label: 'مركز تجميل', resource: 'beauty_centers' },
  { value: 'warehouse', label: 'مستودع طبي', resource: 'medical_warehouses' },
  { value: 'nutrition', label: 'مركز تغذية', resource: 'nutrition_centers' },
  { value: 'optic', label: 'بصريات', resource: 'optics' },
  { value: 'treatment_center', label: 'علاج طبيعي', resource: 'medical_treatment_centers' },
  { value: 'job', label: 'وظيفة', resource: 'jobs' },
  { value: 'city', label: 'مدينة', resource: 'cities' },
]

export const AD_PLACEMENTS = [
  { value: 'banner', label: 'عادي: في سلايدر الرئيسية' },
  { value: 'premium', label: '⭐ مميز: نافذة عند الفتح + تثبيت أعلى القائمة' },
  { value: 'vip', label: '💎 مميز جداً: الراعي الحصري، نافذة كل فتح للتطبيق + قسم خاص بالرئيسية' },
]

export const APPOINTMENT_STATUSES = [
  { value: 'pending', label: 'بانتظار التأكيد' },
  { value: 'confirmed', label: 'مؤكد' },
  { value: 'completed', label: 'تمت الزيارة' },
  { value: 'cancelled', label: 'ملغي' },
]

export const REVIEW_STATUSES = [
  { value: 'pending', label: 'بانتظار المراجعة' },
  { value: 'approved', label: 'منشور في التطبيق' },
  { value: 'rejected', label: 'مرفوض' },
]

/** Reviews belong to doctors and centres only. */
export const REVIEW_TARGETS = AD_TARGETS.filter((t) => t.value !== 'job' && t.value !== 'city')

export const RATINGS = [5, 4, 3, 2, 1].map((n) => ({ value: String(n), label: `${'★'.repeat(n)}${'☆'.repeat(5 - n)}  ${n}` }))

export const JOB_TYPES = [
  { value: 'full-time', label: 'دوام كامل' },
  { value: 'part-time', label: 'دوام جزئي' },
  { value: 'shifts', label: 'مناوبات' },
  { value: 'remote', label: 'عن بعد' },
  { value: 'contract', label: 'عقد مؤقت' },
]

export const RESOURCES: Resource[] = [
  {
    key: 'doctors',
    label: 'الأطباء',
    singular: 'طبيب',
    icon: Stethoscope,
    emoji: '🩺',
    color: '#1565c0',
    group: 'الأطباء',
    titleField: 'name',
    imageField: 'image',
    fields: [
      { key: 'name', label: 'اسم الطبيب', type: 'text', required: true, column: true, wide: true, placeholder: 'د. ...' },
      { key: 'image', label: 'الصورة', type: 'image', wide: true },
      {
        key: 'category_id',
        label: 'التخصص',
        type: 'relation',
        relation: 'doctor-categories',
        required: true,
        column: true,
        filter: true,
      },
      cityField,
      { key: 'mobile', label: 'رقم الهاتف', type: 'phone', column: true, placeholder: '059xxxxxxx' },
      { key: 'address', label: 'العنوان', type: 'text' },
      {
        key: 'featured',
        label: 'طبيب مميز',
        type: 'boolean',
        defaultValue: '0',
        column: true,
        filter: true,
        toggleLabels: ['يظهر في الرئيسية', 'عادي'],
        hint: 'الأطباء المميزون يظهرون في قسم «أطباء مميزون» في الصفحة الرئيسية',
      },
      ...socialFields,
      { key: 'description', label: 'نبذة عن الطبيب', type: 'textarea', wide: true },
      coordinatesField,
    ],
  },
  {
    key: 'doctor-categories',
    label: 'التخصصات',
    singular: 'تخصص',
    icon: Tags,
    emoji: '🏷️',
    color: '#00acc1',
    group: 'الأطباء',
    titleField: 'name',
    imageField: 'image',
    fields: [
      { key: 'name', label: 'اسم التخصص', type: 'text', required: true, column: true, wide: true },
      { key: 'image', label: 'الأيقونة', type: 'image', wide: true },
    ],
  },
  {
    key: 'reels',
    label: 'الريلز',
    singular: 'ريل',
    icon: Clapperboard,
    emoji: '🎬',
    color: '#e11d48',
    group: 'الأطباء',
    titleField: 'title',
    imageField: 'thumbnail',
    fields: [
      { key: 'title', label: 'العنوان', type: 'text', required: true, column: true, wide: true },
      {
        key: 'video',
        label: 'ملف الفيديو',
        type: 'video',
        wide: true,
        hint: 'ارفع ملفاً أو ضع رابطاً في الحقل التالي. عند وجود الاثنين يُعرض الملف المرفوع',
      },
      {
        key: 'video_url',
        label: 'أو رابط الفيديو',
        type: 'url',
        wide: true,
        placeholder: 'https://.../video.mp4',
        hint: 'رابط مباشر لملف فيديو (MP4)، وليس رابط صفحة يوتيوب أو إنستغرام',
      },
      { key: 'thumbnail', label: 'صورة الغلاف (اختياري)', type: 'image', hint: 'تظهر أثناء تحميل الفيديو' },
      {
        key: 'doctor_id',
        label: 'الطبيب المرتبط (اختياري)',
        type: 'relation',
        relation: 'doctors',
        column: true,
        filter: true,
        hint: 'يظهر في الريل زر لفتح صفحة الطبيب وحجز موعد',
      },
      { key: 'description', label: 'الوصف', type: 'textarea', wide: true },
      { key: 'active', label: 'الحالة', type: 'boolean', column: true, filter: true, toggleLabels: ['ظاهر في التطبيق', 'مخفي'] },
      { key: 'views', label: 'المشاهدات', type: 'number', column: true, readOnly: true },
    ],
  },
  {
    key: 'doctor-accounts',
    label: 'حسابات الأطباء',
    singular: 'حساب طبيب',
    icon: KeyRound,
    emoji: '🔑',
    color: '#0a3d91',
    group: 'المواعيد',
    titleField: 'phone',
    fields: [
      { key: 'doctor_id', label: 'الطبيب', type: 'relation', relation: 'doctors', required: true, column: true, filter: true, wide: true },
      {
        key: 'phone',
        label: 'رقم الهاتف (اسم المستخدم)',
        type: 'phone',
        required: true,
        column: true,
        placeholder: '059xxxxxxx',
        hint: 'يسجّل الطبيب الدخول في التطبيق بهذا الرقم',
      },
      {
        key: 'password',
        label: 'كلمة المرور',
        type: 'password',
        placeholder: '6 أحرف على الأقل',
        hint: 'مطلوبة عند إنشاء الحساب. عند التعديل اتركها فارغة للإبقاء على كلمة المرور الحالية',
      },
      { key: 'active', label: 'الحساب', type: 'boolean', column: true, filter: true, toggleLabels: ['مفعّل', 'موقوف'] },
      {
        key: 'booking_enabled',
        label: 'الحجز عبر التطبيق',
        type: 'boolean',
        column: true,
        toggleLabels: ['يستقبل حجوزات', 'لا يستقبل حجوزات'],
        hint: 'يستطيع الطبيب تغييره وتحديد أيام وساعات العمل من التطبيق',
      },
    ],
  },
  {
    key: 'appointments',
    label: 'المواعيد',
    singular: 'موعد',
    icon: CalendarCheck,
    emoji: '📅',
    color: '#16a34a',
    group: 'المواعيد',
    titleField: 'patient_name',
    fields: [
      { key: 'doctor_id', label: 'الطبيب', type: 'relation', relation: 'doctors', required: true, column: true, filter: true, wide: true },
      { key: 'patient_name', label: 'اسم المريض', type: 'text', required: true, column: true },
      { key: 'patient_phone', label: 'هاتف المريض', type: 'phone', required: true, column: true, placeholder: '059xxxxxxx' },
      { key: 'date', label: 'التاريخ', type: 'date', required: true, column: true },
      { key: 'time', label: 'الوقت', type: 'time', required: true, column: true },
      { key: 'status', label: 'الحالة', type: 'select', options: APPOINTMENT_STATUSES, required: true, column: true, filter: true },
      { key: 'notes', label: 'ملاحظات المريض', type: 'textarea', wide: true },
    ],
  },
  {
    key: 'reviews',
    label: 'التقييمات',
    singular: 'تقييم',
    icon: Star,
    emoji: '⭐',
    color: '#f59e0b',
    group: 'المواعيد',
    titleField: 'name',
    fields: [
      { key: 'place_name', label: 'الطبيب / المركز', type: 'text', readOnly: true, column: true },
      { key: 'type', label: 'القسم', type: 'select', options: REVIEW_TARGETS, required: true, filter: true },
      { key: 'target_id', label: 'الطبيب / المركز', type: 'target', required: true },
      { key: 'rating', label: 'التقييم', type: 'select', options: RATINGS, required: true, column: true, filter: true },
      {
        key: 'status',
        label: 'الحالة',
        type: 'select',
        options: REVIEW_STATUSES,
        defaultValue: 'approved',
        required: true,
        column: true,
        filter: true,
        hint: 'يظهر في التطبيق ويدخل في متوسط التقييم عندما يكون «منشور» فقط',
      },
      { key: 'name', label: 'اسم المُقيِّم', type: 'text', required: true, column: true },
      { key: 'phone', label: 'هاتف المُقيِّم', type: 'phone', required: true, placeholder: '059xxxxxxx', hint: 'لا يظهر في التطبيق. تقييم واحد لكل رقم لكل طبيب أو مركز' },
      { key: 'comment', label: 'التعليق', type: 'textarea', column: true, wide: true },
      {
        key: 'verified',
        label: 'زيارة مؤكدة',
        type: 'boolean',
        readOnly: true,
        column: true,
        toggleLabels: ['زيارة مؤكدة', 'غير مؤكد'],
      },
      { key: 'reply', label: 'رد الطبيب / المركز', type: 'textarea', wide: true, hint: 'يظهر تحت التقييم في التطبيق. الأطباء يردّون أيضاً من حسابهم في التطبيق' },
    ],
  },
  placeResource('hospitals', 'المستشفيات', 'مستشفى', Building2, '🏥', '#0d47a1'),
  placeResource('pharmacies', 'الصيدليات', 'صيدلية', Pill, '💊', '#00897b', [
    {
      key: 'on_duty',
      label: 'صيدلية مناوبة',
      type: 'boolean',
      defaultValue: '0',
      column: true,
      filter: true,
      toggleLabels: ['مناوبة الآن', 'غير مناوبة'],
      hint: 'تظهر في قسم «صيدليات مناوبة» في الصفحة الرئيسية',
    },
  ]),
  placeResource('laboratories', 'المختبرات', 'مختبر', FlaskConical, '🧪', '#5e35b1'),
  placeResource('radiology_centers', 'مراكز الأشعة', 'مركز أشعة', ScanLine, '🩻', '#283593'),
  placeResource('beauty_centers', 'مراكز التجميل', 'مركز تجميل', Sparkles, '✨', '#d81b60'),
  placeResource('medical_warehouses', 'المستودعات الطبية', 'مستودع طبي', Warehouse, '📦', '#ef6c00'),
  placeResource('nutrition_centers', 'مراكز التغذية', 'مركز تغذية', Salad, '🥗', '#43a047'),
  placeResource('optics', 'البصريات', 'مركز بصريات', Glasses, '👓', '#00838f'),
  placeResource('medical_treatment_centers', 'العلاج الطبيعي', 'مركز علاج طبيعي', Activity, '🦴', '#3949ab'),
  {
    key: 'staff',
    label: 'طاقم العمل',
    singular: 'عضو في الطاقم',
    icon: Users,
    emoji: '👥',
    color: '#0891b2',
    group: 'المراكز الطبية',
    titleField: 'name',
    imageField: 'image',
    fields: [
      { key: 'place_name', label: 'الطبيب / المركز', type: 'text', readOnly: true, column: true },
      { key: 'type', label: 'القسم', type: 'select', options: REVIEW_TARGETS, required: true, filter: true },
      { key: 'target_id', label: 'يعمل في', type: 'target', required: true, hint: 'يظهر في قسم «طاقم العمل» في صفحة هذا الطبيب أو المركز' },
      { key: 'name', label: 'الاسم', type: 'text', required: true, column: true, placeholder: 'مثال: د. سارة أحمد' },
      { key: 'role', label: 'المسمى الوظيفي', type: 'text', required: true, column: true, placeholder: 'مثال: ممرضة، أخصائي أشعة، صيدلاني' },
      { key: 'image', label: 'الصورة', type: 'image', wide: true },
      {
        key: 'doctor_id',
        label: 'ملفه في التطبيق (اختياري)',
        type: 'relation',
        relation: 'doctors',
        hint: 'إذا كان من الأطباء المسجلين في التطبيق، يفتح ملفه عند الضغط عليه',
      },
      { key: 'sort_order', label: 'الترتيب', type: 'number', column: true, placeholder: '1', hint: 'الرقم الأصغر يظهر أولاً' },
      { key: 'active', label: 'الظهور', type: 'boolean', column: true, filter: true, toggleLabels: ['يظهر في التطبيق', 'مخفي'] },
      { key: 'bio', label: 'نبذة', type: 'textarea', wide: true, placeholder: 'الخبرة، الشهادات، ما يقدّمه للمرضى...' },
    ],
  },
  {
    key: 'cities',
    label: 'المدن',
    singular: 'مدينة',
    icon: MapPin,
    emoji: '🗺️',
    color: '#f9a825',
    group: 'المحتوى',
    titleField: 'name',
    imageField: 'image',
    fields: [
      { key: 'name', label: 'اسم المدينة', type: 'text', required: true, column: true, wide: true },
      { key: 'image', label: 'الصورة', type: 'image', wide: true },
    ],
  },
  {
    key: 'jobs',
    label: 'الوظائف',
    singular: 'وظيفة',
    icon: Briefcase,
    emoji: '💼',
    color: '#6d4c41',
    group: 'المحتوى',
    titleField: 'title',
    fields: [
      { key: 'title', label: 'المسمى الوظيفي', type: 'text', required: true, column: true, wide: true },
      { key: 'type', label: 'نوع الدوام', type: 'select', options: JOB_TYPES, required: true, column: true, filter: true },
      { ...cityField },
      { key: 'location', label: 'جهة العمل / الموقع', type: 'text', column: true, wide: true },
      {
        key: 'mobile',
        label: 'رقم التواصل',
        type: 'phone',
        column: true,
        placeholder: '059xxxxxxx',
        hint: 'يظهر به زرّا «قدّم الآن عبر واتساب» والاتصال في صفحة الوظيفة. بدون رقم لا يظهر الزرّان',
      },
      {
        key: 'featured',
        label: 'بانر الرئيسية',
        type: 'boolean',
        defaultValue: '0',
        column: true,
        filter: true,
        toggleLabels: ['تظهر في البانر', 'عادية'],
        hint: 'الوظائف المختارة تظهر في بانر «وظائف شاغرة» في الصفحة الرئيسية. إذا لم تختر أي وظيفة تظهر أحدث الوظائف',
      },
      { key: 'description', label: 'الوصف والمتطلبات', type: 'textarea', wide: true },
    ],
  },
  {
    key: 'sliders',
    label: 'السلايدر',
    singular: 'صورة سلايدر',
    icon: Images,
    emoji: '🖼️',
    color: '#8e24aa',
    group: 'المحتوى',
    titleField: 'id',
    imageField: 'image',
    gallery: true,
    fields: [{ key: 'image', label: 'الصورة', type: 'image', required: true, wide: true }],
  },
  {
    key: 'advertisements',
    label: 'الإعلانات',
    singular: 'إعلان',
    icon: Megaphone,
    emoji: '📣',
    color: '#e53935',
    group: 'المحتوى',
    titleField: 'title',
    imageField: 'image',
    fields: [
      { key: 'title', label: 'عنوان الإعلان', type: 'text', required: true, column: true, wide: true },
      {
        key: 'placement',
        label: 'نوع الإعلان',
        type: 'select',
        options: AD_PLACEMENTS,
        defaultValue: 'banner',
        required: true,
        column: true,
        filter: true,
        wide: true,
        hint: 'المميز: نافذة كاملة عند فتح التطبيق (مرة يومياً لكل مستخدم) + يُثبَّت أعلى قائمة الطبيب أو المركز بشارة «مُموَّل» + أول السلايدر. المميز جداً (الراعي الحصري): نافذة «الراعي الحصري» بصورته وبياناته كل مرة يُفتح التطبيق (بدل نافذة المميز) + قسم خاص به أعلى الرئيسية بدل السلايدر + التثبيت بشارة «مُموَّل». كلاهما يجب أن يفتح صفحة طبيب أو مركز.',
      },
      { key: 'image', label: 'صورة الإعلان', type: 'image', required: true, wide: true },
      {
        key: 'description',
        label: 'نص الإعلان المميز',
        type: 'textarea',
        wide: true,
        placeholder: 'مثال: خصم 20٪ على تبييض الأسنان طوال هذا الشهر',
        hint: 'يظهر في النافذة تحت العنوان، وفي بطاقة المميز جداً بالرئيسية',
      },
      { key: 'type', label: 'يفتح عند الضغط', type: 'select', options: AD_TARGETS, column: true, filter: true },
      { key: 'target_id', label: 'السجل المستهدف', type: 'target' },
      { key: 'start_date', label: 'يبدأ في', type: 'date', column: true },
      { key: 'end_date', label: 'ينتهي في', type: 'date', column: true },
      { key: 'active', label: 'مفعّل', type: 'boolean', column: true, filter: true },
    ],
  },
]

export const RESOURCE_MAP: Record<string, Resource> = Object.fromEntries(
  RESOURCES.map((r) => [r.key, r]),
)

export const GROUPS = [...new Set(RESOURCES.map((r) => r.group))]

/** Resources whose rows are referenced by others and are loaded whole. */
export const LOOKUPS = ['cities', 'doctor-categories']
