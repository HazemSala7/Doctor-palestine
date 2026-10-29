import type { Row } from './api/types'

/**
 * Sample data for demo mode, mirroring the Flutter app's DemoData.
 * Names and phone numbers are fictional.
 */

// Deterministic PRNG so every reset gives the same data.
function rng(seed: number) {
  return () => {
    seed = (seed * 1664525 + 1013904223) % 4294967296
    return seed / 4294967296
  }
}

const now = Date.now()
const stamp = (daysAgo: number) => new Date(now - daysAgo * 86_400_000).toISOString()

const cities = ['القدس', 'رام الله', 'نابلس', 'الخليل', 'بيت لحم', 'جنين', 'طولكرم', 'غزة']
const centres: [number, number][] = [
  [31.7767, 35.2345],
  [31.9038, 35.2034],
  [32.2211, 35.2544],
  [31.5326, 35.0998],
  [31.7054, 35.2024],
  [32.4594, 35.3009],
  [32.3104, 35.0286],
  [31.5017, 34.4668],
]

const specialties = [
  'باطنية', 'أطفال', 'أسنان', 'نسائية وتوليد', 'عيون', 'قلب وشرايين',
  'جلدية', 'عظام', 'أنف وأذن وحنجرة', 'أعصاب', 'نفسية', 'مسالك بولية',
]

const male = ['أحمد', 'محمد', 'خالد', 'يوسف', 'سامي', 'عمر', 'إبراهيم', 'رامي', 'باسل', 'مازن', 'طارق', 'نزار', 'وسيم', 'فادي', 'جهاد', 'كريم']
const female = ['ليلى', 'سارة', 'رنا', 'هبة', 'دانة', 'نور', 'مي', 'ريم', 'لينا', 'سلمى', 'آية', 'ديما']
const family = ['الخطيب', 'النتشة', 'عودة', 'حماد', 'الشريف', 'أبو عيشة', 'القواسمي', 'دويكات', 'الأغا', 'زيدان', 'منصور', 'سلامة', 'البرغوثي', 'الجعبري', 'صوالحة', 'عابدين', 'التميمي', 'الحروب']
const streets = ['شارع القدس', 'دوار المنارة', 'شارع الإرسال', 'شارع عين سارة', 'شارع فيصل', 'وسط البلد', 'شارع الجامعة', 'شارع الشهداء', 'حي الماصيون']

const doctorAbout = [
  'يقدم رعاية طبية متكاملة تعتمد على أحدث البروتوكولات العلاجية، مع الحرص على شرح الحالة للمريض بوضوح ومتابعته بعد العلاج.',
  'حاصل على البورد في التخصص وخبرة طويلة في المستشفيات الحكومية والخاصة.',
  'يستقبل المرضى بمواعيد مسبقة لتقليل وقت الانتظار، ويوفر استشارات متابعة عبر الهاتف.',
  'عضو في نقابة الأطباء الفلسطينية، شارك في العديد من المؤتمرات الطبية المحلية والدولية.',
]

const places: Record<string, { names: string[]; about: string }> = {
  hospitals: {
    names: ['مستشفى الأمل التخصصي', 'مستشفى الرحمة الجراحي', 'مركز النور الطبي', 'مستشفى السلام', 'مستشفى الحياة للولادة', 'المركز الطبي العربي'],
    about: 'يضم أقساماً متخصصة وطاقماً طبياً على مدار الساعة، مع أجهزة تشخيص حديثة وغرف عمليات مجهزة بالكامل.',
  },
  pharmacies: {
    names: ['صيدلية الشفاء', 'صيدلية النخبة', 'صيدلية الحياة', 'صيدلية ابن سينا', 'صيدلية الريان', 'صيدلية المركز'],
    about: 'تشكيلة واسعة من الأدوية والمكملات ومستحضرات العناية، مع صيدلاني مختص لتقديم الاستشارة الدوائية.',
  },
  laboratories: {
    names: ['مختبرات الدقة الطبية', 'مختبر الحكمة', 'مختبرات بيوتك', 'مختبر المدينة', 'مختبرات الأمان', 'مختبر الرازي'],
    about: 'فحوصات مخبرية دقيقة بأجهزة معتمدة، ونتائج سريعة يمكن استلامها إلكترونياً.',
  },
  radiology_centers: {
    names: ['مركز الأشعة الحديث', 'مركز التصوير الرقمي', 'مركز الرنين المتقدم', 'أشعة المدينة', 'مركز بانوراما للتصوير'],
    about: 'خدمات تصوير طبي متقدمة بإشراف أخصائيي أشعة، مع تقارير مفصلة في نفس اليوم.',
  },
  beauty_centers: {
    names: ['مركز لمسة جمال', 'عيادة نضارة', 'مركز جلامور للتجميل', 'عيادة البشرة الذهبية', 'مركز روز للتجميل'],
    about: 'جلسات عناية وتجميل بإشراف طبي وأحدث تقنيات الليزر والعناية بالبشرة.',
  },
  medical_warehouses: {
    names: ['مستودع الأدوية الوطني', 'مستودع ميديكال بلس', 'المستودع الطبي الحديث', 'مستودع الصحة', 'مستودع الرعاية'],
    about: 'توريد الأدوية والمستلزمات الطبية للصيدليات والمراكز الصحية بأسعار الجملة.',
  },
  nutrition_centers: {
    names: ['مركز توازن للتغذية', 'عيادة رشاقة', 'مركز الحياة الصحية', 'عيادة نيوترا', 'مركز وزن مثالي'],
    about: 'برامج تغذية مصممة حسب احتياجك مع متابعة أسبوعية وقياسات دقيقة لمكونات الجسم.',
  },
  optics: {
    names: ['بصريات الرؤية', 'نظارات فيجن', 'بصريات العين الذهبية', 'مركز النظر الحديث', 'بصريات لنس'],
    about: 'فحص نظر بالكمبيوتر وتشكيلة كبيرة من الإطارات والعدسات العالمية.',
  },
  medical_treatment_centers: {
    names: ['مركز حركة للعلاج الطبيعي', 'مركز التأهيل الحديث', 'عيادة فيزيو كير', 'مركز العافية', 'مركز الشفاء الحركي'],
    about: 'برامج علاج طبيعي وتأهيل حركي لمختلف الإصابات بأجهزة حديثة وأخصائيين معتمدين.',
  },
}

const jobs: [string, string, string][] = [
  ['ممرض/ة قانوني/ة', 'مستشفى الأمل التخصصي', 'full-time'],
  ['صيدلاني/ة', 'صيدلية الشفاء', 'shifts'],
  ['فني/ة مختبر', 'مختبرات الدقة الطبية', 'full-time'],
  ['طبيب/ة عام', 'مركز النور الطبي', 'part-time'],
  ['أخصائي/ة أشعة', 'مركز التصوير الرقمي', 'full-time'],
  ['موظف/ة استقبال', 'عيادة نضارة', 'part-time'],
  ['أخصائي/ة علاج طبيعي', 'مركز حركة للعلاج الطبيعي', 'full-time'],
  ['مندوب/ة مبيعات طبية', 'مستودع ميديكال بلس', 'contract'],
  ['أخصائي/ة تغذية', 'مركز توازن للتغذية', 'remote'],
]

/** A gradient banner as an inline SVG, standing in for uploaded slider art. */
function banner(title: string, sub: string, from: string, to: string, emoji: string) {
  const svg = `<svg xmlns="http://www.w3.org/2000/svg" width="1200" height="520" viewBox="0 0 1200 520">
<defs><linearGradient id="g" x1="1" y1="0" x2="0" y2="1"><stop offset="0" stop-color="${from}"/><stop offset="1" stop-color="${to}"/></linearGradient></defs>
<rect width="1200" height="520" fill="url(#g)"/>
<circle cx="140" cy="120" r="210" fill="#fff" fill-opacity=".08"/><circle cx="1080" cy="470" r="170" fill="#fff" fill-opacity=".08"/>
<text x="1110" y="250" text-anchor="start" font-family="Cairo,sans-serif" font-weight="900" font-size="78" fill="#fff" direction="rtl">${title}</text>
<text x="1110" y="330" text-anchor="start" font-family="Cairo,sans-serif" font-size="38" fill="#fff" fill-opacity=".9" direction="rtl">${sub}</text>
<text x="190" y="330" text-anchor="middle" font-size="180">${emoji}</text></svg>`
  return 'data:image/svg+xml;charset=utf-8,' + encodeURIComponent(svg)
}

export function buildSeed(): Record<string, Row[]> {
  const r = rng(42)
  const pick = <T,>(a: T[]) => a[Math.floor(r() * a.length)]
  const phone = () => `05${r() < 0.5 ? 9 : 6}${Array.from({ length: 7 }, () => Math.floor(r() * 10)).join('')}`
  const near = (cityId: number) => {
    const [lat, lng] = centres[cityId - 1]
    return [{ lat: (lat + (r() - 0.5) * 0.03).toFixed(6), lng: (lng + (r() - 0.5) * 0.03).toFixed(6) }]
  }
  const base = (daysAgo: number) => ({ created_at: stamp(daysAgo), updated_at: stamp(daysAgo) })

  const db: Record<string, Row[]> = {
    cities: cities.map((name, i) => ({ id: i + 1, name, image: null, ...base(200) })),
    'doctor-categories': specialties.map((name, i) => ({ id: i + 1, name, image: null, ...base(200) })),
  }

  db.doctors = Array.from({ length: 72 }, (_, i) => {
    const isFemale = i % 3 === 1
    const first = isFemale ? female[(i * 5) % female.length] : male[(i * 7) % male.length]
    const cityId = ((i * 3 + Math.floor(i / 12)) % cities.length) + 1
    return {
      id: i + 1,
      name: `د. ${first} ${family[(i * 11 + 3) % family.length]}`,
      image: null,
      category_id: (i % specialties.length) + 1,
      city_id: cityId,
      mobile: phone(),
      address: `${cities[cityId - 1]} - ${pick(streets)}`,
      description: doctorAbout[i % doctorAbout.length],
      coordinates: near(cityId),
      ...base(72 - i),
    }
  })

  Object.entries(places).forEach(([key, { names, about }], k) => {
    db[key] = names.map((name, i) => {
      const cityId = ((i * 2 + k) % cities.length) + 1
      return {
        id: i + 1,
        name,
        logo_image: null,
        cover_image: null,
        city_id: cityId,
        mobile: phone(),
        address: `${cities[cityId - 1]} - ${pick(streets)}`,
        experiance: 2 + Math.floor(r() * 30),
        description: about,
        coordinates: near(cityId),
        ...base(60 - i * 3 - k),
      }
    })
  })

  db.jobs = jobs.map(([title, location, type], i) => ({
    id: i + 1,
    title,
    location,
    type,
    city_id: (i % cities.length) + 1,
    description:
      'نبحث عن شخص متحمس للانضمام إلى فريقنا. المتطلبات: شهادة في التخصص، مزاولة مهنة سارية، مهارات تواصل ممتازة، والقدرة على العمل ضمن فريق.',
    ...base(Math.floor(r() * 14)),
  }))

  db.sliders = [
    banner('فحص شامل بخصم 30٪', 'باقة الفحوصات السنوية', '#5e35b1', '#42a5f5', '🧪'),
    banner('صيدليات مناوبة 24 ساعة', 'أقرب صيدلية مفتوحة الآن', '#00897b', '#26c6da', '💊'),
    banner('ابتسامتك تهمنا', 'أفضل أطباء الأسنان في مدينتك', '#1565c0', '#00bcd4', '🦷'),
    banner('نظارتك الجديدة', 'فحص نظر مجاني مع كل نظارة', '#ef6c00', '#ffca28', '👓'),
  ].map((image, i) => ({ id: i + 1, image, ...base(30 - i) }))

  db.advertisements = [
    {
      id: 1,
      title: 'عرض الافتتاح – مستشفى الأمل',
      image: banner('عرض الافتتاح', 'خصم 20٪ على العيادات الخارجية', '#0a3d91', '#42a5f5', '🏥'),
      type: 'hospital',
      target_id: 1,
      active: 1,
      start_date: new Date(now - 5 * 86_400_000).toISOString().slice(0, 10),
      end_date: new Date(now + 25 * 86_400_000).toISOString().slice(0, 10),
      ...base(5),
    },
  ]

  return db
}
