import 'package:flutter/material.dart';

/// Discloses remote storage and provider processing for AI chat messages.
class AiMessagePrivacyNotice extends StatelessWidget {
  const AiMessagePrivacyNotice({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 0, 12, 4),
      child: Semantics(
        container: true,
        label: 'تنبيه الخصوصية لمحادثة الذكاء الاصطناعي',
        child: Card(
          margin: EdgeInsets.zero,
          child: Padding(
            padding: const EdgeInsets.all(10),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  Icons.privacy_tip_outlined,
                  size: 20,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
                const SizedBox(width: 8),
                const Expanded(
                  child: Text(
                    'تنبيه الخصوصية: تُحفظ رسائلك في محادثات AUREN، وقد يُرسل نصها إلى خدمة الذكاء الاصطناعي المهيأة للرد. لا تكتب معلومات طبية أو شخصية حساسة إلا إذا كنت موافقًا على مشاركتها.',
                    style: TextStyle(fontSize: 12),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
