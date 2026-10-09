# App Performance & "Overload" Analysis

I have thoroughly investigated your Flutter codebase, focusing heavily on UI rendering cycles (glassmorphism/animations) and background Firebase streams, which are the two primary causes of app lag or "overload."

Here are my findings and the exact path to make the app significantly lighter without losing a single feature.

## 🚨 The Primary Bottleneck: `PeakHourService` Data Overload

**The Problem:**
In `lib/services/peak_hour_service.dart`, your streams (`hourlyStatsStream` and `peakHourStream`) are currently executing this query:
```dart
FirebaseFirestore.instance.collection('2minlogic').snapshots()
```
Notice that there is **no `.where()` filter and no `.limit()`** applied to this query. 

This means that every single time a person enters the store (which updates the database), your app downloads and loops through **every single 2-minute interval document ever recorded in the history of the app**. If the app has been running for weeks, this could be tens of thousands of documents loaded directly into your phone's memory every few minutes. This will absolutely cause the app to severely lag, crash, and spike your Firebase billing.

**The Fix:**
We can easily fix this without losing any functionality by restricting the query to only fetch what the UI actually needs: **Today's and Yesterday's data** (since the UI compares trends "vs yesterday").
```dart
// Example fix
final yesterday = DateTime.now().subtract(const Duration(days: 2));
FirebaseFirestore.instance
    .collection('2minlogic')
    // Assuming we parse the document ID or add a timestamp field
    .where('timestamp', isGreaterThan: yesterday) 
    .snapshots()
```

## ✅ The Good News: UI Rendering is Highly Optimized

Glassmorphism (`BackdropFilter`) is notoriously expensive for phone GPUs to render. If left unoptimized, it causes severe UI stuttering.

However, in your `GlassCard` widget (`lib/widgets/glass_widgets.dart`), you correctly wrapped the entire container in a `RepaintBoundary`. This forces Flutter to paint the complex blurred layer once, cache it as an image, and reuse it. **Your UI rendering is already perfectly optimized.**

## ✅ The Good News: Alerts are Capped

Your `AlertService` (`lib/pages/alert_service.dart`) handles real-time data correctly. When listening to `WeaponDetections` and `shoplifting_incidents`, it uses `.limit(20)` and `.limit(30)`. This guarantees the app only holds the newest alerts in memory, preventing memory leaks over time.

---

## Next Steps

To stop the app from overloading over time, **we must optimize the `PeakHourService` queries**. 

Shall I go ahead and implement the date-time filters in `PeakHourService` so the app only downloads recent data instead of the entire database history?
