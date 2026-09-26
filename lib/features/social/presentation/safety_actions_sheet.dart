import 'package:flutter/material.dart';
import '../../../services/social/safety_repository.dart';

class AurenSafetyActionsSheet extends StatelessWidget {
  final String uid;
  final String targetUid;
  final String? contentId;
  final String? contentType;

  const AurenSafetyActionsSheet({
    super.key,
    required this.uid,
    required this.targetUid,
    this.contentId,
    this.contentType,
  });

  static Future<void> show(
    BuildContext context, {
    required String uid,
    required String targetUid,
    String? contentId,
    String? contentType,
  }) => showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    builder: (_) => AurenSafetyActionsSheet(
      uid: uid,
      targetUid: targetUid,
      contentId: contentId,
      contentType: contentType,
    ),
  );

  Future<void> _report(BuildContext context) async {
    final reason = await showDialog<String>(
      context: context,
      builder: (dialog) => SimpleDialog(
        title: const Text('Report'),
        children: [
          for (final value in ['Spam', 'Harassment', 'Impersonation', 'Unsafe content', 'Other'])
            SimpleDialogOption(
              onPressed: () => Navigator.pop(dialog, value),
              child: Text(value),
            ),
        ],
      ),
    );
    if (reason == null || !context.mounted) return;
    await AurenSafetyRepository().report(
      reporterUid: uid,
      reportedUid: targetUid,
      reason: reason,
      contentId: contentId,
      contentType: contentType,
    );
    if (context.mounted) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Report submitted.')));
    }
  }

  Future<void> _block(BuildContext context) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (dialog) => AlertDialog(
        title: const Text('Block this user?'),
        content: const Text('You will stop seeing their social interactions where AUREN can apply the block.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialog, false), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.pop(dialog, true), child: const Text('Block')),
        ],
      ),
    );
    if (ok != true || !context.mounted) return;
    await AurenSafetyRepository().block(uid, targetUid);
    if (context.mounted) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('User blocked.')));
    }
  }

  @override
  Widget build(BuildContext context) => SafeArea(
    child: Column(mainAxisSize: MainAxisSize.min, children: [
      ListTile(
        leading: const Icon(Icons.block),
        title: const Text('Block'),
        onTap: () => _block(context),
      ),
      ListTile(
        leading: const Icon(Icons.flag_outlined),
        title: const Text('Report'),
        onTap: () => _report(context),
      ),
      const SizedBox(height: 8),
    ]),
  );
}
