# Implementation Plan: Daily Count Reset & History Archiving

## Goal
Modify the "Live Count" system to ensure the app only displays today's traffic (In-Exit counts). Previous days' totals will be archived into a new `Count_History` collection to facilitate analytics and day-over-day comparisons.

## User Review Required
> [!IMPORTANT]
> The reset logic depends on the Python inference script (`count(inference)/main.py`) running. If the script is turned off for several days, the first time it starts, it will archive the "last known" totals as the previous day's data and then reset for the current day.

## Proposed Changes

### 1. Backend Cleanup & Reset Logic
#### [MODIFY] [main.py](file:///d:/FYP/count(inference)/main.py)
*   **Remove `10minlogic`**: Delete all variables, references, and commented-out code related to the `10minlogic` collection.
*   **Implement `DailyReset` Logic**:
    *   Update `FirebaseManager` to store `last_reset_date` (fetched from Firestore `VirtualLineCount/counter_1` or defaulted to today).
    *   In the `update()` loop:
        1. Compare current date with `last_reset_date`.
        2. If `current_date > last_reset_date`:
            *   **Archive**: Write the current `in_count` and `out_count` to `Count_History` using the previous date as the Document ID.
            *   **Reset Firestore**: Set `in_count` and `out_count` to `0` in `VirtualLineCount/counter_1`.
            *   **Reset Local Counter**: Re-initialize the `supervision.LineZone` object to reset its internal memory to zero.
            *   **Update Tracking**: Set `last_reset_date` to `current_date`.

---

### 2. Database Schema Updates
#### [MODIFY] `VirtualLineCount/counter_1`
*   Add/Update field: `last_reset_date` (String, format: `YYYY-MM-DD`).
*   This document will now always represent "Today's Count".

#### [NEW] `Count_History` (Collection)
*   **Document ID**: `YYYY-MM-DD` (The date the counts belong to).
*   **Fields**:
    ```json
    {
      "total_in": number,
      "total_out": number,
      "timestamp": ServerTimestamp,
      "date_string": "YYYY-MM-DD"
    }
    ```

---

### 3. Flutter App Integration
#### [MODIFY] [people_count_service.dart](file:///d:/FYP/vision_app/lib/services/people_count_service.dart)
*   No breaking changes required. The service already listens to `VirtualLineCount/counter_1`.
*   Since the backend will reset this document to 0 every day, the UI's "Live Count" card will automatically display only today's data.

## Verification Plan

### Automated/Manual Tests
1.  **Date Transition**: Manually edit the `last_reset_date` in Firestore to yesterday's date while the Python script is running. 
    *   **Expectation**: The script should immediately detect the "new day," save the current counts to `Count_History`, and reset the live count to 0.
2.  **App UI**: Open the Flutter app during the reset.
    *   **Expectation**: The "Live Count" card should update from its previous value to 0 in real-time.
3.  **Data Integrity**: Verify that `Count_History` contains the correct final numbers from the previous session.
