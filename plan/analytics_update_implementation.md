# Analytics Page Update - Implementation Plan
## (Roman English mein likha gaya hai)

---

## Maqsad (Goal)

Analytics page ko real Firebase data ke saath connect karna hai. Abhi sab data hard-coded/dummy hai. Hum 3 cheezein implement karne hain:
1. **Total Visitors card** mein real `in_count` dikhana (VirtualLineCount se)
2. **Total Alerts card** mein real alert count dikhana (AlertService se)
3. **Daily / Weekly / Monthly tabs** ko real data ke saath sync karna — visitor trends aur alert frequency dono

---

## Firebase Collections Jo Available Hain

| Collection | Kya store hota hai |
|---|---|
| `VirtualLineCount/counter_1` | `in_count`, `out_count` — aaj ka live count |
| `Count_History/{date}` | `total_in`, `total_out` — har pichle din ka archived data |
| `2minlogic/{timestamp}` | `interval_in`, `interval_out` — har 2 minute ka snapshot |
| `WeaponDetections` | Weapon alerts with `timestamp` |
| `shoplifting_incidents` | Shoplifting alerts with `timestamp` |

---

## Part 1 — Total Visitors Card (Real Data)

### Kya Karna Hai:
- **Daily tab select** hone par: `VirtualLineCount/counter_1` se `in_count` lena (aaj ka live count) — yeh already `PeopleCountService.totalEntriesStream` mein available hai.
- **Weekly tab**: `Count_History` collection se last 7 days ke `total_in` values sum karna + aaj ka live `in_count` add karna.
- **Monthly tab**: `Count_History` collection se current month ke saare documents ke `total_in` sum karna + aaj ka live `in_count`.

### Kahan Change Hoga:
- **`lib/pages/analytics.dart`** — `_buildSimpleStatCard` ko `StreamBuilder` se replace karna. Ek naya `_AnalyticsService` ya directly Firestore calls use karni hongi.

---

## Part 2 — Total Alerts Card (Real Data)

### Kya Karna Hai:
- **Daily tab**: Aaj ke `WeaponDetections` + `shoplifting_incidents` documents count karna (timestamp >= today midnight).
- **Weekly tab**: Is week ke alerts count karna (timestamp >= Monday midnight).
- **Monthly tab**: Is month ke alerts count karna (timestamp >= 1st of month midnight).

### Approach:
- `AlertService.instance.alerts` already mein real-time alerts hain (WeaponDetections + shoplifting).
- Lekin yeh sirf **last 20-30 documents** fetch karta hai. Weekly/Monthly ke liye seedha Firestore query chahiye hogi count ke liye.
- Ek naya `AnalyticsService` banayenge jisme `getAlertCountForPeriod(DateTime from)` method hoga.

---

## Part 3 — Daily/Weekly/Monthly Graphs (Real Data)

### Daily Tab:
- **Visitor Trend Chart**: `2minlogic` collection se aaj ke documents query karna. Har hour ke `interval_in` aggregate karna → 24 FlSpots (hour 0-23).
  - Yeh logic already `PeakHourService.hourlyStatsStream` mein hai — isko reuse karna hai.
- **Alert Frequency Chart**: `WeaponDetections` + `shoplifting_incidents` mein aaj ke records ko hour-wise group karna → 24 FlSpots.

### Weekly Tab:
- **Visitor Trend Chart**: `Count_History` se last 7 din ke documents → har din ka `total_in` → 7 FlSpots (Mon to Sun labels).
  - Agar aaj ka din `Count_History` mein nahi hai (kyunki reset nahi hua) → `VirtualLineCount/counter_1.in_count` se aaj ka data live add karna.
- **Alert Frequency Chart**: `WeaponDetections` + `shoplifting_incidents` se last 7 din ke records → din ke hisab se group karna → 7 FlSpots.

### Monthly Tab:
- **Visitor Trend Chart**: `Count_History` se current month ke documents → har week ka total (W1, W2, W3, W4) → 4 FlSpots.
- **Alert Frequency Chart**: Same collection filter karke alerts weekly group mein → 4 FlSpots.

---

## Naye Files Jo Banenge

### `lib/services/analytics_service.dart` [NEW]
- Singleton service
- Streams provide karega:
  - `Stream<int> visitorsForPeriod(int tab)` — tab 0=daily, 1=weekly, 2=monthly
  - `Stream<int> alertsForPeriod(int tab)`
  - `Stream<List<FlSpot>> visitorTrendSpots(int tab)`
  - `Stream<List<FlSpot>> alertTrendSpots(int tab)`
  - `Stream<List<String>> labelsForTab(int tab)`

---

## Files Jo Modify Honge

### `lib/pages/analytics.dart` [MODIFY]

Ye saari cheezein change hongi:

1. **Import** karna `analytics_service.dart` ka.
2. **`initState`** mein `AnalyticsService` subscribe karna.
3. **`_buildSimpleStatCard`** ko `StreamBuilder<int>` ke andar wrap karna taake real numbers show ho.
4. **`dailyData`, `weeklyData`, `monthlyData`** wali hardcoded lists hata deni.
5. **`dailyAlertData`, `weeklyAlertData`, `monthlyAlertData`** wali hardcoded lists hata deni.
6. **`VisitorTrendChart`** ko dynamic data milega StreamBuilder ke zariye.
7. Tab switch hone par `_selectedTab` change hoga → StreamBuilder automatically naya data fetch karega.

---

## Data Flow Diagram

```
Tab Select (0/1/2)
       |
       v
AnalyticsService
  |          |
  v          v
VirtualLine  Count_History    WeaponDetections
Count/       (weekly/monthly)  + shoplifting_incidents
counter_1    archived days      (timestamp filter)
(today live)
       |          |                    |
       v          v                    v
  Visitor Count  Visitor Trend Spots  Alert Count + Alert Spots
       |                                    |
       v                                    v
  Total Visitors Card              Total Alerts Card
       |                                    |
       v                                    v
  Visitor Trend Chart              Alert Frequency Chart
```

---

## Edge Cases Jo Handle Karne Hain

1. **Aaj ka din `Count_History` mein nahi hoga** — kyunki reset tab hota hai jab naya din aata hai. Isliye weekly/monthly totals mein aaj ka live `in_count` manually add karna hoga.
2. **`2minlogic` collection khali ho** — 0 dikhana hai, crash nahi karna.
3. **Loading state** — StreamBuilder mein `ConnectionState.waiting` par shimmer ya skeleton UI dikhana.
4. **Firestore query costs** — Weekly/Monthly ke liye `orderBy('timestamp').where(timestamp >= X)` use karna — index banana padega (Firestore Console mein already hoga ya auto-create hoga).

---

## Step-by-Step Implementation Order

```
Step 1: AnalyticsService banana (lib/services/analytics_service.dart)
         - visitorsForPeriod stream
         - alertsForPeriod stream
         - visitorTrendSpots stream
         - alertTrendSpots stream

Step 2: analytics.dart mein StatefulWidget update karna
         - StreamBuilders add karna
         - Hardcoded data hatana
         - Loading indicators lagana

Step 3: Test karna
         - Daily: aaj ka in_count dikh raha hai?
         - Weekly: pichle 7 din ka sum sahi hai?
         - Monthly: is month ka total sahi hai?
         - Graphs: points real data se match karte hain?
```

---

## Verification Plan

- **Daily Visitors**: Python backend se kuch log karke `VirtualLineCount/counter_1.in_count` check karo → app mein wohi number dikhna chahiye.
- **Weekly Visitors**: `Count_History` mein pichle dinon ke documents check karo → sum match karna chahiye.
- **Alerts**: Firebase Console mein aaj ke WeaponDetections + shoplifting_incidents count karo → app mein wohi number aana chahiye.
- **Graphs**: Date filter laga ke manually count karo → chart ke points se match karo.

---

> **Note**: Is plan mein koi Python (`main.py`) change nahi hai. Sab kuch Flutter side par hoga. Firebase structure jo already exist karta hai (`VirtualLineCount`, `Count_History`, `2minlogic`, `WeaponDetections`, `shoplifting_incidents`) — usi ko use karenge.
