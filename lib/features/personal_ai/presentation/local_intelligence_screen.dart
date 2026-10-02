/// Compatibility entry point for the canonical Local Intelligence feature.
///
/// The Personal AI surface used to contain a second implementation. Keeping
/// this alias preserves existing imports while ensuring there is only one
/// Local Intelligence UI and data flow in AUREN.
library;

import '../../local/presentation/local_intelligence_screen.dart' as local;

typedef AurenLocalIntelligenceScreen = local.AurenLocalIntelligenceScreen;
