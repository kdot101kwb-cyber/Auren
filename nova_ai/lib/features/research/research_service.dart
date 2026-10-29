import 'package:http/http.dart' as http;

import 'public_opportunity_research_connector.dart';
import 'research_connector.dart';

/// Outcome of a bounded multi-source search.
///
/// A successful empty search is different from every connector failing; callers
/// can use [warnings] and [successfulConnectorIds] to communicate that clearly.
class ResearchSearchReport {
  const ResearchSearchReport({
    required this.results,
    required this.attemptedConnectorIds,
    required this.successfulConnectorIds,
    required this.warnings,
  });

  final List<ResearchResult> results;
  final List<String> attemptedConnectorIds;
  final List<String> successfulConnectorIds;
  final List<String> warnings;

  bool get hasSourceSuccess => successfulConnectorIds.isNotEmpty;
  bool get allSourcesFailed =>
      attemptedConnectorIds.isNotEmpty && successfulConnectorIds.isEmpty;
}

/// Coordinates provider-neutral research connectors.
///
/// Use [ResearchService.publicOpportunitySources] for read-only public job
/// search. Authenticated or paid providers must remain behind a trusted backend;
/// never place their credentials in this Flutter package.
class ResearchService {
  ResearchService({
    required List<ResearchConnector> connectors,
  }) : _connectors = List.unmodifiable(connectors);

  /// Ready-to-use research service backed by two public job-listing APIs.
  ///
  /// [client] is injectable for deterministic tests. No API keys are required.
  ResearchService.publicOpportunitySources({http.Client? client})
      : _connectors = List.unmodifiable([
          PublicOpportunityResearchConnector(client: client),
        ]);

  final List<ResearchConnector> _connectors;

  Future<ResearchSearchReport> search(ResearchQuery query) async {
    final normalizedQuery = query.normalized();
    final collected = <ResearchResult>[];
    final attempted = <String>[];
    final succeeded = <String>[];
    final warnings = <String>[];
    final seenConnectorIds = <String>{};

    for (final connector in _connectors) {
      final id = connector.id.trim();
      if (id.isEmpty || !seenConnectorIds.add(id)) {
        warnings.add('Skipped connector with empty or duplicate identifier.');
        continue;
      }
      attempted.add(id);
      try {
        final results = await connector.search(normalizedQuery);
        succeeded.add(id);
        collected.addAll(results);
      } catch (_) {
        // Do not surface raw exceptions: they can contain endpoints or secrets.
        warnings.add('Research source "$id" is unavailable.');
      }
    }

    return ResearchSearchReport(
      results: normalizeResearchResults(
        collected,
        maxResults: normalizedQuery.maxResults,
      ),
      attemptedConnectorIds: List.unmodifiable(attempted),
      successfulConnectorIds: List.unmodifiable(succeeded),
      warnings: List.unmodifiable(warnings),
    );
  }
}
