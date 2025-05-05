import 'package:upgrader/upgrader.dart';

class CustomUpgraderMessages extends UpgraderMessages {
  @override
  String? message(UpgraderMessage messageKey) {
    switch (messageKey) {
      case UpgraderMessage.title:
        return 'يجب عليك تحديث';
      case UpgraderMessage.body:
        return 'تحديث جديد من التطبيق متاح الآن.';
      case UpgraderMessage.buttonTitleUpdate:
        return 'التحديث الان';
      case UpgraderMessage.prompt:
        return 'النسخة الجديدة تتضمن ميزات اضافية.';
      case UpgraderMessage.releaseNotes:
        return 'ملاحظات الإصدار:';
      default:
        return super.message(messageKey);
    }
  }
}
