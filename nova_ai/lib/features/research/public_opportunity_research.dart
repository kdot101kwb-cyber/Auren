import 'public_opportunity_research_connector.dart';
import 'research_service.dart';

/// Creates NOVA's no-key public opportunity research pipeline.
///
/// The connector uses read-only public listings. A successful response is not
/// proof that a job is open or that a country is eligible; callers should show
/// the source and require the user to verify terms before applying.
ResearchService createPublicOpportunityResearchService() {
  return ResearchService(
    connectors: [PublicOpportunityResearchConnector()],
  );
}
