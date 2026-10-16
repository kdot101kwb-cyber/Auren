# AUREN Repository Capability Inventory — pass 2

Audit date: 2026-10-16  
Baseline inspected: `main` at `0fc34147173fc6f15b5ea6413bb1863b68091c5d`

## What this inventory can and cannot prove

This is a path-level inventory of the repository tree, not a full code, UX, security, or end-to-end review. A screen or service file proves that code exists at that path; it does not prove that the feature is complete, production-ready, wired into navigation, or safe to ship.

## Existing capability areas found in the repository

| Capability area | Evidence found on `main` | Deduplication implication |
| --- | --- | --- |
| Social / timeline | `lib/features/social/presentation/timeline_screen.dart`, `create_post_screen.dart`, `comments_screen.dart`, `user_search_screen.dart` | Do not create another general social feed without a proven gap. |
| Messaging | `lib/features/messenger/presentation/messenger_screen.dart`, `conversation_list_screen.dart`, `group_details_screen.dart`, `message_safety_screen.dart` | Extend Messenger and its group/safety flows rather than duplicate chat. |
| Marketplace / commerce | `lib/features/marketplace/presentation/marketplace_screen.dart`, `marketplace_commerce_screen.dart`, `product_detail_screen.dart`, `seller_storefront_screen.dart` | New shopping ideas should integrate with commerce rather than form a second store. |
| Business / global directory / suppliers | `lib/features/business/presentation/business_screen.dart`, `lib/features/global_directory/presentation/auren_business_navigator_screen.dart`, `auren_supplier_discovery_screen.dart`, `auren_supplier_offer_comparison_screen.dart` | Supplier discovery, business directory, and reverse marketplace concepts need explicit ownership boundaries. |
| Travel | `lib/features/travel/presentation/travel_screen.dart`, `lib/services/travel/travel_repository.dart` | Journey OS and Airport Intelligence should be travel capabilities unless a distinct domain gap is proven. |
| Local / place discovery | `lib/features/local/`, plus business directory and travel areas | Places should be audited as a shared location capability across these systems before becoming a standalone top-level system. |
| News / culture | `lib/features/culture/presentation/culture_news_screen.dart` | Existing news-related UI is present. PR #220 adds a separate news domain model; check integration before building another news feature. |
| Education | `lib/features/education/presentation/education_screen.dart`, `lib/services/education/` | Keep learning/enrollment capabilities here; use shared Library/Research services rather than recreating them. |
| Agriculture | `lib/features/agriculture/presentation/agriculture_dashboard_screen.dart`, `auren_agriculture_screen.dart`, `livestock_dashboard_screen.dart`, `lib/services/agriculture/gaez_v5_service.dart` | Agriculture and livestock AI are already represented; extend existing modules. |
| Entertainment / media | `lib/features/entertainment/`, `lib/features/tv/`, `lib/features/media/`, `lib/services/tv/` | Music, series, video, TV, and watch-together need connected ownership, not parallel entertainment systems. |
| Creator / talent | `lib/features/creator/`, `lib/features/talent/`, `lib/services/talent/` | Creator monetization/studio and talent discovery are present as separate related domains; preserve their distinct jobs. |
| Health / safety / emergency | `lib/features/health/`, `lib/features/safety/`, `lib/features/emergency/` | Review privacy and safety boundaries before adding overlapping safety or health services. |
| AI / search / opportunities / action | `lib/features/personal_ai/`, `lib/features/search/`, `lib/features/opportunities/`, `lib/features/action_center/` | World Intelligence should compose these capabilities rather than duplicate search, AI, or opportunity tracking. |
| Payments / orders | `lib/features/payments/`, `lib/features/orders/` | Any transaction workflow must reuse existing payment/order ownership and authorization boundaries. |
| Communities / games / events-adjacent UI | `lib/features/communities/`, `lib/features/games/`, `lib/features/entertainment/presentation/auren_events_entertainment_screen.dart` | Confirm where community events live before introducing another events or challenges system. |

## Open workstreams observed in this conversation

- PR #220: AUREN News & Information domain model (draft; all five checks passed at the last check).
- PR #223: AUREN News feed ordering policy (draft; depends on #220; verify its latest status separately).
- PR #224: this documentation audit (draft; all five checks passed at the last check).

These states can change; query GitHub checks before claiming current status.

## Candidate decisions after pass 2

1. **Do not start a separate World Intelligence system yet.** Compose Universal Search / Personal AI / Opportunity Radar / News after an integration map identifies what is missing.
2. **Do not start a separate Places system yet.** First define a shared location contract used by Local, Business, Travel, and search.
3. **Do not start Journey OS or Airport Intelligence as standalone systems yet.** Audit and extend the existing Travel domain first.
4. **Do not start another News system.** Continue the existing News & Information PR chain, and verify dependency order and CI.
5. **Do not start another broad system merely because a feature folder is sparse.** Search the master blueprint and all active PRs before creating a workstream.

## Next engineering step

The most defensible next implementation is a **small, non-duplicative shared contract** only after the existing Travel/Local integration is inspected in source. Before coding, review their repositories, route/navigation integration, models, tests, and active PRs; then document one specific gap with acceptance tests. This inventory alone is not authorization to claim a system is complete.
