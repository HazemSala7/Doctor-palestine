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
} from 'lucide-react'

export type FieldType =
  | 'text'
  | 'textarea'
  | 'phone'
  | 'number'
  | 'image'
  | 'relation'
  | 'select'
  | 'coordinates'
  | 'date'
  | 'boolean'
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
  placeResource('hospitals', 'المستشفيات', 'مستشفى', Building2, '🏥', '#0d47a1'),
  placeResource('pharmacies', 'الصيدليات', 'صيدلية', Pill, '💊', '#00897b'),
  placeResource('laboratories', 'المختبرات', 'مختبر', FlaskConical, '🧪', '#5e35b1'),
  placeResource('radiology_centers', 'مراكز الأشعة', 'مركز أشعة', ScanLine, '🩻', '#283593'),
  placeResource('beauty_centers', 'مراكز التجميل', 'مركز تجميل', Sparkles, '✨', '#d81b60'),
  placeResource('medical_warehouses', 'المستودعات الطبية', 'مستودع طبي', Warehouse, '📦', '#ef6c00'),
  placeResource('nutrition_centers', 'مراكز التغذية', 'مركز تغذية', Salad, '🥗', '#43a047'),
  placeResource('optics', 'البصريات', 'مركز بصريات', Glasses, '👓', '#00838f'),
  placeResource('medical_treatment_centers', 'العلاج الطبيعي', 'مركز علاج طبيعي', Activity, '🦴', '#3949ab'),
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
      { key: 'image', label: 'صورة الإعلان', type: 'image', required: true, wide: true },
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
