import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';

class ConnectivityService {
  ConnectivityService._internal();
  static final ConnectivityService instance = ConnectivityService._internal();

  final Connectivity _connectivity = Connectivity();
  final ValueNotifier<bool> isOnline = ValueNotifier<bool>(true);
  StreamSubscription<List<ConnectivityResult>>? _subscription;

  /// Initialize the connectivity listener
  Future<void> initialize() async {
    // Check initial state
    final results = await _connectivity.checkConnectivity();
    _updateStatus(results);

    // Listen for changes
    _subscription = _connectivity.onConnectivityChanged.listen(_updateStatus);
  }

  void _updateStatus(List<ConnectivityResult> results) {
    // We consider it online if any result is NOT 'none'
    final bool online = results.isNotEmpty && !results.contains(ConnectivityResult.none);
    
    // Only update if the status changed for performance
    if (isOnline.value != online) {
      isOnline.value = online;
    }
  }

  void dispose() {
    _subscription?.cancel();
  }
}
