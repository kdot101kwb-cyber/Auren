enum EverydayLifeKind { task, note, taskList, household, householdSupply, householdMaintenance, appointmentDraft, localService }

class EverydayLifeItem {
  const EverydayLifeItem({
    required this.id,
    required this.kind,
    required this.title,
    this.details = '',
    this.category = '',
    this.quantity = '',
    this.requestedWindow = '',
    this.createdAt,
    this.dueAt,
    this.completed = false,
    this.favorite = false,
    this.providerName = '',
    this.contact = '',
    this.location = '',
    this.informationConfirmed = false,
  });

  final String id;
  final EverydayLifeKind kind;
  final String title;
  final String details;
  final String category;
  final String quantity;
  final String requestedWindow;
  final String? createdAt;
  final String? dueAt;
  final bool completed;
  final bool favorite;
  final String providerName;
  final String contact;
  final String location;
  /// False by default: user-provided directory details have not been verified.
  final bool informationConfirmed;

  EverydayLifeItem copyWith({
    String? title,
    String? details,
    String? category,
    String? quantity,
    String? requestedWindow,
    String? dueAt,
    bool clearDueAt = false,
    bool? completed,
    bool? favorite,
    String? providerName,
    String? contact,
    String? location,
    bool? informationConfirmed,
  }) => EverydayLifeItem(
    id: id,
    kind: kind,
    title: title ?? this.title,
    details: details ?? this.details,
    category: category ?? this.category,
    quantity: quantity ?? this.quantity,
    requestedWindow: requestedWindow ?? this.requestedWindow,
    createdAt: createdAt,
    dueAt: clearDueAt ? null : (dueAt ?? this.dueAt),
    completed: completed ?? this.completed,
    favorite: favorite ?? this.favorite,
    providerName: providerName ?? this.providerName,
    contact: contact ?? this.contact,
    location: location ?? this.location,
    informationConfirmed: informationConfirmed ?? this.informationConfirmed,
  );

  Map<String, Object?> toJson() => {
    'id': id,
    'kind': kind.name,
    'title': title,
    'details': details,
    'category': category,
    'quantity': quantity,
    'requestedWindow': requestedWindow,
    'createdAt': createdAt,
    'dueAt': dueAt,
    'completed': completed,
    'favorite': favorite,
    'providerName': providerName,
    'contact': contact,
    'location': location,
    'informationConfirmed': informationConfirmed,
  };

  factory EverydayLifeItem.fromJson(Map<String, dynamic> json) {
    final kindName = json['kind'] as String? ?? '';
    final kind = EverydayLifeKind.values.where((value) => value.name == kindName);
    final title = (json['title'] as String? ?? '').trim();
    final id = (json['id'] as String? ?? '').trim();
    if (id.isEmpty || title.isEmpty || kind.isEmpty) {
      throw const FormatException('Invalid everyday-life record');
    }
    return EverydayLifeItem(
      id: id,
      kind: kind.first,
      title: title,
      details: json['details'] as String? ?? '',
      category: json['category'] as String? ?? '',
      quantity: json['quantity'] as String? ?? '',
      requestedWindow: json['requestedWindow'] as String? ?? '',
      createdAt: json['createdAt'] as String?,
      dueAt: json['dueAt'] as String?,
      completed: json['completed'] == true,
      favorite: json['favorite'] == true,
      providerName: json['providerName'] as String? ?? '',
      contact: json['contact'] as String? ?? '',
      location: json['location'] as String? ?? '',
      // Legacy or missing confirmation fields remain unconfirmed.
      informationConfirmed: json['informationConfirmed'] == true,
    );
  }
}
