import 'dart:async';
import 'dart:convert';


import 'package:shared_preferences/shared_preferences.dart';

/// Local-first community workspace. These records are device-local drafts;
/// no event is published, no reservation/payment is made, and no vote is
/// represented as a cross-device/community-wide result until a trusted sync
/// contract is implemented.
class AurenCommunityWorkbenchStore {
  AurenCommunityWorkbenchStore({
    Future<SharedPreferences> Function()? preferences,
    String scope = 'device',
  })  : _preferences = preferences ?? SharedPreferences.getInstance,
        _scope = scope.trim().isEmpty ? 'device' : scope.trim();

  final Future<SharedPreferences> Function() _preferences;
  final String _scope;

  // Serialize read-modify-write operations by scoped preference key. This
  // prevents concurrent UI actions (or multiple store instances for the same
  // account) from overwriting each other's local changes in this process.
  static final Map<String, Future<void>> _mutationTails = <String, Future<void>>{};

  Future<T> _withMutationLock<T>(
    String key,
    Future<T> Function() action,
  ) async {
    final previous = _mutationTails[key] ?? Future<void>.value();
    final release = Completer<void>();
    final queued = release.future;
    _mutationTails[key] = queued;
    await previous;
    try {
      return await action();
    } finally {
      release.complete();
      if (identical(_mutationTails[key], queued)) {
        _mutationTails.remove(key);
      }
    }
  }

  // Signed-in accounts use isolated keys on shared Android devices.
  String _storageKey(String key) =>
      _scope == 'device' ? key : '$key.${Uri.encodeComponent(_scope)}';

  static const _spaceGuidelinesKey = 'auren.community.space_guidelines.v1';
  static const _projectsKey = 'auren.community.group_projects.v1';
  static const _proposalsKey = 'auren.community.governance_proposals.v1';
  static const _meetupsKey = 'auren.community.meetup_drafts.v1';

  Future<Map<String, dynamic>> _readMap(String key) async {
    final prefs = await _preferences();
    final raw = prefs.getString(key);
    if (raw == null || raw.isEmpty) return <String, dynamic>{};
    try {
      final decoded = jsonDecode(raw);
      if (decoded is Map) {
        final safe = <String, dynamic>{};
        // A malformed or hand-edited cache must not bypass the same bounds
        // enforced by saveSpaceGuidelines. Keep reads bounded as well as writes.
        for (final entry in decoded.entries) {
          if (safe.length >= 100) break;
          if (entry.key is! String ||
              (entry.key as String).trim().isEmpty ||
              (entry.key as String).length > 160 ||
              entry.value is! Map) {
            continue;
          }
          final value = Map<String, dynamic>.from(entry.value as Map);
          final topic = value['topic'];
          final rules = value['rules'];
          final updatedAt = value['updatedAt'];
          if (topic is String &&
              topic.length <= 80 &&
              rules is String &&
              rules.length <= 2000 &&
              updatedAt is String &&
              DateTime.tryParse(updatedAt) != null) {
            safe[entry.key as String] = value;
          }
        }
        return safe;
      }
    } on FormatException {
      // A corrupt local cache must not prevent the user from continuing.
    }
    return <String, dynamic>{};
  }

  Future<List<Map<String, dynamic>>> _readList(String key) async {
    final prefs = await _preferences();
    final raw = prefs.getString(key);
    if (raw == null || raw.isEmpty) return <Map<String, dynamic>>[];
    try {
      final decoded = jsonDecode(raw);
      if (decoded is List) {
        final safe = <Map<String, dynamic>>[];
        final seenIds = <String>{};
        // Treat local caches as untrusted input: enforce the same collection
        // bound on reads as writes and ignore duplicate identities. Without
        // this, a hand-edited/legacy cache could make list screens unbounded
        // or expose ambiguous records with the same ID.
        for (final item in decoded) {
          if (safe.length >= 100) break;
          if (item is! Map) continue;
          final record = Map<String, dynamic>.from(item);
          if (!_isValidRecordForKey(key, record)) continue;
          final id = record['id'] as String;
          if (!seenIds.add(id)) continue;
          safe.add(record);
        }
        return safe;
      }
    } on FormatException {
      // Recover as an empty local list; the next save replaces corrupt data.
    }
    return <Map<String, dynamic>>[];
  }

  bool _isValidRecordForKey(String key, Map<String, dynamic> record) {
    bool hasStrings(List<String> fields) =>
        fields.every((field) => record[field] is String);

    bool validVotes(Object? value) =>
        value is Map &&
        value.length <= 1000 &&
        value.entries.every(
          (entry) =>
              entry.key is String &&
              (entry.key as String).isNotEmpty &&
              (entry.key as String).length <= 128 &&
              entry.value is bool,
        );

    bool validAttendance(Object? value) =>
        value is Map &&
        value.length <= 1000 &&
        value.entries.every(
          (entry) =>
              entry.key is String &&
              (entry.key as String).isNotEmpty &&
              (entry.key as String).length <= 128 &&
              const {'interested', 'going', 'declined'}.contains(entry.value),
        );

    bool hasUniqueChildIds(List<dynamic> items) {
      final ids = <String>{};
      for (final item in items) {
        if (item is! Map || item['id'] is! String) return false;
        final id = (item['id'] as String).trim();
        if (id.isEmpty || !ids.add(id)) return false;
      }
      return true;
    }

    if (key.startsWith(_storageKey(_projectsKey))) {
      final tasks = record['tasks'];
      final milestones = record['milestones'];
      if (!hasStrings(['id', 'title', 'description', 'communityId', 'createdAt']) ||
          (record['id'] as String).isEmpty ||
          (record['id'] as String).length > 128 ||
          (record['title'] as String).isEmpty ||
          (record['title'] as String).length > 120 ||
          (record['description'] as String).length > 2000 ||
          (record['communityId'] as String).length > 160 ||
          DateTime.tryParse(record['createdAt'] as String) == null ||
          tasks is! List ||
          tasks.length > 100 ||
          milestones is! List ||
          milestones.length > 50) {
        return false;
      }
      final validTasks = tasks.every(
        (task) =>
            task is Map &&
            task['id'] is String &&
            (task['id'] as String).isNotEmpty &&
            (task['id'] as String).length <= 128 &&
            task['title'] is String &&
            (task['title'] as String).isNotEmpty &&
            (task['title'] as String).length <= 160 &&
            task['assignee'] is String &&
            (task['assignee'] as String).length <= 128 &&
            const {'todo', 'doing', 'done'}.contains(task['status']),
      );
      final validMilestones = milestones.every(
        (milestone) =>
            milestone is Map &&
            milestone['id'] is String &&
            (milestone['id'] as String).isNotEmpty &&
            (milestone['id'] as String).length <= 128 &&
            milestone['title'] is String &&
            (milestone['title'] as String).isNotEmpty &&
            (milestone['title'] as String).length <= 160 &&
            milestone['completed'] is bool,
      );
      return validTasks &&
          validMilestones &&
          hasUniqueChildIds(tasks) &&
          hasUniqueChildIds(milestones);
    }

    if (key.startsWith(_storageKey(_proposalsKey))) {
      return hasStrings([
            'id',
            'communityId',
            'title',
            'proposedRule',
            'createdAt',
          ]) &&
          (record['id'] as String).isNotEmpty &&
          (record['id'] as String).length <= 128 &&
          (record['communityId'] as String).isNotEmpty &&
          (record['communityId'] as String).length <= 160 &&
          (record['title'] as String).isNotEmpty &&
          (record['title'] as String).length <= 120 &&
          (record['proposedRule'] as String).isNotEmpty &&
          (record['proposedRule'] as String).length <= 2000 &&
          DateTime.tryParse(record['createdAt'] as String) != null &&
          const {'open', 'accepted', 'rejected', 'withdrawn'}
              .contains(record['status']) &&
          validVotes(record['votes']);
    }

    if (key.startsWith(_storageKey(_meetupsKey))) {
      final capacity = record['capacity'];
      final startsAt = record['startsAt'];
      return hasStrings([
            'id',
            'title',
            'description',
            'startsAt',
            'location',
            'createdAt',
          ]) &&
          (record['id'] as String).isNotEmpty &&
          (record['id'] as String).length <= 128 &&
          (record['title'] as String).isNotEmpty &&
          (record['title'] as String).length <= 120 &&
          (record['description'] as String).length <= 2000 &&
          (record['location'] as String).length <= 160 &&
          DateTime.tryParse(startsAt as String) != null &&
          DateTime.tryParse(record['createdAt'] as String) != null &&
          capacity is int &&
          capacity >= 1 &&
          capacity <= 10000 &&
          record['status'] == 'draft' &&
          validAttendance(record['attendance']);
    }

    return false;
  }

  Future<void> _writeMap(String key, Map<String, dynamic> value) async {
    final prefs = await _preferences();
    await prefs.setString(key, jsonEncode(value));
  }

  Future<void> _writeList(String key, List<Map<String, dynamic>> value) async {
    final prefs = await _preferences();
    await prefs.setString(key, jsonEncode(value));
  }

  // Timestamps can collide when several records are created in one clock tick.
  // The process-local sequence adds a second uniqueness component for this store.
  static int _idSequence = 0;

  String _id(String prefix) =>
      '${prefix}_${DateTime.now().microsecondsSinceEpoch}_${_idSequence++}';

  Future<void> saveSpaceGuidelines({
    required String spaceId,
    required String topic,
    required String rules,
  }) async {
    return _withMutationLock(_storageKey(_spaceGuidelinesKey), () async {
    final id = spaceId.trim();
    final cleanTopic = topic.trim();
    final cleanRules = rules.trim();
    if (id.isEmpty || id.length > 160 || cleanTopic.length > 80 || cleanRules.length > 2000) {
      throw ArgumentError('Space topic or rules are invalid.');
    }
    final all = await _readMap(_storageKey(_spaceGuidelinesKey));
    if (!all.containsKey(id) && all.length >= 100) {
      throw StateError('Local space-guideline limit reached.');
    }
    all.remove(id);
    all[id] = <String, dynamic>{
      'topic': cleanTopic,
      'rules': cleanRules,
      'updatedAt': DateTime.now().toUtc().toIso8601String(),
    };
    final bounded = Map<String, dynamic>.fromEntries(
      all.entries.skip(all.length > 100 ? all.length - 100 : 0),
    );
    await _writeMap(_storageKey(_spaceGuidelinesKey), bounded);
  
    });
  }

  Future<Map<String, dynamic>> readSpaceGuidelines(String spaceId) async {
    final all = await _readMap(_storageKey(_spaceGuidelinesKey));
    final value = all[spaceId.trim()];
    return value is Map ? Map<String, dynamic>.from(value) : <String, dynamic>{};
  }

  Future<List<Map<String, dynamic>>> listProjects() => _readList(_storageKey(_projectsKey));

  /// Deletes a project only from this device. No remote project or member data
  /// is changed by this local-first MVP.
  Future<void> deleteProject(String projectId) async {
    return _withMutationLock(_storageKey(_projectsKey), () async {
    final id = projectId.trim();
    if (id.isEmpty) throw ArgumentError('Project ID is required.');
    final projects = await listProjects();
    final originalLength = projects.length;
    projects.removeWhere((project) => project['id'] == id);
    if (projects.length == originalLength) throw StateError('Project not found.');
    await _writeList(_storageKey(_projectsKey), projects);
  
    });
  }

  Future<String> createProject({
    required String title,
    required String description,
    required String communityId,
  }) async {
    return _withMutationLock(_storageKey(_projectsKey), () async {
    final cleanTitle = title.trim();
    final cleanDescription = description.trim();
    final cleanCommunity = communityId.trim();
    if (cleanTitle.isEmpty || cleanTitle.length > 120 ||
        cleanDescription.length > 2000 || cleanCommunity.isEmpty ||
        cleanCommunity.length > 160) {
      throw ArgumentError('Project title, description, or community is invalid.');
    }
    final projects = await listProjects();
    if (projects.length >= 100) {
      throw StateError('Local project limit reached.');
    }
    final id = _id('project');
    projects.insert(0, <String, dynamic>{
      'id': id,
      'title': cleanTitle,
      'description': cleanDescription,
      'communityId': cleanCommunity,
      'createdAt': DateTime.now().toUtc().toIso8601String(),
      'tasks': <Map<String, dynamic>>[],
      'milestones': <Map<String, dynamic>>[],
    });
    await _writeList(_storageKey(_projectsKey), projects);
    return id;
  
    });
  }

  Future<void> addProjectTask({
    required String projectId,
    required String title,
    String assignee = '',
  }) async {
    final cleanTitle = title.trim();
    final cleanAssignee = assignee.trim();
    if (projectId.trim().isEmpty || cleanTitle.isEmpty ||
        cleanTitle.length > 160 || cleanAssignee.length > 128) {
      throw ArgumentError('Task title or assignee is invalid.');
    }
    await _mutateProject(projectId, (project) {
      final tasks = List<Map<String, dynamic>>.from(project['tasks'] as List? ?? const []);
      if (tasks.length >= 100) throw StateError('Project task limit reached.');
      tasks.add(<String, dynamic>{
        'id': _id('task'),
        'title': cleanTitle,
        'assignee': cleanAssignee,
        'status': 'todo',
      });
      project['tasks'] = tasks;
    });
  }

  Future<void> setProjectTaskStatus({
    required String projectId,
    required String taskId,
    required String status,
  }) async {
    if (!const {'todo', 'doing', 'done'}.contains(status)) {
      throw ArgumentError('Unsupported task status.');
    }
    await _mutateProject(projectId, (project) {
      final tasks = List<Map<String, dynamic>>.from(project['tasks'] as List? ?? const []);
      final cleanTaskId = taskId.trim();
      if (cleanTaskId.isEmpty) throw ArgumentError('Task ID is required.');
      final index = tasks.indexWhere((task) => task['id'] == cleanTaskId);
      if (index < 0) throw StateError('Task not found.');
      tasks[index] = <String, dynamic>{...tasks[index], 'status': status};
      project['tasks'] = tasks;
    });
  }

  Future<void> addProjectMilestone({
    required String projectId,
    required String title,
  }) async {
    final cleanTitle = title.trim();
    if (cleanTitle.isEmpty || cleanTitle.length > 160) {
      throw ArgumentError('Milestone title is invalid.');
    }
    await _mutateProject(projectId, (project) {
      final milestones = List<Map<String, dynamic>>.from(
        project['milestones'] as List? ?? const [],
      );
      if (milestones.length >= 50) throw StateError('Project milestone limit reached.');
      milestones.add(<String, dynamic>{
        'id': _id('milestone'),
        'title': cleanTitle,
        'completed': false,
      });
      project['milestones'] = milestones;
    });
  }

  Future<void> setMilestoneCompleted({
    required String projectId,
    required String milestoneId,
    required bool completed,
  }) async {
    await _mutateProject(projectId, (project) {
      final milestones = List<Map<String, dynamic>>.from(
        project['milestones'] as List? ?? const [],
      );
      final cleanMilestoneId = milestoneId.trim();
      if (cleanMilestoneId.isEmpty) {
        throw ArgumentError('Milestone ID is required.');
      }
      final index = milestones.indexWhere((item) => item['id'] == cleanMilestoneId);
      if (index < 0) throw StateError('Milestone not found.');
      milestones[index] = <String, dynamic>{
        ...milestones[index],
        'completed': completed,
      };
      project['milestones'] = milestones;
    });
  }

  Future<void> _mutateProject(
    String projectId,
    void Function(Map<String, dynamic> project) mutate,
  ) async {
    return _withMutationLock(_storageKey(_projectsKey), () async {
    final cleanProjectId = projectId.trim();
    if (cleanProjectId.isEmpty) throw ArgumentError('Project ID is required.');
    final projects = await listProjects();
    final index = projects.indexWhere((project) => project['id'] == cleanProjectId);
    if (index < 0) throw StateError('Project not found.');
    final project = Map<String, dynamic>.from(projects[index]);
    mutate(project);
    projects[index] = project;
    await _writeList(_storageKey(_projectsKey), projects);
  
    });
  }

  int projectProgress(Map<String, dynamic> project) {
    final tasks = List<Map<String, dynamic>>.from(project['tasks'] as List? ?? const []);
    final milestones = List<Map<String, dynamic>>.from(
      project['milestones'] as List? ?? const [],
    );
    final total = tasks.length + milestones.length;
    if (total == 0) return 0;
    final completed = tasks.where((task) => task['status'] == 'done').length +
        milestones.where((item) => item['completed'] == true).length;
    return ((completed / total) * 100).round();
  }

  Future<List<Map<String, dynamic>>> listProposals() => _readList(_storageKey(_proposalsKey));

  /// Removes a proposal draft and its local votes from this device only.
  Future<void> deleteProposal(String proposalId) async {
    return _withMutationLock(_storageKey(_proposalsKey), () async {
    final id = proposalId.trim();
    if (id.isEmpty) throw ArgumentError('Proposal ID is required.');
    final proposals = await listProposals();
    final originalLength = proposals.length;
    proposals.removeWhere((proposal) => proposal['id'] == id);
    if (proposals.length == originalLength) throw StateError('Proposal not found.');
    await _writeList(_storageKey(_proposalsKey), proposals);
  
    });
  }

  Future<String> createRuleProposal({
    required String communityId,
    required String title,
    required String proposedRule,
  }) async {
    return _withMutationLock(_storageKey(_proposalsKey), () async {
    final cleanCommunity = communityId.trim();
    final cleanTitle = title.trim();
    final cleanRule = proposedRule.trim();
    if (cleanCommunity.isEmpty || cleanCommunity.length > 160 ||
        cleanTitle.isEmpty || cleanTitle.length > 120 ||
        cleanRule.isEmpty || cleanRule.length > 2000) {
      throw ArgumentError('Proposal details are invalid.');
    }
    final proposals = await listProposals();
    if (proposals.length >= 100) {
      throw StateError('Local proposal limit reached.');
    }
    final id = _id('proposal');
    proposals.insert(0, <String, dynamic>{
      'id': id,
      'communityId': cleanCommunity,
      'title': cleanTitle,
      'proposedRule': cleanRule,
      'votes': <String, bool>{},
      'status': 'open',
      'createdAt': DateTime.now().toUtc().toIso8601String(),
    });
    await _writeList(_storageKey(_proposalsKey), proposals);
    return id;
  
    });
  }

  Future<void> voteOnProposal({
    required String proposalId,
    required String voterId,
    required bool support,
  }) async {
    return _withMutationLock(_storageKey(_proposalsKey), () async {
    final voter = voterId.trim();
    if (proposalId.trim().isEmpty || voter.isEmpty || voter.length > 128) {
      throw ArgumentError('A valid local voter ID is required.');
    }
    final proposals = await listProposals();
    final cleanProposalId = proposalId.trim();
    if (cleanProposalId.isEmpty) throw ArgumentError('Proposal ID is required.');
    final index = proposals.indexWhere((item) => item['id'] == cleanProposalId);
    if (index < 0) throw StateError('Proposal not found.');
    final proposal = Map<String, dynamic>.from(proposals[index]);
    if (proposal['status'] != 'open') throw StateError('Proposal is closed.');
    final votes = Map<String, bool>.from(proposal['votes'] as Map? ?? const {});
    if (votes.containsKey(voter)) throw StateError('This voter has already voted.');
    if (votes.length >= 1000) throw StateError('Local vote limit reached.');
    votes[voter] = support;
    proposal['votes'] = votes;
    proposals[index] = proposal;
    await _writeList(_storageKey(_proposalsKey), proposals);
  
    });
  }

  Future<void> closeProposal({
    required String proposalId,
    required String status,
  }) async {
    return _withMutationLock(_storageKey(_proposalsKey), () async {
    if (!const {'accepted', 'rejected', 'withdrawn'}.contains(status)) {
      throw ArgumentError('Unsupported proposal status.');
    }
    final proposals = await listProposals();
    final cleanProposalId = proposalId.trim();
    if (cleanProposalId.isEmpty) throw ArgumentError('Proposal ID is required.');
    final index = proposals.indexWhere((item) => item['id'] == cleanProposalId);
    if (index < 0) throw StateError('Proposal not found.');
    if (proposals[index]['status'] != 'open') throw StateError('Proposal is already closed.');
    proposals[index] = <String, dynamic>{...proposals[index], 'status': status};
    await _writeList(_storageKey(_proposalsKey), proposals);
  
    });
  }

  int proposalSupportCount(Map<String, dynamic> proposal) {
    final votes = Map<String, bool>.from(proposal['votes'] as Map? ?? const {});
    return votes.values.where((value) => value).length;
  }

  Future<List<Map<String, dynamic>>> listMeetupDrafts() => _readList(_storageKey(_meetupsKey));

  /// Deletes a meetup draft and its attendance intentions from this device.
  Future<void> deleteMeetupDraft(String meetupId) async {
    return _withMutationLock(_storageKey(_meetupsKey), () async {
    final id = meetupId.trim();
    if (id.isEmpty) throw ArgumentError('Meetup ID is required.');
    final drafts = await listMeetupDrafts();
    final originalLength = drafts.length;
    drafts.removeWhere((draft) => draft['id'] == id);
    if (drafts.length == originalLength) throw StateError('Meetup draft not found.');
    await _writeList(_storageKey(_meetupsKey), drafts);
  
    });
  }

  Future<String> createMeetupDraft({
    required String title,
    required String description,
    required String startsAt,
    required String location,
    required int capacity,
  }) async {
    return _withMutationLock(_storageKey(_meetupsKey), () async {
    final cleanTitle = title.trim();
    final cleanDescription = description.trim();
    final cleanLocation = location.trim();
    final parsedStart = DateTime.tryParse(startsAt);
    if (cleanTitle.isEmpty || cleanTitle.length > 120 ||
        cleanDescription.length > 2000 || cleanLocation.length > 160 ||
        parsedStart == null || capacity < 1 || capacity > 10000) {
      throw ArgumentError('Meetup draft details are invalid.');
    }
    final drafts = await listMeetupDrafts();
    if (drafts.length >= 100) {
      throw StateError('Local meetup-draft limit reached.');
    }
    final id = _id('meetup');
    drafts.insert(0, <String, dynamic>{
      'id': id,
      'title': cleanTitle,
      'description': cleanDescription,
      'startsAt': parsedStart.toUtc().toIso8601String(),
      'location': cleanLocation,
      'capacity': capacity,
      'attendance': <String, String>{},
      'status': 'draft',
      'createdAt': DateTime.now().toUtc().toIso8601String(),
    });
    await _writeList(_storageKey(_meetupsKey), drafts);
    return id;
  
    });
  }

  Future<void> setDraftAttendance({
    required String meetupId,
    required String attendeeId,
    required String status,
  }) async {
    return _withMutationLock(_storageKey(_meetupsKey), () async {
    final attendee = attendeeId.trim();
    if (attendee.isEmpty || attendee.length > 128 ||
        !const {'interested', 'going', 'declined'}.contains(status)) {
      throw ArgumentError('Attendance draft is invalid.');
    }
    final drafts = await listMeetupDrafts();
    final cleanMeetupId = meetupId.trim();
    if (cleanMeetupId.isEmpty) throw ArgumentError('Meetup ID is required.');
    final index = drafts.indexWhere((item) => item['id'] == cleanMeetupId);
    if (index < 0) throw StateError('Meetup draft not found.');
    final draft = Map<String, dynamic>.from(drafts[index]);
    if (draft['status'] != 'draft') throw StateError('Meetup is not a draft.');
    final attendance = Map<String, String>.from(
      draft['attendance'] as Map? ?? const {},
    );
    if (!attendance.containsKey(attendee) && attendance.length >= 1000) {
      throw StateError('Local attendance list limit reached.');
    }
    // Capacity is a local planning limit, not a booking or reservation. A
    // person already marked "going" may change their intention without being
    // blocked by the capacity check.
    final capacity = draft['capacity'] as int;
    final wasGoing = attendance[attendee] == 'going';
    if (status == 'going' && !wasGoing &&
        attendance.values.where((value) => value == 'going').length >= capacity) {
      throw StateError('Proposed meetup capacity reached.');
    }
    attendance[attendee] = status;
    draft['attendance'] = attendance;
    drafts[index] = draft;
    await _writeList(_storageKey(_meetupsKey), drafts);
  
    });
  }

  int meetupGoingCount(Map<String, dynamic> meetup) {
    final attendance = Map<String, String>.from(
      meetup['attendance'] as Map? ?? const {},
    );
    return attendance.values.where((status) => status == 'going').length;
  }
}
