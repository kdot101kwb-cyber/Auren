import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:android_intent_plus/android_intent.dart';
/// Orbot's local HTTP CONNECT proxy. Orbot documents HTTPS proxy on 8118.
class NovaTorResearch {
  NovaTorResearch._();

  static const proxyHost = '127.0.0.1';
  static const proxyPort = 8118;
  static const torCheckUri = 'https://check.torproject.org/api/ip';
  static const searchUri = 'https://html.duckduckgo.com/html/';

  static String proxyFor(Uri uri) {
    if (uri.scheme != 'https') {
      throw ArgumentError.value(uri, 'uri', 'Tor research only permits HTTPS.');
    }
    return 'PROXY $proxyHost:$proxyPort';
  }

  static Future<void> openOrbot() async {
    if (!Platform.isAndroid) {
      throw UnsupportedError('Orbot launch is supported on Android only.');
    }
    const intent = AndroidIntent(
      action: 'android.intent.action.MAIN',
      category: 'android.intent.category.LAUNCHER',
      package: 'org.torproject.android',
    );
    await intent.launch();
  }

  static Future<bool> isProxyListening({
    Duration timeout = const Duration(seconds: 3),
  }) async {
    try {
      final socket = await Socket.connect(proxyHost, proxyPort, timeout: timeout);
      await socket.close();
      return true;
    } on SocketException {
      return false;
    } on TimeoutException {
      return false;
    }
  }

  static HttpClient _newClient() {
    final client = HttpClient()
      ..connectionTimeout = const Duration(seconds: 12)
      ..idleTimeout = const Duration(seconds: 8)
      ..maxConnectionsPerHost = 2
      ..findProxy = proxyFor;
    return client;
  }

  /// Returns true only when the Tor Project endpoint confirms IsTor=true.
  /// No direct-connection fallback is ever attempted.
  static Future<bool> verifyTor({
    Duration timeout = const Duration(seconds: 20),
  }) async {
    final client = _newClient();
    try {
      final request = await client.getUrl(Uri.parse(torCheckUri)).timeout(timeout);
      request.followRedirects = false;
      final response = await request.close().timeout(timeout);
      if (response.statusCode != HttpStatus.ok) return false;
      final body = await utf8.decoder.bind(response).join().timeout(timeout);
      final decoded = jsonDecode(body);
      return decoded is Map && decoded['IsTor'] == true;
    } on Object {
      return false;
    } finally {
      client.close(force: true);
    }
  }

  /// Search requests are sent only through Orbot's HTTPS CONNECT proxy.
  /// The returned HTML is deliberately not opened in an external browser.
  static Future<String> searchHtml(
    String query, {
    Duration timeout = const Duration(seconds: 30),
  }) async {
    final normalized = query.trim();
    if (normalized.isEmpty) {
      throw ArgumentError.value(query, 'query', 'Search query cannot be empty.');
    }
    final client = _newClient();
    try {
      final uri = Uri.parse(searchUri).replace(queryParameters: {'q': normalized});
      final request = await client.getUrl(uri).timeout(timeout);
      request.followRedirects = false;
      request.headers.set(HttpHeaders.acceptHeader, 'text/html');
      request.headers.set(HttpHeaders.userAgentHeader, 'NOVA-Research/1.0');
      final response = await request.close().timeout(timeout);
      if (response.statusCode != HttpStatus.ok) {
        throw HttpException('Tor search returned HTTP ${response.statusCode}.', uri: uri);
      }
      return await utf8.decoder.bind(response).join().timeout(timeout);
    } finally {
      client.close(force: true);
    }
  }
}
