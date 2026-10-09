import 'dart:async';
import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

class PresenceService {
  PresenceService._internal();
  static final PresenceService instance = PresenceService._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  String? _nodeId;
  Timer? _heartbeatTimer;
  bool _isInitialized = false;

  /// Stream of the total number of active nodes (seen in the last 5 minutes)
  /// Includes a self-correction to ensure this device is counted immediately.
  late final Stream<int> activeNodesStream = Stream.periodic(const Duration(seconds: 30))
      .asyncMap((_) => _getActiveNodesCount())
      .asBroadcastStream();

  Future<int> _getActiveNodesCount() async {
    final fiveMinutesAgo = DateTime.now().subtract(const Duration(minutes: 5));
    try {
      final snapshot = await _firestore
          .collection('active_nodes')
          .where('lastSeen', isGreaterThan: Timestamp.fromDate(fiveMinutesAgo))
          .get();

      int count = snapshot.docs.length;

      // Self-Correction: If our device is initialized but not yet in the Firestore snapshot
      // (e.g. during initial sync or write delay), we manually count it as 1.
      if (_isInitialized && _nodeId != null) {
        bool containsSelf = snapshot.docs.any((doc) => doc.id == _nodeId);
        if (!containsSelf) {
          count += 1;
        }
      }

      return count == 0 && _isInitialized ? 1 : count;
    } catch (e) {
      debugPrint("PresenceService: Error fetching active nodes: $e");
      return _isInitialized ? 1 : 0;
    }
  }

  /// Initialize the presence system: generate/retrieve Node ID and start heartbeat
  Future<void> initialize() async {
    await _getOrCreateNodeId();
    await _updatePresence(); // Ensure first update is done before setting initialized
    _isInitialized = true;
    _startHeartbeat();
  }

  Future<void> _getOrCreateNodeId() async {
    final prefs = await SharedPreferences.getInstance();
    _nodeId = prefs.getString('node_id');

    if (_nodeId == null) {
      final deviceInfo = DeviceInfoPlugin();
      try {
        if (Platform.isAndroid) {
          final androidInfo = await deviceInfo.androidInfo;
          _nodeId = androidInfo.id;
        } else if (Platform.isIOS) {
          final iosInfo = await deviceInfo.iosInfo;
          _nodeId = iosInfo.identifierForVendor;
        }
      } catch (e) {
        _nodeId = const Uuid().v4();
      }

      _nodeId ??= const Uuid().v4();
      await prefs.setString('node_id', _nodeId!);
    }
    debugPrint("PresenceService: Node ID initialized: $_nodeId");
  }

  void _startHeartbeat() {
    _heartbeatTimer?.cancel();
    _heartbeatTimer = Timer.periodic(const Duration(minutes: 2), (_) => _updatePresence());
  }

  Future<void> _updatePresence() async {
    if (_nodeId == null) return;

    try {
      await _firestore.collection('active_nodes').doc(_nodeId).set({
        'nodeId': _nodeId,
        'lastSeen': FieldValue.serverTimestamp(),
        'platform': Platform.operatingSystem,
      }, SetOptions(merge: true));
      debugPrint("PresenceService: Heartbeat sent successfully.");
    } catch (e) {
      debugPrint("PresenceService: Failed to send heartbeat: $e");
    }
  }

  void stop() {
    _heartbeatTimer?.cancel();
    _isInitialized = false;
  }
}
