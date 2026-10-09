import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:async';


/// Global key to show pop-up snackbars from anywhere in the app
final GlobalKey<ScaffoldMessengerState> globalScaffoldMessengerKey =
    GlobalKey<ScaffoldMessengerState>();

class AlertItem {
  final String title;
  final String description;
  final DateTime createdAt; // real timestamp used for sorting
  final IconData icon;
  final Color color;
  final String? imageBase64;

  /// 'weapon' | 'shoplifting' — used to filter items per page
  final String source;

  const AlertItem({
    required this.title,
    required this.description,
    required this.createdAt,
    required this.icon,
    required this.color,
    this.imageBase64,
    this.source = 'weapon',
  });

  // Dedupe rule: equality by title + createdAt milliseconds + source
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AlertItem &&
          runtimeType == other.runtimeType &&
          title == other.title &&
          source == other.source &&
          createdAt.millisecondsSinceEpoch ==
              other.createdAt.millisecondsSinceEpoch;

  @override
  int get hashCode =>
      title.hashCode ^
      createdAt.millisecondsSinceEpoch.hashCode ^
      source.hashCode;
}

/// Singleton service that holds the alerts and exposes a ValueNotifier
class AlertService {
  AlertService._internal();
  static final AlertService instance = AlertService._internal();

  /// ValueNotifier so UI can listen and rebuild automatically
  final ValueNotifier<List<AlertItem>> alerts = ValueNotifier<List<AlertItem>>(
    <AlertItem>[],
  );

  /// Helper: returns a sorted copy (newest first)
  List<AlertItem> _sorted(List<AlertItem> list) {
    final copy = List<AlertItem>.from(list);
    copy.sort((a, b) => b.createdAt.compareTo(a.createdAt)); // newest first
    return copy;
  }

  /// Add a single alert (deduped using equality) and keep list sorted by createdAt desc
  void addAlert(AlertItem alert) {
    final current = List<AlertItem>.from(alerts.value);
    if (!current.contains(alert)) {
      current.add(alert);
      alerts.value = _sorted(current);
    }
  }

  /// Remove an alert
  void removeAlert(AlertItem alert) {
    final current = List<AlertItem>.from(alerts.value)..remove(alert);
    alerts.value = _sorted(current);
  }

  /// Clear all alerts
  void clearAlerts() => alerts.value = <AlertItem>[];

  // --------------------------
  // Real-time Firebase Listener
  // --------------------------

  bool _isListening = false;
  final List<StreamSubscription> _weaponSubscriptions = [];
  final Map<String, List<AlertItem>> _weaponAlertsMap = {};
  Map<String, bool> _notificationSettings = {'security': true, 'analytics': true};
  bool _isSettingsListening = false;
  StreamSubscription? _shopliftingSubscription;

  /// Private method to listen to settings from Firestore
  void _initSettingsListener() {
    if (_isSettingsListening) return;
    _isSettingsListening = true;

    FirebaseFirestore.instance
        .collection('app_settings')
        .doc('notification_settings')
        .snapshots()
        .listen((doc) {
      if (doc.exists) {
        final data = doc.data() as Map<String, dynamic>;
        _notificationSettings['security'] = (data['security'] as bool?) ?? true;
        _notificationSettings['analytics'] =
            (data['analytics'] as bool?) ?? true;
      }
    });
  }

  /// Connect to Firestore and start listening for WeaponDetections (historical + weapon-specific subcollections)
  void startListeningToWeapons() {
    _initSettingsListener(); // Ensure we are listening to settings
    if (_isListening) return;
    _isListening = true;

    final List<String> weaponTypes = ['Grenade', 'Knife', 'Missile', 'Pistol', 'Rifle'];

    // Helper to merge all weapon alerts and update notifier
    void updateCombinedAlerts() {
      final List<AlertItem> allWeaponAlerts = [];
      _weaponAlertsMap.forEach((key, list) {
        for (var item in list) {
          if (!allWeaponAlerts.contains(item)) {
            allWeaponAlerts.add(item);
          }
        }
      });

      // ATOMIC SYNC: Keep shoplifting alerts, replace weapon alerts
      final current = alerts.value
          .where((a) => a.source != 'weapon')
          .toList();
      current.addAll(allWeaponAlerts);
      alerts.value = _sorted(current);
    }

    // 1. Subscribe to Historical alerts (root level WeaponDetections documents)
    bool initialFetchHistorical = true;
    final historicalSub = FirebaseFirestore.instance
        .collection('WeaponDetections')
        .orderBy('timestamp', descending: true)
        .limit(20)
        .snapshots()
        .listen(
          (QuerySnapshot snapshot) {
            // Filter out any subcollection parent documents if they have no fields (e.g. Grenade)
            // Historical documents have actual alert fields like status or timestamp
            final List<AlertItem> syncedAlerts = snapshot.docs
                .where((doc) {
                  final data = doc.data() as Map<String, dynamic>? ?? {};
                  return data.containsKey('status') || data.containsKey('timestamp');
                })
                .map((doc) {
                  final data = doc.data() as Map<String, dynamic>;
                  final String status = data['status'] ?? 'Detection';
                  final String weaponType = data['weapon_type'] ?? 'Unknown';

                  DateTime createdAt = DateTime.now();
                  if (data['timestamp'] is Timestamp) {
                    createdAt = (data['timestamp'] as Timestamp).toDate();
                  } else if (data['timestamp'] is String) {
                    createdAt =
                        DateTime.tryParse(data['timestamp']) ?? DateTime.now();
                  }

                  return AlertItem(
                    title: "$status - $weaponType",
                    description: "Weapon tracking model detected: $weaponType",
                    createdAt: createdAt,
                    icon: Icons.security,
                    color: Colors.red,
                    imageBase64: data['image_base64'],
                    source: 'weapon',
                  );
                }).toList();

            // Check for incoming LIVE detections while app is open
            if (!initialFetchHistorical) {
              for (var change in snapshot.docChanges) {
                if (change.type == DocumentChangeType.added) {
                  final data = change.doc.data() as Map<String, dynamic>?;
                  if (data != null && (data.containsKey('status') || data.containsKey('timestamp'))) {
                    _showPopupNotification(
                      data['status'] ?? 'Alert',
                      data['weapon_type'] ?? 'Unknown',
                    );
                  }
                }
              }
            }

            _weaponAlertsMap['historical'] = syncedAlerts;
            updateCombinedAlerts();
            initialFetchHistorical = false;
          },
          onError: (error) {
            debugPrint("Error listening to historical weapons: $error");
          },
        );
    _weaponSubscriptions.add(historicalSub);

    // 2. Subscribe to each specific Weapon type alerts subcollection
    for (final weapon in weaponTypes) {
      bool initialFetchWeapon = true;
      final weaponSub = FirebaseFirestore.instance
          .collection('WeaponDetections')
          .doc(weapon)
          .collection('alerts')
          .orderBy('timestamp', descending: true)
          .limit(20)
          .snapshots()
          .listen(
            (QuerySnapshot snapshot) {
              final List<AlertItem> syncedAlerts = snapshot.docs.map((doc) {
                final data = doc.data() as Map<String, dynamic>? ?? {};
                final String status = data['status'] ?? 'Threat Detected';
                
                // If weapon_type is missing, default to the collection's weapon name
                final String rawWeaponType = data['weapon_type'] ?? weapon;
                // Capitalize first letter of weapon type to display nicely in UI
                final String weaponType = rawWeaponType.isNotEmpty
                    ? '${rawWeaponType[0].toUpperCase()}${rawWeaponType.substring(1)}'
                    : weapon;

                DateTime createdAt = DateTime.now();
                if (data['timestamp'] is Timestamp) {
                  createdAt = (data['timestamp'] as Timestamp).toDate();
                } else if (data['timestamp'] is String) {
                  createdAt =
                      DateTime.tryParse(data['timestamp']) ?? DateTime.now();
                }

                return AlertItem(
                  title: "$status - $weaponType",
                  description: "Weapon tracking model detected: $weaponType",
                  createdAt: createdAt,
                  icon: Icons.security,
                  color: Colors.red,
                  imageBase64: data['image_base64'],
                  source: 'weapon',
                );
              }).toList();

              // Check for incoming LIVE detections while app is open
              if (!initialFetchWeapon) {
                for (var change in snapshot.docChanges) {
                  if (change.type == DocumentChangeType.added) {
                    final data = change.doc.data() as Map<String, dynamic>?;
                    if (data != null) {
                      final String rawWeaponType = data['weapon_type'] ?? weapon;
                      final String weaponType = rawWeaponType.isNotEmpty
                          ? '${rawWeaponType[0].toUpperCase()}${rawWeaponType.substring(1)}'
                          : weapon;
                      _showPopupNotification(
                        data['status'] ?? 'Threat Detected',
                        weaponType,
                      );
                    }
                  }
                }
              }

              _weaponAlertsMap[weapon] = syncedAlerts;
              updateCombinedAlerts();
              initialFetchWeapon = false;
            },
            onError: (error) {
              debugPrint("Error listening to $weapon alerts: $error");
            },
          );
      _weaponSubscriptions.add(weaponSub);
    }
  }

  void _showPopupNotification(String status, String weaponType) {
    // Only show SnackBar if security alerts are enabled in settings
    if (_notificationSettings['security'] != true) return;

    globalScaffoldMessengerKey.currentState?.showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(
              Icons.warning_amber_rounded,
              color: Colors.white,
              size: 28,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "SECURITY ALERT!",
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  Text("$status: $weaponType detected in real-time!"),
                ],
              ),
            ),
          ],
        ),
        backgroundColor: Colors.redAccent.shade700,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.only(top: 10, left: 16, right: 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        duration: const Duration(seconds: 4),
        dismissDirection: DismissDirection.horizontal,
      ),
    );
  }

  // --------------------------
  // Real-time Shoplifting Listener
  // --------------------------

  bool _isListeningToShoplifting = false;

  /// Connect to Firestore and start listening for ShopliftingDetections
  void startListeningToShoplifting() {
    _initSettingsListener(); // Ensure we are listening to settings
    if (_isListeningToShoplifting) return;
    _isListeningToShoplifting = true;

    bool initialFetch = true;

    _shopliftingSubscription = FirebaseFirestore.instance
        .collection('shoplifting_incidents')
        .orderBy('timestamp', descending: true)
        .limit(30)
        .snapshots()
        .listen(
          (QuerySnapshot snapshot) {
            final List<AlertItem> shopliftingAlerts = snapshot.docs.map((doc) {
              final data = doc.data() as Map<String, dynamic>? ?? {};

              DateTime createdAt = DateTime.now();
              if (data['timestamp'] is Timestamp) {
                createdAt = (data['timestamp'] as Timestamp).toDate();
              } else if (data['timestamp'] is String) {
                createdAt =
                    DateTime.tryParse(data['timestamp']) ?? DateTime.now();
              }

              final String action = data['label'] ?? 'Shoplifting';
              final double confidence = (data['confidence'] ?? 0.0) is int
                  ? (data['confidence'] as int).toDouble()
                  : (data['confidence'] ?? 0.0).toDouble();

              // Handle "snapshot" field and strip base64 prefix if exists
              String? rawBase64 = data['snapshot'] as String?;
              if (rawBase64 != null && rawBase64.contains(',')) {
                rawBase64 = rawBase64.split(',').last;
              }

              final String confidenceStr = (confidence * 100).toStringAsFixed(
                0,
              );

              return AlertItem(
                title: 'Shoplifting Detected',
                description: '$action · ${confidenceStr}% confidence',
                createdAt: createdAt,
                icon: Icons.person_off_rounded,
                color: Colors.red,
                imageBase64: rawBase64,
                source: 'shoplifting',
              );
            }).toList();

            // Show popup for each NEW document added while the app is open
            if (!initialFetch) {
              for (var change in snapshot.docChanges) {
                if (change.type == DocumentChangeType.added) {
                  final data = change.doc.data() as Map<String, dynamic>?;
                  if (data != null) {
                    final String action = data['label'] ?? 'Shoplifting';
                    final double confidence = (data['confidence'] ?? 0.0) is int
                        ? (data['confidence'] as int).toDouble()
                        : (data['confidence'] ?? 0.0).toDouble();
                    _showShopliftingPopup(action, confidence);
                  }
                }
              }
            }

            // ATOMIC SYNC: keep weapon alerts, replace shoplifting alerts
            final current = alerts.value
                .where((a) => a.source != 'shoplifting')
                .toList();
            current.addAll(shopliftingAlerts);
            alerts.value = _sorted(current);
            initialFetch = false;
          },
          onError: (error) {
            debugPrint('Error listening to shoplifting: $error');
          },
        );
  }

  void _showShopliftingPopup(String action, double confidence) {
    // Only show SnackBar if security alerts are enabled in settings
    if (_notificationSettings['security'] != true) return;

    final String confidenceStr = (confidence * 100).toStringAsFixed(0);
    globalScaffoldMessengerKey.currentState?.showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.person_off_rounded, color: Colors.white, size: 28),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    '⚠ SHOPLIFTING ALERT!',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  Text('$action detected! Confidence: $confidenceStr%'),
                ],
              ),
            ),
          ],
        ),
        backgroundColor: const Color(0xFFE65100), // deep orange
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.only(top: 10, left: 16, right: 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        duration: const Duration(seconds: 5),
        dismissDirection: DismissDirection.horizontal,
      ),
    );
  }

  /// Cancel all active stream subscriptions (both weapon and shoplifting) and reset listening state.
  void stopListening() {
    for (var sub in _weaponSubscriptions) {
      sub.cancel();
    }
    _weaponSubscriptions.clear();
    _isListening = false;

    _shopliftingSubscription?.cancel();
    _shopliftingSubscription = null;
    _isListeningToShoplifting = false;
  }
}
