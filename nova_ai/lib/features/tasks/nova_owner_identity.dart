/// Small, Firebase-independent checks for preserving NOVA account identity.
bool hasNovaPasswordProvider(Iterable<String> providerIds) {
  return providerIds.any((providerId) => providerId == 'password');
}

bool matchesNovaOwnerEmail(String? accountEmail, String requestedEmail) {
  final account = (accountEmail ?? '').trim().toLowerCase();
  final requested = requestedEmail.trim().toLowerCase();
  return account.isNotEmpty && requested.isNotEmpty && account == requested;
}
