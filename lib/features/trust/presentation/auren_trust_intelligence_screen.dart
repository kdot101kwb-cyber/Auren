import 'package:flutter/material.dart';
import '../../social/presentation/user_search_screen.dart';

/// The user-facing entry point for AUREN's shared trust and safety principles.
/// This first slice deliberately avoids inventing a numeric reputation score:
/// authoritative signals need trusted server-side provenance first.
class AurenTrustIntelligenceScreen extends StatelessWidget {
  const AurenTrustIntelligenceScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    return Scaffold(
      appBar: AppBar(
        title: const Text('AUREN Trust Intelligence'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  colorScheme.primaryContainer,
                  colorScheme.surfaceContainerHighest,
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(24),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.shield_outlined, size: 38, color: colorScheme.primary),
                const SizedBox(height: 12),
                Text(
                  'Trust should be earned, explained, and protected.',
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'AUREN Trust Intelligence is designed to help people make safer '
                  'decisions across social connections, opportunities, services, '
                  'and commerce—without pretending that any signal is perfect.',
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          Text('What it helps with', style: theme.textTheme.titleLarge),
          const SizedBox(height: 8),
          const _TrustCapabilityTile(
            icon: Icons.fact_check_outlined,
            title: 'Evidence-aware verification',
            description:
                'Distinguish confirmed evidence from profile claims and unverified reports.',
          ),
          const _TrustCapabilityTile(
            icon: Icons.report_gmailerrorred_outlined,
            title: 'Report suspicious activity',
            description:
                'Use AUREN’s existing reporting flow. A report is a signal for review, not proof of wrongdoing.',
          ),
          const _TrustCapabilityTile(
            icon: Icons.block_outlined,
            title: 'Personal safety controls',
            description:
                'Use existing blocking and safety tools to reduce unwanted interactions.',
          ),
          const _TrustCapabilityTile(
            icon: Icons.handshake_outlined,
            title: 'Safer opportunities and commerce',
            description:
                'Build toward transparent trust indicators supported by transaction evidence, review integrity, and dispute history.',
          ),
          const SizedBox(height: 12),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.info_outline, color: colorScheme.primary),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Text(
                      'No public trust score is shown in this initial release. '
                      'A score should only be introduced after its evidence, '
                      'privacy, anti-manipulation rules, and review process are validated.',
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          Text('Take action', style: theme.textTheme.titleLarge),
          const SizedBox(height: 8),
          Card(
            child: ListTile(
              leading: const Icon(Icons.manage_search_outlined),
              title: const Text('Find a person'),
              subtitle: const Text(
                'Open people search to review profiles. Use the existing report or block controls on relevant profiles or content.',
              ),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => const AurenUserSearchScreen(),
                ),
              ),
            ),
          ),
          Card(
            child: ListTile(
              leading: const Icon(Icons.fact_check_outlined),
              title: const Text('How to read trust signals'),
              subtitle: const Text(
                'A profile claim is not independently verified evidence. A user report is an allegation for review, not a finding.',
              ),
              trailing: const Icon(Icons.info_outline),
              onTap: () => showDialog<void>(
                context: context,
                builder: (dialogContext) => AlertDialog(
                  title: const Text('Read trust signals carefully'),
                  content: const Text(
                    'Profile claims describe what someone says about themselves. '
                    'Submitted evidence may support a claim but is not an official approval by itself. '
                    'Reports are unverified until reviewed. Automated signals can be incomplete or wrong. '
                    'Do not treat any single signal as proof of wrongdoing or a guarantee of safety.',
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.of(dialogContext).pop(),
                      child: const Text('Got it'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _TrustCapabilityTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String description;

  const _TrustCapabilityTile({
    required this.icon,
    required this.title,
    required this.description,
  });

  @override
  Widget build(BuildContext context) => Card(
        margin: const EdgeInsets.only(bottom: 8),
        child: ListTile(
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 8,
          ),
          leading: Icon(icon, size: 28),
          title: Text(title, style: const TextStyle(fontWeight: FontWeight.w700)),
          subtitle: Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text(description),
          ),
        ),
      );
}
