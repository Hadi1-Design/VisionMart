# Goal Description

The goal is to add a visual touch feedback effect (similar to native app ripples or scale animations) to all interactive buttons and cards across the entire application. This will provide users with immediate visual confirmation whenever they tap an actionable item.

## User Review Required

Since Glassmorphism designs (`GlassCard`) often look muddy with standard Material ripple effects (the ripple gets blurred or hidden by the glass layers), I propose using a **Scale Animation (Bouncing effect)** instead. When a user presses down on a card or button, it will slightly shrink (e.g., to 97% size), and when released, it will bounce back and trigger the action. This is a very premium interaction model used heavily in modern native iOS and Android apps.

Please confirm if a "Scale/Bounce" effect is acceptable, or if you strictly prefer an "InkWell Ripple" effect.

## Open Questions

None. The scale animation approach will cleanly bypass any layering issues with `BackdropFilter` used in the glass widgets.

## Proposed Changes

### 1. `lib/widgets/glass_widgets.dart`
#### [MODIFY] [glass_widgets.dart](file:///d:/FYP/vision_app/lib/widgets/glass_widgets.dart)
- **New Widget**: Add a new `AnimatedTouchable` (or `TouchableCard`) wrapper widget.
- **Implementation**: It will use `GestureDetector`'s `onTapDown`, `onTapUp`, and `onTapCancel` events to trigger an `AnimatedContainer` that slightly scales down the child widget when pressed.

### 2. Global Replacements
- Replace instances of `GestureDetector(onTap: ...)` that wrap interactive UI elements (like `GlassCard` or custom buttons) with `AnimatedTouchable(onTap: ...)` across the app.
- **Affected Files**:
  - `dashboard.dart`
  - `staff_dashboard.dart`
  - `settings.dart`
  - `alerts.dart`
  - `analytics.dart`
  - `roi.dart`
  - `suspicious_activity.dart`
  - `weapon_alerts.dart`
  - `peak_hour_stats.dart`
  - `login.dart`
  - `signup.dart`

## Verification Plan

### Manual Verification
1. Run the app on a simulator or device.
2. Tap on any action card (e.g., "LIVE COUNT", "Suspicious Activity", "Settings" toggles).
3. Observe the immediate visual scale-down effect confirming the touch interaction before the screen navigates.
