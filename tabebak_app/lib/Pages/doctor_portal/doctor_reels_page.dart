import 'dart:io';

import 'package:clinic_dr_alla/Components/brand_widgets.dart';
import 'package:clinic_dr_alla/Components/page_header.dart';
import 'package:clinic_dr_alla/Constants/app_theme.dart';
import 'package:clinic_dr_alla/Pages/booking/booking_widgets.dart';
import 'package:clinic_dr_alla/Pages/doctor_portal/photo_field.dart';
import 'package:clinic_dr_alla/data/booking.dart';
import 'package:clinic_dr_alla/data/doctor_page.dart';
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

/// The doctor adds, plays, edits, hides and removes their reels.
class DoctorReelsPage extends StatefulWidget {
  const DoctorReelsPage({super.key});

  @override
  State<DoctorReelsPage> createState() => _DoctorReelsPageState();
}

class _DoctorReelsPageState extends State<DoctorReelsPage> {
  List<DoctorReel>? _reels;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final reels = await DoctorPageApi.reels();
      if (mounted) {
        setState(() {
          _reels = reels;
          _error = null;
        });
      }
    } on ApiException catch (e) {
      if (!mounted) return;
      if (e.unauthorized) {
        showMessage(context, e.message);
        Navigator.pop(context);
      } else if (_reels == null) {
        setState(() => _error = e.message);
      } else {
        showMessage(context, e.message);
      }
    }
  }

  Future<void> _edit([DoctorReel? reel]) async {
    final changed = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      // A drag must not close the sheet while a video is uploading.
      enableDrag: false,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
      builder: (_) => _ReelSheet(reel: reel),
    );
    if (changed == null || !mounted) return;
    showMessage(context, changed);
    _load();
  }

  @override
  Widget build(BuildContext context) {
    final reels = _reels;
    final header = GradientPageHeader(
      title: 'الريلز',
      subtitle: 'فيديوهات قصيرة تظهر للمرضى في تبويب الريلز',
      emoji: '🎬',
      colors: const [kBrandDark, kBrandPrimary, Color(0xFF29B6F6)],
    );

    return Scaffold(
      backgroundColor: kBrandSurface,
      floatingActionButton: reels == null
          ? null
          : FloatingActionButton.extended(
              onPressed: _edit,
              backgroundColor: kBrandPrimary,
              foregroundColor: Colors.white,
              icon: const Icon(Icons.video_call_rounded),
              label: const Text('إضافة ريل'),
            ),
      body: reels == null || reels.isEmpty
          ? Column(
              children: [
                header,
                Expanded(
                  child: reels != null
                      ? const EmptyState(
                          title: 'لا توجد فيديوهات بعد',
                          subtitle: 'أضف أول فيديو ليظهر للمرضى في تبويب الريلز',
                        )
                      : _error != null
                          ? EmptyState(title: 'تعذّر التحميل', subtitle: _error!)
                          : const AppLoader(),
                ),
              ],
            )
          : ListView.builder(
              padding: const EdgeInsets.only(bottom: 100),
              itemCount: reels.length + 1,
              itemBuilder: (_, i) => i == 0 ? header : _tile(reels[i - 1]),
            ),
    );
  }

  Widget _tile(DoctorReel r) => Container(
        margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(22),
          boxShadow: softShadow(),
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(22),
            onTap: () => _edit(r),
            child: Padding(
              padding: const EdgeInsets.all(10),
              child: Row(
                children: [
                  Opacity(opacity: r.active ? 1 : 0.45, child: _cover(r)),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(r.title,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                                fontWeight: FontWeight.w800, color: kBrandText)),
                        const SizedBox(height: 2),
                        Text('${r.views} مشاهدة',
                            style: const TextStyle(color: kBrandMuted, fontSize: 13)),
                        if (!r.active)
                          const Text('مخفي عن المرضى',
                              style: TextStyle(color: kPendingColor, fontSize: 13)),
                      ],
                    ),
                  ),
                  IconButton(
                    tooltip: 'تشغيل',
                    onPressed: r.videoUrl.isEmpty ? null : () => _play(context, url: r.videoUrl),
                    icon: const Icon(Icons.play_circle_fill_rounded,
                        size: 34, color: kBrandPrimary),
                  ),
                ],
              ),
            ),
          ),
        ),
      );

  Widget _cover(DoctorReel r) {
    const icon = Icon(Icons.movie_outlined, color: kBrandPrimary);
    return Container(
      width: 60,
      height: 80,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: kBrandSky,
        borderRadius: BorderRadius.circular(14),
      ),
      child: r.coverUrl == null
          ? icon
          : Image.network(r.coverUrl!,
              fit: BoxFit.cover, errorBuilder: (_, __, ___) => icon),
    );
  }
}

void _play(BuildContext context, {String? url, String? path}) {
  Navigator.push(context,
      MaterialPageRoute(builder: (_) => _ReelPlayerPage(url: url, path: path)));
}

/// Add or edit one reel. Pops the message to show after a change.
class _ReelSheet extends StatefulWidget {
  final DoctorReel? reel;

  const _ReelSheet({this.reel});

  @override
  State<_ReelSheet> createState() => _ReelSheetState();
}

class _ReelSheetState extends State<_ReelSheet> {
  final _form = GlobalKey<FormState>();
  late final _title = TextEditingController(text: widget.reel?.title);
  late final _description = TextEditingController(text: widget.reel?.description);
  late bool _active = widget.reel?.active ?? true;
  late String? _coverUrl = widget.reel?.coverUrl;
  String? _pickedCover;
  bool _removeCover = false;
  String? _pickedVideo;
  double _videoMb = 0;
  bool _busy = false;
  String? _error;
  Map<String, String> _errors = const {};

  @override
  void dispose() {
    _title.dispose();
    _description.dispose();
    super.dispose();
  }

  Future<void> _pickVideo() async {
    final path = await pickVideoPath();
    if (path == null || !mounted) return;
    final bytes = await File(path).length();
    if (!mounted) return;
    setState(() {
      if (bytes > kMaxReelBytes) {
        _errors = {'video': 'حجم الفيديو يجب ألا يتجاوز 100 ميجابايت'};
      } else {
        _pickedVideo = path;
        _videoMb = bytes / (1024 * 1024);
        _errors = const {};
      }
    });
  }

  Future<void> _pickCover() async {
    final path = await pickPhotoPath();
    if (path != null && mounted) setState(() => _pickedCover = path);
  }

  Future<void> _run(Future<void> Function() action, String done) async {
    setState(() {
      _busy = true;
      _error = null;
      _errors = const {};
    });
    try {
      await action();
      if (mounted) Navigator.pop(context, done);
    } on ApiException catch (e) {
      if (!mounted) return;
      if (e.unauthorized) {
        Navigator.pop(context);
        return;
      }
      setState(() {
        _busy = false;
        _errors = e.fieldErrors;
        _error = e.fieldErrors.isEmpty ? e.message : null;
      });
    }
  }

  void _save() {
    final r = widget.reel;
    final valid = _form.currentState!.validate();
    if (r == null && _pickedVideo == null) {
      setState(() => _errors = {'video': 'اختر فيديو من المعرض'});
      return;
    }
    if (!valid) return;
    _run(
      () => DoctorPageApi.saveReel(
        id: r?.id,
        title: _title.text,
        description: _description.text,
        active: _active,
        videoPath: _pickedVideo,
        coverPath: _pickedCover,
        removeCover: _removeCover,
      ),
      r == null ? 'تمت إضافة الفيديو' : 'تم حفظ التعديلات',
    );
  }

  Future<void> _delete() async {
    final r = widget.reel!;
    final ok = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        title: const Text('حذف الفيديو؟'),
        content: Text('سيختفي «${r.title}» من تبويب الريلز، ولا يمكن التراجع عن الحذف.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(c, false), child: const Text('تراجع')),
          TextButton(
            onPressed: () => Navigator.pop(c, true),
            child: const Text('حذف', style: TextStyle(color: kCancelledColor)),
          ),
        ],
      ),
    );
    if (ok == true && mounted) _run(() => DoctorPageApi.deleteReel(r.id), 'تم حذف الفيديو');
  }

  @override
  Widget build(BuildContext context) {
    final editing = widget.reel != null;
    return PopScope(
      canPop: !_busy,
      child: Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(18, 18, 18, 24),
          child: Form(
            key: _form,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(editing ? 'تعديل الفيديو' : 'إضافة فيديو',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                        fontSize: 18, fontWeight: FontWeight.w900, color: kBrandText)),
                const SizedBox(height: 14),
                _videoBox(),
                const SizedBox(height: 12),
                PhotoField(
                  size: 72,
                  placeholderIcon: Icons.image_outlined,
                  url: _coverUrl,
                  pickedPath: _pickedCover,
                  onPick: _pickCover,
                  onRemove: () => setState(() {
                    _pickedCover = null;
                    _coverUrl = null;
                    _removeCover = true;
                  }),
                ),
                const Text('صورة الغلاف (اختياري)',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: kBrandMuted, fontSize: 12)),
                if (_errors['thumbnail'] != null)
                  Text(_errors['thumbnail']!,
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: kCancelledColor, fontSize: 12)),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _title,
                  maxLength: 150,
                  decoration: fieldDecoration('العنوان',
                      icon: Icons.title_rounded, error: _errors['title']),
                  validator: (v) => (v ?? '').trim().isEmpty ? 'أدخل العنوان' : null,
                ),
                const SizedBox(height: 6),
                TextFormField(
                  controller: _description,
                  minLines: 2,
                  maxLines: 5,
                  maxLength: 1000,
                  decoration: fieldDecoration('الوصف (اختياري)', error: _errors['description']),
                ),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  value: _active,
                  onChanged: (v) => setState(() => _active = v),
                  title: const Text('يظهر للمرضى في تبويب الريلز',
                      style: TextStyle(fontWeight: FontWeight.w800, color: kBrandText)),
                ),
                if (_error != null)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: Text(_error!,
                        style: const TextStyle(
                            color: kCancelledColor, fontWeight: FontWeight.w700)),
                  ),
                GradientButton(
                  label: editing ? 'حفظ التعديلات' : 'إضافة',
                  icon: Icons.save_rounded,
                  loading: _busy,
                  onTap: _busy ? null : _save,
                ),
                if (_busy && _pickedVideo != null)
                  const Padding(
                    padding: EdgeInsets.only(top: 10),
                    child: Text('جارٍ رفع الفيديو وقد يستغرق بضع دقائق. أبقِ التطبيق مفتوحاً.',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: kBrandMuted, fontSize: 13)),
                  ),
                if (editing)
                  TextButton.icon(
                    onPressed: _busy ? null : _delete,
                    icon: const Icon(Icons.delete_outline_rounded, color: kCancelledColor),
                    label: const Text('حذف الفيديو', style: TextStyle(color: kCancelledColor)),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _videoBox() {
    final existing = widget.reel?.videoUrl ?? '';
    final picked = _pickedVideo;
    final hasVideo = picked != null || existing.isNotEmpty;
    final error = _errors['video'];
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: kBrandSurface,
        borderRadius: BorderRadius.circular(18),
        border: error == null ? null : Border.all(color: kCancelledColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(hasVideo ? Icons.check_circle_rounded : Icons.video_library_outlined,
                  color: hasVideo ? kBrandSuccess : kBrandPrimary),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  picked != null
                      ? 'تم اختيار الفيديو (${_videoMb.toStringAsFixed(1)} ميجابايت)'
                      : hasVideo
                          ? 'الفيديو الحالي'
                          : 'فيديو عمودي، حتى 100 ميجابايت',
                  style: const TextStyle(fontWeight: FontWeight.w700, color: kBrandText),
                ),
              ),
            ],
          ),
          Wrap(
            children: [
              TextButton.icon(
                onPressed: _busy ? null : _pickVideo,
                icon: const Icon(Icons.video_library_rounded, size: 18),
                label: Text(hasVideo ? 'تغيير الفيديو' : 'اختيار من المعرض'),
              ),
              if (hasVideo)
                TextButton.icon(
                  onPressed: () => picked != null
                      ? _play(context, path: picked)
                      : _play(context, url: existing),
                  icon: const Icon(Icons.play_arrow_rounded, size: 18),
                  label: const Text('تشغيل'),
                ),
            ],
          ),
          if (error != null)
            Text(error, style: const TextStyle(color: kCancelledColor, fontSize: 12)),
        ],
      ),
    );
  }
}

/// Plays a reel from the server, or one just picked from the gallery.
class _ReelPlayerPage extends StatefulWidget {
  final String? url;
  final String? path;

  const _ReelPlayerPage({this.url, this.path});

  @override
  State<_ReelPlayerPage> createState() => _ReelPlayerPageState();
}

class _ReelPlayerPageState extends State<_ReelPlayerPage> {
  late final VideoPlayerController _video = widget.path != null
      ? VideoPlayerController.file(File(widget.path!))
      : VideoPlayerController.networkUrl(Uri.parse(widget.url!));
  bool _failed = false;

  @override
  void initState() {
    super.initState();
    _start();
  }

  Future<void> _start() async {
    try {
      await _video.initialize();
      await _video.setLooping(true);
      await _video.play();
      if (mounted) setState(() {});
    } catch (_) {
      if (mounted) setState(() => _failed = true);
    }
  }

  @override
  void dispose() {
    _video.dispose();
    super.dispose();
  }

  Future<void> _toggle() async {
    if (_video.value.isPlaying) {
      await _video.pause();
    } else {
      await _video.play();
    }
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: Center(
        child: _failed
            ? const Text('تعذّر تشغيل الفيديو', style: TextStyle(color: Colors.white))
            : !_video.value.isInitialized
                ? const CircularProgressIndicator(color: Colors.white)
                : GestureDetector(
                    onTap: _toggle,
                    child: AspectRatio(
                      aspectRatio: _video.value.aspectRatio,
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          VideoPlayer(_video),
                          if (!_video.value.isPlaying)
                            const Icon(Icons.play_arrow_rounded,
                                size: 72, color: Colors.white70),
                        ],
                      ),
                    ),
                  ),
      ),
    );
  }
}
