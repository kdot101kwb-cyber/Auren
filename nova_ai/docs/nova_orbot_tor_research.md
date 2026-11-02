# NOVA Orbot / Tor research integration

## Scope
- Android only; Orbot is an optional external app and is not bundled.
- Orbot documents a local HTTPS CONNECT proxy at `127.0.0.1:8118`.
- NOVA opens Orbot's launcher activity; the user must start Tor in Orbot.
- NOVA checks the local proxy and then calls the Tor Project check endpoint. A positive result requires `IsTor=true`.
- DuckDuckGo HTML search requests are sent through the same proxy.

## Fail-closed rules
- No direct-network fallback is implemented.
- Only HTTPS destinations are accepted by the proxy policy.
- TLS certificate validation remains enabled; no permissive certificate callback is installed.
- Redirects are disabled for verification and search requests.
- Search response HTML is shown as text and is not executed or loaded into a WebView.
- No credentials, cookies, wallet secrets, or private keys are sent.
- Tor is not a guarantee of anonymity; users must not submit identifying information.

## Manual Android validation
1. Install Orbot from the official Orbot site or Guardian Project distribution.
2. Open Orbot from NOVA and tap Start in Orbot.
3. Return to NOVA and verify both the local listener and `IsTor=true`.
4. Search a harmless test phrase. Confirm that a Tor verification failure sends no search.
5. Stop Orbot and repeat; search must fail closed.
6. Test with Orbot absent; NOVA must show an open/install error without crashing.

## Limitations
This adds a Tor-routed web-search transport, not a crawler or a complete Deep Web index. Onion services must be HTTPS-accessible through Tor; the current HTML search provider does not index arbitrary onion sites. Search-result parsing, source ranking, safe document handling, and background scheduling remain separate work.
