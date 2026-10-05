import 'dart:async';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import '../../../services/auth/auth_service.dart';
import '../../../services/social/random_call_service.dart';

class AurenRandomCallScreen extends StatefulWidget {
  final String callId;
  final bool caller;
  final String kind;
  final String otherName;

  const AurenRandomCallScreen({
    super.key,
    required this.callId,
    required this.caller,
    required this.kind,
    this.otherName = 'AUREN User',
  });

  @override
  State<AurenRandomCallScreen> createState() => _AurenRandomCallScreenState();
}

class _AurenRandomCallScreenState extends State<AurenRandomCallScreen> {
  final auth = FirebaseAurenAuthService();
  final service = AurenRandomCallService();
  final local = RTCVideoRenderer();
  final remote = RTCVideoRenderer();

  RTCPeerConnection? pc;
  MediaStream? stream;
  StreamSubscription<AurenRandomCall?>? callSub;
  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? candidateSub;
  Timer? connectionTimeout;
  Timer? reconnectTimer;

  final Set<String> receivedCandidateIds = <String>{};
  bool muted = false;
  bool cameraOff = false;
  bool ready = false;
  bool ended = false;
  bool reconnecting = false;
  bool reconnectAttempted = false;
  String state = 'connecting';

  @override
  void initState() {
    super.initState();
    _start();
  }

  Future<void> _start() async {
    try {
      await local.initialize();
      await remote.initialize();

      final uid = auth.currentUserId;
      if (uid == null) throw StateError('not_authenticated');

      const turnUrl = String.fromEnvironment('AUREN_TURN_URL');
      const turnUsername = String.fromEnvironment('AUREN_TURN_USERNAME');
      const turnCredential = String.fromEnvironment('AUREN_TURN_CREDENTIAL');

      final iceServers = <Map<String, dynamic>>[
        {'urls': 'stun:stun.l.google.com:19302'},
      ];
      if (turnUrl.isNotEmpty && turnUsername.isNotEmpty && turnCredential.isNotEmpty) {
        iceServers.add({
          'urls': turnUrl,
          'username': turnUsername,
          'credential': turnCredential,
        });
      }

      pc = await createPeerConnection({'iceServers': iceServers});

      pc!.onTrack = (e) {
        if (e.streams.isNotEmpty && mounted) {
          remote.srcObject = e.streams.first;
          setState(() => state = 'connected');
          _markConnected();
        }
      };

      pc!.onConnectionState = (s) {
        final value = s.toString().split('.').last;
        if (!mounted) return;

        if (value == 'connected') {
          _markConnected();
          setState(() {
            reconnecting = false;
            state = 'connected';
          });
          return;
        }

        if (value == 'disconnected') {
          setState(() {
            reconnecting = true;
            state = 'reconnecting';
          });
          _scheduleReconnect();
          return;
        }

        if (value == 'failed') {
          setState(() => state = 'reconnecting');
          _restartIce();
          return;
        }

        if (value == 'closed') {
          _finishLocally();
          return;
        }

        if (mounted) setState(() => state = value);
      };

      pc!.onIceCandidate = (c) async {
        if (c.candidate == null || ended) return;
        await service.addCandidate(
          widget.callId,
          senderUid: uid,
          candidate: RTCandidate(
            candidate: c.candidate,
            sdpMid: c.sdpMid,
            sdpMLineIndex: c.sdpMLineIndex,
          ),
        );
      };

      stream = await navigator.mediaDevices.getUserMedia({
        'audio': true,
        'video': widget.kind == 'video',
      });
      local.srcObject = stream;

      for (final t in stream!.getTracks()) {
        await pc!.addTrack(t, stream!);
      }

      if (widget.caller) {
        await _startCaller();
      } else {
        await _startCallee();
      }

      if (mounted) {
        setState(() => ready = true);
        _startConnectionTimeout();
      }
    } catch (_) {
      _failWithMessage();
    }
  }

  void _startConnectionTimeout() {
    connectionTimeout?.cancel();
    connectionTimeout = Timer(const Duration(seconds: 25), () {
      if (ended || state == 'connected') return;
      _failWithMessage(message: 'انتهت مهلة الاتصال. جرّب مطابقة أخرى.');
    });
  }

  void _markConnected() {
    connectionTimeout?.cancel();
    reconnectTimer?.cancel();
    if (mounted && state != 'connected') {
      setState(() {
        reconnecting = false;
        state = 'connected';
      });
    }
  }

  Future<void> _startCaller() async {
    final offer = await pc!.createOffer();
    await pc!.setLocalDescription(offer);
    final d = await pc!.getLocalDescription();
    await service.setOffer(
      widget.callId,
      {'sdp': d?.sdp, 'type': d?.type},
    );
    _listenForCallChanges();
    _listenForCandidates();
  }

  Future<void> _startCallee() async {
    final call = await service
        .watch(widget.callId)
        .firstWhere((value) => value == null || value.offer != null)
        .timeout(const Duration(seconds: 20));

    if (call == null || call.status == 'ended' || call.offer == null) {
      throw StateError('offer_missing');
    }

    final offer = call.offer!;
    await pc!.setRemoteDescription(
      RTCSessionDescription(
        offer['sdp'] as String,
        offer['type'] as String,
      ),
    );

    _listenForCandidates();

    final answer = await pc!.createAnswer();
    await pc!.setLocalDescription(answer);
    final d = await pc!.getLocalDescription();
    await service.answer(
      widget.callId,
      {'sdp': d?.sdp, 'type': d?.type},
    );
    _listenForCallChanges();
  }

  void _listenForCallChanges() {
    callSub ??= service.watch(widget.callId).listen((call) async {
      if (call == null || ended) return;

      if (call.status == 'ended') {
        await _finishLocally();
        return;
      }

      if (widget.caller && call.answer != null) {
        final current = await pc?.getRemoteDescription();
        if (current == null && !ended) {
          final a = call.answer!;
          await pc!.setRemoteDescription(
            RTCSessionDescription(
              a['sdp'] as String,
              a['type'] as String,
            ),
          );
        }
      }
    });
  }

  void _listenForCandidates() {
    candidateSub ??= service.watchCandidates(widget.callId).listen((snap) async {
      final uid = auth.currentUserId;
      if (uid == null || pc == null || ended) return;

      for (final change in snap.docChanges) {
        if (receivedCandidateIds.contains(change.doc.id)) continue;
        receivedCandidateIds.add(change.doc.id);

        final data = change.doc.data();
        if (data == null || data['senderUid'] == uid || data['candidate'] == null) continue;

        try {
          await pc!.addCandidate(
            RTCIceCandidate(
              data['candidate'] as String,
              data['sdpMid'] as String?,
              (data['sdpMLineIndex'] as num?)?.toInt(),
            ),
          );
        } catch (_) {
          // A candidate can arrive before the remote description.
          // The connection will retry through ICE restart if necessary.
        }
      }
    });
  }

  void _scheduleReconnect() {
    if (ended || reconnectAttempted) return;
    reconnectTimer?.cancel();
    reconnectTimer = Timer(const Duration(seconds: 3), _restartIce);
  }

  Future<void> _restartIce() async {
    if (ended || pc == null || reconnectAttempted) return;

    reconnectAttempted = true;
    reconnecting = true;

    try {
      pc!.restartIce();
      final offer = await pc!.createOffer({'iceRestart': true});
      await pc!.setLocalDescription(offer);
      final d = await pc!.getLocalDescription();
      await service.setOffer(
        widget.callId,
        {'sdp': d?.sdp, 'type': d?.type},
      );

      if (mounted) {
        setState(() => state = 'reconnecting');
      }

      Future<void>.delayed(const Duration(seconds: 10), () {
        if (!ended && mounted && state != 'connected') {
          _failWithMessage(
            message: 'تعذر إعادة الاتصال. جرّب الاتصال بشخص آخر.',
          );
        }
      });
    } catch (_) {
      _failWithMessage(message: 'تعذر إعادة الاتصال.');
    }
  }

  Future<void> _hangUp() async {
    if (ended) return;
    ended = true;
    connectionTimeout?.cancel();
    reconnectTimer?.cancel();

    try {
      await service.end(widget.callId, auth.currentUserId ?? 'unknown');
    } catch (_) {}

    if (mounted) Navigator.of(context).pop();
  }

  Future<void> _finishLocally() async {
    if (ended) return;
    ended = true;
    connectionTimeout?.cancel();
    reconnectTimer?.cancel();
    if (mounted) Navigator.of(context).pop();
  }

  void _failWithMessage({
    String message = 'تعذر تشغيل الكاميرا/الميكروفون أو بدء المكالمة.',
  }) {
    if (ended) return;
    ended = true;
    connectionTimeout?.cancel();
    reconnectTimer?.cancel();

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
    Navigator.of(context).pop();
  }

  @override
  void dispose() {
    connectionTimeout?.cancel();
    reconnectTimer?.cancel();
    callSub?.cancel();
    candidateSub?.cancel();

    for (final t in stream?.getTracks() ?? <MediaStreamTrack>[]) {
      t.stop();
    }

    stream?.dispose();
    pc?.close();
    local.dispose();
    remote.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isVideo = widget.kind == 'video';

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: Text(widget.otherName),
        backgroundColor: Colors.black,
      ),
      body: Stack(
        children: [
          Positioned.fill(
            child: isVideo
                ? RTCVideoView(
                    remote,
                    objectFit:
                        RTCVideoViewObjectFit.RTCVideoViewObjectFitCover,
                  )
                : const Center(
                    child: Icon(
                      Icons.person,
                      color: Colors.white,
                      size: 100,
                    ),
                  ),
          ),
          if (isVideo)
            Positioned(
              right: 16,
              top: 16,
              width: 110,
              height: 160,
              child: RTCVideoView(local, mirror: true),
            ),
          if (state != 'connected')
            Positioned(
              top: 16,
              left: 16,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: Colors.black54,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  child: Text(
                    state == 'ringing'
                        ? 'جاري الاتصال…'
                        : state == 'reconnecting'
                            ? 'إعادة الاتصال…'
                            : state,
                    style: const TextStyle(color: Colors.white),
                  ),
                ),
              ),
            ),
          Positioned(
            bottom: 24,
            left: 16,
            right: 16,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                IconButton(
                  onPressed: () => setState(() {
                    muted = !muted;
                    for (final t
                        in stream?.getAudioTracks() ?? <MediaStreamTrack>[]) {
                      t.enabled = !muted;
                    }
                  }),
                  icon: Icon(
                    muted ? Icons.mic_off : Icons.mic,
                    color: Colors.white,
                  ),
                ),
                IconButton(
                  onPressed: _hangUp,
                  icon: const Icon(
                    Icons.call_end,
                    color: Colors.red,
                    size: 38,
                  ),
                ),
                if (isVideo)
                  IconButton(
                    onPressed: () => setState(() {
                      cameraOff = !cameraOff;
                      for (final t
                          in stream?.getVideoTracks() ??
                              <MediaStreamTrack>[]) {
                        t.enabled = !cameraOff;
                      }
                    }),
                    icon: Icon(
                      cameraOff ? Icons.videocam_off : Icons.videocam,
                      color: Colors.white,
                    ),
                  ),
              ],
            ),
          ),
          if (!ready) const Center(child: CircularProgressIndicator()),
        ],
      ),
    );
  }
}
