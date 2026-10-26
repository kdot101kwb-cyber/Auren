import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'nova_game_build_coordinator.dart';

class NovaGameBuildPlanPanel extends StatefulWidget {
  const NovaGameBuildPlanPanel({
    required this.ideaController,
    super.key,
  });

  final TextEditingController ideaController;

  @override
  State<NovaGameBuildPlanPanel> createState() => _NovaGameBuildPlanPanelState();
}

class _NovaGameBuildPlanPanelState extends State<NovaGameBuildPlanPanel> {
  NovaGameBuildPlan? plan;

  void createPlan() {
    try {
      final next = NovaGameBuildCoordinator.createPlan(widget.ideaController.text);
      setState(() => plan = next);
    } on ArgumentError {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('اكتب فكرة اللعبة أولاً لإنشاء خطة مترابطة.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final current = plan;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('منسّق بناء اللعبة — 10 أدوات',
                style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 6),
            const Text(
              'يربط الأدوات في سلسلة عمل واحدة: تصميم ← نموذج أولي ← أصول ← عالم وفيزياء ← سلوك وحوار ← اختبار. هذا المنسّق ينشئ خطة قابلة للتصدير؛ لا يدّعي أنه شغّل الأدوات الخارجية.',
            ),
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                key: const Key('create_connected_game_plan_button'),
                onPressed: createPlan,
                icon: const Icon(Icons.account_tree_outlined),
                label: const Text('اربط الأدوات وأنشئ خطة اللعبة'),
              ),
            ),
            if (current != null) ...[
              const Divider(height: 24),
              Text('المحرك الأساسي: ${current.engine}'),
              Text('الأدوات المرتبطة بالخطة: ${current.connectedToolIds.length}'),
              Text('المراحل: ${current.tasks.length}'),
              const SizedBox(height: 8),
              for (final task in current.tasks)
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: CircleAvatar(child: Text('${task.order}')),
                  title: Text(task.title),
                  subtitle: Text(
                    '${task.goal}\nالأدوات: ${task.tools.map((tool) => tool.name).join('، ')}\n'
                    'فحص القبول: ${task.acceptanceCheck}\n'
                    'الحالة: ${task.requiresExternalRunner ? 'يتطلب مشغّل Godot خارجي' : 'يمكن تخطيطه محلياً'}',
                  ),
                  isThreeLine: true,
                ),
              const Text(
                'تنبيه: جميع الخطوات حالياً مخططة وليست منفذة. التشغيل والاختبار والتصدير إلى APK تتطلب بيئة بناء متوافقة ومتصلة.',
              ),
              Align(
                alignment: AlignmentDirectional.centerEnd,
                child: OutlinedButton.icon(
                  key: const Key('copy_connected_game_plan_button'),
                  onPressed: () async {
                    await Clipboard.setData(
                      ClipboardData(text: const JsonEncoder.withIndent('  ').convert(current.toJson())),
                    );
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('تم نسخ خطة الأدوات بصيغة JSON')),
                      );
                    }
                  },
                  icon: const Icon(Icons.copy),
                  label: const Text('انسخ خطة الربط JSON'),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
