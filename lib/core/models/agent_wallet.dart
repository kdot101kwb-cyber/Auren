class AurenAgentWallet {
 final String currency; final int balanceMinor; final int reservedMinor; final int dailyLimitMinor;
 const AurenAgentWallet({required this.currency,required this.balanceMinor,required this.reservedMinor,required this.dailyLimitMinor});
 int get availableMinor=>balanceMinor-reservedMinor;
 factory AurenAgentWallet.fromMap(Map<String,dynamic> m)=>AurenAgentWallet(currency:m['currency'] as String? ?? 'USD',balanceMinor:(m['balanceMinor'] as num?)?.toInt()??0,reservedMinor:(m['reservedMinor'] as num?)?.toInt()??0,dailyLimitMinor:(m['dailyLimitMinor'] as num?)?.toInt()??0);
}
