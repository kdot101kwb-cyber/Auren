import 'package:cloud_functions/cloud_functions.dart';

class AurenPluginValidationResult {
  final bool valid;
  final Map<String, dynamic> manifest;
  final Map<String, dynamic> policy;
  const AurenPluginValidationResult({required this.valid, required this.manifest, required this.policy});
}

class AurenAgentPluginRepository {
  final FirebaseFunctions _functions;
  AurenAgentPluginRepository({FirebaseFunctions? functions}) : _functions = functions ?? FirebaseFunctions.instanceFor(region: 'us-central1');

  Future<AurenPluginValidationResult> validate(Map<String, dynamic> manifest) async {
    final result = await _functions.httpsCallable('validateAurenPlugin').call({'manifest': manifest});
    final data = Map<String, dynamic>.from(result.data as Map);
    return AurenPluginValidationResult(
      valid: data['valid'] == true,
      manifest: Map<String, dynamic>.from(data['manifest'] as Map? ?? const {}),
      policy: Map<String, dynamic>.from(data['policy'] as Map? ?? const {}),
    );
  }

  Future<void> installValidated({required String pluginId, required String name, required String version, required List<String> capabilities}) async {
    await _functions.httpsCallable('installAurenPlugin').call({'manifest': {
      'pluginId': pluginId,
      'name': name,
      'version': version,
      'entrypoint': 'auren://plugin',
      'capabilities': capabilities,
    }});
  }

  Future<String> uninstall(String pluginId) async {
    final id = pluginId.trim();
    if (id.isEmpty) throw ArgumentError('Plugin id is required.');
    final result = await _functions.httpsCallable('uninstallAurenPlugin').call({'pluginId': id});
    final data = Map<String, dynamic>.from(result.data as Map);
    return data['status']?.toString() ?? 'uninstalled';
  }

  Future<Map<String, dynamic>> simulateAction({required String agentId, required String action, Map<String, dynamic> payload = const {}}) async {
    final result = await _functions.httpsCallable('simulateAurenAgentAction').call({'agentId': agentId, 'action': action, 'payload': payload});
    return Map<String, dynamic>.from(result.data as Map);
  }

  Future<Map<String, dynamic>> recordInvocation({required String pluginId, required String action, Map<String, dynamic> payload = const {}}) async {
    final id = pluginId.trim();
    final normalizedAction = action.trim();
    if (id.isEmpty || normalizedAction.isEmpty) throw ArgumentError('Plugin id and action are required.');
    if (normalizedAction.length > 120 || !RegExp(r'^[a-zA-Z0-9._:-]+
    final result = await _functions.httpsCallable('invokeAurenPlugin').call({'pluginId': id, 'action': normalizedAction, 'payload': payload});
    return Map<String, dynamic>.from(result.data as Map);
  }
}
).hasMatch(normalizedAction)) {
      throw ArgumentError('Invalid plugin action.');
    }
    if (payload.length > 20) throw ArgumentError('Plugin payload has too many fields.');
    final result = await _functions.httpsCallable('invokeAurenPlugin').call({'pluginId': pluginId, 'action': action, 'payload': payload});
    return Map<String, dynamic>.from(result.data as Map);
  }
}
