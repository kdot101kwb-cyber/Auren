import '../../core/models/talent.dart';
import '../../core/models/opportunity.dart';
import 'talent_discovery_service.dart';

class AurenAgentStep {
  final String agent; final String title; final String instruction;
  const AurenAgentStep({required this.agent, required this.title, required this.instruction});
}
class AurenSkillGap {
  final String skill; final String status; final int priority;
  const AurenSkillGap({required this.skill, required this.status, required this.priority});
}
class AurenTalentPlan {
  final AurenOpportunity opportunity; final int matchScore; final List<String> matchedSkills;
  final List<AurenSkillGap> skillGaps; final List<AurenAgentStep> steps;
  const AurenTalentPlan({required this.opportunity, required this.matchScore, required this.matchedSkills, required this.skillGaps, required this.steps});
  String toPrompt() => 'ابنِ خطة موحدة للفرصة: ${opportunity.title}. المطابقة: ${matchScore}%. المتطابقة: ${matchedSkills.join(', ')}. فجوات المهارات: ${skillGaps.map((g) => g.skill).join(', ')}. استخدم الوكلاء بالترتيب، وكل مرحلة تستفيد من السابقة. لا تنفذ إجراءً حساساً أو مالياً بدون موافقة صريحة.';
}
class AurenTalentAgentOrchestrator {
  const AurenTalentAgentOrchestrator();
  AurenTalentPlan buildPlan({required AurenTalent talent, required AurenOpportunity opportunity, required AurenTalentMatch match}) {
    final gaps = match.missingSkills.map(_norm).where((s) => s.isNotEmpty).toSet().toList()..sort();
    final skillGaps = gaps.asMap().entries.map((e) => AurenSkillGap(skill: e.value, status: 'missing', priority: e.key + 1)).toList();
    return AurenTalentPlan(opportunity: opportunity, matchScore: match.score, matchedSkills: List.unmodifiable(match.matchedSkills), skillGaps: List.unmodifiable(skillGaps), steps: const [
      AurenAgentStep(agent: 'Talent Discovery Agent', title: 'فهم الفرصة', instruction: 'حلل متطلبات الفرصة مقابل مهارات الموهبة.'),
      AurenAgentStep(agent: 'Opportunity Match Agent', title: 'تفسير المطابقة', instruction: 'فسر نقاط القوة والفجوات ونسبة المطابقة.'),
      AurenAgentStep(agent: 'Skill Coach Agent', title: 'سد الفجوة', instruction: 'حوّل الفجوات إلى مسار تعلم وتطبيق عملي.'),
      AurenAgentStep(agent: 'Career Agent', title: 'خطة التقدم', instruction: 'رتب خطوات التقديم والتطور المهني.'),
      AurenAgentStep(agent: 'Portfolio Agent', title: 'تجهيز الملف', instruction: 'حدد الأعمال والأدلة التي يجب إبرازها.'),
      AurenAgentStep(agent: 'Negotiation Agent', title: 'الاستعداد للتفاوض', instruction: 'جهز أسئلة ونقاط تفاوض ومعلومات يجب التحقق منها.'),
    ]);
  }
  List<AurenAgentStep> buildWorkflow({required AurenTalent talent, required AurenOpportunity opportunity, required AurenTalentMatch match}) => buildPlan(talent: talent, opportunity: opportunity, match: match).steps;
  static String _norm(String value) => value.trim().toLowerCase().replaceAll(RegExp(r'\s+'), ' ');
}