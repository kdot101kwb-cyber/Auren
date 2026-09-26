import 'package:flutter/material.dart';

import '../../../services/social/adaptive_profile_service.dart';
import '../../../services/social/profile_mode_service.dart';

/// Context-aware presentation of the same AUREN profile.
/// It recommends how the profile should be presented in the current surface,
/// but never changes the user's active mode automatically.
class AurenAdaptiveProfileSurface extends StatelessWidget {
  final String uid;
  final AurenProfileContext context;
  final bool compact;
  final String? intent;

  const AurenAdaptiveProfileSurface({
    super.key,
    required this.uid,
    required this.context,
    this.compact = false,
    this.intent,
  });

  @override
  Widget build(BuildContext context) {
    final modes = AurenProfileModeService();
    final adaptive = const AurenAdaptiveProfileService();

    return FutureBuilder<AurenProfileMode>(
      future: modes.getActiveMode(uid),
      builder: (context, modeSnapshot) {
        if (!modeSnapshot.hasData) return const SizedBox.shrink();
        final currentMode = modeSnapshot.data!;

        return FutureBuilder<AurenProfileModeData>(
          future: modes.get(uid, currentMode),
          builder: (context, profileSnapshot) {
            if (!profileSnapshot.hasData) return const SizedBox.shrink();
            final profile = profileSnapshot.data!;
            final result = adaptive.suggest(
              currentMode: currentMode,
              context: this.context,
              profile: profile,
              intent: intent,
            );

            final changed = result.mode != currentMode;
            final displayMode = result.mode;
            final title = changed
                ? 'AUREN يكيّف عرض ملفك'
                : 'ملفك متوافق مع هذا السياق';
            final description = changed
                ? 'في ' + this.context.label + ' يمكن إبراز وضع ' + displayMode.label + '.'
                : 'وضع ' + displayMode.label + ' مناسب لهذا المكان في AUREN.';

            if (compact) {
              return Card(
                child: ListTile(
                  dense: true,
                  leading: const CircleAvatar(
                    child: Icon(Icons.auto_awesome, size: 18),
                  ),
                  title: Text(
                    displayMode.label + ' • ' + this.context.label,
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                  subtitle: Text(
                    changed
                        ? 'AUREN يقترح عرض ملفك بهذا الشكل هنا.'
                        : 'AUREN يعرض ملفك بهذا السياق.',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              );
            }

            return Card(
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const CircleAvatar(
                          child: Icon(Icons.auto_awesome),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            title,
                            style: const TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        Chip(label: Text(displayMode.label)),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(description),
                    const SizedBox(height: 6),
                    Text(
                      'الثقة ' + result.confidence.toString() + '٪ • ' + result.reason,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                    if (changed) ...[
                      const SizedBox(height: 8),
                      const Text(
                        'لن يتغير وضعك الأساسي تلقائيًا؛ هذا مجرد أسلوب عرض للسياق الحالي.',
                        style: TextStyle(fontSize: 12),
                      ),
                    ],
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}


/// Context-aware actions that change the visible next-step controls without
/// changing the user's primary Profile Mode.
class AurenAdaptiveActionRail extends StatelessWidget {
  final String uid;
  final AurenProfileContext context;
  final String? intent;
  final ValueChanged<String> onPrompt;

  const AurenAdaptiveActionRail({
    super.key,
    required this.uid,
    required this.context,
    required this.onPrompt,
    this.intent,
  });

  List<String> _actions(AurenProfileMode mode) {
    switch (mode) {
      case AurenProfileMode.creator:
        return const ['اصنع فكرة محتوى', 'اكتشف جمهورك', 'استكشف محتوى مشابه'];
      case AurenProfileMode.professional:
        return const ['ابحث عن فرصة', 'طوّر مهارة', 'حسّن ملفي المهني'];
      case AurenProfileMode.business:
        return const ['ابحث عن عملاء', 'اكتشف موردين', 'نمِّ مشروعي'];
      case AurenProfileMode.personal:
        return const ['اكتشف أشخاصًا', 'اكتشف شيئًا جديدًا', 'ابدأ محادثة'];
    }
  }

  @override
  Widget build(BuildContext context) {
    final modes = AurenProfileModeService();
    final adaptive = const AurenAdaptiveProfileService();

    return FutureBuilder<AurenProfileMode>(
      future: modes.getActiveMode(uid),
      builder: (context, modeSnapshot) {
        if (!modeSnapshot.hasData) return const SizedBox.shrink();
        final currentMode = modeSnapshot.data!;

        return FutureBuilder<AurenProfileModeData>(
          future: modes.get(uid, currentMode),
          builder: (context, profileSnapshot) {
            if (!profileSnapshot.hasData) return const SizedBox.shrink();
            final result = adaptive.suggest(
              currentMode: currentMode,
              context: this.context,
              profile: profileSnapshot.data!,
              intent: intent,
            );
            final actions = _actions(result.mode);

            return SizedBox(
              height: 44,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 2),
                itemCount: actions.length,
                separatorBuilder: (_, __) => const SizedBox(width: 8),
                itemBuilder: (_, index) => ActionChip(
                  avatar: const Icon(Icons.auto_awesome, size: 16),
                  label: Text(actions[index]),
                  onPressed: () => onPrompt(actions[index]),
                ),
              ),
            );
          },
        );
      },
    );
  }
}
