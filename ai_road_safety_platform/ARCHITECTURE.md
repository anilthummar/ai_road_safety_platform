# Production architecture — AI Road Safety Platform

Feature-first Clean Architecture under `lib/`:
Presentation → Domain ← Data, wired with GetIt + `flutter_bloc`.

## Feature map

| Feature | Path | Role |
|---------|------|------|
| Camera | `features/camera` | Preview, permissions, throttled raw frames |
| Flood detection | `features/flood_detection` | YOLO + segmentation TFLite pipelines |
| GPS | `features/gps` | Fixes, tracking, speed |
| IMU | `features/imu` | Accel/gyro/mag, tilt, vibration, calibration |
| Risk analysis | `features/risk_analysis` | Rule engine (flood × speed × IMU × GPS) |
| Dashboard | `features/dashboard` | Driver HUD fusion UI |
| History | `features/history` | Hive DB + images + export |
| Analytics | `features/analytics` | Weekly/monthly/yearly KPIs + charts |
| Settings | `features/settings` | Theme, research navigation, and about |
| Dataset collection | `features/dataset_collection` | Capture, storage, metadata, annotation, export, and analytics |
| AI lifecycle | `features/dataset_collection` | Quality gates, model registry, experiments, benchmarks, active learning, deployment, and sensor fusion |
| Core | `lib/core` | DI, router, theme, errors, shared widgets |

## Performance contracts

- Camera default stream ≤ **8 FPS**; flood overrides to **5 FPS** (hot-update while streaming).
- YOLO inference target **6 FPS** with busy-guard (no backlog queue).
- HUD / risk fusion emit throttled (~100–200 ms).
- Shell branch visibility pauses camera + flood + dashboard fusion when leaving Dashboard.
- Shared camera singleton uses **owner refcount** (soft dispose).
- TFLite input/output buffers are **reused** across frames.
- Camera planes are copied as `Uint8List` (typed).

## Error model

Data layer throws `AppException` subtypes → repositories map via `ErrorHandler` → `Failure` → UI (`AppErrorView`).

## Testing

- Unit: aggregators, processors, filters, rule engine, camera FPS contract
- Widget/golden: risk chips, analytics period selector, warnings panel
- Run: `flutter test`

## Entry

`lib/main.dart` → `configureDependencies()` (Hive open) → `AiRoadSafetyApp`.
