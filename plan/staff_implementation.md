# Goal Description

Update the Staff Dashboard to align certain features with the main Dashboard:
1. Make the "Live Count" stat card tappable to open the `PeakHourStatsPage`, displaying the same detailed peak hour statistics.
2. Remove the "Primary Feed" section entirely from the Staff Dashboard.
3. Update the "Footfall Today" stat card to display real-time data fetched from `PeakHourService` rather than displaying static hardcoded mock data.

## User Review Required

No critical or breaking changes. The proposed updates purely modify the Staff Dashboard UI to match the logic already present and tested in the main Dashboard. 

## Open Questions

None. The requirements are clear and can be implemented using the existing `PeakHourService` and `PeakHourStatsPage`.

## Proposed Changes

### `lib/pages/staff_dashboard.dart`
#### [MODIFY] [staff_dashboard.dart](file:///d:/FYP/vision_app/lib/pages/staff_dashboard.dart)
- **Imports**: Add `package:vision_app/services/peak_hour_service.dart` and `package:vision_app/pages/peak_hour_stats.dart`.
- **Live Count**: Wrap the "LIVE COUNT" `_buildStatCard` in a `GestureDetector` that navigates to `PeakHourStatsPage`. Add `showHint: true` to the card and update the `_buildStatCard` method definition to support the `showHint` boolean parameter.
- **Primary Feed**: Remove the `Text("PRIMARY FEED")` widget, the `SurveillanceOverlay` widget, and their associated spacing.
- **Footfall Today**: Replace the static `_buildStatCard` for "FOOTFALL TODAY" with a `StreamBuilder<PeakHourData>` listening to `PeakHourService.instance.peakHourStream`, replicating the real-time functionality from `dashboard.dart`.

## Verification Plan

### Manual Verification
1. Run the app and log in as a Staff member (or navigate to Staff Dashboard).
2. Tap the "LIVE COUNT" card and verify it navigates to the detailed stats page.
3. Verify that the "PRIMARY FEED" video overlay section is no longer visible on the page.
4. Verify that "FOOTFALL TODAY" updates dynamically with real-time data instead of showing a static "1.2k" value.
