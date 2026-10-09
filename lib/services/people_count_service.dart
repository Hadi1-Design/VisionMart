import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

class PeopleCountService {
  // Singleton instance
  static final PeopleCountService instance = PeopleCountService._internal();

  PeopleCountService._internal();

  /// Stream of current people count (In - Out).
  /// Listens to `VirtualLineCount/counter_1`.
  late final Stream<int> peopleCountStream = FirebaseFirestore.instance
      .collection('VirtualLineCount')
      .doc('counter_1')
      .snapshots()
      .map((snapshot) {
        debugPrint(
          "PeopleCountService: Snapshot received. Exists: ${snapshot.exists}, Data: ${snapshot.data()}",
        );
        if (!snapshot.exists || snapshot.data() == null) {
          return 0;
        }

        final data = snapshot.data()!;
        final inCount = (data['in_count'] as num?)?.toInt() ?? 0;
        final outCount = (data['out_count'] as num?)?.toInt() ?? 0;

        // Return 0 if negative (when out > in)
        final count = inCount - outCount;
        return count < 0 ? 0 : count;
      })
      .handleError((error) {
        debugPrint('Error listening to people count: $error');
        return 0; // Fallback on error
      })
      .asBroadcastStream();

  /// Stream of total people who entered today (in_count only).
  /// This shows how many people have entered, regardless of exits.
  late final Stream<int> totalEntriesStream = FirebaseFirestore.instance
      .collection('VirtualLineCount')
      .doc('counter_1')
      .snapshots()
      .map((snapshot) {
        debugPrint(
          "PeopleCountService: Snapshot received for entries. Exists: ${snapshot.exists}, Data: ${snapshot.data()}",
        );
        if (!snapshot.exists || snapshot.data() == null) {
          return 0;
        }

        final data = snapshot.data()!;
        final inCount = (data['in_count'] as num?)?.toInt() ?? 0;
        return inCount;
      })
      .handleError((error) {
        debugPrint('Error listening to total entries: $error');
        return 0;
      })
      .asBroadcastStream();
}
