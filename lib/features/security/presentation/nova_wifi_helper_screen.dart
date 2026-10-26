import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class NovaWifiHelperScreen extends StatelessWidget {
  const NovaWifiHelperScreen({super.key});
  static const _channel = MethodChannel('nova/wifi');

  Future<void> _openSettings(BuildContext context) async {
    try {
      await _channel.invokeMethod<void>('openWifiSettings');
    } on PlatformException catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Could not open Wi-Fi settings: ${e.message ?? 'unknown error'}')));
    } on MissingPluginException {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Update the Android app to use this feature.')));
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('NOVA Wi-Fi Helper')),
    body: ListView(padding: const EdgeInsets.all(16), children: [
      const Icon(Icons.wifi_find, size: 64),
      const SizedBox(height: 12),
      Text('Find and join a network', style: Theme.of(context).textTheme.headlineSmall, textAlign: TextAlign.center),
      const SizedBox(height: 8),
      const Text('Open Android Wi-Fi settings to view nearby networks and join an open network or enter a password for a network you are allowed to use.', textAlign: TextAlign.center),
      const SizedBox(height: 20),
      FilledButton.icon(onPressed: () => _openSettings(context), icon: const Icon(Icons.settings), label: const Text('Open Wi-Fi settings')),
      const Card(child: ListTile(leading: Icon(Icons.lock_open), title: Text('Open networks'), subtitle: Text('Choose a public network that does not require a password. Avoid sensitive activity on public Wi-Fi.'))),
      const Card(child: ListTile(leading: Icon(Icons.key), title: Text('Forgot your network password?'), subtitle: Text('Check the router label, your provider app, or your own router settings.'))),
      const Card(child: ListTile(leading: Icon(Icons.shield_outlined), title: Text('Network protection'), subtitle: Text('This helper does not crack passwords or bypass network security.'))),
    ]),
  );
}
