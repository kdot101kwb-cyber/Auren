import 'match_everything_service.dart';

class AurenMatchFlowStep {
  final String id;
  final String title;
  final String description;
  const AurenMatchFlowStep(this.id, this.title, this.description);
}

class AurenMatchActionFlow {
  List<AurenMatchFlowStep> stepsFor(AurenMatchItem item, String intent) {
    switch (item.action) {
      case AurenMatchAction.requestQuote:
        return const [
          AurenMatchFlowStep('find', 'العثور على المورد', 'AUREN يطابق طلبك مع الموردين المناسبين.'),
          AurenMatchFlowStep('requirements', 'تجهيز الطلب', 'حدد الكمية ومكان التسليم والملاحظات.'),
          AurenMatchFlowStep('contact', 'إرسال الطلب للمورد', 'يفتح AUREN محادثة جاهزة برسالة الطلب.'),
          AurenMatchFlowStep('follow_up', 'متابعة العرض', 'تابع السعر والعملة والحد الأدنى ومدة التجهيز والشحن من المحادثة.'),
        ];
      case AurenMatchAction.apply:
        return const [
          AurenMatchFlowStep('find', 'العثور على الفرصة', 'راجع الفرصة وتفاصيلها.'),
          AurenMatchFlowStep('application', 'تجهيز التقديم', 'أضف رسالة قصيرة اختيارية.'),
          AurenMatchFlowStep('submitted', 'إرسال التقديم', 'يُحفظ التقديم في حسابك.'),
          AurenMatchFlowStep('track', 'متابعة الفرصة', 'ارجع للفرصة وتابع حالة اهتمامك وتقديمك.'),
        ];
      case AurenMatchAction.addToCart:
        return const [
          AurenMatchFlowStep('find', 'العثور على المنتج', 'راجع المنتج والبائع.'),
          AurenMatchFlowStep('cart', 'إضافة للسلة', 'أضف الكمية المطلوبة إلى سلتك.'),
          AurenMatchFlowStep('contact', 'التواصل مع البائع', 'اسأل عن السعر والتوفر والشحن عند الحاجة.'),
        ];
      case AurenMatchAction.contact:
        return const [
          AurenMatchFlowStep('find', 'العثور على جهة التواصل', 'AUREN حدد الحساب المرتبط بالنتيجة.'),
          AurenMatchFlowStep('contact', 'فتح المحادثة', 'ابدأ محادثة مباشرة مع سياق طلبك.'),
          AurenMatchFlowStep('next', 'المتابعة', 'أكمل الاتفاق أو السؤال داخل Messenger.'),
        ];
      case AurenMatchAction.follow:
      case AurenMatchAction.save:
        return const [
          AurenMatchFlowStep('find', 'العثور على النتيجة', 'راجع النتيجة وسياق المطابقة.'),
          AurenMatchFlowStep('save', 'حفظ / متابعة', 'احتفظ بها للوصول السريع لاحقاً.'),
          AurenMatchFlowStep('return', 'الرجوع إليها', 'يمكنك العودة من قسمك المحفوظ أو المتابعات.'),
        ];
      case AurenMatchAction.watch:
      case AurenMatchAction.open:
        return const [
          AurenMatchFlowStep('find', 'العثور على النتيجة', 'AUREN وجد نتيجة مرتبطة بطلبك.'),
          AurenMatchFlowStep('open', 'فتح التفاصيل', 'راجع التفاصيل والمعلومات المتاحة.'),
        ];
    }
  }
}
